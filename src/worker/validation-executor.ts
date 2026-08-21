// Read-only structural validation executor (R2-02).
//
// This executor reproduces bounded structural checks against already-modelled
// structures. A PASS is an operational reproducibility record: it is never a
// historical truth determination, a scholarly adjudication, a contradiction
// resolution, or a validation of a claim in the epistemic sense.
//
// The executor only reads. It writes nothing except immutable `validation_result`
// rows through the caller-supplied persistence callback.

import type { Pool, PoolClient } from 'pg';

export type ValidationStatus = 'PASS' | 'FAIL' | 'WARNING' | 'NOT_APPLICABLE';

export interface ValidationResultInput {
  validationType: string;
  status: ValidationStatus;
  code: string;
  message: string;
  subjectType?: string | null;
  subjectId?: number | null;
}

export type Queryable = Pool | PoolClient;

/** Validation types this executor implements, in deterministic execution order. */
export const EXECUTED_VALIDATION_TYPES = ['SCHEMA', 'PROVENANCE', 'NEGATIVE_SEMANTIC', 'READ_ONLY'] as const;

/** Accepted request values this executor deliberately does not implement yet. */
export const DEFERRED_VALIDATION_TYPES = [
  'REGISTRY', 'IDENTITY', 'CLAIM', 'EVIDENCE', 'DERIVATION', 'CORPUS', 'REPLAY'
] as const;

/** Baseline tables this runtime requires. Structural only; not a schema diff tool. */
const REQUIRED_TABLES = [
  'source', 'dataset', 'source_record', 'citation', 'entity', 'source_identity',
  'entity_source_mapping', 'event', 'typed_value', 'predicate', 'proposition',
  'claim', 'derivation', 'derivation_input', 'evidence', 'evidence_citation',
  'claim_evidence', 'claim_relation',
  'workflow_actor', 'asynchronous_job', 'validation_run', 'validation_result', 'audit_event'
] as const;

/** Core structural views the read API depends on. */
const REQUIRED_VIEWS = ['claim_rendering', 'event_participation'] as const;

/**
 * Authoritative knowledge and controlled-registry tables. The READ_ONLY check
 * asserts that executing this executor leaves every one of them unchanged.
 * Workflow, result, and audit tables are deliberately excluded because the
 * worker is expected to append to them.
 */
export const KNOWLEDGE_TABLES = [
  'source_type', 'entity_type', 'claim_type', 'claim_status', 'evidence_type',
  'claim_evidence_relation_type', 'mapping_status', 'event_type',
  'event_participation_role', 'claim_relation_type', 'value_type', 'term_kind',
  'predicate', 'source', 'dataset', 'source_record', 'citation', 'entity',
  'source_identity', 'source_identity_alternate_name', 'entity_source_mapping',
  'event', 'typed_value', 'proposition', 'claim', 'derivation', 'evidence',
  'derivation_input', 'evidence_citation', 'claim_evidence', 'claim_relation'
] as const;

/**
 * Predicate semantics the platform explicitly prohibits. Berean registers
 * source-recorded relations; it never registers automatic proof, truth,
 * adjudication, or generalized inference semantics.
 */
const FORBIDDEN_PREDICATE_PATTERN =
  /(proves|proof|istrue|verifiedtrue|confirmstruth|truthof|adjudicat|resolvescontradiction|refutes|disproves|harmoniz|autoinfer|automaticallyinfer|infersthat|generalinference)/;

/** Closed set of workflow job types the platform is allowed to persist. */
const ALLOWED_JOB_TYPES = ['DISCOVERY', 'INGESTION', 'VALIDATION', 'EXPORT', 'SYSTEM_NOOP'] as const;

/** Upper bound on individually reported violations per check. */
const VIOLATION_REPORT_LIMIT = 50;

/** Upper bound on a persisted validation result message. */
const MESSAGE_LIMIT = 500;

export class ValidationExecutorError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = 'ValidationExecutorError';
  }
}

