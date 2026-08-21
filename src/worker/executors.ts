// Closed worker executor registry. Entries are compile-time constants; the
// registry is never mutated at runtime and never executes stored request data.

import type { Pool } from 'pg';
import type { JobRow, JobType, WorkerRepository } from './repository.js';
import {
  ValidationExecutorError,
  executeValidationRun,
  snapshotKnowledgeTablesConsistently
} from './validation-executor.js';
import { executeExport, ExportExecutorError } from './export-executor.js';
import type { PreparedExportArtifact } from './export-artifact.js';

export interface ExecutorOutcome {
  status: 'COMPLETED' | 'CANCELLED' | 'FAILED';
  errorCode?: string;
  errorMessage?: string;
  completeValidationRun?: boolean;
  exportArtifact?: PreparedExportArtifact;
}

export interface ExecutorContext {
  pool: Pool;
  repository: WorkerRepository;
  actorId: number;
  jobId: number;
  leaseToken: string;
  job: JobRow;
  exportArtifactDir?: string;
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
  if (await repository.validationRunHasResults(run.validationRunId)) {
    return {
      status: 'FAILED',
      errorCode: 'VALIDATION_RUN_ALREADY_EXECUTED',
      errorMessage: 'The validation run already holds immutable results from an earlier attempt; queue a new validation run instead of re-executing this one.'
    };
  }
  try {
    const outcome = await executeValidationRun({
      db: pool,
      workerActorId: actorId,
      snapshot: () => snapshotKnowledgeTablesConsistently(pool),
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

const exportExecutor: Executor = async ({
  pool, repository, jobId, leaseToken, actorId, exportArtifactDir
}) => {
  const run = await repository.loadExportRun(jobId, leaseToken, actorId);
  if (!run) {
    return {
      status: 'FAILED',
      errorCode: 'EXPORT_RUN_NOT_FOUND_OR_STALE_LEASE',
      errorMessage: 'The claimed export job has no owned export request or its lease is stale.'
    };
  }
  if (run.artifactExists) {
    return {
      status: 'FAILED',
      errorCode: 'EXPORT_ALREADY_EXECUTED',
      errorMessage: 'This export job already has immutable artifact metadata and cannot be re-executed.'
    };
  }
  try {
    const artifact = await executeExport(
      pool,
      run,
      exportArtifactDir,
      () => repository.cancellationRequested(jobId, leaseToken, actorId)
    );
    return { status: 'COMPLETED', exportArtifact: artifact };
  } catch (error) {
    const code = error instanceof ExportExecutorError ? error.code : 'EXPORT_EXECUTOR_FAILED';
    if (code === 'EXPORT_CANCELLED') {
      return {
        status: 'CANCELLED',
        errorCode: 'CANCELLED_BY_REQUEST',
        errorMessage: 'Cancellation was observed before artifact metadata publication.'
      };
    }
    return {
      status: 'FAILED',
      errorCode: code,
      errorMessage: 'The export executor stopped before publishing artifact metadata.'
    };
  }
};

export const EXECUTORS: Readonly<Record<JobType, Executor>> = Object.freeze({
  SYSTEM_NOOP: systemNoopExecutor,
  VALIDATION: validationExecutor,
  EXPORT: exportExecutor
});

export const EXECUTABLE_JOB_TYPES = Object.keys(EXECUTORS) as JobType[];
