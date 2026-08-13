# Repository Documentation Consolidation Report

Date: 2026-08-13

This report records the documentation and repository-structure consolidation audit. It is a review record, not an architectural authority; current authority is defined in [`../README.md`](../README.md) and [`../01-architecture/REPOSITORY_STRUCTURE.md`](../01-architecture/REPOSITORY_STRUCTURE.md).

## Audit scope

Reviewed repository areas:

- root `README.md`;
- `docs/**`, including architecture, API, phase, validation, ADR, and review material;
- `schema/sql/**`;
- `src/**`;
- `tests/app/**`, `tests/fixtures/**`, `tests/validation/**`;
- `scripts/validation/**`;
- `data/**`;
- package/config files and CI workflow metadata.

## Authority map

1. Implementation/schema/code/tests: `src/`, `schema/sql/`, `tests/`, `scripts/validation/`.
2. Authoritative current documentation: `docs/00-project/CHARTER.md`, `docs/01-architecture/`, `docs/02-domain/`, `docs/03-schema/`, and canonical `docs/api/` behavior/security/limitations/workflow docs.
3. Reference documentation: developer guide, capability matrix, OpenAPI gap report, verification report, Explorer adapter notes.
4. Phase records: legacy `docs/04-data/` records and later `docs/phases/` records.
5. Validation records: `docs/05-validation/` plus executable validation suites.
6. Historical/archive/review material: `docs/06-decisions/` and `docs/07-review/`.

## Before / after repository trees

Meaningful current tree after consolidation:

```text
README.md
docs/
  README.md
  00-project/
  01-architecture/
  02-domain/
  03-schema/
  04-data/
  05-validation/
  06-decisions/
  07-review/
  api/
  phases/
schema/sql/
src/
  administration/
  api/
  ingestion/
  public/
tests/
  app/
  fixtures/
  validation/
scripts/
  acquisition/
  validation/
data/
  candidates/
  external/
  genesis-1-11/
  ingestion/
```

The repository root now contains only the concise entry README for durable documentation. Full guides, architecture, API references, validation guidance, review notes, and phase records live under `docs/`.

## Document placement decisions

| Area | Decision | Reason |
|---|---|---|
| Root README | Keep concise and link to docs | Avoid duplicate architecture/API specifications at the root. |
| `docs/README.md` | Treat as documentation authority index | Gives new contributors one place to resolve document authority and conflicts. |
| `docs/01-architecture/REPOSITORY_STRUCTURE.md` | Treat as placement authority | Defines canonical paths for docs, code, schema, tests, scripts, data, validation, and history. |
| `docs/api/` | Preserve as canonical API documentation tree | Avoids competing API references and keeps OpenAPI/API guides/security/workflows/limitations together. |
| `docs/04-data/` | Retain legacy Phase 6–32 data/model reports in place | Many data and Genesis references intentionally point there; moving them would create churn without changing authority. |
| `docs/phases/` | Use as phase-history entry point and location for new/later phase reports | Centralizes historical phase discovery while preserving stable legacy paths. |
| `docs/05-validation/` | Retain as validation documentation area | Executable tests and fixtures remain under `tests/` and `scripts/validation/`. |
| `docs/07-review/` | Store consolidation/review records | Keeps audit reports out of the root and away from current architecture authority. |

## Moves, merges, archives, and deletions

No executable files, schema files, fixtures, validation runners, or historical phase evidence were moved or deleted in this pass. No duplicate document was clearly disposable after review. Instead:

- current documentation authority was clarified in `docs/README.md`;
- repository placement rules were clarified in `docs/01-architecture/REPOSITORY_STRUCTURE.md`;
- phase history discovery was consolidated through `docs/phases/README.md`;
- the root README was kept concise and updated to point to canonical docs and current limitations.

Historical records remain useful evidence. They should be linked, indexed, or archived with explanation rather than silently rewritten into current specifications.

