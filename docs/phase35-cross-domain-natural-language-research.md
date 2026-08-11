# Phase 35 — Cross-Domain Natural-Language Scholarly Research

## 1. Objective and difference from Phase 34

Phase 34 proved that one natural-language interpreter could interrogate one domain: it recognised
`principe`, `sobral`, `eddington` and `CLAIM_P33_%` keys, so its success said as much about the
interpreter's knowledge of the 1919 eclipse as about Berean.

Phase 35 asks the harder question:

> Does Berean's natural-language scholarly query capability **generalize** across independently
> populated domains, or was it Phase 33/34-specific code?

Phase 35 therefore drives **two** already-persisted domains through **one** generic interpreter:

- Genesis / Nephilim knowledge persisted by Phases 30–31;
- 1919 solar-eclipse knowledge persisted by Phases 32–33.

Neither domain is repopulated, duplicated, or extended. No fixture was added. No schema object was
created. The interpreter contains no domain identifiers, no per-question SQL, no question-keyword
dispatch, and no canned answers; it resolves concepts by matching question terms against **persisted
Berean labels** and resolves relationships from the **predicate registry's own declared semantics**.

## 2. Architecture

```text
Natural language (11 questions x 2 materially different wordings)
  -> Generic semantic interpretation
       lexicon of domain-neutral concepts (person, entity, event, place, source, observation,
       claim, evidence, interpretation, participation, location, ordering, provenance, identity,
       comparison)
       + concept anchors resolved against persisted labels
         (entity.canonical_name, event.description/event_key, source.name/source_key,
          source_identity.display_name)
  -> Normalized query plan (transient)
       semantic_relationship | semantic_target | semantic_filters | candidate_predicates
       | traversal_shape | output_constraints | provenance_requirement | retrieval_scope
  -> Capability check
       ESTABLISHED | DERIVABLE | SCHOLARLY_CANDIDATE | UNRESOLVED | NOT_REPRESENTED
  -> Domain-agnostic graph retrieval (9 generic operators, selected by the plan)
  -> Evidence and provenance resolution
  -> Bounded synthesis (transient answer objects; nothing persisted)
```

Artifacts:

| File | Role |
| --- | --- |
| `tests/validation/phase35-query-interpreter.sql` | the single generic interpreter, included with `\ir` by both validations so no second query engine exists |
| `tests/validation/phase35-query-plan-validation.sql` | plan normalization, wording variation, capability bounds, determinism, non-persistence, read-only counts |
| `tests/validation/phase35-cross-domain-query-validation.sql` | full pipeline execution, answers, provenance, negative semantics, anti-contamination, determinism |
| `scripts/validation/run-postgres-validation.sh` | runs both Phase 35 validations twice, after Phase 34 |

Predicate semantics are **derived**, not listed: `p35_predicate_semantics` reads the `predicate`
registry and classifies each registered predicate into a semantic role
(`PARTICIPATION`, `LOCATION`, `ORDERING`, `KINSHIP`, `COMPOSITION`, `ATTRIBUTE`, `OTHER`) from the
registry's own description text and `event_participation_role_code`. A plan's candidate predicates
are always a subset of the registry; the validation asserts this.

Because Berean deliberately has no `Domain` table, a research "domain" is derived at query time from
resolved anchors plus one claim-asserted hop through the persisted graph. Anchors that resolve to
many persisted labels (> 10) are treated as **scope** anchors; anchors that resolve to few labels are
**concept** anchors used for statement-level filtering. This is a cardinality heuristic over
persisted labels, not a domain vocabulary.

## 3. Domain comparison (same interpreter, different substrate)