/** Bounds and sanitises a persisted message so no internal detail leaks unbounded. */
export const boundedMessage = (message: string): string => {
  const collapsed = [...message]
    .map((character) => {
      const code = character.codePointAt(0) ?? 0;
      return code < 0x20 || code === 0x7f ? ' ' : character;
    })
    .join('')
    .replace(/\s+/g, ' ')
    .trim();
  return collapsed.length > MESSAGE_LIMIT ? `${collapsed.slice(0, MESSAGE_LIMIT - 1)}…` : collapsed;
};

const identifier = (name: string): string => {
  if (!/^[a-z][a-z0-9_]*$/.test(name)) throw new ValidationExecutorError('VALIDATION_INVALID_IDENTIFIER', 'Unexpected identifier.');
  return `"${name}"`;
};

export const checkSchema = async (db: Queryable): Promise<ValidationResultInput[]> => {
  const present = await db.query(
    `SELECT required.name AS name, c.relkind AS relkind
     FROM unnest($1::text[]) WITH ORDINALITY AS required(name, ord)
     LEFT JOIN pg_catalog.pg_class c ON c.oid = to_regclass(quote_ident(required.name))
     ORDER BY required.ord`,
    [[...REQUIRED_TABLES, ...REQUIRED_VIEWS]]
  );
  const results: ValidationResultInput[] = [];
  for (const row of present.rows) {
    const name = String(row.name);
    const relkind = row.relkind === null || row.relkind === undefined ? null : String(row.relkind);
    const isView = (REQUIRED_VIEWS as readonly string[]).includes(name);
    const expected = isView ? ['v', 'm'] : ['r', 'p'];
    if (relkind === null) {
      results.push({
        validationType: 'SCHEMA',
        status: 'FAIL',
        code: isView ? 'SCHEMA_MISSING_VIEW' : 'SCHEMA_MISSING_TABLE',
        message: boundedMessage(`Required ${isView ? 'view' : 'table'} ${name} is not present in the resolved search path.`)
      });
    } else if (!expected.includes(relkind)) {
      results.push({
        validationType: 'SCHEMA',
        status: 'FAIL',
        code: 'SCHEMA_UNEXPECTED_RELATION_KIND',
        message: boundedMessage(`Required structure ${name} exists but is not a ${isView ? 'view' : 'table'}.`)
      });
    }
  }
  if (!results.length) {
    results.push({
      validationType: 'SCHEMA',
      status: 'PASS',
      code: 'SCHEMA_BASELINE_PRESENT',
      message: boundedMessage(
        `All ${REQUIRED_TABLES.length} baseline tables and ${REQUIRED_VIEWS.length} core structural views are present. Structural presence only; no data was interpreted.`
      )
    });
  }
  return results;
};

const truncationResult = (validationType: string, code: string, reported: number, total: number): ValidationResultInput => ({
  validationType,
  status: 'WARNING',
  code,
  message: boundedMessage(`Reported ${reported} of ${total} detected violations; the remainder was withheld by the bounded reporting limit.`)
});

