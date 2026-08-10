# Phase 20 Report: Provenance Engine Capability Discovery and Evaluation Contract

## 1. Scope

Phase 20 is a **discovery and specification phase only**. It continues from the accepted Phase 19
state and produces a repository-grounded capability matrix plus a read-only evaluation contract. It
does **not** design a new Berean model and does **not** implement a provenance engine.

Explicitly in scope:

- extracting every explicit or implicit provenance decision already made by Phase 19 and prior
  phases, as those decisions actually exist in files in this repository;
- classifying each decision by mechanism, determinism, and genericity;
- specifying candidate read-only operations, their inputs, outputs, explanation payloads, and
  disposition;
- formalizing the epistemic non-equivalences Berean already depends on;
- recording where evaluation is currently **human semantic judgment** rather than executable rule.

Explicitly out of scope, and not done:

- no change to `schema/sql/001_core_schema.sql`;
- no new table, column, foreign key, or index;
- no new registry row (no `predicate`, `event_type`, `event_participation_role`,
  `claim_relation_type`, `claim_type`, `claim_status`, `evidence_type`, or `value_type` value);
- no `KnowledgeState` or `ProvenanceDecision` entity, no modal/epistemic-world ontology, no graph
  database, no inference engine, no automatic claim creation;
- no persistence structure for evaluation results, and no conversion of any evaluation result into
  a `Claim`, `Proposition`, `ClaimRelation`, or `Derivation`;
- no alteration of accepted Phase 6–19 semantics and no rewriting of fixtures to fit a proposal.

No deterministic helper suitable for safe generalization into engine behavior was found in the
repository. Every phase validator inspected is a **phase-scoped assertion script**, not a reusable
evaluator (see §11). Nothing was therefore generalized, and no engine behavior was implemented.

## 2. Baseline

Baseline was recorded **before** any file was modified, on PostgreSQL 16.14 against a fresh,
empty database.

### 2.1 Authoritative PostgreSQL validation

`scripts/validation/run-postgres-validation.sh` was executed end to end against a newly created
database. Result: **PASS**, exit code `0`, 120 `ok:` lines, zero `FAIL` lines. The run included
the core schema, the synthetic structural fixture, the negative-integrity fixture, both
`tests/validation/blocking-cases.sh` passes, all Genesis 1 slices, Phases 6–19 slices and coverage
reports, the STEP Bible acquisition manifest check and imported subset, the Phase 15/16/17/18/19
negative-case suites, and the final `scripts/validation/validate.sql` integrity rerun.

### 2.2 Baseline object counts

Counts observed in the freshly built baseline database match the accepted Phase 19 final counts
exactly:

| Object | Phase 19 report final count | Phase 20 observed baseline |
| --- | ---: | ---: |
| Source | 7 | 7 |
| Dataset | 7 | 7 |
| SourceRecord | 56 | 56 |
| Citation | 56 | 56 |
| Evidence | 58 | 58 |
| Entity | 44 | 44 |
| SourceIdentity | 10 | 10 |
| EntitySourceMapping | 10 | 10 |
| Event | 41 | 41 |
| Proposition | 135 | 135 |
| Claim | 146 | 146 |
| ClaimEvidence | 153 | 153 |
| ClaimRelation | 6 | 6 |
| Derivation | 3 | 3 |
| DerivationInput | (not reported) | 6 |
| Projected `event_participation` rows | 101 | 101 |

Additional baseline distributions, used later in this report as evidence:

| Distribution | Observed |
| --- | --- |
| `claim.claim_type_code` | `DIRECT_SOURCE_CLAIM` 143, `DERIVED_CLAIM` 3, `INTERPRETIVE_CLAIM` **0** |
| `claim.claim_status_code` | `ACTIVE` 145, `SUPERSEDED` 1, `RETRACTED` **0**, `UNDER_REVIEW` **0** |
| `evidence.evidence_type_code` | `SOURCE_OBSERVATION` 58, `ANALYTICAL_OBSERVATION` **0** |
| `claim_evidence.relation_type_code` | `SUPPORTS` 147, `CONTRADICTS` 6, `QUALIFIES` **0** |
| `entity_source_mapping.mapping_status_code` | `ACTIVE` 10; `PROPOSED`/`REJECTED`/`SUPERSEDED` **0** |
| Registry sizes | 22 predicates, 8 event types, 5 participation roles |
| Predicates that project participation | 5 (`participatesIn`, `subjectOf`, `parentIn`, `childIn`, `builderIn`) |
| Evidence rows lacking a citation | 0 |

### 2.3 Application baseline

| Check | Command | Result |
| --- | --- | --- |
| Dependency install | `npm ci` | exit 0 |
| Lint | `npm run lint` | **PASS** |
| Typecheck | `npm run typecheck` | **PASS** |
| Tests | `DATABASE_URL=... npm run test` | **PASS**, 7/7 in `tests/app/app.test.ts` |

### 2.4 Environment limitations

- PostgreSQL 16.14 is available locally; validation is genuinely executed, not simulated.
- `npm run test` requires `DATABASE_URL`; it was run against a separate disposable database
  (`berean_app`) because `tests/app/app.test.ts` loads the schema and two fixtures itself.
- No network source acquisition was attempted. Phase 20 acquires no source material, so the
  bounded manually-entered reference-point convention is untouched.
- Only one bounded 2 Samuel locator exists (`MT_2SA_6_3_7`) and it stores no `raw_content`,
  `content_hash`, or `quoted_text`. Every Phase 20 statement about what 2 Samuel 6:3–7 "records"
  is therefore constrained to the single stored observation `EV_MT_2SA_6_3_7`.

## 3. Repository evidence inspected

Inspected before writing anything, and cited throughout this report:

**Charter, architecture, and decisions**

- `docs/00-project/CHARTER.md`, `docs/00-project/PROJECT_OVERVIEW.md`
- `docs/01-architecture/ARCHITECTURE.md` — provenance chain, "Relationship = a semantic
  proposition predicate (a projection, not a table)", "A graph database is not required merely
  because the domain is graph-shaped", and the explicit statement that the physical baseline does
  **not** implement "an application, API, ingestion pipeline, separate relationship table,
  generalized inference engine, or graph store".
- `docs/02-domain/DOMAIN_MODEL.md`, `docs/03-schema/INFORMATION_SCHEMA.md`
- `docs/06-decisions/ADR-0001-claim-evidence.md` — explicit typed Claim↔Evidence many-to-many;
  `DERIVED_FROM` deliberately excluded as an evidential relation type.
- `docs/06-decisions/ADR-0002-epistemic-separation.md` — source ≠ evidence ≠ claim ≠ proposition ≠
  relationship ≠ truth.
- `docs/06-decisions/ADR-0003-reference-schema-boundaries.md` — "The baseline does not implement a
  generalized rule engine…"; event participation is an asserted statement naming its asserting
  claim; derived claims link to one derivation with method, assumptions, and inputs.
- `docs/05-validation/VALIDATION.md` — invariants, including **No implicit truth**.

**Physical schema (`schema/sql/001_core_schema.sql`, unmodified)**

- controlled-vocabulary tables and their seeded rows;
- the `predicate` registry, its `(predicate_code, subject_kind_code, object_kind_code)` unique key,
  its optional `event_participation_role_code`, and the check that a participation role is only
  allowed for `ENTITY → EVENT` predicates;
- `standingRequirementIn`, deliberately registered with **no** participation role so a standing
  requirement can never project as participation;
- `source_record` with `CHECK (raw_content IS NULL OR content_hash IS NOT NULL)` and
  `UNIQUE(dataset_id, source_record_key)`;
- `citation` with `UNIQUE(source_record_id, locator)` and optional `quoted_text`;
- `entity_source_mapping` with `mapping_status_code`, bounded `confidence`, `justification`,
  `supporting_evidence_id`, and the partial unique index `uq_active_entity_source_mapping`;
- `proposition` cardinality checks plus the composite FK into `predicate` that enforces term kinds;
- `claim.statement` with its comment: "Optional human-readable label. The proposition is
  authoritative";
- the `claim_rendering` view (label vs. rendered proposition);
- the `event_participation` **view**, the sole participation projection, which carries
  `asserting_claim_id`;
- `derivation`, `derivation_input` (exactly one of claim/evidence input), and the unique
  `claim.derivation_id`;
- `claim_evidence`, `claim_relation` (with `claim_id <> related_claim_id`).

**Validation infrastructure**

