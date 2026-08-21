# Explorer Test Report

**Classification:** REVIEW / AUDIT record (test evidence). It records what was actually run and
observed. It does not define runtime behavior. Authoritative behavior is defined by `src/`,
`schema/sql/`, `tests/`, and `scripts/validation/`.

**Test date:** 2026-08-14 · **Environment:** sandboxed Linux container, Node.js (see `package.json`
engines), PostgreSQL 16 (apt package), no external network access beyond the Playwright CDN download
recorded in §2. No result below was fabricated; every command was actually executed in this
environment and its exit status/output is reported as observed.

## 1. Database setup and startup

```
sudo service postgresql start
sudo -u postgres psql -c "CREATE ROLE runner WITH LOGIN SUPERUSER PASSWORD '<redacted>';"
sudo -u postgres createdb -O runner berean_test
export DATABASE_URL="postgres://runner:<redacted>@localhost:5432/berean_test"
```

Result: PostgreSQL 16 started; role and database created successfully; `SELECT current_database()`
returned `berean_test`.

## 2. Dependency installation

```
npm ci
```

Result: `added 287 packages … found 0 vulnerabilities` (exit 0).

## 3. Static verification

```
npm run typecheck   # tsc --noEmit
npm run lint        # eslint "src/**/*.ts" "tests/app/**/*.ts"
npm run build       # tsc -p tsconfig.json
```

Result: all three exited 0 with no errors, both before and after the changes made in this pass
(`src/repository.ts` graph fix, `tests/app/app.test.ts` regression test,
`tests/app/explorer-contract.test.ts`).

## 4. PostgreSQL validation

```
bash scripts/validation/run-postgres-validation.sh
```

Result: **exit 0.** Replays the Phase 6–37R/37B fixtures and validation slices, including the
Nikola Tesla / George Westinghouse / World's Columbian Exposition (Phase 37/37R/37B) corpus used for
the prompt matrix in §6, and ends with `All validation self-test cases passed.`

**Sequencing note (repository-known, matches an existing memory of this constraint):** the script
must be run against a clean database. If it or `npm test` has already run once, drop and recreate
schemas before re-running either:

```
psql "$DATABASE_URL" -c "DROP SCHEMA IF EXISTS phase28_ingestion CASCADE; DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

Without this, the validation script fails with `more than one row returned by a subquery` and
`npm test` fails with `relation "source_type" already exists`; both were reproduced in this pass
before the schemas were dropped, and both then passed cleanly.

## 5. Automated test suite

```
npm test   # vitest run
```

Result after cleaning the schema: **141 passed (5 test files)** —
`tests/app/documentation-links.test.ts` (11), `tests/app/openapi-coverage.test.ts` (6),
`tests/app/explorer-contract.test.ts` (27), `tests/app/phase28-ingestion.test.ts` (35), and
`tests/app/app.test.ts` (62, including the graph self-loop regression test).

Current re-verification in the final integration pass:

```
npm run typecheck
npm run lint
npm run build
bash scripts/validation/run-postgres-validation.sh
npm test
npx vitest run tests/app/documentation-links.test.ts
```

Results: `typecheck`, `lint`, and `build` exited 0 after `npm ci`; PostgreSQL validation exited 0
with `All validation self-test cases passed.`; `npm test` exited 0 with **141 passed (5 test
files)**; the focused documentation-link test exited 0 with **11 passed**. The first attempted
`typecheck`/`lint`/`build` before dependency installation failed because `node_modules` was absent
(`eslint`, `express`, `pg`, and Node typings were not installed); no source defect was indicated,
and the commands passed after the repository dependencies were installed with `npm ci`.

**Remaining test-coverage gaps** (unchanged from the predecessor audit, not closed in this pass, and
listed here rather than hidden): 12 documented routes have no behavior-level test (F-11 in
`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`); `src/public/app.js` is outside `npm run lint` and
`npm run typecheck` (F-12); the resource-filtered-search `limit`-before-filter defect (F-01) was outside
this audit's scope (not Explorer-reachable) and was later superseded by R2-13 regression coverage.

## 6. Browser / application-level testing

**The bundled Playwright MCP browser tool was unreachable in this environment** — every call
returned a transport/OAuth error:

```
playwright-browser_navigate → "Error: MCP request failed: Transport closed"
playwright-browser_navigate (retry) → "MCPOAuthBrowserRequiredError: Browser-based OAuth required for http://localhost:3100/mcp"
```

Real browser testing was still performed, not skipped: Playwright 1.49.1 and Chromium Headless
Shell 131.0.6778.33 were installed under `/tmp/browsertest` (outside the repository; `package.json`
unchanged, no new project dependency) via:

```
cd /tmp/browsertest && npm init -y && npm install playwright@1.49.1
npx playwright install --with-deps chromium
```

The application was started against the validated database:

```
DATABASE_URL=postgres://runner:<redacted>@localhost:5432/berean_test PORT=3210 npx tsx src/server.ts
```

Two scripted Playwright sessions were driven against `http://localhost:3210/`.

