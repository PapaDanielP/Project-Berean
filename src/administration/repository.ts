import type { Pool, PoolClient } from 'pg';
import type { AuthenticatedActor } from '../auth.js';

type Values = Record<string, unknown>;

const administrationListQueries: Record<string, string> = {
  corpora: 'SELECT * FROM corpus ORDER BY corpus_id DESC LIMIT $1',
  topics: 'SELECT * FROM research_topic ORDER BY research_topic_id DESC LIMIT $1',
  discoveries: 'SELECT * FROM discovery_request ORDER BY discovery_request_id DESC LIMIT $1',
  candidates: 'SELECT * FROM discovery_candidate ORDER BY discovery_candidate_id DESC LIMIT $1',
  jobs: 'SELECT * FROM asynchronous_job ORDER BY job_id DESC LIMIT $1',
  validations: 'SELECT * FROM validation_run ORDER BY validation_run_id DESC LIMIT $1',
  'validation-results': 'SELECT * FROM validation_result ORDER BY validation_result_id DESC LIMIT $1',
  audits: 'SELECT * FROM audit_event ORDER BY audit_event_id DESC LIMIT $1',
  exports: 'SELECT * FROM export_job ORDER BY export_job_id DESC LIMIT $1'
};

export const ADMINISTRATION_LIST_RESOURCES = Object.keys(administrationListQueries);

export class AdministrationRepository {
  constructor(private readonly pool: Pool) {}

  private async transaction<T>(work: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private async actorId(client: PoolClient, actor: AuthenticatedActor): Promise<number> {
    const result = await client.query(
      `INSERT INTO workflow_actor (actor_key, display_name, role_code)
       VALUES ($1, $2, $3)
       ON CONFLICT (actor_key) DO UPDATE
       SET display_name = EXCLUDED.display_name, role_code = EXCLUDED.role_code
       RETURNING actor_id`,
      [actor.key, actor.displayName, actor.role]
    );
    return Number(result.rows[0].actor_id);
  }

  private async audit(
    client: PoolClient,
    actorId: number,
    action: string,
    resourceType: string,
    resourceId: number | null,
    correlationId: string,
    detail: string
  ): Promise<void> {
    await client.query(
      `INSERT INTO audit_event
         (actor_id, action, resource_type, resource_id, correlation_id, outcome, detail)
       VALUES ($1, $2, $3, $4, $5, 'SUCCEEDED', $6)`,
      [actorId, action, resourceType, resourceId, correlationId, detail]
    );
  }

  async createCorpus(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const result = await client.query(
        `INSERT INTO corpus (corpus_key, name, description, scope_note, owner_actor_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [input.key, input.name, input.description ?? null, input.scopeNote, actorId]
      );
      const row = result.rows[0];
      await this.audit(client, actorId, 'CREATE', 'corpus', Number(row.corpus_id), correlationId, 'Created bounded corpus workspace.');
      return row;
    });
  }

  async updateCorpus(
    corpusId: number,
    version: number,
    input: Values,
    actor: AuthenticatedActor,
    correlationId: string
  ): Promise<Values | null> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const result = await client.query(
        `UPDATE corpus SET
           name = COALESCE($3, name),
           description = COALESCE($4, description),
           scope_note = COALESCE($5, scope_note),
           status = COALESCE($6, status),
           version = version + 1,
           updated_at = CURRENT_TIMESTAMP
         WHERE corpus_id = $1 AND version = $2
         RETURNING *`,
        [corpusId, version, input.name ?? null, input.description ?? null, input.scopeNote ?? null, input.status ?? null]
      );
      if (!result.rowCount) return null;
      await this.audit(client, actorId, 'UPDATE', 'corpus', corpusId, correlationId, 'Updated corpus using optimistic concurrency.');
      return result.rows[0];
    });
  }

  async createTopic(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const result = await client.query(
        `INSERT INTO research_topic
           (corpus_id, topic_key, question, scope_note, owner_actor_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [input.corpusId, input.key, input.question, input.scopeNote, actorId]
      );
      const row = result.rows[0];
      await this.audit(client, actorId, 'CREATE', 'research_topic', Number(row.research_topic_id), correlationId, 'Created research topic.');
      return row;
    });
  }

