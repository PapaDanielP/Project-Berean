# Allegheny County Bounded Provenance Population — Execution Report

**Execution date:** August 21, 2026
**Corpus:** `pa-foster-care-placement-reunification`
**Scope:** Allegheny County, Pennsylvania material only
**Pilot status:** `PILOT_REVIEW_REQUIRED`

## 1. Purpose

This report executes the corpus-specific, county-only bounded provenance population
design already described in `COUNTY_BOUNDED_PROVENANCE_POPULATION.md`. It populates a
disposable test database with exactly the two Allegheny County re-entry observations
already established by prior review, keeps them as separate source/dataset/source-record/
citation/evidence/claim/proposition paths, and proves — with executable SQL, not narrative
assertion — that no county/state comparison, no equivalence between the two county
observations, and no fabricated methodology field is persisted.

This phase does not select Allegheny County as the final county pilot and does not
establish a Pennsylvania statewide comparison. It also does not modify the corpus
charter, source inventory, application code, schema, or generic research behavior.

## 2. Exact county-only scope

Populated:

- **Observation A** — Allegheny County NBPB source-reported **8.1%** re-entry-within-12-months
  indicator (FY 2026-27 Needs-Based Plan & Budget, page 69, section 2-3f).
- **Observation B** — Allegheny County dashboard source-described **approximately 9%**
  re-entry trend (Child Welfare Out-of-Home Placements: Interactive Dashboard, Re-entry
  view).

Not populated:

- Any Pennsylvania statewide observation, entity, source, claim, or comparison (the 7.8%
  APSR figure discussed in `COUNTY_REENTRY_COMPARABILITY_CLOSURE.md` remains outside this
  population entirely; it is not referenced by any row created here).
- Any ranking, performance conclusion, or proposition equating 8.1% with approximately 9%.
- Any downloaded source document, quoted text, numerator, denominator, cohort
  construction, profile period, dashboard filter state, export, or snapshot.

## 3. Artifacts created

| Artifact | Path |
|---|---|
| SQL fixture (county-specific) | `tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql` |
| SQL validation (positive + negative) | `tests/validation/pa-foster-care-allegheny-county-bounded-provenance-validation.sql` |
| This report | `docs/08-corpus/pa-foster-care-placement-reunification/COUNTY_BOUNDED_PROVENANCE_POPULATION_REPORT.md` |

No other file was created or modified. `scripts/validation/run-postgres-validation.sh` was
**not** changed; see §9 for why and how these artifacts are run standalone instead.

## 4. Source metadata and locators

### 4.1 Allegheny County NBPB (Observation A)

- **Source key:** `PA_FOSTER_ALLEGHENY_NBPB_FY2026_27`.
- **Title:** Allegheny County Fiscal Year 2026-27 Needs-Based Plan & Budget.
- **Issuer:** Allegheny County Department of Human Services, Office of Children, Youth and
  Families.
- **Locator:** PDF page 69, section `2-3f Re-entry (in 12 Months)`.
- **Storage:** locator-only; no document was downloaded; `quoted_text` is `NULL`.

### 4.2 Allegheny County dashboard (Observation B)

- **Source key:** `PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY`.
- **Title:** Child Welfare Out-of-Home Placements: Interactive Dashboard.
- **Issuer:** Allegheny County Department of Human Services / Allegheny Analytics.
- **Locator:** Re-entry view, as referenced by county material; publication page.
- **Storage:** locator-only; no document/page was downloaded; `quoted_text` is `NULL`.

## 5. Observation A and B, as populated

```text
Observation A
Scope: Allegheny County
Value: 8.1 percent (source-reported)
Representation: evidence.observation (text) + claim.notes (unresolved-field markers)
Structured percentage: NOT persisted (NOT_YET_MODELED, see §8)

Observation B
Scope: Allegheny County
Value: approximately 9 percent (source-described trend)
Representation: evidence.observation (text) + claim.notes (unresolved-field markers)
Structured percentage: NOT persisted (NOT_YET_MODELED, see §8)
```

Both observations keep independent evidence, claim, and proposition rows. No row in the
population references both observations together.

## 6. Provenance chains (as populated)

