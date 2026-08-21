import { randomUUID } from 'node:crypto';
import type { Pool, PoolClient } from 'pg';
import type { ValidationResultInput } from './validation-executor.js';
import type { ExportArtifactRecord } from './export-artifact.js';

export type JobType = 'SYSTEM_NOOP' | 'VALIDATION' | 'EXPORT';
export type JobRow = Record<string, unknown>;

export class WorkerRepository {
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

  private async audit(client: PoolClient, actorId: number, action: string, job: JobRow, detail: string): Promise<void> {
    await client.query(
      `INSERT INTO audit_event
         (actor_id, action, resource_type, resource_id, correlation_id, outcome, detail)
       VALUES ($1, $2, 'asynchronous_job', $3, $4, 'SUCCEEDED', $5)`,
      [actorId, action, Number(job.job_id), job.correlation_id, detail]
    );
  }

  async resolveSystemActor(actorKey: string, displayName: string): Promise<number> {
    const result = await this.pool.query(
      `INSERT INTO workflow_actor (actor_key, display_name, role_code)
       VALUES ($1, $2, 'SYSTEM')
       ON CONFLICT (actor_key) DO UPDATE
       SET display_name = EXCLUDED.display_name, role_code = 'SYSTEM', active = TRUE
       RETURNING actor_id`,
      [actorKey, displayName]
    );
    return Number(result.rows[0].actor_id);
  }

  async recoverExpired(actorId: number, maxAttempts: number, enabledTypes: readonly JobType[]): Promise<number> {
    if (!enabledTypes.length) return 0;
    return this.transaction(async (client) => {
      const expired = await client.query(
        `SELECT * FROM asynchronous_job
         WHERE status = 'RUNNING' AND lease_expires_at < CURRENT_TIMESTAMP
           AND job_type = ANY($1::text[])
         ORDER BY lease_expires_at, job_id
         FOR UPDATE SKIP LOCKED`,
        [enabledTypes]
      );
      for (const job of expired.rows) {
        const failed = Number(job.attempt_count) >= maxAttempts;
        const update = await client.query(
          `UPDATE asynchronous_job
           SET status = $2,
               error_code = $3, error_message = $4,
               completed_at = CASE WHEN $2 = 'FAILED' THEN CURRENT_TIMESTAMP ELSE NULL END,
               worker_actor_id = NULL, lease_token = NULL, lease_expires_at = NULL, heartbeat_at = NULL,
               updated_at = CURRENT_TIMESTAMP
           WHERE job_id = $1 AND status = 'RUNNING' AND lease_expires_at < CURRENT_TIMESTAMP
           RETURNING *`,
          [job.job_id, failed ? 'FAILED' : 'QUEUED',
            failed ? 'LEASE_EXPIRED_MAX_ATTEMPTS' : 'LEASE_EXPIRED_RECOVERED',
            failed ? 'Lease expired after the configured maximum attempts.' : 'Expired lease recovered for retry.']
        );
        if (update.rowCount) await this.audit(client, actorId, failed ? 'LEASE_FAILED' : 'LEASE_RECOVERED', update.rows[0], 'Recovered expired job lease.');
      }
      return expired.rowCount ?? 0;
    });
  }

  async claimOne(actorId: number, leaseSeconds: number, maxAttempts: number, enabledTypes: readonly JobType[]): Promise<JobRow | null> {
    if (!enabledTypes.length) return null;
    return this.transaction(async (client) => {
      const leaseToken = randomUUID();
      const result = await client.query(
        `WITH candidate AS (
           SELECT job_id
           FROM asynchronous_job
           WHERE status = 'QUEUED' AND cancel_requested = FALSE
             AND attempt_count < $1 AND job_type = ANY($2::text[])
           ORDER BY created_at, job_id
           FOR UPDATE SKIP LOCKED
           LIMIT 1
         )
         UPDATE asynchronous_job j
         SET status = 'RUNNING', started_at = COALESCE(j.started_at, CURRENT_TIMESTAMP),
             worker_actor_id = $3, lease_token = $4::uuid, heartbeat_at = CURRENT_TIMESTAMP,
             lease_expires_at = CURRENT_TIMESTAMP + ($5 * INTERVAL '1 second'),
             updated_at = CURRENT_TIMESTAMP
         FROM candidate
         WHERE j.job_id = candidate.job_id
         RETURNING j.*`,
        [maxAttempts, enabledTypes, actorId, leaseToken, leaseSeconds]
      );
      if (!result.rowCount) return null;
      await this.audit(client, actorId, 'LEASE_CLAIMED', result.rows[0], 'Claimed job lease.');
      return result.rows[0];
    });
  }

