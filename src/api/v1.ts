import { Router, type Request, type Response } from 'express';
import { BereanRepository } from '../repository.js';

const resources = new Set([
  'entities', 'events', 'claims', 'evidence', 'sources', 'datasets',
  'source-records', 'citations', 'identities', 'identity-mappings'
]);
const registries = new Set([
  'predicates', 'entity-types', 'event-types', 'claim-types', 'evidence-types', 'mapping-statuses'
]);

const positiveInteger = (value: unknown): number | null => {
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return null;
  const result = Number.parseInt(value, 10);
  return Number.isSafeInteger(result) && result > 0 ? result : null;
};

const limit = (value: unknown): number | null => {
  if (value === undefined) return 50;
  const result = positiveInteger(value);
  return result && result <= 100 ? result : null;
};

const error = (res: Response, status: number, code: string, message: string): void => {
  res.status(status).json({ error: { code, message } });
};

const openApi = {
  openapi: '3.1.0',
  info: {
    title: 'Project Berean API',
    version: '1.0.0',
    description: 'A read-only, provenance-aware interface over the existing Berean PostgreSQL schema.'
  },
  paths: {
    '/api/v1/capabilities': { get: { summary: 'List implemented and unavailable capabilities' } },
    '/api/v1/schema': { get: { summary: 'Describe the authoritative schema boundary' } },
    '/api/v1/{resource}': { get: { summary: 'List a supported persisted resource', parameters: [{ name: 'resource', in: 'path', required: true }] } },
    '/api/v1/{resource}/{id}': { get: { summary: 'Get a supported persisted resource', parameters: [{ name: 'resource', in: 'path', required: true }, { name: 'id', in: 'path', required: true }] } },
    '/api/v1/research': { post: { summary: 'Run a transient, read-only research query' } }
  }
};