export const checkProvenance = async (db: Queryable): Promise<ValidationResultInput[]> => {
  const results: ValidationResultInput[] = [];

  const uncited = await db.query(
    `SELECT c.claim_id, c.claim_key, count(*) OVER () AS total
     FROM claim c
     WHERE c.claim_type_code IN ('DIRECT_SOURCE_CLAIM', 'INTERPRETIVE_CLAIM')
       AND NOT EXISTS (
         SELECT 1
         FROM claim_evidence ce
         JOIN evidence e ON e.evidence_id = ce.evidence_id
         JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
         JOIN citation ci ON ci.citation_id = ec.citation_id
         JOIN source_record sr ON sr.source_record_id = ci.source_record_id
         JOIN dataset d ON d.dataset_id = sr.dataset_id
         JOIN source s ON s.source_id = d.source_id
         WHERE ce.claim_id = c.claim_id
           AND e.evidence_type_code = 'SOURCE_OBSERVATION'
       )
     ORDER BY c.claim_key
     LIMIT $1`,
    [VIOLATION_REPORT_LIMIT]
  );
  for (const row of uncited.rows) {
    results.push({
      validationType: 'PROVENANCE',
      status: 'FAIL',
      code: 'PROVENANCE_CLAIM_MISSING_CITED_SOURCE_OBSERVATION',
      message: boundedMessage(`Claim ${String(row.claim_key)} traces to no cited SOURCE_OBSERVATION through ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord → Dataset → Source.`),
      subjectType: 'claim',
      subjectId: Number(row.claim_id)
    });
  }
  if (uncited.rowCount) {
    const total = Number(uncited.rows[0].total);
    if (total > uncited.rowCount) {
      results.push(truncationResult('PROVENANCE', 'PROVENANCE_VIOLATIONS_TRUNCATED', uncited.rowCount, total));
    }
  }

  const derived = await db.query(
    `SELECT c.claim_id, c.claim_key, c.derivation_id, count(*) OVER () AS total
     FROM claim c
     WHERE c.claim_type_code = 'DERIVED_CLAIM'
       AND (c.derivation_id IS NULL
            OR NOT EXISTS (SELECT 1 FROM derivation_input di WHERE di.derivation_id = c.derivation_id))
     ORDER BY c.claim_key
     LIMIT $1`,
    [VIOLATION_REPORT_LIMIT]
  );
  for (const row of derived.rows) {
    results.push({
      validationType: 'PROVENANCE',
      status: 'FAIL',
      code: row.derivation_id === null
        ? 'PROVENANCE_DERIVED_CLAIM_MISSING_DERIVATION'
        : 'PROVENANCE_DERIVED_CLAIM_MISSING_DERIVATION_INPUT',
      message: boundedMessage(row.derivation_id === null
        ? `Derived claim ${String(row.claim_key)} records no derivation metadata.`
        : `Derived claim ${String(row.claim_key)} records a derivation with no explicit derivation input.`),
      subjectType: 'claim',
      subjectId: Number(row.claim_id)
    });
  }
  if (derived.rowCount) {
    const total = Number(derived.rows[0].total);
    if (total > derived.rowCount) {
      results.push(truncationResult('PROVENANCE', 'PROVENANCE_DERIVED_VIOLATIONS_TRUNCATED', derived.rowCount, total));
    }
  }

  if (!results.length) {
    results.push({
      validationType: 'PROVENANCE',
      status: 'PASS',
      code: 'PROVENANCE_CHAIN_STRUCTURALLY_COMPLETE',
      message: boundedMessage('Every direct and interpretive claim cites a SOURCE_OBSERVATION and every derived claim declares derivation inputs. Structural provenance only; no source content was adjudicated. No provenance artefact was created or repaired.')
    });
  }
  return results;
};

export const checkNegativeSemantic = async (db: Queryable): Promise<ValidationResultInput[]> => {
  const results: ValidationResultInput[] = [];

  const predicates = await db.query('SELECT predicate_code FROM predicate ORDER BY predicate_code');
  for (const row of predicates.rows) {
    const code = String(row.predicate_code);
    if (FORBIDDEN_PREDICATE_PATTERN.test(code.toLowerCase())) {
      results.push({
        validationType: 'NEGATIVE_SEMANTIC',
        status: 'FAIL',
        code: 'NEGATIVE_SEMANTIC_FORBIDDEN_PREDICATE_REGISTERED',
        message: boundedMessage(`Registered predicate ${code} expresses automatic truth, proof, adjudication, or generalized inference semantics, which the platform prohibits.`)
      });
    }
  }

  const jobTypes = await db.query(
    `SELECT DISTINCT job_type FROM asynchronous_job WHERE NOT (job_type = ANY($1::text[])) ORDER BY job_type LIMIT $2`,
    [[...ALLOWED_JOB_TYPES], VIOLATION_REPORT_LIMIT]
  );
  for (const row of jobTypes.rows) {
    results.push({
      validationType: 'NEGATIVE_SEMANTIC',
      status: 'FAIL',
      code: 'NEGATIVE_SEMANTIC_UNDECLARED_JOB_TYPE',
      message: boundedMessage(`Workflow state persists job type ${String(row.job_type)}, which is outside the declared closed job-type set.`)
    });
  }

  const mappings = await db.query(
    `SELECT entity_source_mapping_id
     FROM entity_source_mapping
     WHERE mapping_status_code = 'ACTIVE' AND (justification IS NULL OR btrim(justification) = '')
     ORDER BY entity_source_mapping_id
     LIMIT $1`,
    [VIOLATION_REPORT_LIMIT]
  );
  for (const row of mappings.rows) {
    results.push({
      validationType: 'NEGATIVE_SEMANTIC',
      status: 'FAIL',
      code: 'NEGATIVE_SEMANTIC_UNJUSTIFIED_ACTIVE_IDENTITY_MAPPING',
      message: boundedMessage('An active source-identity reconciliation records no justification, which would represent an unreviewed automatic promotion.'),
      subjectType: 'entity_source_mapping',
      subjectId: Number(row.entity_source_mapping_id)
    });
  }

  if (!results.length) {
    results.push({
      validationType: 'NEGATIVE_SEMANTIC',
      status: 'PASS',
      code: 'NEGATIVE_SEMANTIC_FORBIDDEN_CAPABILITIES_ABSENT',
      message: boundedMessage('No registered predicate, persisted job type, or active reconciliation represents automatic truth, proof, adjudication, generalized inference, or unreviewed promotion. Structural boundary check only; this asserts nothing about history.')
    });
  }
  return results;
};

