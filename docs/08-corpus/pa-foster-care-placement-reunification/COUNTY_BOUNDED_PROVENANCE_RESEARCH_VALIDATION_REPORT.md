# County-Bounded Provenance Research Validation Report

**Corpus:** `pa-foster-care-placement-reunification`
**Exercise:** independent scholarly/research validation of the county-bounded provenance population
**Executed:** August 21, 2026, 22:24–22:31 UTC
**Final disposition:** `RESEARCH_VALIDATION_BLOCKED`

## 1. Executive Summary

This exercise is an independent research validation, not a continuation of the population work. It executed a controlled research battery against Berean's existing runtime research pathway to determine what the county-bounded material can currently be retrieved, distinguished, established, and correctly refused.

The controlling finding is a starting-state finding:

> The county-bounded provenance population described in [`COUNTY_BOUNDED_PROVENANCE_POPULATION.md`](./COUNTY_BOUNDED_PROVENANCE_POPULATION.md) is a **documentation-only** design record. It creates no source, dataset, source record, citation, evidence, claim, or proposition rows, and no corpus fixture. The report states this explicitly in its §4, §14.1, §14.7, and §16 change-control statement.

Because no county rows exist, the research battery could not be executed *against a populated county corpus*. It was still executed in full against the runtime research pathway, which is the correct scholarly action: it verifies by retrieval, rather than by trusting documentation, that nothing county-scoped is represented, and it verifies that the pathway itself is live.

Separated findings:

- **Corpus integrity:** the corpus documentation set is internally consistent, and its own statements about non-population are accurate. No county material is persisted anywhere in the repository (fixtures, schema, ingestion manifests) or in the loaded database.
- **Provenance integrity:** no county provenance chain exists to audit. The generic provenance chain (`Claim → ClaimEvidence → Evidence → Citation → SourceRecord → Dataset → Source`) is intact for the existing corpora and passes structural provenance validation.
- **Research capability:** the runtime research pathway is functional and correctly returns `NOT_REPRESENTED` with `subject_resolution.status = NO_SUBJECT` for every county and statewide question, while a positive control on represented material returns `ESTABLISHED` with two provenance-bearing rows.
- **Epistemic restraint:** every question that would have required inferring a denominator, cohort, methodology, comparability, or equivalence was answered with a bounded non-answer. The engine explicitly states that "Absence of representation is not a denial," which is the correct epistemic posture and is *not* the same statement as "the corpus establishes that this is unknown."
- **Architectural limitations:** the deliberate negative control described for this corpus (rejection of an inserted `claim_relation` equating the 8.1% and ~9% observations) **does not exist in the repository** and could not be reproduced. A secondary audit shows that the current generic rules would not reject such a relation if it were inserted; §12 of the population report itself frames this control as future work.

Because the primary research subject was never populated, the exercise cannot certify the county-bounded corpus. It is reported as `RESEARCH_VALIDATION_BLOCKED` rather than as a pass or a failure: nothing was found to be broken, and nothing county-scoped was found to be established.

No schema, architecture, fixture, research-engine, or validation-rule change was made. No speculative remediation was performed.

## 2. Frozen Baseline

| Item | Value |
|---|---|
| Repository | `PapaDanielP/Project-Berean` |
| Base branch | `main` |
| Working branch | `copilot/update-county-bounded-provenance-report` |
| Starting commit | `e5cd68eebddb6d56871675c35d1a3ac7a6adde38` ("Initial plan") |
| Preceding corpus commit | `bef1a34` ("docs: document Allegheny bounded provenance population") |
| Date/time of exercise | 2026-08-21, 22:24–22:31 UTC |
| Runtime | Node.js v24.19.0, PostgreSQL 16.15, Vitest 3.2.7 |

### 2.1 Population report actually present

The task brief refers to `COUNTY_BOUNDED_PROVENANCE_POPULATION_REPORT.md`. That filename does not exist. The corresponding artifact in the repository is:

- [`COUNTY_BOUNDED_PROVENANCE_POPULATION.md`](./COUNTY_BOUNDED_PROVENANCE_POPULATION.md) — determination `BOUNDED_PROVENANCE_POPULATION_PARTIAL`, pilot status `PILOT_REVIEW_REQUIRED`.

