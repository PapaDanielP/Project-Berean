# Documentation Governance, Consolidation, and Integrity Audit

**Status:** ACTIVE — current documentation governance audit
**Scope:** Repository-wide documentation authority, placement, duplication, link integrity, and
API/OpenAPI documentation coverage
**Authority:** REVIEW / AUDIT record. It does not supersede implementation, schema, executable
tests, or the authoritative documents listed in [`../README.md`](../README.md)
**Audit date:** 2026-08-14
**Predecessor:** [`REPOSITORY_CONSOLIDATION_REPORT.md`](./REPOSITORY_CONSOLIDATION_REPORT.md)
**Supersedes:** the earlier 2026-08-14 governance pass previously recorded at this path; its
findings (authority model, category reporting, historical preservation, verification log) are
carried forward here and re-measured, so this file remains the single current governance audit.

## 1. Executive summary

The repository was audited in full — every tracked file, not only `docs/`. The documentation
hierarchy established by the predecessor consolidation pass is intact and, with the exceptions
recorded below, accurate.

Findings:

- **Structure:** the canonical hierarchy (`docs/00-project` … `docs/07-review`, `docs/api`,
  `docs/phases`) is complete and populated. No empty, redundant, or competing documentation
  directory exists. No obsolete root-level architecture document exists.
- **Authority:** one current authority exists for each major subject (§3). No competing current
  architecture, repository-structure, domain-model, schema, or API document was found.
- **Links:** all 80 tracked Markdown files were scanned. **0 broken local Markdown links** and
  **0 stale path references** were found. The pre-existing link test only covered `docs/`; it now
  covers the whole repository, so this result is enforced rather than asserted.
- **API:** the implemented route surface, the OpenAPI document, and the canonical API docs agree.
  **0 undocumented endpoints** and **0 documented-but-unimplemented endpoints**.
- **Corrections made:** the "Tests / evidence" column of `docs/api/API_CAPABILITY_MATRIX.md`
  overstated coverage for 3 routes and understated it for 3 routes, and
  `docs/api/OPENAPI_GAP_REPORT.md` reported "implemented but untested: none identified" in a way
  that could be read as a behavior-level claim. Both were corrected against measured evidence (§7).
- **Open item:** 12 implemented routes are documented and route-surface-enforced but have no
  behavior-level test. This is a **test-coverage** gap, reported rather than closed, because
  closing it requires implementation changes outside a documentation audit (§13).

No schema semantics, runtime behavior, API behavior, predicate semantics, or validation fixture
semantics were changed by this audit.

## 2. Method and ground truth

Authority order applied is the one defined in [`../README.md`](../README.md): implementation,
schema, executable tests, and validation scripts first; then current authoritative documentation;
then reference, phase, validation, and review material.

Ground truth inspected for the API sections: `src/app.ts`, `src/api/v1.ts`, `src/api/openapi.ts`,
`src/administration/routes.ts`, `src/administration/service.ts`, `src/administration/repository.ts`,
`src/auth.ts`, `src/repository.ts`, `src/types.ts`, `src/ingestion/**`, `schema/sql/**`,
`tests/app/**`, and the live Express route stack of `createApp()`.

Route facts in this report were **measured**, not read from documentation: the application's route
stack and the object returned by `openApiDocument()` were introspected directly (the same mechanism
`tests/app/openapi-coverage.test.ts` uses), and the result was cross-referenced against the paths
exercised by the test suites.

## 3. Authority model (one current authority per subject)

| Subject | Current authority | Competing current document found? |
|---|---|---|
| Mission and invariants | `docs/00-project/CHARTER.md` | No |
| Conceptual architecture | `docs/01-architecture/ARCHITECTURE.md` | No |
| Workflow vs authoritative knowledge | `docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md` | No |
| Repository structure and placement | `docs/01-architecture/REPOSITORY_STRUCTURE.md` | No |
| Domain semantics | `docs/02-domain/DOMAIN_MODEL.md` | No |
| Physical schema | `docs/03-schema/INFORMATION_SCHEMA.md` (schema itself: `schema/sql/**`) | No |
| API surface | `docs/api/API_DEVELOPER_GUIDE.md` (+ the `docs/api/` set) | No |
| OpenAPI status | `docs/api/OPENAPI_GAP_REPORT.md` | No |
| Phase history | `docs/phases/README.md` (legacy index: `docs/04-data/README.md`) | No |
| Validation methodology | `docs/05-validation/VALIDATION.md` (executable: `scripts/validation/`, `tests/validation/`) | No |
| Documentation authority map | `docs/README.md` | No |

