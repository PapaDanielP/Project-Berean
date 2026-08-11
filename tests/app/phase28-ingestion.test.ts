import path from 'node:path';
import fs from 'node:fs/promises';
import { beforeAll, describe, expect, it } from 'vitest';
import { Pool, type PoolClient } from 'pg';
import { hasCompleteProvenance, runIngestion } from '../../src/ingestion/pipeline.js';
import { parseManifest } from '../../src/ingestion/manifest.js';
import { MANIFEST_COLUMNS, type IngestionReport, type ManifestRow } from '../../src/ingestion/types.js';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required for Phase 28 ingestion tests');
}

const repoRoot = path.resolve(__dirname, '../..');
const TEST_SCHEMA = 'phase28_ingestion';

// The ingestion tests own an isolated schema so they never touch the fixtures loaded into public.
const adminPool = new Pool({ connectionString: databaseUrl });
const pool = new Pool({
  connectionString: databaseUrl,
  options: `-c search_path=${TEST_SCHEMA}`
});

const manifestPath = 'data/ingestion/phase28-genesis-manifest.csv';
let manifestText = '';

const readRepoFile = async (relativePath: string): Promise<string> =>
  fs.readFile(path.join(repoRoot, relativePath), 'utf8');

const ingest = async (text: string, source = manifestPath): Promise<IngestionReport> =>
  runIngestion(pool, { manifestText: text, manifestSource: source });

const outcomeFor = (report: IngestionReport, candidateKey: string) => {
  const outcome = report.candidates.find((candidate) => candidate.candidate_key === candidateKey);
  if (!outcome) throw new Error(`missing candidate outcome: ${candidateKey}`);
  return outcome;
};

