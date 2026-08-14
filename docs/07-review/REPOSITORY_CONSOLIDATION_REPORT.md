# Repository Consolidation Report

**Status:** ACTIVE — repository-wide documentation and structural integrity audit
**Scope:** Documentation governance, repository organization, and integrity enforcement only. No schema, predicate, entity/event/claim/evidence/mapping/provenance/derivation semantics, Explorer behavior, API behavior, runtime architecture, or Phase 36/37/37R/37B conclusions were changed.
**Authority:** REVIEW / AUDIT record. Subordinate to current implementation/schema/code/tests and to the authoritative documents it audits; see the authority hierarchy below.
**Last verified:** 2026-08-14

2026-08-14 addendum: this report remains the consolidation baseline record; final enforcement and completeness findings are recorded in [`DOCUMENTATION_GOVERNANCE_AUDIT.md`](./DOCUMENTATION_GOVERNANCE_AUDIT.md).

## 1. Executive summary

This audit inspected the complete repository (`README.md`, `docs/**`, `src/**`, `schema/**`,
`tests/**`, `scripts/**`, `data/**`, package/config files) against the specification for a
final documentation and structural integrity pass. A prior consolidation (merged in PR #64,
`bb4fda8`) had already established the target repository information architecture: a
numbered `docs/00-project` … `docs/07-review` domain layout, a single canonical
`docs/api/` location, and a two-part phase-history record (`docs/04-data/` for legacy
Phase 6–32, `docs/phases/` for Phase 33–37R/37B). The root directory already contained only
`README.md` plus genuine project configuration (`package.json`, `package-lock.json`,
`tsconfig.json`, `eslint.config.js`, `vitest.config.ts`, `.gitignore`) — no phase reports, API
guides, architecture essays, validation reports, or research notes were found at root.

This pass closes the remaining gaps identified against the specification:

1. `docs/phases/README.md` did not exist — added as the canonical phase-history index.
2. `docs/04-data/README.md` did not exist — added as the traceable legacy Phase 6–32 index.
3. `docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md` (this file) did not exist — added.
4. `tests/app/documentation-links.test.ts` did not exist — added to enforce canonical entry
   points, the single canonical API doc location, the phase index, the repository structure
   document, this report's presence, local Markdown link integrity, and absence of stale
   canonical path fragments from prior (pre-consolidation) structures.
5. `docs/README.md` was updated to link the two new indexes and to add an explicit
   REVIEW / AUDIT documentation classification section.

No files were moved, merged, archived, or deleted in this pass: the prior consolidation had
already performed that work, and repository-wide inspection found no remaining root-level
clutter, duplicate-by-meaning documents, or stale moved-path references (see §7 and §9).

## 2. Authority hierarchy

```
current implementation / schema / code / tests
        -> current authoritative docs (docs/README.md "AUTHORITATIVE" section)
                -> reference docs (docs/README.md "REFERENCE" section)
                        -> phase records (docs/phases/README.md, docs/04-data/README.md)
                                -> validation records (docs/05-validation/, tests/validation/, scripts/validation/)
                                        -> review/audit (docs/07-review/, including this report)
                                                -> historical/archive material (retained in place, cross-linked)
```

`docs/README.md` is the documentation authority index and enumerates every AUTHORITATIVE,
REFERENCE, VALIDATION RECORD, DESIGN PROPOSAL / DECISION RECORD, PHASE RECORD, REVIEW / AUDIT,
and GENERATED / TEST ARTIFACT document. `docs/01-architecture/REPOSITORY_STRUCTURE.md` is the
canonical placement authority for where new material of each kind belongs.

## 3. Documentation classification inventory (significant documents)

