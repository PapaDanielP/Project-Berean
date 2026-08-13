# API Capability Matrix

This matrix is exhaustive for the HTTP routes implemented in `src/app.ts`, `src/api/v1.ts`, and `src/administration/routes.ts`.

Authoritative architecture references:

- [`../01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md)
- [`../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md)

## Route matrix

| Method / path | Auth / minimum role | Sync / async | Idempotent? | Concurrency control | Authoritative-knowledge impact | Classification | Tests / evidence |
|---|---|---|---|---|---|---|---|
| GET `/health` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
| GET `/openapi.json` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts` |
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
| GET `/api/provenance/claims/:claimId` | none | sync | n/a | none | none | IMPLEMENTED | manual 2026-08-13 |
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
| GET `/api/v1/registry/:registry` | none | sync | n/a | none | none | IMPLEMENTED | manual 2026-08-13 |
| GET `/api/v1/search/:resource?` | none | sync | n/a | none | none | PARTIALLY_IMPLEMENTED | manual 2026-08-13; unfiltered search works, some resource filters fail |
| POST `/api/v1/research` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/research/capabilities` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/provenance/claim/:id` | none | sync | n/a | none | none | IMPLEMENTED | manual 2026-08-13 |
| GET `/api/v1/graph/entity/:id` | none | sync | n/a | none | none | IMPLEMENTED | code-traced |
| GET `/api/v1/:resource/:id` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts`, code-traced |
| GET `/api/v1/:resource` | none | sync | n/a | none | none | IMPLEMENTED | `tests/app/app.test.ts`, code-traced |
| wildcard other `/api/v1/*` methods/paths | none | sync | n/a | none | none | IMPLEMENTED | manual 2026-08-13 (`501 NOT_REPRESENTED` for unmatched methods/paths) |
| GET `/api/v1/admin/:resource` | bearer / `READER` | sync | n/a | none | none | PARTIALLY_IMPLEMENTED | code-traced, manual 2026-08-13; invalid resources return 500 |
| POST `/api/v1/corpora` | bearer / `ADMINISTRATOR` | sync | no | none | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| PATCH `/api/v1/corpora/:id` | bearer / `ADMINISTRATOR` | sync | no | `If-Match` integer version; stale => `409 STALE_VERSION` | none (workflow only) | IMPLEMENTED | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/research-topics` | bearer / `RESEARCHER` | sync | no | none | none (workflow only) | IMPLEMENTED | code-traced, manual 2026-08-13 |
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
| POST `/api/v1/ingestion-jobs` | bearer / `CONTENT_EDITOR` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | none until external worker acts | PARTIALLY_IMPLEMENTED, REQUIRES_SYSTEM_WORKER | code-traced |
| POST `/api/v1/validation-runs` | bearer / `REVIEWER` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | none until external worker acts | PARTIALLY_IMPLEMENTED, REQUIRES_SYSTEM_WORKER, REQUIRES_HUMAN_REVIEW | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST `/api/v1/export-jobs` | bearer / `ADMINISTRATOR` | async queued | yes, per actor+job type+key+fingerprint | `Idempotency-Key` | none until external worker acts | PARTIALLY_IMPLEMENTED, REQUIRES_SYSTEM_WORKER | code-traced |
| POST `/api/v1/jobs/:id/cancel` | bearer / `CONTENT_EDITOR` plus job-type/ownership checks | sync | no | job status gate | none (workflow only) | IMPLEMENTED | manual 2026-08-13 |
| POST `/api/v1/jobs/:id/retry` | bearer / `CONTENT_EDITOR` plus job-type/ownership checks | sync | no | job status gate | none (workflow only) | IMPLEMENTED | manual 2026-08-13 |

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

These routes persist queue state immediately, but execution beyond `QUEUED` is outside the process shipped here.

## What should deliberately never become an automatic API capability

- Arbitrary URL fetching, filesystem reads, or SQL execution from API inputs
- Automatic candidate → evidence promotion
- Automatic evidence → claim promotion
- Automatic `PROPOSED` → `ACTIVE` identity promotion
- Truth/falsity adjudication
- Generalized inference or contradiction classification not already persisted by humans
- Person-to-organization membership inference from co-participation
- Treating `NOT_REPRESENTED`, `NO_MATCH`, or locator-only storage as falsity or source silence
