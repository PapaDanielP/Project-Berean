# Explorer / API Integration Audit

**Classification:** REVIEW / AUDIT record. It records findings and evidence. It does **not** define
runtime behavior, schema semantics, or API contracts. Implementation (`src/`), schema
(`schema/sql/`), executable tests (`tests/`), and validation scripts (`scripts/validation/`) remain
the behavioral authority; the authoritative current documentation listed in
[`../README.md`](../README.md) remains the current specification.

**Audit date:** 2026-08-14 · **Repository:** `PapaDanielP/Project-Berean`
**Scope:** whether the Explorer (`src/app.ts` HTML shell + `src/public/app.js` +
`src/public/styles.css`) is a correctly architected, documented, epistemically safe consumer of the
implemented API surface, and nothing else. This document narrows and re-verifies the Explorer
sections of [`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](./FINAL_PLATFORM_ARCHITECTURE_AUDIT.md)
(§§13–22), which remains the platform-wide predecessor audit and is not superseded by this file.
Where this audit found and fixed a defect, that predecessor's finding is marked fixed here, and its
own text is left as the historical record of what was found.

## 1. Architecture: is the Explorer a correct API consumer?

- The Explorer is a dependency-free ES module (`src/public/app.js`, 630 lines) served by an HTML
  shell built inline in `src/app.ts`. There is no bundler, framework, or router.
- **No direct database access.** `src/public/app.js` contains no SQL, no `pg` import, and no
  database connection string. Grep confirms this: `grep -n "pg\.\|SELECT \|INSERT \|new Pool" src/public/app.js` returns nothing.
- **No embedded SQL, no repository/business/provenance/epistemic logic duplicated.** The client
  renders server-returned fields (`classification`, `capability`, `limitation`, `mapping_status`,
  `claim_status_code`, `evidence_relation_type_code`, …) verbatim; it does not recompute
  classifications, does not adjudicate truth, and does not synthesize relationships from raw rows.
- **No fixture-specific IDs.** Every entity/claim/event/source id the client uses is obtained from a
  prior `GET /api/search` (or `POST /api/research`) response at runtime; no id is hard-coded in
  `src/public/app.js` or `src/app.ts`.
- **No hard-coded knowledge.** Static copy in the client is limited to labels, help text, and the
  fixed capability/legend strings already documented in
  [`../api/API_EPISTEMIC_BOUNDARIES.md`](../api/API_EPISTEMIC_BOUNDARIES.md) (e.g. "Matches are not
  established claims."); no represented fact (a name, date, claim, or relationship) is inlined in
  the client.
- **No undocumented/private interfaces.** Every request the client issues resolves to an
  OpenAPI-documented path (§3 below); there is no `/internal`, `/debug`, or otherwise undocumented
  route call.

**Finding: the Explorer is a correctly architected API consumer.** It performs no database access,
embeds no SQL, does not bypass the API, does not duplicate server-side logic, uses no
fixture-specific identifiers, hard-codes no represented knowledge, and calls no undocumented
interface.

## 2. Capability inventory

| Explorer capability | UI entry point | API call(s) |
|---|---|---|
| Research scope discovery | scope `<details>` panel | `GET /api/research/scope` |
| Research question | "Ask Berean" form | `POST /api/research` |
| Keyword search | "Find represented records" form | `GET /api/search` |
| Entity detail | search/research result click | `GET /api/entities/{id}` |
| Claim detail (incl. derivation, evidence, related claims) | search/research result click | `GET /api/claims/{id}` |
| Proposition detail | claim detail link | `GET /api/propositions/{id}` |
| Event detail | search/research result click | `GET /api/events/{id}` |
| Source / dataset browsing | source result click | `GET /api/sources`, `GET /api/sources/{id}` |
| Provenance traversal | claim detail "Trace provenance" | `GET /api/provenance/claims/{id}` |
| Genesis coverage / quality dashboard | dashboard links | `GET /api/genesis/coverage`, `GET /api/dashboard/quality` |
| Bounded relationship graph | "Expand selected node neighborhood" | `GET /api/graph` |

Thirteen distinct endpoint path templates are used. **No administrative UI is present**: there is no login form, no
token input, no write action anywhere in `src/public/app.js` or `src/app.ts`'s HTML shell. This
matches the read-only design stated in `README.md` and `API_SECURITY_MODEL.md`.

## 3. Request/response contract verification

The full endpoint-by-endpoint request/response comparison (methods, parameters, bodies, response
fields, and status codes actually returned by `src/app.ts`) is maintained as the canonical matrix in
[`../api/API_EXPLORER_INTEGRATION_MATRIX.md`](../api/API_EXPLORER_INTEGRATION_MATRIX.md). Summary:

- All thirteen Explorer-called path templates are **IMPLEMENTED_AND_DOCUMENTED** in `src/api/openapi.ts` /
  `GET /openapi.json`, confirmed programmatically by `tests/app/openapi-coverage.test.ts` (route
  surface) and, as of this audit, by `tests/app/explorer-contract.test.ts` (Explorer-specific
  endpoint coverage, added in this pass — see §7).
- No Explorer call assumes a request shape, status code, or response field that the server does not
  actually provide. No outdated assumption was found.
- The Explorer never calls `/api/v1/*`; it only uses the legacy `/api/*` compatibility surface, which
  is intentional (documented in `OPENAPI_GAP_REPORT.md` as the compatibility tag) and not a bypass —
  the compatibility routes are themselves implemented, documented, and tested endpoints.

## 4. Authentication, authorization, and security

- The Explorer never sends an `Authorization` header and never stores a token or credential. It
  writes only the selected dataset-scope identifiers to same-origin `sessionStorage` under
  `berean-scope`; it does not write `localStorage`, cookies, bearer tokens, or credentials. Every
  route it calls is unauthenticated by design (read-only, non-administrative), matching
  `API_SECURITY_MODEL.md`.
- An ordinary reader of the Explorer cannot reach any administrator action: no administration route
  (`/api/v1/admin/*`, ingestion, discovery, candidate review, identity mapping, derivation, job, or
  export endpoints) is called or reachable from the UI. Authorization enforcement for those routes is
  server-side (`src/administration/routes.ts`, `src/auth.ts`) and out of the Explorer's reach entirely
  — verified by code inspection and by live browser sessions (§6) whose network logs showed only
  documented compatibility endpoints from the thirteen-template Explorer surface.
- **XSS:** the client uses `textContent`/DOM node construction for all rendered result text; it does
  not use `innerHTML` with unescaped server data for search results, research results, or error
  messages. A live browser probe (§6) submitted `<img src=x onerror=alert(1)>` as a search term; the
  rendered DOM contained the escaped empty-state paragraph and **zero** injected `<img>` nodes.
- **CSP:** `src/app.ts` serves a `script-src 'self'` Content-Security-Policy; a Playwright
  `waitForFunction` call (which requires evaluating a string as JavaScript) was refused by the
  browser during this audit's session, independently confirming the CSP is enforced, not merely
  declared.
- **Error exposure:** the client renders the server's `{ "error": "message" }` envelope or a generic
  fallback string; it never renders a raw stack trace, SQL fragment, or driver error, because the
  server itself never emits one (verified against `src/app.ts` error handler and `API_SECURITY_MODEL.md`).
- **Open redirects / URL handling:** the client only issues same-origin `fetch` calls built from
  `encodeURIComponent`-escaped query parameters; it does not navigate to, or interpolate, an
  attacker-controlled URL.

## 5. Epistemic-safety review

| Distinction the UI must preserve | Result |
|---|---|
| MATCHED vs. ESTABLISHED | **Safe.** Search hits are labelled "Matched" with the standing note "Matches are not established claims." |
| SOURCE-BACKED vs. TRUE | **Safe.** Claim capability text states a represented claim is not a truth declaration. |
| derived vs. direct | **Safe.** Derived claims render a "Derivation" section (method, assumptions, inputs); direct claims do not. |
| scholarly candidate vs. established | **Safe.** No candidate/discovery surface exists in the Explorer at all — nothing to mislabel. |
| unresolved identity vs. identified person | **Safe.** An unresolved source identity (e.g. `Edison`) renders as "Source identity", not as a canonical entity/person. |
| proposed mapping vs. active mapping | **Safe.** `mapping_status` is rendered as an explicit labelled field, not collapsed into a single "identified" state. |
| NO_MATCH vs. FALSE | **Safe in the Explorer** ("No represented records matched this keyword."). |
| NOT_REPRESENTED vs. FALSE | **Safe.** The server's non-denial limitation text ("Absence of representation is not a denial…") is rendered verbatim. |
| differing source descriptions vs. contradiction | **Safe.** `EVIDENCE_CONTRADICTS`/`EVIDENCE_QUALIFIES` values are rendered as stored relation-type labels, not synthesized into a "conflict" narrative. |
| workflow state vs. authoritative knowledge | **Safe.** No workflow/administration surface is exposed in the Explorer. |
| query-derived graph path vs. persisted relationship assertion | **Fixed in this pass (was unsafe — see §7, F-EXP-01).** The graph neighborhood previously rendered self-referential edges (`entity:X —predicate→ entity:X`) that correspond to no persisted proposition. That defect is corrected; the projection now only emits an edge where a distinct persisted proposition relates two different nodes. |

## 6. User-prompt and browser testing

Browser automation was available in this environment via a manually installed Playwright +
Chromium (the sandboxed Playwright MCP browser tool itself was unreachable — see
[`EXPLORER_TEST_REPORT.md`](./EXPLORER_TEST_REPORT.md) §1 for the exact commands and error). Two
scripted sessions were run against `npx tsx src/server.ts` over a database populated by
`scripts/validation/run-postgres-validation.sh`. Full session transcripts, exact commands, and
results (including console/page error counts, the XSS probe, `NO_MATCH`/`NOT_REPRESENTED` prompts,
and the post-fix graph neighborhood check) are recorded in
[`EXPLORER_TEST_REPORT.md`](./EXPLORER_TEST_REPORT.md). Summary: **0 console errors, 0 page errors,
0 injected XSS nodes, correct `NO_MATCH`/`NOT_REPRESENTED` text, and no self-referential graph edges
after the F-EXP-01 fix.**

The full 23-row user-prompt matrix (Tesla, Westinghouse, Edison, World's Columbian Exposition,
AC/DC, Genesis, supported/unsupported questions, dataset restrictions, scholarly candidates,
unresolved identities, derived results) recorded in
`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` §16 remains accurate; row 10 (graph self-loop) is now **PASS**
following the F-EXP-01 fix rather than FAIL, re-verified live in this pass (§6 of
`EXPLORER_TEST_REPORT.md`).

## 7. Defects found and fixed in this pass

### F-EXP-01 — Entity graph neighborhood emitted self-referential edges (FIXED)
- **Area:** `src/repository.ts`, `getGraphNeighborhood`, entity branch.
- **Root cause:** `row.subject_entity_id !== nodeId` compared a PostgreSQL `bigint` (returned by the
  `pg` driver as a JavaScript `string`) against a `number`, so the strict-inequality self-exclusion
  guard was always true and the center node was re-emitted as its own neighbor for every proposition
  in which it participated.
- **Fix:** both comparisons (subject and object branch) now coerce with `Number(...)` before
  comparing, and node ids are stored as numbers, matching the pattern already used correctly in the
  claim branch of the same function.
- **Regression test added:** `tests/app/app.test.ts` — `projects an entity graph neighborhood with no
  self-referential edges`, asserting the `adam` entity's graph has no `entity:{id} → entity:{id}` edge
  and still contains the real `fatherOf` edge to `seth`.
- **Verified live:** a browser session against the Nikola Tesla entity (§6, `EXPLORER_TEST_REPORT.md`)
  shows only `PARTICIPANT` edges to distinct event nodes, no self-loop.
- **Scope discipline:** this is a one-line correctness fix to an existing function with an added test;
  no schema, API contract, or route was changed. It was previously reported and explicitly deferred
  as `F-02` in `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`; that record is preserved unmodified as the
  historical finding, and is cross-referenced here as fixed.

### F-EXP-02 — No automated Explorer↔API contract test (FIXED, smallest useful test added)
- Previously reported as `F-13` in `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` §20/§21, with a
  recommended smallest strategy of extracting the Explorer's called endpoint paths and asserting each
  resolves to a documented OpenAPI path.
- **Action taken:** added `tests/app/explorer-contract.test.ts`, which parses the Explorer `fetch(...)`
  call sites out of `src/public/app.js` with a regular expression and asserts each resolves to a path
  registered in the live Express route stack (reusing the route-collection helper pattern from
  `tests/app/openapi-coverage.test.ts`) and documented in `src/api/openapi.ts`. This closes the
  contract-drift gap identified by F-13 without adding a browser-test framework as a dependency.

### F-EXP-03 — Unmatched `/api` paths returned `200` HTML instead of a JSON 404 (FIXED, 2026-08-14 verification pass)
- **Severity:** MINOR (API-contract correctness; no epistemic, provenance, or data impact).
- **Observed live** against a running server on the validated corpus:
  `GET /api/nope` → `200 text/html` with the full Explorer HTML shell, and
  `POST /api/unknown` → Express' default HTML 404 page. Only `/api/v1/*` had a JSON 404
  (`{"error":{"code":"NOT_FOUND",…}}`).
- **Cause:** the `app.get('*')` Explorer-shell fallback in `src/app.ts` was reached by any unmatched
  `GET`, including `/api` paths, because no `/api`-scoped terminal handler existed ahead of it.
- **Impact:** an API consumer that requests a mistyped, renamed, or removed compatibility endpoint
  receives a success status and an HTML body. In the Explorer this surfaces through `fetchJson` as
  the misleading `Request failed (200)` (the body is not JSON) instead of a real "not found" error,
  which would mask exactly the contract drift `tests/app/explorer-contract.test.ts` guards against.
- **Fix:** a terminal `app.use('/api', …)` handler mounted after every compatibility and versioned
  route now returns `404 {"error":"route not found"}` in the legacy routes' string-error envelope.
  The non-`/api` HTML shell fallback and every existing route are unchanged; `/api/v1/*` still
  returns its own `501/404` envelope because that router is mounted earlier.
- **Regression test added:** `tests/app/app.test.ts` — `answers unmatched compatibility API paths
  with a JSON 404 instead of the Explorer HTML shell` (asserts JSON 404 for `GET` and `POST` on an
  unknown `/api` path, and that a non-`/api` `GET` still returns the HTML shell).
- **Documentation updated:** the fallback is now declared in `src/api/openapi.ts`
  (`x-berean-fallback-routes`), in [`../api/API_DEVELOPER_GUIDE.md`](../api/API_DEVELOPER_GUIDE.md),
  and in [`../api/OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md), so documentation follows the
  implementation rather than the reverse.
- **Verified after the fix:** `GET /api/no-such-endpoint` → `404 application/json`
  `{"error":"route not found"}`; `GET /` → `200 text/html`; full suite `142 passed`.

## 8. Items unchanged / assessed as still accurate

All remaining findings in `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` §21 (F-01, F-03 through F-12, F-14)
were re-examined and remain accurate as documented there; none required a change to complete this
Explorer/API integration audit, and none is a runtime, schema, or API-contract defect this audit's
scope requires fixing. In particular:

- F-03 (graph edge content previously untested) is now closed by the F-EXP-01 regression test above.
- F-01 (resource-filtered search applies `limit` before the filter) is a `src/api/v1.ts` defect not
  reachable from the Explorer (which uses the unfiltered compatibility route); it remains open and is
  tracked there, not duplicated here.
- F-06 through F-12 remain MINOR GAP / TEST COVERAGE GAP items with no epistemic-safety impact; they
  are listed as remaining issues in `EXPLORER_TEST_REPORT.md` §5 rather than fixed here, per the
  smallest-change-set instruction for this audit.
- Current re-audit also noted non-blocking UI hardening opportunities that are not defects in the
  current Explorer/API contract: the Explorer's generic `fetchJson` helper is tailored to the
  compatibility routes' string error envelopes rather than the authenticated administration API's
  `{ error: { code, message } }` envelope, which the Explorer does not call; a hypothetical
  non-all-selected scope with more than 100 datasets would receive the server's 400 response as a
  generic research failure rather than a pre-submit client warning; and the research button is enabled
  in the initial HTML until scope loading completes, although the submit handler still prevents an
  empty-scope request. These are recorded as UX/hardening limitations, not blocking conformance
  defects, because no current Explorer route, represented-data workflow, or epistemic boundary is
  broken by them.

## 9. Final classification

**PASS WITH NON-BLOCKING ISSUES.** The Explorer is a correctly architected, documented,
epistemically safe API consumer. One implementation defect it exposed (self-referential graph
edges) was fixed with a regression test; one test-coverage gap (Explorer↔API contract) was closed
with the smallest useful test. Remaining findings (F-01, F-05 through F-12 in the predecessor audit)
are non-blocking, previously documented, and out of this pass's minimal-change scope.

**2026-08-14 verification pass (this session):** re-verified end to end against a clean disposable
PostgreSQL 16 database and a live server, including a real headless-Chromium re-execution of the
Explorer prompt matrix (see [`EXPLORER_TEST_REPORT.md`](./EXPLORER_TEST_REPORT.md) §9). Every §1–§6
conclusion above was re-confirmed unchanged: no DB/SQL access from the client, no fixture-specific
ids, no admin affordance, no token handling, no self-loop regression, `MATCHED`/`NO_MATCH`/
`NOT_REPRESENTED`/`UNRESOLVED`/`DERIVED`/`SCHOLARLY_CANDIDATE` labels preserved, and 0 console/page
errors across the whole workflow. One new MINOR contract defect was found and fixed (F-EXP-03).
The classification is unchanged: **PASS WITH NON-BLOCKING FINDINGS.**

## 10. Related records

- [`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](./FINAL_PLATFORM_ARCHITECTURE_AUDIT.md) — platform-wide
  predecessor audit; not superseded.
- [`../api/API_EXPLORER_INTEGRATION_MATRIX.md`](../api/API_EXPLORER_INTEGRATION_MATRIX.md) — canonical
  per-endpoint Explorer/API integration matrix.
- [`EXPLORER_TEST_REPORT.md`](./EXPLORER_TEST_REPORT.md) — exact commands and results for this pass.
- [`DOCUMENTATION_GOVERNANCE_AUDIT.md`](./DOCUMENTATION_GOVERNANCE_AUDIT.md) — documentation
  governance and link-integrity audit.

## 11. Constrained remediation finding classification (A/B/C/D/E)

| ID | Finding | Classification | Action in this pass |
|---|---|---|---|
| R-01 | Explorer heading "What Berean Establishes" could be read as universal truth | **A MUST FIX** | Fixed: wording changed to "Directly source-backed claims" and explanatory copy retained in `src/public/app.js` |
| R-02 | Ask Berean wording could be interpreted as unrestricted reasoning | **A MUST FIX** | Fixed: research copy now states bounded persisted retrieval and no unrestricted historical Q&A in `src/app.ts` |
| R-03 | `NO_MATCH` vs `NOT_REPRESENTED` distinction not explicit enough for first-time users | **A MUST FIX** | Fixed: interpretation guide + capability descriptions explicitly distinguish both and state neither means false |
| R-04 | Explorer `fetchJson` should preserve safe distinctions for known API error categories when available | **B SHOULD FIX** | Fixed minimally: known-code mapping for `NOT_FOUND`, `NOT_REPRESENTED`, and `INVALID_REQUEST` while preserving safe generic fallback |
| R-05 | Compatibility `/api/*` surface should be audited before any migration | **C DOCUMENT** | Documented: compatibility route preserved intentionally; no forced migration to `/api/v1/*` |
| R-06 | Search result types without dedicated detail routes (`dataset`, `source_record`, `citation`, `source_identity`) | **D DEFER** | Unchanged by design: explicit bounded limitation message retained (`No dedicated bounded detail endpoint exists…`) |
| R-07 | Provenance elements should only be interactive when routes exist | **E FALSE POSITIVE** | No defect found: only claim provenance button is interactive and calls existing `GET /api/provenance/claims/{id}` route |
| R-08 | Identity mapping statuses may imply certainty | **C DOCUMENT** | Existing mapping-status rendering retained; interpretation guide clarifies represented status is not truth/certainty |

No schema, ingestion, or administrative-route semantics were changed. Explorer remains read-only and
API-mediated.
