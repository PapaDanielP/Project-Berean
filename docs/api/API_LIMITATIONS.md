# API Limitations and Non-Capabilities

This document records limitations evidenced by implementation, tests, and validation runs. It intentionally does **not** redesign the architecture.

## 1. Deliberate semantic non-capabilities

| Limitation | Actual behavior | Classification |
|---|---|---|
| Truth confirmation / proof | `/api/research` returns `NOT_REPRESENTED` for proof/truth questions. Claims remain assertions. | NOT_IMPLEMENTED |
| Automatic candidate → evidence promotion | Discovery routes create `discovery_request`, `discovery_candidate`, `candidate_review`, and jobs only. | INTENTIONALLY_NOT_REPRESENTED |
| Automatic evidence → claim promotion | `/api/v1/evidence` never creates a claim. | INTENTIONALLY_NOT_REPRESENTED |
| Automatic derivation → claim promotion | `/api/v1/derivations` never creates a claim. | INTENTIONALLY_NOT_REPRESENTED |
| Automatic `PROPOSED` → `ACTIVE` identity promotion | `/api/v1/identity-mappings` starts at `PROPOSED`; review route is required. | INTENTIONALLY_NOT_REPRESENTED |
| Person-to-organization membership from co-participation | Phase 37R/37B explicitly preserves co-participation without inferring employment or membership. | INTENTIONALLY_NOT_REPRESENTED |
| Contradiction / superiority / winner inference | Unsupported relation semantics remain `NOT_REPRESENTED`; no general classifier exists. | INTENTIONALLY_NOT_REPRESENTED |
| Source silence inference from missing text | `NULL raw_content` / `NULL quoted_text` are reported as `NOT_STORED_BY_POLICY`, not silence. | INTENTIONALLY_NOT_REPRESENTED |

## 2. Read-only surface boundaries

- Read routes never mutate state; this was verified by automated tests and manual before/after count checks on 2026-08-13.
- Search returns lexical matches only.
- Research is bounded to persisted Berean rows and registered predicate semantics.
- Provenance explanation is structural only.
- Timeline and graph routes assemble persisted claims, projections, and joins; they do not persist new graph knowledge.

Classification: **IMPLEMENTED boundary**, not a missing feature.

## 3. Workflow versus authoritative knowledge

The workflow tables (`corpus`, `research_topic`, `discovery_request`, `discovery_candidate`, `candidate_review`, `asynchronous_job`, `validation_run`, `export_job`, `audit_event`) coordinate work but do not replace authoritative `source`, `dataset`, `source_record`, `citation`, `evidence`, `proposition`, `claim`, `entity_source_mapping`, or `derivation` rows.

Implications:

- corpus/topic/discovery state is not authoritative knowledge;
- audit rows are not evidence;
- validation rows are reproducibility records, not claims;
- queued jobs are not completed ingestion/validation/export outcomes.

Classification: **INTENTIONALLY_NOT_REPRESENTED** as automatic knowledge promotion.

## 4. External retrieval and acquisition limits

There is no HTTP route for:

- arbitrary URL fetch,
- file upload,
- file download from user-supplied locators,
- SQL execution,
- registry mutation.

The repository contains `scripts/acquisition/fetch-stepbible.sh`, but that is an out-of-band shell script, not an API surface.

Classification: **INTENTIONALLY_NOT_REPRESENTED** for the API; **REQUIRES_FUTURE_ARCHITECTURE** if a sandboxed retriever is ever added.

## 5. Worker and durable execution gaps

Implemented queue persistence exists for:

- discovery jobs,
- ingestion jobs,
- validation runs,
- export jobs.

But this repository does not ship a durable SYSTEM worker that:

- dequeues those jobs,
- performs long-running execution,
- persists `validation_result` or `ingestion_result` rows,
- marks jobs `RUNNING` / `COMPLETED` automatically.

Manual verification on 2026-08-13 observed a queued validation job remaining `QUEUED` with zero `validation_result` rows.

Classification: **PARTIALLY_IMPLEMENTED**, **REQUIRES_SYSTEM_WORKER**.

## 6. OpenAPI coverage

`/openapi.json` now documents every implemented route, with request bodies, enums, limits, security, roles, and error
responses. Drift is prevented by `tests/app/openapi-coverage.test.ts`, which fails if a route is added without
documentation or if a documented path has no route.

