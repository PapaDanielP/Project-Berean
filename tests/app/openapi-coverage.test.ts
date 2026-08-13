import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../../src/app.js';
import { openApiDocument } from '../../src/api/openapi.js';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for OpenAPI coverage tests');
}

const app = createApp(databaseUrl);
const document = openApiDocument() as Record<string, any>;

interface ImplementedRoute {
  method: string;
  path: string;
}

// Express keeps the registered layer stack on the application router. Mount prefixes are literal
// strings in this application, so they can be recovered from the layer regular expression.
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

// `/api/v1/search/:resource?` is one Express layer serving two documented paths.
const documentedPathsFor = (route: ImplementedRoute): string[] => {
  const template = route.path.replace(/:([A-Za-z0-9_]+)\??/g, '{$1}');
  return route.path.endsWith('?')
    ? [template.replace(/\/\{[A-Za-z0-9_]+\}$/, ''), template]
    : [template];
};

const isFallback = (route: ImplementedRoute): boolean => route.path.includes('*');

const normalizeFallback = (path: string): string => path.replace('/*', '*');

const implemented = collectRoutes();
const fallbackRoutes = (document['x-berean-fallback-routes'] as Array<{ method: string; path: string }>) ?? [];

describe('OpenAPI route-surface coverage', () => {
  it('documents every implemented route and method', () => {
    const undocumented: string[] = [];
    for (const route of implemented) {
      if (isFallback(route)) {
        const declared = fallbackRoutes.some((fallback) => normalizeFallback(fallback.path) === normalizeFallback(route.path));
        if (!declared) undocumented.push(`${route.method} ${route.path} (fallback)`);
        continue;
      }
      for (const path of documentedPathsFor(route)) {
        const operation = document.paths?.[path]?.[route.method.toLowerCase()];
        if (!operation) undocumented.push(`${route.method} ${path}`);
      }
    }
    expect(undocumented).toEqual([]);
  });

  it('does not document routes that are not implemented', () => {
    const implementedPaths = new Set<string>();
    for (const route of implemented) {
      if (isFallback(route)) continue;
      for (const path of documentedPathsFor(route)) implementedPaths.add(`${route.method} ${path}`);
    }
    const phantom: string[] = [];
    for (const [path, operations] of Object.entries(document.paths as Record<string, Record<string, unknown>>)) {
      for (const method of Object.keys(operations)) {
        const signature = `${method.toUpperCase()} ${path}`;
        if (!implementedPaths.has(signature)) phantom.push(signature);
      }
    }
    expect(phantom).toEqual([]);
  });

  it('gives every operation responses, read/write classification, and resolvable references', () => {
    const incomplete: string[] = [];
    for (const [path, operations] of Object.entries(document.paths as Record<string, Record<string, any>>)) {
      for (const [method, operation] of Object.entries(operations)) {
        const signature = `${method.toUpperCase()} ${path}`;
        if (!operation.operationId || !operation.summary || !operation.description) incomplete.push(`${signature}: metadata`);
        if (!operation.responses || !Object.keys(operation.responses).length) incomplete.push(`${signature}: responses`);
        if (operation['x-berean-write'] === undefined) incomplete.push(`${signature}: x-berean-write`);
        if (operation['x-berean-write'] === true && !operation['x-berean-persistence']) incomplete.push(`${signature}: persistence`);
      }
    }
    expect(incomplete).toEqual([]);

    const serialized = JSON.stringify(document);
    const references = new Set(Array.from(serialized.matchAll(/"\$ref":"#\/([^"]+)"/g), (match) => match[1]));
    const unresolved = [...references].filter((reference) =>
      reference.split('/').reduce<any>((node, segment) => (node ? node[segment] : undefined), document) === undefined);
    expect(unresolved).toEqual([]);
  });

  it('documents authentication, minimum role, and audit behavior for every mutation', () => {
    const incomplete: string[] = [];
    for (const [path, operations] of Object.entries(document.paths as Record<string, Record<string, any>>)) {
      for (const [method, operation] of Object.entries(operations)) {
        if (method === 'get') continue;
        if (operation['x-berean-write'] !== true) continue;
        const signature = `${method.toUpperCase()} ${path}`;
        if (!operation.security?.length) incomplete.push(`${signature}: security`);
        if (!operation['x-berean-minimum-role']) incomplete.push(`${signature}: minimum role`);
        if (!operation['x-berean-audit']) incomplete.push(`${signature}: audit`);
        if (!operation['x-berean-transaction']) incomplete.push(`${signature}: transaction`);
        if (!operation['x-berean-epistemic-boundary']) incomplete.push(`${signature}: epistemic boundary`);
        for (const status of ['401', '403', '503']) {
          if (!operation.responses[status]) incomplete.push(`${signature}: ${status}`);
        }
      }
    }
    expect(incomplete).toEqual([]);
  });

  it('serves the documented contract over HTTP', async () => {
    const response = await request(app).get('/openapi.json');
    expect(response.status).toBe(200);
    expect(response.body.openapi).toBe('3.1.0');
    expect(Object.keys(response.body.paths).length).toBe(Object.keys(document.paths).length);
    expect(response.body.components.securitySchemes.bearerAuth.scheme).toBe('bearer');
  });

  it('documents the capabilities registry redirect', async () => {
    const response = await request(app).get('/api/v1/registry/capabilities').redirects(0);
    expect(response.status).toBe(307);
    expect(response.headers.location).toBe('/api/v1/capabilities');
    expect(document.paths['/api/v1/registry/{registry}'].get.responses['307']).toBeDefined();
  });
});
