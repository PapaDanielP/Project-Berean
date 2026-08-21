# API Capability Matrix

This matrix is exhaustive for the HTTP routes implemented in `src/app.ts`, `src/api/v1.ts`, and `src/administration/routes.ts`.

Authoritative architecture references:

- [`../01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md)
- [`../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md)

## Route matrix

| Method / path | Auth / minimum role | Sync / async | Idempotent? | Concurrency control | Authoritative-knowledge impact | Classification | Tests / evidence |
|---|---|---|---|---|---|---|---|
| GET `/health` | none | sync | n/a | none | none | IMPLEMENTED | code-traced (behavior tests exercise `GET /api/v1/health`, not this compatibility alias) |
| GET `/openapi.json` | none | sync | n/a | none | none | IMPLEMENTED (complete for the implemented route surface) | `tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts` |
| GET `/api-docs` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/research/scope` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/research` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| GET `/api/search` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| GET `/api/entities/:entityId` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/claims/:claimId` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/propositions/:propositionId` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/events/:eventId` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/sources` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/sources/:sourceId` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/provenance/claims/:claimId` | none | sync | n/a | none | none | IMPLEMENTED (intentional compatibility difference: 200 + empty traversal for a missing claim) | `tests/app/app.test.ts` |
| GET `/api/provenance/explain` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/derivations/check-eligibility` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/exploration/timeline` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/genesis/coverage` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/dashboard/quality` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/graph` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `*` (Explorer shell) | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/v1/health` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/v1/capabilities` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/v1/schema` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/registry/:registry` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (`registry/predicates`), `tests/app/openapi-coverage.test.ts` (`registry/capabilities` 307 redirect), manual 2026-08-13 |
| GET `/api/v1/search/:resource?` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (every supported filter, resource filter before limit, unknown filter 404, unindexed 501, `NO_MATCH`) |
| POST `/api/v1/research` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/api/v1/research/capabilities` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/provenance/claim/:id` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (missing claim returns 404) |
| GET `/api/v1/graph/entity/:id` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/:resource/:id` | none | sync | n/a | none | none | IMPLEMENTED | code-traced (route surface asserted by `tests/app/openapi-coverage.test.ts`; no behavior test issues a generic single-resource read) |
| GET `/api/v1/:resource` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (`/api/v1/entities`) |
| wildcard other `/api/v1/*` methods/paths | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (`501 NOT_REPRESENTED` for unmatched methods/paths) |
| GET `/api/v1/admin/:resource` | bearer / `READER` | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` (unsupported resource returns 404 without leakage) |
| POST `/api/v1/corpora` | bearer / `ADMINISTRATOR` | sync | no | none | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| PATCH `/api/v1/corpora/:id` | bearer / `ADMINISTRATOR` | sync | no | `If-Match` integer version; stale => `409 STALE_VERSION`, no partial commit | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts` (stale write leaves name, status, version, and audit count unchanged) |
| POST `/api/v1/research-topics` | bearer / `RESEARCHER` | sync | no | none | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/discovery-requests` | bearer / `RESEARCHER` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | none (workflow only) | IMPLEMENTED, REQUIRES_SYSTEM_WORKER | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/discovery-requests/:id/candidates` | bearer / `RESEARCHER` | sync | no | none | proposed workflow only | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/candidates/:id/review` | bearer / `REVIEWER` | sync | upsert by candidate | none | reviewed workflow only | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/source-registrations` | bearer / `CONTENT_EDITOR` | sync | partial upsert by stable keys | none | active authoritative rows (`source`, `dataset`, `corpus_dataset`) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/source-records` | bearer / `CONTENT_EDITOR` | sync | partial upsert by stable keys | none | active authoritative rows (`source_record`, `citation`) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/evidence` | bearer / `CONTENT_EDITOR` | sync | no | none | active authoritative rows (`evidence`, `evidence_citation`) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/claims` | bearer / `REVIEWER` | sync | no | none | active or under-review authoritative claim/proposition rows | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/identity-mappings` | bearer / `CONTENT_EDITOR` | sync | no | none | proposed reconciliation only | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/identity-mappings/:id/review` | bearer / `REVIEWER` | sync | no | only `PROPOSED` rows may transition | reviewed/active-or-rejected reconciliation | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/derivations` | bearer / `RESEARCHER` | sync | no | none | active authoritative derivation metadata only; no claim auto-created | IMPLEMENTED, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts` |
| POST `/api/v1/ingestion-jobs` | bearer / `CONTENT_EDITOR` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | none until external worker acts | IMPLEMENTED (queue persistence), REQUIRES_SYSTEM_WORKER (execution) | code-traced |
| POST `/api/v1/validation-runs` | bearer / `REVIEWER` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | executed by the SYSTEM worker for `SCHEMA`, `PROVENANCE`, `READ_ONLY`, `NEGATIVE_SEMANTIC`; other requested types record `NOT_APPLICABLE` | IMPLEMENTED (queue persistence and validation execution) | `tests/app/app.test.ts` |
| POST `/api/v1/export-jobs` | bearer / `ADMINISTRATOR` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | bounded immutable local artifact metadata on successful worker completion | IMPLEMENTED (`JSONL`, no raw content) | `tests/app/app.test.ts` |
| GET `/api/v1/export-artifacts/:artifactKey[/download]` | bearer / `ADMINISTRATOR` | sync read | no | opaque persisted UUID | none | IMPLEMENTED (configured-root-only, integrity checked) | `tests/app/app.test.ts` |
| POST `/api/v1/jobs/:id/cancel` | bearer / `CONTENT_EDITOR` plus job-type/ownership checks | sync | no | job status gate | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts` (unknown job returns `404` without leakage), manual 2026-08-13 |
| POST `/api/v1/jobs/:id/retry` | bearer / `CONTENT_EDITOR` plus job-type/ownership checks | sync | no | job status gate | none (workflow only) | IMPLEMENTED | manual 2026-08-13 |

