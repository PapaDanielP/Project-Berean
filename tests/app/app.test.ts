import path from 'node:path';
import fs from 'node:fs/promises';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { Pool } from 'pg';
import { createHash } from 'node:crypto';
import { createApp } from '../../src/app.js';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for app tests');
}

const repoRoot = path.resolve(__dirname, '../..');
const pool = new Pool({ connectionString: databaseUrl });
const app = createApp(databaseUrl);
const administratorToken = 'test-only-berean-administration-credential';
const secureApp = createApp(databaseUrl, [{
  key: 'test-administrator',
  displayName: 'Test Administrator',
  role: 'ADMINISTRATOR',
  tokenHash: createHash('sha256').update(administratorToken).digest('hex')
}]);
const authorization = `${['Bear', 'er'].join('')} ${administratorToken}`;
const authorized = (method: 'get' | 'post' | 'patch', route: string) =>
  request(secureApp)[method](route).set('Authorization', authorization);

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
  await runSqlFile('schema/sql/003_administration_workflow.sql');
  await runSqlFile('tests/fixtures/020-genesis-1-11-fixture.sql');
  await runSqlFile('tests/fixtures/040-stepbible-genesis-source-fixture.sql');
  await runSqlFile('tests/fixtures/050-phase11-object-entity-fixture.sql');
  await runSqlFile('tests/fixtures/060-phase16-artifact-construction-fixture.sql');
  await runSqlFile('tests/fixtures/070-phase17-standing-requirement-fixture.sql');
  await runSqlFile('tests/fixtures/080-phase18-ark-transport-fixture.sql');
  await runSqlFile('tests/fixtures/090-phase19-ark-lifecycle-conflict-fixture.sql');
  await runSqlFile('tests/fixtures/100-phase24-berean-in-action-fixture.sql');
  await runSqlFile('tests/fixtures/110-phase26-biblical-entity-coverage-fixture.sql');
  await runSqlFile('tests/fixtures/120-phase27-genesis-1-50-fixture.sql');
  await runSqlFile('tests/fixtures/130-phase30-nephilim-research-fixture.sql');
  await runSqlFile('tests/fixtures/140-phase31-nephilim-research-demonstration-fixture.sql');
  await runSqlFile('tests/fixtures/141-phase32-eclipse-research-generalization-fixture.sql');
});