### Session 1 — prompts, search, epistemic states, XSS

Actual captured output:

```json
{
  "title": "Project Berean Explorer",
  "scopeText": "36 of 36 datasets · 378 linked claims",
  "consoleErrors": [],
  "pageErrors": [],
  "searchResultsSnippet": "MatchedCitation · CITE_P37R_DIRECTORY_TESLA · Official Directory (1893), classified exhibitor entry for Nikola Tesla...",
  "xssInjectedNodeCount": 0,
  "xssSnippet": "<p class=\"empty\">No represented records matched this keyword.</p>",
  "noMatchSnippet": "No represented records matched this keyword.",
  "researchSnippet": "AnswerCapability: Not representedThe request asks Berean to establish truth or proof. That relation is not represented by the predicate registry....Absence of representation is not a denial...",
  "requestCount": 8,
  "uniqueApiRequests": [
    "GET /api/research/scope",
    "GET /api/search?q=Nikola%20Tesla&limit=25",
    "GET /api/search?q=%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E&limit=25",
    "GET /api/search?q=zzzznonsenseterm999&limit=25",
    "POST /api/research"
  ]
}
```

Findings:
- **0 console errors, 0 page errors.**
- Searching `Nikola Tesla` returned matched citation/claim/entity hits, correctly labelled.
- The XSS probe `<img src=x onerror=alert(1)>` submitted as a search term produced **0 injected DOM
  nodes**; the rendered result was the escaped "No represented records matched this keyword." empty
  state (the probe term does not match any represented record, so the empty-state path was
  exercised — the search input itself is never reflected as HTML either way, per code inspection of
  `src/public/app.js`).
- The nonsense term `zzzznonsenseterm999` produced the exact `NO_MATCH` non-denial text.
- The research prompt "Prove that alternating current is true" produced
  `Capability: Not represented` with the non-denial limitation text, not a false denial and not a
  fabricated answer.
- Network requests were exactly the documented compatibility endpoints; no unexpected call was made.

### Session 2 — entity detail and graph neighborhood (F-EXP-01 verification)

Actual captured output:

```json
{
  "consoleErrors": [],
  "graphText": "entity:196 —PARTICIPANT→ event:122entity:196 —PARTICIPANT→ event:123"
}
```

Findings:
- Searching `Nikola Tesla`, opening the entity result, and expanding its graph neighborhood produced
  **only edges to distinct event nodes** — no `entity:196 → entity:196` self-loop. This is the live
  confirmation that the `src/repository.ts` fix for F-EXP-01 (see
  `EXPLORER_API_INTEGRATION_AUDIT.md` §7) removed the self-referential edges previously reported in
  `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` (F-02) for this same entity.
- **0 console errors** in this session as well.

