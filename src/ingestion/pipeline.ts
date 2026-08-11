import type { Pool, PoolClient } from 'pg';
import { classifyCandidate, registerCandidateTerms } from './classifier.js';
import { parseManifest } from './manifest.js';
import {
  COUNTED_TABLES,
  type CandidateOutcome,
  type CountedTable,
  type GraphSnapshot,
  type IngestionReport,
  type IngestionTotals,
  type ManifestRow,
  type RegistrySnapshot
} from './types.js';

/**
 * Phase 28 transactional Tier-1 ingestion.
 *
 * The pipeline reads a manifest, classifies every row, persists only AUTO_ACCEPT rows, and builds
 * the complete provenance path Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation
 * -> SourceRecord -> Dataset -> Source for each persisted direct claim. Every write is keyed by a
 * stable natural key, so a second execution of the same manifest changes nothing. Rows that are
 * excluded, deferred, or invalid are reported with reasons and stay outside the graph; that is a
 * statement about Berean's representation status, never about the biblical source.
 */

export interface IngestionOptions {
  manifestText: string;
  manifestSource: string;
  /** When true the transaction is rolled back after reporting, leaving the graph untouched. */
  dryRun?: boolean;
}

const emptyTotals = (): IngestionTotals => ({
  TOTAL_CANDIDATES: 0,
  AUTO_ACCEPTED: 0,
  CANDIDATE_REQUIRES_REVIEW: 0,
  EXCLUDED: 0,
  INVALID: 0,
  ALREADY_PRESENT: 0,
  NEW_ENTITIES: 0,
  NEW_PROPOSITIONS: 0,
  NEW_CLAIMS: 0,
  NEW_EVENTS: 0,
  NEW_EVIDENCE: 0,
  NEW_CITATIONS: 0,
  NEW_SOURCE_RECORDS: 0,
  NEW_TYPED_VALUES: 0,
  NEW_MAPPINGS: 0,
  COMPLETE_PROVENANCE: 0,
  INCOMPLETE_PROVENANCE: 0,
  DUPLICATES_PREVENTED: 0
});

const BOUNDARY_NOTES = [
  'AUTO_ACCEPT means source-backed and automatically importable; it does not mean TRUE.',
  'CANDIDATE_REQUIRES_REVIEW means not automatically importable; it does not mean FALSE.',
  'EXCLUDED and NOT_YET_MODELED describe Berean representation status, not silence in the source.',
  'NOT_STORED_BY_POLICY marks locator-only source storage; it does not mean the source says nothing.',
  'External sources and external identifiers are discovery metadata only and are never persisted as facts.'
];

const countTables = async (client: PoolClient): Promise<Record<CountedTable, number>> => {
  const counts = {} as Record<CountedTable, number>;
  for (const table of COUNTED_TABLES) {
    const result = await client.query(`SELECT count(*)::int AS count FROM ${table}`);
    counts[table] = Number(result.rows[0].count);
  }
  return counts;
};

const loadRegistry = async (client: PoolClient): Promise<RegistrySnapshot> => {
  const predicates = await client.query(
    `SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
     FROM predicate`
  );
  const entityTypes = await client.query('SELECT entity_type_code FROM entity_type');
  const eventTypes = await client.query('SELECT event_type_code FROM event_type');
  const valueTypes = await client.query('SELECT value_type_code FROM value_type');
  const sources = await client.query('SELECT source_key FROM source');
  const datasets = await client.query(
    `SELECT d.dataset_key, s.source_key FROM dataset d JOIN source s ON s.source_id = d.source_id`
  );

  return {
    predicates: new Map(predicates.rows.map((row) => [row.predicate_code, row])),
    entityTypes: new Set(entityTypes.rows.map((row) => row.entity_type_code)),
    eventTypes: new Set(eventTypes.rows.map((row) => row.event_type_code)),
    valueTypes: new Set(valueTypes.rows.map((row) => row.value_type_code)),
    sourceKeys: new Set(sources.rows.map((row) => row.source_key)),
    datasetSourceKeys: new Map(datasets.rows.map((row) => [row.dataset_key, row.source_key]))
  };
};

