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

const getClaimIdByKey = async (claimKey: string): Promise<number> => {
  const result = await pool.query('SELECT claim_id FROM claim WHERE claim_key = $1', [claimKey]);
  if (!result.rowCount) throw new Error(`Missing claim key in fixture: ${claimKey}`);
  return Number(result.rows[0].claim_id);
};

const getPropositionIdByClaimKey = async (claimKey: string): Promise<number> => {
  const result = await pool.query(
    `SELECT c.proposition_id
     FROM claim c
     WHERE c.claim_key = $1`,
    [claimKey]
  );
  if (!result.rowCount) throw new Error(`Missing proposition for claim key: ${claimKey}`);
  return Number(result.rows[0].proposition_id);
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

  it('explains complete direct claim provenance', async () => {
    const claimId = await getClaimIdByKey('CLAIM_MT_ADAM_FATHER_SETH');
    const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    expect(response.status).toBe(200);
    expect(response.body.operation).toBe('EXPLAIN_PROVENANCE');
    expect(response.body.resolution_scope).toBe('CLAIM');
    expect(response.body.claims).toHaveLength(1);
    expect(response.body.claims[0].claim.claim_type_code).toBe('DIRECT_SOURCE_CLAIM');
    expect(response.body.claims[0].provenance_status).toBe('SOURCE-BACKED');
    expect(response.body.claims[0].structural_gaps).toEqual([]);
    expect(response.body.claims[0].supporting_evidence.length).toBeGreaterThan(0);
    expect(response.body.claims[0].citations.length).toBeGreaterThan(0);
    expect(response.body.claims[0].source_records.length).toBeGreaterThan(0);
    expect(response.body.claims[0].source.length).toBeGreaterThan(0);
  });

  it('explains provenance by proposition id and returns all proposition claims', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const response = await request(app).get('/api/provenance/explain').query({ proposition_id: propositionId });
    expect(response.status).toBe(200);
    expect(response.body.resolution_scope).toBe('PROPOSITION');
    expect(response.body.claims.length).toBeGreaterThan(1);
    expect(Number(response.body.proposition.proposition_id)).toBe(propositionId);
  });

  it('reports missing ClaimEvidence for a direct claim', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
       VALUES ('PHASE21_CLAIM_MISSING_EVIDENCE', $1, 'DIRECT_SOURCE_CLAIM', 'phase21 test missing evidence')
       RETURNING claim_id`,
      [propositionId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    try {
      const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
      expect(response.status).toBe(200);
      expect(response.body.claims[0].structural_gaps).toContain('MISSING_CLAIM_EVIDENCE');
    } finally {
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
    }
  });

  it('reports missing citation when evidence is uncited', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const sourceRecord = await pool.query(`SELECT source_record_id FROM source_record ORDER BY source_record_id LIMIT 1`);
    const sourceRecordId = Number(sourceRecord.rows[0].source_record_id);
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
       VALUES ('PHASE21_CLAIM_UNCITED_EVIDENCE', $1, 'DIRECT_SOURCE_CLAIM', 'phase21 uncited evidence')
       RETURNING claim_id`,
      [propositionId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    const insertedEvidence = await pool.query(
      `INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
       VALUES ('EV_PHASE21_UNCITED', $1, 'phase21 uncited observation', 'SOURCE_OBSERVATION')
       RETURNING evidence_id`,
      [sourceRecordId]
    );
    const evidenceId = Number(insertedEvidence.rows[0].evidence_id);
    await pool.query(
      `INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
       VALUES ($1, $2, 'SUPPORTS')`,
      [claimId, evidenceId]
    );
    try {
      const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
      expect(response.status).toBe(200);
      expect(response.body.claims[0].structural_gaps).toContain('MISSING_CITATION');
      expect(response.body.claims[0].source_chain.length).toBeGreaterThan(0);
    } finally {
      await pool.query(`DELETE FROM claim_evidence WHERE claim_id = $1`, [claimId]);
      await pool.query(`DELETE FROM evidence WHERE evidence_id = $1`, [evidenceId]);
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
    }
  });

  it('explains projected event participation rows for asserting claims', async () => {
    const claimId = await getClaimIdByKey('CLAIM_MT_GEN_1_1_GOD_SUBJECT_CREATION');
    const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    expect(response.status).toBe(200);
    expect(response.body.claims[0].projected_relationships.length).toBeGreaterThan(0);
    expect(Number(response.body.claims[0].projected_relationships[0].asserting_claim_id)).toBe(claimId);
  });

  it('explains structurally valid derived claims', async () => {
    const claimId = await getClaimIdByKey('CLAIM_MT_ENOSH_YEAR_DERIVED');
    const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    expect(response.status).toBe(200);
    expect(response.body.claims[0].claim.claim_type_code).toBe('DERIVED_CLAIM');
    expect(response.body.claims[0].derivation).toBeTruthy();
    expect(response.body.claims[0].derivation_inputs.length).toBeGreaterThan(0);
    expect(response.body.claims[0].structural_gaps).not.toContain('MISSING_DERIVATION_INPUT');
  });

  it('reports missing derivation input for derived claims with no inputs', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const insertedDerivation = await pool.query(
      `INSERT INTO derivation (method, assumptions)
       VALUES ('phase21 test method', 'phase21 test assumptions')
       RETURNING derivation_id`
    );
    const derivationId = Number(insertedDerivation.rows[0].derivation_id);
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id, statement)
       VALUES ('PHASE21_DERIVED_NO_INPUT', $1, 'DERIVED_CLAIM', $2, 'phase21 derived no input')
       RETURNING claim_id`,
      [propositionId, derivationId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    try {
      const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
      expect(response.status).toBe(200);
      expect(response.body.claims[0].structural_gaps).toContain('MISSING_DERIVATION_INPUT');
    } finally {
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
      await pool.query(`DELETE FROM derivation WHERE derivation_id = $1`, [derivationId]);
    }
  });

  it('reports self-input derivation for derived claims', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const insertedDerivation = await pool.query(
      `INSERT INTO derivation (method, assumptions)
       VALUES ('phase21 self-input method', 'phase21 self-input assumptions')
       RETURNING derivation_id`
    );
    const derivationId = Number(insertedDerivation.rows[0].derivation_id);
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id, statement)
       VALUES ('PHASE21_DERIVED_SELF_INPUT', $1, 'DERIVED_CLAIM', $2, 'phase21 derived self input')
       RETURNING claim_id`,
      [propositionId, derivationId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    await pool.query(
      `INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
       VALUES ($1, $2, 'self input phase21')`,
      [derivationId, claimId]
    );
    try {
      const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
      expect(response.status).toBe(200);
      expect(response.body.claims[0].structural_gaps).toContain('SELF_INPUT_DERIVATION');
    } finally {
      await pool.query(`DELETE FROM derivation_input WHERE derivation_id = $1`, [derivationId]);
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
      await pool.query(`DELETE FROM derivation WHERE derivation_id = $1`, [derivationId]);
    }
  });

  it('returns 400 for invalid explain-provenance input and 404 for nonexistent artifacts', async () => {
    const both = await request(app).get('/api/provenance/explain').query({ claim_id: 1, proposition_id: 1 });
    expect(both.status).toBe(400);
    const missing = await request(app).get('/api/provenance/explain');
    expect(missing.status).toBe(400);
    const invalid = await request(app).get('/api/provenance/explain').query({ claim_id: 'abc' });
    expect(invalid.status).toBe(400);
    const nonexistentClaim = await request(app).get('/api/provenance/explain').query({ claim_id: 999999999 });
    expect(nonexistentClaim.status).toBe(404);
    const nonexistentProposition = await request(app).get('/api/provenance/explain').query({ proposition_id: 999999999 });
    expect(nonexistentProposition.status).toBe(404);
  });
});
