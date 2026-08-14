# Project Berean API Developer Guide

## Status, scope, and authoritative references

This guide describes the API **as implemented in code and tests in this repository**. For the authoritative architectural model and workflow boundaries, see:

- [`docs/01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md)
- [`docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md)

Berean exposes two HTTP surfaces:

- **Explorer compatibility surface**: `/api/*` plus `/health`, `/openapi.json`, `/api-docs`, and the Explorer HTML shell.
- **Versioned surface**: `/api/v1/*`, combining bounded read routes with authenticated workflow/authoring routes.

Berean's core distinctions remain mandatory in every route and example:

- Source ≠ Dataset ≠ SourceRecord ≠ Citation ≠ Evidence ≠ Claim ≠ Truth
- Claim ≠ Proposition
- Source Identity ≠ Canonical Entity
- Candidate ≠ Evidence
- `PROPOSED` ≠ `ACTIVE`
- query-derived result ≠ persisted derived claim
- `NOT_REPRESENTED` / `NO_MATCH` ≠ `FALSE`

## Shared implementation facts

### Authentication and roles

Administrative routes use opaque bearer credentials loaded from `BEREAN_API_CREDENTIALS` and validated in `src/auth.ts`.

Implemented roles, in ascending rank:

1. `READER`
2. `RESEARCHER`
3. `CONTENT_EDITOR`
4. `REVIEWER`
5. `ADMINISTRATOR`
6. `SYSTEM`

If no credentials are configured, administrative writes fail closed with `503 AUTH_NOT_CONFIGURED`.

### Headers and envelopes

- JSON body limit: **16 KiB** (`express.json({ limit: '16kb' })`)
- Security headers: `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`
- `X-Powered-By` is disabled.
- Administrative routes always return `X-Correlation-Id`; supplied UUIDs are echoed, otherwise a new UUID is generated.
- `401` responses set `WWW-Authenticate: Bearer`.
- `PATCH /api/v1/corpora/:id` accepts `If-Match: <integer version>`.
- Job-queueing routes require `Idempotency-Key`.

### Important typing detail

`pg` returns PostgreSQL `BIGINT` values as JSON strings. Examples: `"claim_id":"348"`, `"job_id":"4"`. PostgreSQL `INTEGER` values remain JSON numbers, for example `"version":2`.

### Error shapes

Explorer compatibility routes use:

```json
{ "error": "..." }
```

or on unhandled failures:

```json
{ "error": "internal_error", "message": "The request could not be completed." }
```

`/api/v1/*` uses:

```json
{ "error": { "code": "...", "message": "..." } }
```

### Transactions, audit, idempotency, concurrency

All implemented administrative mutations run inside a PostgreSQL transaction in `src/administration/repository.ts`.

- Successful mutations append one `audit_event` row in the **same transaction**.
- `audit_event` and `validation_result` are database-immutable via triggers.
- Job idempotency is scoped to **(requested_by_actor_id, job_type, idempotency_key)**.
- Reusing the same idempotency key with the same fingerprint replays the existing job.
- Reusing the same key with a different fingerprint returns `409 IDEMPOTENCY_CONFLICT`.
- Corpus optimistic concurrency uses integer `If-Match`; stale updates return `409 STALE_VERSION`.
- The implementation does **not** emit a resource-version `ETag`. Any Express-generated `ETag` header is generic response hashing, not concurrency metadata.

### Worker boundary

`POST /api/v1/discovery-requests`, `/ingestion-jobs`, `/validation-runs`, and `/export-jobs` persist queue state, but this repository ships **no in-process durable worker**. Manual verification on 2026-08-13 showed queued validation jobs remaining `QUEUED` with zero `validation_result` rows until a separate worker acts.

## Route inventory

### Non-versioned and Explorer compatibility routes

