# Phase 20 — Provenance Engine Capability Specification and Evaluation Contract

## 1. Purpose

Phase 20 converts the accepted Phase 20 repository inventory into a formal specification for a future Berean Provenance Evaluation Engine. This document is a contract for behavior and architectural boundaries; it is not an implementation plan that changes the knowledge model.

The engine is needed because Berean already persists provenance-bearing assertions, but the repository currently has no read-only layer that can answer, in a repeatable and explainable way, what those assertions support, what they do not support, which provenance links are incomplete, and which structural dependencies would be affected by a change. Existing validators protect fixtures and enforce integrity. They do not constitute a generalized evaluator, and phase-scoped prohibitions must not be mistaken for semantic classification.

The engine is distinct from the existing provenance substrate. The substrate stores source records, citations, evidence, propositions, claims, relations, and derivations. The future engine reads those structures, evaluates their reach and completeness, and returns a query-scoped explanation. It must not silently turn an evaluation into knowledge.

Phase 19:
  Provenance substrate — runtime validated

Phase 20:
  Provenance engine capability specification

Future phases:
  Targeted read-only evaluator implementation,
  only where deterministic behavior is justified

Phase 20 specifies capabilities rather than implementing them because the repository evidence supports a precise boundary: structural traversal and integrity checks are automatable, while evidence sufficiency, contradiction, compliance, causation, and theological interpretation remain semantic judgments or source-dependent questions.

## 2. Architectural boundary

The governing principle is:

> Berean persists provenance-bearing assertions; the provenance engine evaluates what those assertions mean, how strongly they are justified, and what follows from them.

The conceptual position is:

```text
Applications
     ↓
Provenance Evaluation API
     ↓
Provenance Evaluation Engine
     ↓
Existing Berean Knowledge Substrate
     ↓
Source Foundation
```

### Persistent substrate

The existing persistent knowledge substrate is:

```text
Source
Dataset
SourceRecord
Citation
Evidence
ClaimEvidence
Claim
Proposition
Entity
Event
ClaimRelation
Derivation
DerivationInput
```

These structures remain the authority for persisted assertions and their provenance. Event participation remains a projection from asserted propositions; it is not a new store for evaluation output.

### Future evaluation layer

The future read-only layer may provide:

```text
evaluation
classification
gap detection
explanation
dependency analysis
derivation eligibility
conflict analysis
```

These are query-time operations. Evaluation results are initially ephemeral and query-scoped. They are not rows, claims, propositions, relations, or derivations.

DEC may inform evaluation semantics, particularly provenance stance and disagreement analysis, but DEC must not become Berean's persistence architecture.

## 3. Evaluation-is-not-knowledge invariant

The following are formal architectural invariants:

```text
UNKNOWN
≠ FALSE

NOT_ESTABLISHED
≠ FALSE

SOURCE_AVAILABILITY_GAP
≠ ABSENCE

DIFFERENCE
≠ CONTRADICTION

SOURCE-BACKED
≠ UNIVERSALLY TRUE

EVENT OCCURRENCE
≠ CAUSATION

STANDING REQUIREMENT
≠ COMPLIANCE OR VIOLATION

EVALUATION RESULT
≠ CLAIM
```

A provenance evaluation must not automatically create or mutate a Claim. In particular, a negative evaluation is not a negative proposition, and a gap in the repository is not a claim that the world lacks the corresponding fact.

## 4. Capability taxonomy and matrix

The classifications below describe future operation boundaries, not new database vocabulary. “Current repository support” identifies actual schema, view, validator, fixture, or report evidence. A phase validator that rejects a human-policy case is not thereby a generic semantic evaluator.