Related corpus documents inspected:

- [`CORPUS_CHARTER.md`](./CORPUS_CHARTER.md)
- [`COUNTY_MEASURE_REPRODUCIBILITY.md`](./COUNTY_MEASURE_REPRODUCIBILITY.md)
- [`COUNTY_PILOT_FOLLOWUP_VERIFICATION.md`](./COUNTY_PILOT_FOLLOWUP_VERIFICATION.md)
- [`COUNTY_PILOT_SOURCE_RECORD_VERIFICATION.md`](./COUNTY_PILOT_SOURCE_RECORD_VERIFICATION.md)
- [`COUNTY_PILOT_SOURCE_REVIEW_ALLEGHENY.md`](./COUNTY_PILOT_SOURCE_REVIEW_ALLEGHENY.md)
- [`COUNTY_REENTRY_COMPARABILITY_CLOSURE.md`](./COUNTY_REENTRY_COMPARABILITY_CLOSURE.md)
- [`SOURCE_INVENTORY.csv`](./SOURCE_INVENTORY.csv)

### 2.2 County fixtures and records: none present

No county fixture exists. `tests/fixtures/` contains fixtures `010`–`146`, none of which reference Allegheny County, Pennsylvania foster care, or a re-entry measure. A repository-wide search for `allegheny` and `foster` matched only Markdown/CSV files under `docs/`:

```
docs/08-corpus/pa-foster-care-placement-reunification/*.md
docs/08-corpus/pa-foster-care-placement-reunification/SOURCE_INVENTORY.csv
docs/README.md
```

No source, citation, evidence, claim, or proposition record for the county material exists in any fixture, migration, or ingestion manifest.

### 2.3 Research pathway and validation rules inspected

- `src/repository.ts` — `BereanRepository.research()`: subject resolution over represented entity, event, and source-identity labels; `SUBJECT_BOUND_REGISTERED_PREDICATE_MATCH` and `EVENT_OBJECT_PARTICIPATION` traversals; bounded results metadata.
- `src/app.ts` — public runtime surface: `POST /api/research`, `GET /api/research/scope`.
- `src/worker/validation-executor.ts` — `checkSchema`, `checkProvenance`, `checkNegativeSemantic`, knowledge-table read-only snapshot comparison.
- `scripts/validation/validate.sql`, `tests/validation/blocking-cases.sh` — SQL validation and its self-tests.
- `tests/app/app.test.ts`, `tests/app/phase28-ingestion.test.ts`, `tests/app/documentation-links.test.ts`, `tests/app/explorer-contract.test.ts`, `tests/app/openapi-coverage.test.ts`.
- Prior scholarly validation work: `docs/04-data/PHASE30_SCHOLARLY_RESEARCH_VALIDATION.md`, `docs/04-data/PHASE31_END_TO_END_SCHOLARLY_RESEARCH_DEMONSTRATION.md` (Genesis 6:1–4 / Nephilim), `docs/04-data/PHASE32_CROSS_DOMAIN_SCHOLARLY_RESEARCH_GENERALIZATION.md` and `docs/phases/PHASE_33_ECLIPSE_DOMAIN_POPULATION_AND_RESEARCH.md` (1919 eclipse).

The Genesis 6:1–4 and 1919 eclipse validations both operate on **persisted fixtures**. That is the material difference between them and this exercise: they had a populated corpus to interrogate; this corpus has none.

### 2.4 Test baseline (before any change)

Commands were executed at commit `e5cd68e` after `npm ci`.

| Command | Result |
|---|---|
| `npm run typecheck` | exit 0 |
| `npm run lint` | exit 0, no findings |
| `npm run build` | exit 0 |
| `npm test` | 5 files, 175 tests — **intermittently 174 passed / 1 failed** (see §10.1) |
| `sh scripts/validation/run-postgres-validation.sh` | exit 0 |

## 3. Research Protocol

### 3.1 Method

