# Documentation Governance Audit

**Status:** ACTIVE — current documentation governance and integrity audit
**Scope:** Documentation authority, consolidation enforcement, API-documentation integrity, OpenAPI status, and local-link/path integrity.
**Authority:** REVIEW / AUDIT (non-authoritative for runtime behavior; implementation/schema/tests remain authoritative).
**Last verified:** 2026-08-14

## Executive summary

This audit re-checked the full repository (`README.md`, `docs/**`, `src/**`, `schema/**`, `tests/**`, `scripts/**`, `data/**`, `.github/**`, and top-level config files) to verify that documentation hierarchy, historical preservation, and API documentation integrity are coherent and evidence-backed.

The repository already retained the prior consolidation hierarchy; this pass focuses on governance completeness:

- confirms `docs/README.md` as the authority map and `docs/01-architecture/REPOSITORY_STRUCTURE.md` as placement authority;
- confirms `docs/api/` as the single canonical API documentation location;
- preserves historical phase and validation records as historical evidence rather than rewriting them as current specification;
- updates OpenAPI coverage reporting with explicit category states;
- adds this audit record as the latest review authority in `docs/07-review/`.

## Authority model

Conflict resolution order is unchanged and remains evidence-based:

1. `src/**`, `schema/sql/**`, `tests/**`, `scripts/**` (implemented behavior and executable verification)
2. AUTHORITATIVE current docs in `docs/README.md`
3. REFERENCE docs
4. PHASE RECORD indexes and reports (`docs/phases/**`, `docs/04-data/**`)
5. VALIDATION RECORD artifacts (`docs/05-validation/**`, `tests/validation/**`, `scripts/validation/**`)
6. REVIEW / AUDIT material (`docs/07-review/**`)

Historical records are preserved as historical evidence even where later implementation differs.

## Repository inventory (documentation/specification classification)

| Area | Classification |
|---|---|
| `README.md` | Authoritative repository entry |
| `docs/README.md` | Documentation authority map |
| `docs/00-project/**` | Project authority + development reference |
| `docs/01-architecture/**` | Architecture authority + placement authority |
| `docs/02-domain/DOMAIN_MODEL.md` | Domain model authority |
| `docs/03-schema/INFORMATION_SCHEMA.md` | Physical schema authority |
| `docs/api/**` | Canonical API docs (authority + reference + verification record) |
| `docs/04-data/**` | Legacy/historical phase records + historical data reference |
| `docs/phases/**` | Canonical phase-history index + later historical phase records |
| `docs/05-validation/**` | Validation methodology authority |
| `docs/06-decisions/**` | ADR / decision records |
| `docs/07-review/**` | Review and audit records |
| `data/**/README.md` | Data staging/reference docs (non-authoritative) |
| `tests/app/documentation-links.test.ts` | Executable documentation integrity test |

No competing API-doc trees or misplaced executable tests were found.

## Duplicate analysis

- No unresolved duplicate-current-authority documents were identified.
- Intentional overlap remains distinguishable:
  - `docs/04-data/**` and `docs/phases/**` both hold phase history by design (legacy vs later phase eras), with explicit index cross-links.
  - API behavior appears in both matrix and guide, but `docs/api/` remains a single canonical location and the matrix is positioned as reference evidence.

## Misplaced/stale/missing documentation

- Root-level documentation clutter: **none** (only `README.md` at root).
- Missing canonical review audit file: addressed by creating this file.
- Stale path references: no active broken canonical-path references found outside intentional historical/discussion context.
- Historical quoted paths were preserved when used as evidence context.

## API coverage comparison (implementation vs documentation vs tests)

Ground truth reviewed:

- Runtime route registration: `src/app.ts`, `src/api/v1.ts`, `src/administration/routes.ts`
- OpenAPI source: `src/api/openapi.ts` (`GET /openapi.json`)
- Behavior tests: `tests/app/app.test.ts`, `tests/app/phase28-ingestion.test.ts`
- Route/documentation drift guard: `tests/app/openapi-coverage.test.ts`
- Canonical docs: `docs/api/**`

Findings:

- Implemented endpoints are documented in canonical `docs/api/**`.
- No documented-but-missing route pairs were identified at route-surface level.
- Auth/authz, idempotency key behavior, optimistic concurrency (`If-Match` / `STALE_VERSION`), audit coupling, async queue semantics, and epistemic boundary behavior (`NOT_REPRESENTED`, `NO_MATCH`) remain documented in `docs/api/**` and reflected in runtime/tests.
- Administration docs remain workflow-state focused and do not reclassify workflow records as authoritative knowledge.

## OpenAPI status

`docs/api/OPENAPI_GAP_REPORT.md` now explicitly reports:

- `IMPLEMENTED_AND_DOCUMENTED`
- `IMPLEMENTED_BUT_UNDOCUMENTED`
- `DOCUMENTED_BUT_NOT_IMPLEMENTED`
- `IMPLEMENTED_BUT_UNTESTED`
- `DOCUMENTED_AND_TESTED`
- `OPENAPI_ONLY`

Current route-surface status remains complete with no implemented/documented drift.

## Broken-link and stale-path audit results

- Local Markdown link integrity is enforced by `tests/app/documentation-links.test.ts`.
- Repository stale-path checks were rerun with `git grep` against canonical old-path fragments.
- This audit excludes intentional historical discussion contexts from false-positive stale-path failures.

## Historical preservation confirmation

- No phase report conclusions were rewritten.
- No validation evidence was upgraded retroactively.
- Phase 28/36/37/37R behavior and records were preserved.
- Legacy numbering and placement (including Phase 6–32 material in `docs/04-data/**`) remain intact and traceable.

## Exact changes made in this audit pass

### Created

- `docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md` — required current governance audit artifact with repository-wide evidence summary and verification log.

### Modified

- `README.md` — adds a direct link to the current governance audit and retains the prior consolidation audit as historical context.
- `docs/README.md` — adds this audit file under REVIEW / AUDIT so the authority map resolves to the latest governance assessment.
- `docs/api/OPENAPI_GAP_REPORT.md` — adds the required explicit category statuses (`IMPLEMENTED_AND_DOCUMENTED`, `IMPLEMENTED_BUT_UNDOCUMENTED`, `DOCUMENTED_BUT_NOT_IMPLEMENTED`, `IMPLEMENTED_BUT_UNTESTED`, `DOCUMENTED_AND_TESTED`, `OPENAPI_ONLY`).
- `tests/app/documentation-links.test.ts` — extends documentation-integrity checks to require the new governance audit file and verify key section presence.

### Moved

- None.

### Deleted

- None.

## Intentionally untouched

- `src/**`, `schema/**`, `tests/fixtures/**`, `tests/validation/**`, and runtime API behavior were intentionally unchanged.
- Historical phase records under `docs/04-data/**` and `docs/phases/**` were preserved verbatim.
- Prior consolidation audit (`docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md`) was preserved as a historical audit artifact.

## Remaining issues / non-blocking notes

1. A small set of read routes remain marked as `code-traced` in `docs/api/API_CAPABILITY_MATRIX.md`; this pre-existing test-granularity note remains explicitly documented.
2. Two-directory phase-history indexing (`docs/04-data/**` and `docs/phases/**`) remains intentional for traceability and historical path stability.

## Verification commands and outcomes

The following commands were executed during this audit, with outcomes:

- `npm run typecheck` — **PASS**
- `npm run lint` — **PASS**
- `npm run build` — **PASS**
- `npx vitest run tests/app/documentation-links.test.ts` — **PASS** (`9/9` tests)
- `npm test` — **PASS** (`4/4` files, `111/111` tests)
- `bash scripts/validation/run-postgres-validation.sh` — **PASS** (`All validation self-test cases passed.`)
- `git grep -n "docs/" -- '*.md' '*.ts' '*.js' '*.json' '*.sh' '.github/**'` — **PASS** (paths resolve to current docs layout)
- stale/moved-path grep for `docs/architecture|docs/data|docs/administration|docs/ingestion|docs/research|docs/history/phases|docs/development|docs/operations` — **PASS WITH EXPECTED HISTORICAL/TEST REFERENCES ONLY** (hits found only in audit discussion and stale-path guard tests)

PostgreSQL validation execution was run after schema reset (`DROP SCHEMA IF EXISTS phase28_ingestion`, `DROP SCHEMA IF EXISTS public`, `CREATE SCHEMA public`) to avoid cross-suite residue.

## Final classification

**DOCUMENTATION GOVERNANCE AUDIT: PASS**