| Capability | Current repository support | Future operation | Determinism | Phase disposition |
| --- | --- | --- | --- | --- |
| Provenance completeness | Generic schema and `scripts/validation/validate.sql` check the source-to-claim chain and evidence requirements. | Traverse and report complete or broken chains. | Deterministic for stored links. | **SAFE TO AUTOMATE** |
| Source/citation tracing | `Evidence` links to `SourceRecord`; citations and `evidence_citation` preserve locators; source/dataset ancestry is stored. | Return source, dataset, record, citation, locator, and storage-policy markers. | Deterministic. | **SAFE TO AUTOMATE** |
| Evidence completeness | Citation and provenance integrity are enforced; evidential sufficiency is not computed. | Report present, missing, contrary, and qualifying evidence without treating absence as falsity. | Conditionally deterministic. | **CONDITIONALLY DETERMINISTIC** |
| Source stance | Source observations, claim types, evidence types, and claim/evidence relation types exist; stance semantics are incomplete and mostly unused. | Report assertion/evidence type and explicitly distinguish it from truth. | Conditionally deterministic; interpretation remains semantic. | **CONDITIONALLY DETERMINISTIC** |
| Proposition support | Claims point to propositions and may have typed evidence; no evaluator computes support strength. | Evaluate whether a proposition is established by current source-backed claims. | Deterministic for retrieval; conditional for negative conclusions. | **CONDITIONALLY DETERMINISTIC** |
| Provenance-gap detection | Coverage reports author gap classifications; no general gap evaluator exists. | Identify structural, source, representational, derivation, and semantic gaps. | Conditional: enumerating rows is deterministic; relevance classification may be semantic. | **CONDITIONALLY DETERMINISTIC** |
| Rejection explanation | Schema constraints, registry closure, generic validation, and phase negative suites reject invalid shapes. | Explain the actual rejecting mechanism and distinguish it from a phase label. | Deterministic for mechanised refusals; semantic for curator policy. | **CONDITIONALLY DETERMINISTIC** |
| Derivation eligibility | Generic checks require derivation metadata, inputs, one input kind, and reject self-input. | Preflight structural eligibility only. | Deterministic structurally; method licensing is semantic. | **CONDITIONALLY DETERMINISTIC** |
| Claim relation classification | `ClaimRelation` stores human-authored relations; no classifier exists. | Compare proposition dimensions and return a candidate plus review requirement. | Semantic judgment. | **REQUIRES FURTHER SEMANTIC MODELING** |
| Dependency impact | Existing foreign keys, `DerivationInput`, `ClaimEvidence`, relations, and projected asserting claim IDs form traversable paths. | Report downstream claims, derivations, relations, and projection effects. | Deterministic traversal. | **SAFE TO AUTOMATE** |
| Projection explanation | `event_participation` is a read-only view with `asserting_claim_id`; validators require asserted participation. | Explain why a projection row exists or disappears. | Deterministic. | **SAFE TO AUTOMATE** |
| Knowledge-state evaluation | No `KnowledgeState` table or evaluator exists; claim lifecycle statuses are not a unified epistemic state. | Only a query-scoped evaluation status, never persisted state. | Conditional and scope-dependent. | **NOT CURRENTLY JUSTIFIED** |

The taxonomy must not be read as permission to implement every row. “SAFE” identifies a bounded deterministic operation; “CONDITIONAL” requires explicit scope and limitation reporting; “SEMANTIC” requires further modeling; “NOT CURRENTLY JUSTIFIED” is deferred.

## 5. Common evaluation contract

Every future read-only operation must expose a common conceptual contract. This is an API/behavioral contract, not a persistence schema.

```text
operation
input
scope
evaluation rules
result status
provenance gaps
supporting information
blocked inferences
explanation
determinism
limitations
```

### Contract requirements

* **operation** names the operation and version of its behavior.
* **input** identifies claims, propositions, evidence, or proposed derivations without creating them.
* **scope** states source, dataset, claim-status, phase, temporal, and other filters actually applied.
* **evaluation rules** names the generic constraints, registry checks, and explicitly bounded rules used.
* **result status** describes what Berean can establish in the requested scope, never universal truth.
* **provenance gaps** distinguish missing source data, missing links, representational limits, missing derivation inputs, and semantic uncertainty.
* **supporting information** contains the existing claims, evidence, citations, source records, derivations, and projections relevant to the result.
* **blocked inferences** lists conclusions deliberately not made and why.
* **explanation** is human-readable and structurally traceable to the returned rows and rules.
* **determinism** states which portions are deterministic and which require semantic judgment.
* **limitations** states source availability, storage policy, unmodeled dimensions, and any scope boundary.

All operations are read-only, must be repeatable for the same database state and scope, and must not create evaluator-generated Claims.

## 6. Initial operations

### `EVALUATE_PROPOSITION`