| Aspect | Genesis / Nephilim (Phases 30–31) | 1919 eclipse (Phases 32–33) |
| --- | --- | --- |
| Direct claims retrieved | `locatedAt` (Nephilim on the earth) | `participatesIn`, `occursAt`, `precedes`, `locatedAt` |
| Relationship roles present | KINSHIP, PARTICIPATION, LOCATION, ORDERING, COMPOSITION, ATTRIBUTE | PARTICIPATION, LOCATION, ORDERING |
| Scholarly candidates | Hendel 2004, Kline 1962, Wenham 1987 | Earman & Glymour 1980, Kennefick 2007 |
| Unreconciled identity | none proposed | `phase33-observatory-astronomer-royal` → `phase33_frank_dyson` (`PROPOSED`) |
| Concepts absent | cross-source identity equivalence | kinship, composition, attribute relations |

The interpreter recognises that a domain need not contain every generic concept: absent concepts
yield `UNRESOLVED` or `NOT_REPRESENTED` capability, never fabricated relations.

## 4. Required Genesis questions

Wordings A/B are materially different; both normalize to the same plan and retrieve the same keys.

### G1 — What does Genesis explicitly say about where the Nephilim were?

- Plan: `LOCATION` / `PLACE_SET`; candidate predicates `locatedAt, occursAt`; capability `ESTABLISHED`.
- Result (`DIRECTLY_SUPPORTED`): `CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30` — "Nephilim in Genesis 6:4 locatedAt earth".
- Provenance: `Claim CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30 -> Evidence EV_MT_GEN_6_1_4_P30 -> Citation CITE_MT_GEN_6_1_4 (Genesis 6:1-4) -> SourceRecord MT_GEN_6_1_4 -> Dataset GEN_MT_REF -> Source GEN_MT`.

### G2 — Who were the sons of God in Genesis 6?

- Plan: `CONCEPT_IDENTITY` / `CONCEPT_CANDIDATE_SET`; output constraint `NO_SINGLE_CANDIDATE_SELECTION`; capability `SCHOLARLY_CANDIDATE`.
- Results (`SCHOLARLY_CANDIDATE`, no claim promotion): `EV_HENDEL_2004_DIVINE_BEING_P31`, `EV_HENDEL_2004_P30` (divine-being reading), `EV_KLINE_1962_P30` (royal-human reading).
- Results (`EVIDENCE_ONLY_NOT_CLAIM`): `EV_MT_GEN_6_1_4_SONS_OF_GOD_P31`, `EV_MT_GEN_5_22` — the source text mentions "sons of God" but Berean asserts no identification claim.
- No candidate is selected; competing readings coexist with citations.

### G3 — Does Numbers identify the same Nephilim as Genesis?

- Plan: `IDENTITY_EQUIVALENCE` / `IDENTITY_EQUIVALENCE_STATUS`; output constraint `NO_INVENTED_EQUIVALENCE`; capability `UNRESOLVED`.
- Results (`UNRESOLVED_IDENTITY`): source identity "Nephilim" in `GEN_MT` maps to canonical entity `nephilim_gen6`; `NUM_MT` contributes no reconciled identity, so no cross-source equivalence exists.
- Results (`EVIDENCE_ONLY_NOT_CLAIM`): `EV_MT_GEN_6_1_4_P30`, `EV_MT_NUM_13_33_P30`, `EV_MT_NUM_13_33_INDEPENDENT_REPORT_P31` are returned as retained observations "without equivalence assertion".
- No `sameAs` predicate is invented and no chronology is asserted.

### G4 — What source supports Berean's statement that the Nephilim were on the earth?

- Plan: `PROVENANCE` / `PROVENANCE_CHAIN`; provenance requirement `FULL_CHAIN`; capability `ESTABLISHED`.
- Result (`DIRECTLY_SUPPORTED`): `Claim CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30 -> ClaimEvidence SUPPORTS -> Evidence EV_MT_GEN_6_1_4_P30 -> EvidenceCitation -> Citation CITE_MT_GEN_6_1_4 (Genesis 6:1-4) -> SourceRecord MT_GEN_6_1_4 -> Dataset GEN_MT_REF -> Source GEN_MT`.

## 5. Required eclipse questions

### E1 — Which people participated in observations, and where were those observations held?

