# Repository Structure and Placement Rules

This document defines where contributors should place new materials.

## Top-level layout

- `src/` — TypeScript runtime implementation (Explorer, API, administration, ingestion)
- `schema/sql/` — authoritative PostgreSQL schema and schema-level validation SQL
- `tests/app/` — application/API tests
- `tests/fixtures/` — deterministic SQL data fixtures for phases and test setup
- `tests/validation/` — SQL/bash validation suites and negative checks
- `scripts/validation/` — executable validation runners
- `data/` — input/manifests/candidates and source metadata declarations
- `docs/` — architecture, schema, API, validation, ADR, and phase documentation
- `.github/workflows/` — CI workflows

## Documentation placement

- `docs/api/` — canonical API docs, endpoint behavior, limitations, security, OpenAPI coverage.
- `docs/01-architecture/` — architecture and workflow-boundary documents.
- `docs/03-schema/` — schema model references.
- `docs/04-data/` — phase-era data/model records and reports.
- `docs/phases/` — later historical phase records and independent domain audits.
- `docs/05-validation/` — validation methodology documentation.
- `docs/06-decisions/` — ADRs and architectural decisions.
- `docs/07-review/` — review/remediation records.

## Placement rules for new contributions

- New executable tests belong in `tests/app/` or `tests/validation/` (not in `docs/`).
- New fixtures belong in `tests/fixtures/`.
- New candidate-review CSVs belong in `data/candidates/`.
- New ingestion manifests belong in `data/ingestion/`.
- New phase reports belong in `docs/phases/` unless they are direct continuations of legacy `docs/04-data/` phase files.
- API endpoint documentation updates must be made in `docs/api/` and `/openapi.json` support (`src/api/openapi.ts`).
- Architecture/spec changes must update authoritative docs and not be recorded only in a phase report.

## Historical material handling

Preserve historical phase and validation records unless content is clearly disposable. Historical records do not supersede current authoritative architecture/schema/API references; they should cross-link to those references.