const toCsv = (rows: Partial<ManifestRow>[]): string => {
  const escape = (value: string): string =>
    /[",\n]/.test(value) ? `"${value.replace(/"/g, '""')}"` : value;
  const lines = [MANIFEST_COLUMNS.join(',')];
  for (const row of rows) {
    lines.push(MANIFEST_COLUMNS.map((column) => escape(row[column] ?? '')).join(','));
  }
  return `${lines.join('\n')}\n`;
};

/** A structurally complete auto-accept row that individual tests mutate to isolate one failure. */
const baseRow = (overrides: Partial<ManifestRow> = {}): Partial<ManifestRow> => ({
  candidate_key: 'TEST_BASE',
  entity_type: 'PERSON',
  candidate_name: 'Kenan',
  biblical_references: 'Genesis 5:12',
  explicit_textual_description: 'Genesis 5:12 states that Kenan begot Mahalalel.',
  proposed_proposition: 'kenan fatherOf mahalalel',
  source_status: 'EXPLICIT_IN_SELECTED_CORPUS',
  review_status: 'PROPOSED_AUTO_ACCEPT',
  proposed_mapping_decision: 'Map the Genesis source referent to the canonical entity.',
  inference_flag: 'NONE',
  source_key: 'GEN_MT',
  dataset_key: 'GEN_MT_REF',
  source_record_key: 'MT_GEN_5_12',
  source_location: 'Genesis 5:12',
  subject_kind: 'ENTITY',
  subject_key: 'kenan',
  subject_type: 'PERSON',
  subject_name: 'Kenan',
  subject_description: 'Person named in the Genesis genealogy.',
  predicate: 'fatherOf',
  object_kind: 'ENTITY',
  object_key: 'mahalalel',
  object_type: 'PERSON',
  object_name: 'Mahalalel',
  object_description: 'Person named in the Genesis genealogy.',
  mapping_source_identity_key: 'mt-test-kenan',
  mapping_display_name: 'Kenan',
  mapping_justification: 'Genesis 5:12 explicitly names this source referent.',
  ...overrides
});

let baselineReport: IngestionReport;
let secondReport: IngestionReport;

const countRows = async (sql: string, values: unknown[] = []): Promise<number> => {
  const result = await pool.query(sql, values);
  return Number(result.rows[0].count);
};

beforeAll(async () => {
  await adminPool.query(`DROP SCHEMA IF EXISTS ${TEST_SCHEMA} CASCADE`);
  await adminPool.query(`CREATE SCHEMA ${TEST_SCHEMA}`);
  await pool.query(await readRepoFile('schema/sql/001_core_schema.sql'));
  await pool.query(await readRepoFile('tests/fixtures/020-genesis-1-11-fixture.sql'));

  manifestText = await readRepoFile(manifestPath);
  baselineReport = await ingest(manifestText);
  secondReport = await ingest(manifestText);
}, 120_000);

describe('Phase 28 manifest', () => {
  it('parses with the declared columns and no invalid rows', () => {
    const rows = parseManifest(manifestText);
    expect(rows.length).toBeGreaterThan(0);
    expect(baselineReport.totals.TOTAL_CANDIDATES).toBe(rows.length);
    expect(baselineReport.totals.INVALID).toBe(0);
  });

  it('reports a reason for every candidate that is not auto-accepted', () => {
    for (const entry of baselineReport.not_accepted_reasons) {
      expect(entry.reasons.length).toBeGreaterThan(0);
    }
    expect(baselineReport.not_accepted_reasons.length).toBe(
      baselineReport.totals.CANDIDATE_REQUIRES_REVIEW +
        baselineReport.totals.EXCLUDED +
        baselineReport.totals.INVALID
    );
  });

  it('classifies every candidate into exactly one of the four outcomes', () => {
    const { totals } = baselineReport;
    expect(
      totals.AUTO_ACCEPTED + totals.CANDIDATE_REQUIRES_REVIEW + totals.EXCLUDED + totals.INVALID
    ).toBe(totals.TOTAL_CANDIDATES);
  });
});

describe('Phase 28 acceptance of explicit source assertions', () => {
  it('persists the accepted Enoch parentage, age, and participation claims', async () => {
    const acceptedKeys = [
      'P28_GEN_5_18_JARED_FATHER_ENOCH',
      'P28_GEN_5_21_ENOCH_FATHER_METHUSELAH',
      'P28_GEN_5_21_ENOCH_AGE_AT_FATHERHOOD_65',
      'P28_GEN_5_18_ENOCH_CHILD_IN_BEGETTING',
      'P28_GEN_5_21_ENOCH_PARENT_IN_BEGETTING'
    ];
    for (const key of acceptedKeys) {
      expect(outcomeFor(baselineReport, key).classification).toBe('AUTO_ACCEPT');
      const claims = await countRows('SELECT count(*)::int AS count FROM claim WHERE claim_key = $1', [
        `CLAIM_${key}`
      ]);
      expect(claims).toBe(1);
    }
  });

  it('records the explicit Enoch age at fatherhood as a typed value', async () => {
    const result = await pool.query(
      `SELECT tv.value_type_code, tv.numeric_value
       FROM claim c
       JOIN proposition p ON p.proposition_id = c.proposition_id
       JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
       WHERE c.claim_key = 'CLAIM_P28_GEN_5_21_ENOCH_AGE_AT_FATHERHOOD_65'`
    );
    expect(result.rowCount).toBe(1);
    expect(result.rows[0].value_type_code).toBe('YEAR');
    expect(Number(result.rows[0].numeric_value)).toBe(65);
  });

  it('projects accepted event participation without a second participant store', async () => {
    const result = await pool.query(
      `SELECT ep.role_code
       FROM event_participation ep
       JOIN event ev ON ev.event_id = ep.event_id
       JOIN entity e ON e.entity_id = ep.entity_id
       WHERE ev.event_key = 'methuselah_begetting' AND e.entity_key = 'enoch'`
    );
    expect(result.rowCount).toBeGreaterThan(0);
    expect(result.rows.map((row) => row.role_code)).toContain('PARENT');
  });

  it('populates people, places, objects, and events named by the manifest', async () => {
    const entityKeys = [
      'abraham',
      'jacob',
      'joseph',
      'sarah',
      'isaac',
      'noah',
      'canaan',
      'egypt',
      'hebron',
      'noahs_ark'
    ];
    for (const key of entityKeys) {
      expect(
        await countRows('SELECT count(*)::int AS count FROM entity WHERE entity_key = $1', [key])
      ).toBe(1);
    }
    expect(
      await countRows("SELECT count(*)::int AS count FROM event WHERE event_key = 'joseph_imprisonment'")
    ).toBe(1);
  });

  it('builds a complete provenance chain for every accepted claim', async () => {
    const incomplete = await pool.query(
      `SELECT c.claim_key
       FROM claim c
       WHERE c.claim_key LIKE 'CLAIM_P28_%'
         AND NOT EXISTS (
           SELECT 1
           FROM claim_evidence ce
           JOIN evidence e ON e.evidence_id = ce.evidence_id
           JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
           JOIN citation ci ON ci.citation_id = ec.citation_id
           JOIN source_record sr ON sr.source_record_id = ci.source_record_id
           JOIN dataset d ON d.dataset_id = sr.dataset_id
           JOIN source s ON s.source_id = d.source_id
           WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
         )`
    );
    expect(incomplete.rowCount).toBe(0);
    expect(baselineReport.totals.COMPLETE_PROVENANCE).toBe(baselineReport.totals.AUTO_ACCEPTED);
    expect(baselineReport.totals.INCOMPLETE_PROVENANCE).toBe(0);
  });

  it('keeps source storage locator-only for records created by ingestion', async () => {
    const stored = await countRows(
      `SELECT count(*)::int AS count FROM source_record
       WHERE raw_content IS NOT NULL OR content_hash IS NOT NULL`
    );
    expect(stored).toBe(0);
    expect(await countRows('SELECT count(*)::int AS count FROM citation WHERE quoted_text IS NOT NULL')).toBe(0);
  });

  it('creates active source identity mappings with justification and supporting evidence', async () => {
    const mappings = await pool.query(
      `SELECT esm.mapping_status_code, esm.justification, esm.supporting_evidence_id
       FROM entity_source_mapping esm
       JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
       WHERE si.source_identity_key LIKE 'mt-p28-%'`
    );
    expect(mappings.rowCount).toBeGreaterThan(0);
    for (const row of mappings.rows) {
      expect(row.mapping_status_code).toBe('ACTIVE');
      expect(row.justification).toBeTruthy();
      expect(row.supporting_evidence_id).not.toBeNull();
    }
  });
});

describe('Phase 28 rejection of inference beyond explicit source statements', () => {
  it('keeps the non-auto-approved Enoch candidates outside the graph', async () => {
    const deferred = [
      ['P28_GEN_5_23_ENOCH_AGE_AT_DEATH_365', 'CANDIDATE_REQUIRES_REVIEW'],
      ['P28_GEN_5_24_ENOCH_ASCENSION', 'EXCLUDED'],
      ['P28_GEN_4_17_ENOCH_SON_OF_CAIN', 'EXCLUDED'],
      ['P28_EXT_ENOCH_AUTHORED_1_ENOCH', 'EXCLUDED']
    ] as const;
    for (const [key, classification] of deferred) {
      const outcome = outcomeFor(baselineReport, key);
      expect(outcome.classification).toBe(classification);
      expect(outcome.persisted).toBe(false);
      expect(outcome.source_backed_status).toBe('NOT_AUTOMATICALLY_IMPORTED');
      expect(
        await countRows('SELECT count(*)::int AS count FROM claim WHERE claim_key = $1', [`CLAIM_${key}`])
      ).toBe(0);
    }
  });

  it('refuses identity, geography, chronology, theology, causation, and harmonization candidates', () => {
    const flagged = [
      'P28_GEN_4_17_ENOCH_SON_OF_CAIN',
      'P28_MODERN_LOCATIONS',
      'P28_GENESIS_CHRONOLOGY',
      'P28_GEN_5_24_ENOCH_ASCENSION',
      'P28_JOSEPH_SALE_CAUSATION',
      'P28_GEN_1_2_CREATION_HARMONIZATION'
    ];
    for (const key of flagged) {
      const outcome = outcomeFor(baselineReport, key);
      expect(['CANDIDATE_REQUIRES_REVIEW', 'EXCLUDED']).toContain(outcome.classification);
      expect(outcome.persisted).toBe(false);
    }
  });

  it('treats external-only assertions as discovery metadata and never as facts', async () => {
    const outcome = outcomeFor(baselineReport, 'P28_EXT_THEOGRAPHIC_PERSON_IDS');
    expect(outcome.classification).toBe('EXCLUDED');
    expect(outcome.external_metadata_status).toBe('DISCOVERY_METADATA_ONLY');
    expect(
      await countRows(
        `SELECT count(*)::int AS count FROM source_identity si
         JOIN source s ON s.source_id = si.source_id
         WHERE s.source_key <> 'GEN_MT' AND si.source_identity_key LIKE 'mt-p28-%'`
      )
    ).toBe(0);
  });

  it('downgrades an otherwise well-formed row that carries an inference flag', async () => {
    const report = await ingest(
      toCsv([
        baseRow({
          candidate_key: 'TEST_INFERENCE_FLAG',
          inference_flag: 'CHRONOLOGY_INFERENCE'
        })
      ]),
      'test:inference-flag'
    );
    const outcome = outcomeFor(report, 'TEST_INFERENCE_FLAG');
    expect(outcome.classification).toBe('CANDIDATE_REQUIRES_REVIEW');
    expect(outcome.reasons).toContain('PROHIBITED_INFERENCE_FLAG:CHRONOLOGY_INFERENCE');
    expect(report.totals.NEW_CLAIMS).toBe(0);
  });

  it('does not accept a candidate on the strength of a biblical reference alone', async () => {
    const report = await ingest(
      toCsv([
        baseRow({
          candidate_key: 'TEST_REFERENCE_ONLY',
          predicate: 'walkedWithGod',
          object_kind: 'VALUE',
          object_value_type: 'TEXT',
          object_value: 'true',
          object_key: '',
          object_type: '',
          object_name: '',
          object_description: ''
        })
      ]),
      'test:reference-only'
    );
    const outcome = outcomeFor(report, 'TEST_REFERENCE_ONLY');
    expect(outcome.classification).toBe('INVALID');
    expect(outcome.reasons).toContain('UNREGISTERED_PREDICATE');
  });
});

describe('Phase 28 structural validation', () => {
  const invalidCases: [string, Partial<ManifestRow>, string][] = [
    ['unregistered predicate', { predicate: 'wasProbablyRelatedTo' }, 'UNREGISTERED_PREDICATE'],
    [
      'unknown entity type',
      { subject_key: 'unknown_type_person', subject_name: 'Unknown Type Person', subject_type: 'DEITY' },
      'UNKNOWN_ENTITY_TYPE:subject'
    ],
    ['unknown source reference', { source_key: 'NOT_A_SOURCE' }, 'UNKNOWN_SOURCE_REFERENCE'],
    ['missing exclusion reason', { review_status: 'EXCLUDED' }, 'MISSING_REQUIRED_FIELD:exclusion_reason'],
    ['unknown enum value', { source_status: 'PROBABLY_TRUE' }, 'UNKNOWN_ENUM_VALUE:source_status'],
    [
      'missing mapping justification',
      { mapping_justification: '' },
      'MISSING_MAPPING_JUSTIFICATION'
    ]
  ];

  for (const [name, overrides, reason] of invalidCases) {
    it(`rejects ${name}`, async () => {
      const report = await ingest(
        toCsv([baseRow({ candidate_key: 'TEST_INVALID', ...overrides })]),
        `test:${name}`
      );
      const outcome = outcomeFor(report, 'TEST_INVALID');
      expect(outcome.classification).toBe('INVALID');
      expect(outcome.reasons).toContain(reason);
      expect(report.totals.NEW_CLAIMS).toBe(0);
      expect(report.delta_counts.claim).toBe(0);
    });
  }

  it('rejects an invalid typed value for a numeric value type', async () => {
    const report = await ingest(
      toCsv([
        baseRow({
          candidate_key: 'TEST_INVALID_VALUE',
          predicate: 'ageAtDeathYears',
          object_kind: 'VALUE',
          object_key: '',
          object_type: '',
          object_name: '',
          object_description: '',
          object_value_type: 'INTEGER',
          object_value: 'nine hundred'
        })
      ]),
      'test:invalid-typed-value'
    );
    expect(outcomeFor(report, 'TEST_INVALID_VALUE').reasons).toContain('INVALID_TYPED_VALUE');
  });

  it('rejects a second canonical entity that reuses an existing type and name', async () => {
    const report = await ingest(
      toCsv([
        baseRow({
          candidate_key: 'TEST_DUPLICATE_CANONICAL',
          subject_key: 'enoch_of_cain',
          subject_name: 'Enoch',
          object_key: 'mahalalel',
          object_name: 'Mahalalel'
        })
      ]),
      'test:duplicate-canonical'
    );
    const outcome = outcomeFor(report, 'TEST_DUPLICATE_CANONICAL');
    expect(outcome.classification).toBe('INVALID');
    expect(outcome.reasons).toContain('DUPLICATE_CANONICAL_ENTITY:subject');
  });

  it('rejects a manifest whose header does not match the declared columns', () => {
    expect(() => parseManifest('candidate_key,entity_type\nX,PERSON\n')).toThrow(/header must be exactly/);
  });
});

describe('Phase 28 transaction and idempotency behaviour', () => {
  it('reports a second execution of the same manifest as fully already present', () => {
    expect(secondReport.totals.AUTO_ACCEPTED).toBe(baselineReport.totals.AUTO_ACCEPTED);
    expect(secondReport.totals.ALREADY_PRESENT).toBe(secondReport.totals.AUTO_ACCEPTED);
    expect(secondReport.totals.NEW_ENTITIES).toBe(0);
    expect(secondReport.totals.NEW_PROPOSITIONS).toBe(0);
    expect(secondReport.totals.NEW_CLAIMS).toBe(0);
    expect(secondReport.totals.NEW_EVENTS).toBe(0);
    expect(secondReport.totals.NEW_EVIDENCE).toBe(0);
    expect(secondReport.totals.NEW_CITATIONS).toBe(0);
    expect(secondReport.totals.NEW_MAPPINGS).toBe(0);
    for (const delta of Object.values(secondReport.delta_counts)) {
      expect(delta).toBe(0);
    }
  });

  it('prevents a duplicate claim asserting an existing proposition from the same evidence', async () => {
    const rows = parseManifest(manifestText);
    const original = rows.find(
      (row) => row.candidate_key === 'P28_GEN_5_18_JARED_FATHER_ENOCH'
    ) as ManifestRow;
    const report = await ingest(
      toCsv([{ ...original, candidate_key: 'TEST_DUPLICATE_CLAIM' }]),
      'test:duplicate-claim'
    );
    const outcome = outcomeFor(report, 'TEST_DUPLICATE_CLAIM');
    expect(outcome.classification).toBe('AUTO_ACCEPT');
    expect(outcome.duplicate_prevented).toBe(true);
    expect(report.totals.DUPLICATES_PREVENTED).toBe(1);
    expect(report.totals.NEW_CLAIMS).toBe(0);
    expect(report.delta_counts.claim).toBe(0);
  });

  it('rolls back a candidate completely when part of its graph cannot be persisted', async () => {
    const conflicting = baseRow({
      candidate_key: 'TEST_ROLLBACK',
      subject_key: 'rollback_person',
      subject_name: 'Rollback Person',
      object_key: 'rollback_child',
      object_name: 'Rollback Child',
      mapping_source_identity_key: 'mt-test-rollback',
      mapping_display_name: 'Rollback Person'
    });
    // A claim key that already asserts a different proposition cannot be reused for this candidate.
    await pool.query(
      `INSERT INTO claim (claim_key, proposition_id, claim_type_code, claim_status_code, statement)
       SELECT 'CLAIM_TEST_ROLLBACK', c.proposition_id, 'DIRECT_SOURCE_CLAIM', 'ACTIVE', 'conflicting claim'
       FROM claim c WHERE c.claim_key = 'CLAIM_P28_GEN_5_18_JARED_FATHER_ENOCH'`
    );

    const before = await countRows('SELECT count(*)::int AS count FROM entity');
    const report = await ingest(toCsv([conflicting]), 'test:rollback');
    const outcome = outcomeFor(report, 'TEST_ROLLBACK');

    expect(outcome.classification).toBe('INVALID');
    expect(outcome.persisted).toBe(false);
    expect(report.totals.NEW_ENTITIES).toBe(0);
    expect(report.delta_counts.entity).toBe(0);
    expect(await countRows('SELECT count(*)::int AS count FROM entity')).toBe(before);
    expect(
      await countRows("SELECT count(*)::int AS count FROM entity WHERE entity_key = 'rollback_person'")
    ).toBe(0);

    await pool.query("DELETE FROM claim WHERE claim_key = 'CLAIM_TEST_ROLLBACK'");
  });

  it('leaves the graph untouched for a dry run', async () => {
    const dryRunManifest = toCsv([
      baseRow({
        candidate_key: 'TEST_DRY_RUN',
        subject_key: 'dry_run_person',
        subject_name: 'Dry Run Person',
        object_key: 'dry_run_child',
        object_name: 'Dry Run Child',
        mapping_source_identity_key: 'mt-test-dry-run',
        mapping_display_name: 'Dry Run Person'
      })
    ]);
    const report = await runIngestion(pool, {
      manifestText: dryRunManifest,
      manifestSource: 'test:dry-run',
      dryRun: true
    });
    expect(report.committed).toBe(false);
    expect(outcomeFor(report, 'TEST_DRY_RUN').classification).toBe('AUTO_ACCEPT');
    expect(
      await countRows("SELECT count(*)::int AS count FROM entity WHERE entity_key = 'dry_run_person'")
    ).toBe(0);
  });

  it('detects a claim without supporting evidence as incomplete provenance', async () => {
    const client = (await pool.connect()) as PoolClient;
    try {
      await client.query('BEGIN');
      const inserted = await client.query(
        `INSERT INTO claim (claim_key, proposition_id, claim_type_code, claim_status_code, statement)
         SELECT 'CLAIM_TEST_NO_EVIDENCE', c.proposition_id, 'DIRECT_SOURCE_CLAIM', 'ACTIVE', 'no evidence'
         FROM claim c WHERE c.claim_key = 'CLAIM_P28_GEN_5_18_JARED_FATHER_ENOCH'
         RETURNING claim_id`
      );
      const claimId = Number(inserted.rows[0].claim_id);
      expect(await hasCompleteProvenance(client, claimId)).toBe(false);
    } finally {
      await client.query('ROLLBACK');
      client.release();
    }
  });
});

describe('Phase 28 boundary semantics', () => {
  it('states the classification boundaries in every report', () => {
    const notes = baselineReport.boundary_notes.join(' ');
    expect(notes).toContain('AUTO_ACCEPT');
    expect(notes).toContain('does not mean TRUE');
    expect(notes).toContain('does not mean FALSE');
    expect(notes).toContain('not silence in the source');
    expect(notes).toContain('NOT_STORED_BY_POLICY');
  });

  it('reports before, after, and delta counts for the ingested tables', () => {
    for (const table of Object.keys(baselineReport.delta_counts)) {
      const key = table as keyof typeof baselineReport.delta_counts;
      expect(baselineReport.after_counts[key] - baselineReport.before_counts[key]).toBe(
        baselineReport.delta_counts[key]
      );
    }
  });

  it('distinguishes source-backed candidates from candidates that were not imported', () => {
    const sourceBacked = baselineReport.candidates.filter(
      (candidate) => candidate.source_backed_status === 'SOURCE_BACKED'
    );
    const notImported = baselineReport.candidates.filter(
      (candidate) => candidate.source_backed_status === 'NOT_AUTOMATICALLY_IMPORTED'
    );
    expect(sourceBacked.length).toBe(baselineReport.totals.AUTO_ACCEPTED);
    expect(notImported.length).toBe(
      baselineReport.totals.TOTAL_CANDIDATES - baselineReport.totals.AUTO_ACCEPTED
    );
  });
});