- `scripts/validation/run-postgres-validation.sh` — the authoritative ordering, including the
  Phase 19 block and the final integrity rerun.
- `scripts/validation/validate.sql` — 18 blocking invariants and 4 warnings; the only genuinely
  **generic, fixture-independent** validator in the repository.
- `tests/validation/blocking-cases.sh` — one clean case and six generic corruption cases.
- Every phase slice/coverage validator, `tests/validation/phase6-regression.sql` through
  `tests/validation/phase19-coverage-report.sql`.
- `tests/validation/phase15-artifact-negative-cases.sh`,
  `tests/validation/phase16-artifact-negative-cases.sh`,
  `tests/validation/phase17-negative-cases.sh`, `tests/validation/phase18-negative-cases.sh`,
  `tests/validation/phase19-negative-cases.sh`.
- Every fixture in `tests/fixtures/`, especially
  `tests/fixtures/090-phase19-ark-lifecycle-conflict-fixture.sql`.

**Phase reports**

- `docs/04-data/PHASE6_REPORT.md` … `docs/04-data/PHASE19_REPORT.md`,
  `docs/04-data/POPULATION_SPECIFICATION.md`, `docs/04-data/DATA_POLICY.md`,
  `docs/04-data/STEPBIBLE_ACQUISITION_REPORT.md`.

**Application**

- `src/repository.ts`, `src/app.ts`, `src/server.ts`, `src/types.ts`, `tests/app/app.test.ts`. The
  application is strictly read-only projection/search over the same relational model. It contains
  no evaluation, inference, classification, or provenance-decision logic.

## 4. Phase 19 decision inventory

Every one of the 18 corruption cases in `tests/validation/phase19-negative-cases.sh` was executed
**individually** against the baseline database and its actual failure was captured. The
"observed rejecting mechanism" column below is the real first error raised, not the case's label.
This distinction matters: in several cases the nominal intent and the actual blocking rule differ,
and the actual rule is coarser and phase-scoped.

| # | Case (as labelled) | Observed rejecting mechanism (actual first error) | Mechanism class | Deterministic / generic? |
| ---: | --- | --- | --- | --- |
| 1 | inferring Uzzah violated Exodus 25:15 | `phase19: forbids fabricated compliance, violation, causation, contradiction, or pole/ring-state claim keys` — a `claim_key ~*` regex in the phase slice | Phase-scoped SQL validator (string pattern) | Deterministic **on the fixture's naming convention only**; not generic |
| 2 | contradiction solely because transport methods differ | `phase19: no ClaimRelation is justified for the 2 Samuel 6:3-7 slice…` — blanket prohibition of any `claim_relation` touching the six Phase 19 claim keys | Phase-scoped SQL validator (key list) | Deterministic; **not** generic — it is a prohibition, not a classifier |
| 3 | ClaimRelation without valid underlying claims | `ERROR: insert or update on table "claim_relation" violates foreign key constraint "claim_relation_claim_id_fkey"` | Schema FK | Deterministic **and** generic |
| 4 | ClaimRelation without preserving both source-backed claims | same blanket Phase 19 `ClaimRelation` prohibition as case 2 — **not** an evidence-sufficiency test | Phase-scoped SQL validator | Deterministic; not generic; nominal intent not actually tested |
| 5 | claim without ClaimEvidence | `phase19: a Phase 19 direct claim lacks complete source-to-proposition provenance` (the generic `validate.sql` rule "non-derived claim lacks evidence" would also block it) | Phase-scoped validator, backed by a generic invariant | Deterministic; the underlying rule **is** generic |
| 6 | evidence without Citation | `phase19: every evidence row supporting a Phase 19 claim requires a citation` (generic analogue: "source observation lacks citation") | Phase-scoped validator, backed by a generic invariant | Deterministic; underlying rule generic |
| 7 | fabricated Scripture text/hash/quotation | `phase19: forbids fabricated raw_content or content_hash for 2 Samuel 6:3-7` | Phase-scoped validator (source-availability policy) | Deterministic; **policy**, not a truth test; conditionally generic |
| 8 | duplicate canonical Ark | `phase19: forbids duplicate canonical Ark entities` — `count(... ILIKE '%ark of the covenant%') <> 1` | Phase-scoped validator (name matching) | Deterministic on this string; **not** generic duplicate detection |
| 9 | duplicate Uzzah | `phase19: forbids duplicate Uzzah entities` — `lower(canonical_name) = 'uzzah'` | Phase-scoped validator (name matching) | Same as case 8 |
| 10 | unsupported participant | `phase19: expected exactly Ark, new cart, and Uzzah projected for the new-cart transport event` | Phase-scoped validator over the `event_participation` projection | Deterministic against an enumerated allow-list; not generic |
| 11 | fabricated pole/ring physical state | blocked by the **same** participant allow-list rule as case 10 | Phase-scoped validator | Deterministic; the "physical state" semantics are not themselves modelled |
| 12 | fabricated causal relationship | `phase19: forbids new predicates such as transportedOn, touched, causeOf…` — predicate-registry count check | Phase-scoped registry check (registry itself is generic) | Deterministic; registry closure **is** generic, the phase check is not |
| 13 | derived claim without DerivationInput | `phase19: forbids derived claims about the Phase 19 lifecycle/conflict slice` — blanket prohibition, **not** the derivation-input rule | Phase-scoped validator | Deterministic; the generic rule "derivation has no inputs" exists separately in `validate.sql` |
| 14 | derived claim used as its own input | same blanket Phase 19 `DERIVED_CLAIM` prohibition as case 13 | Phase-scoped validator | Generic self-input rule exists separately in `validate.sql` and in `blocking-cases.sh` |
| 15 | direct `event_participation` insertion | `ERROR: cannot insert into view "event_participation"` | Schema (view, no rule/trigger) | Deterministic **and** generic |
| 16 | arbitrary JSON artifact semantics | `phase19: forbids arbitrary JSON artifact semantics` — `information_schema.columns` type check | Phase-scoped structural check | Deterministic; conditionally generic |
| 17 | unsupported predicate/event type | `phase19: forbids new event_type rows such as TRANSPORT, CONSEQUENCE, or HANDLING` | Phase-scoped registry closure check | Deterministic; not generic (enumerated) |
| 18 | unjustified SourceIdentity/EntitySourceMapping | `phase19: forbids unjustified SourceIdentity/EntitySourceMapping rows for Uzzah or the new cart` | Phase-scoped validator (generic analogues exist: active mapping requires justification; reconciliation evidence must come from the same source) | Deterministic; underlying reconciliation rules generic |

### 4.1 Findings from the inventory

1. **Only three rejections are schema-level and fully generic**: cases 3 and 15 (FK, non-updatable
   view) and, indirectly, the composite predicate FK on `proposition`.
2. **The genuinely generic executable rule set is `scripts/validation/validate.sql`** (18 blocking
   invariants) plus the schema constraints. Those rules cover claim/evidence presence, provenance
   chain integrity, citation requirements, hash discipline, reconciliation justification and
   same-source evidence, controlled relation types, proposition cardinality, predicate/term-kind
   registration, derivation completeness, derivation self-input, and participation assertedness.
3. **Everything semantic in Phase 19 is enforced by prohibition, not by evaluation.** Phase 19 does
   not decide that "Uzzah violated Exodus 25:15" is unestablished; it forbids any row whose key
   matches a violation/compliance/causation pattern, and forbids any `ClaimRelation` or
   `DERIVED_CLAIM` touching the slice. This is a correct fixture guard and an **incorrect** basis
   for claiming implemented engine behavior.
4. **Named epistemic vocabulary is registered but unused**: `INTERPRETIVE_CLAIM` (0 rows),
   `ANALYTICAL_OBSERVATION` (0 rows), `QUALIFIES` on `claim_evidence` (0 rows), `UNDER_REVIEW` and
   `RETRACTED` statuses (0 rows), and `PROPOSED`/`REJECTED`/`SUPERSEDED` mapping statuses (0 rows).
   Capability therefore exists structurally but is **not exercised**.
5. **Prior phases contribute the only positive derivation evidence**: three `DERIVED_CLAIM` rows,
   each with a `Derivation` (method + assumptions) and two `DerivationInput` claim inputs — the two
   Masoretic/Septuagint chronology derivations and one cross-source shared-parentage derivation.
   These are the repository's only worked examples of a licensed derivation.
6. **The only recorded contradictions are numeric or attributive disagreements between traditions**
   (six `ClaimRelation` rows: five `CONTRADICTS`, one `SUPERSEDES`), all created by human judgment
   in fixtures, none produced by a rule.