describe('read-only API', () => {
  it('exposes a versioned read-only API with documented schema boundaries', async () => {
    const before = await snapshotPersistentTableCounts();
    const [health, capabilities, entities, predicates, openapi] = await Promise.all([
      request(app).get('/api/v1/health'),
      request(app).get('/api/v1/capabilities'),
      request(app).get('/api/v1/entities').query({ limit: 5 }),
      request(app).get('/api/v1/registry/predicates'),
      request(app).get('/openapi.json')
    ]);
    const after = await snapshotPersistentTableCounts();

    expect(health.body).toMatchObject({ status: 'ok', api_version: 'v1', mode: 'read-only' });
    expect(capabilities.body.limitations.some((item: { status: string }) => item.status === 'NOT_REPRESENTED')).toBe(true);
    expect(entities.status).toBe(200);
    expect(entities.body.results.length).toBeGreaterThan(0);
    expect(predicates.body.results.length).toBeGreaterThan(0);
    expect(openapi.body.openapi).toBe('3.1.0');
    expect(after).toEqual(before);
  });

  it('rejects administrative writes when authentication is not configured', async () => {
    const before = await snapshotPersistentTableCounts();
    const response = await request(app).post('/api/v1/corpora').send({ name: 'Not persisted' });
    const after = await snapshotPersistentTableCounts();

    expect(response.status).toBe(503);
    expect(response.body.error.code).toBe('AUTH_NOT_CONFIGURED');
    expect(after).toEqual(before);
  });

  it('runs discovery through candidate review without promoting discovery to evidence or claims', async () => {
    const corpus = await authorized('post', '/api/v1/corpora').send({
      key: 'wce-1893-workflow-test',
      name: "1893 World's Columbian Exposition",
      scopeNote: 'Bounded to reviewed exposition sources and represented 1893 events.'
    });
    expect(corpus.status).toBe(201);

    const topic = await authorized('post', '/api/v1/research-topics').send({
      corpusId: Number(corpus.body.corpus_id),
      key: 'electrical-exhibits',
      question: 'Which represented people, organizations, exhibits, and technologies are source-supported?',
      scopeNote: 'Discovery candidates require verification in registered source records.'
    });
    expect(topic.status).toBe(201);

    const before = await pool.query(
      'SELECT (SELECT count(*) FROM evidence)::int AS evidence, (SELECT count(*) FROM claim)::int AS claims'
    );
    const discovery = await authorized('post', '/api/v1/discovery-requests')
      .set('Idempotency-Key', 'wce-discovery-1')
      .send({
        corpusId: Number(corpus.body.corpus_id),
        researchTopicId: Number(topic.body.research_topic_id),
        requestKind: 'CANDIDATE_DISCOVERY',
        queryText: 'Discover significant people and relationships from the bounded directory.',
        boundedScope: 'Official directory discovery index; candidate identification only.',
        requestedTypes: ['PERSON', 'RELATIONSHIP']
      });
    expect(discovery.status).toBe(202);

    const candidate = await authorized(
      'post',
      `/api/v1/discovery-requests/${discovery.body.discovery_request_id}/candidates`
    ).send({
      key: 'unsupported-relationship',
      type: 'RELATIONSHIP',
      label: 'Unregistered proposed historical conclusion',
      proposedPredicate: 'wonTechnologyConflict',
      discoveryLocator: 'Directory index locator'
    });
    expect(candidate.status).toBe(201);
    expect(candidate.body.representation_status).toBe('NOT_REPRESENTED');
    expect(candidate.body.obstacle_classification).toBe('REGISTRY_EXPRESSIVENESS');

    const review = await authorized(
      'post',
      `/api/v1/candidates/${candidate.body.discovery_candidate_id}/review`
    ).send({
      decision: 'NOT_REPRESENTED',
      rationale: 'The requested semantics have no registered predicate and absence is not falsity.'
    });
    expect(review.status).toBe(200);

    const after = await pool.query(
      'SELECT (SELECT count(*) FROM evidence)::int AS evidence, (SELECT count(*) FROM claim)::int AS claims'
    );
    expect(after.rows[0]).toEqual(before.rows[0]);
  });

  it('enforces optimistic concurrency, job idempotency, and append-only audit', async () => {
    const corpus = await pool.query(`SELECT corpus_id, version FROM corpus WHERE corpus_key = 'wce-1893-workflow-test'`);
    const corpusId = Number(corpus.rows[0].corpus_id);
    const stale = await authorized('patch', `/api/v1/corpora/${corpusId}`)
      .set('If-Match', '999')
      .send({ status: 'ACTIVE' });
    expect(stale.status).toBe(409);
    expect(stale.body.error.code).toBe('STALE_VERSION');

    const first = await authorized('post', '/api/v1/validation-runs')
      .set('Idempotency-Key', 'wce-validation-1')
      .send({ corpusId, validationTypes: ['PROVENANCE', 'READ_ONLY', 'NEGATIVE_SEMANTIC'] });
    const replay = await authorized('post', '/api/v1/validation-runs')
      .set('Idempotency-Key', 'wce-validation-1')
      .send({ corpusId, validationTypes: ['PROVENANCE', 'READ_ONLY', 'NEGATIVE_SEMANTIC'] });
    expect(first.status).toBe(202);
    expect(replay.status).toBe(202);
    expect(replay.body.job_id).toBe(first.body.job_id);
    const conflict = await authorized('post', '/api/v1/validation-runs')
      .set('Idempotency-Key', 'wce-validation-1')
      .send({ corpusId, validationTypes: ['SCHEMA'] });
    expect(conflict.status).toBe(409);
    expect(conflict.body.error.code).toBe('IDEMPOTENCY_CONFLICT');

    await expect(pool.query(`UPDATE audit_event SET detail = 'changed'`)).rejects.toThrow(/append-only/);
  });

  it('enforces bearer authentication and server-side roles', async () => {
    const unauthenticated = await request(secureApp).post('/api/v1/corpora').send({});
    const invalid = await request(secureApp)
      .post('/api/v1/corpora')
      .set('Authorization', `${['Bear', 'er'].join('')} invalid-test-credential`)
      .send({});
    const readerToken = 'test-only-reader-credential';
    const readerApp = createApp(databaseUrl, [{
      key: 'test-reader',
      displayName: 'Test Reader',
      role: 'READER',
      tokenHash: createHash('sha256').update(readerToken).digest('hex')
    }]);
    const forbidden = await request(readerApp)
      .post('/api/v1/corpora')
      .set('Authorization', `${['Bear', 'er'].join('')} ${readerToken}`)
      .send({});

    expect(unauthenticated.status).toBe(401);
    expect(invalid.status).toBe(401);
    expect(forbidden.status).toBe(403);
    expect(() => createApp(databaseUrl, [{
      key: 'invalid-role',
      displayName: 'Invalid Role',
      role: 'UNRECOGNIZED' as 'READER',
      tokenHash: createHash('sha256').update('invalid-role-token').digest('hex')
    }])).toThrow(/Invalid administrative API credential/);
  });

  it('keeps analytical evidence out of direct claims and derivations out of claims', async () => {
    const corpus = await pool.query(`SELECT corpus_id FROM corpus WHERE corpus_key = 'wce-1893-workflow-test'`);
    const registration = await authorized('post', '/api/v1/source-registrations').send({
      corpusId: Number(corpus.rows[0].corpus_id),
      sourceKey: 'workflow-test-analysis-source',
      sourceName: 'Workflow test analysis source',
      sourceType: 'HISTORICAL_WORK',
      datasetKey: 'workflow-test-analysis-dataset',
      datasetName: 'Workflow test analysis dataset',
      licenseStatus: 'LOCATOR_ONLY',
      acquisitionMethod: 'TEST_FIXTURE'
    });
    expect(registration.status).toBe(201);
    const sourceRecord = await authorized('post', '/api/v1/source-records').send({
      datasetId: Number(registration.body.dataset.dataset_id),
      key: 'analysis-record',
      sourceLocation: 'Test locator',
      citationKey: 'analysis-citation',
      locator: 'Test locator'
    });
    expect(sourceRecord.status).toBe(201);
    const evidence = await authorized('post', '/api/v1/evidence').send({
      key: 'workflow-analysis-evidence',
      sourceRecordId: Number(sourceRecord.body.sourceRecord.source_record_id),
      observation: 'An analytical observation that must not become direct claim evidence.',
      evidenceType: 'ANALYTICAL_OBSERVATION',
      citationIds: [Number(sourceRecord.body.citation.citation_id)]
    });
    expect(evidence.status).toBe(201);

    const entities = await pool.query(`SELECT entity_id FROM entity ORDER BY entity_id LIMIT 2`);
    const claimCountBefore = await pool.query('SELECT count(*)::int AS count FROM claim');
    const rejectedClaim = await authorized('post', '/api/v1/claims').send({
      key: 'workflow-rejected-analytical-claim',
      predicate: 'fatherOf',
      subjectEntityId: Number(entities.rows[0].entity_id),
      objectEntityId: Number(entities.rows[1].entity_id),
      claimType: 'DIRECT_SOURCE_CLAIM',
      evidenceIds: [Number(evidence.body.evidence_id)]
    });
    expect(rejectedClaim.status).toBe(422);
    expect(rejectedClaim.body.error.code).toBe('DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION');

    const inputClaim = await pool.query('SELECT claim_id FROM claim ORDER BY claim_id LIMIT 1');
    const derivation = await authorized('post', '/api/v1/derivations').send({
      method: 'Bounded traversal of a persisted claim.',
      assumptions: 'No truth, causation, or direct source support is inferred.',
      inputs: [{ claimId: Number(inputClaim.rows[0].claim_id) }]
    });
    expect(derivation.status).toBe(201);
    const claimCountAfter = await pool.query('SELECT count(*)::int AS count FROM claim');
    expect(claimCountAfter.rows[0].count).toBe(claimCountBefore.rows[0].count);
  });

  it('preserves proposed identity state until explicit review', async () => {
    const identity = await pool.query(
      `SELECT si.source_identity_id, e.evidence_id
       FROM source_identity si
       JOIN dataset d ON d.source_id = si.source_id
       JOIN source_record sr ON sr.dataset_id = d.dataset_id
       JOIN evidence e ON e.source_record_id = sr.source_record_id
       ORDER BY si.source_identity_id, e.evidence_id
       LIMIT 1`
    );
    const entity = await pool.query('SELECT entity_id FROM entity ORDER BY entity_id DESC LIMIT 1');
    const proposed = await authorized('post', '/api/v1/identity-mappings').send({
      sourceIdentityId: Number(identity.rows[0].source_identity_id),
      entityId: Number(entity.rows[0].entity_id),
      confidence: 0.5,
      justification: 'Provisional test reconciliation requiring reviewer action.',
      supportingEvidenceId: Number(identity.rows[0].evidence_id)
    });
    expect(proposed.status).toBe(201);
    expect(proposed.body.mapping_status_code).toBe('PROPOSED');

    const reviewed = await authorized(
      'post',
      `/api/v1/identity-mappings/${proposed.body.entity_source_mapping_id}/review`
    ).send({ status: 'REJECTED', rationale: 'Evidence does not establish canonical identity.' });
    expect(reviewed.status).toBe(200);
    expect(reviewed.body.mapping_status_code).toBe('REJECTED');
  });

  it('serves an accessible Explorer shell with distinct search and research workflows', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.text).toContain('id="scopeFilter"');
    expect(response.text).toContain('id="selectAllScopes"');
    expect(response.text).toContain('id="clearScopes"');
    expect(response.text).toContain('id="researchStatus"');
    expect(response.text).toContain('Keyword search');
    expect(response.text).toContain('Natural-language research');
    expect(response.text).toContain('How to interpret Berean results');
    expect(response.text).toContain('NO_MATCH');
    expect(response.text).toContain('NOT_REPRESENTED');
    expect(response.text).toContain('unrestricted historical Q&amp;A');
  });

  it('discovers research scope from persisted sources and datasets', async () => {
    const response = await request(app).get('/api/research/scope');
    expect(response.status).toBe(200);
    expect(response.body.sources.length).toBeGreaterThan(0);
    expect(response.body.datasets.length).toBeGreaterThan(0);
    expect(response.body.inventory.claims).toBeGreaterThan(0);
  });

  it('returns an inspectable bounded participation plan without persisting research', async () => {
    const before = await snapshotPersistentTableCounts();
    const response = await request(app)
      .post('/api/research')
      .send({ question: 'Who participated in observations?' });
    const after = await snapshotPersistentTableCounts();
    expect(response.status).toBe(200);
    expect(after).toEqual(before);
    expect(response.body.plan.scope.retrieval_scope).toBe('BEREAN_ONLY');
    expect(response.body.plan.subject_resolution.status).toBe('NO_SUBJECT');
    expect(response.body.plan.candidate_predicates.length).toBeGreaterThan(0);
    expect(response.body.results.length).toBeLessThanOrEqual(50);
    expect(response.body.bounded).toEqual({
      total_matched: 0,
      returned: 0,
      truncated: false,
      limit: 50,
      order: ['claim_key', 'evidence_key', 'evidence_relation_type_code', 'dataset_key', 'source_key'],
      ordering_stable: true
    });
  });

  it('supports all, single, and multiple persisted dataset scopes', async () => {
    const scope = await request(app).get('/api/research/scope');
    const all = await request(app).post('/api/research').send({ question: 'In which represented events does Seth participate?' });
    expect(all.status).toBe(200);
    expect(all.body.plan.scope.dataset_ids).toEqual([]);
    expect(all.body.results.length).toBeGreaterThan(0);

    const firstScopedResult = all.body.results.find((result: { dataset_id: number | string | null }) => Number.isFinite(Number(result.dataset_id)));
    expect(firstScopedResult).toBeTruthy();
    const representedDatasetId = Number(firstScopedResult.dataset_id);
    const otherDatasetId = scope.body.datasets
      .map((dataset: { dataset_id: number | string }) => Number(dataset.dataset_id))
      .find((datasetId: number) => datasetId !== representedDatasetId);
    expect(otherDatasetId).toBeTruthy();
    const datasetIds = [representedDatasetId, otherDatasetId];

    const single = await request(app)
      .post('/api/research')
      .send({ question: 'In which represented events does Seth participate?', datasetIds: datasetIds.slice(0, 1) });
    expect(single.status).toBe(200);
    expect(single.body.plan.scope.dataset_ids).toEqual(datasetIds.slice(0, 1));
    expect(single.body.results.length).toBeGreaterThan(0);
    expect(single.body.results.every((result: { dataset_id: number | string }) => Number(result.dataset_id) === datasetIds[0])).toBe(true);

    const multiple = await request(app)
      .post('/api/research')
      .send({ question: 'In which represented events does Seth participate?', datasetIds });
    expect(multiple.status).toBe(200);
    expect(multiple.body.plan.scope.dataset_ids).toEqual(datasetIds);
    expect(multiple.body.results.every((result: { dataset_id: number | string }) => datasetIds.includes(Number(result.dataset_id)))).toBe(true);
  });

  it('excludes predicate matches that are unrelated to the resolved subject', async () => {
    const noParticipationSubject = await pool.query(
      `SELECT e.canonical_name
       FROM entity e
       WHERE NOT EXISTS (
         SELECT 1
         FROM proposition p
         JOIN predicate pr ON pr.predicate_code = p.predicate
         WHERE p.subject_entity_id = e.entity_id
           AND pr.event_participation_role_code IS NOT NULL
       )
       ORDER BY char_length(e.canonical_name) DESC, e.entity_id
       LIMIT 1`
    );
    expect(noParticipationSubject.rowCount).toBeGreaterThan(0);
    const subjectName = noParticipationSubject.rows[0].canonical_name as string;

    const response = await request(app)
      .post('/api/research')
      .send({ question: `Who participates in ${subjectName} events?` });
    expect(response.status).toBe(200);
    expect(response.body.plan.subject_resolution.status).toBe('RESOLVED');
    expect(response.body.capability).toBe('NO_MATCH');
    expect(response.body.results).toEqual([]);
  });

  it('returns UNRESOLVED for ambiguous and unresolved source-identity subjects', async () => {
    const ambiguous = await request(app)
      .post('/api/research')
      .send({ question: 'What fatherOf claim relates Adam and Seth?' });
    expect(ambiguous.status).toBe(200);
    expect(ambiguous.body.capability).toBe('UNRESOLVED');
    expect(ambiguous.body.plan.subject_resolution.status).toBe('AMBIGUOUS');
    expect(ambiguous.body.results).toEqual([]);

    const unresolvedName = 'Unresolved Test Identity';
    await pool.query(
      `WITH seeded AS (
         INSERT INTO source_identity (source_id, source_identity_key, display_name)
         SELECT source_id, 'phase32-unresolved-test-identity', $1
         FROM source
         WHERE source_key = 'EARMAN_GLYMOUR_1980'
         ON CONFLICT (source_id, source_identity_key) DO UPDATE SET display_name = EXCLUDED.display_name
         RETURNING source_identity_id
       )
       INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification)
       SELECT seeded.source_identity_id, entity.entity_id, 'PROPOSED', 0.5000, 'Test-only unresolved source identity mapping.'
       FROM seeded
       JOIN entity ON entity.entity_key = 'adam'
       WHERE NOT EXISTS (
         SELECT 1 FROM entity_source_mapping existing
         WHERE existing.source_identity_id = seeded.source_identity_id
           AND existing.entity_id = entity.entity_id
       )`,
      [unresolvedName]
    );

    const unresolved = await request(app)
      .post('/api/research')
      .send({ question: `What represented claims involve ${unresolvedName}?` });
    expect(unresolved.status).toBe(200);
    expect(unresolved.body.capability).toBe('UNRESOLVED');
    expect(unresolved.body.plan.subject_resolution.status).toBe('UNRESOLVED_SOURCE_IDENTITY');
    expect(unresolved.body.results).toEqual([]);
  });

  it('returns NOT_REPRESENTED when no represented subject can be resolved', async () => {
    const response = await request(app).post('/api/research').send({ question: 'What fatherOf claim exists for zzz-no-subject-zzz?' });
    expect(response.status).toBe(200);
    expect(response.body.capability).toBe('NOT_REPRESENTED');
    expect(response.body.plan.subject_resolution.status).toBe('NO_SUBJECT');
    expect(response.body.results).toEqual([]);
  });

  it('returns NO_MATCH for a represented subject with no matching subject-bound claims', async () => {
    const response = await request(app).post('/api/research').send({ question: 'Is Earth fatherOf anyone?' });
    expect(response.status).toBe(200);
    expect(response.body.plan.subject_resolution.status).toBe('RESOLVED');
    expect(response.body.capability).toBe('NO_MATCH');
    expect(response.body.results).toEqual([]);
  });

  it('preserves evidence relations and inactive claim lifecycle states in research results', async () => {
    const scope = await request(app).get('/api/research/scope');
    const lxxDatasetId = Number(scope.body.datasets.find((dataset: { dataset_key: string }) => dataset.dataset_key === 'GEN_LXX_REF').dataset_id);
    const mtDatasetId = Number(scope.body.datasets.find((dataset: { dataset_key: string }) => dataset.dataset_key === 'GEN_MT_REF').dataset_id);

    const lxx = await request(app)
      .post('/api/research')
      .send({ question: 'What ageAtFatherhoodYears claim is represented for Adam?', datasetIds: [lxxDatasetId] });
    const contradictedMtClaim = lxx.body.results.find(
      (result: { claim_key: string }) => result.claim_key === 'CLAIM_MT_ADAM_AGE_AT_SETH'
    );
    expect(contradictedMtClaim.evidence_relation_type_code).toBe('CONTRADICTS');
    expect(contradictedMtClaim.classification).toBe('EVIDENCE_CONTRADICTS');

    const mt = await request(app)
      .post('/api/research')
      .send({ question: 'What ageAtFatherhoodYears claim is represented for Adam?', datasetIds: [mtDatasetId] });
    const superseded = mt.body.results.find(
      (result: { claim_key: string }) => result.claim_key === 'CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT'
    );
    expect(superseded.claim_status_code).toBe('SUPERSEDED');
    expect(superseded.classification).toBe('UNRESOLVED');
  });

  it('does not represent requests for proof as a Berean fact', async () => {
    const response = await request(app)
      .post('/api/research')
      .send({ question: 'Did an observation prove a theory?' });
    expect(response.status).toBe(200);
    expect(response.body.capability).toBe('NOT_REPRESENTED');
    expect(response.body.results).toEqual([]);
  });

  it('validates bounded research and keyword-search input', async () => {
    expect((await request(app).post('/api/research').send({ question: 'x', datasetIds: [1, '2'] })).status).toBe(400);
    expect((await request(app).post('/api/research').send({ question: 'x', datasetIds: Array.from({ length: 101 }, (_, index) => index + 1) })).status).toBe(400);
    expect((await request(app).get('/api/search').query({ q: 'x'.repeat(201) })).status).toBe(400);
    expect((await request(app).get('/api/search').query({ q: 'adam', limit: 'not-a-number' })).status).toBe(400);
    expect((await request(app).get('/api/graph').query({ nodeType: 'dataset', nodeId: 1 })).status).toBe(400);
  });

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

  it('projects an entity graph neighborhood with no self-referential edges', async () => {
    const entitySearch = await request(app).get('/api/search').query({ q: 'adam', limit: 50 });
    const entity = entitySearch.body.results.find((r: { type: string; key: string }) => r.type === 'entity' && r.key === 'adam');
    expect(entity).toBeTruthy();
    const response = await request(app).get('/api/graph').query({ nodeType: 'entity', nodeId: entity.id });
    expect(response.status).toBe(200);
    const centerNodeId = `entity:${entity.id}`;
    const selfLoops = response.body.edges.filter(
      (edge: { source: string; target: string }) => edge.source === centerNodeId && edge.target === centerNodeId
    );
    expect(selfLoops).toEqual([]);
    expect(
      response.body.edges.some(
        (edge: { source: string; target: string; relation: string }) =>
          edge.relation === 'fatherOf' && (edge.source === centerNodeId || edge.target === centerNodeId)
      )
    ).toBe(true);
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

  it('answers unmatched compatibility API paths with a JSON 404 instead of the Explorer HTML shell', async () => {
    for (const response of [
      await request(app).get('/api/no-such-endpoint'),
      await request(app).post('/api/no-such-endpoint').send({})
    ]) {
      expect(response.status).toBe(404);
      expect(response.type).toBe('application/json');
      expect(response.body.error).toBe('route not found');
    }
    const shell = await request(app).get('/not-an-api-path');
    expect(shell.status).toBe(200);
    expect(shell.type).toBe('text/html');
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

  it('returns 400 for invalid exploration timeline input and 404 for a nonexistent entity', async () => {
    expect((await request(app).get('/api/exploration/timeline')).status).toBe(400);
    expect(
      (await request(app).get('/api/exploration/timeline').query({ entity_id: 1, entity_key: 'ark_of_covenant' })).status
    ).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_id: 'abc' })).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_id: '1.5' })).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_id: 0 })).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_id: -1 })).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline?entity_id=1&entity_id=2')).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_key: '' })).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline?entity_key=a&entity_key=b')).status).toBe(400);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_id: 999999999 })).status).toBe(404);
    expect((await request(app).get('/api/exploration/timeline').query({ entity_key: 'no_such_entity' })).status).toBe(404);
  });

  it('returns 200 for an existing entity with no associated events or claims', async () => {
    const inserted = await pool.query(
      `INSERT INTO entity (entity_key, entity_type_code, canonical_name)
       VALUES ('phase25_unassociated_entity', 'CONCEPT', 'phase25 unassociated entity')
       RETURNING entity_id`
    );
    const entityId = Number(inserted.rows[0].entity_id);
    try {
      const byId = await request(app).get('/api/exploration/timeline').query({ entity_id: entityId });
      const byKey = await request(app).get('/api/exploration/timeline').query({ entity_key: 'phase25_unassociated_entity' });
      expect(byId.status).toBe(200);
      expect(byId.body.timeline).toEqual([]);
      expect(byId.body.entity_claims_without_event).toEqual([]);
      expect(byId.body.source_comparison.distinct_source_count).toBe(0);
      expect(byKey.status).toBe(200);
      expect(Number(byKey.body.entity.entity_id)).toBe(entityId);
    } finally {
      await pool.query(`DELETE FROM entity WHERE entity_id = $1`, [entityId]);
    }
  });

  it('explores the Ark entity timeline with claims, provenance, and projected participation', async () => {
    const before = await snapshotPersistentTableCounts();
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'ark_of_covenant' });
    const after = await snapshotPersistentTableCounts();

    expect(response.status).toBe(200);
    expect(after).toEqual(before);
    expect(response.body.operation).toBe('EXPLORE_TIMELINE');
    expect(response.body.read_only).toBe(true);
    expect(response.body.entity.entity_key).toBe('ark_of_covenant');
    expect(response.body.entity.entity_type_code).toBe('OBJECT');

    const eventKeys = response.body.timeline.map((entry: { event: { event_key: string } }) => entry.event.event_key);
    expect(eventKeys).toEqual(
      expect.arrayContaining([
        'ark_covenant_instruction',
        'ark_covenant_construction',
        'ark_covenant_contents_placement',
        'ark_covenant_transport_instruction_jordan',
        'ark_covenant_transport_jordan',
        'ark_covenant_transport_new_cart_2sam6',
        'ark_covenant_physical_interaction_uzzah_2sam6'
      ])
    );
    expect(new Set(eventKeys).size).toBe(eventKeys.length);
    expect(
      response.body.timeline.every(
        (entry: { temporal: { temporal_status: string } }) => entry.temporal.temporal_status === 'DATE_NOT_STORED'
      )
    ).toBe(true);

    const newCartTransport = response.body.timeline.find(
      (entry: { event: { event_key: string } }) => entry.event.event_key === 'ark_covenant_transport_new_cart_2sam6'
    );
    const arkClaim = newCartTransport.claims.find(
      (entry: { claim: { claim_key: string } }) =>
        entry.claim.claim_key === 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'
    );
    expect(arkClaim.record_type).toBe('STORED_CLAIM');
    expect(arkClaim.claim.statement_role).toBe('DISPLAY_METADATA_ONLY');
    expect(arkClaim.proposition.authority).toBe('AUTHORITATIVE_STRUCTURED_CONTENT');
    expect(arkClaim.proposition.predicate).toBe('subjectOf');
    expect(arkClaim.predicate.event_participation_role_code).toBe('SUBJECT');
    expect(arkClaim.provenance.supporting_evidence[0].evidence_key).toBe('EV_MT_2SA_6_3');
    expect(arkClaim.provenance.supporting_evidence[0].relation_type_code).toBe('SUPPORTS');
    expect(arkClaim.provenance.citations[0].locator).toBe('2 Samuel 6:3');
    expect(arkClaim.provenance.citations[0].quoted_text_status).toBe('NOT_STORED_BY_POLICY');
    expect(arkClaim.provenance.source_records[0].source_record_key).toBe('MT_2SA_6_3');
    expect(arkClaim.provenance.source_records[0].raw_content_status).toBe('NOT_STORED_BY_POLICY');
    expect(arkClaim.provenance.datasets[0].dataset_key).toBe('2SA_MT_REF');
    expect(arkClaim.provenance.sources[0].source_key).toBe('2SA_MT');
    expect(arkClaim.projected_relationships[0].projection).toBe('PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION');

    const participants = newCartTransport.projected_event_participation;
    expect(participants.map((row: { entity_key: string }) => row.entity_key)).toEqual(
      expect.arrayContaining(['ark_of_covenant', 'uzzah', 'new_cart_2sam6'])
    );
    expect(participants.every((row: { projection: string }) => row.projection === 'PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION')).toBe(true);
    expect(participants.every((row: { asserting_claim_key: string }) => typeof row.asserting_claim_key === 'string')).toBe(true);

    const locators = response.body.timeline
      .flatMap((entry: { claims: { provenance: { citations: { locator: string }[] } }[] }) => entry.claims)
      .flatMap((entry: { provenance: { citations: { locator: string }[] } }) => entry.provenance.citations)
      .map((citation: { locator: string }) => citation.locator);
    expect(locators).toEqual(
      expect.arrayContaining([
        'Exodus 25:10',
        'Exodus 37:1',
        'Exodus 40:20',
        'Deuteronomy 10:3',
        'Joshua 3:6',
        '2 Samuel 6:3',
        '2 Samuel 6:6'
      ])
    );

    expect(response.body.entity_claims_without_event.length).toBeGreaterThan(0);
    expect(response.body.entity_source_mappings.length).toBeGreaterThan(0);
  });

  it('keeps the Genesis 6:4 direct claim distinct from scholarly and later-tradition observations', async () => {
    const claimId = await getClaimIdByKey('CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30');
    const before = await snapshotPersistentTableCounts();
    const response = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    const after = await snapshotPersistentTableCounts();

    expect(response.status).toBe(200);
    expect(after).toEqual(before);
    expect(response.body.claims).toHaveLength(1);
    expect(response.body.claims[0].claim.claim_type_code).toBe('DIRECT_SOURCE_CLAIM');
    expect(response.body.claims[0].proposition.predicate).toBe('locatedAt');
    expect(response.body.claims[0].supporting_evidence[0].evidence_key).toBe('EV_MT_GEN_6_1_4_P30');
    expect(response.body.claims[0].source[0].source_key).toBe('GEN_MT');

    const promotedScholarlyOrLaterClaims = await pool.query(
      `SELECT c.claim_key
       FROM claim c
       JOIN claim_evidence ce ON ce.claim_id = c.claim_id
       JOIN evidence e ON e.evidence_id = ce.evidence_id
       WHERE e.evidence_key IN (
         'EV_HENDEL_2004_P30', 'EV_KLINE_1962_P30', 'EV_WENHAM_1987_P30', 'EV_1EN_ETH_6_7_P30'
       )`
    );
    expect(promotedScholarlyOrLaterClaims.rowCount).toBe(0);
  });

  it('keeps Joshua 3, 2 Samuel 6, and Hebrews 9 descriptions distinct and unclassified', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'ark_of_covenant' });
    expect(response.status).toBe(200);

    const sourceKeys = response.body.source_comparison.sources.map((source: { source_key: string }) => source.source_key);
    expect(sourceKeys).toEqual(expect.arrayContaining(['JOS_MT', '2SA_MT', 'HEB_GNT']));
    expect(response.body.source_comparison.comparison_status).toBe('DIFFERING_SOURCE_DESCRIPTION');
    expect(response.body.source_comparison.distinct_source_count).toBeGreaterThan(1);

    const locatorsBySource = Object.fromEntries(
      response.body.source_comparison.sources.map((source: { source_key: string; descriptions: { locators: string[] }[] }) => [
        source.source_key,
        source.descriptions.flatMap((description) => description.locators)
      ])
    );
    expect(locatorsBySource.JOS_MT).toContain('Joshua 3:6');
    expect(locatorsBySource['2SA_MT']).toContain('2 Samuel 6:3');
    expect(locatorsBySource.HEB_GNT).toContain('Hebrews 9:4');

    const descriptionTypes = response.body.source_comparison.sources.flatMap(
      (source: { descriptions: { record_type: string }[] }) => source.descriptions.map((description) => description.record_type)
    );
    expect(new Set(descriptionTypes)).toEqual(new Set(['SOURCE_DESCRIPTION']));

    const labels = new Set<string>();
    for (const entry of response.body.timeline) {
      labels.add(entry.record_type);
      for (const claimEntry of entry.claims) {
        labels.add(claimEntry.record_type);
        labels.add(claimEntry.provenance.provenance_status);
        labels.add(claimEntry.claim.statement_role);
      }
    }
    labels.add(response.body.source_comparison.comparison_status);
    for (const source of response.body.source_comparison.sources) {
      for (const description of source.descriptions) labels.add(description.record_type);
    }
    for (const forbidden of ['CONTRADICTION', 'CONTRADICTS', 'COMPLIANCE', 'VIOLATION', 'ERROR', 'TRUE', 'FALSE']) {
      expect(labels.has(forbidden)).toBe(false);
    }

    const storedRelationTypes = response.body.stored_claim_relations.map(
      (relation: { relation_type_code: string }) => relation.relation_type_code
    );
    expect(storedRelationTypes).toContain('CONTRADICTS');
    expect(response.body.source_comparison.note).toContain('DIFFERENCE IS NOT CONTRADICTION');
    expect(response.body.limitations).toContain(
      'This operation assembles existing Berean knowledge. It does not create, evaluate, or promote knowledge.'
    );
  });

  it('keeps Phase 31 Nephilim research exploration read-only while preserving storage-policy reporting', async () => {
    const before = await snapshotPersistentTableCounts();
    const search = await request(app).get('/api/search').query({ q: 'nephilim', limit: 20 });
    expect(search.status).toBe(200);
    expect(search.body.results.some((r: { key?: string }) => r.key === 'nephilim_gen6')).toBe(true);

    const claimId = await getClaimIdByKey('CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30');
    const provenance = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    expect(provenance.status).toBe(200);
    expect(provenance.body.claims[0].citations[0].quoted_text_status).toBe('NOT_STORED_BY_POLICY');
    expect(provenance.body.claims[0].source_records[0].raw_content_status).toBe('NOT_STORED_BY_POLICY');

    const timeline = await request(app).get('/api/exploration/timeline').query({ entity_key: 'nephilim_gen6' });
    expect(timeline.status).toBe(200);
    expect(timeline.body.limitations).toContain(
      'NULL raw_content and NULL quoted_text are reported as NOT_STORED_BY_POLICY, never as source silence.'
    );
    expect(await snapshotPersistentTableCounts()).toEqual(before);
  });

  it('keeps Phase 31 scholarly, textual-comparison, and later-tradition evidence out of promoted claims', async () => {
    const promoted = await pool.query(
      `SELECT c.claim_key
       FROM claim c
       JOIN claim_evidence ce ON ce.claim_id = c.claim_id
       JOIN evidence e ON e.evidence_id = ce.evidence_id
       WHERE e.evidence_key IN (
         'EV_LXX_GEN_6_1_4_DISTINCT_TRADITION_P31',
         'EV_MT_NUM_13_33_INDEPENDENT_REPORT_P31',
         'EV_1EN_ETH_6_7_LATER_TRADITION_P31',
         'EV_HENDEL_2004_DIVINE_BEING_P31',
         'EV_KLINE_1962_ROYAL_HUMAN_P31',
         'EV_WENHAM_1987_WATCHERS_GIANTS_CONTEXT_P31'
       )`
    );
    expect(promoted.rowCount).toBe(0);

    const termRelationships = await pool.query(
      `SELECT s.entity_key AS subject_key, p.predicate, o.entity_key AS object_key
       FROM proposition p
       JOIN entity s ON s.entity_id = p.subject_entity_id
       LEFT JOIN entity o ON o.entity_id = p.object_entity_id
       WHERE s.entity_key IN (
         'sons_of_god_gen6',
         'daughters_of_man_gen6',
         'mighty_men_gen6',
         'men_of_renown_gen6',
         'nephilim_gen6'
       )`
    );
    expect(termRelationships.rows).toEqual([
      { subject_key: 'nephilim_gen6', predicate: 'locatedAt', object_key: 'gen1_earth' }
    ]);
  });

  it('keeps Phase 32 eclipse research read-only while preserving storage-policy reporting', async () => {
    const before = await snapshotPersistentTableCounts();
    const search = await request(app).get('/api/search').query({ q: 'Eddington', limit: 20 });
    expect(search.status).toBe(200);
    expect(search.body.results.some((r: { key?: string }) => r.key === 'phase32_arthur_eddington')).toBe(true);

    const claimId = await getClaimIdByKey('CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION');
    const provenance = await request(app).get('/api/provenance/explain').query({ claim_id: claimId });
    expect(provenance.status).toBe(200);
    expect(provenance.body.claims[0].citations[0].quoted_text_status).toBe('NOT_STORED_BY_POLICY');
    expect(provenance.body.claims[0].source_records[0].raw_content_status).toBe('NOT_STORED_BY_POLICY');

    const timeline = await request(app).get('/api/exploration/timeline').query({ entity_key: 'phase32_arthur_eddington' });
    expect(timeline.status).toBe(200);
    expect(timeline.body.limitations).toContain(
      'NULL raw_content and NULL quoted_text are reported as NOT_STORED_BY_POLICY, never as source silence.'
    );
    expect(await snapshotPersistentTableCounts()).toEqual(before);
  });

  it('keeps Phase 32 ambiguous and scholarly eclipse evidence out of promoted claims', async () => {
    const promoted = await pool.query(
      `SELECT c.claim_key
       FROM claim c
       JOIN claim_evidence ce ON ce.claim_id = c.claim_id
       JOIN evidence e ON e.evidence_id = ce.evidence_id
       WHERE e.evidence_key IN (
         'EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32',
         'EV_EARMAN_GLYMOUR_1980_INTERPRETATION_P32',
         'EV_KENNEFICK_2007_INTERPRETATION_P32'
       )`
    );
    expect(promoted.rowCount).toBe(0);

    const theoryRelationships = await pool.query(
      `SELECT p.predicate
       FROM proposition p
       LEFT JOIN entity s ON s.entity_id = p.subject_entity_id
       LEFT JOIN entity o ON o.entity_id = p.object_entity_id
       WHERE s.entity_key IN (
         'phase32_general_relativity_deflection',
         'phase32_newtonian_deflection'
       )
          OR o.entity_key IN (
         'phase32_general_relativity_deflection',
         'phase32_newtonian_deflection'
       )`
    );
    expect(theoryRelationships.rowCount).toBe(0);
  });
});

