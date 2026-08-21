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
- F-01 (resource-filtered search applied `limit` before the filter) was not reachable from the Explorer
  (which uses the unfiltered compatibility route) and was superseded by R2-13 on 2026-08-21.
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

## 12. Phase R1 follow-on design gate: D-1 subject binding (2026-08-14)

This section records the implementation design required before code changes for the approved
research-integrity next step.

1. **Existing structures used for subject resolution**
   - `entity` (`entity_key`, `canonical_name`) for represented canonical entities.
   - `event` (`event_key`, `description`) for represented events.
   - `source_identity` (`source_identity_key`, `display_name`) and
     `entity_source_mapping` (`mapping_status_code`) to preserve unresolved source identities and avoid
     forced canonical promotion.
   - `proposition` subject columns (`subject_entity_id`, `subject_event_id`) as authoritative claim
     subject anchors.

2. **Subject resolution behavior**
   - Explicit represented entity/event in the question: bind to that subject.
   - Source-identity wording in the question: resolve as source identity first; map to canonical entity
     only when exactly one `ACTIVE` mapping exists.
   - Multiple plausible represented matches (same/overlapping labels): return unresolved/ambiguous
     result without `ESTABLISHED`.
   - Unresolved source identity (no active mapping): keep unresolved identity status, do not promote.
   - Absent represented subject: return bounded `NO_MATCH`/`NOT_REPRESENTED` semantics (non-denial),
     never a truth denial.

3. **Proof of subject relevance before `ESTABLISHED`**
   - A row is eligible only when claim subject is the resolved subject:
     `proposition.subject_entity_id = resolved entity` or
     `proposition.subject_event_id = resolved event`.
   - Predicate-only matches without subject binding are excluded from answer rows and cannot produce
     `ESTABLISHED`.

4. **Derived-claim scope through derivation inputs**
   - No schema change in this pass.
   - D-1 fix keeps derived/direct distinction and introduces no new inferred provenance path.
   - D-3 remains separate: if implemented later, scope for derived claims must traverse
     `claim -> derivation -> derivation_input -> input claim/evidence -> source_record -> dataset`.

5. **Claim/evidence aggregation**
   - D-1 scope: prevent cross-subject contamination first.
   - D-6 aggregation (single claim with multiple evidence/provenance paths) is deferred unless required
     for correctness in touched code.

6. **Provenance-gap semantics**
   - Direct claims still require source-backed chain to classify as directly supported.
   - Derived claims remain distinct from direct source observation.
   - Missing required provenance remains unresolved; D-7 refinement remains a follow-on unless required
     by D-1 implementation changes.

7. **API contract alignment (`/api/*` and `/api/v1/*`)**
   - Both surfaces share the same repository research engine; any response-shape change in `research()`
     applies to both routes.
   - Compatibility routes remain in place; no migration to `/api/v1/*` is introduced by this pass.

8. **Regression strategy (Q10/X1 recurrence)**
   - Keep existing tests unchanged.
   - Add focused API regressions for:
     - predicate match with wrong subject (must be excluded),
     - same-name/multiple candidates (ambiguous/unresolved),
     - absent subject,
     - source identity vs canonical entity boundary,
     - supported subject with no matching claim in selected scope.

### 12.1 Finding classification for this gate (A/B/C/D/E)

| ID | Finding | Classification | Planned action |
|---|---|---|---|
| RI-D1 | Predicate-only research can return claims unrelated to asked subject | **A MUST FIX** | Implement subject-first binding and subject-anchored filtering in `research()` with tests |
| RI-D2 | Research limit can truncate silently | **B SHOULD FIX** | Implement bounded truncation metadata (`total_matched`, `returned`, `truncated`) if safe in current contract |
| RI-D3 | Derived scope through derivation inputs is incomplete for dataset scoping | **C DOCUMENT / D DEFER (unless locally safe)** | Document as follow-on unless D-1 changes require immediate fix |
| RI-D6 | Claim/evidence rows are not yet aggregated per claim | **D DEFER** | Defer unless required to preserve correctness in D-1 touched code |
| RI-D7 | Derived provenance wording can blur valid-derived vs missing-provenance gaps | **C DOCUMENT** | Preserve current distinctions; refine only if touched by D-1 |
| RI-D8 | Per-result provenance context depth may be insufficient for one-shot inspection | **D DEFER** | Evaluate after D-1/D-2; avoid oversized payload changes in this pass |
| RI-D4 | Scholarly capability population is a coverage/product concern, not synthetic generation | **E FALSE POSITIVE (for code fix)** | Document honestly; do not fabricate scholarly material |

