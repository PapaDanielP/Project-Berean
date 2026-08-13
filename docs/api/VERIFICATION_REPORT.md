# Verification / Test Report

## Scope and method

This report records **commands actually run** and **manual API checks actually performed** on 2026-08-13. No results below are simulated.

## Commands run

### PostgreSQL setup used for verification

A local PostgreSQL 16 service was started and a disposable `berean_test` database was created. A repository-local shell file (`.copilot_pg_env.sh`) exported:

- `PGUSER=runner`
- `PGPASSWORD=runner`
- `DATABASE_URL=******localhost:5432/berean_test`

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
| Unmatched search behavior | PASS | `/api/search?q=Nikola%20Tesla&limit=5` returned regular search hits; `/api/v1/search/entities?q=adam&limit=3` returned an empty result set because of the current pluralization bug documented below. |

## Discrepancies found between implementation and expected or previously implied behavior

1. **Stale `If-Match` returns 409, not 412.** The code uses `409 STALE_VERSION` for optimistic-concurrency failure.
2. **No semantic ETag contract exists.** `If-Match` is accepted, but the API does not return a resource-version `ETag` for concurrency.
3. **`GET /api/v1/search/:resource?` resource filtering is buggy for several plurals.** Example: `/api/v1/search/entities?q=adam&limit=3` returned `classification: "MATCHED"` and `results: []` because `entities` is singularized to `entitie`.
4. **Unsupported admin list resources return 500.** `GET /api/v1/admin/not-real?limit=5` returned the generic `internal_error` envelope.
5. **Missing-claim behavior differs across provenance routes.** `/api/provenance/claims/:id` returned `200 { traversal: [] }`, while `/api/v1/provenance/claim/:id` returned `404 NOT_FOUND`.
6. **OpenAPI is incomplete relative to implementation.** See [`OPENAPI_GAP_REPORT.md`](./OPENAPI_GAP_REPORT.md).

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
- `schema/sql/*.sql`
- `tests/app/*.test.ts`
- `tests/fixtures/*.sql`
- `tests/validation/*`
- `scripts/validation/run-postgres-validation.sh`
- `scripts/acquisition/fetch-stepbible.sh`
- relevant existing docs under `docs/**`
- `data/candidates/*`

## Conclusion

All required automated verification commands passed. The API documentation in `docs/api/*.md` was updated to match **current code behavior**, including the discrepancies above rather than idealized behavior.
