import path from 'node:path';
import fs from 'node:fs/promises';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Pool } from 'pg';
import { createApp } from '../../src/app.js';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for research determinism tests');
}

const repoRoot = path.resolve(__dirname, '../..');

// Two isolated schemas stand in for two logically equivalent fresh database reloads. They are
// loaded from the same schema definition and the same fixture, so their knowledge content is
// identical; only their generated surrogate identifiers differ.
const SCHEMA_A = 'research_reload_a';
const SCHEMA_B = 'research_reload_b';

const TESLA_QUESTION = 'In which represented events does Nikola Tesla participate?';

const adminPool = new Pool({ connectionString: databaseUrl });

const schemaConnectionString = (schema: string): string => {
  const url = new URL(databaseUrl);
  url.searchParams.set('options', `-c search_path=${schema}`);
  return url.toString();
};

const poolFor = (schema: string): Pool =>
  new Pool({ connectionString: databaseUrl, options: `-c search_path=${schema}` });

const poolA = poolFor(SCHEMA_A);
const poolB = poolFor(SCHEMA_B);
const appA = createApp(schemaConnectionString(SCHEMA_A), []);

const runSqlFile = async (pool: Pool, relativePath: string): Promise<void> => {
  const sql = await fs.readFile(path.join(repoRoot, relativePath), 'utf8');
  await pool.query(sql);
};

const loadReload = async (pool: Pool, schema: string): Promise<void> => {
  await adminPool.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
  await adminPool.query(`CREATE SCHEMA ${schema}`);
  await runSqlFile(pool, 'schema/sql/001_core_schema.sql');
  await runSqlFile(pool, 'tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql');
};

/**
 * Reissues the generated claim identifiers for the named claims in the given order, keeping every
 * persisted knowledge value (claim key, proposition, type, status, statement, notes, derivation and
 * claim-evidence links) unchanged. This models a fresh reload whose identity allocation happened to
 * differ, which is exactly the condition that produced the reported ordering defect.
 */