export interface KnowledgeSnapshotEntry {
  rowCount: number;
  digest: string;
}

export type KnowledgeSnapshot = Record<string, KnowledgeSnapshotEntry>;

/** Content snapshot of the authoritative knowledge tables. Read-only. */
export const snapshotKnowledgeTables = async (db: Queryable): Promise<KnowledgeSnapshot> => {
  const snapshot: KnowledgeSnapshot = {};
  for (const table of KNOWLEDGE_TABLES) {
    const result = await db.query(
      `SELECT count(*)::int AS row_count,
              coalesce(md5(string_agg(row_digest, '' ORDER BY row_digest)), '') AS digest
       FROM (SELECT md5(t::text) AS row_digest FROM ${identifier(table)} t) sampled`
    );
    snapshot[table] = { rowCount: Number(result.rows[0].row_count), digest: String(result.rows[0].digest) };
  }
  return snapshot;
};

/**
 * Takes an internally consistent snapshot inside a read-only repeatable-read
 * transaction, so a concurrent commit cannot be captured by some tables only.
 */
export const snapshotKnowledgeTablesConsistently = async (pool: Pool): Promise<KnowledgeSnapshot> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN TRANSACTION READ ONLY ISOLATION LEVEL REPEATABLE READ');
    const snapshot = await snapshotKnowledgeTables(client);
    await client.query('COMMIT');
    return snapshot;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Reports whether another actor recorded audited activity during the execution
 * window. A knowledge-table change is only attributable to this executor when no
 * other actor was writing; otherwise it is reported as concurrent authorized
 * activity rather than as an executor mutation.
 */
export const hasConcurrentExternalActivity = async (
  db: Queryable,
  since: string,
  workerActorId: number | null
): Promise<boolean> => {
  const result = await db.query(
    `SELECT 1 FROM audit_event
     WHERE occurred_at >= $1::timestamptz AND ($2::bigint IS NULL OR actor_id <> $2::bigint)
     LIMIT 1`,
    [since, workerActorId]
  );
  return Boolean(result.rowCount);
};

export const compareKnowledgeSnapshots = (
  before: KnowledgeSnapshot,
  after: KnowledgeSnapshot,
  options: { concurrentExternalActivity?: boolean } = {}
): ValidationResultInput[] => {
  const results: ValidationResultInput[] = [];
  for (const table of KNOWLEDGE_TABLES) {
    const start = before[table];
    const end = after[table];
    if (!start || !end) {
      results.push({
        validationType: 'READ_ONLY',
        status: 'FAIL',
        code: 'READ_ONLY_SNAPSHOT_INCOMPLETE',
        message: boundedMessage(`Authoritative knowledge table ${table} could not be compared across the execution window.`)
      });
      continue;
    }
    if (start.rowCount !== end.rowCount || start.digest !== end.digest) {
      results.push(options.concurrentExternalActivity
        ? {
            validationType: 'READ_ONLY',
            status: 'WARNING',
            code: 'READ_ONLY_CONCURRENT_EXTERNAL_MUTATION',
            message: boundedMessage(`Authoritative knowledge table ${table} changed during validation execution (rows ${start.rowCount} → ${end.rowCount}) while another actor recorded audited activity, so the change is not attributable to this executor.`)
          }
        : {
            validationType: 'READ_ONLY',
            status: 'FAIL',
            code: 'READ_ONLY_KNOWLEDGE_TABLE_MUTATED',
            message: boundedMessage(`Authoritative knowledge table ${table} changed during validation execution (rows ${start.rowCount} → ${end.rowCount}).`)
          });
    }
  }
  if (!results.length) {
    results.push({
      validationType: 'READ_ONLY',
      status: 'PASS',
      code: 'READ_ONLY_KNOWLEDGE_TABLES_UNCHANGED',
      message: boundedMessage(`All ${KNOWLEDGE_TABLES.length} authoritative knowledge and registry tables were unchanged across validation execution. Workflow, result, and audit tables are excluded because the worker appends to them.`)
    });
  }
  return results;
};

