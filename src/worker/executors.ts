// Closed worker executor registry. Entries are compile-time constants; the
// registry is never mutated at runtime and never executes stored request data.

import type { Pool } from 'pg';
import type { JobRow, JobType, WorkerRepository } from './repository.js';
import { ValidationExecutorError, executeValidationRun } from './validation-executor.js';

export interface ExecutorOutcome {
  status: 'COMPLETED' | 'CANCELLED' | 'FAILED';
  errorCode?: string;
  errorMessage?: string;
  completeValidationRun?: boolean;
}

export interface ExecutorContext {
  pool: Pool;
  repository: WorkerRepository;
  actorId: number;
  jobId: number;
  leaseToken: string;
  job: JobRow;
}

export type Executor = (context: ExecutorContext) => Promise<ExecutorOutcome>;

const systemNoopExecutor: Executor = async ({ repository, jobId, leaseToken, actorId }) => {
  if (await repository.cancellationRequested(jobId, leaseToken, actorId)) {
    return { status: 'CANCELLED', errorCode: 'CANCELLED_BY_REQUEST', errorMessage: 'Cancellation was requested before no-op completion.' };
  }
  return { status: 'COMPLETED' };
};

const validationExecutor: Executor = async ({ pool, repository, jobId, leaseToken, actorId }) => {
  const run = await repository.loadValidationRun(jobId, leaseToken, actorId);
  if (!run) {
    return {
      status: 'FAILED',
      errorCode: 'VALIDATION_RUN_NOT_FOUND',
      errorMessage: 'The claimed validation job has no owned validation run.'
    };
  }
  try {
    const outcome = await executeValidationRun({
      db: pool,
      validationTypes: run.validationTypes,
      isCancelled: () => repository.cancellationRequested(jobId, leaseToken, actorId),
      persist: async (results) => {
        await repository.appendValidationResults(jobId, leaseToken, actorId, run.validationRunId, results);
      }
    });
    if (outcome.cancelled) {
      return {
        status: 'CANCELLED',
        errorCode: 'CANCELLED_BY_REQUEST',
        errorMessage: 'Cancellation was observed; no further validation results were persisted and the run was not completed.'
      };
    }
    return { status: 'COMPLETED', completeValidationRun: true };
  } catch (error) {
    return {
      status: 'FAILED',
      errorCode: error instanceof ValidationExecutorError ? error.code : 'VALIDATION_EXECUTOR_FAILED',
      errorMessage: 'The validation executor stopped before completing the requested checks. Already persisted results remain immutable.'
    };
  }
};

export const EXECUTORS: Readonly<Record<JobType, Executor>> = Object.freeze({
  SYSTEM_NOOP: systemNoopExecutor,
  VALIDATION: validationExecutor
});

export const EXECUTABLE_JOB_TYPES = Object.keys(EXECUTORS) as JobType[];
