import path from 'node:path';
import fs from 'node:fs/promises';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { Pool } from 'pg';
import { createApp } from '../../src/app.js';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for app tests');
}

const repoRoot = path.resolve(__dirname, '../..');
const pool = new Pool({ connectionString: databaseUrl });
const app = createApp(databaseUrl);

const runSqlFile = async (relativePath: string): Promise<void> => {
  const sql = await fs.readFile(path.join(repoRoot, relativePath), 'utf8');
  await pool.query(sql);
};

beforeAll(async () => {
  await runSqlFile('schema/sql/001_core_schema.sql');
  await runSqlFile('tests/fixtures/020-genesis-1-11-fixture.sql');
  await runSqlFile('tests/fixtures/040-stepbible-genesis-source-fixture.sql');
});

describe('read-only API', () => {
  it('searches across entities and locators', async () => {
    const response = await request(app).get('/api/search').query({ q: 'Gen.1.1', limit: 20 });
    expect(response.status).toBe(200);
    expect(response.body.results.length).toBeGreaterThan(0);
    expect(response.body.results.some((r: { type: string }) => r.type === 'citation')).toBe(true);
  });

  it('returns an entity with mapping, claims, and events', async () => {
    const entitySearch = await request(app).get('/api/search').query({ q: 'adam', limit: 50 });
    const entity = entitySearch.body.results.find((r: { type: string; key: string }) => r.type === 'entity' && r.key === 'adam');
    expect(entity).toBeTruthy();
    const response = await request(app).get(`/api/entities/${entity.id}`);
    expect(response.status).toBe(200);
    expect(response.body.entity.canonical_name.toLowerCase()).toContain('adam');
    expect(Array.isArray(response.body.claims)).toBe(true);
    expect(Array.isArray(response.body.events)).toBe(true);
  });

  it('returns claim provenance chain to source', async () => {
    const claimSearch = await request(app).get('/api/search').query({ q: 'CLAIM_MT_ADAM_FATHER_SETH', limit: 5 });
    const claim = claimSearch.body.results.find((r: { type: string }) => r.type === 'claim');
    const response = await request(app).get(`/api/claims/${claim.id}`);
    expect(response.status).toBe(200);
    expect(response.body.claim.claim_type_code).toBe('DIRECT_SOURCE_CLAIM');
    expect(response.body.evidence.some((e: { source_key?: string }) => typeof e.source_key === 'string')).toBe(true);
  });

  it('shows multiple claims for one proposition', async () => {
    const claimSearch = await request(app).get('/api/search').query({ q: 'CLAIM_MT_ADAM_FATHER_SETH', limit: 1 });
    const claim = await request(app).get(`/api/claims/${claimSearch.body.results[0].id}`);
    const propositionId = claim.body.claim.proposition_id;
    const proposition = await request(app).get(`/api/propositions/${propositionId}`);
    expect(proposition.status).toBe(200);
    expect(proposition.body.claims.length).toBeGreaterThan(1);
  });

  it('uses projected event participation in event detail', async () => {
    const eventSearch = await request(app).get('/api/search').query({ q: 'seth_begetting', limit: 5 });
    const event = eventSearch.body.results.find((r: { type: string }) => r.type === 'event');
    const response = await request(app).get(`/api/events/${event.id}`);
    expect(response.status).toBe(200);
    expect(response.body.participation.length).toBeGreaterThan(0);
  });

  it('reports genesis source-unavailable status from runtime data', async () => {
    const response = await request(app).get('/api/genesis/coverage');
    expect(response.status).toBe(200);
    expect(response.body.summary.sourceUnavailableCount).toBeGreaterThan(0);
  });

  it('keeps API read-only (no create route)', async () => {
    const response = await request(app).post('/api/claims').send({ claim_key: 'X' });
    expect(response.status).toBe(404);
  });
});
