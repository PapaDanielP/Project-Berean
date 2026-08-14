# Documentation Governance Audit

**Status:** ACTIVE — final repository-wide documentation governance and integrity enforcement audit  
**Scope:** Documentation/repository-governance only. No schema/runtime/API/epistemic semantics changed.  
**Authority:** REVIEW / AUDIT record (subordinate to implementation/schema/tests).  
**Last verified:** 2026-08-14

## Executive summary

This audit re-checked the full repository (`README.md`, `docs/**`, `src/**`, `schema/**`, `tests/**`, `scripts/**`, `data/**`, `.github/**`, package/config files) for authority structure, duplicate current documentation, misplaced documentation, API-doc/runtime consistency, OpenAPI consistency, and local-link integrity.

Result: the repository remains structurally consolidated, with `docs/README.md` as the authority map and `docs/api/` as the single canonical API documentation location. This pass adds one explicit governance audit record (this file), updates OpenAPI gap categorization, strengthens documentation-link integrity checks, and removes stale wildcard references in current verification/audit documents.

## Authority hierarchy (enforced)

1. **Current implementation** (`src/**`, `schema/sql/**`, `tests/**`, `scripts/validation/**`)
2. **Current authoritative documentation** (`docs/README.md` AUTHORITATIVE set)
3. **Reference documentation**
4. **Phase records** (`docs/phases/**`, `docs/04-data/**`)
5. **Validation records** (`docs/05-validation/**`, `tests/validation/**`)
6. **Review/audit records** (`docs/07-review/**`)
7. **Historical context/archives**

Historical records were preserved and not rewritten as current truth.

## Repository inventory and classification (significant groups)

| Group | Classification | Canonical location |
|---|---|---|
| Root orientation (`README.md`) | AUTHORITATIVE (entry navigation) | `/README.md` |
| Architecture & placement | AUTHORITATIVE / ARCHITECTURE | `/docs/01-architecture/**` |
| Domain model | AUTHORITATIVE / DATA MODEL | `/docs/02-domain/DOMAIN_MODEL.md` |
| Physical schema | AUTHORITATIVE / DATA MODEL | `/docs/03-schema/INFORMATION_SCHEMA.md` |
| Validation methodology | AUTHORITATIVE / VALIDATION RECORD | `/docs/05-validation/VALIDATION.md` |
| API docs | AUTHORITATIVE + REFERENCE / API | `/docs/api/**` (canonical set of 8 docs) |
| Decision records | REFERENCE / ARCHITECTURE HISTORY | `/docs/06-decisions/**` |
| Legacy Phase 6–32 records | PHASE RECORD / HISTORICAL | `/docs/04-data/**` |
| Phase 33+ records | PHASE RECORD / HISTORICAL | `/docs/phases/**` |
| Audit/review records | REVIEW/AUDIT | `/docs/07-review/**` |
| Executable test evidence | TEST DOCUMENTATION / VALIDATION RECORD | `/tests/**`, `/scripts/validation/**` |
| Source/candidate manifests | REFERENCE / OPERATIONS DATA | `/data/**` |

No root-level architecture/API/phase report clutter was found.

## Duplicate, obsolete, and misplaced documentation analysis

- **Duplicate current authorities:** none identified for architecture, domain model, schema, validation methodology, API location, or phase indexing.
- **Misplaced current documentation:** none identified.
- **Obsolete/broken canonical path trees reintroduced:** none detected in current docs.
- **Historical overlap retained intentionally:** `docs/04-data/**` and `docs/phases/**` are separate by design for traceable phase history, not competing current specifications.

## API documentation integrity audit

Ground truth compared against implementation/tests:
- `src/api/**`, `src/app.ts`, `src/administration/**`, `src/auth.ts`, `src/repository.ts`, `src/types.ts`
- `schema/sql/**`
- `tests/app/**`
- `docs/api/**`

