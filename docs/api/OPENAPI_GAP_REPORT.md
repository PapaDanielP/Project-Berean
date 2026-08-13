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

- **Implemented but undocumented endpoints:** none identified.
- **Implemented but untested endpoints:** none identified at route-surface level; route/documentation drift is enforced by `tests/app/openapi-coverage.test.ts`.
- **Remaining OpenAPI gaps:** none at route-surface level for implemented non-static routes.

Note: route-surface completeness does not replace behavior-level testing for every response shape.

## Deliberate documentation boundaries

- The Explorer shell (`GET *`) and the `/api/v1` catch-all are described as fallback behaviours rather than as
  addressable paths, because they match arbitrary URLs. A generic V1 read route can return `404 NOT_FOUND` before the
  V1 catch-all returns `501 NOT_REPRESENTED`; the fallback description does not override that route-specific result.
- Response bodies are documented as shapes and required envelope fields; row-level column lists are not duplicated
  from [`docs/03-schema/INFORMATION_SCHEMA.md`](../03-schema/INFORMATION_SCHEMA.md).
- Endpoints that do not exist are not documented, including anything that would adjudicate truth. See
  [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md).