1. **Purpose:** Evaluate whether a requested proposition is established by current persisted assertions.
2. **Inputs:** Subject term, registered predicate, object term, optional proposition/claim ID, and optional source, dataset, status, or phase scope.
3. **Evaluation behavior:** Validate predicate and term kinds; locate matching propositions and claims; verify provenance chains; collect supporting, contrary, qualifying, related, and derived material; identify gaps and blocked inferences.
4. **Output contract:** Status; matched propositions; asserting claims; evidence and source paths; competing claims; gaps; blocked inferences; explanation; determinism; limitations.
5. **Deterministic portions:** Registry matching, row retrieval, provenance traversal, claim-status filtering, and structural integrity checks.
6. **Semantic portions:** Evidence sufficiency, relevance, contradiction, and any conclusion beyond what the rows explicitly assert.
7. **Current repository equivalent:** No evaluator. `src/repository.ts` performs read-only retrieval; validators enforce integrity only.
8. **Justified now?:** Only as a structurally limited retrieval evaluator after provenance explanation exists.
9. **Non-goals:** Truth assignment, generalized entailment, automatic claim creation, compliance, causation, theology, or modal reasoning.

### `EXPLAIN_SUPPORT`

1. **Purpose:** Explain the provenance supporting a claim or proposition.
2. **Inputs:** Claim ID or proposition ID, with optional relation and source filters.
3. **Evaluation behavior:** Traverse `Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord → Dataset → Source`; include derivation and inputs where applicable.
4. **Output contract:** Supporting, contrary, and qualifying evidence; citations and locators; source records; derivation details; `chain_complete`; explicit “text not stored” markers when content is NULL by policy.
5. **Deterministic portions:** Entire traversal and completeness checks.
6. **Semantic portions:** None for traversal; any strength or sufficiency interpretation is outside this operation.
7. **Current repository equivalent:** Partial claim-detail retrieval and generic validation, with no formal explanation contract.
8. **Justified now?:** Yes; this is the smallest justified read-only implementation, also referred to as `EXPLAIN_PROVENANCE`.
9. **Non-goals:** Declaring truth, adding evidence, repairing provenance, or promoting an explanation into a Claim.

### `EXPLAIN_REJECTION`

1. **Purpose:** Explain why a proposed row or inference is refused.
2. **Inputs:** Proposed proposition, claim, relation, derivation, mapping, or projection operation; optionally the attempted operation's validation context.
3. **Evaluation behavior:** Identify schema CHECK/FK/UNIQUE failure, registry closure, non-updatable projection, generic validator rule, phase-scoped policy, or human semantic decision.
4. **Output contract:** Rejecting mechanism, rule identifier or text, mechanism class, deterministic flag, affected input, and required change category.
5. **Deterministic portions:** Actual database constraints and stable generic rules.
6. **Semantic portions:** Curator prohibitions and judgments represented only by phase-specific scripts or reports.
7. **Current repository equivalent:** Negative suites demonstrate rejection but do not consistently explain the actual first rejecting mechanism.
8. **Justified now?:** Deterministic subset only, after stable rule identifiers exist.
9. **Non-goals:** Rewriting validators, inferring that rejected means false, or converting a rejection into a negative Claim.

### `EXPLAIN_GAP`

1. **Purpose:** Explain why a proposition is not established in a declared scope.
2. **Inputs:** Proposition or question, scope, and optional desired evidence/source categories.
3. **Evaluation behavior:** Enumerate available records and claims, distinguish absent rows from unacquired material and unrepresentable semantics, and identify blocked steps.
4. **Output contract:** Gap category, searched scope, supporting information, missing or unavailable information, blocked inferences, explanation, determinism, and limitations.
5. **Deterministic portions:** Inventory of stored records and links.
6. **Semantic portions:** Determining which absent observation would be relevant.
7. **Current repository equivalent:** Authored coverage-report classifications such as `SOURCE AVAILABILITY GAP` and `SEMANTIC PRECISION GAP`.
8. **Justified now?:** Specify only; implement after gap vocabulary and scope semantics are independently stabilized.
9. **Non-goals:** Reporting source silence from an unquoted record, reporting absence as FALSE, or persisting gap rows.

### `CHECK_DERIVATION_ELIGIBILITY`

