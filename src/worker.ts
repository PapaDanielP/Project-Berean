import { Pool } from 'pg';
import { WorkerRepository, type JobType } from './worker/repository.js';
import { EXECUTABLE_JOB_TYPES, EXECUTORS } from './worker/executors.js';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL is required');

const positiveInteger = (name: string, fallback: number, maximum: number): number => {
  const raw = process.env[name];
  if (raw === undefined) return fallback;
  const value = Number.parseInt(raw, 10);
  if (!Number.isSafeInteger(value) || value < 1 || value > maximum) throw new Error(`${name} must be an integer between 1 and ${maximum}`);
  return value;
};

const enabledTypes = (process.env.BEREAN_SYSTEM_WORKER_ENABLED_TYPES ?? EXECUTABLE_JOB_TYPES.join(','))
  .split(',').map((value) => value.trim()).filter(Boolean);
const unsupported = enabledTypes.filter((type) => !(EXECUTABLE_JOB_TYPES as string[]).includes(type));
if (unsupported.length) {
  throw new Error(`Only ${EXECUTABLE_JOB_TYPES.join(', ')} job types have registered executors`);
}

const config = {
  actorKey: process.env.BEREAN_SYSTEM_WORKER_KEY ?? 'local-system-worker',
  displayName: process.env.BEREAN_SYSTEM_WORKER_DISPLAY_NAME ?? 'Local SYSTEM Worker',
  pollMilliseconds: positiveInteger('BEREAN_SYSTEM_WORKER_POLL_MS', 1000, 60_000),
  leaseSeconds: positiveInteger('BEREAN_SYSTEM_WORKER_LEASE_SECONDS', 60, 3600),
  heartbeatSeconds: positiveInteger('BEREAN_SYSTEM_WORKER_HEARTBEAT_SECONDS', 15, 1800),
  maxAttempts: positiveInteger('BEREAN_SYSTEM_WORKER_MAX_ATTEMPTS', 3, 100),
  exportArtifactDir: process.env.EXPORT_ARTIFACT_DIR,
  enabledTypes: enabledTypes as JobType[]
};
if (config.heartbeatSeconds >= config.leaseSeconds) throw new Error('BEREAN_SYSTEM_WORKER_HEARTBEAT_SECONDS must be less than BEREAN_SYSTEM_WORKER_LEASE_SECONDS');

const pool = new Pool({ connectionString: databaseUrl });
const repository = new WorkerRepository(pool);
let stopping = false;
let active: Promise<void> | undefined;

const sleep = (milliseconds: number) => new Promise<void>((resolve) => setTimeout(resolve, milliseconds));

const run = async (): Promise<void> => {
  const actorId = await repository.resolveSystemActor(config.actorKey, config.displayName);
  while (!stopping) {
    await repository.recoverExpired(actorId, config.maxAttempts, config.enabledTypes);
    const job = await repository.claimOne(actorId, config.leaseSeconds, config.maxAttempts, config.enabledTypes);
    if (!job) {
      await sleep(config.pollMilliseconds);
      continue;
    }
    const jobId = Number(job.job_id);
    const leaseToken = String(job.lease_token);
    const executor = EXECUTORS[job.job_type as JobType];
    const heartbeat = setInterval(() => {
      void repository.renewLease(jobId, leaseToken, actorId, config.leaseSeconds).catch(() => undefined);
    }, config.heartbeatSeconds * 1000);
    let outcome;
    try {
      outcome = await executor({
        pool, repository, actorId, jobId, leaseToken, job,
        exportArtifactDir: config.exportArtifactDir
      });
    } catch {
      outcome = {
        status: 'FAILED' as const,
        errorCode: 'EXECUTOR_UNHANDLED_FAILURE',
        errorMessage: 'The executor stopped with an unhandled failure.'
      };
    } finally {
      clearInterval(heartbeat);
    }
    try {
      const finalized = await repository.finalize(
        jobId, leaseToken, actorId, outcome.status,
        outcome.errorCode ?? null, outcome.errorMessage ?? null,
        {
          completeValidationRun: outcome.completeValidationRun === true,
          exportArtifact: outcome.exportArtifact?.record
        }
      );
      if (!finalized && outcome.exportArtifact) {
        await outcome.exportArtifact.discard();
        if (await repository.cancellationRequested(jobId, leaseToken, actorId)) {
          await repository.finalize(
            jobId, leaseToken, actorId, 'CANCELLED',
            'CANCELLED_BY_REQUEST', 'Cancellation was observed before artifact metadata publication.'
          );
        }
      }
    } catch {
      await outcome.exportArtifact?.discard();
      await repository.finalize(
        jobId, leaseToken, actorId, 'FAILED',
        'EXPORT_ARTIFACT_PERSIST_FAILED', 'Artifact metadata could not be persisted after the final write.'
      );
    }
  }
};

const shutdown = (): void => {
  stopping = true;
  void (async () => {
    await active;
    await pool.end();
  })();
};

process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
active = run().catch(async (error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  await pool.end();
  process.exitCode = 1;
});