Current smoke re-verification: the sandboxed Playwright MCP browser tool again failed with
`Transport closed`. A same-origin smoke test was therefore run with the existing server instead:

```
PORT=3210 npx tsx src/server.ts
curl -sS -D /tmp/berean-headers.txt http://127.0.0.1:3210/
curl -sS http://127.0.0.1:3210/api/research/scope
```

Result: the Explorer HTML shell returned 200 with the configured CSP, `X-Content-Type-Options:
nosniff`, and `Referrer-Policy: no-referrer`; `GET /api/research/scope` returned a JSON dataset
scope (20 datasets in the post-`npm test` database state). This was a smoke check only, not a
replacement for the earlier real-browser sessions recorded above.

### Responsive / accessibility commands

No dedicated responsive-layout or automated accessibility (axe-core, Lighthouse) tooling exists in
this repository, and none was added (consistent with the smallest-change-set instruction). The HTML
shell in `src/app.ts` was inspected instead: form inputs have associated `<label>`s, live regions use
`aria-live`, and result/status text uses `role="status"`; this was not newly verified with an
automated accessibility tool in this pass and remains a documented gap (see §7).

## 7. Limitations of this test pass

- Browser automation via the sandboxed Playwright MCP tool was unavailable; a manually installed
  Playwright/Chromium was used instead, as recorded above. This mirrors the approach used in the
  predecessor `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` audit.
- No automated accessibility scanner (axe-core, Lighthouse, or similar) exists in the repository or
  was added in this pass; accessibility was reviewed by code inspection only (see
  `EXPLORER_API_INTEGRATION_AUDIT.md` for the epistemic-safety review, which is the primary focus of
  this pass).
- The full 23-row user-prompt matrix from `FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` §16 was not
  re-executed row-by-row in this pass; a representative subset (search, `NO_MATCH`, `NOT_REPRESENTED`,
  XSS, and the previously-failing graph row) was re-verified live, as shown above. The remaining rows
  were not re-run because no code change in this pass affects them, and re-running all 23 was outside
  the minimal-change scope of this audit.

## 8. Related records

- [`EXPLORER_API_INTEGRATION_AUDIT.md`](./EXPLORER_API_INTEGRATION_AUDIT.md) — architecture, defect,
  and epistemic-safety findings this test evidence supports.
- [`../api/API_EXPLORER_INTEGRATION_MATRIX.md`](../api/API_EXPLORER_INTEGRATION_MATRIX.md) — canonical
  per-endpoint matrix.
