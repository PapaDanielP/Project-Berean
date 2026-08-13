import { createHash, timingSafeEqual } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

export type Role = 'READER' | 'RESEARCHER' | 'CONTENT_EDITOR' | 'REVIEWER' | 'ADMINISTRATOR' | 'SYSTEM';

export interface AuthenticatedActor {
  key: string;
  displayName: string;
  role: Role;
}

export interface ApiCredential extends AuthenticatedActor {
  tokenHash: string;
}

declare module 'express-serve-static-core' {
  interface Request {
    actor?: AuthenticatedActor;
    correlationId?: string;
  }
}

const rank: Record<Role, number> = {
  READER: 0,
  RESEARCHER: 1,
  CONTENT_EDITOR: 2,
  REVIEWER: 3,
  ADMINISTRATOR: 4,
  SYSTEM: 5
};

const digest = (token: string): Buffer => createHash('sha256').update(token, 'utf8').digest();

export class BearerAuthenticator {
  private readonly credentials: Array<ApiCredential & { digest: Buffer }>;

  constructor(credentials: ApiCredential[]) {
    this.credentials = credentials.map((credential) => ({
      ...credential,
      digest: Buffer.from(credential.tokenHash, 'hex')
    })).filter((credential) => credential.digest.length === 32);
  }

  require(minimumRole: Role) {
    return (req: Request, res: Response, next: NextFunction): void => {
      if (!this.credentials.length) {
        res.status(503).json({ error: { code: 'AUTH_NOT_CONFIGURED', message: 'Administrative authentication is not configured.' } });
        return;
      }
      const authorization = req.get('authorization') ?? '';
      const separator = authorization.indexOf(' ');
      const scheme = separator < 0 ? '' : authorization.slice(0, separator);
      const token = separator < 0 ? '' : authorization.slice(separator + 1);
      if (scheme.toLowerCase() !== 'bearer' || !token) {
        res.status(401).setHeader('WWW-Authenticate', 'Bearer').json({
          error: { code: 'UNAUTHENTICATED', message: 'A bearer credential is required.' }
        });
        return;
      }
      const presented = digest(token);
      const credential = this.credentials.find((candidate) => timingSafeEqual(candidate.digest, presented));
      if (!credential) {
        res.status(401).setHeader('WWW-Authenticate', 'Bearer').json({
          error: { code: 'UNAUTHENTICATED', message: 'The bearer credential is invalid.' }
        });
        return;
      }
      if (rank[credential.role] < rank[minimumRole]) {
        res.status(403).json({ error: { code: 'FORBIDDEN', message: `${minimumRole} role or higher is required.` } });
        return;
      }
      req.actor = { key: credential.key, displayName: credential.displayName, role: credential.role };
      next();
    };
  }
}

export const credentialsFromEnvironment = (): ApiCredential[] => {
  const encoded = process.env.BEREAN_API_CREDENTIALS;
  if (!encoded) return [];
  const value: unknown = JSON.parse(encoded);
  if (!Array.isArray(value)) throw new Error('BEREAN_API_CREDENTIALS must be a JSON array.');
  return value as ApiCredential[];
};