Behavioral authority remains the implementation, schema, executable tests, and validation scripts.
Every document above explains that behavior; none of them override it.

## 4. Repository inventory

80 tracked Markdown files, plus executable and data artifacts.

| Location | Count | Classification |
|---|---|---|
| `README.md` (root) | 1 | Current entry point |
| `docs/README.md` | 1 | Documentation authority map |
| `docs/00-project/` | 4 | Current project framing (`CHARTER`, `PROJECT_OVERVIEW`), development reference (`DEVELOPER_GUIDE`), historical plan (`WEB_APP_MVP_PLAN`) |
| `docs/01-architecture/` | 4 | Authoritative architecture, workflow boundary, repository structure; reference adapter note |
| `docs/02-domain/` | 1 | Authoritative domain model |
| `docs/03-schema/` | 1 | Authoritative physical schema |
| `docs/04-data/` | 32 | Legacy Phase 6–32 records + data policy/population reference; historical |
| `docs/05-validation/` | 1 | Authoritative validation methodology |
| `docs/06-decisions/` | 3 | Decision records (ADR-0001…0003) |
| `docs/07-review/` | 4 → 5 | Review/audit records (this file added) |
| `docs/api/` | 8 | Canonical API documentation set — the sole API documentation location |
| `docs/phases/` | 8 | Phase 33–37R/37B records + canonical phase index; historical |
| `data/**` | 11 | Source metadata, acquisition manifests, candidate/ingestion input documentation |
| `.github/copilot-instructions.md` | 1 | Contributor/agent guidance |
| `schema/sql/**`, `tests/**`, `scripts/**`, `src/**` | — | Executable artifacts; authoritative for behavior, not relocated |

Non-Markdown documentation-bearing artifacts (`data/external/*/MANIFEST.yaml`,
`data/external/stepbible/ACQUISITION_MANIFEST.yaml`) were inspected and left in place: they are
acquisition inputs consumed by `tests/validation/stepbible-acquisition-manifest.sh`, not prose
documentation, and moving them would break executable checks.

## 5. Duplicate analysis

No duplicate **current** documentation was found. Overlaps that exist are intentional and were
retained:

| Overlap | Decision | Reason |
|---|---|---|
| Phase history split between `docs/04-data/` and `docs/phases/` | Retained, both indexed | Two historical numbering conventions. Merging would rewrite historical paths cited by other records. |
| `docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md` vs this audit | Both retained; this file is current, that file is the predecessor pass | Superseding an audit by deleting it would destroy the evidence of what was found and when. |
| `docs/00-project/WEB_APP_MVP_PLAN.md` vs `docs/07-review/WEB_APP_MVP_REPORT.md` | Both retained, now classified as historical plan / review record | Plan and outcome are distinct historical artifacts. |
| API topics split across 8 files in `docs/api/` | Retained | Different subjects (surface, matrix, boundaries, limits, security, workflows, OpenAPI status, verification), not restatements. Each is linked from `docs/README.md`. |
| Epistemic boundaries appear in `docs/api/API_EPISTEMIC_BOUNDARIES.md`, `API_LIMITATIONS.md`, and the ADRs | Retained | Boundary statements are enforced invariants; restating them at the point of use is a safety property, and the wording is consistent. |

No document was deleted, merged, or replaced by a pointer during this audit.

## 6. Misplaced, stale, and missing documentation

- **Misplaced:** none found. No API documentation exists outside `docs/api/`; no executable SQL,
  fixture, or test was found inside a documentation directory; no documentation was found
  masquerading as an executable artifact.
- **Stale:** no document describing removed functionality was found. All referenced commands
  (`npm run typecheck|lint|build|test|ingest`, `scripts/validation/run-postgres-validation.sh`)
  exist and execute.
- **Missing from the indexes (fixed):** `docs/00-project/WEB_APP_MVP_PLAN.md` and
  `docs/07-review/COPILOT_PEER_REVIEW_PROMPT.md` existed but were referenced by no index. Both are
  now classified and linked from `docs/README.md`.
- **Missing documentation of implemented functionality:** none found. Administration, discovery,
  ingestion, identity review, derivation, jobs, audit, authentication, authorization, idempotency,
  and optimistic concurrency are all documented in the `docs/api/` set and in
  `docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`.

