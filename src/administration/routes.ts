import { randomUUID } from 'node:crypto';
import { Router, type NextFunction, type Request, type Response } from 'express';
import { BearerAuthenticator } from '../auth.js';
import { ADMINISTRATION_LIST_RESOURCES, AdministrationRepository } from './repository.js';
import { AdministrationError, AdministrationService } from './service.js';
import { ExportArtifactError, readExportArtifact } from '../worker/export-artifact.js';

const positiveId = (value: string): number | null => {
  if (!/^\d+$/.test(value)) return null;
  const result = Number(value);
  return Number.isSafeInteger(result) && result > 0 ? result : null;
};

const handler = (
  operation: (req: Request, res: Response) => Promise<void>
) => (req: Request, res: Response, next: NextFunction): void => {
  operation(req, res).catch(next);
};

export const registerAdministrationRoutes = (
  repository: AdministrationRepository,
  authenticator: BearerAuthenticator,
  exportArtifactDirectory: string | undefined
): Router => {
  const router = Router();
  const service = new AdministrationService(repository);

  router.use((req, res, next) => {
    const supplied = req.get('x-correlation-id');
    req.correlationId = supplied && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(supplied)
      ? supplied
      : randomUUID();
    res.setHeader('X-Correlation-Id', req.correlationId);
    next();
  });

  router.get(
    '/admin/:resource',
    authenticator.require('READER'),
    handler(async (req, res) => {
      if (!ADMINISTRATION_LIST_RESOURCES.includes(req.params.resource)) {
        throw new AdministrationError(
          404,
          'NOT_FOUND',
          `Administrative resource was not found. Supported resources: ${ADMINISTRATION_LIST_RESOURCES.join(', ')}.`
        );
      }
      const rawLimit = req.query.limit === undefined ? 50 : Number(req.query.limit);
      if (!Number.isSafeInteger(rawLimit) || rawLimit < 1 || rawLimit > 100) {
        throw new AdministrationError(400, 'INVALID_REQUEST', 'limit must be between 1 and 100.');
      }
      res.json({ results: await repository.list(req.params.resource, rawLimit) });
    })
  );

  const artifactKey = (value: string): string | null =>
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
      ? value.toLowerCase()
      : null;

  router.get(
    '/export-artifacts/:artifactKey',
    authenticator.require('ADMINISTRATOR'),
    handler(async (req, res) => {
      const key = artifactKey(req.params.artifactKey);
      if (!key) throw new AdministrationError(400, 'INVALID_REQUEST', 'artifactKey must be an opaque UUID.');
      const artifact = await repository.getExportArtifact(key);
      if (!artifact) throw new AdministrationError(404, 'NOT_FOUND', 'Export artifact metadata was not found.');
      res.json(artifact);
    })
  );

  router.get(
    '/export-artifacts/:artifactKey/download',
    authenticator.require('ADMINISTRATOR'),
    handler(async (req, res) => {
      const key = artifactKey(req.params.artifactKey);
      if (!key) throw new AdministrationError(400, 'INVALID_REQUEST', 'artifactKey must be an opaque UUID.');
      const artifact = await repository.getExportArtifact(key);
      if (!artifact) throw new AdministrationError(404, 'NOT_FOUND', 'Export artifact metadata was not found.');
      const bytes = await readExportArtifact(
        exportArtifactDirectory,
        String(artifact.relative_locator),
        Number(artifact.byte_length),
        String(artifact.sha256)
      );
      res
        .setHeader('Content-Disposition', 'attachment; filename="berean-export.jsonl"')
        .setHeader('Cache-Control', 'private, no-store')
        .type(String(artifact.content_type))
        .send(bytes);
    })
  );

  router.post(
    '/corpora',
    authenticator.require('ADMINISTRATOR'),
    handler(async (req, res) => {
      res.status(201).json(await service.createCorpus(req.body, req.actor!, req.correlationId!));
    })
  );
  router.patch(
    '/corpora/:id',
    authenticator.require('ADMINISTRATOR'),
    handler(async (req, res) => {
      const id = positiveId(req.params.id);
      const version = Number(req.get('if-match'));
      if (!id || !Number.isSafeInteger(version) || version < 1) {
        throw new AdministrationError(400, 'INVALID_REQUEST', 'A positive id and numeric If-Match version are required.');
      }
      const result = await service.updateCorpus(id, version, req.body, req.actor!, req.correlationId!);
      if (!result) throw new AdministrationError(409, 'STALE_VERSION', 'The corpus version is stale or the corpus does not exist.');
      res.json(result);
    })
  );
  router.post(
    '/research-topics',
    authenticator.require('RESEARCHER'),
    handler(async (req, res) => {
      res.status(201).json(await service.createTopic(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/discovery-requests',
    authenticator.require('RESEARCHER'),
    handler(async (req, res) => {
      res.status(202).json(await service.createDiscovery(
        req.body, req.get('idempotency-key'), req.actor!, req.correlationId!
      ));
    })
  );
  router.post(
    '/discovery-requests/:id/candidates',
    authenticator.require('RESEARCHER'),
    handler(async (req, res) => {
      const id = positiveId(req.params.id);
      if (!id) throw new AdministrationError(400, 'INVALID_REQUEST', 'id must be a positive integer.');
      res.status(201).json(await service.addCandidate(id, req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/candidates/:id/review',
    authenticator.require('REVIEWER'),
    handler(async (req, res) => {
      const id = positiveId(req.params.id);
      if (!id) throw new AdministrationError(400, 'INVALID_REQUEST', 'id must be a positive integer.');
      res.json(await service.reviewCandidate(id, req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/source-registrations',
    authenticator.require('CONTENT_EDITOR'),
    handler(async (req, res) => {
      res.status(201).json(await service.registerSource(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/source-records',
    authenticator.require('CONTENT_EDITOR'),
    handler(async (req, res) => {
      res.status(201).json(await service.createSourceRecord(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/evidence',
    authenticator.require('CONTENT_EDITOR'),
    handler(async (req, res) => {
      res.status(201).json(await service.createEvidence(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/claims',
    authenticator.require('REVIEWER'),
    handler(async (req, res) => {
      res.status(201).json(await service.createClaim(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/identity-mappings',
    authenticator.require('CONTENT_EDITOR'),
    handler(async (req, res) => {
      res.status(201).json(await service.createIdentityMapping(req.body, req.actor!, req.correlationId!));
    })
  );
  router.post(
    '/identity-mappings/:id/review',
    authenticator.require('REVIEWER'),
    handler(async (req, res) => {
      const id = positiveId(req.params.id);
      if (!id) throw new AdministrationError(400, 'INVALID_REQUEST', 'id must be a positive integer.');
      const result = await service.reviewIdentityMapping(id, req.body, req.actor!, req.correlationId!);
      if (!result) throw new AdministrationError(409, 'INVALID_MAPPING_STATE', 'Only a proposed mapping can be reviewed.');
      res.json(result);
    })
  );
  router.post(
    '/derivations',
    authenticator.require('RESEARCHER'),
    handler(async (req, res) => {
      res.status(201).json(await service.createDerivation(req.body, req.actor!, req.correlationId!));
    })
  );

  for (const [path, type, role] of [
    ['/ingestion-jobs', 'INGESTION', 'CONTENT_EDITOR'],
    ['/validation-runs', 'VALIDATION', 'REVIEWER'],
    ['/export-jobs', 'EXPORT', 'ADMINISTRATOR']
  ] as const) {
    router.post(
      path,
      authenticator.require(role),
      handler(async (req, res) => {
        res.status(202).json(await service.createJob(
          type, req.body, req.get('idempotency-key'), req.actor!, req.correlationId!
        ));
      })
    );
  }

  for (const action of ['cancel', 'retry'] as const) {
    router.post(
      `/jobs/:id/${action}`,
      authenticator.require('CONTENT_EDITOR'),
      handler(async (req, res) => {
        const id = positiveId(req.params.id);
        if (!id) throw new AdministrationError(400, 'INVALID_REQUEST', 'id must be a positive integer.');
        const result = await repository.changeJob(id, action, req.actor!, req.correlationId!);
        if (!result) throw new AdministrationError(409, 'INVALID_JOB_STATE', `The job cannot ${action} from its current state.`);
        res.json(result);
      })
    );
  }

  return router;
};

export const administrationErrorHandler = (
  error: Error & { code?: string; constraint?: string },
  _req: Request,
  res: Response,
  next: NextFunction
): void => {
  if (res.headersSent) return next(error);
  if (error instanceof AdministrationError) {
    res.status(error.status).json({ error: { code: error.code, message: error.message } });
    return;
  }
  if (error instanceof ExportArtifactError) {
    const configuration = error.code === 'EXPORT_ARTIFACT_DIR_MISSING' ||
      error.code === 'EXPORT_ARTIFACT_DIR_INVALID';
    res.status(configuration ? 503 : 409).json({
      error: {
        code: error.code,
        message: configuration
          ? 'Local export artifact storage is not configured safely.'
          : 'The persisted export artifact is unavailable or failed integrity verification.'
      }
    });
    return;
  }
  if (error.message === 'DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION') {
    res.status(422).json({
      error: {
        code: error.message,
        message: 'Direct and interpretive claims require cited SOURCE_OBSERVATION evidence; analytical observations are not promoted automatically.'
      }
    });
    return;
  }
  if (error.message === 'UNSUPPORTED_ADMIN_RESOURCE') {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Administrative resource was not found.' } });
    return;
  }
  if (error.message === 'IDEMPOTENCY_KEY_REUSED') {
    res.status(409).json({
      error: { code: 'IDEMPOTENCY_CONFLICT', message: 'The idempotency key was already used with a different request.' }
    });
    return;
  }
  if (error.message === 'DERIVATION_INPUT_REQUIRED') {
    res.status(422).json({
      error: { code: error.message, message: 'A derived claim requires an existing derivation with explicit inputs.' }
    });
    return;
  }
  if (error.message === 'IDENTITY_EVIDENCE_SOURCE_MISMATCH') {
    res.status(422).json({
      error: { code: error.message, message: 'Identity reconciliation evidence must originate from the source that supplied the identity.' }
    });
    return;
  }
  if (error.message === 'JOB_ACTION_FORBIDDEN') {
    res.status(403).json({ error: { code: 'FORBIDDEN', message: 'The actor cannot change this job.' } });
    return;
  }
  if (error.code === '23505') {
    res.status(409).json({ error: { code: 'DUPLICATE', message: 'A resource with the same stable key already exists.' } });
    return;
  }
  if (error.code === '23503' || error.code === '23514') {
    res.status(422).json({ error: { code: 'INTEGRITY_VIOLATION', message: 'The request violates a controlled registry or provenance constraint.' } });
    return;
  }
  next(error);
};
