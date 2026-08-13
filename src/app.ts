import express from 'express';
import path from 'node:path';
import { Pool } from 'pg';
import { openApiDocument, registerV1Routes } from './api/v1.js';
import { BereanRepository } from './repository.js';

const toInt = (value: string): number | null => {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? null : parsed;
};

const toStrictInt = (value: unknown): number | null => {
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return null;
  const parsed = Number.parseInt(value, 10);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
};

const homeHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Project Berean Explorer</title>
  <link rel="stylesheet" href="/public/styles.css" />
</head>
<body>
  <a class="skip-link" href="#research-heading">Skip to research</a>
  <header>
    <p class="eyebrow">Provenance-aware scholarly research</p>
    <h1>Project Berean Explorer</h1>
    <p class="subtitle">Inspect what represented sources, evidence, claims, relationships, and provenance can establish—and what remains unresolved or unrepresented.</p>
    <span class="read-only">Read-only</span>
  </header>
  <main>
    <aside class="integrity" aria-label="Research integrity">
      <strong>Research integrity.</strong> Source-backed claims, graph-derived results, scholarly observations, and unresolved material remain distinct. Results are not truth declarations.
    </aside>
    <section class="research-workspace" aria-labelledby="research-heading">
      <div>
        <p class="eyebrow">Natural-language research</p>
        <h2 id="research-heading">Ask Berean</h2>
        <p>Berean answers only from represented, persisted structures. It does not generate conclusions.</p>
        <form id="researchForm">
          <label for="researchQuestion">Research question</label>
          <div class="row">
            <input id="researchQuestion" type="search" maxlength="1000" required placeholder="Who participated in represented events?" />
            <button id="researchButton" type="submit">Research</button>
          </div>
        </form>
        <p id="researchStatus" class="status" role="status" aria-live="polite"></p>
      </div>
      <details class="scope-panel" open>
        <summary>Active research scope <span id="scopeCount">Loading…</span></summary>
        <p>Persisted datasets only. Scope selection never creates a domain or reconciles identities.</p>
        <label for="scopeFilter">Filter scopes</label>
        <input id="scopeFilter" type="search" placeholder="Filter by source or dataset" autocomplete="off" />
        <div class="scope-actions">
          <button id="selectAllScopes" type="button">Select all</button>
          <button id="clearScopes" type="button">Clear all</button>
        </div>
        <div id="scopeOptions" class="scope-options" aria-live="polite" aria-busy="true">Loading persisted scopes…</div>
        <p id="scopeEmpty" class="muted" hidden>No persisted scopes match this filter.</p>
      </details>
      <div id="researchResults" class="research-results" aria-live="polite"></div>
    </section>
    <section aria-labelledby="search-heading">
      <p class="eyebrow">Keyword search</p>
      <h2 id="search-heading">Find represented records</h2>
      <p>Matched records are search hits—not established claims.</p>
      <form id="searchForm">
        <label for="searchInput">Entities, events, claims, propositions, evidence, sources, datasets, citations, and locators</label>
        <div class="row">
          <input id="searchInput" type="search" maxlength="200" required placeholder="Try: Adam, Gen.1.1, CLAIM_MT…" />
          <button id="searchButton" type="submit">Search</button>
        </div>
      </form>
      <p id="searchStatus" class="status" role="status" aria-live="polite"></p>
      <ul id="searchResults" class="result-list"></ul>
    </section>

    <nav aria-label="Explorer sections">
      <button data-load="dashboard" type="button">Coverage / quality dashboard</button>
      <button data-load="genesis" type="button">Genesis locator coverage</button>
      <button data-load="sources" type="button">Source / Dataset / SourceRecord</button>
    </nav>

    <section aria-labelledby="detail-heading">
      <h2 id="detail-heading">Details</h2>
      <div id="detail"><p class="muted">Select a matched record or research result to inspect it.</p></div>
    </section>

    <section aria-labelledby="graph-heading">
      <h2 id="graph-heading">Bounded relationship neighborhood</h2>
      <p>Select a search result first, then expand nearby relationships from actual database edges.</p>
      <div class="row">
        <button id="expandGraph" type="button">Expand selected node neighborhood</button>
        <button id="resetGraph" type="button">Reset graph</button>
      </div>
      <label for="relationFilter">Relation filter</label>
      <input id="relationFilter" type="text" placeholder="Filter relation text" />
      <ul id="graphText" aria-live="polite"></ul>
      <button id="loadMoreGraph" type="button" hidden>Load more relationships</button>
    </section>
  </main>
  <script type="module" src="/public/app.js"></script>
