# OpenAPI Coverage Report

Ground truth inspected: `src/app.ts`, `src/api/v1.ts`, `src/api/openapi.ts`, `src/administration/routes.ts`,
and the live Express route stack introspected by `tests/app/openapi-coverage.test.ts`.

## Status

The earlier discovery stub has been replaced by an OpenAPI 3.1 contract in `src/api/openapi.ts`, served at
`GET /openapi.json`. Every non-static route registered by the application is documented, and every documented path
corresponds to a registered route. This route-surface result is enforced automatically rather than by review; it is not
by itself proof that every response or schema detail mirrors runtime behavior.

## How coverage is enforced

`tests/app/openapi-coverage.test.ts` walks `app._router.stack` (including the mounted `/api/v1` router), converts each
Express path to its OpenAPI form, and asserts:

1. **Implemented → documented.** Every registered method/path pair appears in `paths` (or, for the two wildcard
   fallback layers, in `x-berean-fallback-routes`). A new route with no documentation fails the suite.
2. **Documented → implemented.** Every documented path/method maps to a registered route, so the document cannot
   describe endpoints that do not exist.
3. **Operation metadata.** Every operation has an operation ID, `summary`, `description`, at least one response,
   read/write classification, and resolvable `$ref`s.
4. **Mutation metadata.** Every write operation declares `security`, `x-berean-minimum-role`, `x-berean-audit`,
   `x-berean-transaction`, and an epistemic boundary note.
5. **Serving.** The document is retrievable over HTTP and is byte-identical to the in-process object.

## Previously reported gaps and their closure

| Gap (previous report) | Status |
|---|---|
| Non-versioned compatibility routes undocumented (`/health`, `/api/research`, `/api/search`, `/api/entities/{id}`, `/api/claims/{id}`, `/api/propositions/{id}`, `/api/events/{id}`, `/api/sources`, `/api/provenance/*`, `/api/derivations/check-eligibility`, `/api/exploration/timeline`, `/api/genesis/coverage`, `/api/dashboard/quality`, `/api/graph`, `/api-docs`, `/openapi.json`) | **Closed** — documented, including the intentional legacy provenance behaviour |
| Versioned read routes undocumented (`/api/v1/health`, `/registry/{registry}`, `/search/{resource}`, `/research/capabilities`, `/provenance/claim/{id}`, `/graph/entity/{id}`) | **Closed** |
| Administration routes undocumented (`admin/{resource}`, `corpora`, `research-topics`, `discovery-requests`, candidates, reviews, source registration, source records, evidence, claims, identity mappings, derivations, jobs, exports, validation runs) | **Closed** |
| Request bodies, enums, required fields absent | **Closed** — request schemas declare required fields, enums, and length limits |
| Error responses absent (validation, auth, authz, not found, conflict, stale version, idempotency conflict, `NOT_REPRESENTED`) | **Closed** — reusable components under `components.responses` |
| Security schemes not applied per operation | **Closed** — bearer scheme declared and applied to every write operation with a minimum role extension |
| Pagination and limits undocumented | **Closed** — `limit` parameters document their defaults and maximums |
| Wildcard `NOT_REPRESENTED` behaviour undocumented | **Closed** — recorded under `x-berean-fallback-routes` |
| No test detecting drift | **Closed** — `tests/app/openapi-coverage.test.ts` |
| Registry capabilities redirect response omitted | **Closed** — `GET /api/v1/registry/capabilities` documents its `307` redirect |

## Explicit current gap status

Measured on 2026-08-14 by introspecting the live Express route stack of `createApp()` and the object returned by
`openApiDocument()` (the same mechanism used by `tests/app/openapi-coverage.test.ts`), and by cross-referencing the
paths exercised in `tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts`, and `tests/app/phase28-ingestion.test.ts`.

Measured surface: **51 registered Express route/method pairs** — 49 addressable routes plus 2 wildcard fallback
layers (`GET *` Explorer shell, `ALL /api/v1/*`). The OpenAPI document declares **50 operations across 50 paths**;
the count differs from 49 because the single Express layer `GET /api/v1/search/:resource?` is documented as the two
addressable paths `/api/v1/search` and `/api/v1/search/{resource}`, and the 2 fallback layers are described under
`x-berean-fallback-routes` rather than as paths.