  async createDiscovery(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const job = await client.query(
        `INSERT INTO asynchronous_job
           (job_type, idempotency_key, request_fingerprint, requested_by_actor_id, correlation_id)
         VALUES ('DISCOVERY', $1, $2, $3, $4)
         ON CONFLICT (requested_by_actor_id, job_type, idempotency_key)
         DO UPDATE SET updated_at = asynchronous_job.updated_at
         WHERE asynchronous_job.request_fingerprint = EXCLUDED.request_fingerprint
         RETURNING *`,
        [input.idempotencyKey, input.requestFingerprint, actorId, correlationId]
      );
      if (!job.rowCount) throw new Error('IDEMPOTENCY_KEY_REUSED');
      const jobRow = job.rows[0];
      const request = await client.query(
        `INSERT INTO discovery_request
           (corpus_id, research_topic_id, job_id, request_kind, query_text, bounded_scope, requested_types)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (job_id) DO UPDATE SET job_id = EXCLUDED.job_id
         RETURNING *`,
        [
          input.corpusId, input.researchTopicId ?? null, jobRow.job_id, input.requestKind,
          input.queryText, input.boundedScope, input.requestedTypes
        ]
      );
      const row = request.rows[0];
      await this.audit(client, actorId, 'REQUEST', 'discovery_request', Number(row.discovery_request_id), correlationId, 'Queued bounded discovery; results are candidates only.');
      return { ...row, job: jobRow };
    });
  }

  async addCandidate(requestId: number, input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      if (input.proposedPredicate) {
        const predicate = await client.query('SELECT 1 FROM predicate WHERE predicate_code = $1', [input.proposedPredicate]);
        if (!predicate.rowCount) {
          input.representationStatus = 'NOT_REPRESENTED';
          input.obstacleClassification = 'REGISTRY_EXPRESSIVENESS';
        }
      }
      const result = await client.query(
        `INSERT INTO discovery_candidate
           (discovery_request_id, candidate_key, candidate_type, label, description,
            representation_status, obstacle_classification, proposed_predicate, discovery_locator)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         ON CONFLICT (discovery_request_id, candidate_key)
         DO UPDATE SET label = EXCLUDED.label
         RETURNING *`,
        [
          requestId, input.key, input.type, input.label, input.description ?? null,
          input.representationStatus ?? 'UNREVIEWED', input.obstacleClassification ?? null,
          input.proposedPredicate ?? null, input.discoveryLocator
        ]
      );
      const row = result.rows[0];
      await this.audit(client, actorId, 'DISCOVER', 'discovery_candidate', Number(row.discovery_candidate_id), correlationId, 'Recorded discovery candidate; no evidence or claim was created.');
      return row;
    });
  }

  async reviewCandidate(candidateId: number, input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const result = await client.query(
        `INSERT INTO candidate_review
           (discovery_candidate_id, decision, rationale, reviewer_actor_id)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (discovery_candidate_id) DO UPDATE
         SET decision = EXCLUDED.decision, rationale = EXCLUDED.rationale,
             reviewer_actor_id = EXCLUDED.reviewer_actor_id, reviewed_at = CURRENT_TIMESTAMP
         RETURNING *`,
        [candidateId, input.decision, input.rationale, actorId]
      );
      await client.query(
        `UPDATE discovery_candidate SET representation_status =
           CASE $2 WHEN 'APPROVED' THEN 'REPRESENTABLE'
                   WHEN 'REJECTED' THEN 'EXCLUDED'
                   WHEN 'NOT_REPRESENTED' THEN 'NOT_REPRESENTED'
                   ELSE representation_status END
         WHERE discovery_candidate_id = $1`,
        [candidateId, input.decision]
      );
      const row = result.rows[0];
      await this.audit(client, actorId, 'REVIEW', 'discovery_candidate', candidateId, correlationId, `Candidate decision: ${input.decision as string}.`);
      return row;
    });
  }

  async registerSource(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const source = await client.query(
        `INSERT INTO source (source_key, name, source_type_code, description)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (source_key) DO UPDATE SET name = EXCLUDED.name
         RETURNING *`,
        [input.sourceKey, input.sourceName, input.sourceType, input.description ?? null]
      );
      const sourceId = Number(source.rows[0].source_id);
      const dataset = await client.query(
        `INSERT INTO dataset
           (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         ON CONFLICT (dataset_key) DO UPDATE SET license_status = EXCLUDED.license_status
         RETURNING *`,
        [
          sourceId, input.datasetKey, input.datasetName, input.editionLabel ?? null,
          input.version ?? null, input.licenseStatus, input.acquisitionMethod
        ]
      );
      const datasetId = Number(dataset.rows[0].dataset_id);
      await client.query(
        `INSERT INTO corpus_dataset (corpus_id, dataset_id, added_by_actor_id)
         VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
        [input.corpusId, datasetId, actorId]
      );
      await this.audit(client, actorId, 'REGISTER', 'source', sourceId, correlationId, 'Registered source identity and licensed dataset locator.');
      return { source: source.rows[0], dataset: dataset.rows[0] };
    });
  }

  async createSourceRecord(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const record = await client.query(
        `INSERT INTO source_record
           (dataset_id, source_record_key, source_location, raw_content, content_hash, revision_label)
         VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT (dataset_id, source_record_key) DO UPDATE SET source_record_key = EXCLUDED.source_record_key
         RETURNING *`,
        [
          input.datasetId, input.key, input.sourceLocation, input.rawContent ?? null,
          input.contentHash ?? null, input.revisionLabel ?? null
        ]
      );
      const recordId = Number(record.rows[0].source_record_id);
      const citation = await client.query(
        `INSERT INTO citation (citation_key, source_record_id, locator, quoted_text)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (citation_key) DO UPDATE SET locator = EXCLUDED.locator
         RETURNING *`,
        [input.citationKey, recordId, input.locator, input.quotedText ?? null]
      );
      await this.audit(client, actorId, 'REGISTER', 'source_record', recordId, correlationId, 'Registered source record and citation locator.');
      return { sourceRecord: record.rows[0], citation: citation.rows[0] };
    });
  }

  async createEvidence(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const evidence = await client.query(
        `INSERT INTO evidence
           (evidence_key, source_record_id, observation, evidence_type_code, notes)
         VALUES ($1,$2,$3,$4,$5)
         RETURNING *`,
        [input.key, input.sourceRecordId, input.observation, input.evidenceType, input.notes ?? null]
      );
      const evidenceId = Number(evidence.rows[0].evidence_id);
      for (const citationId of input.citationIds as number[]) {
        await client.query(
          'INSERT INTO evidence_citation (evidence_id, citation_id) VALUES ($1,$2)',
          [evidenceId, citationId]
        );
      }
      await this.audit(client, actorId, 'CREATE', 'evidence', evidenceId, correlationId, `Created ${input.evidenceType as string}; no claim was created.`);
      return evidence.rows[0];
    });
  }

  async createClaim(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const evidenceIds = input.evidenceIds as number[];
      if (input.claimType === 'DERIVED_CLAIM') {
        const derivation = await client.query(
          `SELECT 1 FROM derivation d
           WHERE d.derivation_id = $1
             AND EXISTS (SELECT 1 FROM derivation_input di WHERE di.derivation_id = d.derivation_id)`,
          [input.derivationId]
        );
        if (!derivation.rowCount) throw new Error('DERIVATION_INPUT_REQUIRED');
      } else {
        const eligible = await client.query(
          `SELECT count(*)::int AS count
           FROM evidence e
           WHERE e.evidence_id = ANY($1::bigint[])
             AND e.evidence_type_code = 'SOURCE_OBSERVATION'
             AND EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)`,
          [evidenceIds]
        );
        if (Number(eligible.rows[0].count) !== evidenceIds.length) {
          throw new Error('DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION');
        }
      }
      const proposition = await client.query(
        `INSERT INTO proposition
           (subject_entity_id, subject_event_id, predicate,
            object_entity_id, object_event_id, object_typed_value_id)
         VALUES ($1,$2,$3,$4,$5,$6)
         RETURNING *`,
        [
          input.subjectEntityId ?? null, input.subjectEventId ?? null, input.predicate,
          input.objectEntityId ?? null, input.objectEventId ?? null, input.objectTypedValueId ?? null
        ]
      );
      const claim = await client.query(
        `INSERT INTO claim
           (claim_key, proposition_id, claim_type_code, claim_status_code, statement, notes, derivation_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         RETURNING *`,
        [
          input.key, proposition.rows[0].proposition_id, input.claimType,
          input.status ?? 'UNDER_REVIEW', input.statement ?? null, input.notes ?? null,
          input.derivationId ?? null
        ]
      );
      const claimId = Number(claim.rows[0].claim_id);
      for (const evidenceId of evidenceIds) {
        await client.query(
          `INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
           VALUES ($1,$2,$3)`,
          [claimId, evidenceId, input.evidenceRelation ?? 'SUPPORTS']
        );
      }
      await this.audit(client, actorId, 'AUTHOR', 'claim', claimId, correlationId, 'Authored validated proposition and claim; status is not a truth determination.');
      return { claim: claim.rows[0], proposition: proposition.rows[0] };
    });
  }

  async createIdentityMapping(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const ancestry = await client.query(
        `SELECT 1
         FROM source_identity si
         JOIN evidence e ON e.evidence_id = $2
         JOIN source_record sr ON sr.source_record_id = e.source_record_id
         JOIN dataset d ON d.dataset_id = sr.dataset_id
         WHERE si.source_identity_id = $1 AND si.source_id = d.source_id`,
        [input.sourceIdentityId, input.supportingEvidenceId]
      );
      if (!ancestry.rowCount) throw new Error('IDENTITY_EVIDENCE_SOURCE_MISMATCH');
      const result = await client.query(
        `INSERT INTO entity_source_mapping
           (source_identity_id, entity_id, mapping_status_code, confidence,
            justification, notes, supporting_evidence_id)
         VALUES ($1,$2,'PROPOSED',$3,$4,$5,$6)
         RETURNING *`,
        [
          input.sourceIdentityId, input.entityId, input.confidence, input.justification,
          input.notes ?? null, input.supportingEvidenceId
        ]
      );
      const row = result.rows[0];
      await this.audit(client, actorId, 'PROPOSE', 'entity_source_mapping', Number(row.entity_source_mapping_id), correlationId, 'Proposed source identity reconciliation; proposal is not active.');
      return row;
    });
  }

  async reviewIdentityMapping(
    mappingId: number,
    input: Values,
    actor: AuthenticatedActor,
    correlationId: string
  ): Promise<Values | null> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const ancestry = await client.query(
        `SELECT 1
         FROM entity_source_mapping esm
         JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
         JOIN evidence e ON e.evidence_id = esm.supporting_evidence_id
         JOIN source_record sr ON sr.source_record_id = e.source_record_id
         JOIN dataset d ON d.dataset_id = sr.dataset_id
         WHERE esm.entity_source_mapping_id = $1 AND si.source_id = d.source_id`,
        [mappingId]
      );
      if (!ancestry.rowCount) throw new Error('IDENTITY_EVIDENCE_SOURCE_MISMATCH');
      const result = await client.query(
        `UPDATE entity_source_mapping
         SET mapping_status_code = $2, notes = concat_ws(E'\n', notes, $3::text)
         WHERE entity_source_mapping_id = $1 AND mapping_status_code = 'PROPOSED'
         RETURNING *`,
        [mappingId, input.status, `Reviewed by ${actor.key}: ${input.rationale as string}`]
      );
      if (!result.rowCount) return null;
      await this.audit(client, actorId, 'REVIEW', 'entity_source_mapping', mappingId, correlationId, `Identity mapping decision: ${input.status as string}.`);
      return result.rows[0];
    });
  }

  async createDerivation(input: Values, actor: AuthenticatedActor, correlationId: string): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const derivation = await client.query(
        `INSERT INTO derivation (method, assumptions) VALUES ($1,$2) RETURNING *`,
        [input.method, input.assumptions]
      );
      const derivationId = Number(derivation.rows[0].derivation_id);
      for (const entry of input.inputs as Values[]) {
        await client.query(
          `INSERT INTO derivation_input
             (derivation_id, input_claim_id, input_evidence_id, notes)
           VALUES ($1,$2,$3,$4)`,
          [derivationId, entry.claimId ?? null, entry.evidenceId ?? null, entry.notes ?? null]
        );
      }
      await this.audit(client, actorId, 'CREATE', 'derivation', derivationId, correlationId, 'Recorded explicit derivation inputs; no claim was created automatically.');
      return derivation.rows[0];
    });
  }

  async createJob(
    jobType: 'INGESTION' | 'VALIDATION' | 'EXPORT',
    input: Values,
    actor: AuthenticatedActor,
    correlationId: string
  ): Promise<Values> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const result = await client.query(
        `INSERT INTO asynchronous_job
           (job_type, idempotency_key, request_fingerprint, requested_by_actor_id, correlation_id)
         VALUES ($1,$2,$3,$4,$5)
         ON CONFLICT (requested_by_actor_id, job_type, idempotency_key)
         DO UPDATE SET updated_at = asynchronous_job.updated_at
         WHERE asynchronous_job.request_fingerprint = EXCLUDED.request_fingerprint
         RETURNING *`,
        [jobType, input.idempotencyKey, input.requestFingerprint, actorId, correlationId]
      );
      if (!result.rowCount) throw new Error('IDEMPOTENCY_KEY_REUSED');
      const job = result.rows[0];
      if (jobType === 'INGESTION') {
        await client.query(
          `INSERT INTO ingestion_job
             (job_id, corpus_id, source_id, discovery_candidate_id, transaction_policy, partial_failure_policy)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (job_id) DO NOTHING`,
          [
            job.job_id, input.corpusId, input.sourceId ?? null, input.candidateId ?? null,
            input.transactionPolicy ?? 'ATOMIC', input.partialFailurePolicy ?? 'ROLLBACK_ALL'
          ]
        );
      } else if (jobType === 'VALIDATION') {
        await client.query(
          `INSERT INTO validation_run (job_id, corpus_id, validation_types)
           VALUES ($1,$2,$3) ON CONFLICT (job_id) DO NOTHING`,
          [job.job_id, input.corpusId ?? null, input.validationTypes]
        );
      } else {
        await client.query(
          `INSERT INTO export_job
             (job_id, corpus_id, format, include_raw_content, reproducibility_note)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (job_id) DO NOTHING`,
          [job.job_id, input.corpusId, input.format, input.includeRawContent ?? false, input.reproducibilityNote]
        );
      }
      await this.audit(client, actorId, 'QUEUE', `${jobType.toLowerCase()}_job`, Number(job.job_id), correlationId, `Queued idempotent ${jobType.toLowerCase()} job.`);
      return job;
    });
  }

  async changeJob(jobId: number, action: 'cancel' | 'retry', actor: AuthenticatedActor, correlationId: string): Promise<Values | null> {
    return this.transaction(async (client) => {
      const actorId = await this.actorId(client, actor);
      const job = await client.query(
        'SELECT job_type, requested_by_actor_id, status FROM asynchronous_job WHERE job_id = $1 FOR UPDATE',
        [jobId]
      );
      if (!job.rowCount) return null;
      const requiredRole = job.rows[0].job_type === 'EXPORT'
        ? 'ADMINISTRATOR'
        : job.rows[0].job_type === 'VALIDATION'
          ? 'REVIEWER'
          : 'CONTENT_EDITOR';
      const roleRank: Record<string, number> = {
        READER: 0, RESEARCHER: 1, CONTENT_EDITOR: 2, REVIEWER: 3, ADMINISTRATOR: 4, SYSTEM: 5
      };
      const ownsJob = Number(job.rows[0].requested_by_actor_id) === actorId;
      if (roleRank[actor.role] < roleRank[requiredRole] ||
          (!ownsJob && actor.role !== 'ADMINISTRATOR' && actor.role !== 'SYSTEM')) {
        throw new Error('JOB_ACTION_FORBIDDEN');
      }
      const result = action === 'cancel'
        ? await client.query(
            `UPDATE asynchronous_job
             SET status = CASE WHEN status = 'RUNNING' THEN 'RUNNING' ELSE 'CANCELLED' END,
                 cancel_requested = TRUE,
                 cancel_requested_at = CURRENT_TIMESTAMP,
                 completed_at = CASE WHEN status = 'RUNNING' THEN completed_at ELSE CURRENT_TIMESTAMP END,
                 worker_actor_id = CASE WHEN status = 'RUNNING' THEN worker_actor_id ELSE NULL END,
                 lease_token = CASE WHEN status = 'RUNNING' THEN lease_token ELSE NULL END,
                 lease_expires_at = CASE WHEN status = 'RUNNING' THEN lease_expires_at ELSE NULL END,
                 heartbeat_at = CASE WHEN status = 'RUNNING' THEN heartbeat_at ELSE NULL END,
                 updated_at = CURRENT_TIMESTAMP
             WHERE job_id = $1 AND status IN ('QUEUED','RUNNING','WAITING_FOR_REVIEW')
             RETURNING *`,
            [jobId]
          )
        : await client.query(
            `UPDATE asynchronous_job
             SET status = 'QUEUED', attempt_count = attempt_count + 1,
                 error_code = NULL, error_message = NULL, completed_at = NULL,
                 cancel_requested = FALSE, cancel_requested_at = NULL,
                 worker_actor_id = NULL, lease_token = NULL, lease_expires_at = NULL,
                 heartbeat_at = NULL, started_at = NULL,
                 progress_current = 0, progress_total = 0,
                 updated_at = CURRENT_TIMESTAMP
             WHERE job_id = $1 AND status IN ('FAILED','CANCELLED')
             RETURNING *`,
            [jobId]
          );
      if (!result.rowCount) return null;
      await this.audit(client, actorId, action.toUpperCase(), 'asynchronous_job', jobId, correlationId, `${action} accepted.`);
      return result.rows[0];
    });
  }

  async list(resource: string, limit: number): Promise<Values[]> {
    const query = administrationListQueries[resource];
    if (!query) throw new Error('UNSUPPORTED_ADMIN_RESOURCE');
    return (await this.pool.query(query, [Math.max(1, Math.min(limit, 100))])).rows;
  }

  async getExportArtifact(artifactKey: string): Promise<Values | null> {
    const result = await this.pool.query(
      `SELECT a.artifact_key, a.job_id, a.export_job_id, x.corpus_id,
              a.content_type, a.format_version, a.byte_length, a.sha256,
              a.relative_locator, a.generated_at
       FROM export_artifact a
       JOIN export_job x ON x.export_job_id = a.export_job_id
       JOIN asynchronous_job j ON j.job_id = a.job_id
       WHERE a.artifact_key = $1::uuid AND j.status = 'COMPLETED'`,
      [artifactKey]
    );
    return result.rowCount ? result.rows[0] : null;
  }
}
