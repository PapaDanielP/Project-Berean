import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { createApp } from '../../src/app.js';
import { openApiDocument } from '../../src/api/openapi.js';

// Smallest useful Explorer <-> API contract test (docs/07-review/EXPLORER_API_INTEGRATION_AUDIT.md
// F-EXP-02). It extracts every `/api/...` path literal the Explorer client
// (`src/public/app.js`) actually calls and asserts each one resolves to a route registered on the
// live Express application and documented in `GET /openapi.json`. This protects against a server
// route rename/removal silently breaking the UI, without adding a browser-test dependency.

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for Explorer contract tests');
}

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const explorerSource = fs.readFileSync(path.join(repoRoot, 'src/public/app.js'), 'utf8');

const app = createApp(databaseUrl);
const document = openApiDocument() as Record<string, any>;

interface ImplementedRoute {
  method: string;
  path: string;
}

// Mirrors the mount-prefix recovery already established in tests/app/openapi-coverage.test.ts.
const mountPrefix = (regexp: { source: string; fast_slash?: boolean }): string => {
  if (regexp.fast_slash) return '';
  const match = /^\^((?:\\\/|[\w\-.~])*)/.exec(regexp.source);
  return (match ? match[1] : '').replace(/\\\//g, '/').replace(/\/$/, '');
};

const collectRoutes = (): ImplementedRoute[] => {
  const routes: ImplementedRoute[] = [];
  const walk = (stack: any[], prefix: string): void => {
    for (const layer of stack) {
      if (layer.route) {
        for (const method of Object.keys(layer.route.methods)) {
          routes.push({ method: method.toUpperCase(), path: `${prefix}${layer.route.path}` });
        }
      } else if (layer.name === 'router' && layer.handle?.stack) {
        walk(layer.handle.stack, prefix + mountPrefix(layer.regexp));
      }
    }
  };
  walk((app as unknown as { _router: { stack: any[] } })._router.stack, '');
  return routes;
};

const implemented = collectRoutes();
const documentedPaths = new Set(Object.keys(document.paths ?? {}));

// Normalizes an Express route path (`/api/claims/:claimId`) to a template comparable with the
// normalized Explorer literal (`/api/claims/{param}`).
const normalizeExpressPath = (routePath: string): string =>
  routePath.replace(/:([A-Za-z0-9_]+)\??/g, '{param}');

// Normalizes an OpenAPI path (`/api/claims/{claimId}`) the same way.
const normalizeOpenApiPath = (openApiPath: string): string => openApiPath.replace(/\{[^}]+\}/g, '{param}');

const normalizedImplemented = new Map<string, ImplementedRoute[]>();
for (const route of implemented) {
  const key = normalizeExpressPath(route.path);
  const bucket = normalizedImplemented.get(key) ?? [];
  bucket.push(route);
  normalizedImplemented.set(key, bucket);
}

const normalizedDocumented = new Set([...documentedPaths].map(normalizeOpenApiPath));

// Extracts every distinct `/api/...` path literal referenced by the Explorer client, whether a
// plain string or a template literal, stripping any query string and normalizing interpolated
// segments (`${...}`) to a single `{param}` placeholder.
const extractExplorerApiCalls = (source: string): string[] => {
  const pattern = /['"`](\/api\/[^'"`]*)['"`]/g;
  const calls = new Set<string>();
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(source)) !== null) {
    const literal = match[1];
    const withoutQuery = literal.split('?')[0];
    const normalized = withoutQuery.replace(/\$\{[^}]*\}/g, '{param}').replace(/\/$/, '');
    if (normalized === '/api') continue;
    calls.add(normalized);
  }
  return [...calls].sort();
};

const explorerCalls = extractExplorerApiCalls(explorerSource);

describe('Explorer <-> API contract', () => {
  it('extracted at least the ten documented Explorer endpoints', () => {
    expect(explorerCalls.length).toBeGreaterThanOrEqual(10);
  });

  it.each(explorerCalls)('Explorer call %s resolves to a registered Express route', (call) => {
    expect(normalizedImplemented.has(call), `no registered route matches Explorer call ${call}`).toBe(true);
  });

  it.each(explorerCalls)('Explorer call %s is documented in the OpenAPI paths', (call) => {
    expect(normalizedDocumented.has(call), `no OpenAPI path matches Explorer call ${call}`).toBe(true);
  });

  it('keeps NO_MATCH and NOT_REPRESENTED distinct in Explorer wording', () => {
    expect(explorerSource).toContain('NOT_REPRESENTED');
    expect(explorerSource).toContain('outside the represented query capability');
    expect(explorerSource).toContain('NO_MATCH');
    expect(explorerSource).toContain('supported query found no matching represented claim');
    expect(explorerSource).toContain('Directly source-backed claims');
    expect(explorerSource).not.toContain('What Berean Establishes');
  });
});