1. **Purpose:** Determine whether a proposed derivation is structurally admissible.
2. **Inputs:** Proposed derived Claim, target Proposition, method, assumptions, and proposed Claim/Evidence inputs.
3. **Evaluation behavior:** Apply the structural checks in §8 and separately report that method licensing and entailment remain human judgments.
4. **Output contract:** Structural eligibility, failed checks, input status, provenance completeness, cycle findings, method/assumption presence, license status, explanation, and limitations.
5. **Deterministic portions:** Foreign-key existence, input exclusivity, self-input, target registry validity, derivation linkage, and provenance traversal.
6. **Semantic portions:** Whether the method and assumptions actually license the conclusion.
7. **Current repository equivalent:** `validate.sql` and `blocking-cases.sh`, applied after insertion rather than as a preflight API.
8. **Justified now?:** Yes, structural checks only.
9. **Non-goals:** Logical entailment, automatic derivation, automatic Claim creation, or treating a method string as proof.

### `CLASSIFY_CLAIM_RELATION`

1. **Purpose:** Compare two claims and report whether a relation is structurally comparable or requires human judgment.
2. **Inputs:** Two Claim IDs and optional source/scope context.
3. **Evaluation behavior:** Compare subject, predicate, object, event identity, temporal/spatial/source scope, qualification, modality, negation, and quantifier availability.
4. **Output contract:** Compared dimensions, differences, comparable dimensions, candidate relation if any, review requirement, explanation, and limitations.
5. **Deterministic portions:** Field comparison and existing `ClaimRelation` retrieval.
6. **Semantic portions:** Contradiction, supersession, qualification, and disagreement classification.
7. **Current repository equivalent:** Human-authored fixture relations; no classifier.
8. **Justified now?:** No generalized classifier. A comparison reporter may be investigated later.
9. **Non-goals:** Automatically inserting `ClaimRelation`, declaring different descriptions contradictory, or resolving disagreement.

### `ANALYZE_DEPENDENCY_IMPACT`

1. **Purpose:** Report what existing assertions and projections depend on a claim or evidence row.
2. **Inputs:** Claim or Evidence ID and a hypothetical action such as retract, supersede, revise, or remove.
3. **Evaluation behavior:** Traverse ClaimEvidence, derivation inputs, reverse derived-claim links, ClaimRelation, mapping-support evidence, and `event_participation.asserting_claim_id`.
4. **Output contract:** Dependent claims, derivations, evidence, relations, projection rows, invariants at risk, paths, explanation, determinism, and limitations.
5. **Deterministic portions:** All existing foreign-key and view traversal.
6. **Semantic portions:** The meaning or policy consequence of the hypothetical action.
7. **Current repository equivalent:** No traversal operation; dependencies are nevertheless represented by existing keys and views.
8. **Justified now?:** Yes, as a read-only traversal; no dependency table is needed.
9. **Non-goals:** Applying the action, cascading mutations, or recomputing and persisting evaluation state.

## 7. First implementation boundary

The smallest justified future implementation is:

```text
EXPLAIN_PROVENANCE
```

This may be exposed as a structurally limited `EXPLAIN_SUPPORT`, or followed by a retrieval-only `EVALUATE_PROPOSITION`. It should trace:

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

and, where applicable:

```text
Claim
→ Proposition
→ Predicate registry
→ Entity/Event projection
```

It may report structural gaps such as:

```text
MISSING_CLAIM_EVIDENCE
MISSING_CITATION
MISSING_SOURCE_RECORD
INVALID_PREDICATE
INVALID_DERIVATION_INPUT
MISSING_DERIVATION
```

These are output vocabulary for a future read-only operation, not database values. The first implementation must not attempt:

```text
truth assignment
contradiction inference
compliance reasoning
violation reasoning
causal reasoning
theological interpretation
modal-logic reasoning
automatic Claim creation
automatic derivation
global factual-core promotion
```

## 8. Structural derivation eligibility

Future structural checks may automate the following:

```text
Derivation exists
method exists
assumptions exist
DerivationInput exists
each input is exactly one Claim or Evidence
no self-input
derived Claim references Derivation
derived Claim is not mislabeled as direct source claim
source-backed premises retain provenance
```

These checks are grounded in the existing derivation and validation rules. They establish:

```text
structural eligibility
```

not:

```text
logical entailment
```

A proposed derivation can be structurally complete and still lack a justified method, adequate assumptions, semantic sufficiency, or entailment. No evaluator may create a derived Claim merely because these structural checks pass.

## 9. Provenance-gap semantics

The contract must keep three concepts distinct:

```text
status
  What Berean can establish in the requested scope.

gap
  Why the available substrate cannot establish more.

explanation
  The evidence paths, rules, missing links, and blocked inferences supporting that result.
```

For example:

```text
status:
  NOT_ESTABLISHED

gap:
  INSUFFICIENT_EVIDENCE

explanation:
  The available source-backed claims establish the standing
  requirement and the historical event, but do not establish
  the physical state required to infer violation.
```

### Gap vocabulary

The following terms are already observed in repository reports and validators, or are explicitly proposed as future evaluator output vocabulary. They must not be added to the database merely to document them.

| Category | Vocabulary | Current status |
| --- | --- | --- |
| Source/report classification | `SOURCE_AVAILABILITY_GAP` | Existing repository/report classification; spelling/format varies in prose as `SOURCE AVAILABILITY GAP`. |
| Source/report classification | `ACQUISITION_PENDING` | Existing repository/report classification. |
| Future evaluator result | `SEMANTIC_PRECISION_GAP` | Existing report vocabulary; future evaluator may return it only with explicit scope. |
| Future evaluator result | `INSUFFICIENT_EVIDENCE` | Proposed evaluator vocabulary; not persisted and not a current validator result. |
| Future evaluator result | `MISSING_DERIVATION_INPUT` | Proposed evaluator vocabulary for structural preflight. |
| Future evaluator result | `UNRESOLVED_CONFLICT` | Proposed evaluator vocabulary; must not imply contradiction. |
| Source/report classification | `NOT_DERIVED` | Existing repository/report classification. |
| Source/report classification | `INTENTIONALLY_EXCLUDED` | Existing repository/report classification. |
| Source/report classification | `DOCUMENTED_UNRESOLVED_DECISION` | Existing repository/report classification. |

A gap is never `FALSE`, world-absence, or proof that a source is silent. A NULL quotation or raw payload means the repository deliberately does not store that text under its current source policy.

## 10. Difference versus contradiction

Berean cannot currently perform generalized contradiction detection. A future evaluator would need to compare at least:

```text
subject
predicate
object
event identity
temporal scope
spatial scope
source scope
qualification
modality
negation
particular/universal scope
```

The current Proposition structure does not formally encode all of these dimensions. Therefore:

```text
different description
≠ contradiction
```

`ClaimRelation.CONTRADICTS` is currently a stored assertion of a semantic judgment, not proof that the propositions logically contradict one another. Existing preserved disagreement is valuable evidence that disagreement can be stored without being resolved; it is not an implemented classifier.

## 11. DEC boundary

DEC is a conceptual reference only. It informs future evaluation semantics; it does not define Berean persistence architecture.

| DEC concept | Berean status |
| --- | --- |
| Provenance has epistemic meaning | Conceptually aligned |
| Source assertion ≠ universal truth | Supported by architecture |
| Doxastic stance | Not explicitly representable |
| Epistemic stance | Partially representable |
| Conjectural stance | Partially representable |
| Cognitive worlds | Not currently representable |
| Factual core/permeation | Not currently justified |
| Disagreement preservation | Structurally supported |
| Formal disagreement detection | Not implemented |
| Settlement/supersession | Partially supported |
| Modal-logic reasoning | Not justified |

No DEC-shaped tables, columns, ontology, cognitive worlds, factual-core structure, or modal persistence model is introduced.

## 12. Phase 19 mapping

The Phase 19 negative suite is evidence for the boundary, not evidence that a semantic engine already exists.

| Negative case | Current enforcement mechanism | Future evaluation capability | Determinism | Disposition |
| --- | --- | --- | --- | --- |
| Missing ClaimEvidence | Phase-scoped validator plus generic provenance invariant | Explain support/provenance completeness | Deterministic | Safe to automate |
| Missing Citation | Phase-scoped validator plus generic citation invariant | Explain provenance gap | Deterministic | Safe to automate |
| Fabricated source payload | Phase-scoped source-availability policy and source-record checks | Explain rejection/source policy | Conditional: policy is deterministic, truth is not | Conditional |
| Duplicate canonical entity | Phase-scoped name/allow-list check | Dependency/provenance explanation, not generic identity inference | Conditional | Conditional |
| Unsupported participant | Phase-scoped projection allow-list | Explain projection and assertedness | Deterministic within scope | Safe to automate |
| Fabricated pole/ring state | Phase-scoped participant/claim prohibition | Explain source and semantic gap | Conditional | Conditional |
| Fabricated causal relation | Registry closure and phase predicate check | Explain rejection; no causal evaluator | Deterministic rejection | Safe to automate rejection only |
| Derived claim without inputs | Phase-scoped prohibition and generic derivation invariant | Structural derivation eligibility | Deterministic structurally | Conditional |
| Self-input derivation | Generic validator and blocking cases | Structural cycle/self-input explanation | Deterministic | Safe to automate |
| Direct projection insertion | Non-updatable `event_participation` view | Explain projection integrity | Deterministic | Safe to automate |
| Unsupported predicate/event type | Registry closure and phase registry check | Explain admissibility failure | Deterministic | Safe to automate rejection only |
| Unjustified source identity mapping | Phase validator plus mapping evidence/justification rules | Explain mapping support and gap | Conditional | Conditional |
| Uzzah violation inference | Phase-scoped prohibition; no violation predicate | Explain `NOT_ESTABLISHED`, missing state, and blocked derivation | Semantic result with deterministic evidence traversal | Not justified as inference |
| Transport-method contradiction inference | Phase-scoped ClaimRelation prohibition | Difference/contradiction comparison report | Semantic judgment | Requires further modeling |

