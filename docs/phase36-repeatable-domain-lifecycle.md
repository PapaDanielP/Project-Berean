# Phase 36 — Repeatable Domain Lifecycle and Independent Research Platform Validation

## Objective and domain selection

Phase 36 tests whether the lifecycle established for the 1919 eclipse can be repeated for a genuinely
new bounded domain without a schema, registry, Explorer, or capability-classification change. The
selected domain is the **two-day 1848 Seneca Falls Woman's Rights Convention**, bounded to the
contemporary published proceedings, a contemporary *North Star* report, and two later historical
studies.

This is distinct from the Genesis/Nephilim, Ark, and eclipse domains. It is deliberately small but
meaningful: it has multiple source traditions, people, places, two ordered events, explicit
participation and location relationships, a source-identity ambiguity, and two analytical
observations. The research objective is not to determine whether the convention was the origin of a
movement or which historiography is correct. It is to establish exactly what the represented corpus
supports while preserving unresolved identity and scholarly analysis separately.

## Lifecycle

1. **Candidate review** — `data/candidates/phase36-seneca-falls-domain-candidates.csv` records
   scope, representation decisions, and exclusions before population.
2. **Independent Stage A population** —
   `tests/fixtures/143-phase36-seneca-falls-domain-population-fixture.sql` is independently keyed
   (`phase36_*`, `*_P36`, `CLAIM_P36_*`), idempotent, source-driven, and contains no research
   question, expected answer, answer table, or interpretation verdict.
3. **Population validation** —
   `tests/validation/phase36-seneca-falls-domain-population-validation.sql` validates source scope,
   locator-only storage, provenance, direct-claim boundaries, scholarly isolation, lack of automatic
   contradiction, and unresolved identity.
4. **Independent Stage B interrogation** —
   `tests/validation/phase36-seneca-falls-independent-query-validation.sql` runs later, in a
   read-only transaction, to traverse persisted claims, retrieve the two scholarly observations, and
   expose the `PROPOSED` identity mapping. It persists nothing.

## Corpus and representation

| Source | Role |
| --- | --- |
| `SENECA_FALLS_PROCEEDINGS_1848` | contemporary proceedings |
| `NORTH_STAR_1848_SENECA_FALLS` | independent contemporary newspaper account |
| `WELLMAN_2004_SENECA_FALLS` | later historical analysis |
| `TETRAULT_2014_SENECA_FALLS` | later historiographical analysis |

All four datasets are locator-only: source records have no raw content or hash and citations have no
quoted text. This is a storage policy, not source silence.

The authoritative structured propositions use only established predicates:

- day one and day two `occursAt` Wesleyan Chapel;
- Stanton, Mott, Douglass, and the convention body `participatesIn` the represented events;
- day one `precedes` day two.

The six direct claims each have `SUPPORTS` evidence, citations, source records, datasets, and sources.
`EV_P36_WELLMAN_INTERPRETATION` and `EV_P36_TETRAULT_INTERPRETATION` are cited
`ANALYTICAL_OBSERVATION` rows and back no claim. They are not ranked, merged, or transformed into a
claim relation.

The proceedings' `Mrs. Mott` is retained as a source identity with a justified, evidence-backed
`PROPOSED` mapping to Lucretia Mott. The Phase 36 corpus does not itself provide a full-name
reconciliation, so the mapping is not activated. `PROPOSED` is not `FALSE`.

## Independent research results and boundaries

Stage B retrieves direct claims with their provenance; it separately retrieves the two scholarly
candidate observations and the unresolved identity mapping. It neither chooses an interpretation nor
turns absent representation into a negative conclusion.

The following remain intentionally unrepresented:

- a claim that Seneca Falls was the first, decisive, or sole origin of a movement;
- a contradiction or ranking between Wellman and Tetrault;
- a proposition-level identity equivalence for `Mrs. Mott`;
- calendar dates or outcomes of resolutions.

Those limits are `REGISTRY_EXPRESSIVENESS` or bounded-corpus `DATA_ENTRY` limits, not a reason to add
predicates or a second relationship store. The existing Explorer/API remains read-only and unchanged:
this phase validates persisted-domain lifecycle behavior, not a new query interface.

## Verification

`scripts/validation/run-postgres-validation.sh` replays Stage A, validates it, performs Stage B, and
repeats the sequence. The fixture's conflict-safe inserts and the validations ensure repeatability,
while Stage B checks that its read-only traversal leaves persistent counts unchanged.

**Verdict: PASS WITH INTENTIONAL LIMITATION.** The established domain lifecycle is repeatable across
an independent historical domain using the existing provenance, claim, predicate, identity, and
read-only research boundaries.
