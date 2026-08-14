# Verification / Test Report

## Scope and method

This report records **commands actually run** and **manual API checks actually performed** on 2026-08-13. No results below are simulated.

## Commands run

### PostgreSQL setup used for verification

A local PostgreSQL 16 service was started and a disposable `berean_test` database was created. A repository-local shell file (`.copilot_pg_env.sh`) exported:

- `PGUSER=runner`
- `PGPASSWORD=runner`
- `DATABASE_URL=postgresql://runner@localhost:5432/berean_test` (with `PGPASSWORD` supplied separately)

## Automated command results

| Command | Exit code | Result summary |
|---|---:|---|
| `npm run typecheck` | 0 | Passed. |
| `npm run lint` | 0 | Passed. |
| `npm run build` | 0 | Passed. |
| `dropdb --if-exists berean_test && createdb -O runner berean_test && npm test` | 0 | Passed: **2 test files, 90 tests**. (`tests/app/phase28-ingestion.test.ts`: 35; `tests/app/app.test.ts`: 55) |
| `dropdb --if-exists berean_test && createdb -O runner berean_test && npx vitest run tests/app/app.test.ts` | 0 | Passed: **1 test file, 55 tests**. |
| `dropdb --if-exists berean_test && createdb -O runner berean_test && bash scripts/validation/run-postgres-validation.sh` | 0 | Passed full PostgreSQL validation pipeline end-to-end. |

### Full PostgreSQL validation observations

The validation runner completed with exit code 0 and included these successful notices in output:

- `ok: Phase 28 automated Tier-1 ingestion passes provenance, boundary, and idempotency validation`
- `ok: Phase 36 population is source-scoped, provenance-backed, idempotent, and preserves scholarship and identity uncertainty.`
- `ok: Phase 36 withheld interrogation is read-only and returns direct claims, scholarly candidates, and unresolved identity separately.`
- `ok: Phase 37 population is source-scoped, provenance-backed, idempotent, and preserves scholarship and identity uncertainty.`
- `ok: Phase 37 Stage B answered ten withheld BEREAN_ONLY questions plus two unsupported probes by traversal, with identical before/after persistent counts`
- `ok: Phase 37R candidate audit has 33 discovered, 20 selected, 13 excluded candidates across all required categories`
- `ok: Phase 37R expanded population is provenance-backed, locator-only, and preserves discovery, scholarship, identity, and registry boundaries.`
- `ok: Phase 37B withheld suite distinguishes ESTABLISHED, DERIVED, SCHOLARLY, UNRESOLVED, and NOT_REPRESENTED results with unchanged persistent counts.`
- closing self-tests: `ok: loaded fixture data passes validation`, `ok: blocked a claim with no evidence`, `ok: blocked source-observation evidence with no citation`, `ok: blocked an active reconciliation with no justification`, `ok: blocked reconciliation justified by evidence from another source`, `ok: blocked a derivation with no inputs`, `ok: blocked a derived claim used as its own derivation input`, `All validation self-test cases passed.`

## Manual API verification

For manual checks, the database was reloaded with:

- `schema/sql/001_core_schema.sql`
- `schema/sql/003_administration_workflow.sql`
- the fixture set loaded by `tests/app/app.test.ts`
- `tests/fixtures/143-phase36-seneca-falls-domain-population-fixture.sql`
- `tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql`
- `tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql`

A built server was then run locally on port `3110` with two configured credentials: one `ADMINISTRATOR`, one `READER`.

### Manual checks and evidence