Findings:
- Implemented endpoint families are documented in `docs/api/API_DEVELOPER_GUIDE.md` and `docs/api/API_CAPABILITY_MATRIX.md`.
- Mutation/read-only boundaries, authorization, idempotency, optimistic concurrency, audit behavior, and epistemic boundary semantics remain documented in `API_SECURITY_MODEL.md`, `API_WORKFLOWS.md`, `API_EPISTEMIC_BOUNDARIES.md`, and `API_LIMITATIONS.md`.
- No implementation changes were made to align docs.

## OpenAPI integrity audit

`GET /openapi.json` coverage is tracked in `docs/api/OPENAPI_GAP_REPORT.md` and test-enforced by `tests/app/openapi-coverage.test.ts`.

This pass updates explicit category reporting to include:
- `IMPLEMENTED_AND_DOCUMENTED`
- `IMPLEMENTED_BUT_UNDOCUMENTED`
- `DOCUMENTED_BUT_NOT_IMPLEMENTED`
- `IMPLEMENTED_BUT_UNTESTED`
- `DOCUMENTED_AND_TESTED`
- `OPENAPI_ONLY`

## Link and stale-reference audit

Repository-wide local-link checks and stale-reference searches were run over Markdown and related repository files.  
Current-link integrity is additionally enforced by `tests/app/documentation-links.test.ts`.

## Historical preservation audit

- Phase records and validation records were not rewritten to current semantics.
- Legacy phase numbering/history remains preserved (including historical gaps and historical conclusions).
- Historical records remain linked as historical evidence, not promoted to current authority.

## Exact changes in this pass

### Created
- `docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md` — final governance/integrity audit record.

### Modified
- `docs/README.md` — added this governance audit to REVIEW/AUDIT index.
- `docs/api/OPENAPI_GAP_REPORT.md` — added explicit OpenAPI gap categories.
- `docs/api/VERIFICATION_REPORT.md` — replaced stale wildcard path references with explicit audited path references.
- `docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md` — refreshed verification date; added governance-audit reference; replaced stale wildcard test-documentation reference.
- `tests/app/documentation-links.test.ts` — added canonical check for this governance audit document.

### Moved / deleted
- None.

## Intentionally untouched

- `src/**`, `schema/sql/**`, runtime behavior, API semantics, predicates, provenance/derivation logic, and phase conclusions.
- Historical phase content in `docs/04-data/**` and `docs/phases/**` beyond indexing/context.

## Remaining open items (non-blocking governance notes)

None blocking this governance pass.  
Historical manual verification timestamps in existing API reference documents were intentionally preserved as historical evidence rather than rewritten.

## Verification commands and results

The required verification command set and outcomes for this pass:

```text
npm run typecheck
npm run lint
npm run build
npm test
bash scripts/validation/run-postgres-validation.sh
npx vitest run tests/app/documentation-links.test.ts
git grep 'docs/'
git grep -nE 'docs/(architecture|data|administration|ingestion|research|history/phases|development|operations)/' -- README.md docs tests scripts .github package.json
```

Observed outcomes:

| Command | Result |
|---|---|
| `npm run typecheck` | Pass (exit 0) |
| `npm run lint` | Pass (exit 0) |
| `npm run build` | Pass (exit 0) |
| `npx vitest run tests/app/app.test.ts` (API smoke) | Pass: 61/61 tests |
| `npm test` | Pass: 4 files, 112/112 tests |
| `bash scripts/validation/run-postgres-validation.sh` | Pass (exit 0), ended with `All validation self-test cases passed.` |
| `npx vitest run tests/app/documentation-links.test.ts` | Pass: 10/10 tests |
| `git grep 'docs/'` | 208 references found and reviewed for current-path validity |
| stale-path grep for old canonical trees | Hits only in intentional negative examples (integrity test + audit narrative), no live misplaced canonical links |

Operational sequencing note: after `npm test`, `phase28_ingestion` and `public` schemas were dropped/recreated before running `scripts/validation/run-postgres-validation.sh` to keep validation deterministic with its `information_schema` assumptions.

## Final audit classification

**DOCUMENTATION GOVERNANCE AUDIT: PASS**