  async renewLease(jobId: number, leaseToken: string, actorId: number, leaseSeconds: number): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE asynchronous_job
       SET heartbeat_at = CURRENT_TIMESTAMP,
           lease_expires_at = CURRENT_TIMESTAMP + ($4 * INTERVAL '1 second'),
           updated_at = CURRENT_TIMESTAMP
       WHERE job_id = $1 AND lease_token = $2::uuid AND worker_actor_id = $3 AND status = 'RUNNING'
       RETURNING job_id`,
      [jobId, leaseToken, actorId, leaseSeconds]
    );
    return Boolean(result.rowCount);
  }

  async cancellationRequested(jobId: number, leaseToken: string, actorId: number): Promise<boolean> {
    const result = await this.pool.query(
      `SELECT cancel_requested FROM asynchronous_job
       WHERE job_id = $1 AND lease_token = $2::uuid AND worker_actor_id = $3 AND status = 'RUNNING'`,
      [jobId, leaseToken, actorId]
    );
    return Boolean(result.rowCount && result.rows[0].cancel_requested);
  }

  /** Loads the validation run owned by a currently leased job. */
  async loadValidationRun(jobId: number, leaseToken: string, actorId: number): Promise<{ validationRunId: number; validationTypes: string[] } | null> {
    const result = await this.pool.query(
      `SELECT v.validation_run_id, v.validation_types
       FROM validation_run v
       JOIN asynchronous_job j ON j.job_id = v.job_id
       WHERE v.job_id = $1 AND j.lease_token = $2::uuid AND j.worker_actor_id = $3 AND j.status = 'RUNNING'`,
      [jobId, leaseToken, actorId]
    );
    if (!result.rowCount) return null;
    return {
      validationRunId: Number(result.rows[0].validation_run_id),
      validationTypes: (result.rows[0].validation_types as string[]).map(String)
    };
  }

  /** Reports whether a validation run already holds immutable results. */
  async validationRunHasResults(validationRunId: number): Promise<boolean> {
    const result = await this.pool.query(
      'SELECT 1 FROM validation_result WHERE validation_run_id = $1 LIMIT 1',
      [validationRunId]
    );
    return Boolean(result.rowCount);
  }

  async loadExportRun(jobId: number, leaseToken: string, actorId: number): Promise<{
    exportJobId: number;
    corpusId: number;
    corpusKey: string;
    format: string;
    includeRawContent: boolean;
    artifactExists: boolean;
  } | null> {
    const result = await this.pool.query(
      `SELECT x.export_job_id, x.corpus_id, c.corpus_key, x.format, x.include_raw_content,
              EXISTS (SELECT 1 FROM export_artifact a WHERE a.job_id = j.job_id) AS artifact_exists
       FROM export_job x
       JOIN corpus c ON c.corpus_id = x.corpus_id
       JOIN asynchronous_job j ON j.job_id = x.job_id
       WHERE x.job_id = $1 AND j.lease_token = $2::uuid
         AND j.worker_actor_id = $3 AND j.status = 'RUNNING'
         AND j.lease_expires_at > CURRENT_TIMESTAMP`,
      [jobId, leaseToken, actorId]
    );
    if (!result.rowCount) return null;
    return {
      exportJobId: Number(result.rows[0].export_job_id),
      corpusId: Number(result.rows[0].corpus_id),
      corpusKey: String(result.rows[0].corpus_key),
      format: String(result.rows[0].format),
      includeRawContent: Boolean(result.rows[0].include_raw_content),
      artifactExists: Boolean(result.rows[0].artifact_exists)
    };
  }

  async exportArtifactPublished(jobId: number, artifactKey: string): Promise<boolean> {
    const result = await this.pool.query(
      `SELECT 1
       FROM export_artifact a
       JOIN asynchronous_job j ON j.job_id = a.job_id
       WHERE a.job_id = $1 AND a.artifact_key = $2::uuid AND j.status = 'COMPLETED'`,
      [jobId, artifactKey]
    );
    return Boolean(result.rowCount);
  }

  /**
   * Appends immutable validation results. The insert is guarded by the current
   * lease so a stale worker cannot append to a job it no longer owns.
   */
  async appendValidationResults(
    jobId: number,
    leaseToken: string,
    actorId: number,
    validationRunId: number,
    results: readonly ValidationResultInput[]
  ): Promise<number> {
    if (!results.length) return 0;
    return this.transaction(async (client) => {
      const owned = await client.query(
        `SELECT 1 FROM asynchronous_job
         WHERE job_id = $1 AND lease_token = $2::uuid AND worker_actor_id = $3 AND status = 'RUNNING'`,
        [jobId, leaseToken, actorId]
      );
      if (!owned.rowCount) return 0;
      const inserted = await client.query(
        `INSERT INTO validation_result
           (validation_run_id, validation_type, status, code, message, subject_type, subject_id)
         SELECT $1, entry.validation_type, entry.status, entry.code, entry.message, entry.subject_type, entry.subject_id
         FROM unnest($2::text[], $3::text[], $4::text[], $5::text[], $6::text[], $7::bigint[])
           AS entry(validation_type, status, code, message, subject_type, subject_id)`,
        [
          validationRunId,
          results.map((result) => result.validationType),
          results.map((result) => result.status),
          results.map((result) => result.code),
          results.map((result) => result.message),
          results.map((result) => result.subjectType ?? null),
          results.map((result) => result.subjectId ?? null)
        ]
      );
      return inserted.rowCount ?? 0;
    });
  }

  async finalize(
    jobId: number,
    leaseToken: string,
    actorId: number,
    status: 'COMPLETED' | 'FAILED' | 'CANCELLED',
    errorCode: string | null = null,
    errorMessage: string | null = null,
    options: { completeValidationRun?: boolean; exportArtifact?: ExportArtifactRecord } = {}
  ): Promise<JobRow | null> {
    return this.transaction(async (client) => {
      const publishingExport = options.exportArtifact !== undefined;
      const result = await client.query(
        `UPDATE asynchronous_job
         SET status = $4, error_code = $5, error_message = $6, completed_at = CURRENT_TIMESTAMP,
             worker_actor_id = NULL, lease_token = NULL, lease_expires_at = NULL, heartbeat_at = NULL,
             updated_at = CURRENT_TIMESTAMP
         WHERE job_id = $1 AND lease_token = $2::uuid AND worker_actor_id = $3 AND status = 'RUNNING'
           AND (NOT $7::boolean OR (
             job_type = 'EXPORT' AND cancel_requested = FALSE
             AND lease_expires_at > CURRENT_TIMESTAMP AND $4 = 'COMPLETED'
           ))
         RETURNING *`,
        [jobId, leaseToken, actorId, status, errorCode, errorMessage, publishingExport]
      );
      if (!result.rowCount) return null;
      if (options.completeValidationRun && status === 'COMPLETED') {
        await client.query(
          'UPDATE validation_run SET completed_at = CURRENT_TIMESTAMP WHERE job_id = $1 AND completed_at IS NULL',
          [jobId]
        );
      }
      if (options.exportArtifact && status === 'COMPLETED') {
        const artifact = await client.query(
          `INSERT INTO export_artifact
             (artifact_key, job_id, export_job_id, content_type, format_version,
              byte_length, sha256, relative_locator)
           VALUES ($1::uuid,$2,$3,$4,$5,$6,$7,$8)
           RETURNING export_artifact_id`,
          [
            options.exportArtifact.artifactKey, jobId, options.exportArtifact.exportJobId,
            options.exportArtifact.contentType, options.exportArtifact.formatVersion,
            options.exportArtifact.byteLength, options.exportArtifact.sha256,
            options.exportArtifact.relativeLocator
          ]
        );
        await client.query(
          `INSERT INTO audit_event
             (actor_id, action, resource_type, resource_id, correlation_id, outcome, detail)
           VALUES ($1, 'ARTIFACT_PUBLISHED', 'export_artifact', $2, $3, 'SUCCEEDED',
                   'Published immutable local export artifact metadata after atomic final write.')`,
          [actorId, artifact.rows[0].export_artifact_id, result.rows[0].correlation_id]
        );
      }
      await this.audit(client, actorId, `JOB_${status}`, result.rows[0], `Finalized job as ${status}.`);
      return result.rows[0];
    });
  }
}