const loadGraph = async (client: PoolClient): Promise<GraphSnapshot> => {
  const entities = await client.query('SELECT entity_key, entity_type_code, canonical_name FROM entity');
  const events = await client.query('SELECT event_key, event_type_code FROM event');
  const claims = await client.query('SELECT claim_key FROM claim');
  return {
    entityByKey: new Map(
      entities.rows.map((row) => [
        row.entity_key,
        { entity_type_code: row.entity_type_code, canonical_name: row.canonical_name }
      ])
    ),
    entityKeyByTypeAndName: new Map(
      entities.rows.map((row) => [
        `${row.entity_type_code}|${String(row.canonical_name).toLowerCase()}`,
        row.entity_key
      ])
    ),
    eventByKey: new Map(events.rows.map((row) => [row.event_key, { event_type_code: row.event_type_code }])),
    claimKeys: new Set(claims.rows.map((row) => row.claim_key))
  };
};

interface PersistenceCounters {
  entities: number;
  events: number;
  typedValues: number;
  propositions: number;
  claims: number;
  evidence: number;
  citations: number;
  sourceRecords: number;
  mappings: number;
}

const ensureSourceRecord = async (
  client: PoolClient,
  row: ManifestRow,
  counters: PersistenceCounters
): Promise<number> => {
  const existing = await client.query(
    `SELECT sr.source_record_id
     FROM source_record sr
     JOIN dataset d ON d.dataset_id = sr.dataset_id
     WHERE d.dataset_key = $1 AND sr.source_record_key = $2`,
    [row.dataset_key, row.source_record_key]
  );
  if (existing.rowCount) return Number(existing.rows[0].source_record_id);

  // Locator-only storage policy: raw_content and content_hash stay NULL.
  const inserted = await client.query(
    `INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
     SELECT d.dataset_id, $2, $3, 'ref-1' FROM dataset d WHERE d.dataset_key = $1
     RETURNING source_record_id`,
    [row.dataset_key, row.source_record_key, row.source_location]
  );
  counters.sourceRecords += 1;
  return Number(inserted.rows[0].source_record_id);
};

const ensureCitation = async (
  client: PoolClient,
  sourceRecordId: number,
  row: ManifestRow,
  counters: PersistenceCounters
): Promise<number> => {
  const existing = await client.query(
    'SELECT citation_id FROM citation WHERE source_record_id = $1 AND locator = $2',
    [sourceRecordId, row.source_location]
  );
  if (existing.rowCount) return Number(existing.rows[0].citation_id);

  // quoted_text stays NULL under the locator-only source storage policy.
  const inserted = await client.query(
    `INSERT INTO citation (citation_key, source_record_id, locator)
     VALUES ($1, $2, $3) RETURNING citation_id`,
    [`CITE_${row.source_record_key}`, sourceRecordId, row.source_location]
  );
  counters.citations += 1;
  return Number(inserted.rows[0].citation_id);
};

const ensureEvidence = async (
  client: PoolClient,
  sourceRecordId: number,
  citationId: number,
  row: ManifestRow,
  counters: PersistenceCounters
): Promise<number> => {
  const evidenceKey = `EV_${row.source_record_key}`;
  const existing = await client.query('SELECT evidence_id FROM evidence WHERE evidence_key = $1', [evidenceKey]);
  let evidenceId: number;
  if (existing.rowCount) {
    evidenceId = Number(existing.rows[0].evidence_id);
  } else {
    const inserted = await client.query(
      `INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
       VALUES ($1, $2, $3, 'SOURCE_OBSERVATION') RETURNING evidence_id`,
      [
        evidenceKey,
        sourceRecordId,
        `${row.source_location} is retained as an explicit source observation.`
      ]
    );
    counters.evidence += 1;
    evidenceId = Number(inserted.rows[0].evidence_id);
  }
  await client.query(
    'INSERT INTO evidence_citation (evidence_id, citation_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [evidenceId, citationId]
  );
  return evidenceId;
};

