# Phase 32 — Cross-Domain Scholarly Research Generalization (1919 Solar Eclipse)

## Scope

Phase 32 tests whether the Berean architecture generalizes beyond the Genesis/Nephilim
fixtures from Phases 30–31. It uses a bounded historical research problem: the 1919
solar-eclipse expedition and later interpretation of the Principe and Sobral observations.

It does not add schema, predicates, entity types, claim types, evidence types, interpretation
tables, truth/confidence/consensus fields, reconciliation/ranking mechanisms, or a second
knowledge store.

Research question:

> Can Berean represent primary and near-primary 1919 eclipse source observations, a meaningful
> data-handling ambiguity, a chronology question, and competing scholarly interpretations without
> converting source-backed observations or later scholarship into settled truth?

## Corpus actually used

- Primary expedition report: Dyson, Eddington, and Davidson 1920
  (`ECLIPSE_1919_REPORT`).
- Near-primary contemporary announcement: *The Observatory* 1919 joint-meeting report
  (`OBSERVATORY_1919_ECLIPSE`).
- Scholarship: Earman and Glymour 1980; Kennefick 2007.

No source text is redistributed. Source records and citations are locator-only, and unavailable
payloads remain `NOT_STORED_BY_POLICY`.

Artifacts:

- `tests/fixtures/141-phase32-eclipse-research-generalization-fixture.sql`
- `tests/validation/phase32-eclipse-research-generalization-validation.sql`
- `data/candidates/phase32-eclipse-research-candidates.csv`

## Deterministic result classifications

| Question / requirement | Result |
| --- | --- |
| Non-Genesis bounded historical problem | PASS |
| At least two independent primary or near-primary source traditions | PASS |
| Meaningful source disagreement or ambiguity | PASS |
| At least two identifiable entities and an event | PASS |
| Explicit representable relationship | PASS |
| Chronological question | PASS |
| At least two competing scholarly interpretations | PASS |
| At least one directly representable proposition | PASS |
| At least one important relationship not faithfully representable by current predicates | PASS WITH INTENTIONAL LIMITATION |
| No schema or registry changes | PASS |
| Deterministic replay/idempotent fixture behavior | PASS |

## Represented source-backed layer

Phase 32 creates direct source-backed claims only for relationships the existing predicate registry
can represent without interpretation:

- `phase32_principe_eclipse_observation_1919 occursAt phase32_principe`
- `phase32_sobral_eclipse_observation_1919 occursAt phase32_sobral`
- `phase32_arthur_eddington participatesIn phase32_principe_eclipse_observation_1919`
- `phase32_charles_davidson participatesIn phase32_sobral_eclipse_observation_1919`
- `phase32_andrew_crommelin participatesIn phase32_sobral_eclipse_observation_1919`
- `phase32_principe_eclipse_observation_1919 precedes phase32_joint_eclipse_announcement_1919`
- `phase32_sobral_eclipse_observation_1919 precedes phase32_joint_eclipse_announcement_1919`

These claims demonstrate entity/event relationships, event participation projection, and chronology
without asserting that any theory is true.

## Ambiguity and competing interpretations

The Sobral astrographic-plate data-handling issue is represented as a source observation only. The
fixture does not assert a predicate such as `excludedBecause`, `biasedBy`, `invalidates`, or
`confirmsTheory`; those would require interpretation or registry extension.

Earman/Glymour 1980 and Kennefick 2007 are represented as `ANALYTICAL_OBSERVATION` evidence. They
are useful scholarly interpretation candidates, but no claim links are created from them.

## Not established by represented corpus

- No claim that the eclipse observations proved, disproved, confirmed, or refuted general
  relativity or a Newtonian comparison value.
- No claim that a specific data-selection motive was present.
- No claim that one scholarly reassessment is correct or consensus.
- No contradiction relation merely because source traditions or scholars differ.
- No source silence inferred from absent stored source text.

## Architectural assessment

No architectural deficiency is introduced or fixed in Phase 32. The phase intentionally preserves
the current predicate registry limit: important research relations such as theory confirmation,
data weighting/exclusion rationale, and scholarly ranking cannot be faithfully represented without
interpretation.

This is a successful generalization test precisely because the existing architecture can represent
source-backed entities, events, relationships, chronology, provenance, citation policy, and
scholarly isolation while declining to manufacture unsupported truth.

## Determinism

- Fixture uses stable keys plus `ON CONFLICT`/`NOT EXISTS` inserts.
- Validation enforces non-promotion of ambiguous and scholarly evidence.
- Re-running the fixture produces no duplicate Phase 32 sources, records, evidence, entities,
  events, mappings, propositions, claims, or claim/evidence links.

## Final verdict

PASS WITH INTENTIONAL LIMITATION