## 7. API documentation audit

Measured surface: **51 registered Express route/method pairs** — 49 addressable routes plus 2
wildcard fallback layers (`GET *` Explorer shell; `ALL /api/v1/*` → `501 NOT_REPRESENTED`). The
OpenAPI document declares **50 operations across 50 paths**: the single Express layer
`GET /api/v1/search/:resource?` is documented as two addressable paths, and the 2 fallbacks are
described under `x-berean-fallback-routes` rather than as paths.

| Comparison | Result |
|---|---|
| Implemented and documented | 49 addressable routes + 2 fallbacks |
| Implemented but undocumented | 0 |
| Documented but not implemented | 0 |
| OpenAPI-only | 0 |
| Documented and behavior-tested | 37 addressable routes + 2 fallbacks |
| Documented but behavior-untested | 12 (enumerated in `docs/api/OPENAPI_GAP_REPORT.md`) |

Auth/authz, mutation vs read-only, async/job, idempotency, optimistic concurrency, audit, epistemic
consequence, `NOT_REPRESENTED`, `NO_MATCH`, and validation-error behavior are documented per route
in `docs/api/API_CAPABILITY_MATRIX.md`, `docs/api/API_DEVELOPER_GUIDE.md`, and
`docs/api/API_SECURITY_MODEL.md`, and are additionally asserted per operation by
`tests/app/openapi-coverage.test.ts` (every write operation must declare `security`,
`x-berean-minimum-role`, `x-berean-audit`, `x-berean-transaction`, and an epistemic boundary note).

### Documentation-vs-evidence discrepancies found and corrected

| # | Document | Claim | Measured evidence | Correction |
|---|---|---|---|---|
| 1 | `API_CAPABILITY_MATRIX.md` | `GET /health` evidence: `tests/app/app.test.ts` | No suite requests `/health`; only `/api/v1/health` is asserted (`tests/app/app.test.ts:103`) | Downgraded to code-traced, with the reason stated |
| 2 | `API_CAPABILITY_MATRIX.md` | `GET /api/v1/:resource/:id` evidence: `tests/app/app.test.ts`, code-traced | No suite issues a generic single-resource read | Downgraded to code-traced only |
| 3 | `API_CAPABILITY_MATRIX.md` | `GET /api/v1/:resource` evidence: `tests/app/app.test.ts`, code-traced | Tested at `tests/app/app.test.ts:105` (`/api/v1/entities`) | Upgraded to tested, with the exercised path named |
| 4 | `API_CAPABILITY_MATRIX.md` | `GET /api/v1/registry/:registry` evidence: manual only | Tested at `tests/app/app.test.ts:106` and in `openapi-coverage.test.ts` (307 redirect) | Upgraded to tested |
| 5 | `API_CAPABILITY_MATRIX.md` | `POST /api/v1/research` evidence: code-traced | Tested at `tests/app/app.test.ts:1423` | Upgraded to tested |
| 6 | `API_CAPABILITY_MATRIX.md` | `POST /api/v1/research-topics` evidence: code-traced, manual | Tested at `tests/app/app.test.ts:138` | Upgraded to tested |
| 7 | `API_CAPABILITY_MATRIX.md` | `POST /api/v1/jobs/:id/cancel` evidence: manual only | Tested at `tests/app/app.test.ts:1411` | Upgraded to tested |
| 8 | `OPENAPI_GAP_REPORT.md` | "Implemented but untested endpoints: none identified at route-surface level" | True of the route surface; 11 routes have no behavior assertion | Replaced with explicit categories and the enumerated 11-route list |

No runtime, route, or OpenAPI source was modified to change any count above.

### Administration documentation

Corpus, dataset, source, source record/citation, discovery, candidate/review, identity mapping,
ingestion, claim/evidence, derivation, validation, job control, export, and audit domains are each
documented in the "Administrative completeness matrix" of `docs/api/API_CAPABILITY_MATRIX.md` with
database representation, API exposure, SQL/script-only boundaries, persistence, authorization,
audit, async/idempotency, and human-review requirements. The workflow-state versus
authoritative-knowledge distinction is stated per row and elaborated in
`docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`. No correction was required.

## 8. OpenAPI status