const ensureEntity = async (
  client: PoolClient,
  entityKey: string,
  entityType: string,
  canonicalName: string,
  description: string,
  counters: PersistenceCounters
): Promise<number> => {
  const existing = await client.query('SELECT entity_id FROM entity WHERE entity_key = $1', [entityKey]);
  if (existing.rowCount) return Number(existing.rows[0].entity_id);
  const inserted = await client.query(
    `INSERT INTO entity (entity_key, entity_type_code, canonical_name, description)
     VALUES ($1, $2, $3, $4) RETURNING entity_id`,
    [entityKey, entityType, canonicalName, description === '' ? null : description]
  );
  counters.entities += 1;
  return Number(inserted.rows[0].entity_id);
};

const ensureEvent = async (
  client: PoolClient,
  eventKey: string,
  eventType: string,
  description: string,
  counters: PersistenceCounters
): Promise<number> => {
  const existing = await client.query('SELECT event_id FROM event WHERE event_key = $1', [eventKey]);
  if (existing.rowCount) return Number(existing.rows[0].event_id);
  const inserted = await client.query(
    'INSERT INTO event (event_key, event_type_code, description) VALUES ($1, $2, $3) RETURNING event_id',
    [eventKey, eventType, description === '' ? null : description]
  );
  counters.events += 1;
  return Number(inserted.rows[0].event_id);
};

const ensureTypedValue = async (
  client: PoolClient,
  valueType: string,
  value: string,
  counters: PersistenceCounters
): Promise<number> => {
  const numeric = ['INTEGER', 'DECIMAL', 'YEAR'].includes(valueType);
  const existing = numeric
    ? await client.query(
        'SELECT typed_value_id FROM typed_value WHERE value_type_code = $1 AND numeric_value = $2',
        [valueType, value]
      )
    : await client.query(
        'SELECT typed_value_id FROM typed_value WHERE value_type_code = $1 AND text_value = $2',
        [valueType, value]
      );
  if (existing.rowCount) return Number(existing.rows[0].typed_value_id);

  const inserted = numeric
    ? await client.query(
        'INSERT INTO typed_value (value_type_code, numeric_value) VALUES ($1, $2) RETURNING typed_value_id',
        [valueType, value]
      )
    : await client.query(
        'INSERT INTO typed_value (value_type_code, text_value) VALUES ($1, $2) RETURNING typed_value_id',
        [valueType, value]
      );
  counters.typedValues += 1;
  return Number(inserted.rows[0].typed_value_id);
};

interface TermIds {
  subjectEntityId: number | null;
  subjectEventId: number | null;
  objectEntityId: number | null;
  objectEventId: number | null;
  objectTypedValueId: number | null;
}

const ensureProposition = async (
  client: PoolClient,
  row: ManifestRow,
  terms: TermIds,
  counters: PersistenceCounters
): Promise<number> => {
  const parameters = [
    terms.subjectEntityId,
    terms.subjectEventId,
    row.predicate,
    terms.objectEntityId,
    terms.objectEventId,
    terms.objectTypedValueId
  ];
  const existing = await client.query(
    `SELECT proposition_id FROM proposition
     WHERE subject_entity_id IS NOT DISTINCT FROM $1
       AND subject_event_id IS NOT DISTINCT FROM $2
       AND predicate = $3
       AND object_entity_id IS NOT DISTINCT FROM $4
       AND object_event_id IS NOT DISTINCT FROM $5
       AND object_typed_value_id IS NOT DISTINCT FROM $6`,
    parameters
  );
  if (existing.rowCount) return Number(existing.rows[0].proposition_id);

  const inserted = await client.query(
    `INSERT INTO proposition
       (subject_entity_id, subject_event_id, predicate, object_entity_id, object_event_id, object_typed_value_id)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING proposition_id`,
    parameters
  );
  counters.propositions += 1;
  return Number(inserted.rows[0].proposition_id);
};