The actual rejecting mechanism must be reported where it differs from a test label. A validator's human policy is not a generalized evaluator.

## 13. Phase 19 Ark example

Question:

```text
Did 2 Samuel 6:3–7 establish that Uzzah violated Exodus 25:15?
```

A future read-only evaluator should produce approximately:

```text
status:
  NOT_ESTABLISHED

supporting information:
  Exodus 25:15 — standing requirement
  2 Samuel 6:3–7 — transport/handling event

missing information:
  physical pole/ring state
  source-backed violation proposition
  licensed derivation connecting the premises to violation

blocked inferences:
  standing requirement → violation
  transport method → violation
  different transport method → contradiction
  interaction → causation
  death → punishment
```

This is an evaluation result, not a new Claim. It does not establish compliance, non-violation, source silence, contradiction, causation, or punishment.

## 14. Persistence decision and promotion criteria

The explicit rule is:

> Do not persist evaluator results until repeated use demonstrates that they must be versioned, independently cited, compared over time, consumed by other derivations, invalidated when evidence changes, or treated as inputs to downstream evaluations.

Until that threshold is met:

```text
Knowledge graph
      ↓
Read-only evaluator
      ↓
Ephemeral explainable result
```

No following tables should be introduced during Phase 20:

```text
KnowledgeState
ProvenanceDecision
EvaluationResult
CognitiveWorld
FactualCore
```

Before a future phase promotes an evaluation result into persistent architecture, it must demonstrate that the result is independently:

* versioned;
* independently cited;
* historically compared;
* consumed downstream;
* invalidated or recomputed when dependencies change;
* treated as an input to another evaluation; and
* independently auditable.

The burden of proof remains on the proposed persistence structure. A result must not be persisted merely because it is convenient to cache or display.

## 15. Phase 20 acceptance criteria

The specification is accepted when the following can be verified without implementing the evaluator:

1. Existing Phase 19 schema remains unchanged.
2. Existing Phase 19 fixtures remain unchanged.
3. Existing Phase 19 validators remain unchanged.
4. No DEC persistence model is introduced.
5. No new generalized inference engine is introduced.
6. No unified status table is introduced.
7. Every proposed capability has a determinism classification.
8. Every semantic judgment is explicitly identified.
9. Every proposed future operation has an input/output contract.
10. The first implementation boundary is limited to deterministic provenance explanation and structural gap reporting.
11. The distinction between evaluation and knowledge is explicit.
12. The document identifies what is currently impossible to automate safely.
13. Phase 19 remains the runtime-validated baseline.
14. The specification is traceable to actual repository artifacts, including the Phase 19 fixtures, negative suite, schema, generic validator, projections, and prior reports.

## 16. Repository integrity and non-goals

This document uses the established `docs/04-data/PHASE*_REPORT.md` convention and is placed beside the Phase 20 inventory/report because it is a Phase 20 data-and-architecture specification. It does not alter existing domain or schema documentation and does not introduce a competing persistence architecture.

No schema, table, column, registry value, fixture, validator, runner, application source file, or data row is changed by this specification. No evaluator-generated Claim is created. No existing Phase 19 behavior is modified.

The recommended next phase is a targeted read-only implementation of `EXPLAIN_PROVENANCE`/`EXPLAIN_SUPPORT`, followed only after validation by a retrieval-limited `EVALUATE_PROPOSITION`. That work is explicitly deferred and is not implemented here.