1. The **primary** method is the existing public runtime research pathway. The application was started with `PORT=3210 npx tsx src/server.ts` against a PostgreSQL database loaded by `scripts/validation/run-postgres-validation.sh` (that is, every committed fixture). Each question was submitted as `POST /api/research` with `{"question": …, "datasetIds": []}` (unscoped, the broadest possible scope, so a county row would be returned if one existed).
2. Direct SQL inspection was used **only** as a secondary audit to confirm the retrieval results, never as a research answer.
3. Negative-control behavior was probed inside transactions that were rolled back, so the database was left unchanged. No fixture, rule, or test was modified.

### 3.2 Question selection

The battery mirrors the probes required by §11 and §12 of the population report and by the task brief, in five categories: direct provenance retrieval (Q1–Q3), boundary/scope reasoning (Q4–Q6), comparison reasoning (Q7–Q9), exclusion/negative research (Q10–Q11), and epistemic restraint (Q12–Q16). Two controls were added:

- **C1** (`Who were the Nephilim?`) — a question whose *subject* is represented but whose relation is not, to distinguish `NO_SUBJECT` from "subject resolved, no registered predicate matched".
- **C2** (`Who participated in seth_begetting?`) — a positive control that must return provenance-bearing rows, proving the pathway is live rather than uniformly empty.

### 3.3 Vocabulary discipline

The following are kept distinct throughout, because they are not interchangeable:

- *Berean establishes this* — a represented, source-backed, claim-asserted result.
- *Berean can retrieve evidence related to this* — retrieval without adjudication.
- *Berean cannot currently establish this* — an architectural/query boundary.
- *The corpus does not establish this* — a corpus-population boundary.
- *The question is semantically under-modeled* — the question presupposes semantics (metric comparability, denominator identity) the model does not represent.

In this exercise nearly every county answer falls into *the corpus does not establish this* — specifically, into its strongest form: **the corpus is not represented at all**.

## 4. Research Question Results

All rows below were obtained from `POST /api/research` at 2026-08-21 22:29 UTC against the fully fixture-loaded database. `NO_SUBJECT` denotes `plan.subject_resolution.status`.