const ensureMapping = async (
  client: PoolClient,
  row: ManifestRow,
  entityId: number,
  evidenceId: number,
  counters: PersistenceCounters
): Promise<void> => {
  // A canonical entity that already carries an ACTIVE reconciliation with this source needs no
  // second source identity; ingestion never re-reconciles what a human already reconciled.
  const existingMapping = await client.query(
    `SELECT esm.entity_source_mapping_id
     FROM entity_source_mapping esm
     JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
     JOIN source s ON s.source_id = si.source_id
     WHERE esm.entity_id = $1 AND s.source_key = $2 AND esm.mapping_status_code = 'ACTIVE'`,
    [entityId, row.source_key]
  );
  if (existingMapping.rowCount) return;

  const sourceIdentity = await client.query(
    `SELECT si.source_identity_id
     FROM source_identity si
     JOIN source s ON s.source_id = si.source_id
     WHERE s.source_key = $1 AND si.source_identity_key = $2`,
    [row.source_key, row.mapping_source_identity_key]
  );
  let sourceIdentityId: number;
  if (sourceIdentity.rowCount) {
    sourceIdentityId = Number(sourceIdentity.rows[0].source_identity_id);
  } else {
    const inserted = await client.query(
      `INSERT INTO source_identity (source_id, source_identity_key, display_name)
       SELECT s.source_id, $2, $3 FROM source s WHERE s.source_key = $1
       RETURNING source_identity_id`,
      [row.source_key, row.mapping_source_identity_key, row.mapping_display_name]
    );
    sourceIdentityId = Number(inserted.rows[0].source_identity_id);
  }

  await client.query(
    `INSERT INTO entity_source_mapping
       (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
     VALUES ($1, $2, 'ACTIVE', NULL, $3, $4)`,
    [sourceIdentityId, entityId, row.mapping_justification, evidenceId]
  );
  counters.mappings += 1;
};

/**
 * Verifies the full provenance path
 * Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source.
 */
export const hasCompleteProvenance = async (client: PoolClient, claimId: number): Promise<boolean> => {
  const result = await client.query(
    `SELECT 1
     FROM claim c
     JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
     JOIN evidence e ON e.evidence_id = ce.evidence_id
     JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
     JOIN citation ci ON ci.citation_id = ec.citation_id
     JOIN source_record sr ON sr.source_record_id = ci.source_record_id
     JOIN dataset d ON d.dataset_id = sr.dataset_id
     JOIN source s ON s.source_id = d.source_id
     WHERE c.claim_id = $1
     LIMIT 1`,
    [claimId]
  );
  return result.rowCount === 1;
};

const renderStatement = (row: ManifestRow): string => {
  const subject = row.subject_kind === 'ENTITY' ? row.subject_name || row.subject_key : row.subject_key;
  const object =
    row.object_kind === 'VALUE' ? row.object_value : row.object_name || row.object_key;
  return `${row.source_location} records ${subject} ${row.predicate} ${object}.`;
};

interface PersistOutcome {
  alreadyPresent: boolean;
  duplicatePrevented: boolean;
  completeProvenance: boolean;
}