Classification: **IMPLEMENTED**. See [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md).

## 7. Previously reported discrepancies and their current status

### 7.1 V1 resource-filtered search normalization — FIXED

`GET /api/v1/search/:resource?` now normalizes each supported plural resource explicitly
(`entities`→`entity`, `events`→`event`, `claims`→`claim`, `evidence`→`evidence`, `sources`→`source`,
`datasets`→`dataset`, `source-records`→`source_record`, `citations`→`citation`, `identities`→`source_identity`,
`propositions`→`proposition`).
Unknown filters return `404 NOT_FOUND` instead of silently empty results, and `identity-mappings` returns
`501 NOT_REPRESENTED` because mappings are not part of the search index. Empty result sets are classified `NO_MATCH`,
which is not a denial of existence.

Classification: **IMPLEMENTED**. Evidence: `tests/app/app.test.ts`.

### 7.2 Unsupported admin list resources — FIXED

`GET /api/v1/admin/:resource` validates the resource against the supported list and returns `404 NOT_FOUND` with no
implementation detail. Authentication still runs first, so an unauthenticated request receives `401` and learns
nothing about which resources exist.

Classification: **IMPLEMENTED**. Evidence: `tests/app/app.test.ts`.

### 7.3 Stale `If-Match` returns 409 — INTENTIONAL

Berean issues no `ETag`; `If-Match` carries an opaque integer version, so the request is not a conventional HTTP
entity-tag precondition. Every other write conflict in the API (`IDEMPOTENCY_CONFLICT`, `INVALID_MAPPING_STATE`,
`INVALID_JOB_STATE`, `DUPLICATE`) is `409`, and the version guard executes as `UPDATE ... WHERE version = $2` inside
the same transaction as the audit row, so a stale write commits nothing at all. `409 STALE_VERSION` is therefore the
documented contract and was retained deliberately rather than changed for standards conformity alone.

Classification: **INTENTIONALLY_NOT_REPRESENTED** (as a 412 precondition contract). Evidence: `tests/app/app.test.ts`
asserts that a stale update leaves the name, status, version, and audit-event count unchanged.

### 7.4 Missing-artifact provenance behaviour — INTENTIONAL COMPATIBILITY DIFFERENCE

- `GET /api/v1/provenance/claim/:id` → `404 NOT_FOUND` (the V1 contract).
- `GET /api/provenance/claims/:id` → `200` with `traversal: []` plus explicit `claim_present: false`,
  `classification: "CLAIM_NOT_REPRESENTED"`, and `compatibility` fields, preserving the legacy shape the Explorer depends on
  while stating plainly that absence is not denial.

Classification: **IMPLEMENTED** as a documented, tested divergence. Evidence: `tests/app/app.test.ts`.

## 8. Capability classes by domain concern

| Concern | Current state |
|---|---|
| Read-only exploration of persisted knowledge | IMPLEMENTED |
| Controlled workflow state | IMPLEMENTED |
| Source-backed authoring | IMPLEMENTED |
| Identity proposal and review | IMPLEMENTED + REQUIRES_HUMAN_REVIEW |
| Background execution queue persistence | IMPLEMENTED (queueing) + REQUIRES_SYSTEM_WORKER (execution) |
| Full OpenAPI contract | IMPLEMENTED (drift-tested) |
| Automatic truth / contradiction / causal inference | NOT_IMPLEMENTED / INTENTIONALLY_NOT_REPRESENTED |
| External network acquisition via API | NOT_IMPLEMENTED / REQUIRES_FUTURE_ARCHITECTURE |

## 9. What should deliberately remain non-automatic

The current architecture and tests explicitly argue against turning these into automatic API decisions:

- candidate acceptance as knowledge,
- claim truth,
- scholarly correctness,
- identity certainty without evidence-backed review,
- superiority / victory / causation narratives,
- treating absence or `NOT_REPRESENTED` as falsity.

## 10. Related documents

- [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md) — the distinctions above and where each is enforced.
- [`API_SECURITY_MODEL.md`](./API_SECURITY_MODEL.md) — authentication, roles, transactionality, and audit.
- [`API_CAPABILITY_MATRIX.md`](./API_CAPABILITY_MATRIX.md) — per-route status and the administrative completeness matrix.
- [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md) — OpenAPI coverage status.