const reissueClaimIdentities = async (pool: Pool, claimKeys: string[]): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const claims = await client.query(
      `SELECT claim_key, proposition_id, claim_type_code, claim_status_code, statement, notes, derivation_id
       FROM claim
       WHERE claim_key = ANY($1::text[])`,
      [claimKeys]
    );
    if (claims.rowCount !== claimKeys.length) {
      throw new Error('Fixture is missing one of the claims selected for identity reissue.');
    }
    const links = await client.query(
      `SELECT c.claim_key, e.evidence_key, ce.relation_type_code, ce.notes
       FROM claim_evidence ce
       JOIN claim c ON c.claim_id = ce.claim_id
       JOIN evidence e ON e.evidence_id = ce.evidence_id
       WHERE c.claim_key = ANY($1::text[])`,
      [claimKeys]
    );
    await client.query(
      `DELETE FROM claim_evidence
       WHERE claim_id IN (SELECT claim_id FROM claim WHERE claim_key = ANY($1::text[]))`,
      [claimKeys]
    );
    await client.query('DELETE FROM claim WHERE claim_key = ANY($1::text[])', [claimKeys]);
    for (const claimKey of claimKeys) {
      const row = claims.rows.find((candidate) => candidate.claim_key === claimKey);
      if (!row) throw new Error(`Missing claim row for ${claimKey}`);
      await client.query(
        `INSERT INTO claim (claim_key, proposition_id, claim_type_code, claim_status_code, statement, notes, derivation_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [row.claim_key, row.proposition_id, row.claim_type_code, row.claim_status_code, row.statement, row.notes, row.derivation_id]
      );
    }
    for (const link of links.rows) {
      await client.query(
        `INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
         SELECT c.claim_id, e.evidence_id, $3, $4
         FROM claim c
         JOIN evidence e ON e.evidence_key = $2
         WHERE c.claim_key = $1`,
        [link.claim_key, link.evidence_key, link.relation_type_code, link.notes]
      );
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

type ResearchRow = Record<string, unknown>;

/** Externally observable, durable projection of a research response: never generated identifiers. */
const durableProjection = (body: Record<string, unknown>): Record<string, unknown> => {
  const results = (body.results as ResearchRow[]).map((result) => ({
    claim_key: result.claim_key,
    evidence_key: result.evidence_key,
    evidence_relation_type_code: result.evidence_relation_type_code,
    dataset_key: result.dataset_key,
    source_key: result.source_key,
    predicate: result.predicate,
    claim_type_code: result.claim_type_code,
    claim_status_code: result.claim_status_code,
    classification: result.classification,
    rendered_proposition: result.rendered_proposition
  }));
  const plan = body.plan as Record<string, unknown>;
  const subjectResolution = plan.subject_resolution as Record<string, unknown>;
  return {
    capability: body.capability,
    interpretation: body.interpretation,
    limitation: body.limitation,
    classification: plan.classification,
    traversal_shape: plan.traversal_shape,
    candidate_predicates: plan.candidate_predicates,
    subject_status: subjectResolution.status,
    subject_resolved_kind: subjectResolution.resolved_kind ?? null,
    subject_resolved_from: subjectResolution.resolved_from ?? null,
    bounded: body.bounded,
    results
  };
};

const claimKeySequence = (body: Record<string, unknown>): unknown[] =>
  (body.results as ResearchRow[]).map((result) => result.claim_key);

const claimIdsByKey = async (pool: Pool, claimKeys: string[]): Promise<Record<string, number>> => {
  const result = await pool.query('SELECT claim_key, claim_id FROM claim WHERE claim_key = ANY($1::text[])', [claimKeys]);
  return Object.fromEntries(result.rows.map((row) => [row.claim_key as string, Number(row.claim_id)]));
};

beforeAll(async () => {
  await loadReload(poolA, SCHEMA_A);
  await loadReload(poolB, SCHEMA_B);
  // Reload B allocates the two Tesla participation claims in the opposite identity order.
  await reissueClaimIdentities(poolB, [
    'CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT',
    'CLAIM_P37R_TESLA_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT'
  ]);
}, 120_000);

afterAll(async () => {
  // Leave the database exactly as the suite found it so other suites and the PostgreSQL
  // validation script never observe these temporary reload schemas.
  await adminPool.query(`DROP SCHEMA IF EXISTS ${SCHEMA_A} CASCADE`);
  await adminPool.query(`DROP SCHEMA IF EXISTS ${SCHEMA_B} CASCADE`);
});

describe('deterministic research ordering', () => {
  it('returns the same ordering for repeated identical requests against the same database', async () => {
    const first = await request(appA).post('/api/research').send({ question: TESLA_QUESTION });
    const second = await request(appA).post('/api/research').send({ question: TESLA_QUESTION });

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect(second.body.capability).toBe(first.body.capability);
    expect(claimKeySequence(second.body)).toEqual(claimKeySequence(first.body));
    expect(second.body.bounded).toEqual(first.body.bounded);
    expect(first.body.bounded.order).toEqual([
      'claim_key',
      'evidence_key',
      'evidence_relation_type_code',
      'dataset_key',
      'source_key'
    ]);
    expect(first.body.bounded.ordering_stable).toBe(true);
  });

  it('returns identical ordering through /api/research and /api/v1/research', async () => {
    const legacy = await request(appA).post('/api/research').send({ question: TESLA_QUESTION });
    const versioned = await request(appA).post('/api/v1/research').send({ question: TESLA_QUESTION });

    expect(legacy.status).toBe(200);
    expect(versioned.status).toBe(200);
    expect(durableProjection(versioned.body)).toEqual(durableProjection(legacy.body));
    expect(claimKeySequence(versioned.body)).toEqual(claimKeySequence(legacy.body));
  });

  it('produces the same ordered results across logically equivalent fresh reloads', async () => {
    const teslaClaimKeys = [
      'CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT',
      'CLAIM_P37R_TESLA_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT'
    ];
    const idsA = await claimIdsByKey(poolA, teslaClaimKeys);
    const idsB = await claimIdsByKey(poolB, teslaClaimKeys);
    // The two reloads must disagree about generated-identifier order, otherwise this test could
    // pass even if ordering still depended on generated ids.
    const orderA = idsA[teslaClaimKeys[0]] < idsA[teslaClaimKeys[1]];
    const orderB = idsB[teslaClaimKeys[0]] < idsB[teslaClaimKeys[1]];
    expect(orderA).not.toBe(orderB);

    const appB = createApp(schemaConnectionString(SCHEMA_B), []);
    const reloadA = await request(appA).post('/api/research').send({ question: TESLA_QUESTION });
    const reloadB = await request(appB).post('/api/research').send({ question: TESLA_QUESTION });

    expect(reloadA.status).toBe(200);
    expect(reloadB.status).toBe(200);
    expect(durableProjection(reloadB.body)).toEqual(durableProjection(reloadA.body));
    expect(claimKeySequence(reloadB.body)).toEqual(claimKeySequence(reloadA.body));
  });

  it('keeps the Nikola Tesla participation ordering stable across equivalent fresh reloads', async () => {
    const appB = createApp(schemaConnectionString(SCHEMA_B), []);
    const reloadA = await request(appA).post('/api/research').send({ question: TESLA_QUESTION });
    const reloadB = await request(appB).post('/api/research').send({ question: TESLA_QUESTION });

    const expectedOrder = [
      { claim_key: 'CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT', evidence_key: 'EV_P37R_BARRETT_TESLA' },
      { claim_key: 'CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT', evidence_key: 'EV_P37R_ELECTRICAL_INDUSTRIES_TESLA' },
      { claim_key: 'CLAIM_P37R_TESLA_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', evidence_key: 'EV_P37R_BARRETT_WESTINGHOUSE' }
    ];
    const observed = (body: Record<string, unknown>) =>
      (body.results as ResearchRow[]).map((result) => ({
        claim_key: result.claim_key,
        evidence_key: result.evidence_key
      }));

    expect(reloadA.body.capability).toBe('ESTABLISHED');
    expect(reloadB.body.capability).toBe('ESTABLISHED');
    expect(observed(reloadA.body)).toEqual(expectedOrder);
    expect(observed(reloadB.body)).toEqual(expectedOrder);
  });
});