| Path | Classification |
|---|---|
| `README.md` | AUTHORITATIVE (entry point) |
| `docs/README.md` | AUTHORITATIVE (documentation index) |
| `docs/00-project/CHARTER.md` | AUTHORITATIVE |
| `docs/00-project/DEVELOPER_GUIDE.md` | REFERENCE |
| `docs/00-project/PROJECT_OVERVIEW.md` | REFERENCE |
| `docs/00-project/WEB_APP_MVP_PLAN.md` | REFERENCE (design planning record) |
| `docs/01-architecture/ARCHITECTURE.md` | AUTHORITATIVE |
| `docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md` | AUTHORITATIVE |
| `docs/01-architecture/REPOSITORY_STRUCTURE.md` | AUTHORITATIVE (placement authority) |
| `docs/01-architecture/EXPLORER_READ_ONLY_ADAPTER.md` | REFERENCE |
| `docs/02-domain/DOMAIN_MODEL.md` | AUTHORITATIVE (data model) |
| `docs/03-schema/INFORMATION_SCHEMA.md` | AUTHORITATIVE (physical schema) |
| `docs/04-data/README.md` | PHASE RECORD index (new) |
| `docs/04-data/PHASE6_REPORT.md` … `PHASE32_CROSS_DOMAIN_SCHOLARLY_RESEARCH_GENERALIZATION.md` | PHASE RECORD (historical) |
| `docs/04-data/DATA_POLICY.md`, `GENESIS_1_1-5_SLICE.md`, `POPULATION_SPECIFICATION.md`, `STEPBIBLE_ACQUISITION_REPORT.md` | REFERENCE (historical data-policy records) |
| `docs/05-validation/VALIDATION.md` | AUTHORITATIVE (validation methodology) |
| `docs/06-decisions/ADR-0001..0003` | DESIGN PROPOSAL / DECISION RECORD |
| `docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md` | REVIEW / AUDIT (this file, new) |
| `docs/07-review/REMEDIATION-REPORT.md` | REVIEW / AUDIT (historical) |
| `docs/07-review/WEB_APP_MVP_REPORT.md` | REVIEW / AUDIT (historical) |
| `docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md` | REVIEW / AUDIT (final governance integrity pass) |
| `docs/07-review/COPILOT_PEER_REVIEW_PROMPT.md` | REFERENCE (process record) |
| `docs/phases/README.md` | PHASE RECORD index (new) |
| `docs/phases/PHASE_33...PHASE_37R_37B...` | PHASE RECORD (historical) |
| `docs/api/API_DEVELOPER_GUIDE.md` | AUTHORITATIVE (API) |
| `docs/api/API_EPISTEMIC_BOUNDARIES.md` | AUTHORITATIVE (API) |
| `docs/api/API_WORKFLOWS.md` | AUTHORITATIVE (API) |
| `docs/api/API_SECURITY_MODEL.md` | AUTHORITATIVE (API) |
| `docs/api/API_LIMITATIONS.md` | AUTHORITATIVE (API) |
| `docs/api/API_CAPABILITY_MATRIX.md` | REFERENCE (route-by-route matrix) |
| `docs/api/OPENAPI_GAP_REPORT.md` | REFERENCE / VALIDATION RECORD (OpenAPI coverage status) |
| `docs/api/VERIFICATION_REPORT.md` | VALIDATION RECORD |
| `tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts`, `tests/app/phase28-ingestion.test.ts`, `tests/app/documentation-links.test.ts`, `tests/validation/*.sql`, `tests/fixtures/*.sql` | TEST DOCUMENTATION / GENERATED (executable, not prose docs) |
| `data/*/README.md` | REFERENCE (dataset-scoped, cross-links to `docs/04-data/`) |

No document was classified DUPLICATE, OBSOLETE, or MISPLACED. No root-level or misplaced
documentation was found.

## 4. Duplicate/overlap audit

Repository-wide duplicate-by-meaning analysis (architecture, schema, provenance, claims,
evidence, validation, research, ingestion, administration, identity, derivation, security)
found **no unresolved duplicates**:

- Architecture is described once authoritatively (`docs/01-architecture/ARCHITECTURE.md`),
  with `docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md` and
  `docs/01-architecture/EXPLORER_READ_ONLY_ADAPTER.md` as distinct, non-overlapping
  specializations (workflow boundary; Explorer read-only adapter behavior).