- Plan: `PARTICIPATION_LOCATION_COMPOSITION` / `AGENT_PLACE_PAIR_SET`; capability `DERIVABLE`.
- 7 derived pairs per wording (`DERIVED_FROM_PERSISTED_GRAPH`), e.g. `Arthur Stanley Eddington participatesIn phase33_principe_observation_1919 occursAt Principe eclipse station`, also Cottingham (Principe), Davidson and Crommelin (Sobral), plus the corresponding Phase 32 events.
- Traversal is generic: `participatesIn` and `occursAt` are selected by registry semantic role, not by name.

### E2 — What source observations remain evidence-only rather than claims?

- Plan: `EVIDENCE_CLASSIFICATION` / `EVIDENCE_SET`; output constraint `CLAIM_LINKAGE=NONE`; capability `ESTABLISHED`.
- Results (`EVIDENCE_ONLY_NOT_CLAIM`): `EV_P33_OBSERVATORY_MEETING_DISCUSSION` (reservations expressed in discussion) and `EV_MT_GEN_32_28`. Both carry citations and explicitly report `[ClaimEvidence: none]`.

### E3 — Which source identities have not been fully reconciled to canonical entities?

- Plan: `IDENTITY_RECONCILIATION` / `IDENTITY_MAPPING_SET`; output constraint `MAPPING_STATUS<>ACTIVE`; capability `ESTABLISHED`.
- Result (`UNRESOLVED_IDENTITY`): source identity "The Astronomer Royal" (`OBSERVATORY_1919_ECLIPSE`) proposed for `phase33_frank_dyson` `[PROPOSED]`. The mapping is retrieved, never activated.

### E4 — Which theory did the eclipse observations prove?

- Plan: `TRUTH_CONFIRMATION` / `TRUTH_ASSERTION`; candidate predicates `{}`; output constraint `NO_INVENTED_PREDICATE`; capability `NOT_REPRESENTED`.
- Result (`NOT_REPRESENTED`): "No registered predicate and no schema mechanism represents the requested relation; absence of representation is not a denial." Retrieval scope stays `BEREAN_ONLY`; no external supplementation.

## 6. Cross-domain novel questions

### X1 — Which relationships can Berean directly support, and which remain interpretive?

Answered by inspecting actual persisted knowledge, not by hard-coded text. 24 directly supported
relationship roles per wording and 4 interpretive groups, for example:

| Scope | Role / predicate | Classification |
| --- | --- | --- |
| `genesi` | KINSHIP / `fatherOf` (30 claims), `motherOf` (10), `siblingOf` (1) | DIRECTLY_SUPPORTED |
| `genesi` | PARTICIPATION / `participatesIn` (66), `subjectOf` (63), `childIn` (20), `parentIn` (12), `builderIn` (1) | DIRECTLY_SUPPORTED |
| `genesi` | LOCATION / `occursAt` (23), `locatedAt` (2); ORDERING / `precedes` (1); COMPOSITION / `hasComponent` (2); ATTRIBUTE / 8 predicates | DIRECTLY_SUPPORTED |
| `genesi` | KLINE_1962, WENHAM_1987 — 2 analytical observations each | INTERPRETIVE_ONLY |
| `eclips` | PARTICIPATION / `participatesIn` (9); LOCATION / `occursAt` (5), `locatedAt` (3); ORDERING / `precedes` (4) | DIRECTLY_SUPPORTED |
| `eclips` | EARMAN_GLYMOUR_1980, KENNEFICK_2007 — 2 analytical observations each | INTERPRETIVE_ONLY |

### X2 — One direct and one interpretive example per domain, with provenance

Both examples are selected dynamically from the persisted graph (deterministic `DISTINCT ON` over
ordered keys); no answer text is hard-coded.

