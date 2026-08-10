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

const getDerivationIdByClaimKey = async (claimKey: string): Promise<number> => {
  const result = await pool.query(
    `SELECT derivation_id
     FROM claim
     WHERE claim_key = $1`,
    [claimKey]
  );
  if (!result.rowCount || result.rows[0].derivation_id === null) {
    throw new Error(`Missing derivation for fixture claim key: ${claimKey}`);
  }
  return Number(result.rows[0].derivation_id);
};

const snapshotPersistentTableCounts = async (): Promise<Record<string, number>> => {
  const tables = await pool.query(
    `SELECT table_name
     FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
     ORDER BY table_name`
  );
  const counts = await Promise.all(
    tables.rows.map(async ({ table_name }: { table_name: string }) => {
      if (!/^[a-z_]+$/.test(table_name)) throw new Error(`Unexpected table name: ${table_name}`);
      const result = await pool.query(`SELECT COUNT(*)::int AS count FROM "${table_name}"`);
      return [table_name, Number(result.rows[0].count)] as const;
    })
  );
  return Object.fromEntries(counts);
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
    const before = await snapshotPersistentTableCounts();
    const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    const after = await snapshotPersistentTableCounts();
    expect(response.status).toBe(200);
    expect(after).toEqual(before);
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
    expect(response.body.claims[0].citations[0].quoted_text_status).toBe('NOT_STORED_BY_POLICY');
    expect(response.body.claims[0].source_records[0].raw_content_status).toBe('NOT_STORED_BY_POLICY');
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

  it('reports missing derivation for derived claims without derivation metadata', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
       VALUES ('PHASE21_DERIVED_NO_DERIVATION', $1, 'DERIVED_CLAIM', 'phase21 derived no derivation')
       RETURNING claim_id`,
      [propositionId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    try {
      const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
      expect(response.status).toBe(200);
      expect(response.body.claims[0].structural_gaps).toContain('MISSING_DERIVATION');
    } finally {
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
    }
  });

  it('reports missing proposition claim for an unasserted proposition', async () => {
    const entities = await pool.query(
      `SELECT entity_id
       FROM entity
       WHERE entity_type_code = 'PERSON'
       ORDER BY entity_id
       LIMIT 2`
    );
    if (entities.rowCount !== 2) throw new Error('Fixture must contain two person entities');
    const insertedProposition = await pool.query(
      `INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
       VALUES ($1, 'fatherOf', $2)
       RETURNING proposition_id`,
      [entities.rows[0].entity_id, entities.rows[1].entity_id]
    );
    const propositionId = Number(insertedProposition.rows[0].proposition_id);
    try {
      const response = await request(app).get('/api/provenance/explain').query({ proposition_id: propositionId });
      expect(response.status).toBe(200);
      expect(response.body.claims).toEqual([]);
      expect(response.body.structural_gaps).toContain('MISSING_PROPOSITION_CLAIM');
    } finally {
      await pool.query(`DELETE FROM proposition WHERE proposition_id = $1`, [propositionId]);
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

  it('checks an accepted derivation structurally without interpreting its method', async () => {
    const expectedCheckIds = [
      'DERIVATION_EXISTS',
      'DERIVED_CLAIM_EXISTS',
      'DERIVED_CLAIM_TYPE_VALID',
      'DERIVATION_LINK_VALID',
      'METHOD_PRESENT',
      'ASSUMPTIONS_PRESENT',
      'DERIVATION_INPUT_EXISTS',
      'DERIVATION_INPUT_KIND_VALID',
      'DERIVATION_INPUT_REFERENCE_VALID',
      'INPUT_PROVENANCE_STRUCTURALLY_COMPLETE',
      'SELF_INPUT_ABSENT',
      'TARGET_PROPOSITION_EXISTS',
      'TARGET_PREDICATE_VALID',
      'TARGET_TERM_KINDS_VALID'
    ];
    const derivationId = await getDerivationIdByClaimKey('CLAIM_MT_ENOSH_YEAR_DERIVED');
    const before = await snapshotPersistentTableCounts();
    const response = await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: derivationId });
    const after = await snapshotPersistentTableCounts();

    expect(response.status).toBe(200);
    expect(after).toEqual(before);
    expect(response.body.operation).toBe('CHECK_DERIVATION_ELIGIBILITY');
    expect(response.body.structurally_eligible).toBe(true);
    expect(response.body.license_status).toBe('REQUIRES_HUMAN_METHOD_JUSTIFICATION');
    expect(response.body.read_only).toBe(true);
    expect(response.body.explanation).toContain('structural eligibility');
    expect(response.body.derivation.method).toContain('Cumulative addition');
    expect(response.body.input_status.length).toBeGreaterThan(0);
    expect(response.body.checks.map((check: { id: string }) => check.id)).toEqual(expectedCheckIds);
    expect(response.body.checks.every((check: { status: string }) => check.status === 'PASS')).toBe(true);
    expect(response.body.limitations).toContain('Structural eligibility is not logical entailment.');
  });

  it('reports missing linkage and inputs for structurally incomplete temporary derivations', async () => {
    const unlinked = await pool.query(
      `INSERT INTO derivation (method, assumptions)
       VALUES ('The inputs entail the conclusion', 'All premises are necessarily valid')
       RETURNING derivation_id`
    );
    const unlinkedDerivationId = Number(unlinked.rows[0].derivation_id);
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const linked = await pool.query(
      `INSERT INTO derivation (method, assumptions)
       VALUES ('temporary method', 'temporary assumptions')
       RETURNING derivation_id`
    );
    const linkedDerivationId = Number(linked.rows[0].derivation_id);
    const linkedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
       VALUES ('PHASE23_DERIVED_NO_INPUT', $1, 'DERIVED_CLAIM', $2)
       RETURNING claim_id`,
      [propositionId, linkedDerivationId]
    );
    try {
      const unlinkedResponse = await request(app)
        .get('/api/derivations/check-eligibility')
        .query({ derivation_id: unlinkedDerivationId });
      const linkedResponse = await request(app)
        .get('/api/derivations/check-eligibility')
        .query({ derivation_id: linkedDerivationId });
      const unlinkedCheck = unlinkedResponse.body.checks.find((check: { id: string }) => check.id === 'DERIVED_CLAIM_EXISTS');
      const inputCheck = linkedResponse.body.checks.find((check: { id: string }) => check.id === 'DERIVATION_INPUT_EXISTS');

      expect(unlinkedResponse.status).toBe(200);
      expect(unlinkedResponse.body.derivation.method).toBe('The inputs entail the conclusion');
      expect(unlinkedResponse.body.derivation.assumptions).toBe('All premises are necessarily valid');
      expect(unlinkedCheck.status).toBe('FAIL');
      expect(unlinkedResponse.body.explanation).toContain('structural eligibility failures');
      expect(linkedResponse.status).toBe(200);
      expect(linkedResponse.body.structurally_eligible).toBe(false);
      expect(inputCheck.status).toBe('FAIL');
    } finally {
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [linkedClaim.rows[0].claim_id]);
      await pool.query(`DELETE FROM derivation WHERE derivation_id IN ($1, $2)`, [unlinkedDerivationId, linkedDerivationId]);
    }
  });

  it('reports self-input as structurally ineligible', async () => {
    const propositionId = await getPropositionIdByClaimKey('CLAIM_MT_ADAM_FATHER_SETH');
    const insertedDerivation = await pool.query(
      `INSERT INTO derivation (method, assumptions) VALUES ('temporary method', 'temporary assumptions') RETURNING derivation_id`
    );
    const derivationId = Number(insertedDerivation.rows[0].derivation_id);
    const insertedClaim = await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
       VALUES ('PHASE23_DERIVED_SELF_INPUT', $1, 'DERIVED_CLAIM', $2)
       RETURNING claim_id`,
      [propositionId, derivationId]
    );
    const claimId = Number(insertedClaim.rows[0].claim_id);
    await pool.query(
      `INSERT INTO derivation_input (derivation_id, input_claim_id) VALUES ($1, $2)`,
      [derivationId, claimId]
    );
    try {
      const response = await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: derivationId });
      expect(response.status).toBe(200);
      expect(response.body.structurally_eligible).toBe(false);
      expect(response.body.checks.find((check: { id: string }) => check.id === 'SELF_INPUT_ABSENT').status).toBe('FAIL');
    } finally {
      await pool.query(`DELETE FROM derivation_input WHERE derivation_id = $1`, [derivationId]);
      await pool.query(`DELETE FROM claim WHERE claim_id = $1`, [claimId]);
      await pool.query(`DELETE FROM derivation WHERE derivation_id = $1`, [derivationId]);
    }
  });

  it('returns 400 for invalid eligibility input and 404 for a missing derivation', async () => {
    expect((await request(app).get('/api/derivations/check-eligibility')).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: '' })).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: 'abc' })).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: '1.5' })).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: 0 })).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: -1 })).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility?derivation_id=1&derivation_id=2')).status).toBe(400);
    expect((await request(app).get('/api/derivations/check-eligibility').query({ derivation_id: 999999999 })).status).toBe(404);
  });

  it('returns 400 for invalid explain-provenance input and 404 for nonexistent artifacts', async () => {
    const both = await request(app).get('/api/provenance/explain').query({ claim_id: 1, proposition_id: 1 });
    expect(both.status).toBe(400);
    const missing = await request(app).get('/api/provenance/explain');
    expect(missing.status).toBe(400);
    const invalid = await request(app).get('/api/provenance/explain').query({ claim_id: 'abc' });
    expect(invalid.status).toBe(400);
    const zeroClaim = await request(app).get('/api/provenance/explain').query({ claim_id: 0 });
    expect(zeroClaim.status).toBe(400);
    const negativeClaim = await request(app).get('/api/provenance/explain').query({ claim_id: -1 });
    expect(negativeClaim.status).toBe(400);
    const zeroProposition = await request(app).get('/api/provenance/explain').query({ proposition_id: 0 });
    expect(zeroProposition.status).toBe(400);
    const negativeProposition = await request(app).get('/api/provenance/explain').query({ proposition_id: -1 });
    expect(negativeProposition.status).toBe(400);
    const nonexistentClaim = await request(app).get('/api/provenance/explain').query({ claim_id: 999999999 });
    expect(nonexistentClaim.status).toBe(404);
    const nonexistentProposition = await request(app).get('/api/provenance/explain').query({ proposition_id: 999999999 });
    expect(nonexistentProposition.status).toBe(404);
  });
});