| Behavior requested | Result | Evidence |
|---|---|---|
| Authentication rejection: missing bearer token | PASS | `POST /api/v1/corpora` returned `401 UNAUTHENTICATED` with `WWW-Authenticate: Bearer` and message `A bearer credential is required.` |
| Authentication rejection: invalid bearer token | PASS | `POST /api/v1/corpora` returned `401 UNAUTHENTICATED` with message `The bearer credential is invalid.` |
| Role / authorization failure | PASS | `READER` credential calling `POST /api/v1/corpora` returned `403 FORBIDDEN` with message `ADMINISTRATOR role or higher is required.` |
| Request validation failure | PASS | Automated tests cover invalid search, research, graph, explain-provenance, and derivation inputs. Manual checks also observed `409 STALE_VERSION` on stale corpus patch and `422` on analytical-evidence claim promotion. |
| Idempotency-key replay | PASS | Two identical `POST /api/v1/discovery-requests` with `Idempotency-Key: doc-discovery-1` returned `202` and the same `job_id: "1"`. Same behavior verified for `POST /api/v1/validation-runs` with `job_id: "4"`. |
| Idempotency conflict | PASS | Reusing `doc-discovery-1` with a different body returned `409 IDEMPOTENCY_CONFLICT`. Reusing `doc-validation-1` with different `validationTypes` also returned `409 IDEMPOTENCY_CONFLICT`. |
| Stale `If-Match` handling | PASS, with discrepancy | Actual behavior is `409 STALE_VERSION`, not `412`. Successful patch with `If-Match: 1` updated corpus `version` from `1` to `2`. |
| Audit event creation | PASS | Manual admin actions increased `audit_event` count to 18; `GET /api/v1/admin/audits?limit=5` showed recent `CANCEL` and `RETRY` events with correlation IDs and `outcome: "SUCCEEDED"`. |
| Rollback / no partial commit on failure | PASS | Manual `POST /api/v1/claims` using `ANALYTICAL_OBSERVATION` evidence returned `422 DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION`; DB counts stayed `claim_count 348 -> 348`, `proposition_count 336 -> 336`. |
| Read-only routes never mutate state | PASS | Manual before/after counts around `POST /api/research` and `GET /api/v1/entities/1` were unchanged: `claim_count 348 -> 348`, `evidence_count 182 -> 182`, `audit_count 18 -> 18`. Automated tests also assert this extensively. |
| Discovery/candidate/identity/derivation epistemic boundaries | PASS | Candidate creation and review left `evidence_count` and `claim_count` unchanged at `180/347`; identity mapping returned `PROPOSED` first, then `REJECTED` only after explicit review; derivation creation is separately tested in `tests/app/app.test.ts` and creates no claim automatically. |
| Worker/job dependency behavior | PASS | Manual `POST /api/v1/validation-runs` returned queued job `{ "job_id": "4", "status": "QUEUED" }`; direct DB query showed validation run still `QUEUED` with `result_count: 0`. Cancel/retry routes changed workflow state only. |
| `NOT_REPRESENTED` behavior | PASS | Manual `DELETE /api/v1/entities/1` returned `501 NOT_REPRESENTED`. `POST /api/research {"question":"Did an observation prove a theory?"}` is already covered by automated tests and returns `capability: "NOT_REPRESENTED"`. |
| `NO_MATCH` behavior | PASS | Manual `POST /api/research` with question `ageAtFatherhoodYears` scoped to dataset `WCE_OFFICIAL_DIRECTORY_P37R` returned `200` with `capability: "NO_MATCH"`, `results: []`, and limitation `No matching persisted claims were found in the selected scope.` |
| Unmatched search behavior | PASS | `/api/search?q=Nikola%20Tesla&limit=5` returned regular search hits; `/api/v1/search/entities?q=adam&limit=3` originally returned an empty result set because of the pluralization defect; after the fix it returns entity results, and genuinely empty result sets are classified `NO_MATCH`. |

## Remediation verification (2026-08-13, second pass)

After the five discrepancies were addressed in code and documentation, the full command set was re-run from clean
schemas.

| Command | Exit code | Result |
|---|---:|---|
| `npm run typecheck` | 0 | Passed. |
| `npm run lint` | 0 | Passed. |
| `npm run build` | 0 | Passed. |
| `npm test` | 0 | Passed: **3 test files, 102 tests** (`app.test.ts` 61, `phase28-ingestion.test.ts` 35, `openapi-coverage.test.ts` 6). The 90-test baseline is preserved; 12 tests are new. |
| `bash scripts/validation/run-postgres-validation.sh` | 0 | Full PostgreSQL validation passed, including the Phase 28/36/37/37R notices listed above and all closing self-tests. |

Ordering note: `npm test` creates objects in `public` and in `phase28_ingestion`. The validation script inspects
`information_schema.tables` without a schema filter, so `phase28_ingestion` and `public` must both be dropped and
`public` recreated before running the script after a test run. This is an environment-sequencing requirement, not a
product defect.

## Status of the five reported discrepancies