### 12.2 Implementation outcome for this pass

- **Implemented (fixed):**
  - **D-1 subject binding** in `src/repository.ts::research()`:
    question processing now runs `subject_resolution` first and applies subject-bound proposition filters
    before result classification, preventing predicate-only cross-subject contamination.
  - **D-2 truncation transparency**:
    `ResearchResponse` now includes `bounded { total_matched, returned, truncated, limit, order }`,
    and the Explorer renders returned-vs-total status.
- **Regression coverage added (Q10/X1 recurrence protections):**
  - wrong-subject predicate-match exclusion;
  - ambiguous multi-subject resolution (`UNRESOLVED`);
  - unresolved source-identity handling without canonical promotion;
  - absent subject (`NOT_REPRESENTED`);
  - represented subject with no matching claim (`NO_MATCH`).
- **Compatibility impact:** both `/api/research` and `/api/v1/research` stay aligned because both call the
  same repository research engine; `/api/*` compatibility routes remain supported and unchanged in path.
- **Deferred in this pass (documented, not silently changed):**
  - D-3 derived-claim scope expansion through derivation inputs;
  - D-6 claim/evidence row aggregation into one claim row with nested paths;
  - D-7 derived provenance semantic split refinements;
  - D-8 expanded per-result provenance payload;
  - D-5 broader pagination architecture work.

## 13. D-1/D-2 post-remediation verification follow-up (2026-08-14)

### 13.1 Frozen system under test and complete diff review

- **Repository/ref:** `PapaDanielP/Project-Berean`,
  `copilot/verify-d1-d2-remediation`.