const persistCandidate = async (
  client: PoolClient,
  row: ManifestRow,
  counters: PersistenceCounters
): Promise<PersistOutcome> => {
  const sourceRecordId = await ensureSourceRecord(client, row, counters);
  const citationId = await ensureCitation(client, sourceRecordId, row, counters);
  const evidenceId = await ensureEvidence(client, sourceRecordId, citationId, row, counters);

  const terms: TermIds = {
    subjectEntityId: null,
    subjectEventId: null,
    objectEntityId: null,
    objectEventId: null,
    objectTypedValueId: null
  };

  if (row.subject_kind === 'ENTITY') {
    terms.subjectEntityId = await ensureEntity(
      client,
      row.subject_key,
      row.subject_type,
      row.subject_name,
      row.subject_description,
      counters
    );
  } else {
    terms.subjectEventId = await ensureEvent(
      client,
      row.subject_key,
      row.subject_type,
      row.subject_description,
      counters
    );
  }

  if (row.object_kind === 'ENTITY') {
    terms.objectEntityId = await ensureEntity(
      client,
      row.object_key,
      row.object_type,
      row.object_name,
      row.object_description,
      counters
    );
  } else if (row.object_kind === 'EVENT') {
    terms.objectEventId = await ensureEvent(
      client,
      row.object_key,
      row.object_type,
      row.object_description,
      counters
    );
  } else {
    terms.objectTypedValueId = await ensureTypedValue(client, row.object_value_type, row.object_value, counters);
  }

  const propositionId = await ensureProposition(client, row, terms, counters);
  const claimKey = `CLAIM_${row.candidate_key}`;

  const existingClaim = await client.query(
    'SELECT claim_id, proposition_id FROM claim WHERE claim_key = $1',
    [claimKey]
  );
  let claimId: number;
  let alreadyPresent = false;
  let duplicatePrevented = false;

  if (existingClaim.rowCount) {
    if (Number(existingClaim.rows[0].proposition_id) !== propositionId) {
      throw new Error(`CLAIM_KEY_PROPOSITION_CONFLICT:${claimKey}`);
    }
    claimId = Number(existingClaim.rows[0].claim_id);
    alreadyPresent = true;
  } else {
    // An existing direct claim asserting the same proposition from the same evidence is the same
    // assertion under a different key. Reuse it rather than creating a second authoritative claim.
    const duplicate = await client.query(
      `SELECT c.claim_id FROM claim c
       JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.evidence_id = $2
       WHERE c.proposition_id = $1 AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
       ORDER BY c.claim_id LIMIT 1`,
      [propositionId, evidenceId]
    );
    if (duplicate.rowCount) {
      claimId = Number(duplicate.rows[0].claim_id);
      duplicatePrevented = true;
      alreadyPresent = true;
    } else {
      const inserted = await client.query(
        `INSERT INTO claim (claim_key, proposition_id, claim_type_code, claim_status_code, statement, notes)
         VALUES ($1, $2, 'DIRECT_SOURCE_CLAIM', 'ACTIVE', $3, $4) RETURNING claim_id`,
        [claimKey, propositionId, renderStatement(row), `Phase 28 automated ingestion of ${row.candidate_key}.`]
      );
      counters.claims += 1;
      claimId = Number(inserted.rows[0].claim_id);
    }
  }

  const linked = await client.query(
    `INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
     VALUES ($1, $2, 'SUPPORTS', $3)
     ON CONFLICT DO NOTHING
     RETURNING claim_evidence_id`,
    [claimId, evidenceId, 'Direct source observation for this Phase 28 manifest candidate.']
  );
  if (linked.rowCount) alreadyPresent = false;

  // The reconciliation target is the row's entity term: its subject entity, or its object entity
  // when the subject is an event (for example an occursAt row that names a place).
  const mappingEntityId = terms.subjectEntityId ?? terms.objectEntityId;
  if (row.mapping_source_identity_key !== '' && mappingEntityId !== null) {
    await ensureMapping(client, row, mappingEntityId, evidenceId, counters);
  }

  const completeProvenance = await hasCompleteProvenance(client, claimId);
  if (!completeProvenance) throw new Error(`INCOMPLETE_PROVENANCE:${row.candidate_key}`);

  return { alreadyPresent, duplicatePrevented, completeProvenance };
};

