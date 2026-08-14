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

Result after cleaning the schema: **114 passed (4 test files)** —
`tests/app/documentation-links.test.ts` (11), `tests/app/openapi-coverage.test.ts` (6),
`tests/app/phase28-ingestion.test.ts` (35), `tests/app/app.test.ts` (62, including the new graph
self-loop regression test). A fifth file, `tests/app/explorer-contract.test.ts` (27 tests, added in
this pass), was run standalone as `npx vitest run tests/app/explorer-contract.test.ts` and passed;
it also passes as part of the full suite once the database is clean (verified in the final
pre-PR run recorded in `git`/CI history for this branch).

**Remaining test-coverage gaps** (unchanged from the predecessor audit, not closed in this pass, and
listed here rather than hidden): 12 documented routes have no behavior-level test (F-11 in
`FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`); `src/public/app.js` is outside `npm run lint` and
`npm run typecheck` (F-12); the resource-filtered-search `limit`-before-filter defect (F-01) has no
regression test yet because it is outside this audit's scope (not Explorer-reachable).

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