## 5. Capability matrix

Column key: **Det.** = determinism (D deterministic, CD conditionally deterministic, SJ semantic
judgment, U unresolved). **Gen.** = genericity (G generic, PG potentially generic, DS
domain-specific, SJ semantic judgment, U unresolved). **Cand.** = future evaluator candidate.
**Persist.** = is persistence justified (NE no evidence, PF possible future need, DN demonstrated
need). **Action** = Phase 20 action.

States marked **(R)** are repository-established terminology; states marked **(P)** are proposed
future output vocabulary introduced by this report and **not** present in the repository.

| # | Capability | Repository evidence | Required inputs | Actual current rule | Result / classification states | Provenance gap | Required explanation | Current mechanism | Det. | Gen. | Cand. | Persist. | Action |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Provenance completeness of a claim | `validate.sql` "non-derived claim lacks evidence", "evidence has broken provenance", "source record has broken provenance chain"; Phase 19 slice §6 | claim | Non-derived claim must have ≥1 `claim_evidence`; evidence must resolve to `source_record` → `dataset` → `source` | pass/blocking exception (R); `COMPLETE`/`INCOMPLETE` (P) | none for existence; chain says nothing about sufficiency | which links exist, which are missing | Generic SQL validator + FKs | D | G | yes | NE | specify |
| 2 | Source availability for a question | Phase 19 report §Source availability; `MT_2SA_6_3_7` with NULL `raw_content`/`content_hash`/`quoted_text`; `data/external/*/MANIFEST.yaml` | question scope, locator set | Only manually entered reference points exist for 2 Samuel; no text stored | `SOURCE AVAILABILITY GAP` (R), `ACQUISITION PENDING` (R) | source text itself is absent by policy | which locators exist, what each observation states, what is not stored | Fixture + coverage report prose | CD | PG | investigate | PF | specify |
| 3 | Evidence sufficiency for a proposition | No repository rule computes sufficiency; Phase 19 §7 forbids instead | proposition, evidence set | none — absence of an evaluator | `NOT_ESTABLISHED` (P) | Berean records evidential *bearing* (`SUPPORTS`/`CONTRADICTS`/`QUALIFIES`), not sufficiency thresholds | which evidence bears on the proposition and why it is insufficient | Human semantic judgment | SJ | SJ | investigate | NE | investigate |
| 4 | ClaimEvidence typed bearing | `claim_evidence.relation_type_code` FK; ADR-0001 | claim, evidence | Relation type must be a registered vocabulary row | `SUPPORTS`/`CONTRADICTS`/`QUALIFIES` (R) | bearing is asserted by a curator, never computed | the typed links and their notes | Schema FK + `validate.sql` | D | G | yes | NE | specify |
| 5 | Source/citation integrity | `source_record` `CHECK (raw_content IS NULL OR content_hash IS NOT NULL)`; `citation UNIQUE(source_record_id, locator)`; `validate.sql` "source observation lacks citation" | evidence, citation | Source observations require a citation; imported content requires a hash | pass/blocking (R) | citation proves locatability, not accuracy | citation locator, source record, dataset, source | Schema CHECK + generic validator | D | G | yes | NE | specify |
| 6 | Source identity vs. canonical entity | `source_identity`, `entity_source_mapping`, `uq_active_entity_source_mapping`, `validate.sql` justification and same-source rules | source identity, entity | Active mapping needs justification; supporting evidence must come from the identity's own source; at most one active mapping per pair | `PROPOSED`/`ACTIVE`/`REJECTED`/`SUPERSEDED` (R) | only `ACTIVE` is exercised (10 rows); no confidence value is used to gate anything | mapping status, confidence, justification, supporting evidence | Generic validator + partial unique index | D | G | yes | NE | specify |
| 7 | Direct vs. derived claim | `claim_type` registry; `validate.sql` derived-claim rules; three worked derivations | claim | `DERIVED_CLAIM` ⇒ `derivation_id` NOT NULL and ≥1 `derivation_input`; non-derived ⇒ no derivation | `DIRECT_SOURCE_CLAIM`, `INTERPRETIVE_CLAIM` (unused), `DERIVED_CLAIM` (R) | the rule checks derivation *structure*, never derivation *licence* | claim type, derivation method/assumptions, inputs | Generic validator | D | G | yes | NE | specify |
| 8 | Derivation inputs and self-input rejection | `validate.sql` "derivation has no inputs" / "derived claim is an input to its own derivation"; `blocking-cases.sh` cases 5–6; Phase 19 slice §7 | derivation, claim | Structural: inputs must exist; a derived claim may not be its own input | pass/blocking (R); `ELIGIBLE`/`INELIGIBLE` (P) | no transitive cycle check beyond depth 1; no semantic licence test | inputs, method, assumptions, blocked cycles | Generic validator | D | G | yes | PF | specify |
| 9 | Unsupported inference rejection | Phase 19 negative cases 1, 11, 12; Phase 17/18 negative suites | proposed claim | Phase-scoped: forbid claim keys matching a pattern; forbid new predicates; forbid disallowed participants | `INTENTIONALLY EXCLUDED` (R) | rejection is by prohibition list, not by evaluating the inference | which inference was attempted and which licence is missing | Phase-scoped SQL validator | CD | DS | investigate | NE | investigate |
| 10 | Standing requirement representation | `standingRequirementIn` predicate (no participation role); `STANDING_REQUIREMENT` event type; Phase 17 report; Phase 19 slice §9 | entity, requirement event | A standing requirement asserts only that the requirement exists | `SUPPORTED` (R) | requirement existence carries no compliance information | requirement event, asserting claim, its evidence | Registry design + schema CHECK | D | G | yes | NE | specify |
| 11 | Historical event occurrence | `event` + `event_type`; `OTHER`/`DEATH` used for the 2 Samuel slice | event | Event exists and its participation is asserted by claims | `SOURCE-BACKED` (R) | occurrence establishes neither cause nor normative status | event, type, description, asserting claims, evidence | Schema + fixture | D | G | yes | NE | specify |
| 12 | Compliance determination | none — no compliance predicate, event type, or rule exists | requirement, event, actor | none | `NOT_ESTABLISHED` (P) | no source observation links the 2 Samuel occurrence to the Exodus requirement | requirement, candidate event, missing linking evidence | Human semantic judgment | SJ | SJ | no | NE | reject |
| 13 | Violation determination | Phase 19 negative case 1; no violation predicate | requirement, event, actor | Prohibited by key-pattern check | `NOT_ESTABLISHED` (P), `INTENTIONALLY EXCLUDED` (R) | same as row 12, plus missing physical-state evidence | requirement, event, missing evidence, blocked inferences | Phase-scoped validator + human judgment | SJ | SJ | no | NE | reject |
| 14 | Causation determination | Phase 19 negative case 12 (`causeOf` predicate rejected) | two events | Registry closure blocks a causal predicate | `INTENTIONALLY EXCLUDED` (R), `NOT_ESTABLISHED` (P) | no causal semantics in the registry, by decision | the two events, absence of causal licence | Registry closure + human judgment | D (block) / SJ (decide) | G (block) / SJ (decide) | no | NE | reject |
| 15 | Consequence representation | `uzzah_death_2sam6` typed `DEATH`; Phase 19 report §Observed-state | event | Represent occurrence only | `SOURCE-BACKED` (R) | proximity in a source slice is not consequence | event, subject, evidence, excluded causal reading | Fixture + phase validator | D | G | yes | NE | specify |
| 16 | Contradiction determination | six `ClaimRelation` rows, all curator-created; `validate.sql` only checks the relation type is registered | two claims | none — the type is validated, the judgment is not | `CONTRADICTS`/`QUALIFIES`/`REFINES`/`DUPLICATES`/`SUPERSEDES` (R) | no comparison semantics for scope, modality, negation, or qualification | both claims, their propositions, sources, and the axis of difference | Human semantic judgment | SJ | SJ | investigate | NE | investigate |
| 17 | Difference vs. contradiction | Phase 19 rejects "different transport methods" as contradiction; the accepted MT/LXX age contradictions are same-subject same-predicate numeric conflicts | two claims | Phase-scoped prohibition only | `DOCUMENTED UNRESOLVED DECISION` (R); `DIFFERENT`/`CONTRADICTORY`/`UNDECIDABLE` (P) | see §12 — several needed dimensions are unmodelled | which dimensions match, which differ, which are unmodelled | Human semantic judgment | SJ | PG (partial) | investigate | NE | investigate |
| 18 | Physical state of an object at a time | Phase 19 negative case 11; no state predicate; `poles_ark_covenant`/`rings_ark_covenant` carry no state proposition | object, time/event | Prohibited for the Phase 19 slice | `SOURCE AVAILABILITY GAP` (R) | no source observation states pole/ring position during 2 Samuel 6:3–7 | object, requested state, absent evidence | Phase-scoped validator | D (block) / U (model) | DS | investigate | NE | defer |
| 19 | Temporal reasoning | `precedes`, `occursAt`, `yearsFromCreation` predicates; Phase 19 slice forbids chronology for its own events | events | Only explicitly asserted temporal propositions exist | `SOURCE-BACKED` when asserted (R); otherwise unmodelled | no interval, calendar, or ordering algebra | asserted temporal propositions and their evidence | Schema + fixtures | D (retrieval) / U (reasoning) | PG | investigate | NE | defer |
| 20 | Event participation | `event_participation` **view**; participation-role column on `predicate`; case 15 (view not insertable) | event | Participation exists iff a claim asserts a role-bearing proposition | projected rows with `asserting_claim_id` (R) | participation is assertion, not verification | each participating entity, role, and asserting claim | Schema view + registry | D | G | yes | NE | specify |
| 21 | Dependency path of a claim | Derivation/DerivationInput graph; `claim_evidence`; `event_participation.asserting_claim_id` | claim | none — no traversal exists in SQL or in `src/` | `DEPENDENTS`/`DEPENDENCIES` sets (P) | derivation depth is 1 everywhere; nothing exercises deep traversal | claims/evidence upstream and downstream, and projection rows that would change | Human inspection | D (traversal) | G | yes | NE | specify |
| 22 | ClaimRelation classification | see rows 16–17 | two claims | none | as row 16 | as rows 16–17 | as row 16 | Human semantic judgment | SJ | SJ | investigate | NE | investigate |
| 23 | Unsupported predicate / event type rejection | composite FK `proposition → predicate`; `validate.sql` "unregistered predicate or term kind"; Phase 19 slice §2 | proposition | Predicate and its subject/object kinds must be registered | pass/blocking (R) | registry closure is deliberate policy, not truth | the predicate, the required kinds, the registry entry | Schema FK + generic validator | D | G | yes | NE | specify |
| 24 | Arbitrary JSON semantics rejection | Phase 19 negative case 16; `information_schema.columns` check | schema | No `json`/`jsonb` column on `entity`/`proposition`/`claim`/`event` | pass/blocking (R) | structural guard only | which table/column violated the rule | Phase-scoped structural check | D | PG | yes | NE | specify |
| 25 | Projection integrity | `event_participation` view definition; `validate.sql` "event participation is not fully asserted"; case 15 | database | Every projected row must name a live asserting claim | pass/blocking (R) | projection cannot be more authoritative than its claims | claim, proposition, predicate, role | Schema view + generic validator | D | G | yes | NE | specify |
| 26 | Fabricated source content rejection | Phase 19 negative case 7; `source_record` CHECK; `data/*/README.md` policy | source record, citation | This repository stores no Scripture text; `raw_content`, `content_hash`, `quoted_text` stay NULL for manually entered reference points | pass/blocking (R) | prevents fabrication; does not verify real content | which field was populated and the storage policy | Schema CHECK + phase validator + policy | D | PG | yes | NE | specify |
| 27 | Source gap identification | Phase 19 coverage report row "Pole/ring physical state … SOURCE AVAILABILITY GAP" | question | none executable — the classification is authored prose | `SOURCE AVAILABILITY GAP` (R), `ACQUISITION PENDING` (R) | Berean cannot enumerate what a source *does not* say | requested proposition, searched locators, absent observations | Human judgment recorded in a coverage report | SJ | PG | investigate | PF | investigate |
| 28 | Semantic precision gap | Phase 16 and Phase 19 coverage rows "SEMANTIC PRECISION GAP" | modelling question | none executable | `SEMANTIC PRECISION GAP` (R) | registry deliberately lacks touched/cart/causal vocabulary | which query-level distinction is unavailable and why it was not added | Human judgment recorded in a coverage report | SJ | SJ | no | NE | defer |
| 29 | Unresolved decision recording | Phase 19 coverage row "DOCUMENTED UNRESOLVED DECISION" | decision | none executable | `DOCUMENTED UNRESOLVED DECISION` (R) | unresolved status lives in documents, not in data | the competing options and why neither is licensed | Human judgment recorded in a coverage report | SJ | SJ | no | NE | defer |
| 30 | Claim label vs. authoritative semantics | `claim.statement` comment; `claim_rendering` view | claim | The proposition is authoritative; the label is display text | rendered proposition vs. display label (R) | a divergent label is visible but not blocked | both strings, side by side | Schema view | D | G | yes | NE | specify |