- The data model is described once (`docs/02-domain/DOMAIN_MODEL.md`) and the physical schema
  once (`docs/03-schema/INFORMATION_SCHEMA.md`); these are complementary (conceptual vs.
  physical), not duplicative.
- API documentation lives only in `docs/api/`; no competing API guide exists elsewhere in the
  repository (`git grep` search below confirms this).
- Validation methodology is described once (`docs/05-validation/VALIDATION.md`); phase-specific
  validation evidence remains in phase records and cross-links back rather than restating
  methodology.
- Phase history is intentionally split into two directories for a historical reason (an
  earlier phase-numbering convention under `docs/04-data/` and a later convention under
  `docs/phases/`); this is not duplication, and the new indexes make the split traceable
  rather than merging the directories (merging would rewrite established historical paths
  cited by other documents, violating "do not rewrite historical quoted paths unnecessarily").

## 5. API documentation audit

Ground truth inspected: `src/app.ts`, `src/api/v1.ts`, `src/api/openapi.ts`,
`src/administration/routes.ts`, `src/administration/service.ts`,
`src/administration/repository.ts`, `src/auth.ts`, `src/repository.ts`, `src/types.ts`,
`src/ingestion/**`, `tests/app/app.test.ts`, `tests/app/openapi-coverage.test.ts`,
`tests/app/phase28-ingestion.test.ts`, and `/openapi.json` as served by
`src/api/openapi.ts`.

### 5.1 Endpoint count and categories

`docs/api/API_CAPABILITY_MATRIX.md` enumerates **51 route rows** covering every registered
Express route (including the two intentional wildcard/fallback rows: the Explorer shell
`GET *` and the `/api/v1` catch-all). By category:

| Category | Representative routes | Documentation coverage |
|---|---|---|
| Health / capabilities / schema | `/health`, `/api/v1/capabilities`, `/api/v1/schema` | Documented |
| Registries | `/api/v1/registry/:registry` | Documented |
| Search | `/api/search`, `/api/v1/search/:resource?` | Documented, incl. `NO_MATCH` |
| Research | `/api/research`, `/api/v1/research`, `/research/capabilities` | Documented |
| Entities / claims / propositions / events / sources | `/api/{entities,claims,propositions,events,sources}/:id` | Documented |
| Provenance | `/api/provenance/claims/:id`, `/api/v1/provenance/claim/:id`, `/api/provenance/explain` | Documented, incl. intentional versioned-vs-compatibility difference |
| Graph / timeline | `/api/graph`, `/api/v1/graph/entity/:id`, `/api/exploration/timeline` | Documented |
| Derivation eligibility | `/api/derivations/check-eligibility` | Documented |
| Administration: corpora / research topics | `POST /api/v1/corpora`, `PATCH /api/v1/corpora/:id`, `POST /api/v1/research-topics` | Documented, incl. `If-Match` concurrency contract |
| Discovery | `POST /api/v1/discovery-requests`, `.../candidates`, `POST /api/v1/candidates/:id/review` | Documented, incl. idempotency key behavior |
| Source registration / ingestion | `POST /api/v1/source-registrations`, `/source-records`, `/evidence`, `/api/v1/ingestion-jobs` | Documented |
| Claims / identity mappings | `POST /api/v1/claims`, `/identity-mappings`, `/identity-mappings/:id/review` | Documented, incl. `PROPOSED` -> `ACTIVE`/`REJECTED` review gating |
| Derivations | `POST /api/v1/derivations` | Documented, incl. explicit no-auto-claim-creation boundary |
| Jobs / exports / validation / audit | administration job, export, validation, audit routes | Documented in `API_CAPABILITY_MATRIX.md` |
| Fallbacks | `GET *` (Explorer), unmatched `/api/v1/*` | Documented as fallback behavior, not addressable paths |

### 5.2 Implemented-vs-documented-vs-tested discrepancies

- **Implemented but undocumented endpoints:** none identified. `tests/app/openapi-coverage.test.ts`
  enforces this automatically by walking the live Express route stack and diffing it against
  `paths` in `src/api/openapi.ts`.
