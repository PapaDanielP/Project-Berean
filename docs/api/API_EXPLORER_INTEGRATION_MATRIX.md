# API ↔ Explorer Integration Matrix

This is the canonical Explorer/API integration matrix: for every endpoint the Explorer
(`src/public/app.js` + the HTML shell in `src/app.ts`) calls, the actual request shape, actual
response shape, epistemic interpretation, authentication, and test coverage. It does not duplicate
the full endpoint reference in [`API_DEVELOPER_GUIDE.md`](./API_DEVELOPER_GUIDE.md) or the
route-level matrix in [`API_CAPABILITY_MATRIX.md`](./API_CAPABILITY_MATRIX.md); it cross-references
them and adds the Explorer-specific columns (UI entry point, client-side field usage, and the
Explorer's own epistemic-safety handling).

Ground truth inspected: `src/public/app.js` (630 lines), `src/app.ts`, `src/api/openapi.ts`,
`tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts`, and
`tests/app/explorer-contract.test.ts` (added alongside this document — see
[`../07-review/EXPLORER_API_INTEGRATION_AUDIT.md`](../07-review/EXPLORER_API_INTEGRATION_AUDIT.md)
§7).

## Classification key

- **IMPLEMENTED_AND_DOCUMENTED** — the route exists in the Express router and in `GET /openapi.json`.
- **DOCUMENTED_AND_TESTED** — additionally covered by a behavior-level test.
- All thirteen Explorer-called path templates below are both.

## Matrix

| Capability | UI entry point | API | Request | Response fields the client reads | Epistemic interpretation | Auth | Tests |
|---|---|---|---|---|---|---|---|
| Research scope discovery | scope `<details>` panel, loaded on page load | `GET /api/research/scope` | none | `datasets[].dataset_id`, `.name`, `.source_name`, `.claim_count` | Scope selection is presentation over persisted datasets; it never creates a domain or reconciles identities (stated in the UI copy itself) | none (read-only, unauthenticated) | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Research question | "Ask Berean" form → `#researchButton` | `POST /api/research` | JSON `{question: string, datasetIds: number[]}` (empty array = all persisted datasets) | `capability`, `interpretation`, `plan.classification`, `plan.subject_resolution.status`, `plan.traversal_shape`, `bounded.total_matched`, `bounded.returned`, `bounded.truncated`, `results[].classification`, `results[].claim_status_code`, `limitation` | Research is now subject-bound: predicate matches that are not bound to the resolved represented subject are excluded; ambiguous/unresolved/no-subject states are returned explicitly and never promoted to `ESTABLISHED` | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Keyword search | "Find represented records" form → `#searchButton` | `GET /api/search?q&limit` | `q` (≤ 200 chars), `limit` (positive integer; effective cap 50 rows server-side) | `results[].type`, `.id`, `.key`, `.label` | Every hit is labelled "Matched"; the standing note "Matches are not established claims" is always shown alongside results | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Entity detail | click an entity search/research hit | `GET /api/entities/{id}` | numeric `id` from a prior search/research response | `entity.canonical_name`, `sourceMappings[]`, `events[]`, `claims[]` | Source identity mappings are rendered with `mapping_status`, not collapsed into "identified" | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Claim detail | click a claim search/research hit | `GET /api/claims/{id}` | numeric `id` | `claim.claim_type_code`, `.claim_status_code`, `proposition`, `evidence[]`, `derivation`, `claimRelations[]` | `SUPERSEDED` claims render their status badge and retained evidence, never promoted; derived claims render a `Derivation` section instead of an invented citation | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Proposition detail | claim detail link | `GET /api/propositions/{id}` | numeric `id` | `proposition`, `claims[]` (may list multiple competing claims for one proposition) | Competing claims for the same proposition are listed side by side, not merged into one answer | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Event detail | click an event search/research hit | `GET /api/events/{id}` | numeric `id` | `event`, `participation[]` (from the `event_participation` view), `claims[]` | Participation rows render as "claim-asserted participation" with the asserting claim id, never as a synthesized relationship (e.g. employment) | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Source / dataset browsing | click a source search hit / source list | `GET /api/sources`, `GET /api/sources/{id}` | none / numeric `id` | `sources[]` / `source`, `datasets[]`, `sourceRecords[]` | none (pass-through metadata display) | none | code-traced; `tests/app/explorer-contract.test.ts` |
| Provenance traversal | claim detail "Trace provenance" | `GET /api/provenance/claims/{id}` | numeric `id` | `traversal[]` (evidence → citation → source record → dataset → source chain) | A derived claim's traversal row with null evidence fields renders no invented citation; the intentional 200-with-empty-traversal behavior for a missing claim (vs. the versioned API's 404) is documented in OpenAPI, not treated as a bug | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Genesis coverage / quality dashboard | dashboard links | `GET /api/genesis/coverage`, `GET /api/dashboard/quality` | none | arbitrary structured JSON rendered as formatted text | Locator population state (e.g. `populated:false, source_unavailable:true`) is rendered as absence-of-representation, not as a false statement | none | `tests/app/app.test.ts`; `tests/app/explorer-contract.test.ts` |
| Bounded relationship graph | "Expand selected node neighborhood" | `GET /api/graph?nodeType&nodeId` | `nodeType ∈ {entity, claim}`, numeric `nodeId` | `edges[].source`, `.target`, `.relation`, `.claimId` | An edge represents a persisted proposition between two distinct nodes; the client renders no edge as an assertion for a node not connected by a persisted proposition (self-referential edges were a defect — see below) | none | `tests/app/app.test.ts` (including the graph-content regression test added in this pass); `tests/app/explorer-contract.test.ts` |