export const registerV1Routes = (repository: BereanRepository): Router => {
  const router = Router();

  router.get('/health', (_req, res) => {
    res.json({ status: 'ok', api_version: 'v1', mode: 'read-only' });
  });

  router.get('/capabilities', (_req, res) => {
    res.json({
      api_version: 'v1',
      mode: 'read-only',
      implemented: ['knowledge reads', 'registry reads', 'provenance explanation', 'bounded graph neighborhood', 'transient research', 'keyword search'],
      limitations: [
        { capability: 'corpus administration', status: 'NOT_REPRESENTED', reason: 'The schema has sources and datasets but no corpus administrative resource.' },
        { capability: 'ingestion, discovery, candidates, jobs, audit, import, and export workflows', status: 'NOT_REPRESENTED', reason: 'No corresponding workflow persistence exists in the authoritative model.' },
        { capability: 'knowledge mutation', status: 'NOT_REPRESENTED', reason: 'The Explorer is intentionally read-only; claims and evidence are populated through validated SQL ingestion.' }
      ]
    });
  });

  router.get('/schema', (_req, res) => {
    res.json({
      authoritative_chain: ['source', 'dataset', 'source_record', 'citation', 'evidence', 'claim_evidence', 'claim', 'proposition'],
      projections: ['event_participation', 'claim_rendering'],
      limitations: ['No corpus, candidate, request, job, audit, or workflow tables are present.']
    });
  });

  router.get('/registry/:registry', async (req, res, next) => {
    try {
      if (req.params.registry === 'capabilities') {
        res.redirect(307, '/api/v1/capabilities');
        return;
      }
      if (!registries.has(req.params.registry)) {
        error(res, 404, 'NOT_FOUND', 'Registry was not found.');
        return;
      }
      res.json({ results: await repository.listApiResource(req.params.registry, 100) });
    } catch (exception) {
      next(exception);
    }
  });

  router.get('/search/:resource?', async (req, res, next) => {
    try {
      const query = typeof req.query.q === 'string' ? req.query.q.trim() : '';
      const requestedLimit = limit(req.query.limit);
      if (!query || query.length > 200 || !requestedLimit) {
        error(res, 400, 'INVALID_REQUEST', 'q is required (at most 200 characters) and limit must be between 1 and 100.');
        return;
      }
      const results = await repository.search(query, requestedLimit);
      const resource = req.params.resource;
      res.json({ query, results: resource ? results.filter((result) => result.type === resource.slice(0, -1)) : results, classification: 'MATCHED' });
    } catch (exception) {
      next(exception);
    }
  });

  router.post('/research', async (req: Request, res: Response, next) => {
    try {
      const question = typeof req.body?.question === 'string' ? req.body.question.trim() : '';
      const datasetIds = Array.isArray(req.body?.datasetIds) ? req.body.datasetIds : [];
      if (!question || question.length > 1000 || !datasetIds.every((id: unknown) => typeof id === 'number' && Number.isSafeInteger(id) && id > 0) || datasetIds.length > 100) {
        error(res, 400, 'INVALID_REQUEST', 'question is required and datasetIds must contain at most 100 positive integers.');
        return;
      }
      res.json(await repository.research(question, [...new Set<number>(datasetIds)]));
    } catch (exception) {
      next(exception);
    }
  });

  router.get('/research/capabilities', (_req, res) => {
    res.json({ mode: 'transient_read_only', classifications: ['ESTABLISHED', 'DERIVED', 'SCHOLARLY_CANDIDATE', 'UNRESOLVED', 'NOT_REPRESENTED', 'NO_MATCH'] });
  });

  router.get('/provenance/claim/:id', async (req, res, next) => {
    try {
      const id = positiveInteger(req.params.id);
      if (!id) return error(res, 400, 'INVALID_REQUEST', 'id must be a positive integer.');
      const result = await repository.explainProvenance({ claimId: id });
      if (!result) return error(res, 404, 'NOT_FOUND', 'Claim was not found.');
      res.json(result);
    } catch (exception) {
      next(exception);
    }
  });

  router.get('/graph/entity/:id', async (req, res, next) => {
    try {
      const id = positiveInteger(req.params.id);
      if (!id) return error(res, 400, 'INVALID_REQUEST', 'id must be a positive integer.');
      res.json(await repository.getGraphNeighborhood('entity', id));
    } catch (exception) {
      next(exception);
    }
  });

  router.get('/:resource/:id', async (req, res, next) => {
    try {
      const { resource } = req.params;
      const id = positiveInteger(req.params.id);
      if (!resources.has(resource)) return error(res, 404, 'NOT_FOUND', 'Resource was not found.');
      if (!id) return error(res, 400, 'INVALID_REQUEST', 'id must be a positive integer.');
      const result = resource === 'entities' ? await repository.getEntity(id)
        : resource === 'events' ? await repository.getEvent(id)
          : resource === 'claims' ? await repository.getClaim(id)
            : resource === 'sources' ? await repository.getSource(id)
              : await repository.getApiResource(resource, id);
      if (!result) return error(res, 404, 'NOT_FOUND', 'Resource was not found.');
      res.json(result);
    } catch (exception) {
      next(exception);
    }
  });

  router.get('/:resource', async (req, res, next) => {
    try {
      const { resource } = req.params;
      const requestedLimit = limit(req.query.limit);
      if (!resources.has(resource)) return error(res, 404, 'NOT_FOUND', 'Resource was not found.');
      if (!requestedLimit) return error(res, 400, 'INVALID_REQUEST', 'limit must be between 1 and 100.');
      res.json({ results: await repository.listApiResource(resource, requestedLimit) });
    } catch (exception) {
      next(exception);
    }
  });

  router.all('*', (req, res) => {
    error(res, 501, 'NOT_REPRESENTED', `${req.method} ${req.originalUrl} requires workflow or mutation structures not represented by the current Berean schema.`);
  });

  return router;
};

export const openApiDocument = (): object => openApi;