## 6. Provenance status model

**Provenance status answers only: what can Berean establish?** It is a statement about the
repository's evidential reach, never about the world.

### 6.1 Repository-established status vocabulary

These strings already exist in `tests/validation/phase19-coverage-report.sql` (and its Phase 15–18
predecessors) and are therefore authoritative Berean terminology today:

| Status | Established meaning |
| --- | --- |
| `SOURCE-BACKED` | A populated source record, citation, and evidence row support the assertion. |
| `SUPPORTED` | An existing prior-phase assertion remains intact and evidence-backed. |
| `NOT DERIVED` | No derived claim was produced; nothing was inferred. |
| `INTENTIONALLY EXCLUDED` | A candidate assertion was deliberately not made. |
| `SOURCE AVAILABILITY GAP` | The populated sources do not address the question. |
| `ACQUISITION PENDING` | Material is out of the bounded acquisition scope. |
| `DOCUMENTED UNRESOLVED DECISION` | A modelling/semantic decision is deliberately open. |
| `SEMANTIC PRECISION GAP` | A query-level distinction is unavailable and was not added. |
| `RUNTIME VERIFIED` | Verified by an executed validation run. |

Structural vocabularies also exist in the schema and are distinct from the above:
`claim_type` (`DIRECT_SOURCE_CLAIM`, `INTERPRETIVE_CLAIM`, `DERIVED_CLAIM`), `claim_status`
(`ACTIVE`, `SUPERSEDED`, `RETRACTED`, `UNDER_REVIEW`), `mapping_status`, `evidence_type`,
`claim_evidence_relation_type`, and `claim_relation_type`.

### 6.2 Proposed future evaluation-output states (not in the repository)

The following are **proposed** in this report as candidate *evaluation outputs*. They are not
registry rows, not claim statuses, and not persisted anywhere:

| Proposed status | Meaning | Explicit non-meaning |
| --- | --- | --- |
| `ESTABLISHED` | A claim with complete provenance asserts the proposition. | Not "true". |
| `NOT_ESTABLISHED` | Berean cannot establish it from current data and rules. | Not "false". |
| `CONTESTED` | Competing claims with preserved provenance exist. | Not "unresolved truth". |
| `BLOCKED_BY_RULE` | An architectural rule forbids the inference. | Not "disproved". |
| `SOURCE_AVAILABILITY_GAP` | The needed observation is not populated. | Not "the source is silent" and not "absence". |
| `REQUIRES_SEMANTIC_JUDGMENT` | Only a human can decide with current semantics. | Not "unknowable". |

Any adoption of these strings requires an independently justified future phase. Phase 20 does not
adopt them.

## 7. Provenance gap model

**Provenance gap answers only: why can Berean not establish more?** A gap is a statement about the
system, not about reality. Five gap kinds are distinguishable from repository evidence:

1. **Source availability gap** — no populated `source_record`/`evidence` addresses the proposition.
   Evidence: only `MT_2SA_6_3_7` exists for 2 Samuel, storing no text; pole/ring state is classified
   `SOURCE AVAILABILITY GAP` in the Phase 19 coverage report.