| ID | Research Question | Result | Provenance | Status |
|---|---|---|---|---|
| Q1 | What county/place observations are represented? | `capability: NOT_REPRESENTED`; 0 results; `NO_SUBJECT`; limitation: "No represented subject was identified for subject-bound retrieval. Absence of representation is not a denial." | none — no county entity, source, or claim exists | `NOT_ESTABLISHED` (corpus not populated) |
| Q2 | What source supports the ~8.1% county observation? | `NOT_REPRESENTED`; 0 results; `NO_SUBJECT` | none | `NOT_ESTABLISHED` |
| Q3 | What source supports the ~9% county observation? | `NOT_REPRESENTED`; 0 results; `NO_SUBJECT` | none | `NOT_ESTABLISHED` |
| Q4 | Same geographic scope for both observations? | `NOT_REPRESENTED`; 0 results | none | `NOT_ESTABLISHED` |
| Q5 | Same reporting period? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` (documented `UNRESOLVED` in the population report; not represented in the graph) |
| Q6 | Same numerator/denominator definitions? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` |
| Q7 | Can Berean establish direct comparability? | `NOT_REPRESENTED`; 0 results. No comparability relation exists in the model even for populated corpora. | none | `NOT_ESTABLISHED` + `EXPECTED_LIMITATION` |
| Q8 | Can Berean establish one is higher than the other? | `NOT_REPRESENTED`; 0 results. Numeric magnitude comparison is not a research capability. | none | `EXPECTED_LIMITATION` |
| Q9 | Does ~9% confirm/corroborate/validate 8.1%? | `NOT_REPRESENTED`; `plan.classification: TRUTH_ASSERTION`; interpretation: "The request asks Berean to establish truth or proof. That relation is not represented by the predicate registry." | none | `PROHIBITED_BY_MODEL` |
| Q10 | Does the county-bounded population contain statewide 7.8%? | `NOT_REPRESENTED`; 0 results. Secondary audit: no row anywhere contains the statewide figure. | none | `ESTABLISHED` (absence verified by retrieval) |
| Q11 | Can the statewide 7.8% be retrieved as a county observation? | `NOT_REPRESENTED`; 0 results for "What re-entry rate is reported for Pennsylvania?" | none | `ESTABLISHED` (no leakage path; trivially, since neither observation is persisted) |
| Q12 | Denominator represented for 8.1%? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` |
| Q13 | Denominator represented for ~9%? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` |
| Q14 | Cohort definition for each? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` |
| Q15 | Calculation methodology for each? | `NOT_REPRESENTED`; 0 results | none | `UNRESOLVED` |
| Q16 | Is either percentage a rate from the same underlying population definition? | `NOT_REPRESENTED`; 0 results | none | `NOT_ESTABLISHED` + `EXPECTED_LIMITATION` |
| F | Negative control: inserted `claim_relation` equating the two observations must fail validation | Control **not present in the repository**; cannot be reproduced. Secondary audit shows the generic rules would not reject the analogous relation (§9). | n/a | `EXPECTED_LIMITATION` (control never implemented; **not** a regression of an existing control) |
| C1 | Control: `Who were the Nephilim?` | `NOT_REPRESENTED`; subject `RESOLVED`; "No registered predicate matched this question." | subject resolved from represented entity label | `EXPECTED_LIMITATION` (distinguishes resolved-subject from `NO_SUBJECT`) |
| C2 | Positive control: `Who participated in seth_begetting?` | `capability: ESTABLISHED`; 2 results; `plan.classification: EVENT_PARTICIPANT`, `traversal_shape: EVENT_OBJECT_PARTICIPATION` | `Event → Proposition → Claim → ClaimEvidence → Evidence → Citation → SourceRecord → Dataset → Source` | `RETRIEVED` / `ESTABLISHED` (pathway proven live) |

Statuses in the county rows must be read precisely. `NOT_ESTABLISHED` and `UNRESOLVED` here mean *the corpus does not represent this*, and specifically *this corpus is not persisted at all*. They do not mean the source material is silent, and they do not mean Berean examined county evidence and declined to conclude.

## 5. Provenance Findings

There is no county provenance chain to trace. The intended chain published in §5 of the population report —

```text
Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
```

— exists as design text only. No row of that chain is present for the NBPB 8.1% observation or the dashboard ~9% observation.

Secondary audit (SQL, read-only) against the fully fixture-loaded database:

```sql
SELECT 'entity', count(*) FROM entity
  WHERE canonical_name ILIKE '%allegheny%' OR canonical_name ILIKE '%pennsylvania%' OR canonical_name ILIKE '%foster%'