export const runIngestion = async (pool: Pool, options: IngestionOptions): Promise<IngestionReport> => {
  const rows = parseManifest(options.manifestText);
  const totals = emptyTotals();
  const outcomes: CandidateOutcome[] = [];
  const counters: PersistenceCounters = {
    entities: 0,
    events: 0,
    typedValues: 0,
    propositions: 0,
    claims: 0,
    evidence: 0,
    citations: 0,
    sourceRecords: 0,
    mappings: 0
  };

  const client = await pool.connect();
  let committed = false;
  try {
    await client.query('BEGIN');
    const beforeCounts = await countTables(client);
    const registry = await loadRegistry(client);
    const graph = await loadGraph(client);
    const seenCandidateKeys = new Set<string>();

    for (const row of rows) {
      totals.TOTAL_CANDIDATES += 1;
      const classification = classifyCandidate(row, registry, graph, seenCandidateKeys);
      seenCandidateKeys.add(row.candidate_key);

      const externalMetadataStatus =
        row.external_source !== '' || row.external_identifier !== '' ? 'DISCOVERY_METADATA_ONLY' : 'NONE';

      if (classification.classification !== 'AUTO_ACCEPT') {
        totals[classification.classification] += 1;
        outcomes.push({
          ...classification,
          claim_key: null,
          persisted: false,
          already_present: false,
          duplicate_prevented: false,
          provenance_status: 'NOT_PERSISTED',
          source_backed_status: 'NOT_AUTOMATICALLY_IMPORTED',
          external_metadata_status: externalMetadataStatus
        });
        continue;
      }

      await client.query('SAVEPOINT candidate');
      const countersBeforeCandidate = { ...counters };
      try {
        const result = await persistCandidate(client, row, counters);
        await client.query('RELEASE SAVEPOINT candidate');
        registerCandidateTerms(row, graph);
        graph.claimKeys.add(`CLAIM_${row.candidate_key}`);
        totals.AUTO_ACCEPTED += 1;
        totals.COMPLETE_PROVENANCE += 1;
        if (result.alreadyPresent) totals.ALREADY_PRESENT += 1;
        if (result.duplicatePrevented) totals.DUPLICATES_PREVENTED += 1;
        outcomes.push({
          ...classification,
          claim_key: `CLAIM_${row.candidate_key}`,
          persisted: !result.alreadyPresent,
          already_present: result.alreadyPresent,
          duplicate_prevented: result.duplicatePrevented,
          provenance_status: 'COMPLETE_PROVENANCE',
          source_backed_status: 'SOURCE_BACKED',
          external_metadata_status: externalMetadataStatus
        });
      } catch (error) {
        // The candidate graph is rolled back completely; nothing partial survives, so the new-row
        // counters return to their pre-candidate values.
        await client.query('ROLLBACK TO SAVEPOINT candidate');
        await client.query('RELEASE SAVEPOINT candidate');
        Object.assign(counters, countersBeforeCandidate);
        const message = error instanceof Error ? error.message : String(error);
        const incomplete = message.startsWith('INCOMPLETE_PROVENANCE');
        if (incomplete) totals.INCOMPLETE_PROVENANCE += 1;
        totals.INVALID += 1;
        outcomes.push({
          candidate_key: row.candidate_key,
          classification: 'INVALID',
          reasons: [incomplete ? 'INCOMPLETE_PROVENANCE' : `PERSISTENCE_ROLLED_BACK:${message}`],
          claim_key: null,
          persisted: false,
          already_present: false,
          duplicate_prevented: false,
          provenance_status: incomplete ? 'INCOMPLETE_PROVENANCE' : 'NOT_PERSISTED',
          source_backed_status: 'NOT_AUTOMATICALLY_IMPORTED',
          external_metadata_status: externalMetadataStatus
        });
      }
    }

    totals.NEW_ENTITIES = counters.entities;
    totals.NEW_EVENTS = counters.events;
    totals.NEW_TYPED_VALUES = counters.typedValues;
    totals.NEW_PROPOSITIONS = counters.propositions;
    totals.NEW_CLAIMS = counters.claims;
    totals.NEW_EVIDENCE = counters.evidence;
    totals.NEW_CITATIONS = counters.citations;
    totals.NEW_SOURCE_RECORDS = counters.sourceRecords;
    totals.NEW_MAPPINGS = counters.mappings;

    const afterCounts = await countTables(client);
    const deltaCounts = {} as Record<CountedTable, number>;
    for (const table of COUNTED_TABLES) deltaCounts[table] = afterCounts[table] - beforeCounts[table];

    if (options.dryRun) {
      await client.query('ROLLBACK');
    } else {
      await client.query('COMMIT');
      committed = true;
    }

    return {
      manifest_source: options.manifestSource,
      committed,
      totals,
      candidates: outcomes,
      not_accepted_reasons: outcomes
        .filter((outcome) => outcome.classification !== 'AUTO_ACCEPT')
        .map((outcome) => ({
          candidate_key: outcome.candidate_key,
          classification: outcome.classification,
          reasons: outcome.reasons
        })),
      before_counts: beforeCounts,
      after_counts: afterCounts,
      delta_counts: deltaCounts,
      boundary_notes: BOUNDARY_NOTES
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