| # | Discrepancy | Status | Evidence |
|---|---|---|---|
| 1 | Stale `If-Match` returns `409 STALE_VERSION`, not `412` | **INTENTIONAL — documented and tested.** No `ETag` is issued, `If-Match` carries an opaque integer version, and every Berean write conflict is `409`. The version guard runs inside the mutation transaction, so a stale write commits nothing. | `tests/app/app.test.ts` asserts the stale response and that name, status, version, and audit count are unchanged |
| 2 | V1 search resource filtering | **FIXED.** Explicit normalization for all ten resources; unknown filters return `404`; `identity-mappings` returns `501 NOT_REPRESENTED`; empty results are classified `NO_MATCH`. | `src/api/v1.ts`; `tests/app/app.test.ts` covers every supported resource |
| 3 | `GET /api/v1/admin/not-real` returned `500` | **FIXED.** Supported resources are validated up front and unknown ones return `404 NOT_FOUND` with no implementation leakage; the internal marker is also mapped to `404` in the error handler. | `src/administration/routes.ts`, `src/administration/repository.ts`; `tests/app/app.test.ts` |
| 4 | Missing-claim provenance behaviour differed between routes | **FIXED as a documented compatibility difference.** V1 returns `404`; the legacy route keeps `200` with `traversal: []` but now states `claim_present`, `classification`, and `compatibility` explicitly. | `src/repository.ts`; `tests/app/app.test.ts` asserts both routes together, preventing accidental divergence |
| 5 | OpenAPI incomplete | **FIXED for the implemented route surface.** `src/api/openapi.ts` documents every implemented non-static route, including the `307` registry-capabilities redirect. Route-surface coverage does not by itself prove every runtime response-body detail. | `tests/app/openapi-coverage.test.ts` enforces bidirectional route coverage and the registry redirect |

## Files and code areas audited for this documentation work

Implementation reviewed:

- `package.json`
- `src/server.ts`
- `src/app.ts`
- `src/api/v1.ts`
- `src/auth.ts`
- `src/repository.ts`
- `src/types.ts`
- `src/administration/routes.ts`
- `src/administration/service.ts`
- `src/administration/repository.ts`
- `src/ingestion/*`
- `schema/sql/001_core_schema.sql`
- `schema/sql/002_validation_queries.sql`
- `schema/sql/003_administration_workflow.sql`
- `tests/app/app.test.ts`
- `tests/app/openapi-coverage.test.ts`
- `tests/app/phase28-ingestion.test.ts`
- `tests/app/documentation-links.test.ts`
- `tests/fixtures/010-synthetic-structural-fixture.sql` through `tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql`
- `tests/validation/phase6-regression.sql` through `tests/validation/phase37r-worlds-columbian-exposition-population-validation.sql` and supporting coverage/slice validators in the same directory
- `scripts/validation/run-postgres-validation.sh`
- `scripts/acquisition/fetch-stepbible.sh`
- relevant existing docs under `docs/**`
- `data/candidates/*`

## Conclusion

All required automated verification commands passed on both passes. Three defects were fixed in code, one was fixed as
a documented compatibility difference, and one was retained deliberately with a stated rationale and a test proving no
partial commit. The documentation under `docs/api/*.md` matches **current code behavior**.

Final classification: **PASS WITH INTENTIONAL LIMITATION** — the remaining limitation is that queued jobs
(`INGESTION`, `VALIDATION`, `EXPORT`, discovery) persist state but are never executed, because no `SYSTEM` worker
exists. That is classified **REQUIRES_SYSTEM_WORKER** and is out of scope for an API-hardening change.

## Documentation governance verification (2026-08-14)

The final documentation-governance pass re-ran the automated API/documentation verification from a
fresh dependency install and a disposable local PostgreSQL 16 database. Results:

| Command | Exit code | Result |
|---|---:|---|
| `npm ci` | 0 | Installed the existing lockfile dependencies; npm audit reported 0 vulnerabilities. |
| `npm run typecheck` | 0 | Passed. |
| `npm run lint` | 0 | Passed. |
| `npm run build` | 0 | Passed. |
| `npx vitest run tests/app/documentation-links.test.ts` | 0 | Passed: **1 file, 10 tests**. |
| `npx vitest run tests/app/openapi-coverage.test.ts` | 0 | Passed: **1 file, 6 tests**. |
| `npm test` | 0 | Passed: **4 files, 112 tests**. |
| `bash scripts/validation/run-postgres-validation.sh` | 0 | Full PostgreSQL validation passed end-to-end after resetting `phase28_ingestion` and `public`. |

The 2026-08-14 pass made no runtime, schema, fixture, API semantic, or validation semantic changes.