2. **Representational gap** — no registered predicate or event type can express the proposition.
   Evidence: `causeOf`, `touched`, `violatedRequirement`, `complianceWith` are all rejected by the
   registry closure (`proposition`'s composite FK, plus Phase 19 negative cases 12 and 17).
3. **Derivation licence gap** — the inputs exist, but no method/assumption set licenses the step.
   Evidence: the three accepted `Derivation` rows each carry an explicit `method` and `assumptions`;
   the Phase 19 slice forbids any derived claim about its own entities because no such licence was
   established.
4. **Semantic judgment gap** — the decision requires human semantics Berean does not model.
   Evidence: contradiction classification, compliance, and difference-vs-contradiction have no rule
   anywhere in `scripts/` or `tests/`.
5. **Unresolved decision gap** — the modelling choice is deliberately open and documented.
   Evidence: the "Relationship among Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7" coverage row.

A gap must never be reported as `FALSE`, as absence of the fact, or as a defect in the source.

## 8. Provenance explanation model

**Provenance explanation answers: on what basis?** An explanation is a structured, read-only
payload assembled from rows that already exist. Every field below maps to real columns; no field
requires a new structure.

| Explanation field | Repository source |
| --- | --- |
| `supporting_evidence[]` | `claim_evidence` (`SUPPORTS`) → `evidence` → `evidence_citation` → `citation` → `source_record` → `dataset` → `source` |
| `contrary_evidence[]` | `claim_evidence` (`CONTRADICTS`) along the same chain |
| `qualifying_evidence[]` | `claim_evidence` (`QUALIFIES`) — registered, currently unused |
| `missing_evidence[]` | the proposition components for which no evidence row exists (computable only as an absence report, never as a denial) |
| `rules_applied[]` | the named blocking invariants in `scripts/validation/validate.sql` and the schema constraints that participated |
| `blocked_inferences[]` | the inference steps refused, each with the gap kind from §7 |
| `relevant_claims[]` | claims over the same `proposition_id`, and claims linked by `claim_relation` |
| `claim_relations[]` | `claim_relation` rows with `relation_type_code` and `notes` |
| `derivation_inputs[]` | `derivation` (`method`, `assumptions`) + `derivation_input` claim/evidence inputs |
| `dependencies[]` | upstream claims/evidence; downstream `event_participation` projection rows via `asserting_claim_id` |
| `source_records[]` | distinct `source_record` rows with `source_location`, and an explicit note when `raw_content`/`quoted_text` are NULL by policy |

Explanations must state the storage policy explicitly, because a NULL `quoted_text` in this
repository means "text deliberately not stored", **not** "the source says nothing".

## 9. Provenance semantics findings

Question: can the repository distinguish (a) what a source record asserts/reports/quotes/
attributes, (b) a researcher's interpretation, (c) a Berean derivation, and (d) inability to
establish?

| Distinction | Verdict | Evidence |
| --- | --- | --- |
| A source **record** exists and is locatable | **Representable** | `source_record.source_location`, `citation.locator`, `UNIQUE(source_record_id, locator)` |
| A source **asserts/reports** something | **Representable** | `evidence.observation` with `evidence_type_code = 'SOURCE_OBSERVATION'`, cited, linked to claims via `claim_evidence` |
| A source **quotes** text verbatim | **Partially representable** | `citation.quoted_text` and `source_record.raw_content`/`content_hash` exist, but this repository stores none of them by policy; only the STEP Bible subset carries imported structure |
| A source **attributes** a statement to a further party | **Not currently representable** | no attribution predicate, no nested-assertion structure, no reported-speech modelling; `INSTRUCTION` events record commanded acts, which is not the same thing |
| A **researcher interpretation** | **Partially representable** | `claim_type_code = 'INTERPRETIVE_CLAIM'` and `evidence_type_code = 'ANALYTICAL_OBSERVATION'` are registered — but both have **0 rows**, so the capability is structural and unexercised |
| A **Berean derivation** | **Representable and exercised** | 3 `DERIVED_CLAIM` rows, each with `derivation.method` + `assumptions` and 2 `derivation_input` rows |
| **Inability to establish** | **Not representable as data** | it exists only as authored prose classifications in coverage reports; there is no row, status, or view expressing "not established" |
| **Preserved disagreement** | **Representable and exercised** | 6 `claim_relation` rows preserving MT/LXX and Bezalel/Moses disagreements without reconciliation |
| **Withdrawal / supersession** | **Partially representable** | `claim_status` has `SUPERSEDED` (1 row) and `RETRACTED`/`UNDER_REVIEW` (0 rows) |

Principal finding: **Berean can represent what is asserted and what is derived, but has no data
representation for what it cannot establish.** That asymmetry is exactly the gap a future read-only
evaluator would address — and, importantly, it can be addressed *without persistence*, by computing
the negative result at read time.

## 10. Candidate read-only operations

All seven are **specifications only**. None is implemented in this phase. None writes any row.
None creates a `Claim`, `Proposition`, `ClaimRelation`, or `Derivation`. "Current equivalent" names
what exists today, which in every case is either a generic invariant, a phase-scoped assertion
script, or a human.

### 10.1 `EVALUATE_PROPOSITION`

- **Inputs**: a proposition specification (subject term, registered predicate, object term), plus
  optional scope filters (source, dataset, claim status).
- **Evaluation**: match registered predicate and term kinds; find `proposition` rows; find `claim`
  rows over them; verify each claim's provenance chain; collect competing claims and relations.
- **Structured output**: `status` from §6.2, `matched_propositions[]`, `asserting_claims[]`,
  `competing_claims[]`, `gap` (§7 kind or null).
- **Explanation payload**: full §8 payload.
- **Determinism**: **deterministic** for `ESTABLISHED`/`CONTESTED` (pure retrieval + existing
  invariants); **conditionally deterministic** for `NOT_ESTABLISHED`, which is only ever
  "not established *from currently populated data under current rules*".
- **Current equivalent**: none. `src/repository.ts` retrieves claims and provenance for display but
  performs no evaluation or classification.
- **Disposition**: **IMPLEMENT LATER** — smallest genuinely useful evaluator; see §22/D.

### 10.2 `EXPLAIN_SUPPORT`

- **Inputs**: a claim identifier.
- **Evaluation**: traverse `claim_evidence` → `evidence` → `evidence_citation` → `citation` →
  `source_record` → `dataset` → `source`; include derivation inputs when the claim is derived.
- **Structured output**: `supporting_evidence[]`, `qualifying_evidence[]`, `contrary_evidence[]`,
  `source_records[]`, `derivation` (nullable), `chain_complete` boolean.
- **Explanation payload**: per-link locators, relation types, notes, and explicit "text not stored"
  markers.
- **Determinism**: **deterministic** — pure traversal.
- **Current equivalent**: partially, `src/repository.ts` claim detail plus the `validate.sql`
  provenance invariants; assembled per request, never as a contract.
- **Disposition**: **IMPLEMENT LATER**.

### 10.3 `EXPLAIN_REJECTION`

- **Inputs**: a proposed proposition or claim shape that was refused.
- **Evaluation**: identify which mechanism refuses it — registry closure (composite FK on
  `proposition`), a named blocking invariant in `validate.sql`, a schema CHECK/FK, projection
  read-only-ness, or human judgment.
- **Structured output**: `rejecting_mechanism`, `rule_name`, `mechanism_class` (constraint / FK /
  check / registry / SQL validator / projection / provenance rule / derivation rule / human
  semantic judgment), `is_deterministic`.
- **Explanation payload**: the exact rule text and what would have to change for the shape to be
  admissible.
- **Determinism**: **deterministic** for mechanised refusals; **semantic judgment** where the
  refusal is a curator decision (Phase 19 cases 1, 2, 4, 13, 14 are curator prohibitions, per §4).
- **Current equivalent**: the phase negative-case suites, which prove *that* something is blocked
  but do not report *which rule* blocked it — as §4 shows, the label and the actual rule can differ.
- **Disposition**: **IMPLEMENT LATER** (deterministic subset only).

### 10.4 `EXPLAIN_GAP`

- **Inputs**: a proposition that was not established.
- **Evaluation**: classify the gap using §7; enumerate searched locators and absent observations.
- **Structured output**: `gap_kind`, `searched_scope[]`, `absent_observations[]`,
  `representable` boolean, `acquisition_candidates[]`.
- **Explanation payload**: an explicit statement that a gap is not falsity and not absence in the
  world.
- **Determinism**: **conditionally deterministic** — enumeration of what exists is deterministic;
  deciding *which* observations "would have been" relevant is semantic judgment.
- **Current equivalent**: authored coverage-report rows such as "Pole/ring physical state …
  SOURCE AVAILABILITY GAP".
- **Disposition**: **SPECIFY ONLY**.

### 10.5 `CHECK_DERIVATION_ELIGIBILITY`

- **Inputs**: a proposed derived claim, a proposed method + assumptions, and proposed inputs.
- **Evaluation**: structural only — every input must exist and be provenance-complete; the proposed
  claim may not be its own input; no input may be transitively derived from the proposed claim;
  the target proposition's predicate/term kinds must be registered.
- **Structured output**: `structurally_eligible` boolean, `failed_checks[]`, `input_status[]`,
  `licence_status` = `REQUIRES_HUMAN_METHOD_JUSTIFICATION` (always).
- **Explanation payload**: which inputs are complete, which cycles were detected, and the explicit
  statement that structural eligibility is **not** a derivation licence.
- **Determinism**: **deterministic** for the structural part; the licence itself is permanently
  semantic judgment, since `derivation.method`/`assumptions` are free text authored by a curator.
- **Current equivalent**: the `validate.sql` derivation invariants and `blocking-cases.sh` cases 5–6
  — depth-1 checks, applied post hoc rather than as a pre-check.
- **Disposition**: **IMPLEMENT LATER** (structural checks only).

### 10.6 `CLASSIFY_CLAIM_RELATION`

- **Inputs**: two claim identifiers.
- **Evaluation**: compare the authoritative propositions across the dimensions in §12.
- **Structured output**: `same_subject`, `same_predicate`, `same_object`, `object_value_conflict`,
  `same_event`, `scope_comparable`, `suggested_relation` (nullable), `requires_human_review`.
- **Explanation payload**: which dimensions matched, which differ, which are unmodelled.
- **Determinism**: **semantic judgment** for the classification; the dimension comparison itself is
  deterministic but insufficient (§12).
- **Current equivalent**: human curation. All six `claim_relation` rows were authored in fixtures.
- **Disposition**: **INVESTIGATE** — a *comparison reporter* may be justified; a *classifier* is not.

### 10.7 `ANALYZE_DEPENDENCY_IMPACT`

- **Inputs**: a claim or evidence identifier and a hypothetical action (retract, supersede, revise).
- **Evaluation**: traverse only existing structures — `derivation_input` upward and downward,
  `claim_evidence`, `claim_relation`, and `event_participation.asserting_claim_id`.
- **Structured output**: `dependent_claims[]`, `dependent_derivations[]`,
  `affected_projection_rows[]`, `affected_relations[]`, `invariants_at_risk[]`.
- **Explanation payload**: the path from the target to each dependent, and which `validate.sql`
  invariant would be violated.
- **Determinism**: **deterministic** — pure graph traversal over existing foreign keys.
- **Current equivalent**: none. No traversal exists in SQL or in `src/`. No dependency table exists
  and none is proposed.
- **Disposition**: **IMPLEMENT LATER** (low value today — maximum derivation depth is 1 — but
  entirely safe and additive).

## 11. Determinism analysis

Classification of every mechanism actually present in the repository:

| Mechanism class | Where | Determinism | Genericity |
| --- | --- | --- | --- |
| Schema constraints (PK, FK, UNIQUE, CHECK, partial unique index, generated columns) | `schema/sql/001_core_schema.sql` | Deterministic | Generic |
| Registry closure (composite FK `proposition → predicate`) | same file | Deterministic | Generic |
| Non-updatable projection view | `event_participation` | Deterministic | Generic |
| Generic blocking invariants (18) | `scripts/validation/validate.sql` | Deterministic | Generic |
| Generic corruption self-tests (6) | `tests/validation/blocking-cases.sh` | Deterministic | Generic |
| Phase-scoped slice validators | `tests/validation/phase*-slice.sql` etc. | Deterministic **against their own fixture** | Domain-specific |
| Phase-scoped negative suites | `tests/validation/phase*-negative-cases.sh` | Deterministic **against their own fixture** | Domain-specific |
| Coverage classification rows | `tests/validation/phase*-coverage-report.sql` | Authored constants — **not** computed | Semantic judgment |
| Application read paths | `src/repository.ts` | Deterministic retrieval | Generic, but performs no evaluation |
| Compliance / violation / causation / contradiction decisions | nowhere | Semantic judgment | Semantic judgment |

**Classification of the current state, stated precisely:**

- **RUNTIME VERIFIED**: schema constraints, the 18 generic invariants, the 6 generic self-tests, the
  18 Phase 19 corruption cases, and every phase slice/coverage validator — all executed and passing
  in this phase's baseline and regression runs.
- **CONCEPTUALLY DEMONSTRATED**: the Phase 19 reference case's `NOT_ESTABLISHED` result (§12–§14)
  is demonstrated by argument over real rows, not computed by any code.
- **SPECIFIED BUT NOT IMPLEMENTED**: every operation in §10.
- **SEMANTIC JUDGMENT**: compliance, violation, causation, contradiction classification,
  difference-vs-contradiction, evidence sufficiency, derivation licence, gap relevance.
- **SOURCE AVAILABILITY GAP**: pole/ring physical state; any 2 Samuel content beyond the single
  stored observation.
- **NOT CURRENTLY JUSTIFIED**: persistence of evaluation results; any `KnowledgeState` or
  `ProvenanceDecision` entity; modal/epistemic-world ontology; graph database; automatic claim
  creation.

**Explicit warning, restated because §4 makes it easy to get wrong:** the coverage reports print
authored constants and the phase validators enforce fixture-specific prohibitions. Neither is
implemented engine behavior. Berean today has **no** provenance engine, and this report does not
create one.

### 11.1 Formal non-equivalences

These are stated as architectural commitments, consistent with `docs/05-validation/VALIDATION.md`
("No implicit truth") and ADR-0002:

| Non-equivalence | Meaning | Repository grounding |
| --- | --- | --- |
| `UNKNOWN != FALSE` | Absence of a claim is not a negative claim. | No negation predicate exists; nothing in the schema encodes "not P". |
| `NOT_ESTABLISHED != FALSE` | Failure to establish reflects data and rules, not the world. | Phase 19 refuses the violation claim without asserting non-violation. |
| `SOURCE_AVAILABILITY_GAP != ABSENCE` | "Not populated here" is not "the source is silent". | `MT_2SA_6_3_7` stores no text at all, by policy. |
| `DIFFERENCE != CONTRADICTION` | Distinct descriptions are not logical conflict. | Phase 19 rejects contradiction between Joshua 3:6 and 2 Samuel 6:3–7. |
| `SOURCE-BACKED != UNIVERSALLY TRUE` | Provenance is traceability, not truth. | ADR-0002; `VALIDATION.md` "No implicit truth". |
| `EVENT OCCURRENCE != CAUSATION` | Adjacency in a source slice is not cause. | No causal predicate; `causeOf` is rejected by registry closure. |
| `STANDING REQUIREMENT != COMPLIANCE/VIOLATION` | A requirement's existence says nothing about conduct. | `standingRequirementIn` carries no participation role and projects nothing. |

**Evaluation is not graph knowledge.** An evaluation result is a read-time answer about the state
of the repository. It becomes graph knowledge only if some future, independently justified
mechanism turns it into a `Proposition` asserted by a `Claim` with its own provenance. Phase 20
proposes no such mechanism.

## 12. Difference-versus-contradiction analysis

Dimensions available for comparison, assessed against the actual schema:

| Dimension | Representable today? | Mechanism |
| --- | --- | --- |
| Subject | **Yes** | `proposition.subject_entity_id` / `subject_event_id` (canonical entity identity) |
| Predicate | **Yes** | `proposition.predicate`, closed registry |
| Object | **Yes** | `object_entity_id` / `object_event_id` / `object_typed_value_id` |
| Object value conflict | **Yes, for typed values** | `typed_value` comparison; this is exactly what the MT/LXX age contradictions rest on |
| Event identity | **Yes** | distinct `event` rows; distinct events are not comparable as the same occurrence |
| Source scope | **Yes** | evidence → source record → dataset → source |
| Temporal scope | **Partial** | only `precedes`, `occursAt`, `yearsFromCreation`; no interval or calendar algebra |
| Spatial scope | **Partial** | `locatedAt`, `occursAt`; no containment or geometry, and none is proposed |
| Qualification | **Structural only** | `claim_evidence` `QUALIFIES` and `claim_relation` `QUALIFIES` exist but carry no semantics (0 `QUALIFIES` evidence rows) |
| Modality | **No** | nothing distinguishes asserted / commanded / required / conjectured, except the coarse `INSTRUCTION` and `STANDING_REQUIREMENT` event types |
| Negation | **No** | no negation operator anywhere |
| Particular vs. universal scope | **No** | every proposition is particular; no quantifier exists |

**Conclusion.** Automated contradiction classification is **not currently supported**, and this is a
**semantic-judgment boundary**, not a missing feature to be filled by a rule.

The narrow, defensible case that *is* deterministic — and which the accepted MT/LXX relations
already exemplify — is: *same subject entity, same predicate, both objects typed values, values
unequal, and no qualifying relation present*. Even this yields only a **candidate** for human
review, because unequal typed values can legitimately reflect different measurement conventions.
Everything else, including the Phase 19 Joshua 3:6 vs. 2 Samuel 6:3–7 comparison, fails on
modality, negation, temporal scope, and quantifier grounds simultaneously: the two accounts have
**different events**, **different source scopes**, and **no shared proposition**, so they are
`DIFFERENT`, not `CONTRADICTORY`.

## 13. Provenance-gap analysis — the Phase 19 pole/ring question

**Reference question**: *Did 2 Samuel 6:3–7 establish that Uzzah violated Exodus 25:15?*

**Conceptual result: `NOT_ESTABLISHED`.** No `Claim` is created, and none may be. This result is
`CONCEPTUALLY DEMONSTRATED`, not computed.

**What is established, with provenance:**

- Exodus 25:15 supports a **standing requirement** concerning poles and rings. Grounding:
  `ark_covenant_pole_standing_requirement` (`STANDING_REQUIREMENT`), asserted through
  `poles_ark_covenant standingRequirementIn ark_covenant_pole_standing_requirement`, which
  deliberately projects **no** participation.
- 2 Samuel 6:3–7 supports **transport/handling information**. Grounding: the six Phase 19
  `DIRECT_SOURCE_CLAIM` rows over `ark_covenant_new_cart_transport_2sam6`,
  `uzzah_ark_physical_interaction_2sam6`, and `uzzah_death_2sam6`, all supported by
  `EV_MT_2SA_6_3_7`, cited to `CITE_MT_2SA_6_3_7` and `MT_2SA_6_3_7` (`2 Samuel 6:3-7`).

**What is missing:**

1. **Pole/ring physical state** during the 2 Samuel occurrence — a *source availability gap*. No
   evidence row states whether the poles were present, absent, in the rings, withdrawn, or used.
2. **A violation proposition** — a *representational gap*. No predicate can express "X violated
   requirement R"; `violatedRequirement`/`complianceWith` are refused by registry closure.
3. **A licensed derivation** — a *derivation licence gap*. No `Derivation` with a method and
   assumptions connecting a standing requirement to conduct exists, and none is justified.

**Blocked inferences, each with its gap kind:**

| Blocked inference | Gap kind |
| --- | --- |
| standing requirement → violation | derivation licence gap (a requirement's existence is not conduct) |
| transport method → violation | derivation licence + source availability gap |
| different method → contradiction | semantic judgment gap (§12) |
| physical interaction → causation | representational gap (no causal predicate) |
| death → punitive/causal interpretation | representational + semantic judgment gap |

**What must not be concluded**: not that Uzzah complied; not that Uzzah did not violate the
requirement; not that the source is silent; not that Joshua 3:6 and 2 Samuel 6:3–7 conflict.
`NOT_ESTABLISHED` is a statement about Berean, not about the events.

## 14. Derivation eligibility analysis

Using only `derivation`, `derivation_input`, `claim.derivation_id`, and the `claim_type` rules:

**Structural requirements that are executable today** (`scripts/validation/validate.sql`):

1. `DERIVED_CLAIM` ⇒ `derivation_id IS NOT NULL`;
2. `derivation_id IS NOT NULL` ⇒ `claim_type_code = 'DERIVED_CLAIM'`;
3. `DERIVED_CLAIM` ⇒ at least one `derivation_input`;
4. a derived claim may not be an input to its own derivation;
5. `claim.derivation_id` is `UNIQUE` — one derivation belongs to at most one claim;
6. each `derivation_input` supplies exactly one of `input_claim_id` / `input_evidence_id`.

**Worked precedents** (the only ones in the repository): derivation 1 and 2 each sum recorded
begetting ages within a single textual tradition, with the assumptions stated verbatim ("ages are
elapsed whole years; no gaps in the genealogy"); derivation 3 compares normalized parentage
propositions across traditions while explicitly keeping the differing numerals as separate
competing claims. Each has exactly two claim inputs, and every input is itself a provenance-complete
direct source claim.

**What is not executable, and cannot be made so without semantic modelling:**

- whether the stated `method` actually licenses the step;
- whether the stated `assumptions` hold;
- whether the inputs are *sufficient* rather than merely present;
- transitive cycle detection beyond the depth-1 self-input rule (currently unexercised: maximum
  observed derivation depth is 1).

**Applied to the Phase 19 question**: a derived violation claim would be structurally constructible
— inputs exist — and is nevertheless **ineligible**, because no method can bridge requirement to
conduct without the missing physical-state evidence, and because no predicate can express the
conclusion. This is the clearest demonstration in the repository that **structural eligibility is
not a derivation licence**, and any future `CHECK_DERIVATION_ELIGIBILITY` must say so in its output.

## 15. Dependency-impact analysis

Traversal is possible **entirely through existing structures**. No dependency table exists, none is
proposed, and none is needed:

| Direction | Edge | Column |
| --- | --- | --- |
| Claim → evidence | `claim_evidence` | `claim_id`, `evidence_id`, `relation_type_code` |
| Evidence → source | `evidence.source_record_id` → `dataset` → `source` | FK chain |
| Evidence → citation | `evidence_citation` → `citation` | composite PK |
| Derived claim → inputs | `claim.derivation_id` → `derivation_input` | `input_claim_id` / `input_evidence_id` |
| Input claim → dependent derived claims | reverse of the above | `derivation_input.input_claim_id` |
| Claim → competing claims | `claim_relation` | `claim_id`, `related_claim_id` |
| Claim → projection rows | `event_participation` | `asserting_claim_id` |
| Mapping → justifying evidence | `entity_source_mapping.supporting_evidence_id` | FK |

**Observed impact profile in the baseline**: retracting `CLAIM_MT_ADAM_AGE_AT_SETH` would affect
derivation 1 (hence `CLAIM_MT_ENOSH_YEAR_DERIVED`) and the `CONTRADICTS` relation with the LXX
counterpart. Retracting any of the six Phase 19 claims would remove the corresponding
`event_participation` rows immediately, because participation is a view, not a store — a genuine
architectural strength worth recording. Maximum derivation depth is 1, so impact analysis is cheap
today and would matter more as derivations accumulate.

## 16. DEC comparison

DEC is used here **only as an external conceptual reference**. The repository contains no DEC
artifact, no DEC vocabulary, and no dependency on it; a case-insensitive search of `docs/` returns
no occurrence of "DEC", and "epistemic" appears only in the filename
`docs/06-decisions/ADR-0002-epistemic-separation.md`. Nothing below is a proposal to adopt DEC.

| DEC-adjacent concern | Berean status | Grounding |
| --- | --- | --- |
| Provenance is epistemically meaningful, not mere metadata | **Already representable** | The Claim → ClaimEvidence → Evidence → SourceRecord → Dataset → Source chain is mandatory and validated. |
| Source assertion vs. factual status | **Already representable** | ADR-0002; `evidence_type_code`; "No implicit truth". |
| Cognitive stance (believes / asserts / conjectures / doubts) | **Not currently representable** | No stance vocabulary; `claim_status` expresses lifecycle, not stance. |
| Disagreement | **Already representable and exercised** | 6 `claim_relation` rows preserving competing claims. |
| Conjecture | **Partially representable** | `INTERPRETIVE_CLAIM` and `UNDER_REVIEW` are registered but unused (0 rows). |
| Controlled acceptance | **Partially representable** | `claim_status` `ACTIVE`/`SUPERSEDED`/`RETRACTED` and `mapping_status` with `confidence`; only `ACTIVE` and one `SUPERSEDED` are exercised. |
| Explanation of an epistemic position | **Not currently representable** | No explanation structure; §8 shows one can be *assembled at read time* without persistence. |
| Modal / possible-world semantics | **Not currently justified** | Explicitly out of scope; nothing in Phases 6–19 required it. |

**Conclusion**: DEC informs **evaluation semantics** — specifically the discipline of separating
assertion, stance, acceptance, and explanation — and must not inform **Berean persistence
architecture**. Berean's existing tables already carry the provenance DEC would want to reference;
adding DEC-shaped entities would duplicate authority and violate the charter's rule against a second
semantic authority.

## 17. Persistence decision

**Decision: no persistence is justified by Phase 20.**

| Candidate persistence | Justification status | Reason |
| --- | --- | --- |
| Evaluation result rows | **No evidence** | Every proposed operation is a pure read-time function of existing rows; storing results would create a stale second authority. |
| `KnowledgeState` entity | **No evidence** | Nothing in Phases 6–19 needs a state distinct from `claim_status` + provenance. |
| `ProvenanceDecision` entity | **No evidence** | Decisions live in ADRs and phase reports; no query needs them as rows. |
| Explanation payload storage | **No evidence** | §8 shows the payload is fully derivable from existing columns. |
| Dependency/closure tables | **No evidence** | §15 shows traversal works over existing FKs; maximum depth is 1. |
| Gap records | **Possible future need** | Only if acquisition planning requires queryable gap tracking — and even then, prefer documentation first. |
| Stance / modality vocabulary | **Possible future need** | Only if a real source requires reported speech or attribution (§9), which no current phase does. |
| DEC-derived structures | **Not currently justified** | §16. |

Converting an evaluation result into a `Claim` remains prohibited. If a future phase ever wants an
evaluation to enter the graph, it must first justify the mechanism independently, give the resulting
proposition its own provenance, and treat it as a derived claim with an explicit method and
assumptions — not as an engine side effect.

## 18. Architectural boundary

Boundary classification for each capability family:

| Capability family | Boundary classification |
| --- | --- |
| Provenance-chain completeness, citation integrity, hash discipline | **SAFE TO AUTOMATE** (already automated generically) |
| Claim/evidence retrieval and typed bearing reporting | **SAFE TO AUTOMATE** |
| Registry/term-kind admissibility checking | **SAFE TO AUTOMATE** |
| Projection integrity and participation assertedness | **SAFE TO AUTOMATE** |
| Derivation **structural** eligibility, cycle detection | **SAFE TO AUTOMATE** |
| Dependency-impact traversal | **SAFE TO AUTOMATE** |
| Rejection reporting for mechanised refusals | **SAFE TO AUTOMATE** |
| Evidence sufficiency | **REQUIRES FURTHER SEMANTIC MODELING** |
| Difference vs. contradiction classification | **REQUIRES FURTHER SEMANTIC MODELING** |
| Modality, negation, quantifier scope, attribution/reported speech | **REQUIRES FURTHER SEMANTIC MODELING** |
| Pole/ring physical state; any 2 Samuel content beyond one observation | **REQUIRES ADDITIONAL SOURCE DATA** |
| Temporal/spatial reasoning beyond asserted propositions | **REQUIRES ADDITIONAL SOURCE DATA** and further modelling |
| Persisting evaluation results; `KnowledgeState`/`ProvenanceDecision`; DEC structures | **REQUIRES FUTURE ARCHITECTURAL DECISION** |
| Compliance, violation, causation determination | **NOT JUSTIFIED** |
| Automatic claim creation; graph database; inference engine; modal ontology | **NOT JUSTIFIED** |

## 19. Recommended subsequent implementation phases

Ordered smallest-first, each independently valuable and each read-only:

1. **Phase 21 — read-only provenance explanation.** Implement `EXPLAIN_SUPPORT` as a SQL view or a
   read path in `src/repository.ts`, returning the §8 payload for one claim. No schema change; the
   existing app test pattern covers it. Highest value per unit of risk.
2. **Phase 22 — `EVALUATE_PROPOSITION`, retrieval-only.** Return `ESTABLISHED` / `CONTESTED` /
   `NOT_ESTABLISHED` with the §8 explanation, computed at read time, never persisted, never
   converted into a claim. Must ship with negative tests asserting that no row is written.
3. **Phase 23 — `CHECK_DERIVATION_ELIGIBILITY` (structural) and transitive cycle detection.**
   Generalises the existing depth-1 invariants without adding vocabulary; output must state that
   structural eligibility is not a licence.
4. **Phase 24 — `ANALYZE_DEPENDENCY_IMPACT`.** Pure traversal over existing FKs; no dependency
   table.
5. **Phase 25 — `EXPLAIN_REJECTION` for mechanised refusals only.** Requires first refactoring
   phase validators to emit stable rule identifiers; §4 shows labels and actual rules currently
   diverge.
6. **Deferred, gated on independent justification**: gap tracking as data, stance/modality
   vocabulary, contradiction classification, and any persistence.

Not recommended in any near phase: compliance/violation/causation evaluation, automatic claim
creation, a graph store, an inference engine, or modal ontology.

## 20. Validation results

Phase 20 modified **no** implementation file. Regression was nevertheless executed in full after the
report was written, on a freshly created PostgreSQL 16.14 database.

| Check | Result |
| --- | --- |
| `scripts/validation/run-postgres-validation.sh` on a fresh database (schema, all fixtures, Phases 6–19 slices and coverage reports, STEP Bible checks, all negative suites, both blocking-case passes, final integrity rerun) | **PASS** — exit 0, 120 `ok:` lines, 0 `FAIL` |
| Phase 19 positive validation (`phase19-ark-lifecycle-conflict-slice.sql`) | **PASS** |
| Phase 19 coverage report (`phase19-coverage-report.sql`) | **PASS**, classifications unchanged |
| Phase 19 negative validation (`phase19-negative-cases.sh`) | **PASS** — all 18 cases blocked |
| Generic blocking cases (`blocking-cases.sh`, both passes) | **PASS** — clean case plus 6 corruption cases |
| Final `scripts/validation/validate.sql` integrity rerun | **PASS** |
| `npm run test` | **PASS**, 7/7 |
| `npm run lint` | **PASS** |
| `npm run typecheck` | **PASS** |

Post-change object counts are **identical** to the §2.2 baseline in every row, as expected: Source 7,
Dataset 7, SourceRecord 56, Citation 56, Evidence 58, Entity 44, SourceIdentity 10,
EntitySourceMapping 10, Event 41, Proposition 135, Claim 146, ClaimEvidence 153, ClaimRelation 6,
Derivation 3, DerivationInput 6, projected `event_participation` 101.

**Explicit statement, as required: no implementation file was modified by Phase 20.** No schema
file, registry, fixture, validator, runner, application source file, or package file was changed.
The only changed file is `docs/04-data/PHASE20_REPORT.md`, which is new. No implementation change
became necessary to expose information for this specification; every fact above was obtained by
reading existing files and by running existing validation, including running each Phase 19 negative
case individually to observe its real rejecting mechanism.

## 21. Final architectural classification

- **A. Repository-grounded capability matrix**: §5, 30 rows, every row citing a real file, view,
  constraint, invariant, or observed validator behavior.
- **B. Evaluation contract**: inputs, evaluation, outputs, explanation payloads, and determinism in
  §10, with statuses in §6, gaps in §7, and explanations in §8. Specification only.
- **C. Implementation boundary**: §18. Provenance-chain, retrieval, registry, projection,
  structural-derivation, and dependency-traversal capabilities are **SAFE TO AUTOMATE**. Sufficiency
  and contradiction classification **REQUIRE FURTHER SEMANTIC MODELING**. Physical state and broader
  lifecycle content **REQUIRE ADDITIONAL SOURCE DATA**. Persistence of evaluation results
  **REQUIRES A FUTURE ARCHITECTURAL DECISION**. Compliance, violation, causation, and automatic
  claim creation are **NOT JUSTIFIED**.
- **D. Smallest genuinely useful future read-only evaluator**: `EXPLAIN_SUPPORT` — a single
  read-only operation that, for one claim, returns its complete provenance chain, its typed
  supporting/contrary/qualifying evidence, its derivation method, assumptions, and inputs when
  derived, and an explicit `chain_complete` flag together with a "text not stored" marker wherever
  `raw_content`/`quoted_text` are NULL by policy. It is fully deterministic, requires no schema,
  registry, or vocabulary change, writes nothing, creates no claim, and is the necessary substrate
  for `EVALUATE_PROPOSITION` in a later phase.

**Overall classification**: **SPECIFIED BUT NOT IMPLEMENTED.** Berean currently has no provenance
engine. It has a runtime-verified provenance-integrity model, a small set of genuinely generic
executable invariants, and a much larger body of phase-scoped prohibitions and human semantic
judgment that must not be mistaken for engine behavior. Phase 20 makes that boundary explicit,
records the evaluation contract that a future engine would have to honour, and adds no architecture.