| Scope | Example | Classification |
| --- | --- | --- |
| `genesi` | knows directly: `Adam fatherOf Seth` (full claim → source chain) | DIRECTLY_SUPPORTED |
| `genesi` | requires interpretation: Kline's royal-human reading of the sons of God, `[no claim promotion]` | SCHOLARLY_CANDIDATE |
| `eclips` | knows directly: `Andrew C. D. Crommelin participatesIn phase32_sobral_eclipse_observation_1919` | DIRECTLY_SUPPORTED |
| `eclips` | requires interpretation: Earman & Glymour's reassessment of the eclipse evidence | SCHOLARLY_CANDIDATE |

### X3 — Novel multi-hop derivation (not answer-encoded anywhere)

> "Which events supported by sources have people participating and a represented place?"

`PARTICIPATION_LOCATION_COMPOSITION` / `EVENT_SET`, capability `DERIVABLE`, 30 events per wording
(60 rows across both), spanning both domains — for example
`ark_resting [participants: Noah, Noah's Ark] [location: Ararat]`,
`jacob_household_migration [participants: Benjamin, Jacob] [location: Egypt]`, and the Principe and
Sobral observation events. Every row is classified `DERIVED_FROM_PERSISTED_GRAPH` and carries the
supporting claim/evidence/citation/source chain: derivation is never presented as source text.

## 7. Query-plan normalization and wording variation

All 11 groups reported `EQUIVALENT` for plan normalization and for retrieved-key/provenance equality:

```text
E1 EQUIVALENT | E2 EQUIVALENT | E3 EQUIVALENT | E4 EQUIVALENT | G1 EQUIVALENT | G2 EQUIVALENT
G3 EQUIVALENT | G4 EQUIVALENT | X1 EQUIVALENT | X2 EQUIVALENT | X3 EQUIVALENT
```

Plans are domain-neutral and inspectable; the validation additionally asserts that every candidate
predicate exists in the registry and that every semantic filter resolves to a persisted Berean label.

## 8. Unsupported questions and controlled limitations

`E4` is the explicit refusal case: theory confirmation has no registered predicate and no schema
mechanism, so the pipeline returns a controlled limitation with capability `NOT_REPRESENTED` instead
of an answer. `G3` returns `UNRESOLVED` rather than "no" — absence of a reconciliation is not a
denial of identity. `G2` returns candidates rather than a selection.

## 9. Provenance from both domains

- Genesis, direct claim: `Claim CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30 -> ClaimEvidence SUPPORTS -> Evidence EV_MT_GEN_6_1_4_P30 -> EvidenceCitation -> Citation CITE_MT_GEN_6_1_4 (Genesis 6:1-4) -> SourceRecord MT_GEN_6_1_4 -> Dataset GEN_MT_REF -> Source GEN_MT`
- Eclipse, direct claim: `Claim CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION -> Evidence EV_P33_PRINCIPE_OBSERVATIONS -> Citation CITE_P33_REPORT_PRINCIPE_OBSERVATIONS -> Source ECLIPSE_1919_REPORT`
- Scholarly candidate (no claim promotion): `Evidence EV_KLINE_1962_P30 -> Citation CITE_KLINE_1962_187_204 (Westminster Theological Journal 24 (1962): 187-204) -> SourceRecord KLINE_1962_187_204 -> Dataset KLINE_1962_REF -> Source KLINE_1962 [no claim promotion]`
- Graph-derived answer: the derived path is printed explicitly (`X participatesIn E occursAt P`) together with the supporting claims, evidence, citations and sources.

## 10. Negative semantic validation