| Method | Path | Auth | Actual behavior | Tests / evidence |
|---|---|---|---|---|
| GET | `/health` | none | Returns `{status:"ok",mode:"read-only"}`; no DB access. | `tests/app/app.test.ts` |
| GET | `/openapi.json` | none | Returns the complete OpenAPI 3.1 document built in `src/api/openapi.ts`. Coverage is enforced by `tests/app/openapi-coverage.test.ts`. | `tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts` |
| GET | `/api-docs` | none | Minimal HTML page linking to `/openapi.json`; not Swagger UI. | code-traced |
| GET | `/api/research/scope` | none | Lists persisted sources, datasets, and inventory counts. Read-only. | `tests/app/app.test.ts`, manual 2026-08-13 |
| POST | `/api/research` | none | Bounded read-only research over persisted data only. Never persists a plan or answer. | `tests/app/app.test.ts`, manual 2026-08-13 |
| GET | `/api/search` | none | Keyword search across represented records. `MATCHED` search hits are not evidence. | `tests/app/app.test.ts`, manual 2026-08-13 |
| GET | `/api/entities/:entityId` | none | Entity detail: entity + source mappings + claims + events + related entities. | `tests/app/app.test.ts` |
| GET | `/api/claims/:claimId` | none | Claim detail: claim + proposition + evidence + claim relations + derivation metadata. | `tests/app/app.test.ts` |
| GET | `/api/propositions/:propositionId` | none | Proposition detail + all claims asserting it. | `tests/app/app.test.ts` |
| GET | `/api/events/:eventId` | none | Event detail + projected participation + connected claims. | `tests/app/app.test.ts` |
| GET | `/api/sources` | none | Lists all sources with dataset and source-record counts. | code-traced |
| GET | `/api/sources/:sourceId` | none | Source detail + datasets + up to 200 source records. | code-traced |
| GET | `/api/provenance/claims/:claimId` | none | Raw traversal rows for a claim. Intentional compatibility behavior: a missing claim returns `200` with `traversal: []` plus `claim_present:false` and `classification:"CLAIM_NOT_REPRESENTED"`. | `tests/app/app.test.ts` |
| GET | `/api/provenance/explain` | none | Deterministic structural provenance explanation for `claim_id` or `proposition_id`. | `tests/app/app.test.ts` |
| GET | `/api/derivations/check-eligibility` | none | Structural derivation-eligibility check only. Read-only. | `tests/app/app.test.ts` |
| GET | `/api/exploration/timeline` | none | Entity-centered timeline / coverage / source comparison assembly. Read-only. | `tests/app/app.test.ts` |
| GET | `/api/genesis/coverage` | none | Genesis-locator coverage dashboard. Read-only. | `tests/app/app.test.ts` |
| GET | `/api/dashboard/quality` | none | Current structural totals, claim-type distribution, contradiction count, mapping status. | code-traced |
| GET | `/api/graph` | none | Bounded graph neighborhood for `nodeType=entity|claim`. Read-only. | `tests/app/app.test.ts` |
| ALL | `/api/*` (unmatched) | none | Any `/api` path that matches no compatibility or versioned route returns `404 {"error":"route not found"}` as JSON, never the HTML shell. | `tests/app/app.test.ts` |
| GET | `*` (non-`/api`) | none | Returns Explorer HTML shell. | `tests/app/app.test.ts` |

### Versioned read routes

| Method | Path | Auth | Actual behavior | Tests / evidence |
|---|---|---|---|---|
| GET | `/api/v1/health` | none | `{status:"ok",api_version:"v1",mode:"read-only"}` | `tests/app/app.test.ts` |
| GET | `/api/v1/capabilities` | none | Lists implemented high-level capabilities and two `NOT_REPRESENTED` limitations. | `tests/app/app.test.ts` |
| GET | `/api/v1/schema` | none | Returns authoritative-chain / projection / workflow-boundary summary. | code-traced |
| GET | `/api/v1/registry/:registry` | none | Supported registries: `predicates`, `entity-types`, `event-types`, `claim-types`, `evidence-types`, `mapping-statuses`. `/capabilities` 307-redirects to `/api/v1/capabilities`. | manual 2026-08-13 |
| GET | `/api/v1/search/:resource?` | none | Same search engine as `/api/search`. Plural resource segments are normalized explicitly; unknown filters return `404 NOT_FOUND`, `identity-mappings` returns `501 NOT_REPRESENTED`, and empty results are classified `NO_MATCH`. | `tests/app/app.test.ts` |
| POST | `/api/v1/research` | none | Same bounded research behavior as `/api/research`, V1 envelope. | code-traced |
| GET | `/api/v1/research/capabilities` | none | Returns supported research classifications. | code-traced |
| GET | `/api/v1/provenance/claim/:id` | none | V1 claim provenance explanation. Missing claim returns `404 NOT_FOUND`. | `tests/app/app.test.ts` |
| GET | `/api/v1/graph/entity/:id` | none | Entity neighborhood graph only. | code-traced |
| GET | `/api/v1/:resource/:id` | none | Supported resources: `entities`, `events`, `claims`, `evidence`, `sources`, `datasets`, `source-records`, `citations`, `identities`, `identity-mappings`. Rich detail only for `entities`, `events`, `claims`, `sources`; others are direct table reads. | `tests/app/app.test.ts`, code-traced |
| GET | `/api/v1/:resource` | none | Lists the same supported resources, `limit=1..100`, default 50. | `tests/app/app.test.ts`, code-traced |
| any | unmatched `/api/v1/*` | none | Usually `501 NOT_REPRESENTED`; generic one- or two-segment resource patterns can instead return `404 NOT_FOUND` because they match `/:resource` or `/:resource/:id` first. | manual 2026-08-13 |

## Read-route request validation and notable behaviors

### `/api/research/scope`

Response shape:

```json
{
  "sources": [{ "source_id": "12", "source_key": "1EN_ETH", "name": "1 Enoch, Ethiopic textual tradition", "source_type_code": "HISTORICAL_WORK", "dataset_count": 1 }],
  "datasets": [{ "dataset_id": "32", "dataset_key": "ELECTRICAL_INDUSTRIES_P37R", "source_record_count": 2, "evidence_count": 2, "claim_count": 4 }],
  "inventory": { "entities": 142, "events": 112, "claims": 348, "evidence": 182, "sources": 31, "datasets": 33 }
}
```

DB reads: `source`, `dataset`, `source_record`, `evidence`, `claim_evidence`, `claim`.

### `/api/research` and `/api/v1/research`

