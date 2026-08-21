import { randomUUID } from 'node:crypto';
import type { Pool, PoolClient } from 'pg';
import type { ValidationResultInput } from './validation-executor.js';

export type JobType = 'SYSTEM_NOOP' | 'VALIDATION';
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
    options: { completeValidationRun?: boolean } = {}
  ): Promise<JobRow | null> {
    return this.transaction(async (client) => {
      const result = await client.query(
        `UPDATE asynchronous_job
         SET status = $4, error_code = $5, error_message = $6, completed_at = CURRENT_TIMESTAMP,
             worker_actor_id = NULL, lease_token = NULL, lease_expires_at = NULL, heartbeat_at = NULL,
             updated_at = CURRENT_TIMESTAMP
         WHERE job_id = $1 AND lease_token = $2::uuid AND worker_actor_id = $3 AND status = 'RUNNING'
         RETURNING *`,
        [jobId, leaseToken, actorId, status, errorCode, errorMessage]
      );
      if (!result.rowCount) return null;
      if (options.completeValidationRun && status === 'COMPLETED') {
        await client.query(
          'UPDATE validation_run SET completed_at = CURRENT_TIMESTAMP WHERE job_id = $1 AND completed_at IS NULL',
          [jobId]
        );
      }
      await this.audit(client, actorId, `JOB_${status}`, result.rows[0], `Finalized job as ${status}.`);
      return result.rows[0];
    });
  }
}