- **Documented but unimplemented endpoints:** none identified; the same test enforces the
  reverse direction.
- **Implemented but untested endpoints:** at the route-surface level, none — every route is
  exercised by `openapi-coverage.test.ts` for existence/documentation, and the majority of
  routes have behavior-level coverage in `tests/app/app.test.ts` and
  `tests/app/phase28-ingestion.test.ts`. A small number of read routes
  (`GET /api-docs`, `GET /api/sources`, `GET /api/sources/:sourceId`,
  `GET /api/dashboard/quality`, `GET /api/v1/schema`) are marked "code-traced" rather than
  behavior-tested in `API_CAPABILITY_MATRIX.md`; this is an existing, previously disclosed gap
  and is preserved here rather than silently upgraded to "tested."
- **Route-vs-OpenAPI discrepancies:** none found; `openapi-coverage.test.ts` passed (see §8).
- **Documentation-vs-runtime discrepancies:** none found during this pass. Epistemic
  distinctions (Discovery != Evidence, Evidence != Claim, Claim != Truth,
  Claim.statement != authoritative proposition, PROPOSED != ACTIVE,
  NOT_REPRESENTED/NOT_ESTABLISHED/NO_MATCH != FALSE, source-backed != true, locator-only
  policy != source silence) are consistently preserved across `API_EPISTEMIC_BOUNDARIES.md`,
  `API_LIMITATIONS.md`, and the runtime behavior exercised by `tests/app/app.test.ts`.

### 5.3 Security / auth / authz / admin / ingestion / discovery / research / provenance / graph / search

- **Auth/authz:** bearer-token authentication with minimum-role enforcement per mutation route,
  documented in `docs/api/API_SECURITY_MODEL.md` and enforced in `src/auth.ts` /
  `src/administration/routes.ts`; verified consistent with `x-berean-minimum-role` extensions
  in `src/api/openapi.ts`.
- **Admin/ingestion/discovery:** workflow-only persistence (`corpus`, `research_topic`,
  `discovery_request`, `discovery_candidate`, `candidate_review`, `ingestion_job`,
  `asynchronous_job`) is documented as never auto-promoting to authoritative knowledge rows;
  confirmed against `src/administration/service.ts` and `src/administration/repository.ts`.
- **Research/provenance/graph/search:** read-only; documented and confirmed read-only by both
  automated tests and the manual before/after row-count checks referenced in
  `API_CAPABILITY_MATRIX.md` and `API_LIMITATIONS.md`.

## 6. OpenAPI audit

Ground truth: `/openapi.json` (`src/api/openapi.ts`) and `docs/api/OPENAPI_GAP_REPORT.md`.

Classification: **COMPLETE** at the route-surface level for the current implemented route
set. Basis:

- `tests/app/openapi-coverage.test.ts` passed (6/6 assertions: implemented -> documented,
  documented -> implemented, operation metadata present, mutation metadata present on every
  write operation, and the served document is byte-identical to the in-process object).
