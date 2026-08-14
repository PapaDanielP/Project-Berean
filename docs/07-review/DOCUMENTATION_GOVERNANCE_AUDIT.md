# Documentation Governance Audit

**Status:** ACTIVE — repository-wide documentation governance and integrity audit  
**Scope:** Documentation, navigation, and documentation-link coverage only. This audit does
not change the schema, predicates, domain semantics, runtime/API behavior, or historical
phase conclusions.  
**Authority:** REVIEW / AUDIT record. The authority order is defined by
[`docs/README.md`](../README.md): implementation/schema/executable tests and validation
scripts first, then current documentation, reference material, historical records, and review
material.

## Executive summary

The repository has an established, coherent documentation hierarchy. The prior
[`REPOSITORY_CONSOLIDATION_REPORT.md`](./REPOSITORY_CONSOLIDATION_REPORT.md) records the
consolidation that established it; this audit independently rechecked the current checkout.
There is one current authority for architecture, repository placement, domain semantics,
physical schema, API behavior, phase history, and validation methodology. The only retained
split is the intentional historical boundary between legacy Phase 6–32 records in
`docs/04-data/` and later records in `docs/phases/`.

**DOCUMENTATION GOVERNANCE AUDIT: PASS WITH OPEN ITEMS.** The current documentation and
OpenAPI route-surface checks are complete, but the repository intentionally records a small
set of read routes as code-traced rather than behavior-tested. This is a test-depth limitation,
not an undocumented or unimplemented route.

## Authority model and inventory

| Subject | Current authority | Classification |
|---|---|---|
| Documentation hierarchy | [`docs/README.md`](../README.md) | authoritative index |
| Project mission and epistemic invariants | [`docs/00-project/CHARTER.md`](../00-project/CHARTER.md) | authoritative |
| Architecture and workflow/knowledge boundary | [`docs/01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md), [`KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md) | authoritative |
| Repository placement | [`docs/01-architecture/REPOSITORY_STRUCTURE.md`](../01-architecture/REPOSITORY_STRUCTURE.md) | authoritative |
| Domain and physical schema | [`docs/02-domain/DOMAIN_MODEL.md`](../02-domain/DOMAIN_MODEL.md), [`docs/03-schema/INFORMATION_SCHEMA.md`](../03-schema/INFORMATION_SCHEMA.md) | authoritative |
| API | [`docs/api/`](../api/), led by [`API_DEVELOPER_GUIDE.md`](../api/API_DEVELOPER_GUIDE.md) | authoritative API location |
| Validation method | [`docs/05-validation/VALIDATION.md`](../05-validation/VALIDATION.md); executable behavior in `tests/validation/` and `scripts/validation/` | authoritative / executable |
| Decisions | `docs/06-decisions/` | decision records |
| Phase history | [`docs/phases/README.md`](../phases/README.md), [`docs/04-data/README.md`](../04-data/README.md) | historical indexes |
| Reviews | `docs/07-review/` | review/audit |
| Dataset-scoped READMEs and source metadata | `data/**` | reference; not a competing specification |
| Tests, fixtures, validation scripts, configuration, and workflows | `tests/**`, `schema/**`, `scripts/**`, `.github/**`, root configuration | executable/reference artifacts |

The inspected repository surface included all top-level entries and recursively included
`README.md`, `docs/**`, `src/**`, `schema/**`, `tests/**`, `scripts/**`, `data/**`, `.github/**`,
`package.json`, and configuration files. Markdown artifacts are classified by the index above:
current authorities stay in their numbered documentation areas; phase, validation, review, and
dataset records retain their distinct historical or reference role.

## Duplicate, misplaced, stale, and missing documentation

- **Duplicate current specifications:** none found. Complementary documents are deliberately
  separated: domain semantics versus physical schema, API reference versus API security and
  workflows, and validation methodology versus executable validation.
- **Misplaced or obsolete current documentation:** none found. The root contains only the
  concise entry point and project configuration; API documentation is only in `docs/api/`.
- **Historical preservation:** Phase 6–32 files in `docs/04-data/`, Phase 33–37R/37B files in
  `docs/phases/`, and existing validation/review records were not moved, deleted, or rewritten.
  Their index pages make their non-current authority explicit.
