# Phase 22 — Capability Discovery and Architectural Boundary

## Executive conclusion

```text
PHASE 22 STATUS:
DISCOVERY COMPLETE

IMPLEMENTATION:
NONE

SCHEMA CHANGE:
NONE

ARCHITECTURAL CHANGE:
NONE
```

### Recommended next capability

```text
RECOMMENDED NEXT CAPABILITY:
CHECK_DERIVATION_ELIGIBILITY — structural subset only
```

The structural subset is the smallest new capability that is both useful and mechanically grounded in the current repository. Berean already stores `Derivation`, `DerivationInput`, derived `Claim` metadata, provenance-bearing premises, registered propositions, and generic validation rules for missing inputs and self-input. A future operation could preflight those existing structures without creating a derivation, creating a claim, asserting entailment, or changing the schema.

`ANALYZE_DEPENDENCY_IMPACT` is the second-best candidate: the required edges exist and traversal is safe, but its immediate value is lower while the current derivation depth is small. `EXPLAIN_GAP` remains partly semantic. `EVALUATE_PROPOSITION` is premature unless explicitly restricted to retrieval and structural support reporting. `CLASSIFY_CLAIM_RELATION` is deferred because contradiction and relation semantics are not encoded by the current Proposition model.

No Phase 22 capability is implemented by this assessment.

## Phase 21 baseline

Phase 21 remains in the accepted state documented by `docs/04-data/PHASE21_EXPLAIN_PROVENANCE.md`:

```text
OPERATION:
  GET /api/provenance/explain

MODE:
  READ-ONLY

SEMANTIC INFERENCE:
  NONE

PERSISTENCE:
  NONE
```

The implementation continues to resolve the existing substrate through these paths:

```text
Claim
→ ClaimEvidence
→ Evidence
→ EvidenceCitation
→ Citation
→ SourceRecord
→ Dataset
→ Source
```

```text
Claim
→ Proposition
→ Predicate registry
```

```text
Claim
→ Derivation
→ DerivationInput
```

and, for registered participation predicates:

```text
Claim-backed Proposition
→ event_participation
```

The application route is defined in `src/app.ts`; traversal is implemented in `BereanRepository.explainProvenance` in `src/repository.ts`; Phase 21 tests are in `tests/app/app.test.ts`. No Phase 22 change modifies those files.

## Existing capability map

| Existing structure | Current role | Phase 22 relevance |
| --- | --- | --- |
| `source`, `dataset`, `source_record` | Source ancestry and source-record identity | Supports provenance and dependency traversal |
| `citation`, `evidence_citation` | Locator-bearing citation edges | Supports deterministic evidence/source traversal |
| `evidence` | Source-grounded or analytical observation | Provides derivation inputs and provenance-bearing premises |
| `claim_evidence` | Typed Claim↔Evidence association | Provides support, contradiction, and qualification edges without deciding truth |
| `claim` | Persisted assertion over a Proposition | Target and dependency node; not truth storage |
| `proposition` | Authoritative structured subject/predicate/object | Validated by predicate registry and term-kind constraints |
| `predicate` | Closed semantic registry with optional projection role | Determines admissibility and event projection behavior |
| `event_participation` | Read-only projection from asserted propositions | Provides downstream projection dependencies |
| `derivation` | Method and assumptions for one derived Claim | Candidate for structural eligibility checks |
| `derivation_input` | Explicit Claim or Evidence inputs | Candidate for input existence, exclusivity, and cycle checks |
| `claim_relation` | Human-authored claim-to-claim relation | Evidence for preserved disagreement; not a classifier |
| `entity_source_mapping` | Source identity reconciliation with optional supporting evidence | Possible dependency edge, but not the recommended next operation |
| `scripts/validation/validate.sql` | Generic structural/provenance invariants | Existing executable precedent for derivation preflight |
| Phase 19 validators/negative cases | Bounded source and semantic prohibitions | Concrete evidence for what must not be inferred |
| Phase 21 API | Read-only provenance explanation | Provides the first reusable explanation substrate |

