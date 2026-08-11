# Phase 34 — Natural-Language Scholarly Query Interpretation over the Phase 33 Eclipse Substrate

## 1. Objective and difference from Phase 33

Phase 34 tests whether Berean can translate natural-language scholarly questions into bounded,
reproducible query plans over the existing persisted Phase 33 1919 eclipse substrate, perform an
explicit capability check, retrieve represented claims/propositions/evidence, resolve provenance,
and compose bounded answers without inventing semantics.

Difference from Phase 33: Phase 33 validated independent population + withheld SQL interrogation;
Phase 34 validates a deterministic natural-language interpretation pipeline over that same persisted
substrate without repopulating it, changing schema, or persisting answers/plans.

## 2. Architecture pipeline

```text
Natural Language
  -> Query Interpretation
  -> Structured Query Plan (normalized, inspectable)
  -> Capability Check (ESTABLISHED / NOT_ESTABLISHED)
  -> Berean Graph Retrieval (BEREAN_ONLY)
  -> Evidence/Provenance Resolution
  -> Bounded Answer Composition
```

## 3. Query-plan examples

- **Relationship query (Q1)**
  - Classification: `RELATIONSHIP_LOOKUP`
  - Predicates: `participatesIn`, `occursAt`
  - Traversal: `Claim -> Proposition(participatesIn) -> Event -> Proposition(occursAt) -> Place`
  - Capability: `ESTABLISHED`

- **Multi-hop graph query (Novel)**
  - Classification: `GRAPH_DERIVATION`
  - Predicates: `participatesIn`, `occursAt`
  - Traversal: `Claim -> Proposition(participatesIn) -> Event -> Proposition(occursAt) -> Place`
  - Capability: `ESTABLISHED`

- **Provenance query (Q6)**
  - Classification: `PROVENANCE`
  - Traversal: `Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`
  - Capability: `ESTABLISHED`

- **Unsupported query (Q7)**
  - Classification: `UNSUPPORTED_THEORY_RELATION`
  - Unsupported concept: theory-confirmation truth relation
  - Capability: `NOT_ESTABLISHED`

## 4. Results for Q1–Q6

1. **Q1** (`DIRECTLY_SUPPORTED`): Arthur Stanley Eddington; Edwin T. Cottingham.
2. **Q2** (`DIRECTLY_SUPPORTED`):
   - `phase33_principe_observation_1919` -> Principe eclipse station
   - `phase33_sobral_observation_1919` -> Sobral eclipse station
3. **Q3** (`DIRECTLY_SUPPORTED`):
   - `phase33_principe_observation_1919` precedes `phase33_joint_eclipse_meeting_1919`
   - `phase33_sobral_observation_1919` precedes `phase33_joint_eclipse_meeting_1919`
4. **Q4** (`DIRECTLY_SUPPORTED` + `UNRESOLVED_NOT_ESTABLISHED`): represented source observations are retrieved by source, preserving evidence-only rows that back no claim.
5. **Q5** (`SCHOLARLY_CANDIDATE`): represented analytical observations are returned with citations; they are not promoted into direct claims.
6. **Q6** (`DIRECTLY_SUPPORTED`): provenance chain for Eddington participation resolves through claim -> evidence -> citation -> source record -> dataset -> source.

## 5. Results for Q7–Q10

All unsupported questions return capability `NOT_ESTABLISHED` and remain bounded:

7. Theory confirmation (`UNSUPPORTED_THEORY_RELATION`) -> `NOT_REPRESENTED`.
8. Exclusion rationale (`UNSUPPORTED_RELATION`) -> `UNRESOLVED_NOT_ESTABLISHED`.
9. Measured Sobral value (`UNSUPPORTED_QUANTITY`) -> `NOT_REPRESENTED`.
10. Exact Principe date (`UNSUPPORTED_DATE`) -> `NOT_REPRESENTED`.

No `excludedBecause`, `biasedBy`, `confirmsTheory`, or date/quantity substitution is invented.

## 6. Novel-query result

Novel query: **Which people are connected to an eclipse observation through participation, and where
did those observations occur?**

Result (`DERIVED_FROM_STORED_GRAPH`, deterministic order):
- Arthur Stanley Eddington -> `phase33_principe_observation_1919` -> Principe eclipse station
- Edwin T. Cottingham -> `phase33_principe_observation_1919` -> Principe eclipse station
- Charles R. Davidson -> `phase33_sobral_observation_1919` -> Sobral eclipse station
- Andrew C. D. Crommelin -> `phase33_sobral_observation_1919` -> Sobral eclipse station

## 7. Negative semantic tests

Validated in `tests/validation/phase34-natural-language-query-validation.sql`:
- invented predicates are absent;
- evidence-only/scholarly rows are not promoted to claims;
- source differences are not promoted to contradiction;
- no truth inference is persisted;
- no invented quantities or exact dates are promoted into Phase 33 claims;
- unresolved source identity (`phase33-observatory-astronomer-royal`) is not silently reconciled.

## 8. Complete provenance explanation example

For “Why does Berean say Eddington participated in the Principe observation?” the pipeline retrieves:

`CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION`
-> `EV_P33_PRINCIPE_OBSERVATIONS`
-> `CITE_P33_REPORT_PRINCIPE_OBSERVATIONS`
-> `P33_REPORT_PRINCIPE_OBSERVATIONS`
-> `ECLIPSE_1919_REPORT_P33`
-> `ECLIPSE_1919_REPORT`

with source-text status `NOT_STORED_BY_POLICY`.

## 9. Read-only before/after validation

Both new Phase 34 validations capture persistent-table counts for:
`source, dataset, source_record, citation, source_identity, entity_source_mapping, entity, event,
proposition, claim, evidence, claim_evidence, claim_relation`

and assert identical before/after totals.

## 10. Determinism and normalized plan repeatability

- Query plans are generated twice and compared for exact equality.
- Q1 retrieval is executed twice and compared for identical ordered output.
- Result sets are explicitly ordered.
- No dependence on insertion order or external retrieval.

## 11. Limitations classification

- **QUERY**: natural-language interpretation is implemented as deterministic SQL translation logic in validation, not a production API layer.
- **REGISTRY_EXPRESSIVENESS**: theory confirmation, exclusion rationale, exact observation date, and measured Sobral value are not represented by registered predicates/typed claims in Phase 33.
- **DATA_ENTRY**: anything outside represented Phase 33 locators remains unstored and thus not established.
- **DOMAIN_SCOPING_LIMITATION**: bounded eclipse corpus intentionally limits coverage breadth.

No requirement was classified `ARCHITECTURAL_DEFICIENCY`.

## 12. Architectural assessment

Yes. Within current registry and represented corpus, Berean can translate natural-language scholarly
questions into bounded reproducible queries, preserve provenance boundaries, and explicitly refuse
unsupported claims without fabricating predicates, facts, relationships, quantities, dates, or truth
verdicts.

## 13. Final verdict

PASS WITH INTENTIONAL LIMITATION