UNION ALL SELECT 'source', count(*) FROM source WHERE name ILIKE '%allegheny%' OR name ILIKE '%pennsylvania%' OR name ILIKE '%foster%'
UNION ALL SELECT 'dataset', count(*) FROM dataset WHERE name ILIKE '%allegheny%' OR name ILIKE '%foster%'
UNION ALL SELECT 'claim', count(*) FROM claim WHERE statement ILIKE '%re-entry%' OR statement ILIKE '%8.1%' OR statement ILIKE '%7.8%'
UNION ALL SELECT 'corpus', count(*) FROM corpus WHERE corpus_key ILIKE '%foster%' OR corpus_key ILIKE '%pa-%'
UNION ALL SELECT 'typed_value_pct', count(*) FROM typed_value WHERE numeric_value IN (8.1, 9, 7.8);
```

Every count returned `0`. `SELECT corpus_key, name FROM corpus` returned 0 rows in this database state.

The two county observations therefore remain distinct in the only place they exist — the documentation — and this exercise did nothing to merge, equate, or reinterpret them. The distinctness required by the population report is preserved trivially, not demonstrated by the engine.

The generic provenance machinery is intact and was exercised on the represented corpora: the `PROVENANCE` check reported `PROVENANCE_CHAIN_STRUCTURALLY_COMPLETE`, and control C2 returned rows carrying a complete `Evidence → Citation → SourceRecord → Dataset → Source` path.

## 6. Comparability Findings

**Berean cannot establish direct comparability between the 8.1% and ~9% observations.** Two independent reasons, at different levels:

1. **Corpus level (decisive here):** neither observation is represented. There is nothing to compare.
2. **Architecture level (would still hold if they were represented):** Berean's research pathway retrieves claim-asserted propositions through registered predicates. It has no metric-comparability relation, no denominator/cohort/period alignment semantics, and no numeric comparison operator. Q7, Q8, and Q16 are therefore *semantically under-modeled* questions: the model has no representation in which "these two percentages are directly comparable" could be asserted, other than an explicit source-backed claim that a source itself makes.

Numerical proximity (8.1 vs ~9) is not treated as semantic equivalence anywhere in this report. Q9 is the sharpest result: the engine classified the request as `TRUTH_ASSERTION` and refused it on the grounds that confirmation/proof is not a registered predicate semantics. That refusal is correct and is charter-aligned; it is the behavior that would have prevented accidental conflation had the corpus been populated.

This exercise makes **no** recommendation to add a comparability construct, a percentage/rate predicate, or metric metadata. The population report's §13 position stands: a concrete failing case on persisted material must be demonstrated before any such change is considered, and no such case can be demonstrated while the corpus is unpopulated.

## 7. Statewide Exclusion Findings

Q10 and Q11 were answered by retrieval, not by trusting §3.3 or §6 of the population report.

- Q10 (`What is the Pennsylvania statewide re-entry rate of 7.8 percent?`) → `NOT_REPRESENTED`, `NO_SUBJECT`, 0 results.
- Q11 (`What re-entry rate is reported for Pennsylvania?`) → `NOT_REPRESENTED`, `NO_SUBJECT`, 0 results.
- Secondary audit: no `typed_value` with numeric value 7.8, and no source, dataset, entity, or claim matching Pennsylvania statewide material.

The statewide 7.8% observation is outside any county-bounded research population, and no traversal returns it as a county observation. The **strength** of this result must be stated honestly: it is verified absence of *any* representation, not a demonstration that populated scope controls (dataset scoping, corpus membership, entity scope) successfully exclude a persisted statewide row. The latter remains untested.

## 8. Epistemic Restraint Findings

Correct refusals observed, each verified through the runtime pathway:

| Probe | Refusal actually returned |
|---|---|
| Q9 (confirmation/corroboration) | `plan.classification: TRUTH_ASSERTION`; "The request asks Berean to establish truth or proof. That relation is not represented by the predicate registry." |
| Q1–Q8, Q10–Q16 | `capability: NOT_REPRESENTED` with `subject_resolution.status: NO_SUBJECT` and the explicit non-denial limitation string: "No represented subject was identified for subject-bound retrieval. Absence of representation is not a denial." |
| C1 (represented subject, unregistered relation) | subject `RESOLVED`, then "No registered predicate matched this question. Berean cannot represent an answer from the available query capability." |

Three properties are demonstrated and are evidence of correctness:

1. **No fabrication.** No denominator, cohort, methodology, period, or comparison was invented for any question. Zero rows were returned for zero represented rows.
2. **No silent inference.** The engine does not return predicate-only cross-subject results, so a question naming an unrepresented county cannot pick up loosely related material from another domain.
3. **Absence is not denial.** The engine consistently reports absence of representation as a representational boundary rather than as a negative factual claim — precisely the distinction the corpus charter requires.

One restraint result must not be over-claimed: because the corpus is unpopulated, these refusals demonstrate the *engine's* restraint in general, not that Berean examined county evidence and correctly declined to reconstruct its methodology.

## 9. Negative-Control Findings

The task brief states that the population report documents a deliberately inserted `claim_relation` equating the two county observations that causes validation failure. **The repository contains no such control.** The population report's §12 instead lists the prohibited assertions and says: "A future corpus-specific validation *should fail* if any of these are persisted as unsupported claims or returned as established results." That is a statement of future work, not of implemented behavior. There is no county fixture and no county validation script in `tests/`.

Consequently the control could not be reproduced. Rather than weakening or inventing a rule, the existing generic controls were probed inside rolled-back transactions:

| Probe | Result | Interpretation |
|---|---|---|
| Insert `claim_relation` with `relation_type_code = 'EQUIVALENT_TO'` | Rejected: `violates foreign key constraint "claim_relation_relation_type_code_fkey" … (EQUIVALENT_TO) is not present in table "claim_relation_type"` | The controlled vocabulary (`CONTRADICTS`, `DUPLICATES`, `QUALIFIES`, `REFINES`, `SUPERSEDES`) blocks an invented equivalence relation type. |
| Insert `claim_relation … 'DUPLICATES'` between two arbitrary claims, then run `scripts/validation/validate.sql` | Accepted; validation exited 0 | An unsupported equivalence expressed through the *registered* `DUPLICATES` vocabulary is **not** rejected by the current SQL validation. |
| Same injection, then `checkNegativeSemantic()` | `NEGATIVE_SEMANTIC_FORBIDDEN_CAPABILITIES_ABSENT` (PASS) — no violation raised for the relation | The negative-semantic executor examines predicates, job types, and identity mappings; it does not examine `claim_relation` rows. |
| Register predicate `confirmsTruthOf`, then `checkNegativeSemantic()` | `FAIL` — `NEGATIVE_SEMANTIC_FORBIDDEN_PREDICATE_REGISTERED` | The generic prohibition on truth/proof/adjudication predicate semantics is intact and still fails as designed. |
| `tests/validation/blocking-cases.sh` (within the full validation run) | all 6 blocking cases blocked as expected; "All validation self-test cases passed." | Existing negative controls are not regressed. |

Classification: `EXPECTED_LIMITATION`, **not** `REGRESSION`. Nothing that previously failed now passes; the corpus-specific control was never implemented. No validation rule was modified, relaxed, or added in this exercise.

All probe transactions were rolled back. The database contents were unchanged by this exercise.

## 10. Regression Results

Executed at commit `e5cd68e` with `DATABASE_URL` pointing at a local PostgreSQL 16.15 `berean_test` database, after `npm ci`.

| # | Command | Covers | Result |
|---|---|---|---|
| 1 | `npm run typecheck` | typecheck | exit 0 |
| 2 | `npm run lint` | lint (`eslint "src/**/*.ts" "tests/app/**/*.ts"`) | exit 0, no findings |
| 3 | `npm run build` | build (`tsc -p tsconfig.json`) | exit 0 |
| 4 | `npm test` | unit tests, schema/fixture/provenance/idempotency/research/negative-control assertions across 5 Vitest files | 175 tests; 3 consecutive clean-database runs: **175 passed**; 2 earlier runs: **174 passed, 1 failed** (§10.1) |
| 5 | `sh scripts/validation/run-postgres-validation.sh` | schema validation, fixture validation, provenance validation, repeated-lifecycle idempotency, research/query validation, blocking negative cases | exit 0; final lines: "ok: loaded fixture data passes validation", 6 × "ok: blocked …", "All validation self-test cases passed." |

Before runs 4 and 5 the database was reset with `DROP SCHEMA IF EXISTS phase28_ingestion CASCADE; DROP SCHEMA public CASCADE; CREATE SCHEMA public;`, which the fixtures require because they apply `schema/sql/001_core_schema.sql` without `IF NOT EXISTS`.

There is no separate `typecheck`/`lint`/`build`/`test` target beyond the four npm scripts, and no county-specific validation target exists to run.

### 10.1 Intermittent pre-existing test failure (not caused by this exercise)

`tests/app/app.test.ts > read-only API > leases, recovers, and finalizes worker foundation jobs safely` failed twice and then passed on three consecutive clean-database runs:

```
AssertionError: expected 12 to be 11
 ❯ tests/app/app.test.ts:543:35
