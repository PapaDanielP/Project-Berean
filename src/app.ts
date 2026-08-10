import express from 'express';
import path from 'node:path';
import { Pool } from 'pg';
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
  <title>Project Berean Explorer (Read-only MVP)</title>
  <link rel="stylesheet" href="/public/styles.css" />
</head>
<body>
  <header>
    <h1>Project Berean Explorer</h1>
    <p class="subtitle">Read-only exploration of claims, propositions, evidence, and provenance.</p>
  </header>
  <main>
    <section aria-labelledby="search-heading">
      <h2 id="search-heading">Global search</h2>
      <label for="searchInput">Search entities, events, claims, propositions, evidence, sources, datasets, citations, and locators</label>
      <div class="row">
        <input id="searchInput" type="search" placeholder="Try: Adam, Gen.1.1, CLAIM_MT..." />
        <button id="searchButton" type="button">Search</button>
      </div>
      <ul id="searchResults" aria-live="polite"></ul>
    </section>

    <nav aria-label="Explorer sections">
      <button data-load="dashboard" type="button">Coverage / quality dashboard</button>
      <button data-load="genesis" type="button">Genesis locator coverage</button>
      <button data-load="sources" type="button">Source / Dataset / SourceRecord</button>
    </nav>

    <section aria-labelledby="detail-heading">
      <h2 id="detail-heading">Details</h2>
      <div id="detail"></div>
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
    </section>
  </main>
  <script type="module" src="/public/app.js"></script>
</body>
</html>`;

export const createApp = (databaseUrl: string): express.Express => {
  const app = express();
  const pool = new Pool({ connectionString: databaseUrl });
  const repository = new BereanRepository(pool);

  app.use(express.json());
  app.use('/public', express.static(path.resolve('src/public')));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', mode: 'read-only' });
  });

  app.get('/api/search', async (req, res, next) => {
    try {
      const q = String(req.query.q ?? '').trim();
      if (!q) {
        res.status(400).json({ error: 'query parameter q is required' });
        return;
      }
      const limit = req.query.limit ? Number.parseInt(String(req.query.limit), 10) : undefined;
      const results = await repository.search(q, limit);
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
      if (!nodeType || !nodeId) {
        res.status(400).json({ error: 'nodeType and nodeId are required' });
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

  app.use((error: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    res.status(500).json({ error: 'internal_error', message: error.message });
  });

  return app;
};