```text
Observation A:
source PA_FOSTER_ALLEGHENY_NBPB_FY2026_27
  -> dataset PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS
    -> source_record PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1
      -> citation CITE_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1
        -> evidence EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1 (SOURCE_OBSERVATION)
          -> claim_evidence (SUPPORTS)
            -> claim CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE (DIRECT_SOURCE_CLAIM)
              -> proposition: Allegheny County --subjectOf--> NBPB re-entry report event

Observation B:
source PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY
  -> dataset PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS
    -> source_record PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9
      -> citation CITE_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9
        -> evidence EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9 (SOURCE_OBSERVATION)
          -> claim_evidence (SUPPORTS)
            -> claim CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE (DIRECT_SOURCE_CLAIM)
              -> proposition: Allegheny County --subjectOf--> dashboard trend description event
```

Allegheny County is represented once, as a single `PLACE` entity
(`pa_foster_allegheny_county`), reused as the subject of both propositions. Reuse of the
same county entity is intentional: it establishes shared county scope without merging the
two observations into one claim, event, or proposition.

## 7. Unresolved fields (preserved, not fabricated)

| Field | Observation A (8.1%) | Observation B (~9%) |
|---|---|---|
| Numerator | `NUMERATOR_NOT_STATED` | `NUMERATOR_NOT_STATED` |
| Denominator | `DENOMINATOR_NOT_STATED` | `DENOMINATOR_NOT_STATED` |
| Cohort construction | `COHORT_PARTIALLY_STATED` | not established |
| Calculation method | `CALCULATION_NOT_RECONSTRUCTIBLE` | not established |
| Underlying profile period | `UNDERLYING_PROFILE_PERIOD_NOT_VERIFIED` | not established |
| Dashboard filter state | n/a | `EXACT_FILTER_STATE_NOT_VERIFIED` |
| Export/snapshot | n/a | `EXPORT_NOT_OBTAINED` / `SNAPSHOT_NOT_VERIFIED` |
| Relationship between A and B | `RELATION_TO_8_1_PERCENT_NOT_VERIFIED` | `RELATION_TO_8_1_PERCENT_NOT_VERIFIED` |

These markers are stored as plain text inside `evidence.notes` and `claim.notes` — the
existing generic structures — because the schema has no first-class structured column for
unresolved methodology. No schema change was made or considered necessary for this.

## 8. Classifications

| Item | Classification |
|---|---|
| County NBPB reports 8.1% | `ESTABLISHED` (source-reported) |
| County NBPB functional definition (12-month window, listed exit destinations) | `QUALIFIED` |
| County NBPB numerator/denominator/cohort/calculation/profile period | `UNRESOLVED` |
| Dashboard describes approximately 9% | `ESTABLISHED` (source-described) |
| Dashboard exact filter state, export, snapshot, arithmetic | `UNRESOLVED` |
| 8.1% equals approximately 9% | `NOT_SUPPORTED` |
| County/state performance comparison | `NOT_SUPPORTED` (not populated at all in this phase) |
| A first-class structured percentage-metric proposition (e.g., a `reentryRatePercent`
  predicate) | `NOT_YET_MODELED` |
| County scoping of both observations via the registered `subjectOf` predicate | `ESTABLISHED` |
| Runtime natural-language research probes for unresolved methodology (Q1–Q6 in
  `COUNTY_BOUNDED_PROVENANCE_POPULATION.md` §11) | `CANDIDATE_REQUIRES_REVIEW` / deferred,
  not executable without generic research-engine changes (see §10) |

## 9. Positive validation expectations and results

Executed with:

```sh
psql "$DATABASE_URL" -f schema/sql/001_core_schema.sql
psql "$DATABASE_URL" -f schema/sql/003_administration_workflow.sql
psql "$DATABASE_URL" -f tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql
psql "$DATABASE_URL" -f tests/validation/pa-foster-care-allegheny-county-bounded-provenance-validation.sql
```

Against a disposable local PostgreSQL 16 database (`berean_pa_test`, not a shared or
production database).