- [`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](./FINAL_PLATFORM_ARCHITECTURE_AUDIT.md) — predecessor
  platform-wide audit and its own (still-accurate) browser-test record.

## 9. Final verification pass — 2026-08-14 (re-executed end to end)

This section records a complete re-execution in a fresh sandbox (PostgreSQL 16 apt package, clean
disposable `berean_test` database). Nothing below is copied from the sections above; every command
was run again and every observation was captured from the running system.

### 9.1 Commands and exit codes

| Command | Exit | Observed result |
|---|---|---|
| `npm ci` | 0 | dependencies installed |
| `npm run typecheck` | 0 | no diagnostics |
| `npm run lint` | 0 | no findings (`src/**/*.ts`, `tests/app/**/*.ts`) |
| `npm run build` | 0 | `tsc -p tsconfig.json` clean |
| `npm test` | 0 | **141 passed (5 files)** before the fix below; **142 passed** after the added regression test |
| `bash scripts/validation/run-postgres-validation.sh` | 0 | `All validation self-test cases passed.` (run twice: before and after the change) |
| `npx vitest run tests/app/documentation-links.test.ts` | 0 | 11 passed |
| `npx vitest run tests/app/openapi-coverage.test.ts` | 0 | 6 passed |
| `npx vitest run tests/app/explorer-contract.test.ts` | 0 | 27 passed |

Sequencing note from §4 was reconfirmed: the `phase28_ingestion` and `public` schemas must be
dropped (and `public` recreated) between `npm test` and the validation script in either direction.

### 9.2 Browser automation

The sandboxed Playwright MCP browser tool was again unavailable (`MCP request failed: Transport
closed`, then `MCPOAuthBrowserRequiredError: Browser-based OAuth required for
http://localhost:3100/mcp`). As in the earlier passes, real browser testing was performed instead
with Playwright 1.49.1 + Chromium Headless Shell 131.0.6778.33 installed under `/tmp/browsertest`
(outside the repository; `package.json` unchanged). The server was started with
`PORT=3210 npx tsx src/server.ts` against the database left by the validation script
(`36 of 36 datasets · 378 linked claims`).

An incidental confirmation of the deployed CSP: Playwright's `waitForFunction` polling failed with
`Refused to evaluate a string as JavaScript because 'unsafe-eval' is not an allowed source of
script`, i.e. the `script-src 'self'` policy is genuinely enforced in a real browser. The scripts
were rewritten to poll through the DOM instead.

### 9.3 Live prompt / workflow matrix (all rows LIVE_TESTED)

| # | Prompt / action | Observed result | Verdict |
|---|---|---|---|
| 1 | Search `Nikola Tesla` | 9 hits (citation, 2 claims, entity, event, evidence…), "9 matched records. Matches are not established claims." | PASS |
| 2 | Search `George Westinghouse` | 2 hits: evidence `EV_P37R_BARRETT_WESTINGHOUSE`, source identity `phase37r-barrett-george-westinghouse` | PASS |
| 3 | Search `World's Columbian Exposition` | 7 hits (events, sources); no narrative synthesis | PASS |
| 4 | Search `AC` | 25 bounded lexical hits, all labelled `MATCHED` | PASS |
| 5 | Search `DC` | 2 lexical hits (dataset + source record); no AC/DC comparison or verdict | PASS |
| 6 | Search `1893` | 25 bounded hits incl. "identity context unresolved" citation text | PASS |
| 7 | Search `Genesis` | 25 bounded citation hits | PASS |
| 8 | Search `zzzznonsenseterm999` | exactly "No represented records matched this keyword." | PASS |
| 9 | Open entity `Nikola Tesla` | sections "Source identities and reconciliation (1)", "Events (2)", "Claims (2)"; mapping status `ACTIVE` with justification and stored confidence `0.9800` | PASS |
| 10 | Expand graph neighborhood | exactly `entity:196 —PARTICIPANT→ event:122` and `→ event:123`; **0 self-loops** | PASS (F-EXP-01 fix holds) |
| 11 | Inspect claim + trace provenance | `CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT` → proposition → Evidence (2) `SOURCE_OBSERVATION`/`SUPPORTS` → citation → source record → dataset → source | PASS |
| 12 | Derived claim `CLAIM_MT_ENOSH_YEAR_DERIVED` | `DERIVED_CLAIM`, Derivation method/assumptions shown, **no evidence or citation invented**, competing `CONTRADICTS` relation to `CLAIM_LXX_ENOSH_YEAR_DERIVED` preserved | PASS |
| 12b | Derived claim `CLAIM_XSRC_ADAM_FATHER_SETH_SHARED_DERIVED` | cross-source derivation rendered as derivation, assumptions state the differing numerals remain separate competing claims | PASS |
| 13 | Superseded claim `CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT` | `SUPERSEDED` badge, supporting evidence retained, `SUPERSEDES` relation shown; not deleted, not promoted | PASS |
| 14 | Search `Edison` | 4 hits incl. `Source identity · phase37r-directory-edison-name` and the "identity context unresolved" citation; no person record asserted | PASS |
| 15 | Research "Who participated in represented events?" | `CAPABILITY: ESTABLISHED`, 50 bounded results, sections Answer / What Berean Establishes (50) / Sources (1) | PASS |
| 16 | Research "Prove that alternating current is true" | `NOT REPRESENTED`, 0 results, "Absence of representation is not a denial…" | PASS |
| 17 | Research "What did the exhibits confirm about AC?" | `NOT REPRESENTED`, 0 results | PASS |
| 18 | Research `ageAtFatherhoodYears` | `UNRESOLVED`, 14 results split into Establishes (7) / Unresolved (1) / Evidence (6) / Sources (2) | PASS |
| 19 | Research "Which unicorn attended the exposition?" | `NOT REPRESENTED` with non-denial text | PASS |
| 20 | Research with empty scope | client blocks submission and shows "No scope selected…" (button disabled until a dataset is selected) | PASS |
| 21 | Dashboard / Genesis coverage / sources | rendered; Genesis locators still report `populated:false, source_unavailable:true` rather than absence of the text | PASS |
| 22 | Administrative flow through the UI | DOM scan for admin/ingest/token/delete/approve/reject affordances returned **0** | N/A (intentionally unsupported) |
| 23 | XSS probe `<img src=x onerror=alert(1)>` | 0 injected nodes, no alert, container HTML `<p class="empty">No represented records matched this keyword.</p>` | PASS |
| A1 | Search `Adam` | 13 hits, all labelled `MATCHED` (incl. the superseded draft claim) | PASS |
| A2 | Search `Seth` | 25 bounded hits | PASS |
| A3 | Research "What is represented about Adam and Seth?" | `NOT REPRESENTED` + non-denial text (no registered predicate matched) — no fabricated summary | PASS |
| A4 | Research "Which scholarly interpretations are represented?" | `NOT REPRESENTED` + non-denial text | PASS |
| A5 | Research "Who won the AC/DC current war?" | `NOT REPRESENTED`, 0 results — no winner, no ranking, no causal conclusion | PASS |
| A6 | Research "What derived relationships are represented?" | `NOT REPRESENTED` + non-denial text | PASS |

Across the whole session: **0 console errors, 0 page errors**, and the only network calls were the
documented compatibility endpoints (`/api/research/scope`, `/api/search`, `/api/research`,
`/api/entities/{id}`, `/api/claims/{id}`, `/api/provenance/claims/{id}`, `/api/graph`,
`/api/dashboard/quality`, `/api/genesis/coverage`, `/api/sources`). No `/api/v1` call, no
`Authorization` header, no request outside the origin.

### 9.4 Accessibility / UX observations (measured in the browser)

Measured from the live DOM: `documentElement.lang="en"`, single `<h1>` "Project Berean Explorer",
`HEADER`/`MAIN`/`NAV` landmarks present, **0** form controls without a `<label>` or `aria-label`,
**0** buttons without an accessible name, `aria-live` regions on `#researchStatus`, `#scopeOptions`,
`#researchResults`, `#searchStatus`, `#graphText`, and `role="status"` on `#searchStatus` and
`#researchStatus`. Loading/empty/error states were each observed live (loading text while a detail
loads, empty state for `NO_MATCH`, error copy path in `fetchJson`). No automated accessibility
scanner (axe-core/Lighthouse) exists in the repository and none was added; contrast and screen-reader
behavior remain unverified.

### 9.5 Error-path and header probes

```
GET /api/entities/999999            → 404 {"error":"entity not found"}
GET /api/entities/abc               → 400 {"error":"entityId must be an integer"}
GET /api/claims/999999              → 404 {"error":"claim not found"}
GET /api/graph?nodeType=bogus&…     → 400 {"error":"nodeType must be entity or claim …"}
GET /api/search   (no q)            → 400 {"error":"query parameter q is required"}
POST /api/research {"question":""}  → 400 {"error":"question is required and must be at most 1000 characters"}
GET /api/provenance/claims/999999   → 200 {"claim_present":false,"classification":"CLAIM_NOT_REPRESENTED",…}  (documented compatibility behavior)
GET /api/v1/nope                    → 404 {"error":{"code":"NOT_FOUND",…}}
GET /  headers                      → CSP default-src 'self'; script-src 'self'; …; X-Content-Type-Options: nosniff; Referrer-Policy: no-referrer; no X-Powered-By
```

One defect was found here and fixed: `GET /api/nope` returned **200 text/html** (the Explorer shell)
and `POST /api/unknown` returned Express' default HTML 404. See F-EXP-03 in
[`EXPLORER_API_INTEGRATION_AUDIT.md`](./EXPLORER_API_INTEGRATION_AUDIT.md) §7. After the fix:
`GET /api/no-such-endpoint → 404 application/json {"error":"route not found"}` and `GET / → 200
text/html` (shell unchanged). The full live matrix in §9.3 was re-run after the fix with identical
results and 0 console/page errors.

### 9.6 Limitations of this pass

- The Playwright MCP browser tool remained unavailable; a locally installed Playwright/Chromium was
  used instead (recorded above) — real browser, not the sandboxed tool.
- No automated accessibility scanner and no visual/responsive regression tooling exists in the
  repository; none was added. Contrast ratios, screen-reader output, and small-viewport layout are
  therefore unverified.
- The corpus contains only `DIRECT_SOURCE_CLAIM`/`DERIVED_CLAIM` types and `ACTIVE`/`SUPERSEDED`
  statuses, so scholarly-candidate and unresolved *claim-level* presentation could only be exercised
  through the research classifications (row 18) and the `CONTRADICTS`/`SUPERSEDES` claim relations
  (rows 12, 13), not through a dedicated scholarly claim row.
- No load, concurrency, or long-running-job testing was performed; queued-job and administrative
  behavior remains covered by `tests/app/app.test.ts` and `tests/app/phase28-ingestion.test.ts`
  rather than by live Explorer workflows (the Explorer exposes no administrative surface).

## 10. Constrained Explorer maturity remediation verification (2026-08-14, this change set)

### 10.1 Commands executed and outcomes

| Command | Exit | Observations |
|---|---|---|
| `npm ci` | 0 | 287 packages installed, 0 vulnerabilities |
| `npm run typecheck` | 0 | `tsc --noEmit` clean |
| `npm run lint` | 0 | ESLint clean |
| `npm run build` | 0 | `tsc -p tsconfig.json` clean |
| `npm test` (first run) | 1 | failed with `relation "source_type" already exists` due pre-existing schema state |
| `psql ... DROP SCHEMA IF EXISTS phase28_ingestion; DROP SCHEMA IF EXISTS public; CREATE SCHEMA public;` | 0 | required reset applied |
| `npm test` (after reset) | 0 | 5 files, 143 tests passed |
| `npx vitest run tests/app/documentation-links.test.ts` | 0 | 11 passed |
| `bash scripts/validation/run-postgres-validation.sh` | 0 | completed; `All validation self-test cases passed.` |
| `npx vitest run tests/app/explorer-contract.test.ts tests/app/app.test.ts` | 0 | affected Explorer/API tests passed (91 tests) |

### 10.2 Implemented behavior checks covered by tests

- Explorer shell now includes the "How to interpret Berean results" guidance and explicit
  `NO_MATCH` / `NOT_REPRESENTED` distinction (`tests/app/app.test.ts`).
- Explorer client wording keeps `NO_MATCH` and `NOT_REPRESENTED` distinct and replaces the
  ambiguous "What Berean Establishes" heading with "Directly source-backed claims"
  (`tests/app/explorer-contract.test.ts`).
- Explorer↔API compatibility-route contract coverage remains enforced (`tests/app/explorer-contract.test.ts`).

### 10.3 Browser limitation for this change set

No browser automation was run in this constrained pass. Existing browser evidence for Explorer
runtime behavior remains documented in §9 above; this pass relied on focused + full automated tests
and did not claim additional live-browser verification.