## Candidate assessment matrix

| Candidate | Existing inputs and semantics | Deterministic subset | Semantic subset / missing semantics | Explainability | Read-only / persistence | Schema / registry need | Negative-case boundary | Testability | False-precision risk | Recommendation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `EXPLAIN_GAP` | Claims, evidence, citations, source records, coverage classifications, and Phase 21 structural gaps. Existing meanings distinguish not populated from not true. | Enumerate missing links, absent claims for a proposition, missing derivation metadata, and bounded searched scope. | `INSUFFICIENT_EVIDENCE`, source silence, relevant missing observations, unresolved conflict, and semantic insufficiency cannot be established from emptiness alone. | Good for structural gaps; weak for semantic gaps. | Read-only and ephemeral are feasible; persistence not required. | None for structural subset. | Phase 19 pole/ring state, compliance, causation, and 6:4–6:5 coverage show why absence is not a semantic conclusion. | Existing Phase 21 temporary-gap patterns are usable. | High if it reports `INSUFFICIENT_EVIDENCE` or source silence from missing rows. | **DEFER**; consider only a structural-gap reporter later. |
| `CHECK_DERIVATION_ELIGIBILITY` | `derivation`, `derivation_input`, `claim.derivation_id`, `claim_type`, `proposition`, `predicate`, `claim_evidence`, and generic validation rules. | Check derivation linkage, method/assumptions presence, input existence, exactly-one input kind, input provenance, claim type, self-input, and registered target proposition. | Method entailment, assumption validity, semantic applicability, scope preservation, sufficiency, and logical consequence. | High: each failed structural check maps to a row, FK, registry rule, or generic invariant. | Fully read-only and query-scoped; no persistence required. | No schema or registry change. | Phase 19 derived-claim-without-input and self-input cases; earlier accepted derivations provide positive precedents. | Strong: existing derivations plus temporary structurally invalid test setups. | Moderate and controllable if output says structural eligibility is not logical entailment. | **PROCEED NEXT** with structural subset only. |
| `ANALYZE_DEPENDENCY_IMPACT` | Foreign keys and projections connect evidence, claims, propositions, derivations, relations, mappings, and event participation. | Traverse claim/evidence dependencies, reverse derivation inputs, relation edges, and projection rows. | Policy meaning of retract/supersede/revise, transitive semantic impact, and downstream truth consequences. | High for path reporting; policy impact needs explicit limitation. | Fully read-only; no dependency table required. | No schema change justified. | Phase 21 provenance path and existing derivation graph; maximum observed derivation depth is limited. | Good, but requires more traversal fixtures and careful cycle handling. | Moderate if “affected” is confused with “false” or “invalid.” | **PROCEED AFTER DERIVATION**. |
| `CLASSIFY_CLAIM_RELATION` | Claims, Propositions, typed values, ClaimRelation, source scope, and event identity. | Compare stored subject, predicate, object, event, typed value, and existing relation rows. | Temporal/spatial scope, modality, negation, qualification semantics, quantifiers, attribution, and logical contradiction. | Comparison output is explainable; classification is not safely explainable as logic. | Read-only is feasible; automatic ClaimRelation persistence is prohibited. | Additional semantic model would be required for generalized classification; not justified. | Phase 19 Joshua 3 versus 2 Samuel 6: different transport descriptions are not contradiction. | Narrow comparison tests are possible; classifier tests would encode unsupported judgments. | Very high: difference can be mislabeled contradiction. | **DEFER / REJECT GENERAL CLASSIFIER**. |
| `EVALUATE_PROPOSITION` | Proposition, Claim, ClaimEvidence, evidence chain, predicate registry, and Phase 21 explanation. | Retrieve matching claims, verify provenance, report stored support/contrary/qualifying bearings, and identify structural gaps. | Sufficiency, entailment, truth, falsity, contradiction, and semantic relevance. | Good only when explicitly limited to structural support explanation. | Read-only and ephemeral are feasible. | No schema change for retrieval subset. | Phase 19 rejects requirement→violation, event→causation, and transport-difference→contradiction. | Existing fixtures support retrieval tests. | High if `ESTABLISHED` is interpreted as true. | **DEFER BROAD FORM**; consider only a retrieval-limited structural operation after the recommended step. |