### IMPLEMENTED_AND_DOCUMENTED

All 49 addressable routes, plus both fallback layers. Enforced in both directions by
`tests/app/openapi-coverage.test.ts`.

### IMPLEMENTED_BUT_UNDOCUMENTED

None. Every registered method/path pair resolves to an operation in `paths` or to an entry in
`x-berean-fallback-routes`; a new undocumented route fails the suite.

### DOCUMENTED_BUT_NOT_IMPLEMENTED

None. Every documented path/method maps to a registered route; the suite rejects phantom operations.

### OPENAPI_ONLY

None. This category is empty for the same reason as `DOCUMENTED_BUT_NOT_IMPLEMENTED`: the document cannot describe a
path that the route stack does not register.

### IMPLEMENTED_BUT_UNTESTED

Route-surface coverage is complete, but the following 12 routes have **no behavior-level assertion** in any suite.
They are documented and their existence is enforced, yet no test inspects their responses:

| Route | Documented | Route surface enforced | Behavior test |
|---|---|---|---|
| `GET /health` | yes | yes | none (only `GET /api/v1/health` is asserted) |
| `GET /api-docs` | yes | yes | none |
| `GET /api/sources` | yes | yes | none |
| `GET /api/sources/{sourceId}` | yes | yes | none |
| `GET /api/dashboard/quality` | yes | yes | none |
| `GET /api/v1/schema` | yes | yes | none |
| `GET /api/v1/research/capabilities` | yes | yes | none |
| `GET /api/v1/graph/entity/{id}` | yes | yes | none |
| `GET /api/v1/{resource}/{id}` | yes | yes | none (generic single-resource read) |
| `POST /api/v1/ingestion-jobs` | yes | yes | none over HTTP; the ingestion pipeline module is covered by `tests/app/phase28-ingestion.test.ts` |
| `POST /api/v1/export-jobs` | yes | yes | none |
| `POST /api/v1/jobs/{id}/retry` | yes | yes | none (`POST /api/v1/jobs/{id}/cancel` is asserted) |

This is a **reported test-coverage gap, not a documentation gap**. It is recorded here rather than closed, because
closing it means adding behavior tests, which is an implementation change outside the scope of a documentation audit.
An earlier statement in this report ("implemented but untested endpoints: none identified at route-surface level")
was true only of the route surface; the enumeration above is the behavior-level answer.

### DOCUMENTED_AND_TESTED

The remaining **37 addressable routes plus both fallback layers** are documented *and* have behavior-level
assertions in `tests/app/app.test.ts` (with `GET /openapi.json` and the `GET /api/v1/registry/capabilities`
redirect additionally asserted in `tests/app/openapi-coverage.test.ts`). Per-route evidence is recorded in
[`API_CAPABILITY_MATRIX.md`](./API_CAPABILITY_MATRIX.md).

### Remaining OpenAPI gaps

None at route-surface level for implemented non-static routes. Route-surface completeness does not replace
behavior-level testing for every response shape. In the current pass, the `ResearchResponse` schema was
updated to include subject-resolution planning and bounded truncation metadata
(`bounded.total_matched/returned/truncated`) so bounded subsets are explicit in both `/api/research`
and `/api/v1/research`.

## Deliberate documentation boundaries

- The Explorer shell (`GET *`), the unmatched-`/api` JSON 404 handler (`ALL /api/*`), and the `/api/v1` catch-all are
  described as fallback behaviours rather than as addressable paths, because they match arbitrary URLs. A generic V1 read route can return `404 NOT_FOUND` before the
  V1 catch-all returns `501 NOT_REPRESENTED`; the fallback description does not override that route-specific result.
- Response bodies are documented as shapes and required envelope fields; row-level column lists are not duplicated
  from [`docs/03-schema/INFORMATION_SCHEMA.md`](../03-schema/INFORMATION_SCHEMA.md).
- Endpoints that do not exist are not documented, including anything that would adjudicate truth. See
  [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md).