## Authentication

The Explorer never sends an `Authorization` header, never stores or reads a token/credential, and
never calls an authenticated or administrative route. It persists only selected dataset-scope
identifiers in same-origin `sessionStorage` (`berean-scope`) for reader convenience. All thirteen
endpoint path templates above are unauthenticated by design; the full authentication/authorization
model for the routes the Explorer does **not** call is documented in
[`API_SECURITY_MODEL.md`](./API_SECURITY_MODEL.md).

## Endpoints the Explorer does not use

The Explorer never calls `/api/v1/*`, `/api/exploration/timeline`, `/api/provenance/explain`, or
`/api/derivations/check-eligibility`, although those are implemented, documented, and tested. This
is a product-surface gap, not a contract defect (recorded as F-06 in
[`../07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](../07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md)).
No new API surface is required to close it; it would require an Explorer UI addition against
existing documented endpoints.

## Compatibility-route decision (constrained remediation)

For this remediation pass, the Explorer remains on the `/api/*` compatibility surface by design.
No migration to `/api/v1/*` was made solely due to versioning preference. The decision is intentional
because all Explorer-called compatibility routes are implemented, OpenAPI-documented, and covered by
contract tests in this repository.

The Explorer UI now includes a concise interpretation guide near the research form that explains
`ESTABLISHED`, `DERIVED`, `SCHOLARLY_CANDIDATE`, `UNRESOLVED`, `NO_MATCH`, and `NOT_REPRESENTED` in
plain language while preserving backend classifications and epistemic boundaries. In particular:

- `NO_MATCH` means a supported query found no matching persisted claim in the active scope.
- `NOT_REPRESENTED` means the question/conclusion is outside Berean's currently represented scope.
- Neither state is rendered as "false."

## Defect fixed as part of this integration audit

The `GET /api/graph` entity-neighborhood projection previously emitted self-referential edges
(`entity:X —predicate→ entity:X`) because of a string/number type-comparison bug in
`src/repository.ts`. This has been fixed (numeric coercion) with a regression test in
`tests/app/app.test.ts`. See
[`../07-review/EXPLORER_API_INTEGRATION_AUDIT.md`](../07-review/EXPLORER_API_INTEGRATION_AUDIT.md)
§7 (F-EXP-01) for full detail.

## Unmatched `/api` paths (2026-08-14 verification pass)

Any `/api` path that matches no compatibility or versioned route now returns
`404 {"error":"route not found"}` as JSON. Previously an unmatched `GET /api/...` fell through to the
Explorer HTML shell and returned `200 text/html`, which the client's `fetchJson` helper surfaced as
the misleading `Request failed (200)`. The Explorer calls no such path, so no capability row above
changes; the fix makes contract drift observable to the Explorer and to any other API consumer
instead of silently succeeding. See `EXPLORER_API_INTEGRATION_AUDIT.md` §7 (F-EXP-03).

## Contract-test coverage

`tests/app/explorer-contract.test.ts` (added in this pass) extracts the endpoint path Explorer calls
from `src/public/app.js` with a regular expression and asserts each one resolves to a route
registered on the live Express application and documented in `GET /openapi.json`, reusing the
route-collection approach already established in `tests/app/openapi-coverage.test.ts`. This is the
smallest useful Explorer↔API contract test: it fails if a route the Explorer depends on is renamed,
removed, or undocumented, without adding a browser-test framework or new dependency.