const notApplicable = (validationType: string): ValidationResultInput => ({
  validationType,
  status: 'NOT_APPLICABLE',
  code: 'VALIDATION_TYPE_NOT_IMPLEMENTED',
  message: boundedMessage(`Validation type ${validationType} is accepted by the API but is not implemented by this executor. NOT_APPLICABLE is neither a pass nor a failure.`)
});

export interface ValidationExecutionContext {
  db: Queryable;
  validationTypes: readonly string[];
  isCancelled: () => Promise<boolean>;
  persist: (results: readonly ValidationResultInput[]) => Promise<void>;
  /** Overrides how the READ_ONLY before/after snapshot is taken. */
  snapshot?: () => Promise<KnowledgeSnapshot>;
  /** Worker actor whose audited activity is expected during execution. */
  workerActorId?: number;
}

export interface ValidationExecutionOutcome {
  cancelled: boolean;
  persisted: number;
}

/**
 * Executes the requested validation types in a deterministic order, persisting
 * immutable results as each type completes and observing cooperative
 * cancellation before every type and before finalization.
 */
export const executeValidationRun = async (
  context: ValidationExecutionContext
): Promise<ValidationExecutionOutcome> => {
  const requested = new Set(context.validationTypes.map((type) => String(type)));
  const unknown = [...requested].filter((type) =>
    !(EXECUTED_VALIDATION_TYPES as readonly string[]).includes(type) &&
    !(DEFERRED_VALIDATION_TYPES as readonly string[]).includes(type));
  if (unknown.length) {
    throw new ValidationExecutorError('VALIDATION_TYPE_UNRECOGNISED', 'The validation run requests an unrecognised validation type.');
  }

  const snapshot = context.snapshot ?? (() => snapshotKnowledgeTables(context.db));
  const window = await context.db.query('SELECT CURRENT_TIMESTAMP AS started_at');
  const startedAt = String(window.rows[0].started_at instanceof Date
    ? window.rows[0].started_at.toISOString()
    : window.rows[0].started_at);
  const before = await snapshot();
  let persisted = 0;
  const persist = async (results: readonly ValidationResultInput[]): Promise<void> => {
    if (!results.length) return;
    await context.persist(results);
    persisted += results.length;
  };

  for (const type of EXECUTED_VALIDATION_TYPES) {
    if (!requested.has(type)) continue;
    if (await context.isCancelled()) return { cancelled: true, persisted };
    if (type === 'SCHEMA') await persist(await checkSchema(context.db));
    else if (type === 'PROVENANCE') await persist(await checkProvenance(context.db));
    else if (type === 'NEGATIVE_SEMANTIC') await persist(await checkNegativeSemantic(context.db));
    else {
      const after = await snapshot();
      const concurrentExternalActivity = await hasConcurrentExternalActivity(
        context.db, startedAt, context.workerActorId ?? null
      );
      await persist(compareKnowledgeSnapshots(before, after, { concurrentExternalActivity }));
    }
  }

  for (const type of DEFERRED_VALIDATION_TYPES) {
    if (!requested.has(type)) continue;
    if (await context.isCancelled()) return { cancelled: true, persisted };
    await persist([notApplicable(type)]);
  }

  if (await context.isCancelled()) return { cancelled: true, persisted };
  return { cancelled: false, persisted };
};