- `docs/api/OPENAPI_GAP_REPORT.md` explicit gap status ("Implemented but undocumented
  endpoints: none identified"; "Implemented but untested endpoints: none identified at
  route-surface level") is consistent with the automated evidence above and is not a claim
  made without evidence.
- No PARTIAL, STALE, or INCONSISTENT status is warranted based on current inspection; this
  finding is itself evidence-backed by the passing coverage test rather than assumed.

## 7. Historical preservation

- No historical phase or validation record content was rewritten. Phase 28, 36, and
  37/37R/37B conclusions are unchanged; the new `docs/phases/README.md` and
  `docs/04-data/README.md` indexes only add navigational metadata (Status/Scope/Authority/Last
  verified headers and a table of contents) and explicitly state that phase records remain
  historical evidence subordinate to current authoritative documentation.
- The Phase 20 legacy-numbering gap (no Phase 29 report file) is preserved as-is in the new
  `docs/04-data/README.md` index rather than renumbered or hidden.
- Validation record distinctions (PASS, PASS WITH INTENTIONAL LIMITATION, NOT DEMONSTRATED,
  NOT REPRESENTED, FAILED) already present in phase records and `docs/api/VERIFICATION_REPORT.md`
  were left untouched.

## 8. Link-integrity and verification results

Commands run in this session (PostgreSQL 16, local instance, `berean_test` database):

```
$ npm run typecheck
> tsc --noEmit
(no errors)

$ npm run lint
> eslint "src/**/*.ts" "tests/app/**/*.ts"
(no errors)

$ npm run build
> tsc -p tsconfig.json
(no errors)

$ npx vitest run tests/app/app.test.ts
 Test Files  1 passed (1)
      Tests  61 passed (61)

$ npm test
 Test Files  4 passed (4)
      Tests  112 passed (112)

$ npx vitest run tests/app/documentation-links.test.ts
 Test Files  1 passed (1)
      Tests  10 passed (10)

$ bash scripts/validation/run-postgres-validation.sh
... (Phase 6-37R/37B fixture and validation replay) ...
All validation self-test cases passed.
exit code 0

$ git grep -n "docs/"
209 references found (current repository state), manually spot-checked and file-resolved.

$ git grep -nE 'docs/(architecture|data|administration|ingestion|research|history/phases|development|operations)/' -- README.md docs tests scripts .github package.json
No stale live canonical-path references outside intentional negative examples in this report and in documentation integrity tests.
```

The new `tests/app/documentation-links.test.ts` suite additionally enforces, on every future
run of `npm test`:

- presence of every canonical entry point (`README.md`, `docs/README.md`, architecture, domain
  model, schema, validation, phase indexes, this report, and `DOCUMENTATION_GOVERNANCE_AUDIT.md`);
- presence of every canonical `docs/api/` document and absence of a competing API doc
  directory;
- `README.md` -> `docs/README.md` -> per-domain navigation;
- `docs/phases/README.md` referencing both `docs/04-data/` and the newest Phase 37R/37B record;
- `docs/01-architecture/REPOSITORY_STRUCTURE.md` containing placement rules;
- this report containing an authority hierarchy and an API documentation audit section;
- absence of stale/obsolete canonical path fragments (e.g. a flat `docs/architecture/`,
  `docs/data/`, or `docs/history/phases/` layout that existed only in the original task
  specification's illustrative structure and was never adopted);
- resolvability of every local Markdown link under `docs/` to an existing file or directory.

No broken internal documentation links, stale moved-file references, or credential/temporary
files were found. `git status` and `git diff --stat` were reviewed before finalizing and show
only the intentionally added/edited documentation and test files listed in §1.

## 9. Known limitations and unresolved ambiguity

- A small number of read routes remain "code-traced" rather than behavior-tested (§5.2); this
  is a pre-existing, disclosed limitation, not introduced or hidden by this audit.
- The two-directory phase-history split (`docs/04-data/` and `docs/phases/`) is preserved
  rather than unified into a single directory, because unifying it would require rewriting a
  large number of historically-cited paths across phase records themselves — out of scope for
  a documentation-governance pass that must not silently rewrite historical records. This is
  reported, not silently resolved.
- No architectural deficiency was found that would require an implementation change; this
  audit made no changes to `src/**`, `schema/**`, or runtime behavior.

## 10. Confirmation

A new developer can navigate: `README.md` -> `docs/README.md` -> architecture
(`docs/01-architecture/ARCHITECTURE.md`) -> data model (`docs/02-domain/DOMAIN_MODEL.md`,
`docs/03-schema/INFORMATION_SCHEMA.md`) -> provenance (`API_EPISTEMIC_BOUNDARIES.md`,
`docs/01-architecture/ARCHITECTURE.md`) -> API (`docs/api/API_DEVELOPER_GUIDE.md` and the rest
of `docs/api/`) -> administration/research/validation (`docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`,
`docs/05-validation/VALIDATION.md`) -> tests/fixtures (`tests/app/`, `tests/fixtures/`,
`tests/validation/`) -> history (`docs/phases/README.md`, `docs/04-data/README.md`) ->
current status and limitations (`docs/api/API_LIMITATIONS.md`, this report).