`GET /openapi.json` serves an OpenAPI 3.1 document that is byte-identical to the in-process object
and complete with respect to the registered route surface in both directions. The explicit
category breakdown (`IMPLEMENTED_AND_DOCUMENTED`, `IMPLEMENTED_BUT_UNDOCUMENTED`,
`DOCUMENTED_BUT_NOT_IMPLEMENTED`, `IMPLEMENTED_BUT_UNTESTED`, `DOCUMENTED_AND_TESTED`,
`OPENAPI_ONLY`) now lives in [`../api/OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md).

Route-surface completeness is not evidence that every response shape matches runtime. That
limitation is stated in the gap report and is not claimed away here.

## 9. Broken-link and stale-path audit

Scope: all 80 tracked Markdown files (root, `docs/**`, `data/**`, `.github/**`), plus path
references appearing in TypeScript sources, SQL, shell scripts, and the CI workflow.

| Check | Result |
|---|---|
| Local Markdown links resolving to an existing file or directory | 80 files scanned, **0 broken** |
| References to moved/deleted paths (`docs/`, `src/`, `tests/`, `scripts/`, `schema/`, `data/`) in Markdown, code, scripts, and workflows | **0 stale** |
| References to the obsolete canonical documentation directories retired by the predecessor consolidation (enumerated in `tests/app/documentation-links.test.ts` as `OBSOLETE_PATH_FRAGMENTS`) | **0** outside the predecessor report, which discusses them as negative examples |

Because 0 broken links were found, no link was rewritten and no historical quoted path was altered.
The improvement made is enforcement: `tests/app/documentation-links.test.ts` previously resolved
links only within `docs/`; it now resolves local Markdown links across the entire repository, so a
future broken link in `README.md`, `data/**`, or `.github/**` fails the suite.

## 10. Historical preservation

Deliberately retained, unmodified:

- All 32 legacy Phase 6–32 records in `docs/04-data/` and all 7 Phase 33–37R/37B records in
  `docs/phases/`, including Phase 28, 36, 37, and 37R/37B conclusions.
- `docs/06-decisions/ADR-0001…0003`.
- `docs/07-review/REMEDIATION-REPORT.md`, `WEB_APP_MVP_REPORT.md`,
  `COPILOT_PEER_REVIEW_PROMPT.md`, and `REPOSITORY_CONSOLIDATION_REPORT.md`.
- `docs/00-project/WEB_APP_MVP_PLAN.md`.
- All `data/**` source metadata, manifests, and candidate CSVs.

No historical conclusion was rewritten, no phase record was merged or deleted, and no superseded
validation result was removed. Two historical documents gained an index entry describing what they
are; their content is untouched.

## 11. Changes made by this audit

| File | Change | Justification |
|---|---|---|
| `docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md` | Created (replacing the earlier pass at this path) | Required audit report; kept as one current governance authority rather than two competing audits |
| `docs/api/OPENAPI_GAP_REPORT.md` | Modified | Added the six explicit coverage categories with measured counts; replaced an ambiguous "none identified" statement with the enumerated behavior-untested set |
| `docs/api/API_CAPABILITY_MATRIX.md` | Modified | Corrected 7 "Tests / evidence" entries against measured test coverage; added an evidence-column legend defining tested / code-traced / manual |
| `docs/README.md` | Modified | Indexed this audit, `COPILOT_PEER_REVIEW_PROMPT.md`, and `WEB_APP_MVP_PLAN.md`; marked the predecessor consolidation report as such |
| `tests/app/documentation-links.test.ts` | Modified | Extended local-link resolution from `docs/` to the whole repository, and asserted that this audit is present and indexed |

Files moved: **none**. Files deleted: **none**. No `src/**`, `schema/**`, `scripts/**`,
`tests/fixtures/**`, `tests/validation/**`, or `data/**` file was changed.

## 12. Files intentionally untouched

- All executable artifacts: `src/**`, `schema/sql/**`, `scripts/**`, `tests/fixtures/**`,
  `tests/validation/**`, and `tests/app/app.test.ts`, `openapi-coverage.test.ts`,
  `phase28-ingestion.test.ts`.
- All phase records, ADRs, prior review records, and `data/**`.
- `.github/workflows/postgres-validation.yml` and `.github/copilot-instructions.md`.

## 13. Remaining issues

1. **Behavior-test coverage gap (open, reported not closed).** 12 implemented routes have no
   behavior-level assertion (`GET /health`, `GET /api-docs`, `GET /api/sources`,
   `GET /api/sources/{sourceId}`, `GET /api/dashboard/quality`, `GET /api/v1/schema`,
   `GET /api/v1/research/capabilities`, `GET /api/v1/graph/entity/{id}`,
   `GET /api/v1/{resource}/{id}`, `POST /api/v1/ingestion-jobs`, `POST /api/v1/export-jobs`,
   `POST /api/v1/jobs/{id}/retry`).
   - *Evidence:* no suite references these paths; the route surface is nonetheless enforced.
   - *Insufficiency:* documented behavior for these routes rests on code tracing and one-time
     manual observation, neither of which is re-executed by CI.
   - *Minimal proposal:* add response-shape assertions for these routes to `tests/app/app.test.ts`.
   - *Impact:* test-only; no runtime, schema, or documentation-authority change.
   - *Not implemented here* because it is an implementation change outside a documentation audit.
2. **Manual verification entries are not re-executed.** Several matrix rows cite
   "manual 2026-08-13". They are now labelled as non-CI evidence rather than promoted; converting
   them into automated assertions is the same work item as (1).
3. **Job execution remains absent by design.** Discovery, ingestion, validation, and export routes
   persist queue state only; execution requires a SYSTEM worker that this repository does not ship.
   This is documented, not a defect, and is recorded here so it is not mistaken for a gap closed by
   this audit.

## 14. Integrity confirmation

- Exactly one current authority exists per major subject (§3).
- API documentation remains solely under `docs/api/`.
- All historical phase and validation records are preserved unmodified.
- Repository-structure documentation matches the actual repository.
- All local Markdown links resolve, now enforced repository-wide.
- Discovery is not represented as evidence; evidence is not represented as truth; claims are not
  represented as truth; `PROPOSED` identities are not represented as reconciled;
  derived results are not represented as source assertions; `NOT_REPRESENTED` / `NO_MATCH` are not
  represented as falsity.
- No schema semantics, API semantics, runtime architecture, predicate semantics, or validation
  fixture semantics were changed.

## 15. Verification commands and results

Commands below were executed on 2026-08-14 from the repository root unless otherwise noted. The
local PostgreSQL 16 service was started, a disposable `berean_test` database owned by `runner` was
created, and `DATABASE_URL` was exported from `/tmp/berean-env.sh`. The test schemas were reset
before database-backed verification by dropping `phase28_ingestion` and `public`, recreating
`public`, and granting access to `runner`.

| Command | Result |
|---|---|
| `npm ci` | PASS — installed locked dependencies; npm audit reported 0 vulnerabilities. |
| `npm run typecheck` | PASS. |
| `npm run lint` | PASS. |
| `npm run build` | PASS. |
| `npx vitest run tests/app/documentation-links.test.ts` | PASS — 1 file, 10 tests. |
| `npx vitest run tests/app/openapi-coverage.test.ts` | PASS — 1 file, 6 tests. |
| `npm test` | PASS — 4 files, 112 tests (`documentation-links`, `openapi-coverage`, `phase28-ingestion`, `app`). |
| `bash scripts/validation/run-postgres-validation.sh` | PASS — full PostgreSQL validation completed with exit code 0. |
| `git grep -n 'docs/' -- '*.md' ':!docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md'` | PASS — active `docs/` references reviewed; no stale active paths found. |
| `git grep -n -E 'docs/(architecture\|data\|administration\|ingestion\|research\|history/phases\|development\|operations)/' -- '*.md' ':!docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md'` | PASS — no obsolete live documentation path references found. |

Initial note: before `npm ci`, `npm run typecheck` failed because the fresh checkout lacked
installed dependencies (`express`, `pg`, `@types/node`, and related packages). After installing the
existing lockfile dependencies, the command passed without source changes.

GitHub Actions note: the recent PostgreSQL reference validation workflow run was inspected with the
GitHub Actions API. The listed run had conclusion `action_required`; fetching failed-job logs
returned "No failed jobs found in this workflow run", so there was no failing job log to remediate.

## 16. Final classification

**DOCUMENTATION GOVERNANCE: PASS WITH NON-BLOCKING NOTES**

Non-blocking notes:

1. The OpenAPI route surface is complete and enforced, but 12 documented routes remain
   behavior-untested as listed in [`../api/OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md).
2. Queue-backed discovery, ingestion, validation, and export routes persist workflow state only;
   this repository does not ship a `SYSTEM` worker to execute queued jobs.
3. Several API evidence rows still cite manual 2026-08-13 observations. They are labelled as manual
   evidence and should become automated tests in a future engineering task if CI-level behavior
   coverage is desired.
