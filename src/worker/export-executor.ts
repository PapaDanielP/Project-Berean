import type { Pool } from 'pg';
import {
  EXPORT_FORMAT_VERSION,
  ExportArtifactError,
  type PreparedExportArtifact,
  writeExportArtifact
} from './export-artifact.js';

export const EXPORT_ROW_LIMIT = 1000;
export const EXPORT_BYTE_LIMIT = 8 * 1024 * 1024;

export class ExportExecutorError extends Error {
  constructor(readonly code: string) {
    super(code);
    this.name = 'ExportExecutorError';
  }
}

interface ExportRun {
  exportJobId: number;
  corpusId: number;
  corpusKey: string;
  format: string;
  includeRawContent: boolean;
}

const text = (value: unknown): string | null => value === null || value === undefined ? null : String(value);

const exportRows = async (pool: Pool, corpusId: number): Promise<Record<string, unknown>[]> => {
  const result = await pool.query(
    `SELECT c.claim_key, c.claim_type_code, c.claim_status_code, c.statement,
            p.predicate, p.subject_kind_code, se.entity_key AS subject_entity_key,
            sv.event_key AS subject_event_key, p.object_kind_code,
            oe.entity_key AS object_entity_key, ov.event_key AS object_event_key,
            tv.value_type_code, tv.text_value, tv.numeric_value::text AS numeric_value,
            to_char(tv.date_value, 'YYYY-MM-DD') AS date_value,
            to_char(tv.duration_value, 'YYYY-MM-DD"T"HH24:MI:SS.US') AS duration_value,
            tv.uncertainty_lower::text AS uncertainty_lower,
            tv.uncertainty_upper::text AS uncertainty_upper,
            ce.relation_type_code, e.evidence_key, e.evidence_type_code, e.observation,
            ci.citation_key, ci.locator AS citation_locator,
            sr.source_record_key, sr.source_location, sr.content_hash, sr.revision_label,
            d.dataset_key, d.version AS dataset_version, d.license_status,
            s.source_key, s.source_type_code
     FROM corpus_dataset cd
     JOIN dataset d ON d.dataset_id = cd.dataset_id
     JOIN source s ON s.source_id = d.source_id
     JOIN source_record sr ON sr.dataset_id = d.dataset_id
     JOIN evidence e ON e.source_record_id = sr.source_record_id
     JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
     JOIN claim c ON c.claim_id = ce.claim_id
     JOIN proposition p ON p.proposition_id = c.proposition_id
     LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
     LEFT JOIN event sv ON sv.event_id = p.subject_event_id
     LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
     LEFT JOIN event ov ON ov.event_id = p.object_event_id
     LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
     LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
     LEFT JOIN citation ci ON ci.citation_id = ec.citation_id
     WHERE cd.corpus_id = $1
     ORDER BY c.claim_key, e.evidence_key, ce.relation_type_code,
              ci.citation_key NULLS FIRST, sr.source_record_key, d.dataset_key, s.source_key
     LIMIT $2`,
    [corpusId, EXPORT_ROW_LIMIT + 1]
  );
  return result.rows;
};

const canonicalBytes = (run: ExportRun, rows: readonly Record<string, unknown>[]): Buffer => {
  const truncated = rows.length > EXPORT_ROW_LIMIT;
  const bounded = rows.slice(0, EXPORT_ROW_LIMIT);
  const lines: unknown[] = [{
    format: EXPORT_FORMAT_VERSION,
    scope: { type: 'CORPUS_SOURCE_BACKED_CLAIM_EVIDENCE', corpus_key: run.corpusKey },
    limits: { maximum_rows: EXPORT_ROW_LIMIT },
    row_count: bounded.length,
    truncated,
    epistemic_notice: 'Exported representations retain recorded classifications and provenance; they are not verified facts or truth adjudications.'
  }];
  for (const row of bounded) {
    lines.push({
      claim: {
        key: text(row.claim_key),
        type: text(row.claim_type_code),
        status: text(row.claim_status_code),
        statement: text(row.statement)
      },
      proposition: {
        subject: {
          kind: text(row.subject_kind_code),
          key: text(row.subject_entity_key ?? row.subject_event_key)
        },
        predicate: text(row.predicate),
        object: {
          kind: text(row.object_kind_code),
          key: text(row.object_entity_key ?? row.object_event_key),
          value: row.object_kind_code === 'VALUE' ? {
            type: text(row.value_type_code),
            text: text(row.text_value),
            numeric: text(row.numeric_value),
            date: text(row.date_value),
            duration: text(row.duration_value),
            uncertainty_lower: text(row.uncertainty_lower),
            uncertainty_upper: text(row.uncertainty_upper)
          } : null
        }
      },
      evidence: {
        key: text(row.evidence_key),
        type: text(row.evidence_type_code),
        claim_relation: text(row.relation_type_code),
        observation: text(row.observation)
      },
      citation: row.citation_key === null ? null : {
        key: text(row.citation_key),
        locator: text(row.citation_locator)
      },
      source_record: {
        key: text(row.source_record_key),
        location: text(row.source_location),
        content_hash: text(row.content_hash),
        revision: text(row.revision_label)
      },
      dataset: {
        key: text(row.dataset_key),
        version: text(row.dataset_version),
        license_status: text(row.license_status)
      },
      source: {
        key: text(row.source_key),
        type: text(row.source_type_code)
      }
    });
  }
  const bytes = Buffer.from(`${lines.map((line) => JSON.stringify(line)).join('\n')}\n`, 'utf8');
  if (bytes.byteLength > EXPORT_BYTE_LIMIT) throw new ExportExecutorError('EXPORT_PAYLOAD_TOO_LARGE');
  return bytes;
};

export const executeExport = async (
  pool: Pool,
  run: ExportRun,
  artifactDirectory: string | undefined,
  isCancelled: () => Promise<boolean>
): Promise<PreparedExportArtifact> => {
  if (run.format !== 'JSONL' || run.includeRawContent) {
    throw new ExportExecutorError('EXPORT_REQUEST_UNSUPPORTED');
  }
  if (await isCancelled()) throw new ExportExecutorError('EXPORT_CANCELLED');
  const rows = await exportRows(pool, run.corpusId);
  const bytes = canonicalBytes(run, rows);
  if (await isCancelled()) throw new ExportExecutorError('EXPORT_CANCELLED');
  let artifact: PreparedExportArtifact | undefined;
  try {
    artifact = await writeExportArtifact(artifactDirectory, run.exportJobId, bytes);
    if (await isCancelled()) {
      await artifact.discard();
      throw new ExportExecutorError('EXPORT_CANCELLED');
    }
    return artifact;
  } catch (error) {
    await artifact?.discard();
    if (error instanceof ExportExecutorError) throw error;
    if (error instanceof ExportArtifactError) throw new ExportExecutorError(error.code);
    throw new ExportExecutorError('EXPORT_EXECUTOR_FAILED');
  }
};
