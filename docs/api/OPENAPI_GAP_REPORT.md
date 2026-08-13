# OpenAPI Gap Report

Ground truth inspected:

- `src/app.ts`
- `src/api/v1.ts`
- `src/administration/routes.ts`
- manual `GET /openapi.json` on 2026-08-13

## Summary

`openApiDocument()` exposes a valid OpenAPI 3.1 object, but it is a **discovery stub**, not a complete contract.

Manual verification counted **17 documented path entries** in `/openapi.json`, while the application exposes substantially more concrete route/method combinations across `/api/*`, `/api/v1/*`, and the administration surface.

## 1. Implemented routes missing entirely from the OpenAPI document

### Missing non-versioned routes

- `GET /health`
- `GET /openapi.json`
- `GET /api-docs`
- `GET /api/research/scope`
- `POST /api/research`
- `GET /api/search`
- `GET /api/entities/{entityId}`
- `GET /api/claims/{claimId}`
- `GET /api/propositions/{propositionId}`
- `GET /api/events/{eventId}`
- `GET /api/sources`
- `GET /api/sources/{sourceId}`
- `GET /api/provenance/claims/{claimId}`
- `GET /api/provenance/explain`
- `GET /api/derivations/check-eligibility`
- `GET /api/exploration/timeline`
- `GET /api/genesis/coverage`
- `GET /api/dashboard/quality`
- `GET /api/graph`
- `GET *` Explorer shell

### Missing versioned read routes

- `GET /api/v1/health`
- `GET /api/v1/registry/{registry}`
- `GET /api/v1/search/{resource?}`
- `GET /api/v1/research/capabilities`
- `GET /api/v1/provenance/claim/{id}`
- `GET /api/v1/graph/entity/{id}`

### Missing administration routes

- `GET /api/v1/admin/{resource}`
- `PATCH /api/v1/corpora/{id}`
- `POST /api/v1/identity-mappings`
- `POST /api/v1/identity-mappings/{id}/review`
- `POST /api/v1/derivations`
- `POST /api/v1/jobs/{id}/cancel`
- `POST /api/v1/jobs/{id}/retry`

## 2. Paths present but under-specified

### `/api/v1/{resource}` and `/api/v1/{resource}/{id}`

Documented only as generic placeholders. Missing from OpenAPI:

- allowed resource enum values:
  - `entities`
  - `events`
  - `claims`
  - `evidence`
  - `sources`
  - `datasets`
  - `source-records`
  - `citations`
  - `identities`
  - `identity-mappings`
- different detail shapes for `entities`, `events`, `claims`, and `sources`
- `limit` query parameter schema and bounds
- `404` vs `400` errors for bad resource/id

### `/api/v1/research`

Present, but missing:

- request body schema (`question`, optional `datasetIds`)
- validation bounds (question max 1000, datasetIds max 100 positive integers)
- response classifications (`ESTABLISHED`, `DERIVED`, `SCHOLARLY_CANDIDATE`, `UNRESOLVED`, `NOT_REPRESENTED`, `NO_MATCH`)
- plan structure
- examples

### `POST /api/v1/corpora`, `/research-topics`, `/discovery-requests`, `/discovery-requests/{id}/candidates`, `/candidates/{id}/review`, `/source-registrations`, `/source-records`, `/evidence`, `/claims`, `/ingestion-jobs`, `/validation-runs`, `/export-jobs`

Present as summary-only stubs. Missing:

- request body schemas
- response schemas
- error schemas
- minimum-role requirements
- transaction/audit notes
- header documentation
- examples

## 3. Missing headers and conditional-request documentation

The OpenAPI document does not describe any of the headers that matter operationally:

- `Authorization: <bearer token>`
- `Idempotency-Key` (required on queueing routes)
- `If-Match` (required on `PATCH /api/v1/corpora/{id}`)
- `X-Correlation-Id` response header on admin routes
- `WWW-Authenticate: Bearer` on 401 responses

It also does not explain the important implementation fact that there is **no semantic ETag concurrency contract** even though `If-Match` is used.

## 4. Missing error definitions

No reusable OpenAPI components exist for these implemented errors:

- `AUTH_NOT_CONFIGURED` (`503`)
- `UNAUTHENTICATED` (`401`)
- `FORBIDDEN` (`403`)
- `INVALID_REQUEST` (`400`)
- `INVALID_PROPOSITION` (`400`)
- `STALE_VERSION` (`409`)
- `IDEMPOTENCY_CONFLICT` (`409`)
- `DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION` (`422`)
- `DERIVATION_REQUIRED` (`422`)
- `DERIVATION_NOT_ALLOWED` (`422`)
- `DERIVATION_INPUT_REQUIRED` (`422`)
- `IDENTITY_EVIDENCE_SOURCE_MISMATCH` (`422`)
- `INVALID_MAPPING_STATE` (`409`)
- `INVALID_JOB_STATE` (`409`)
- `NOT_REPRESENTED` (`501`)
- `NOT_FOUND` (`404`)
- generic `internal_error` (`500`)
- database-mapped `DUPLICATE` (`409`)
- database-mapped `INTEGRITY_VIOLATION` (`422`)

## 5. Missing auth and role semantics

OpenAPI defines only one generic `bearerAuth` scheme. It does **not** document that implemented routes require different minimum roles:

- `READER`
- `RESEARCHER`
- `CONTENT_EDITOR`
- `REVIEWER`
- `ADMINISTRATOR`
- `SYSTEM` (used in job-ownership checks, not as a direct route minimum)

The document also omits the fail-closed `503 AUTH_NOT_CONFIGURED` behavior when no credentials are configured.

## 6. Missing pagination / bounds / parameter contracts

Not documented in OpenAPI:

- `limit` bounds on `/api/search`, `/api/v1/search`, `/api/v1/:resource`, `/api/v1/admin/:resource`
- `entity_id` vs `entity_key` mutual exclusivity on `/api/exploration/timeline`
- `claim_id` vs `proposition_id` mutual exclusivity on `/api/provenance/explain`
- positive-integer constraints on IDs throughout the API
- supported `registry` values for `/api/v1/registry/{registry}`
- supported admin resources for `/api/v1/admin/{resource}`

## 7. Missing worker / async semantics

OpenAPI does not state that queueing routes:

- return `202` because they persist queue state,
- do not complete work in-process,
- require an external SYSTEM worker for execution,
- may remain `QUEUED` indefinitely in this repository alone.

## 8. Missing examples and epistemic-boundary notes

OpenAPI includes no examples for:

- Genesis provenance reads,
- Seneca Falls scope/research,
- World's Columbian Exposition discovery/candidate review,
- identity proposals remaining `PROPOSED`,
- `NOT_REPRESENTED` and `NO_MATCH` outputs,
- analytical evidence rejection for direct claims.

It also omits the key conceptual warnings proven throughout the repository:

- claim ≠ truth
- candidate ≠ evidence
- proposed mapping ≠ active reconciliation
- derived graph path ≠ persisted claim

## 9. Recommended documentation-only conclusion

Do **not** treat `/openapi.json` as a complete integration contract. Use it only as a discovery stub until the missing path, schema, header, error, and role documentation gaps are closed.