## Duplicate / overlap audit

| Concept | Authoritative current location | Historical/reference overlaps | Resolution |
|---|---|---|---|
| Architecture and epistemic boundaries | `docs/01-architecture/ARCHITECTURE.md`, `docs/02-domain/DOMAIN_MODEL.md` | Phase reports in `docs/04-data/` and `docs/phases/` | Current docs win; phase records remain historical evidence. |
| Schema and provenance model | `schema/sql/*.sql`, `docs/03-schema/INFORMATION_SCHEMA.md` | population/phase reports | Schema and information schema are current authority. |
| API behavior | `src/app.ts`, `src/api/v1.ts`, `src/administration/routes.ts`, `src/api/openapi.ts`, `docs/api/API_DEVELOPER_GUIDE.md` | `docs/04-data/PHASE25_EXPLORATION_API.md` and phase API notes | Canonical API docs stay under `docs/api/`; phase API notes are historical. |
| API capability/gaps | `docs/api/API_CAPABILITY_MATRIX.md`, `docs/api/OPENAPI_GAP_REPORT.md` | `docs/api/VERIFICATION_REPORT.md` | Retain distinct purposes: matrix, gap status, and evidence. |
| Validation | `docs/05-validation/VALIDATION.md`, `scripts/validation/run-postgres-validation.sh`, `tests/validation/` | phase validation reports | Executable validation remains under tests/scripts; historical reports are indexed. |
| Research/discovery/ingestion | `docs/api/API_WORKFLOWS.md`, `docs/api/API_LIMITATIONS.md`, `data/ingestion/README.md`, `data/candidates/README.md` | phase research and ingestion reports | Current workflows link to supported implementation; phase reports are evidence. |
| Security | `docs/api/API_SECURITY_MODEL.md`, `src/auth.ts`, Express middleware in `src/app.ts` | API verification report | Security model remains canonical; verification report is evidence. |

## API surface summary

The current OpenAPI document contains 50 documented operations across 50 paths:

- 6 meta operations;
- 7 current read operations;
- 2 research operations;
- 19 administration/workflow operations;
- 16 compatibility operations.

Route-surface coverage is enforced by `tests/app/openapi-coverage.test.ts`, which compares the Express route stack with `src/api/openapi.ts`.

## Known gaps and limits

- Implemented-but-undocumented route-surface gaps: none identified by the OpenAPI coverage test.
- Implemented-but-untested route-surface gaps: none identified at route-surface level; behavior-level coverage still depends on focused application tests.
- OpenAPI route-surface gaps: none currently identified.
- Operational gap: queued discovery, ingestion, validation, and export jobs require a system worker or scripts for execution beyond queue persistence.
- Architectural limit: APIs must not create truth adjudication, automatic candidate promotion, automatic evidence-to-claim promotion, or automatic `PROPOSED` to `ACTIVE` identity promotion.
- Security limit: bearer credentials and administrative roles are suitable for controlled pre-beta operation but are not a complete production identity/access-management system.

## New developer checklist

A new developer should start with:

1. [`../../README.md`](../../README.md) for project entry points and commands.
2. [`../README.md`](../README.md) for documentation authority and conflict resolution.
3. [`../01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md) and [`../03-schema/INFORMATION_SCHEMA.md`](../03-schema/INFORMATION_SCHEMA.md) for architecture and data model.
4. [`../api/API_DEVELOPER_GUIDE.md`](../api/API_DEVELOPER_GUIDE.md), [`../api/API_WORKFLOWS.md`](../api/API_WORKFLOWS.md), and [`../api/API_LIMITATIONS.md`](../api/API_LIMITATIONS.md) for API usage and non-capabilities.
5. [`../05-validation/VALIDATION.md`](../05-validation/VALIDATION.md), `tests/validation/`, and `scripts/validation/` for validation workflows.
6. [`../phases/README.md`](../phases/README.md) for historical phases and current/historical boundaries.