describe('phase 26 biblical entity coverage', () => {
  it('represents Enoch end-to-end with complete provenance', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'enoch' });
    expect(response.status).toBe(200);
    expect(response.body.entity.entity_key).toBe('enoch');
    expect(response.body.entity.entity_type_code).toBe('PERSON');

    const claims = [
      ...response.body.timeline.flatMap((entry: { claims: unknown[] }) => entry.claims),
      ...response.body.entity_claims_without_event
    ];
    expect(claims.length).toBeGreaterThan(0);
    for (const claimEntry of claims) {
      expect(claimEntry.provenance.provenance_status).toBe('SOURCE-BACKED');
      expect(claimEntry.provenance.sources.map((source: { source_key: string }) => source.source_key)).toContain('GEN_MT');
      for (const record of claimEntry.provenance.source_records) {
        expect(record.raw_content_status).toBe('NOT_STORED_BY_POLICY');
      }
      for (const citation of claimEntry.provenance.citations) {
        expect(citation.quoted_text_status).toBe('NOT_STORED_BY_POLICY');
      }
    }

    const locators = claims.flatMap((claimEntry: { provenance: { citations: { locator: string }[] } }) =>
      claimEntry.provenance.citations.map((citation) => citation.locator)
    );
    expect(locators).toEqual(expect.arrayContaining(['Genesis 5:18', 'Genesis 5:21']));

    const participation = response.body.timeline.flatMap(
      (entry: { projected_event_participation: { entity_key: string; projection: string }[] }) =>
        entry.projected_event_participation
    );
    expect(participation.map((row: { entity_key: string }) => row.entity_key)).toEqual(
      expect.arrayContaining(['enoch', 'methuselah'])
    );
    expect(participation.every((row: { projection: string }) => row.projection === 'PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION')).toBe(true);
  });

  it('leaves Genesis 5:22-24 observations unmodeled and marked as requiring review', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'enoch' });
    expect(response.status).toBe(200);

    const locators = [
      ...response.body.timeline.flatMap((entry: { claims: { provenance: { citations: { locator: string }[] } }[] }) => entry.claims),
      ...response.body.entity_claims_without_event
    ].flatMap((claimEntry: { provenance: { citations: { locator: string }[] } }) =>
      claimEntry.provenance.citations.map((citation) => citation.locator)
    );
    expect(locators).not.toContain('Genesis 5:22');
    expect(locators).not.toContain('Genesis 5:23');
    expect(locators).not.toContain('Genesis 5:24');

    expect(response.body.coverage.candidate_reference_count).toBeGreaterThan(0);
    expect(response.body.coverage.related_source_material_status).toBe('RELATED_SOURCE_MATERIAL_NOT_YET_MODELED');
    expect(response.body.coverage.labels).toEqual(expect.arrayContaining(['SOURCE-BACKED', 'CANDIDATE-REQUIRES-REVIEW']));
  });

  it('reports sparse-state coverage metadata for an explored entity', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'ark_of_covenant' });
    expect(response.status).toBe(200);

    const coverage = response.body.coverage;
    expect(coverage.coverage_status).toBe('EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED');
    expect(coverage.entity_type).toBe('OBJECT');
    expect(coverage.provenance_status).toBe('COMPLETE_SOURCE_CHAIN');
    expect(coverage.claim_count).toBeGreaterThan(0);
    expect(coverage.event_count).toBeGreaterThan(0);
    expect(coverage.source_count).toBeGreaterThan(1);
    expect(coverage.modeled_reference_count).toBeGreaterThan(0);
    expect(typeof coverage.candidate_reference_count).toBe('number');
    expect(coverage.labels).toContain('SOURCE-BACKED');
  });

  it('reports NO_ENTITY_FOUND for an unmodeled subject', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'dagon' });
    expect(response.status).toBe(404);
    expect(response.body.coverage_status).toBe('NO_ENTITY_FOUND');
  });

  it('makes 1 Samuel 4-7 people and places explorable with 1SA_MT provenance', async () => {
    for (const entityKey of ['eli', 'ashdod', 'kiriath_jearim', 'abinadab']) {
      const response = await request(app).get('/api/exploration/timeline').query({ entity_key: entityKey });
      expect(response.status).toBe(200);
      const sourceKeys = response.body.source_comparison.sources.map((source: { source_key: string }) => source.source_key);
      expect(sourceKeys).toContain('1SA_MT');
      expect(response.body.coverage.provenance_status).toBe('COMPLETE_SOURCE_CHAIN');
    }
  });

  it('keeps 1 Samuel 5 alongside Joshua 3 and 2 Samuel 6 without contradiction classification', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'ark_of_covenant' });
    expect(response.status).toBe(200);
    const sourceKeys = response.body.source_comparison.sources.map((source: { source_key: string }) => source.source_key);
    expect(sourceKeys).toEqual(expect.arrayContaining(['JOS_MT', '1SA_MT', '2SA_MT']));
    expect(response.body.source_comparison.comparison_status).toBe('DIFFERING_SOURCE_DESCRIPTION');

    const descriptionTypes = response.body.source_comparison.sources.flatMap(
      (source: { descriptions: { record_type: string }[] }) => source.descriptions.map((description) => description.record_type)
    );
    expect(new Set(descriptionTypes)).toEqual(new Set(['SOURCE_DESCRIPTION']));
  });

  it('does not mutate any persistent or registry table while exploring phase 26 data', async () => {
    const before = await snapshotPersistentTableCounts();
    for (const entityKey of ['enoch', 'methuselah', 'eli', 'ashdod', 'ark_of_covenant']) {
      const response = await request(app).get('/api/exploration/timeline').query({ entity_key: entityKey });
      expect(response.status).toBe(200);
    }
    const after = await snapshotPersistentTableCounts();
    expect(after).toEqual(before);
  });
});