| Expectation | Result |
|---|---|
| Both observations have complete source→dataset→source_record→citation→evidence→claim_evidence→claim→proposition provenance | **PASS** |
| Both observations are explicitly county-scoped (`subjectOf` → Allegheny County `PLACE` entity) | **PASS** |
| 8.1% and approximately 9% remain separate claims/evidence paths | **PASS** |
| No proposition or claim equates them (no shared event, no `claim_relation` row) | **PASS** |
| No numeric denominator, inferred numerator, full 2018–2025 scope, or county/state comparison is persisted | **PASS** |
| Unresolved methodological fields remain documented in notes | **PASS** |
| No unsupported statewide or performance statement is present | **PASS** |
| No schema-specific foster-care table or new predicate is introduced | **PASS** |
| Repeated execution is idempotent (`ON CONFLICT` guards) | **PASS** — fixture re-run inserted 0 additional rows; validation still passed |
| Source identity/mapping remains conservative | **PASS** — only the unambiguous county self-identification is `ACTIVE`; no unrelated entity was mapped |

Full validation output on first run:

```
NOTICE:  ok: PA foster-care Allegheny County bounded provenance population is
county-scoped, dual-path, non-equated, provenance-complete, idempotent, and free
of unresolved-field fabrication.
```

Identical output on the second (idempotency) run.

## 10. Negative validation expectations and results

The validation script (`tests/validation/pa-foster-care-allegheny-county-bounded-provenance-validation.sql`)
raises an exception and aborts if any of the following is detected:

- a Pennsylvania statewide source, or literal `7.8%`, is present;
- either observation's text is missing or contaminated with the other's value;
- an evidence row lacks a linked citation;
- a claim's proposition is not scoped to Allegheny County via `subjectOf`;
- a claim lacks cited `SOURCE_OBSERVATION` support;
- either proposition persists a structured percentage `typed_value`;
- a `claim_relation` row links the two observations, or they share one event;
- either claim's notes no longer document its unresolved-field markers;
- an unsupported statewide/performance/full-period statement is present;
- county source-identity mapping is missing, not `ACTIVE`, or mapped to an unexpected
  entity;
- a metric-specific predicate (e.g., containing `reentry`, `percent`, `rate`) or an
  unexpected `entity_type` exists in the registry.

As a control, a `claim_relation` row equating the two claims was manually inserted into
the test database and the validation script correctly failed with:

```
ERROR:  pa-foster-allegheny: the 8.1% and approximately-9% observations were linked by a
claim relation
```

The row was then removed and the validation script passed again, confirming the negative
check is load-bearing rather than vacuous.

## 11. Architecture findings

- The existing generic model (`source` → `dataset` → `source_record` → `citation` →
  `evidence` → `claim_evidence` → `claim` → `proposition`) is sufficient to represent both
  county observations' provenance, source identity, and county scope without any schema
  change.
- Allegheny County is represented as a `PLACE` entity, consistent with existing corpus
  convention (`docs/02-domain/DOMAIN_MODEL.md`, "Entity").
- **No registered predicate exists for a generic reported percentage metric** on an
  `ENTITY`/`EVENT` subject (`schema/sql/001_core_schema.sql`, predicate registry). The only
  `ENTITY`/`EVENT` → `VALUE` predicates are domain-specific to the biblical corpus
  (`ageAtDeathYears`, `ageAtFatherhoodYears`, `yearsFromCreation`, `lengthCubits`,
  `widthCubits`, `heightCubits`). Reusing any of these for a foster-care re-entry
  percentage would be a semantic distortion forbidden by this task's instructions and by
  the project's core semantic rules (a Claim is not Truth; a Relationship is not Truth).
- Per instruction, the registry was **not** modified. Instead:
  - each observation is represented as its own reporting/description `event`
    (`event_type_code = 'OTHER'`);
  - the already-registered `subjectOf` predicate (`ENTITY` → `EVENT`) asserts only that
    Allegheny County is the subject of its own reporting event — establishing explicit
    county scope without encoding the percentage as a structured, potentially
    misleading fact;
  - the reported percentage value itself is classified **`NOT_YET_MODELED`** as a
    first-class structured proposition, and is preserved only as text in
    `evidence.observation` and `claim.notes`, per the existing generic model's own
    `statement`/`notes` conventions (`claim.statement` is optional display text;
    `claim.notes` and `evidence.notes` already carry qualifying detail elsewhere in the
    corpus, e.g. `tests/fixtures/143-...-fixture.sql`).