```

Line 543 asserts `Number(first?.job_id)` equals the *first* inserted job id after two workers claim concurrently via `Promise.all`. The immediately preceding assertion (line 542) already checks, order-independently, that the two workers claimed the two distinct jobs. The failing assertion additionally presumes that the worker whose promise is listed first wins the lower-id job, which is not guaranteed under concurrent `claimOne` execution.

Assessment: a pre-existing, order-dependent flake in the worker-lease test, entirely unrelated to the county corpus, the research pathway, provenance, or any negative control. It was **not** modified, skipped, or "fixed" here, because doing so is outside this exercise's change discipline. It is reported so the baseline is stated faithfully rather than as an unqualified "all tests pass".

## 11. Architectural Assessment

### 11.1 Confirmed capabilities

- The public runtime research pathway (`POST /api/research`) resolves subjects from represented entity, event, and source-identity labels and returns bounded, deterministic, provenance-bearing results (control C2: `ESTABLISHED`, 2 results, full traversal reported in `plan.traversal`).
- The engine refuses truth/proof/confirmation requests by classification (`TRUTH_ASSERTION`) rather than by attempting an answer.
- The engine distinguishes "no subject represented" (`NO_SUBJECT`) from "subject represented, no registered predicate matched", and reports absence as a representational boundary, not a denial.
- Structural provenance validation, schema validation, negative-semantic validation, read-only knowledge-table invariance, and the six SQL blocking cases all execute and behave as documented.
- The controlled `claim_relation_type` vocabulary prevents invented relation semantics such as `EQUIVALENT_TO` at the database level.

### 11.2 Confirmed limitations

- **The county-bounded corpus is not represented.** Every county research question is unanswerable for population reasons, not for architectural reasons.
- Berean has no metric-comparability semantics: no denominator, cohort, calculation-methodology, or reporting-period alignment representation, and no numeric comparison capability. Q7, Q8, and Q16 are under-modeled questions rather than retrieval failures.
- Negative-semantic validation does not inspect `claim_relation` rows. An unsupported semantic equivalence expressed through the registered `DUPLICATES` vocabulary passes current validation. The safeguard against that is currently editorial (corpus-specific validation, per §12 of the population report), not generic.
- The research pathway offers no way to ask "what does this corpus *not* establish?"; a negative research result is expressed only as an empty bounded result plus a limitation string.

### 11.3 Recommended future work

Recommended only where justified at the generic architecture level; none of these is required by, or specific to, this corpus, and none was implemented here.

1. **Populate before validating.** A research validation of a documentation-only design record cannot be completed. If the county material is to be validated, it must first be persisted as a corpus fixture (source → dataset → source record → citation → evidence → claim → proposition) under an explicit corpus scope, as the Genesis 6:1–4 and 1919 eclipse corpora were.
2. **Generic corpus-scoped negative validations.** The mechanism that would fail on a prohibited assertion should be expressible generically (a per-corpus prohibited-assertion validation), so any corpus can register its negative controls without adding domain-specific schema. This is a validation-layer capability, not a knowledge-model change.
3. **Consider whether `claim_relation` deserves a generic restraint check** — for example, requiring that a `DUPLICATES` relation between claims from different sources carry a justification, analogous to the existing `NEGATIVE_SEMANTIC_UNJUSTIFIED_ACTIVE_IDENTITY_MAPPING` rule for reconciliation. This is a generic provenance-restraint concern, not a foster-care requirement, and should only be pursued with a concrete failing case.

Explicitly **not** recommended: a percentage/rate predicate, metric/denominator/cohort tables, a comparability relation, Pennsylvania- or county-specific constructs, or any relaxation of validation rules.

## 12. Final Disposition

```text
RESEARCH_VALIDATION_BLOCKED
```

Rationale: the research battery was executed in full through the intended runtime pathway, the regression suite was executed in full, and no rule, fixture, or architecture was changed — but the primary subject of the validation, the county-bounded provenance population, does not exist as persisted data. A `RESEARCH_VALIDATION_PASS_WITH_EXPECTED_LIMITATIONS` disposition would incorrectly imply that populated county provenance was interrogated and correctly bounded. A `RESEARCH_VALIDATION_FAIL` would incorrectly imply that something behaved wrongly; nothing did. The exercise is therefore blocked on a starting-state precondition.

Unchanged by this report:

- Corpus pilot status remains **`PILOT_REVIEW_REQUIRED`**. No existing rule authorizes any transition, and this exercise does not create one.
- The population report's determination `BOUNDED_PROVENANCE_POPULATION_PARTIAL` is unchanged.
- Schema, fixtures, research engine, validation rules, charter, and all unrelated documents are unchanged. The only file added by this exercise is this report.