- **Missing documentation:** none found for implemented route surface. Administration,
  discovery, candidate review, identity mapping review, source/evidence/claim creation,
  derivation, jobs, audit, retry/cancel, authentication, authorization, concurrency, and
  idempotency are documented in `docs/api/`.

## API and OpenAPI coverage

Implementation was compared with `src/app.ts`, `src/api/v1.ts`,
`src/administration/routes.ts`, `src/administration/service.ts`, `src/auth.ts`,
`src/repository.ts`, `src/types.ts`, `schema/sql/**`, and `tests/app/**`.
`API_CAPABILITY_MATRIX.md` is the route inventory; `API_SECURITY_MODEL.md` and
`API_WORKFLOWS.md` document transaction, idempotency, optimistic concurrency, audit,
authorization, and the difference between workflow state and authoritative knowledge.

The actual `/openapi.json` contract is separately checked against the live Express route stack
by `tests/app/openapi-coverage.test.ts`. The canonical
[`OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md) explicitly classifies:

| Category | Result |
|---|---|
| IMPLEMENTED_AND_DOCUMENTED | all non-static routes |
| IMPLEMENTED_BUT_UNDOCUMENTED | none |
| DOCUMENTED_BUT_NOT_IMPLEMENTED | none |
| IMPLEMENTED_BUT_UNTESTED | no route-surface gaps; selected read-route behavior remains code-traced |
| DOCUMENTED_AND_TESTED | route surface, OpenAPI metadata, and mutations |
| OPENAPI_ONLY | none |

The API documents preserve `NOT_REPRESENTED`, `NO_MATCH`, validation-error, and epistemic
transition meanings. They do not promote discovery to evidence, source identities to canonical
entities, or workflow rows to authoritative knowledge; claim/evidence and derivation boundaries
remain explicit.

## Link and stale-path audit

A repository-wide local Markdown-link scan found **131** local links and **0** broken links.
`git grep 'docs/'` and stale canonical-path searches found no current moved-path references.
Historical quoted paths are retained as evidence and are not treated as current navigation.
`tests/app/documentation-links.test.ts` enforces canonical entry points, the sole `docs/api/`
location, phase indexes, authority placement, this audit, and local Markdown-link resolution.

## Changes and intentionally untouched files

| Change | Justification |
|---|---|
| Created this audit | Provides the requested named current governance record without rewriting the earlier consolidation evidence. |
| Updated `docs/README.md`, `README.md`, and the documentation-link test | Makes the named audit discoverable and protects it as a canonical review artifact. |
| No file moves or deletions | Existing placement is coherent; moving phase records would weaken historically cited evidence. |
| No source, schema, fixture, validation-script, workflow, or runtime changes | The audit found no documentation defect requiring behavioral change. |

## Remaining issue and minimal proposal

Some read endpoints are classified as code-traced rather than behavior-tested in
`API_CAPABILITY_MATRIX.md`. Evidence: the existing matrix names `GET /api-docs`,
`GET /api/sources`, `GET /api/sources/:sourceId`, `GET /api/dashboard/quality`, and
`GET /api/v1/schema`. The minimal future proposal is focused response-behavior coverage for
those routes; it has no schema, API, or epistemic impact and is not implemented by this
documentation-only audit.

## Verification record

The following commands were run after the documentation changes:

| Command | Result |
|---|---|
| `npm run typecheck` | passed (exit 0) |
| `npm run lint` | passed (exit 0) |
| `npm run build` | passed (exit 0) |
| `npx vitest run tests/app/documentation-links.test.ts` | passed: 1 file, 10 tests |
| `npm test` | passed: 4 files, 112 tests |
| `bash scripts/validation/run-postgres-validation.sh` | passed (exit 0): `All validation self-test cases passed.` |
| OpenAPI smoke/route-surface coverage (`tests/app/openapi-coverage.test.ts`, included in `npm test`) | passed: 6 tests |
| repository-wide Markdown link scan | passed: 148 local links, 0 broken |
| `git grep 'docs/'` and stale-path searches | reviewed; no current broken or moved canonical documentation path found |

The PostgreSQL validation database was reset after application tests so the Phase 28 test schema
could not affect the independent validation replay. Final scope review uses `git status`,
`git diff --stat`, and `git diff --name-status`; only this audit, its navigation links, and its
focused documentation-link coverage are intended. No conclusion in a historical phase or
validation record was altered.
