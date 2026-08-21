# ADR-0004: Durable SYSTEM Worker for Asynchronous Internal Jobs

## Status

Proposed for R2 — 2026-08-21

## 1. Context

Berean persists asynchronous administrative jobs (`DISCOVERY`, `INGESTION`, `VALIDATION`, `EXPORT`) but does not yet ship a durable worker that executes queued work end-to-end. The architecture already distinguishes workflow coordination from authoritative knowledge and requires explicit provenance, review, and bounded capability behavior ([`../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md), [`../api/API_LIMITATIONS.md`](../api/API_LIMITATIONS.md)).

Current repository behavior queues jobs and supports API-level retry/cancel transitions in administration code ([`../../src/administration/repository.ts`](../../src/administration/repository.ts)), while ingestion semantics remain provenance-first and non-truth-adjudicating ([`../../src/ingestion/pipeline.ts`](../../src/ingestion/pipeline.ts)).

## 2. Decision

Introduce a separately deployed, durable `SYSTEM` worker process that claims queued internal jobs and executes registered job executors safely. This worker is operational infrastructure, not epistemic authority:

- it executes bounded procedures against already-modeled structures;
- it must not create new truth semantics;
- it must not bypass review/provenance boundaries;
- it must not auto-promote discovery candidates/evidence/claims/mappings;
- it must not adjudicate truth.

## 3. Goals / non-goals

### Goals

- Reliably execute queued internal jobs with crash-safe claim/lease recovery.
- Preserve explicit operational auditability and normalized failure semantics.
- Keep queue orchestration separate from knowledge-authority semantics.
- Enable incremental rollout without changing external read semantics.

### Non-goals

- No redesign of Berean authoritative schema semantics.
- No generalized workflow engine or arbitrary plugin runtime.
- No automatic scholarly interpretation, contradiction resolution, or truth confirmation.
- No in-worker source acquisition from arbitrary external locations.

## 4. Existing state and gap

The current API and repository can queue jobs and expose status/retry/cancel operations, but durable in-process dequeue/execution is not shipped ([`../api/API_LIMITATIONS.md`](../api/API_LIMITATIONS.md)).

Gaps to close:

- safe concurrent claiming by multiple worker instances;
- lease heartbeat and recovery after worker failure;
- running-job cooperative cancellation;
- bounded retries and attempt limits;
- operational observability for queue/worker health.

## 5. Architecture and process model

- **API process**: validates/authenticates and writes queue rows, job specializations, and audit events.
- **SYSTEM worker process**: separate entry point (for example `src/worker/system-worker.ts`), separate process lifecycle, configured with DB + worker settings.
- **Topology**: one or more worker instances may run concurrently; each claims jobs with row-level locking and lease token ownership.
- **Actor identity**: each worker executes as a configured `workflow_actor` with role `SYSTEM` and stable actor key (environment configured), used for audit and mutation attribution.

The API remains authoritative for request acceptance and state visibility; the worker remains authoritative only for execution progress/finalization of claimed jobs.

## 6. Proposed schema evolution

Add execution/lease fields to `asynchronous_job`:

- `worker_actor_id BIGINT NULL REFERENCES workflow_actor(actor_id)`
- `lease_token TEXT NULL`
- `lease_expires_at TIMESTAMPTZ NULL`
- `heartbeat_at TIMESTAMPTZ NULL`
- `cancel_requested BOOLEAN NOT NULL DEFAULT FALSE`

Add a claim-focused index (name illustrative):

- `CREATE INDEX asynchronous_job_claimable_idx ON asynchronous_job (status, lease_expires_at, created_at) WHERE status = 'QUEUED';`

`worker_actor_id` and `lease_token` represent current execution ownership. `heartbeat_at` and `lease_expires_at` support liveness and recovery.

## 7. Claiming, lease, heartbeat, recovery, cancellation, retry

### Claiming (safe multi-worker)

Workers claim atomically using PostgreSQL row locks:

```sql
WITH candidate AS (
  SELECT job_id
  FROM asynchronous_job
  WHERE status = 'QUEUED'
    AND cancel_requested = FALSE
    AND attempt_count < $1
  ORDER BY created_at, job_id
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
UPDATE asynchronous_job j
SET status = 'RUNNING',
    started_at = COALESCE(started_at, CURRENT_TIMESTAMP),
    worker_actor_id = $2,
    lease_token = $3,
    heartbeat_at = CURRENT_TIMESTAMP,
    lease_expires_at = CURRENT_TIMESTAMP + ($4::interval),
    updated_at = CURRENT_TIMESTAMP
FROM candidate
WHERE j.job_id = candidate.job_id
RETURNING j.*;
```

### Poll/lease/heartbeat configuration

Worker configuration is explicit and bounded:

- poll interval (for queued work);
- lease duration;
- heartbeat interval;
- stale-lease reclaim grace;
- maximum attempts and retry backoff policy;
- batch size (default 1 for deterministic initial rollout).

Worker heartbeats update only rows owned by matching `(job_id, lease_token, worker_actor_id)`.

### Recovery on expiry

If a worker dies and the lease expires, another worker can reclaim the job by standard queued-claim logic after the prior lease is considered stale. Recovery must be idempotent and preserve attempt accounting.

### Revised cancellation semantics

- **Queued job cancel**: immediate terminal `CANCELLED` transition.
- **Running job cancel**: API sets `cancel_requested = TRUE`; status remains `RUNNING` until executor observes cancellation checkpoint and exits safely.
- **Worker finalization**: worker writes terminal `CANCELLED` with normalized cancellation code/message, completion timestamp, and audit event.

This avoids unsafe partial writes from abrupt status flipping on active execution.

### Retry semantics

Retry is allowed only from terminal `FAILED` or `CANCELLED` states.

On retry request:

- transition to `QUEUED`;
- increment `attempt_count`;
- clear execution fields (`worker_actor_id`, `lease_token`, `lease_expires_at`, `heartbeat_at`, `started_at`, `completed_at`, `cancel_requested`, `error_code`, `error_message`);
- record audit event.

Retry is denied when `attempt_count` already reached configured maximum.

## 8. Executor registry and per-job-type boundaries

The worker uses a closed executor registry keyed by `job_type`. Registry entries are compile-time/configured in code, not mutable at runtime.

- `INGESTION` executor: performs bounded ingestion orchestration; must keep provenance and representation boundaries from ingestion pipeline behavior.
- `VALIDATION` executor (implemented): runs a bounded, read-only structural validation workflow and persists immutable `validation_result` rows only. A result is an operational reproducibility record, never a truth determination.
- `EXPORT` executor: runs bounded export workflow with policy checks.
- `DISCOVERY` executor: **queue-only in R2** (no automatic external retrieval/candidate promotion) and may complete as `NOT_IMPLEMENTED`/deferred behavior while preserving audit.

Boundaries preserved:

- no discovery candidate auto-promotion to evidence/claim;
- no evidence/derivation auto-promotion to claim;
- no identity mapping auto-promotion `PROPOSED -> ACTIVE`.

## 9. State transitions, audit, errors, security, observability

### State transitions

Allowed transitions (R2):

- `QUEUED -> RUNNING` (worker claim)
- `QUEUED -> CANCELLED` (immediate cancel)
- `RUNNING -> COMPLETED | FAILED | CANCELLED` (worker finalization)
- `FAILED | CANCELLED -> QUEUED` (retry)
- Optional preexisting `WAITING_FOR_REVIEW` handling remains explicit and non-automatic.

Invalid transitions return `INVALID_JOB_STATE`.

### Audit behavior

Every state transition and execution-finalization mutation writes `audit_event` in the same transaction, including actor identity (`SYSTEM` worker for execution transitions) and correlation metadata.

### Normalized errors

Executors must return normalized domain-safe `error_code`/`error_message` values, without leaking SQL internals, credentials, or arbitrary stack traces in persisted fields.

### Security constraints (explicit prohibitions)

The worker must **not** perform:

- arbitrary URL fetching;
- user-controlled filesystem path access;
- arbitrary SQL execution;
- runtime registry mutation;
- automatic candidate/evidence/claim/mapping promotion;
- truth adjudication.

All DB calls are parameterized and bounded. Worker identity is credentialed as `SYSTEM` only for required queue execution responsibilities.

### Observability

Emit metrics/logging for:

- queue depth by type/status;
- claim/lease latency;
- heartbeat freshness;
- lease-expiry recoveries;
- attempt counts and retry outcomes;
- executor duration/success/failure/cancel counts.

Correlate logs/metrics with `job_id`, `correlation_id`, `job_type`, and `lease_token`.

## 10. Testing strategy and rollout phases

### Test strategy

- unit tests: claim query behavior, lease-token ownership checks, cancellation/retry transition guards, max-attempt enforcement;
- integration tests: concurrent workers claiming distinct jobs via `FOR UPDATE SKIP LOCKED`, heartbeat extension, stale-lease recovery, cooperative running cancellation;
- failure-mode tests: worker crash between claim and finalize, duplicate heartbeat with wrong lease token, retry refusal at limit;
- documentation/link tests updated for ADR indexing.

### Rollout phases

1. **Phase A** (implemented): schema migration + no-op worker skeleton + metrics.
2. **Phase B** (implemented): enable claiming/lease/heartbeat and terminal finalization for one executor type — the read-only `VALIDATION` executor (`src/worker/validation-executor.ts`), documented in [`../05-validation/VALIDATION.md`](../05-validation/VALIDATION.md).
3. **Phase C**: enable remaining executor types (except discovery execution), bounded retries, cooperative cancellation.
4. **Phase D**: hardening (alerts, dashboards, runbooks), promote as default operational mode.

Discovery remains queue-only unless a future ADR defines a sandboxed retrieval subsystem and review-safe promotion model.

## 11. Consequences, risks, acceptance criteria, deferred decisions

### Consequences

- Operational completeness improves for asynchronous jobs.
- Administration/read boundaries remain unchanged.
- Worker deployment/operations become a required runtime concern.

### Risks and mitigations

- **Lease misconfiguration** can cause premature reclaim or slow recovery — mitigate with conservative defaults and heartbeat SLO monitoring.
- **Executor side effects** can break idempotency — mitigate with transactional boundaries and deterministic idempotency keys.
- **Cancellation race conditions** can leave ambiguous state — mitigate with lease-token ownership checks and transactional finalization.

### Acceptance criteria

- Concurrent workers claim different jobs without double-execution.
- Running cancellation is cooperative and finalized safely by worker completion path.
- Queued cancellation is immediate terminal.
- Retry only allowed from terminal failed/cancelled states and clears execution fields.
- Expired leases are recoverable and auditable.
- Discovery remains queue-only; no automatic epistemic promotion behavior is introduced.
- Documentation and link-integrity tests pass with ADR-0004 indexed.

### Deferred decisions

- exact lease interval defaults and environment-specific tuning;
- whether to support worker sharding/partitioning by job type in R2 or post-R2;
- dead-letter queue policy for permanently failing jobs;
- future sandboxed external retrieval architecture (if ever introduced) under separate ADR.