describe('phase 27 Genesis 1-50 corpus', () => {
  it('explores required people and a major location through complete GEN_MT provenance', async () => {
    for (const entityKey of ['adam', 'noah', 'abraham', 'sarah', 'isaac', 'jacob', 'joseph', 'egypt']) {
      const response = await request(app).get('/api/exploration/timeline').query({ entity_key: entityKey });
      expect(response.status).toBe(200);
      expect(response.body.coverage.provenance_status).toBe('COMPLETE_SOURCE_CHAIN');
      expect(response.body.coverage.claim_count).toBeGreaterThan(0);
      expect(response.body.source_comparison.sources.map((source: { source_key: string }) => source.source_key)).toContain('GEN_MT');
    }
  });

  it('projects a multi-participant event from source-backed claim propositions', async () => {
    const response = await request(app).get('/api/exploration/timeline').query({ entity_key: 'noah' });
    expect(response.status).toBe(200);
    const revelation = response.body.timeline.find((entry: { event: { event_key: string } }) =>
      entry.event.event_key === 'noah_sons_genealogy'
    );
    expect(revelation).toBeTruthy();
    expect(revelation.projected_event_participation.map((row: { entity_key: string }) => row.entity_key)).toEqual(
      expect.arrayContaining(['noah', 'shem', 'ham', 'japheth'])
    );
    for (const claimEntry of revelation.claims) {
      expect(claimEntry.provenance.provenance_status).toBe('SOURCE-BACKED');
      expect(claimEntry.provenance.source_records[0].raw_content_status).toBe('NOT_STORED_BY_POLICY');
      expect(claimEntry.provenance.citations[0].quoted_text_status).toBe('NOT_STORED_BY_POLICY');
    }
  });

  it('keeps exploration read-only across the expanded corpus', async () => {
    const before = await snapshotPersistentTableCounts();
    for (const entityKey of ['abraham', 'sarah', 'isaac', 'jacob', 'joseph', 'egypt']) {
      expect((await request(app).get('/api/exploration/timeline').query({ entity_key: entityKey })).status).toBe(200);
    }
    expect(await snapshotPersistentTableCounts()).toEqual(before);
  });
});

