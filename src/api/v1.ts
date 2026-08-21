import { Router, type Request, type Response } from 'express';
import { BereanRepository } from '../repository.js';
import type { SearchType } from '../types.js';

const resources = new Set([
  'entities', 'events', 'claims', 'evidence', 'sources', 'datasets',
  'source-records', 'citations', 'identities', 'identity-mappings'
]);
const registries = new Set([
  'predicates', 'entity-types', 'event-types', 'claim-types', 'evidence-types', 'mapping-statuses'
]);

// Search filters are normalized explicitly. Plural route segments never map to search
// result types by string slicing, and unrepresented filters never return a silent empty list.
const searchResourceTypes: Record<string, SearchType> = {
  entities: 'entity',
  events: 'event',
  claims: 'claim',
  propositions: 'proposition',
  evidence: 'evidence',
  sources: 'source',
  datasets: 'dataset',
  'source-records': 'source_record',
  citations: 'citation',
  identities: 'source_identity'
};

// Supported persisted resources that keyword search does not index.
const unsearchableResources = new Set(['identity-mappings']);

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

export const registerV1Routes = (repository: BereanRepository): Router => {
  const router = Router();

  router.get('/health', (_req, res) => {
    res.json({ status: 'ok', api_version: 'v1', mode: 'read-only' });
  });

  router.get('/capabilities', (_req, res) => {
    res.json({
      api_version: 'v1',
      mode: 'read-only explorer with authorized administration',
      implemented: [
        'knowledge reads', 'registry reads', 'provenance explanation', 'bounded graph neighborhood',
        'transient research', 'keyword search', 'corpus and topic administration',
        'candidate-only discovery and review', 'source and citation registration',
        'controlled evidence and claim authoring', 'idempotent ingestion, validation, and export jobs',
        'append-only audit and optimistic concurrency'
      ],
      limitations: [
        { capability: 'external retrieval', status: 'NOT_REPRESENTED', reason: 'The API records locators but intentionally provides no arbitrary URL-fetch capability.' },
        { capability: 'truth confirmation and arbitrary registry mutation', status: 'NOT_REPRESENTED', reason: 'Claims remain assertions and registry changes require reviewed migrations.' }
      ]
    });
  });

  router.get('/schema', (_req, res) => {
    res.json({
      authoritative_chain: ['source', 'dataset', 'source_record', 'citation', 'evidence', 'claim_evidence', 'claim', 'proposition'],
      projections: ['event_participation', 'claim_rendering'],
      workflow_boundary: ['corpus', 'research_topic', 'discovery_request', 'discovery_candidate', 'candidate_review', 'asynchronous_job', 'validation_run', 'export_job', 'audit_event'],
      limitations: ['Workflow records coordinate administration and never replace authoritative propositions, evidence, source records, or identity mappings.']
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
      const resource = req.params.resource;
      if (resource !== undefined && unsearchableResources.has(resource)) {
        error(res, 501, 'NOT_REPRESENTED', `Keyword search does not index ${resource}; absence of a search filter is not falsity. Read the resource through /api/v1/${resource}.`);
        return;
      }
      const resourceType = resource === undefined ? null : searchResourceTypes[resource] ?? null;
      if (resource !== undefined && !resourceType) {
        error(res, 404, 'NOT_FOUND', `Search resource filter was not found. Supported filters: ${Object.keys(searchResourceTypes).join(', ')}.`);
        return;
      }
      const results = resourceType
        ? await repository.searchByType(query, resourceType, requestedLimit)
        : await repository.search(query, requestedLimit);
      res.json({
        query,
        resource: resource ?? null,
        resource_type: resourceType,
        results,
        classification: results.length ? 'MATCHED' : 'NO_MATCH',
        limitation: results.length
          ? 'Matched records are lexical search hits, not established claims.'
          : 'NO_MATCH reports that no persisted record matched this term. It is not a denial of the searched subject.'
      });
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