</body>
</html>`;

export const createApp = (databaseUrl: string): express.Express => {
  const app = express();
  const pool = new Pool({ connectionString: databaseUrl });
  const repository = new BereanRepository(pool);

  app.disable('x-powered-by');
  app.use((_req, res, next) => {
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'");
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Referrer-Policy', 'no-referrer');
    next();
  });
  app.use(express.json({ limit: '16kb' }));
  app.use('/public', express.static(path.resolve('src/public')));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', mode: 'read-only' });
  });

  app.get('/openapi.json', (_req, res) => {
    res.json(openApiDocument());
  });

  app.get('/api-docs', (_req, res) => {
    res.type('html').send('<!doctype html><title>Project Berean API</title><h1>Project Berean API</h1><p>Machine-readable API documentation is available at <a href="/openapi.json">/openapi.json</a>.</p>');
  });

  app.use('/api/v1', registerV1Routes(repository));

  app.get('/api/research/scope', async (_req, res, next) => {
    try {
      res.json(await repository.getResearchScope());
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/research', async (req, res, next) => {
    try {
      const question = typeof req.body?.question === 'string' ? req.body.question.trim() : '';
      const rawDatasetIds = Array.isArray(req.body?.datasetIds) ? req.body.datasetIds : [];
      if (!question || question.length > 1000) {
        res.status(400).json({ error: 'question is required and must be at most 1000 characters' });
        return;
      }
      if (!rawDatasetIds.every((id: unknown) => typeof id === 'number' && Number.isSafeInteger(id) && id > 0)) {
        res.status(400).json({ error: 'datasetIds must contain positive integer identifiers' });
        return;
      }
      if (rawDatasetIds.length > 100) {
        res.status(400).json({ error: 'datasetIds must contain at most 100 identifiers' });
        return;
      }
      res.json(await repository.research(question, [...new Set<number>(rawDatasetIds)]));
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/search', async (req, res, next) => {
    try {
      const q = String(req.query.q ?? '').trim();
      if (!q) {
        res.status(400).json({ error: 'query parameter q is required' });
        return;
      }
      if (q.length > 200) {
        res.status(400).json({ error: 'query parameter q must be at most 200 characters' });
        return;
      }
      const limit = req.query.limit === undefined ? undefined : toStrictInt(req.query.limit);
      if (req.query.limit !== undefined && !limit) {
        res.status(400).json({ error: 'limit must be a positive integer' });
        return;
      }
      const results = await repository.search(q, limit ?? undefined);
      res.json({ query: q, results });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/entities/:entityId', async (req, res, next) => {
    try {
      const entityId = toInt(req.params.entityId);
      if (!entityId) {
        res.status(400).json({ error: 'entityId must be an integer' });
        return;
      }
      const entity = await repository.getEntity(entityId);
      if (!entity) {
        res.status(404).json({ error: 'entity not found' });
        return;
      }
      res.json(entity);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/claims/:claimId', async (req, res, next) => {
    try {
      const claimId = toInt(req.params.claimId);
      if (!claimId) {
        res.status(400).json({ error: 'claimId must be an integer' });
        return;
      }
      const claim = await repository.getClaim(claimId);
      if (!claim) {
        res.status(404).json({ error: 'claim not found' });
        return;
      }
      res.json(claim);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/propositions/:propositionId', async (req, res, next) => {
    try {
      const propositionId = toInt(req.params.propositionId);
      if (!propositionId) {
        res.status(400).json({ error: 'propositionId must be an integer' });
        return;
      }
      const proposition = await repository.getProposition(propositionId);
      if (!proposition) {
        res.status(404).json({ error: 'proposition not found' });
        return;
      }
      res.json(proposition);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/events/:eventId', async (req, res, next) => {
    try {
      const eventId = toInt(req.params.eventId);
      if (!eventId) {
        res.status(400).json({ error: 'eventId must be an integer' });
        return;
      }
      const event = await repository.getEvent(eventId);
      if (!event) {
        res.status(404).json({ error: 'event not found' });
        return;
      }
      res.json(event);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/sources', async (_req, res, next) => {
    try {
      const sources = await repository.listSources();
      res.json({ sources });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/sources/:sourceId', async (req, res, next) => {
    try {
      const sourceId = toInt(req.params.sourceId);
      if (!sourceId) {
        res.status(400).json({ error: 'sourceId must be an integer' });
        return;
      }
      const source = await repository.getSource(sourceId);
      if (!source) {
        res.status(404).json({ error: 'source not found' });
        return;
      }
      res.json(source);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/provenance/claims/:claimId', async (req, res, next) => {
    try {
      const claimId = toInt(req.params.claimId);
      if (!claimId) {
        res.status(400).json({ error: 'claimId must be an integer' });
        return;
      }
      const provenance = await repository.getClaimProvenance(claimId);
      res.json(provenance);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/provenance/explain', async (req, res, next) => {
    try {
      const claimIdRaw = req.query.claim_id;
      const propositionIdRaw = req.query.proposition_id;
      const claimId = claimIdRaw === undefined ? null : toStrictInt(String(claimIdRaw));
      const propositionId = propositionIdRaw === undefined ? null : toStrictInt(String(propositionIdRaw));
      const hasClaim = claimIdRaw !== undefined;
      const hasProposition = propositionIdRaw !== undefined;

      if ((hasClaim && hasProposition) || (!hasClaim && !hasProposition)) {
        res.status(400).json({ error: 'exactly one of claim_id or proposition_id is required' });
        return;
      }

      if ((hasClaim && !claimId) || (hasProposition && !propositionId)) {
        res.status(400).json({ error: 'claim_id and proposition_id must be positive integers' });
        return;
      }

      const explanation = await repository.explainProvenance({ claimId: claimId ?? undefined, propositionId: propositionId ?? undefined });
      if (!explanation) {
        res.status(404).json({ error: hasClaim ? 'claim not found' : 'proposition not found' });
        return;
      }
      res.json(explanation);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/derivations/check-eligibility', async (req, res, next) => {
    try {
      const derivationId = toStrictInt(String(req.query.derivation_id ?? ''));
      if (!derivationId) {
        res.status(400).json({ error: 'derivation_id must be a positive integer' });
        return;
      }
      const eligibility = await repository.checkDerivationEligibility(derivationId);
      if (!eligibility) {
        res.status(404).json({ error: 'derivation not found' });
        return;
      }
      res.json(eligibility);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/exploration/timeline', async (req, res, next) => {
    try {
      const entityIdRaw = req.query.entity_id;
      const entityKeyRaw = req.query.entity_key;
      const hasEntityId = entityIdRaw !== undefined;
      const hasEntityKey = entityKeyRaw !== undefined;

      if ((hasEntityId && hasEntityKey) || (!hasEntityId && !hasEntityKey)) {
        res.status(400).json({ error: 'exactly one of entity_id or entity_key is required' });
        return;
      }

      const entityId = hasEntityId ? toStrictInt(entityIdRaw) : null;
      if (hasEntityId && !entityId) {
        res.status(400).json({ error: 'entity_id must be a positive integer' });
        return;
      }

      const entityKey = hasEntityKey && typeof entityKeyRaw === 'string' ? entityKeyRaw.trim() : null;
      if (hasEntityKey && !entityKey) {
        res.status(400).json({ error: 'entity_key must be a non-empty string' });
        return;
      }

      const timeline = await repository.exploreEntityTimeline({
        entityId: entityId ?? undefined,
        entityKey: entityKey ?? undefined
      });
      if (!timeline) {
        res.status(404).json({ error: 'entity not found', coverage_status: 'NO_ENTITY_FOUND' });
        return;
      }
      res.json(timeline);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/genesis/coverage', async (_req, res, next) => {
    try {
      const coverage = await repository.getGenesisCoverage();
      res.json(coverage);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/dashboard/quality', async (_req, res, next) => {
    try {
      const dashboard = await repository.getQualityDashboard();
      res.json(dashboard);
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/graph', async (req, res, next) => {
    try {
      const nodeType = String(req.query.nodeType ?? '').trim();
      const nodeId = toInt(String(req.query.nodeId ?? ''));
      if (!['entity', 'claim'].includes(nodeType) || !nodeId) {
        res.status(400).json({ error: 'nodeType must be entity or claim and nodeId must be a positive integer' });
        return;
      }
      const graph = await repository.getGraphNeighborhood(nodeType, nodeId);
      res.json(graph);
    } catch (error) {
      next(error);
    }
  });

  app.get('*', (_req, res) => {
    res.type('html').send(homeHtml);
  });

  app.use((_error: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    res.status(500).json({ error: 'internal_error', message: 'The request could not be completed.' });
  });

  return app;
};