Request body:

```json
{ "question": "Who participates in the Opening Day event and where does it occur?", "datasetIds": [31, 32] }
```

Validation:

- `question`: required non-empty string, trimmed, max 1000 chars
- `datasetIds`: optional array of at most 100 positive integers; duplicates are removed

Actual research behaviors:

- Questions containing `prove|proved|true|truth|confirm*` return `capability: "NOT_REPRESENTED"`.
- Subject resolution now runs before claim retrieval:
  - one resolved represented subject (`entity` or `event`) → subject-bound retrieval only;
  - multiple plausible subjects → `capability: "UNRESOLVED"` with no promoted answer rows;
  - unresolved source identity (no single `ACTIVE` mapping) → `capability: "UNRESOLVED"`;
  - no represented subject → `capability: "NOT_REPRESENTED"` (non-denial).
- Participation questions use predicates whose registry row has `event_participation_role_code`.
- Other questions match registered `predicate_code` or `predicate.description`.
- Predicate matches that are not subject-relevant are excluded.
- Results remain bounded to 50 rows and now expose:
  - `bounded.total_matched`
  - `bounded.returned`
  - `bounded.truncated`
  - deterministic `bounded.order`.
- Scope is always `BEREAN_ONLY`; no external retrieval happens.
- `NO_MATCH` means no persisted claim in the selected scope matched the registered predicate set.

Manual example (2026-08-13):

```json
{
  "capability": "ESTABLISHED",
  "plan": {
    "classification": "PARTICIPATION",
    "subject_resolution": { "status": "RESOLVED", "resolved_kind": "ENTITY" },
    "scope": { "dataset_ids": [], "retrieval_scope": "BEREAN_ONLY" },
    "candidate_predicates": ["builderIn", "childIn", "parentIn", "participatesIn", "subjectOf"],
    "traversal_shape": "SUBJECT_BOUND_EVENT_PARTICIPATION",
    "provenance_requirement": "FULL_CHAIN"
  },
  "bounded": {
    "total_matched": 2,
    "returned": 2,
    "truncated": false,
    "limit": 50,
    "order": ["claim_id", "claim_evidence_id", "dataset_id", "source_key"]
  },
  "results": [
    {
      "claim_key": "CLAIM_SETH_CHILD_SETH_BEGETTING",
      "predicate": "childIn",
      "dataset_key": "GEN_MT_REF",
      "classification": "DIRECTLY_SUPPORTED"
    }
  ]
}
```

Failure example (`NO_MATCH`, manual 2026-08-13):

```json
{
  "capability": "NO_MATCH",
  "results": [],
  "limitation": "No matching persisted claims were found in the selected scope."
}
```

### `/api/search` and `/api/v1/search/:resource?`

Validation:

- `q`: required, trimmed, max 200 chars
- compatibility `limit`: positive integer, default 20, effective max 50
- V1 `limit`: positive integer 1..100, default 50

Searches: `entity`, `event`, `claim`, `proposition`, `evidence`, `source`, `dataset`, `source_record`, `citation`, `source_identity`.

Manual example (`GET /api/search?q=Nikola%20Tesla&limit=5`):

```json
{
  "query": "Nikola Tesla",
  "results": [
    { "type": "citation", "key": "CITE_P37R_DIRECTORY_TESLA", "label": "Official Directory (1893), classified exhibitor entry for Nikola Tesla" },
    { "type": "claim", "key": "CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT", "detail": "DIRECT_SOURCE_CLAIM" },
    { "type": "entity", "key": "phase37r_nikola_tesla", "label": "Nikola Tesla", "detail": "PERSON" }
  ]
}
```

#### V1 resource filter normalization

`GET /api/v1/search/:resource` normalizes the plural route segment explicitly. No string truncation is used.

| Route segment | Search result type |
|---|---|
| `entities` | `entity` |
| `events` | `event` |
| `claims` | `claim` |
| `propositions` | `proposition` |
| `evidence` | `evidence` |
| `sources` | `source` |
| `datasets` | `dataset` |
| `source-records` | `source_record` |
| `citations` | `citation` |
| `identities` | `source_identity` |

Controlled errors replace silently empty results:

- an unsupported filter (for example `/api/v1/search/not-a-resource` or the singular `/api/v1/search/entity`) returns `404 NOT_FOUND` listing the supported filters;
- `identity-mappings` is a supported persisted resource that keyword search does not index, so it returns `501 NOT_REPRESENTED` and points at `GET /api/v1/identity-mappings`;
- a legitimate empty result set returns `200` with `classification:"NO_MATCH"` and an explicit statement that `NO_MATCH` is not a denial.

Response example (`GET /api/v1/search/entities?q=adam&limit=100`):

```json
{
  "query": "adam",
  "resource": "entities",
  "resource_type": "entity",
  "results": [{ "type": "entity", "id": 1, "key": "adam", "label": "Adam", "detail": "PERSON" }],
  "classification": "MATCHED",
  "limitation": "Matched records are lexical search hits, not established claims."
}
```