- This is a `CANDIDATE_REQUIRES_REVIEW` item for any future phase that wants a queryable
  structured percentage metric: it would require a new, carefully scoped, generic
  (non-foster-care-specific) predicate such as a reported-rate value predicate, reviewed
  against the existing biblical-corpus predicates for naming and semantic consistency.
  This report does not add that predicate.
- Runtime research probes (Q1–Q6 in `COUNTY_BOUNDED_PROVENANCE_POPULATION.md` §11) that ask
  natural-language questions about denominators, cohorts, or comparability are **deferred /
  not executable** against the current generic research engine (`src/repository.ts`)
  without application-code changes, which are out of scope for this phase. The generic
  `research()` traversal matches registered predicates and does not have a notion of
  "denominator not stated" as an answer; it can, at most, return the `subjectOf`
  propositions created here. This limitation is documented rather than worked around.

## 12. Explicit non-comparability boundary

No claim, proposition, evidence row, or dataset in this population compares Allegheny
County to Pennsylvania statewide, ranks the county, or asserts a performance conclusion.
The Pennsylvania 7.8% figure is not referenced anywhere in the populated rows. The
relationship between 8.1% and approximately 9% is explicitly marked
`RELATION_TO_8_1_PERCENT_NOT_VERIFIED` in both claims' notes and is enforced as
`NOT_SUPPORTED` by the negative validation in §10.

## 13. Pilot status

```text
PILOT_REVIEW_REQUIRED
```

This population phase demonstrates that Berean's existing generic architecture can
represent the two bounded county observations with complete provenance and without
semantic distortion, while leaving the structured percentage metric explicitly
`NOT_YET_MODELED`. It does not resolve the underlying methodology gaps identified in
`COUNTY_MEASURE_REPRODUCIBILITY.md` and `COUNTY_REENTRY_COMPARABILITY_CLOSURE.md`, and it
does not authorize `PILOT_SELECTED`.

## 14. Change-control statement

- **Created:**
  - `tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql`
  - `tests/validation/pa-foster-care-allegheny-county-bounded-provenance-validation.sql`
  - `docs/08-corpus/pa-foster-care-placement-reunification/COUNTY_BOUNDED_PROVENANCE_POPULATION_REPORT.md`
- **Modified:** no existing file.
- **`CORPUS_CHARTER.md`:** unchanged.
- **`SOURCE_INVENTORY.csv`:** unchanged.
- **Application code, schema, migrations, API contracts, generic research behavior:**
  unchanged.
- **`scripts/validation/run-postgres-validation.sh`:** unchanged. The new fixture and
  validation are corpus-specific, are not part of the shared reference-model regression
  suite, and are documented here to be run standalone against a disposable database
  (§9). Adding them to the shared runner was judged unnecessary and was avoided per this
  phase's instructions not to weaken or entangle existing checks with a single-corpus,
  single-county exercise.
- **Downloaded source documents / data/corpora artifacts:** none.
- **Database used for validation:** a disposable local PostgreSQL 16 database
  (`berean_pa_test`), not a shared or production database; it was created and used only
  for this verification and is not part of the committed repository state.

## 15. Validation commands and results (summary)

| Command | Result |
|---|---|
| `npm run typecheck` | pass |
| `npm run lint` | pass |
| `npm run build` | pass |
| `npm test` (175 tests, 5 files, against a freshly reset local PostgreSQL database) | pass |
| `psql -f schema/sql/001_core_schema.sql` then `003_administration_workflow.sql` | pass |
| `psql -f tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql` (first run) | pass, rows inserted |
| `psql -f tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql` (second run) | pass, 0 additional rows (idempotent) |
| `psql -f tests/validation/pa-foster-care-allegheny-county-bounded-provenance-validation.sql` (both runs) | pass |
| `psql -f scripts/validation/validate.sql` (generic reference-model validation, against the populated database) | pass |
| Manual negative-control injection of an equating `claim_relation` row | validation correctly failed, then passed again after removal |