| Check | Observed | Expectation |
| --- | --- | --- |
| NO_INVENTED_PREDICATE | 0 | no `confirmsTheory`/`sameAs`/`contradicts`/`occursOnDate`… registered |
| NO_PREDICATE_OUTSIDE_REGISTRY | 0 | every planned predicate comes from the registry |
| NO_SCHOLARSHIP_PROMOTED_TO_CLAIM | 0 | analytical observations back no claim |
| NO_CONTRADICTION_INFERRED_FROM_DIFFERENCE | 0 | no answer reports difference as contradiction |
| NO_TRUTH_ASSERTION | 0 | no answer is classified TRUE/CONFIRMED/PROVEN |
| NO_FABRICATED_QUANTITY_OR_DATE | 0 | every number in an answer already occurs in persisted knowledge |
| NO_SILENT_IDENTITY_RECONCILIATION | 0 | the `PROPOSED` mapping is never activated |
| ABSENCE_IS_NOT_FALSE | 2 | unrepresented relations return controlled limitations |
| BEREAN_ONLY_RETRIEVAL | 0 | no plan leaves the Berean substrate |

The six `claim_relation` rows persisted by earlier phases are deliberately represented disagreement;
Phase 35 neither adds to them nor reads a difference between sources as a contradiction.

## 11. Anti-contamination validation

| Check | Observed |
| --- | --- |
| Phase 35 question text found in evidence/claims/events/source records/citations | 0 |
| Persisted (non-temporary) relations named `p35_%`/`phase35_%` | 0 |
| Persisted knowledge keys containing `phase35`/`p35` | 0 |

No Phase 35 question or expected answer exists in any fixture, candidate, or table: the answers are
retrieved from Phase 30–33 knowledge that was populated long before these questions were written.
All interpreter state is `TEMP`; nothing survives the session.

## 12. Read-only behaviour and determinism

Counts captured before and after the complete Phase 35 query suite:

| measurement | sources | datasets | source_records | citations | source_identities | mappings | entities | events | propositions | claims | evidence | claim_evidence | claim_relations |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| before | 19 | 23 | 154 | 154 | 97 | 97 | 135 | 106 | 318 | 331 | 166 | 340 | 6 |
| after | 19 | 23 | 154 | 154 | 97 | 97 | 135 | 106 | 318 | 331 | 166 | 340 | 6 |

Determinism:

- every question is interpreted twice and executed twice inside each script, and both scripts run
  twice in `run-postgres-validation.sh`;
- normalized plans, resolved anchors, retrieved keys, capability statuses, provenance strings and
  result classifications are compared for exact equality across runs;
- results are explicitly ordered and answer arrays are aggregated in sorted order.

## 13. Limitations

- **QUERY**: the generic interpreter is expressed as repository-native validation SQL, not a
  production API; its lexicon covers the generic concepts exercised here rather than open-ended
  English, and concept/scope anchoring uses a persisted-label cardinality heuristic.
- **REGISTRY_EXPRESSIVENESS**: theory confirmation, cross-source identity equivalence, motive and
  data-selection rationale have no registered predicate; these questions can only be answered as
  `NOT_REPRESENTED`/`UNRESOLVED`.
- **DATA_ENTRY**: answers are bounded by what Phases 30–33 actually stored; unstored source payloads
  remain policy-marked, not silence.
- **DOMAIN_SCOPING_LIMITATION**: Berean still has no `Domain` object, so scope is derived from
  resolved anchors plus one claim-asserted hop. Broad anchors (for example `genesi`) therefore scope
  more of the substrate than a curated domain boundary would. This is reported, not "fixed" by
  adding a schema object.

No requirement was classified as `ARCHITECTURAL_DEFICIENCY`.

## 14. Architectural assessment

Berean's natural-language scholarly research capability is **not** Phase 33/34-specific. A single
interpreter, containing no domain identifiers and no question-specific logic, resolved concepts
against persisted labels, resolved relationships from the predicate registry, planned domain-neutral
traversals, performed a capability check before retrieval, and produced provenance-backed answers in
two independently populated domains — including a multi-hop derivation that crosses both. Where a
domain lacks a concept, the same pipeline degrades to `UNRESOLVED` or `NOT_REPRESENTED` rather than
fabricating semantics.

The remaining limits are expressiveness and scoping limits of the registry and of the deliberate
absence of a domain object, not deficiencies of the query architecture.

## 15. Final verdict

PASS WITH INTENTIONAL LIMITATION