`limit` is applied by the search query **before** the resource filter is applied to the returned rows,
so a small `limit` on a filtered search can report `NO_MATCH` while a matching persisted record exists
further down the unfiltered result set (verified 2026-08-14: `?q=adam&limit=3` returns `NO_MATCH`,
`?q=adam&limit=100` returns the `adam` entity). Use a high `limit` for filtered searches. This behavior
is recorded as finding F-01 in
[`../07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](../07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md);
it does not change the documented meaning of `NO_MATCH`, which remains "no persisted record matched",
never "false".

### Entity / claim / proposition / event / source detail routes

Validation:

- compatibility routes accept any integer-looking path parsed by `parseInt`; invalid text gives `400`
- V1 detail routes require positive safe integers

Important distinctions:

- `/api/entities/:id` and `/api/v1/entities/:id` return **entity-centered joined detail**.
- `/api/propositions/:id` returns **proposition + all claims**.
- `/api/events/:id` uses projected `event_participation`, not a second participant store.
- `/api/sources/:id` returns up to **200** source records.

### Provenance routes

- `/api/provenance/explain` and `/api/v1/provenance/claim/:id` perform structured explanation and **do 404** when the target does not exist.
- `/api/provenance/explain` requires **exactly one** of `claim_id` or `proposition_id`.
- `/api/provenance/claims/:claimId` is a compatibility route that keeps its `200` shape because the Explorer interface depends on it.

#### Intentional compatibility difference for missing claims

`GET /api/v1/provenance/claim/999999999`:

```json
{ "error": { "code": "NOT_FOUND", "message": "Claim was not found." } }
```

`GET /api/provenance/claims/999999999`:

```json
{
  "claimId": 999999999,
  "claim_present": false,
  "classification": "CLAIM_NOT_REPRESENTED",
  "compatibility": "A claim that is not represented returns 200 with an empty traversal on this legacy route. GET /api/v1/provenance/claim/{id} returns 404 NOT_FOUND instead.",
  "traversal": []
}
```

A represented claim returns `classification:"PROVENANCE_TRAVERSAL_REPRESENTED"`. Because the traversal starts `FROM claim`, an empty traversal can only mean "claim not represented", so the classification removes the ambiguity between an absent claim and a claim without evidence. Both behaviors are asserted in `tests/app/app.test.ts`, which prevents accidental divergence.

**Use `/api/v1/provenance/claim/:id` for new integrations.**

### `/api/derivations/check-eligibility`

Validation: `derivation_id` must be one positive integer.

Returns structural checks such as:

- `DERIVATION_EXISTS`
- `DERIVED_CLAIM_EXISTS`
- `DERIVATION_INPUT_EXISTS`
- `INPUT_PROVENANCE_STRUCTURALLY_COMPLETE`
- `SELF_INPUT_ABSENT`
- `TARGET_PREDICATE_VALID`

It never decides entailment, truth, or adequacy of method.

### `/api/exploration/timeline`

Validation:

- exactly one of `entity_id` or `entity_key`
- `entity_id`: positive integer
- `entity_key`: non-empty string

Returns:

- `entity`
- `coverage`
- `entity_source_mappings`
- ordered `timeline`
- `entity_claims_without_event`
- `source_comparison`
- `stored_claim_relations`
- `limitations`

Manual example (`ark_of_covenant`, truncated):

```json
{
  "operation": "EXPLORE_TIMELINE",
  "entity": { "entity_key": "ark_of_covenant", "entity_type_code": "OBJECT" },
  "coverage": { "coverage_status": "EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED", "provenance_status": "COMPLETE_SOURCE_CHAIN" },
  "timeline": [
    {
      "record_type": "RELATED_EVENT",
      "event": { "event_key": "ark_covenant_instruction", "event_type_code": "INSTRUCTION" },
      "claims": [{ "record_type": "STORED_CLAIM", "claim": { "statement_role": "DISPLAY_METADATA_ONLY" } }],
      "projected_event_participation": [{ "projection": "PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION" }]
    }
  ]
}
```

## Administrative read route

### `GET /api/v1/admin/:resource`

Auth: `READER` or higher.

Supported resources and backing queries:

- `corpora` → `SELECT * FROM corpus ...`
- `topics` → `research_topic`
- `discoveries` → `discovery_request`
- `candidates` → `discovery_candidate`
- `jobs` → `asynchronous_job`
- `validations` → `validation_run`
- `audits` → `audit_event`
- `exports` → `export_job`

Validation: `limit` must be integer 1..100, default 50.

Unsupported resources (for example `GET /api/v1/admin/not-real`) return a structured `404 NOT_FOUND` listing the supported resources. Authentication is still evaluated first, so an unauthenticated request returns `401` and never discloses which administrative resources exist. The internal `UNSUPPORTED_ADMIN_RESOURCE` marker is also mapped to `404` in the administration error handler, so no code path can produce `500 internal_error` for an unknown resource.

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Administrative resource was not found. Supported resources: corpora, topics, discoveries, candidates, jobs, validations, audits, exports."
  }
}
```

## Administrative write routes

Every route below:

- requires bearer auth and minimum role shown,
- runs in one DB transaction,
- writes one `audit_event` row on success,
- returns PostgreSQL rows from `RETURNING *`,
- does **not** perform background processing inside this process.

### 1. Corpora

#### `POST /api/v1/corpora`

Minimum role: `ADMINISTRATOR`

Body:

- `key`: required, max 120, regex `^[A-Za-z0-9][A-Za-z0-9_.:-]*$`
- `name`: required, max 300
- `description`: optional, max 2000
- `scopeNote`: required, max 4000

Writes: `workflow_actor` upsert, `corpus`, `audit_event(action='CREATE', resource_type='corpus')`

Response: raw `corpus` row.

Manual success example:

```http
POST /api/v1/corpora
Authorization: <bearer token>
Content-Type: application/json
X-Correlation-Id: 11111111-1111-1111-1111-111111111111
```

```json
{ "key": "doc-wce", "name": "Documentation WCE Corpus", "scopeNote": "Bounded to documentation examples." }
```

```json
{
  "corpus_id": "1",
  "corpus_key": "doc-wce",
  "name": "Documentation WCE Corpus",
  "scope_note": "Bounded to documentation examples.",
  "status": "DRAFT",
  "version": 1
}
```

Failure examples:

- missing token → `401 UNAUTHENTICATED`
- invalid token → `401 UNAUTHENTICATED`
- reader token → `403 FORBIDDEN`
- credentials absent → `503 AUTH_NOT_CONFIGURED`

#### `PATCH /api/v1/corpora/:id`

Minimum role: `ADMINISTRATOR`

Headers:

- `If-Match`: required positive integer current version

Body (all optional):

- `name` max 300
- `description` max 2000
- `scopeNote` max 4000
- `status` in `DRAFT | ACTIVE | ARCHIVED`

Writes: `corpus.version = version + 1`, `updated_at`, `audit_event(action='UPDATE')`

Success example (manual 2026-08-13):

```json
{ "corpus_id": "1", "status": "ACTIVE", "version": 2, "description": "Activated for documentation examples." }
```

Stale example (actual implementation):

```json
{
  "error": {
    "code": "STALE_VERSION",
    "message": "The corpus version is stale or the corpus does not exist."
  }
}
```

> **The 409 status is the intended Berean contract, not an oversight.** `If-Match` carries the opaque integer `version`
> counter returned by the previous write; Berean issues no entity tag, so no HTTP precondition contract is claimed.
> Every Berean write conflict — `STALE_VERSION`, `IDEMPOTENCY_CONFLICT`, `INVALID_MAPPING_STATE`, `INVALID_JOB_STATE`,
> and `DUPLICATE` — is reported as `409` so integrators can handle conflicts uniformly.
>
> The update and its audit row share one transaction and the version guard is in the `UPDATE ... WHERE version = $2`
> predicate, so a stale write commits nothing: `tests/app/app.test.ts` asserts that after a stale `PATCH` the corpus name,
> status, version, and `audit_event` count are all unchanged. A missing or non-numeric `If-Match` is rejected with
> `400 INVALID_REQUEST` before any write is attempted.

### 2. Research topics and discovery workflow

#### `POST /api/v1/research-topics`

Minimum role: `RESEARCHER`

Body:

- `corpusId`: positive integer
- `key`: identifier pattern
- `question`: required, max 2000
- `scopeNote`: required, max 4000

Writes: `research_topic`, audit `CREATE research_topic`

#### `POST /api/v1/discovery-requests`

Minimum role: `RESEARCHER`

Headers:

- `Idempotency-Key`: required identifier pattern

Body:

- `corpusId`: positive integer
- `researchTopicId`: optional positive integer
- `requestKind`: `SOURCE_DISCOVERY | CANDIDATE_DISCOVERY | GAP_DISCOVERY`
- `queryText`: required, max 2000
- `boundedScope`: required, max 4000
- `requestedTypes`: array, max 10, values from `PERSON | ORGANIZATION | PLACE | EVENT | DOCUMENT | TECHNOLOGY | CONCEPT | RELATIONSHIP | SOURCE_IDENTITY | SOURCE`

Writes:

- `asynchronous_job(job_type='DISCOVERY', status='QUEUED')`
- `discovery_request`
- audit `REQUEST discovery_request`

Idempotency: fingerprint includes the validated request body plus `idempotencyKey`.

Manual example:

```http
POST /api/v1/discovery-requests
Authorization: <bearer token>
Idempotency-Key: doc-discovery-1
Content-Type: application/json
```

```json
{
  "corpusId": 1,
  "researchTopicId": 1,
  "requestKind": "CANDIDATE_DISCOVERY",
  "queryText": "Discover electrical people and relationship candidates from the bounded directory.",
  "boundedScope": "Official directory and contemporaneous electrical sources only.",
  "requestedTypes": ["PERSON", "RELATIONSHIP"]
}
```

```json
{
  "discovery_request_id": "1",
  "request_kind": "CANDIDATE_DISCOVERY",
  "requested_types": ["PERSON", "RELATIONSHIP"],
  "job": {
    "job_id": "1",
    "job_type": "DISCOVERY",
    "status": "QUEUED",
    "idempotency_key": "doc-discovery-1"
  }
}
```

Replay with identical body returns `202` and the same `job_id`. Reuse with a different body returns `409 IDEMPOTENCY_CONFLICT`.

#### `POST /api/v1/discovery-requests/:id/candidates`

Minimum role: `RESEARCHER`

Body:

- `key`: identifier pattern
- `type`: candidate type enum above
- `label`: required, max 500
- `description`: optional, max 2000
- `representationStatus`: optional `UNREVIEWED | REPRESENTABLE | NOT_REPRESENTED | DUPLICATE | EXCLUDED`
- `obstacleClassification`: optional `QUERY | DATA_ENTRY | REGISTRY_EXPRESSIVENESS | DOMAIN_SCOPING_LIMITATION | ARCHITECTURAL_DEFICIENCY`
- `proposedPredicate`: optional, max 120; **required by DB check for `RELATIONSHIP` rows**
- `discoveryLocator`: required, max 2000

Writes: `discovery_candidate`, audit `DISCOVER discovery_candidate`

Special behavior: if `proposedPredicate` is supplied but is not in `predicate`, the repository overwrites the row to `representation_status='NOT_REPRESENTED'` and `obstacle_classification='REGISTRY_EXPRESSIVENESS'` before insert.

Manual example (`wonTechnologyConflict` is not registered):

```json
{
  "discovery_candidate_id": "1",
  "representation_status": "NOT_REPRESENTED",
  "obstacle_classification": "REGISTRY_EXPRESSIVENESS",
  "proposed_predicate": "wonTechnologyConflict"
}
```

This route writes **no** `evidence`, `claim`, `proposition`, or `entity` rows.

#### `POST /api/v1/candidates/:id/review`

Minimum role: `REVIEWER`

Body:

- `decision`: `APPROVED | REJECTED | NEEDS_SOURCE_VERIFICATION | NOT_REPRESENTED`
- `rationale`: required, max 4000

Writes:

- upsert `candidate_review`
- updates `discovery_candidate.representation_status`:
  - `APPROVED -> REPRESENTABLE`
  - `REJECTED -> EXCLUDED`
  - `NOT_REPRESENTED -> NOT_REPRESENTED`
  - `NEEDS_SOURCE_VERIFICATION` leaves current status unchanged
- audit `REVIEW discovery_candidate`

This still does **not** create `evidence` or `claim` rows.

### 3. Source registration and source-backed authoring

#### `POST /api/v1/source-registrations`

Minimum role: `CONTENT_EDITOR`

Body:

- `corpusId`: positive integer
- `sourceKey`, `datasetKey`: identifier pattern
- `sourceName`, `datasetName`: required, max 500
- `sourceType`: identifier pattern; DB FK must match `source_type`
- `description`: optional
- `editionLabel`: optional
- `version`: optional, max 200
- `licenseStatus`: required, max 500
- `acquisitionMethod`: required, max 500

Writes:

- `source` (`ON CONFLICT (source_key) DO UPDATE SET name = EXCLUDED.name`)
- `dataset` (`ON CONFLICT (dataset_key) DO UPDATE SET license_status = EXCLUDED.license_status`)
- `corpus_dataset` (`ON CONFLICT DO NOTHING`)
- audit `REGISTER source`

Response shape:

```json
{
  "source": { "source_id": "33", "source_key": "doc-source", "source_type_code": "HISTORICAL_WORK" },
  "dataset": { "dataset_id": "33", "dataset_key": "doc-dataset", "license_status": "LOCATOR_ONLY" }
}
```

#### `POST /api/v1/source-records`

Minimum role: `CONTENT_EDITOR`

Body:

- `datasetId`: positive integer
- `key`: identifier pattern
- `sourceLocation`: required, max 2000
- `rawContent`: optional, max 10000
- `contentHash`: required when `rawContent` is supplied; when present, must be lowercase 64-char SHA-256 hex
- `revisionLabel`: optional, max 200
- `citationKey`: identifier pattern
- `locator`: required, max 2000
- `quotedText`: optional, max 10000

Writes:

- `source_record` (`ON CONFLICT (dataset_id, source_record_key) DO UPDATE SET source_record_key = EXCLUDED.source_record_key`)
- `citation` (`ON CONFLICT (citation_key) DO UPDATE SET locator = EXCLUDED.locator`)
- audit `REGISTER source_record`

Response shape:

```json
{
  "sourceRecord": { "source_record_id": "169", "source_record_key": "doc-record", "source_location": "Example locator 1", "content_hash": null },
  "citation": { "citation_id": "169", "citation_key": "doc-citation", "locator": "Example locator 1", "quoted_text": null }
}
```

#### `POST /api/v1/evidence`

Minimum role: `CONTENT_EDITOR`

Body:

- `key`: identifier pattern
- `sourceRecordId`: positive integer
- `observation`: required, max 10000
- `evidenceType`: `SOURCE_OBSERVATION | ANALYTICAL_OBSERVATION`
- `notes`: optional, max 4000
- `citationIds`: array of 1..100 positive integers

Writes:

- `evidence`
- one `evidence_citation` row per citation id
- audit `CREATE evidence`

Important boundary: creating evidence does **not** create a claim.

#### `POST /api/v1/claims`

Minimum role: `REVIEWER`

Body:

- `key`: identifier pattern
- `predicate`: identifier pattern; DB FK must match registered predicate/term kinds
- exactly one of `subjectEntityId` or `subjectEventId`
- exactly one of `objectEntityId`, `objectEventId`, or `objectTypedValueId`
- `claimType`: `DIRECT_SOURCE_CLAIM | INTERPRETIVE_CLAIM | DERIVED_CLAIM`
- `status`: optional `ACTIVE | UNDER_REVIEW`, defaults `UNDER_REVIEW`
- `statement`, `notes`: optional, max 4000
- `derivationId`: required only for `DERIVED_CLAIM`; forbidden otherwise
- `evidenceIds`: array of 1..100 positive integers
- `evidenceRelation`: optional `SUPPORTS | CONTRADICTS | QUALIFIES`, defaults `SUPPORTS`

Writes:

- `proposition`
- `claim`
- one `claim_evidence` row per `evidenceId`
- audit `AUTHOR claim`

Critical validation rules:

- Non-derived claims require every supplied evidence row to be `SOURCE_OBSERVATION` **and** cited.
- Derived claims require an existing `derivation` row with at least one `derivation_input`.
- Analytical evidence is not auto-promoted into direct or interpretive claims.

Manual success example:

```json
{
  "claim": { "claim_id": "348", "claim_key": "doc-direct-claim", "claim_type_code": "DIRECT_SOURCE_CLAIM", "claim_status_code": "UNDER_REVIEW" },
  "proposition": { "proposition_id": "336", "predicate": "fatherOf", "subject_entity_id": "1", "object_entity_id": "2" }
}
```

Manual failure example (`ANALYTICAL_OBSERVATION` evidence):

```json
{
  "error": {
    "code": "DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION",
    "message": "Direct and interpretive claims require cited SOURCE_OBSERVATION evidence; analytical observations are not promoted automatically."
  }
}
```

Manual counts before/after that failure were unchanged (`claim_count 348 -> 348`, `proposition_count 336 -> 336`), confirming rollback/no partial commit.

### 4. Identity reconciliation

#### `POST /api/v1/identity-mappings`

Minimum role: `CONTENT_EDITOR`

Body:

- `sourceIdentityId`: positive integer
- `entityId`: positive integer
- `confidence`: number in `[0,1]`
- `justification`: required, max 4000
- `notes`: optional, max 4000
- `supportingEvidenceId`: positive integer

Writes:

- `entity_source_mapping(mapping_status_code='PROPOSED')`
- audit `PROPOSE entity_source_mapping`

Validation: supporting evidence must come from the same source as the source identity, else `422 IDENTITY_EVIDENCE_SOURCE_MISMATCH`.

Manual example:

```json
{ "entity_source_mapping_id": "101", "mapping_status_code": "PROPOSED", "supporting_evidence_id": "1" }
```

#### `POST /api/v1/identity-mappings/:id/review`

Minimum role: `REVIEWER`

Body:

- `status`: `ACTIVE | REJECTED`
- `rationale`: required, max 4000

Writes:

- updates only `PROPOSED` mappings
- appends rationale text into `notes`
- audit `REVIEW entity_source_mapping`

If the mapping is not currently `PROPOSED`, returns `409 INVALID_MAPPING_STATE`.

### 5. Derivations

#### `POST /api/v1/derivations`

Minimum role: `RESEARCHER`

Body:

- `method`: required, max 4000
- `assumptions`: required, max 4000
- `inputs`: array of 1..100 objects; each must contain exactly one of `claimId` or `evidenceId`; optional `notes`

Writes:

- `derivation`
- `derivation_input` rows
- audit `CREATE derivation`

Boundary: this route creates **no claim automatically**.

### 6. Jobs and job control

#### `POST /api/v1/ingestion-jobs`

Minimum role: `CONTENT_EDITOR`

Headers: `Idempotency-Key` required

Body:

- `corpusId`: optional positive integer
- `sourceId`: optional positive integer
- `candidateId`: optional positive integer
- `transactionPolicy`: optional `ATOMIC | SAVEPOINT_PER_ITEM`, default `ATOMIC`
- `partialFailurePolicy`: optional `ROLLBACK_ALL | RETAIN_SUCCESSES`, default `ROLLBACK_ALL`

Writes:

- `asynchronous_job(job_type='INGESTION')`
- `ingestion_job`
- audit `QUEUE ingestion_job`

#### `POST /api/v1/validation-runs`

Minimum role: `REVIEWER`

Headers: `Idempotency-Key` required

Body:

- `corpusId`: optional positive integer
- `validationTypes`: non-empty array of `SCHEMA | PROVENANCE | REGISTRY | IDENTITY | CLAIM | EVIDENCE | DERIVATION | CORPUS | REPLAY | READ_ONLY | NEGATIVE_SEMANTIC`

Writes:

- `asynchronous_job(job_type='VALIDATION')`
- `validation_run`
- audit `QUEUE validation_job`

Manual queue example:

```json
{ "job_id": "4", "job_type": "VALIDATION", "status": "QUEUED", "idempotency_key": "doc-validation-1" }
```

Manual worker-boundary evidence:

```json
{ "validation_run_id": "1", "status": "QUEUED", "result_count": 0 }
```

#### `POST /api/v1/export-jobs`

Minimum role: `ADMINISTRATOR`

Headers: `Idempotency-Key` required

Body:

- `corpusId`: positive integer when supplied to the validator
- `format`: `JSONL | CSV`
- `includeRawContent`: boolean, defaults false
- `reproducibilityNote`: required, max 4000

Writes:

- `asynchronous_job(job_type='EXPORT')`
- `export_job`
- audit `QUEUE export_job`

#### `POST /api/v1/jobs/:id/cancel`

Minimum role: `CONTENT_EDITOR`, plus ownership / elevated-role checks

Behavior:

- export jobs require `ADMINISTRATOR`
- validation jobs require `REVIEWER`
- ingestion/discovery jobs require `CONTENT_EDITOR`
- non-owner actors may act only if they are `ADMINISTRATOR` or `SYSTEM`
- valid source states: `QUEUED | RUNNING | WAITING_FOR_REVIEW`

Writes: updates `asynchronous_job` to `CANCELLED`, sets cancel/completed timestamps, audit `CANCEL asynchronous_job`

#### `POST /api/v1/jobs/:id/retry`

Minimum role and ownership rules: same as cancel.

Valid source states: `FAILED | CANCELLED`

Writes: updates `asynchronous_job` to `QUEUED`, increments `attempt_count`, clears error fields, audit `RETRY asynchronous_job`

Manual examples:

```json
{ "job_id": "4", "status": "CANCELLED", "cancel_requested_at": "2026-08-13T19:32:57.463Z", "completed_at": "2026-08-13T19:32:57.463Z" }
```

```json
{ "job_id": "4", "status": "QUEUED", "attempt_count": 1 }
```

## Failure examples

### Missing bearer token

```json
{
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "A bearer credential is required."
  }
}
```

### Invalid bearer token

```json
{
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "The bearer credential is invalid."
  }
}
```

### Role failure

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "ADMINISTRATOR role or higher is required."
  }
}
```

### Validation failure (bad search / research / headers)

Examples:

- `/api/search?q=<201 chars>` → `400`
- `/api/research` with non-integer dataset ids → `400`
- `PATCH /api/v1/corpora/:id` without numeric `If-Match` → `400 INVALID_REQUEST`
- `/api/v1/evidence` with empty `citationIds` → `400 INVALID_REQUEST`

### Idempotency replay and conflict

Replay: same actor + same job type + same `Idempotency-Key` + same validated request body → same `job_id`, still `202`.

Conflict:

```json
{
  "error": {
    "code": "IDEMPOTENCY_CONFLICT",
    "message": "The idempotency key was already used with a different request."
  }
}
```

### Stale optimistic concurrency

Actual implementation:

```json
{
  "error": {
    "code": "STALE_VERSION",
    "message": "The corpus version is stale or the corpus does not exist."
  }
}
```

Status: `409`.

### Not represented

Manual 2026-08-13 examples:

```json
DELETE /api/v1/entities/1
{
  "error": {
    "code": "NOT_REPRESENTED",
    "message": "DELETE /api/v1/entities/1 requires workflow or mutation structures not represented by the current Berean schema."
  }
}
```

```json
POST /api/research { "question": "Did an observation prove a theory?" }
{
  "capability": "NOT_REPRESENTED",
  "results": []
}
```

## Current implementation notes and discrepancies

1. **V1 resource-filtered search — FIXED.** Plural segments are normalized explicitly; unknown filters return `404`, unindexed resources return `501 NOT_REPRESENTED`, and empty results are `NO_MATCH`.
2. **Unsupported admin list resources — FIXED.** They return a structured `404 NOT_FOUND` with no implementation leakage.
3. **Corpus concurrency returns 409, not 412 — INTENTIONAL AND DOCUMENTED.** `If-Match` carries an opaque version counter, no `ETag` is issued, and every Berean conflict uses `409`. Stale writes commit nothing.
4. **`/api/provenance/claims/:id` versus `/api/v1/provenance/claim/:id` — INTENTIONAL COMPATIBILITY DIFFERENCE.** The legacy route keeps `200` with an empty traversal for the Explorer and now reports `classification:"CLAIM_NOT_REPRESENTED"`; the versioned route returns `404`. Both are tested.
5. **OpenAPI — COMPLETE for the implemented surface.** `tests/app/openapi-coverage.test.ts` fails if a route is implemented but undocumented or documented but not implemented. See [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md).

## Cross-references

- Exhaustive route-by-route matrix: [`API_CAPABILITY_MATRIX.md`](./API_CAPABILITY_MATRIX.md)
- Workflow and composition recipes: [`API_WORKFLOWS.md`](./API_WORKFLOWS.md)
- Authentication, roles, and audit: [`API_SECURITY_MODEL.md`](./API_SECURITY_MODEL.md)
- Epistemic boundaries and their enforcement: [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md)
- Non-capabilities and deliberate boundaries: [`API_LIMITATIONS.md`](./API_LIMITATIONS.md)
- OpenAPI coverage status: [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md)
- Verification evidence and command results: [`VERIFICATION_REPORT.md`](./VERIFICATION_REPORT.md)
