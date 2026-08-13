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

## 6. OpenAPI documentation gap

`/openapi.json` exists, but it omits many implemented routes and almost all request/response schemas, headers, error shapes, and role requirements.

Classification: **PARTIALLY_IMPLEMENTED**. See [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md).

## 7. Current implementation discrepancies (documented, not fixed here)

### 7.1 V1 resource-filtered search pluralization bug

`GET /api/v1/search/:resource?` filters with `result.type === resource.slice(0, -1)`.

Consequences:

- `claims`, `events`, `sources`, `datasets`, `citations`, `evidence` generally work;
- `entities` becomes `entitie` and returns empty results;
- `identities` becomes `identitie` and returns empty results;
- `source-records` becomes `source-record`, which does not match `source_record`;
- `identity-mappings` becomes `identity-mapping`, which matches nothing.

Classification: **PARTIALLY_IMPLEMENTED**.

### 7.2 Unsupported admin list resources return 500

`GET /api/v1/admin/:resource` supports only eight resources, but unsupported values throw `UNSUPPORTED_ADMIN_RESOURCE`, which falls through to the generic `500 internal_error` handler.

Classification: **PARTIALLY_IMPLEMENTED**.

### 7.3 Stale `If-Match` returns 409, not 412

The implementation accepts `If-Match`, but stale updates return `409 STALE_VERSION`. No semantic ETag contract is exposed.

Classification: **PARTIALLY_IMPLEMENTED** relative to a conventional HTTP precondition contract.

### 7.4 Missing-artifact provenance routes are inconsistent

- `/api/provenance/claims/:id` → `200 { traversal: [] }`
- `/api/v1/provenance/claim/:id` → `404 NOT_FOUND`

Classification: **PARTIALLY_IMPLEMENTED** as a uniform contract.

## 8. Capability classes by domain concern

| Concern | Current state |
|---|---|
| Read-only exploration of persisted knowledge | IMPLEMENTED |
| Controlled workflow state | IMPLEMENTED |
| Source-backed authoring | IMPLEMENTED |
| Identity proposal and review | IMPLEMENTED + REQUIRES_HUMAN_REVIEW |
| Background execution queue persistence | PARTIALLY_IMPLEMENTED + REQUIRES_SYSTEM_WORKER |
| Full OpenAPI contract | PARTIALLY_IMPLEMENTED |
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