- **Frozen verification baseline:** `b68ed049fbdebea613defc2d9bb256b643a718fe`. Its tree is
  identical to remediation merge `27cd328968b183d5978910839d6f30f931e55da4` (PR #77);
  `b68ed049` only records the follow-up plan.
- **Initial status:** clean, tracking `origin/copilot/verify-d1-d2-remediation`, with no staged,
  unstaged, or untracked files.
- The clone was unshallowed before comparison. The complete 759-line patch from the remediation
  merge's first parent was read, not only its stat/name-status. It changes 10 expected files:
  `src/repository.ts`, `src/api/openapi.ts`, `src/public/app.js`, `tests/app/app.test.ts`, this
  current audit, and five current API documents.
- No schema, fixture, historical phase record, data record, secret, database, log, generated, or
  scratch file occurs in that diff. `git diff --check 27cd328^1..27cd328` passed.

Verification used Node.js 24.18.0, npm 11.16.0, PostgreSQL 16.14, and Chromium 150.0.7871.0.
The clean disposable `berean_test` database was loaded by
`scripts/validation/run-postgres-validation.sh`, which creates both core and administration
schemas and replays the Phase 30–37 fixtures/validations. The resulting corpus contained 45 public
base tables, 157 entities, 115 events, 361 claims, 349 propositions, and 191 evidence rows.

### 13.2 D-1 semantic verification

**PASS.** `resolveResearchSubject()` searches existing `entity`, `event`, and `source_identity`
labels. A source identity is promoted only through exactly one `ACTIVE`
`entity_source_mapping`; zero active mappings remain `UNRESOLVED_SOURCE_IDENTITY`, and multiple
active mappings remain `AMBIGUOUS`. Equal strongest candidates consolidate only when they identify
the same represented entity.

Retrieval then joins `claim` to its authoritative `proposition` and requires either
`p.subject_entity_id = resolved entity` or `p.subject_event_id = resolved event` before dataset
scope, classification, or result return. Predicate-only cross-subject rows therefore cannot enter
the result set. No subject-specific answer map, unrestricted inference, truth adjudication, new
relationship authority, or fabricated provenance was introduced.

Code review plus tests/live requests covered:

| Case | Observed outcome |
|---|---|
| One represented entity (`God`) | `RESOLVED`; 23 subject-bound direct rows; `ESTABLISHED` |
| Wrong-subject participation predicate | `RESOLVED`; zero rows; `NO_MATCH` |
| Same question names `Adam` and `Seth` | `AMBIGUOUS`; zero rows; `UNRESOLVED` |
| Unmapped source identity (`Edison`) | `UNRESOLVED_SOURCE_IDENTITY`; zero rows; `UNRESOLVED` |
| Active source-identity alias (`the tablets of the covenant`) | `RESOLVED` via `SOURCE_IDENTITY_ACTIVE_MAPPING` |
| Absent subject | `NO_SUBJECT`; zero rows; `NOT_REPRESENTED` |
| Represented entity with no matching claim (`Earth`/`fatherOf`) | zero rows; `NO_MATCH` |
| Event subject (`enosh_begetting`) | subject-bound derived rows only; `DERIVED` |
| Direct/derived boundary | direct rows remain evidence-classified; derived rows remain `DERIVED_FROM_PERSISTED_GRAPH` |

Ambiguous/unresolved identity responses cannot reach result classification and therefore cannot
yield `ESTABLISHED`. The permanent wrong-subject, ambiguity, unresolved-identity, absent-subject,
and represented-no-match assertions in `tests/app/app.test.ts` exercise response semantics rather
than weakening expected values.

### 13.3 D-2 truncation transparency and contract parity

**PASS with one demonstrated-corpus limitation.** The `subject_bound` CTE is counted with
`COUNT(*) OVER()` before `LIMIT 50`. Results are ordered by
`claim_id, claim_evidence_id NULLS LAST, dataset_id NULLS LAST, source_key NULLS LAST`. The response
sets `returned` from the actual result-array length and `truncated` from
`total_matched > returned`; the explicit limit is 50. Both research routes call the same repository
method and returned byte-identical successful payloads. OpenAPI and current API documents describe
the same fields/order, and actual Chromium rendering displayed “Returned 23 of 23 matched rows.”

The validated corpus's largest subject/predicate result set was 23 rows. It therefore demonstrated
the below-limit path (`total_matched = returned = 23`, `truncated = false`) but could not produce a
real over-limit response. No artificial claims or provenance were inserted merely to force
truncation. The pre-limit window count and truncation expression were instead verified directly in
the complete SQL/logic review. This is a documented verification limitation, not evidence of a
runtime defect.

### 13.4 Explicit non-mutation evidence

Nine representative cases (direct, ambiguous, unresolved identity, absent subject, `NO_MATCH`,
`NOT_REPRESENTED`, derived, bounded, active mapping/wrong-subject) were each sent twice to each
research route: 36 requests total. Before and after, every row of every one of the 45 public base
tables was serialized deterministically and SHA-256 hashed, so updates as well as row-count changes
would be detected. All table counts and hashes were unchanged.

The focused snapshot digest was
`8515a2f72ab3b7396a045ace2331680f652a67fab51a79881e3b0d8f8867ee92`.
Representative counts included: source 30; dataset 36; source_record 179; citation 179; evidence
191; evidence_citation 191; claim 361; claim_evidence 379; proposition 349; derivation 3;
derivation_input 6; entity_source_mapping 110; audit_event 0; asynchronous_job 0; research_topic
0; discovery_request 0; validation_run 0. Research inserted, updated, and deleted none of them.

### 13.5 Reproducibility

Within one unchanged corpus, all repeated responses were byte-identical; no response fields were
excluded. Comparisons included capability, complete `subject_resolution`, plan, ordered claim keys,
classifications, bounded metadata, source/dataset provenance fields, and result ordering.
Compatibility and v1 responses were also identical.

After dropping/recreating both schemas and rerunning the deterministic validation loader, the same
representative responses remained byte-identical; their combined evidence digest was
`ba57e7aed0aac7393e30d2006c6a32094d18cafce3146c3994169b9dd15cb7c9`.
Raw database hashes across the two independent loads were not expected to be identical:
`source.created_at`, `dataset.created_at`, `source_record.imported_at`, and
`derivation.created_at` use `CURRENT_TIMESTAMP`. Counts and API outputs were identical, and these
database-only load timestamps do not occur in research responses.

### 13.6 Actual browser, API/UI parity, and security verification

The Playwright MCP transport was unavailable, but a real installed Chromium process was launched
headlessly and driven through the browser's DevTools protocol against the built app and validated
database. This is actual browser execution, not a static-contract-only claim.

The run verified page and 36-dataset scope load; keyword search; entity detail; claim/evidence
detail; graph expansion; direct, `NO_MATCH`, `NOT_REPRESENTED`, ambiguous, unresolved, and derived
research; and bounded metadata display. It observed 13 API requests, all to read-only compatibility
routes, with zero `Authorization` headers and zero administration-route calls. Static client review
also found no SQL, database connection, token, credential, or `/api/v1` administration call.

The XSS-like search `<img src=x onerror=alert(1)>` produced the safe empty state, zero injected
`img` nodes, and zero injected event-handler attributes. Browser totals were zero console errors
and zero page exceptions.

### 13.7 Commands and results

| Command/evidence | Result |
|---|---|
| `npm ci` | exit 0; 287 packages; 0 vulnerabilities; warning for locked `esbuild` install script approval |
| `npm run typecheck` | exit 0 |
| `npm run lint` | exit 0 |
| `npm run build` | exit 0 |
| `npx vitest run tests/app/documentation-links.test.ts` | exit 0; 11 passed |
| `npx vitest run tests/app/openapi-coverage.test.ts` | initial exit 1: shell lacked `DATABASE_URL`; rerun exit 0, 6 passed |
| `npx vitest run tests/app/explorer-contract.test.ts` | exit 0; 28 passed |
| `npx vitest run tests/app/app.test.ts` | initial exit 1: hostless URL selected TCP/SCRAM; explicit Unix-socket URL rerun exit 0, 67 passed |
| `npm test` | exit 0; 147 passed in 5 files |
| `bash scripts/validation/run-postgres-validation.sh` on a clean database | exit 0; no warning/error matches; “All validation self-test cases passed.” |
| Fresh-schema validation reload and response comparison | loader exit 0; representative responses identical |
| 36-request hash/repeat/parity probe | exit 0; all 45 table snapshots unchanged |
| Actual Chromium DevTools-protocol smoke run | exit 0; 0 console errors, 0 page errors, 0 XSS nodes |
| GitHub Actions run `31843801786` | `action_required`, zero jobs and therefore no failed-job logs; approval/infrastructure state, not a repository failure |

### 13.8 Findings and disposition

| ID | Finding | Classification | Disposition |
|---|---|---|---|
| PV-01 | Residual D-1 subject-binding concern | **E FALSE POSITIVE** | Complete SQL review, regressions, and live adversarial cases verify subject-bound retrieval |
| PV-02 | Residual D-2 metadata/route/UI parity concern | **E FALSE POSITIVE** | Count/order/limit logic, route parity, OpenAPI, and browser display agree |
| PV-03 | No represented result set exceeds 50 rows | **C DOCUMENT** | Limitation recorded; no fabricated knowledge added |
| PV-04 | Fresh loads have differing database timestamps | **C DOCUMENT** | Expected `CURRENT_TIMESTAMP` metadata; response reproducibility is exact |
| PV-05 | `/api/v1/research` validation text does not mention the 1000-character question bound | **D DEFER** | Existing non-semantic wording issue; validation and OpenAPI are correct and unrelated to D-1/D-2 |
| PV-06 | Actions run has `action_required` and no jobs | **E FALSE POSITIVE** | External approval/runtime state; local repository gates pass |

### 13.9 Recommendation

**PASS WITH NON-BLOCKING FINDINGS.** D-1 and D-2 are semantically and operationally verified on the
frozen remediation tree. Research is read-only and reproducible, API/OpenAPI/Explorer behavior is
aligned, actual browser execution passed, and no scholarly data or provenance was fabricated.
PV-03 through PV-05 are non-blocking and do not justify implementation changes in this focused
follow-up.

Project Berean is ready for **Blind Scholarly Research Evaluation #2**, subject to treating the
documented lack of an organically over-limit corpus case as a coverage limitation rather than a
claim that truncation itself was observed.