### Evidence column legend

- **`tests/app/*.ts`** — the route is exercised at HTTP behavior level by the named suite.
- **code-traced** — the route's existence and documentation are enforced by
  [`tests/app/openapi-coverage.test.ts`](../../tests/app/openapi-coverage.test.ts), which walks the live Express
  route stack, but no suite asserts its response body. Route-surface coverage is not behavior coverage.
- **manual `<date>`** — a one-time manual observation recorded in
  [`VERIFICATION_REPORT.md`](./VERIFICATION_REPORT.md); it is not re-executed by CI.

The current code-traced (behavior-untested) set is enumerated under `IMPLEMENTED_BUT_UNTESTED` in
[`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md).

## What APIs can do today

- Read persisted Berean knowledge, provenance, coverage, graph neighborhoods, and structural derivation checks.
- Discover persisted research scope and run bounded, read-only research over registered predicates.
- Search represented records by keyword.
- Create and version corpora and research topics.
- Queue discovery requests, record candidates, and review them.
- Register sources, datasets, source records, citations, evidence, claims, identity mappings, and derivations.
- Queue ingestion, validation, and export jobs, and cancel/retry queued or failed jobs.
- Append immutable audit events for successful administrative mutations.

## What APIs can prepare but cannot decide

- Discovery requests and candidates can prepare reviewed work, but they do not create evidence or claims automatically.
- Identity mappings can be proposed, but `PROPOSED` is not `ACTIVE`.
- Derivations can be recorded, but they do not create derived claims automatically.
- Research can classify results as `ESTABLISHED`, `DERIVED`, `SCHOLARLY_CANDIDATE`, `UNRESOLVED`, `NOT_REPRESENTED`, or `NO_MATCH`, but it never decides truth.
- Claim creation can persist `UNDER_REVIEW` or `ACTIVE`, but claim status is still not a truth determination.

## What requires a SYSTEM worker

- `POST /api/v1/discovery-requests`
- `POST /api/v1/ingestion-jobs`
- `POST /api/v1/validation-runs`
- `POST /api/v1/export-jobs`

These routes persist queue state immediately. Execution happens in the separate `npm run worker`
process, whose closed executor registry covers `SYSTEM_NOOP`, `VALIDATION`, and bounded `EXPORT`.
Ingestion and discovery jobs stay `QUEUED` until their bounded executors exist.

## What should deliberately never become an automatic API capability

- Arbitrary URL fetching, filesystem reads, or SQL execution from API inputs
- Automatic candidate → evidence promotion
- Automatic evidence → claim promotion
- Automatic `PROPOSED` → `ACTIVE` identity promotion
- Truth/falsity adjudication
- Generalized inference or contradiction classification not already persisted by humans
- Person-to-organization membership inference from co-participation
- Treating `NOT_REPRESENTED`, `NO_MATCH`, or locator-only storage as falsity or source silence

## Administrative completeness matrix

For each administrative domain: how it is represented in the database, whether the API exposes it, whether it is
SQL/script-only, whether exposing more of it would be architecturally safe, and the controls that apply.

| Domain | Database representation | API exposure | SQL / script only | Safe to expose further? | Persistence required | Authorization | Audited | Async / idempotent | Human review |
|---|---|---|---|---|---|---|---|---|---|
| Corpus | `corpus`, `corpus_dataset` | `POST /api/v1/corpora`, `PATCH /api/v1/corpora/:id`, `GET /api/v1/admin/corpora` | Deletion is SQL-only by design | Yes for read expansion; **no** for delete — corpora are referenced by discovery, jobs, and exports | Yes | `ADMINISTRATOR` (write), `READER` (read) | Yes | Sync; `If-Match` version | No |
| Dataset | `dataset` | Created through `POST /api/v1/source-registrations`; read through `GET /api/v1/datasets` | Licence changes are SQL-only | Only with reviewed licence workflow; licence status must not be editable casually | Yes | `CONTENT_EDITOR` | Yes | Sync | No |
| Source | `source`, `source_type` | `POST /api/v1/source-registrations`, `GET /api/v1/sources` | `source_type` registry is migration-only | Registry mutation must stay migration-only | Yes | `CONTENT_EDITOR` | Yes | Sync; stable-key reuse | No |
| Source record / citation | `source_record`, `citation`, `evidence_citation` | `POST /api/v1/source-records`, `GET /api/v1/source-records`, `GET /api/v1/citations` | Bulk load via `src/ingestion` | Yes for reads; bulk import must stay a controlled job | Yes | `CONTENT_EDITOR` | Yes | Sync; stable-key reuse | No |
| Discovery | `discovery_request`, `asynchronous_job` | `POST /api/v1/discovery-requests`, `GET /api/v1/admin/discoveries` | Execution is worker-only (absent) | Yes for status reads; execution requires a `SYSTEM` worker | Yes | `RESEARCHER` | Yes | `202`; `Idempotency-Key` | Downstream review required |
| Candidate | `discovery_candidate`, `candidate_review` | `POST /api/v1/discovery-requests/:id/candidates`, `POST /api/v1/candidates/:id/review`, `GET /api/v1/admin/candidates` | — | **No** automatic promotion to evidence | Yes | `RESEARCHER` / `REVIEWER` | Yes | Sync; review upserts | **Yes** |
| Identity | `source_identity`, `entity_source_mapping` | `POST /api/v1/identity-mappings`, `POST /api/v1/identity-mappings/:id/review`, `GET /api/v1/identities`, `GET /api/v1/identity-mappings` | `source_identity` creation is ingestion/SQL-only | Creating identities over HTTP is acceptable only with source provenance; activation must stay reviewed | Yes | `CONTENT_EDITOR` / `REVIEWER` | Yes | Sync; `409 INVALID_MAPPING_STATE` | **Yes** |
| Ingestion | `asynchronous_job`, `ingestion_job`, `ingestion_result` | `POST /api/v1/ingestion-jobs`, `GET /api/v1/admin/jobs` | Actual ingestion runs through `npm run ingest` (`src/ingestion`) | Yes for queueing and status; arbitrary import endpoints must never exist | Yes | `CONTENT_EDITOR` | Yes | `202`; `Idempotency-Key` | Manifest review |
| Claim / evidence | `proposition`, `claim`, `claim_evidence`, `evidence`, `derivation`, `derivation_input` | `POST /api/v1/evidence`, `POST /api/v1/claims`, `POST /api/v1/derivations`, plus read routes | Claim retraction and supersession are SQL-only | Retraction could be exposed **only** as a reviewed, audited status transition that preserves the original claim | Yes | `CONTENT_EDITOR` (evidence), `REVIEWER` (claims), `RESEARCHER` (derivations) | Yes | Sync | **Yes** |
| Validation | `validation_run`, `validation_result` (append-only) | `POST /api/v1/validation-runs`, `GET /api/v1/admin/validations`, `GET /api/v1/admin/validation-results` | Full validation runs via `scripts/validation/run-postgres-validation.sh` | Yes for queue and read; results must remain append-only | Yes | `REVIEWER` | Yes | `202`; `Idempotency-Key` | Interpretation is human |
| Audit | `audit_event` (append-only) | `GET /api/v1/admin/audits` | — | Read-only forever; no write route may exist | Yes | `READER` | Is the audit | Sync | No |
| Job control | `asynchronous_job` | `POST /api/v1/jobs/:id/cancel`, `/retry`, `GET /api/v1/admin/jobs` | Worker execution absent | Yes; already state-gated and ownership-checked | Yes | `CONTENT_EDITOR` plus ownership | Yes | Sync; `409 INVALID_JOB_STATE` | No |
| Export | `export_job`, immutable `export_artifact` | `POST /api/v1/export-jobs`, `GET /api/v1/admin/exports`, `GET /api/v1/export-artifacts/:artifactKey[/download]` | Artifact production is worker-only | Implemented only for bounded JSONL under configured local storage | Yes | `ADMINISTRATOR` | Yes | `202`; `Idempotency-Key` | Licence review |

Capabilities deliberately **not** implemented after this review, with reasons:

| Missing capability | Why it was not added |
|---|---|
| Corpus / topic / candidate deletion | Deleting workflow rows would break audit and job references. Archival status already exists. |
| Claim retraction or supersession route | Requires a reviewed status-transition design that preserves the superseded claim and its provenance. Classification: **REQUIRES_HUMAN_REVIEW**. |
| Registry (predicate, type) mutation | Registries are controlled vocabularies changed by reviewed migration. Classification: **INTENTIONALLY_NOT_REPRESENTED**. |
| Single-resource `GET /api/v1/admin/:resource/:id` | No workflow need is demonstrated by tests or fixtures; list plus filter already serves review. Classification: **NOT_IMPLEMENTED**. |
| `ingestion_result` production and ingestion/discovery job execution | Requires bounded executors beyond the shipped validation/export executors. Classification: **REQUIRES_SYSTEM_WORKER**. |
| `source_identity` creation over HTTP | Identities must arrive with source provenance through ingestion. Classification: **REQUIRES_HUMAN_REVIEW**. |