describe('V1 API contract', () => {
  const searchProbes = [
    { resource: 'entities', type: 'entity', sql: 'SELECT entity_key AS key FROM entity ORDER BY entity_id LIMIT 1' },
    { resource: 'events', type: 'event', sql: 'SELECT event_key AS key FROM event ORDER BY event_id LIMIT 1' },
    { resource: 'claims', type: 'claim', sql: 'SELECT claim_key AS key FROM claim ORDER BY claim_id LIMIT 1' },
    { resource: 'propositions', type: 'proposition', sql: 'SELECT predicate AS key FROM proposition ORDER BY proposition_id LIMIT 1' },
    { resource: 'evidence', type: 'evidence', sql: 'SELECT evidence_key AS key FROM evidence ORDER BY evidence_id LIMIT 1' },
    { resource: 'sources', type: 'source', sql: 'SELECT source_key AS key FROM source ORDER BY source_id LIMIT 1' },
    { resource: 'datasets', type: 'dataset', sql: 'SELECT dataset_key AS key FROM dataset ORDER BY dataset_id LIMIT 1' },
    { resource: 'source-records', type: 'source_record', sql: 'SELECT source_record_key AS key FROM source_record ORDER BY source_record_id LIMIT 1' },
    { resource: 'citations', type: 'citation', sql: 'SELECT citation_key AS key FROM citation ORDER BY citation_id LIMIT 1' },
    { resource: 'identities', type: 'source_identity', sql: 'SELECT source_identity_key AS key FROM source_identity ORDER BY source_identity_id LIMIT 1' }
  ];

  it('normalizes every supported search resource filter to its persisted type', async () => {
    for (const probe of searchProbes) {
      const row = await pool.query(probe.sql);
      expect(row.rowCount, `fixture row required for ${probe.resource}`).toBeGreaterThan(0);
      const term = String(row.rows[0].key);

      const response = await request(app).get(`/api/v1/search/${probe.resource}`).query({ q: term, limit: 100 });
      expect(response.status, `${probe.resource} search status`).toBe(200);
      expect(response.body.resource).toBe(probe.resource);
      expect(response.body.resource_type).toBe(probe.type);
      expect(response.body.results.length, `${probe.resource} results`).toBeGreaterThan(0);
      expect(response.body.classification).toBe('MATCHED');
      for (const result of response.body.results) {
        expect(result.type, `${probe.resource} filtered type`).toBe(probe.type);
      }
    }
  });

  it('returns a controlled error for unknown and unindexed search filters', async () => {
    const before = await snapshotPersistentTableCounts();

    const unknown = await request(app).get('/api/v1/search/not-a-resource').query({ q: 'adam' });
    expect(unknown.status).toBe(404);
    expect(unknown.body.error.code).toBe('NOT_FOUND');

    const singular = await request(app).get('/api/v1/search/entity').query({ q: 'adam' });
    expect(singular.status).toBe(404);

    const unindexed = await request(app).get('/api/v1/search/identity-mappings').query({ q: 'adam' });
    expect(unindexed.status).toBe(501);
    expect(unindexed.body.error.code).toBe('NOT_REPRESENTED');

    const noMatch = await request(app).get('/api/v1/search/entities').query({ q: 'zzz-no-such-persisted-record-zzz' });
    expect(noMatch.status).toBe(200);
    expect(noMatch.body.results).toEqual([]);
    expect(noMatch.body.classification).toBe('NO_MATCH');
    expect(noMatch.body.limitation).toContain('not a denial');

    expect(await snapshotPersistentTableCounts()).toEqual(before);
  });

  it('rejects an unsupported administrative resource with 404 and no implementation leakage', async () => {
    const unauthenticated = await request(secureApp).get('/api/v1/admin/not-real');
    expect(unauthenticated.status).toBe(401);

    const response = await authorized('get', '/api/v1/admin/not-real');
    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
    expect(JSON.stringify(response.body)).not.toContain('UNSUPPORTED_ADMIN_RESOURCE');
    expect(JSON.stringify(response.body)).not.toContain('internal_error');
    expect(response.headers['x-correlation-id']).toBeTruthy();

    const supported = await authorized('get', '/api/v1/admin/corpora').query({ limit: 5 });
    expect(supported.status).toBe(200);
    expect(Array.isArray(supported.body.results)).toBe(true);
  });

  it('distinguishes missing-claim provenance between the versioned and compatibility routes', async () => {
    const missingId = 2147483000;
    const versioned = await request(app).get(`/api/v1/provenance/claim/${missingId}`);
    expect(versioned.status).toBe(404);
    expect(versioned.body.error.code).toBe('NOT_FOUND');

    const compatibility = await request(app).get(`/api/provenance/claims/${missingId}`);
    expect(compatibility.status).toBe(200);
    expect(compatibility.body.traversal).toEqual([]);
    expect(compatibility.body.claim_present).toBe(false);
    expect(compatibility.body.classification).toBe('CLAIM_NOT_REPRESENTED');

    const claimId = await getClaimIdByKey('CLAIM_MT_ADAM_FATHER_SETH');
    const represented = await request(app).get(`/api/provenance/claims/${claimId}`);
    expect(represented.status).toBe(200);
    expect(represented.body.claim_present).toBe(true);
    expect(represented.body.classification).toBe('PROVENANCE_TRAVERSAL_REPRESENTED');
    expect((await request(app).get(`/api/v1/provenance/claim/${claimId}`)).status).toBe(200);
  });

  it('applies one 409 conflict contract to If-Match, mapping state, and job state without partial writes', async () => {
    const created = await authorized('post', '/api/v1/corpora').send({
      key: 'concurrency-contract-corpus',
      name: 'Concurrency contract corpus',
      scopeNote: 'Bounded to verifying the optimistic concurrency contract.'
    });
    expect(created.status).toBe(201);
    const corpusId = Number(created.body.corpus_id);
    const version = Number(created.body.version);

    const missingHeader = await authorized('patch', `/api/v1/corpora/${corpusId}`).send({ status: 'ACTIVE' });
    expect(missingHeader.status).toBe(400);
    expect(missingHeader.body.error.code).toBe('INVALID_REQUEST');

    const auditsBefore = await pool.query('SELECT count(*)::int AS count FROM audit_event');
    const stale = await authorized('patch', `/api/v1/corpora/${corpusId}`)
      .set('If-Match', String(version + 41))
      .send({ status: 'ACTIVE', name: 'Stale write that must not commit' });
    expect(stale.status).toBe(409);
    expect(stale.body.error.code).toBe('STALE_VERSION');

    const unchanged = await pool.query('SELECT name, status, version FROM corpus WHERE corpus_id = $1', [corpusId]);
    expect(unchanged.rows[0].name).toBe('Concurrency contract corpus');
    expect(unchanged.rows[0].status).not.toBe('ACTIVE');
    expect(Number(unchanged.rows[0].version)).toBe(version);
    const auditsAfter = await pool.query('SELECT count(*)::int AS count FROM audit_event');
    expect(auditsAfter.rows[0].count).toBe(auditsBefore.rows[0].count);

    const current = await authorized('patch', `/api/v1/corpora/${corpusId}`)
      .set('If-Match', String(version))
      .send({ status: 'ACTIVE' });
    expect(current.status).toBe(200);
    expect(Number(current.body.version)).toBe(version + 1);

    const replayed = await authorized('patch', `/api/v1/corpora/${corpusId}`)
      .set('If-Match', String(version))
      .send({ status: 'ARCHIVED' });
    expect(replayed.status).toBe(409);
    expect(replayed.body.error.code).toBe('STALE_VERSION');

    const unknownJob = await authorized('post', '/api/v1/jobs/2147483000/cancel').send({});
    expect(unknownJob.status).toBe(409);
    expect(unknownJob.body.error.code).toBe('INVALID_JOB_STATE');
  });

  it('keeps unmatched versioned routes and read routes free of mutation and truth assertions', async () => {
    const before = await snapshotPersistentTableCounts();

    const unmatched = await request(app).delete('/api/v1/claims/1');
    expect(unmatched.status).toBe(501);
    expect(unmatched.body.error.code).toBe('NOT_REPRESENTED');

    const truth = await request(app).post('/api/v1/research').send({ question: 'Prove that this claim is true.' });
    expect(truth.status).toBe(200);
    expect(truth.body.capability).toBe('NOT_REPRESENTED');
    expect(truth.body.results).toEqual([]);

    const forbidden = await request(secureApp).post('/api/v1/corpora').send({ key: 'x', name: 'x', scopeNote: 'x' });
    expect(forbidden.status).toBe(401);

    expect(await snapshotPersistentTableCounts()).toEqual(before);
  });
});