## Recommended capability: structural derivation eligibility

### Exact future boundary

A future `CHECK_DERIVATION_ELIGIBILITY` operation may verify:

```text
Derivation exists
method exists
assumptions exist
DerivationInput exists
required input Claim/Evidence rows exist
each input is exactly one Claim or Evidence
input Claim provenance is structurally complete
input Evidence has its source chain and citation where required
derived Claim references the Derivation
claim type is DERIVED_CLAIM
target Proposition uses a registered predicate and valid term kinds
no self-input exists
```

It must return an explainable structural result, for example:

```text
structurally_eligible: true | false
failed_checks: []
input_status: []
license_status: REQUIRES_HUMAN_METHOD_JUSTIFICATION
explanation: ...
limitations: ...
```

The operation must explicitly distinguish:

```text
structural eligibility
≠
logical entailment
```

It must not decide:

```text
Does the method entail the conclusion?
Are the assumptions valid?
Is the rule semantically applicable?
Does the derivation preserve temporal, spatial, modal, or source scope?
Is the evidence sufficient?
Is the derived proposition true?
```

### Why this is the smallest next step

1. The required inputs already exist as first-class relational structures.
2. Generic validators already enforce much of the structural contract.
3. Three accepted derivations provide positive repository precedents.
4. Phase 19 and earlier negative cases provide concrete failure boundaries.
5. The operation can be implemented without writes, schema changes, registry changes, or new ontology.
6. Its output can be explained entirely through existing rows and named checks.
7. It directly prepares the repository for later dependency analysis without introducing inference.

## Determinism boundary

### DETERMINISTIC

* Identifier and row existence checks.
* Predicate and subject/object term-kind admissibility.
* Claim type and derivation linkage.
* Method and assumptions presence when represented by non-null required columns.
* Derivation input existence.
* Exactly-one Claim/Evidence input enforcement.
* Foreign-key resolution.
* ClaimEvidence provenance traversal.
* Citation and source-chain traversal.
* Self-input detection.
* Existing projection lookup.
* Dependency path traversal over existing foreign keys and views.

### CONDITIONALLY DETERMINISTIC

* Structural `EXPLAIN_GAP` output when the scope is explicitly limited to enumerating stored rows and broken links.
* Retrieval-limited proposition evaluation that reports stored claims and structural provenance only.
* Dependency impact under a declared hypothetical action, provided “impact” means graph reachability rather than semantic consequence.

### SEMANTIC JUDGMENT

* Evidence sufficiency.
* Relevance of an absent observation.
* Method licensing and entailment.
* Assumption validity.
* Source stance and attribution.
* Difference versus contradiction.
* Qualification, refinement, supersession, and disagreement meaning.
* Compliance, violation, causation, punishment, and theological interpretation.

### NOT CURRENTLY JUSTIFIED

* Truth assignment or falsity assignment.
* Generalized inference.
* Modal or cognitive-world reasoning.
* Global factual-core promotion.
* Persisted evaluation state.
* Automatic Claim, Proposition, or Derivation creation.
* Automatic ClaimRelation classification or persistence.

## Provenance boundary

Berean can currently establish, structurally:

```text
A Claim exists.
A Claim asserts a structured Proposition.
A Proposition uses a registered predicate and valid term kinds.
Evidence is linked to a Claim.
Evidence points to a SourceRecord.
A SourceRecord belongs to a Dataset.
A Dataset belongs to a Source.
Evidence may have Citation links.
A derived Claim may have a Derivation and explicit inputs.
A registered event predicate may produce event_participation rows.
```

Berean cannot currently establish from those structures alone:

```text
The Claim is true.
The Evidence is sufficient.
The source intended a particular epistemic stance.
Two propositions contradict one another.
A requirement was complied with or violated.
An event caused another event.
A death was punishment.
A derivation is logically valid.
A source is silent because a row is absent.
```

The storage policy remains mandatory:

```text
raw_content = NULL
quoted_text = NULL
```

means the repository does not store the source payload or quotation. It does not mean source silence.

## Source stance and evidence semantics

The current repository has partial structural distinctions:

* `SOURCE_OBSERVATION` and `ANALYTICAL_OBSERVATION` evidence types;
* `DIRECT_SOURCE_CLAIM`, `INTERPRETIVE_CLAIM`, and `DERIVED_CLAIM` claim types;
* `SUPPORTS`, `CONTRADICTS`, and `QUALIFIES` ClaimEvidence relations;
* Claim lifecycle statuses;
* Derivation method, assumptions, and explicit inputs.

However, the repository does not currently model a complete distinction among:

```text
SOURCE_ASSERTS φ
SOURCE_REPORTS_PERSON_BELIEVES φ
SOURCE_QUOTES_PERSON_ASSERTING φ
RESEARCHER_INTERPRETS_SOURCE_AS_SUPPORTING φ
BEREAN_DERIVES φ
```

The available types and relations are not sufficient to infer those distinctions from free text. No Phase 22 vocabulary or structure is justified for them.

## Difference versus contradiction

The current Proposition model stores subject, predicate, object/value, and entity/event identity. It does not formally encode all of:

```text
temporal scope
spatial scope
source scope as semantic qualification
modality
negation
particular/universal scope
reported speech or attribution
```

The Phase 19 comparison is decisive:

```text
Joshua 3 transport by priests
≠
2 Samuel 6 transport on a new cart
```

These are different source-backed event descriptions. The current substrate cannot mechanically promote their difference to `CONTRADICTS`. Existing `ClaimRelation.CONTRADICTS` rows are stored semantic judgments, not generated logical proofs.

Therefore generalized `CLASSIFY_CLAIM_RELATION` is deferred.

## Candidate-specific false-precision risks

| Risk | Boundary |
| --- | --- |
| `EXPLAIN_GAP` reports `INSUFFICIENT_EVIDENCE` from an empty table | Empty means not populated in the selected repository scope, not source silence or falsity. |
| Structural derivation eligibility is presented as valid reasoning | Eligibility must state that method licensing and entailment remain human judgments. |
| Dependency impact is presented as semantic consequence | Report graph reachability and affected projections only. |
| `EVALUATE_PROPOSITION` returns `ESTABLISHED` | Use structural wording such as “stored Claim with complete provenance”; never imply true. |
| Claim comparison emits `CONTRADICTION` from unequal descriptions | Preserve `DIFFERENCE ≠ CONTRADICTION`. |
| Phase 19 prohibition is generalized into semantic inference | Phase validators are fixture-scoped guards, not a reasoning engine. |
| NULL source text becomes source silence | Preserve `NOT_STORED_BY_POLICY`. |

## Schema and architecture sufficiency

```text
SCHEMA CHANGE JUSTIFIED:
NO
```

The existing schema provides the required edges for the recommended structural operation. No new dependency table is needed; dependency paths can be traversed through existing foreign keys, `claim_evidence`, `derivation_input`, `claim_relation`, mappings, and the `event_participation` view.

No new registry vocabulary is justified. In particular, no compliance, violation, causation, modality, stance, negation, or contradiction predicate should be added merely to make a future evaluator easier to write.

DEC remains conceptual only:

```text
DEC:
  conceptual influence only

Berean:
  relational provenance-bearing knowledge substrate
```

No `CognitiveWorld`, `KnowledgeState`, `EpistemicState`, `BeliefState`, `FactualCore`, or `ModalWorld` structure is justified.

## Future implementation boundary

A future implementation of the recommended operation may:

* accept an existing proposed target Claim/Proposition and existing or proposed input identifiers;
* read current Derivation, DerivationInput, ClaimEvidence, Evidence, Proposition, Predicate, and source-chain rows;
* return an ephemeral structural report;
* identify failed structural checks;
* explain each result using existing row identities and generic validation rules;
* state that structural eligibility is not logical entailment;
* remain read-only and non-persistent.

It may not:

* create or mutate a Claim, Proposition, Evidence, Derivation, DerivationInput, or ClaimRelation;
* assign truth or falsity;
* infer contradiction, compliance, violation, causation, punishment, or theology;
* validate free-text method semantics as logic;
* introduce a generalized rule engine;
* add a persistence table or registry vocabulary.

## Test strategy for a future implementation

Use existing repository evidence:

### Positive precedents

* The three accepted derivations from earlier phases.
* Their explicit methods and assumptions.
* Their Claim and Evidence inputs.
* Their existing source provenance.

### Negative cases

* Generic `scripts/validation/validate.sql` checks for missing derivation, missing inputs, and self-input.
* Generic `tests/validation/blocking-cases.sh` derivation corruption cases.
* Phase 19 negative cases for derived claims without inputs and self-input derivations.
* Phase 19 negative cases for unsupported predicates and fabricated semantic inference.

### Required future assertions

* Complete structural derivation is reported as eligible only structurally.
* Missing Derivation is reported without creating one.
* Missing DerivationInput is reported without creating one.
* Invalid input references are reported when a temporary state can be created without weakening constraints.
* Self-input is reported deterministically.
* A method string is returned as metadata, never evaluated as proof.
* Database row counts remain unchanged after every operation.
* Phase 19 positive and negative behavior remains unchanged.

## Deferred capabilities

The following remain deferred:

```text
semantic EXPLAIN_GAP
source silence determination
evidence sufficiency
source epistemic stance
reported-speech attribution
semantic EVALUATE_PROPOSITION
truth/falsity assignment
contradiction classification
compliance reasoning
violation reasoning
causal reasoning
punitive/theological interpretation
modal-logic reasoning
cognitive-world modeling
global knowledge-state evaluation
evaluation persistence
automatic Claim creation
automatic Derivation creation
```

## What Berean can do now, later, and should not do

### What Berean can do now

* Persist provenance-bearing assertions.
* Preserve competing claims and human-authored ClaimRelations.
* Validate generic structural and provenance invariants.
* Explain deterministic provenance paths with `EXPLAIN_PROVENANCE`.
* Traverse existing dependency edges manually or in bounded read-only operations.
* Verify a future derivation's structural shape without asserting entailment.

### What Berean could do later

* Implement structural `CHECK_DERIVATION_ELIGIBILITY`.
* Implement bounded `ANALYZE_DEPENDENCY_IMPACT`.
* Implement structural-only `EXPLAIN_GAP`.
* Implement retrieval-limited `EVALUATE_PROPOSITION`.
* Add semantic capabilities only after their required dimensions and testable rules are demonstrated independently.

### What Berean should not do

* Treat source-backed or complete provenance as truth.
* Treat absence from the repository as source silence or falsity.
* Infer contradiction from different descriptions.
* Infer compliance, violation, causation, punishment, or theological meaning from adjacent claims/events.
* Persist evaluation results without demonstrated lifecycle and audit requirements.
* Add DEC-shaped persistence structures or a second semantic authority.
* Build a generalized inference engine before deterministic boundaries are exhausted.

## Final status

```text
PHASE 22 STATUS:
DISCOVERY COMPLETE

IMPLEMENTATION:
NONE

SCHEMA CHANGE:
NONE

ARCHITECTURAL CHANGE:
NONE

RECOMMENDED NEXT CAPABILITY:
CHECK_DERIVATION_ELIGIBILITY — STRUCTURAL SUBSET ONLY
```

Phase 22 establishes the next architectural question without implementing it. The next implementation instruction, if issued, should be separately scoped to a read-only structural derivation preflight and must preserve the distinction:

```text
structural eligibility
≠
logical entailment
```
