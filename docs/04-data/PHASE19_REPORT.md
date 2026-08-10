# Phase 19 Report: Source-Backed Ark Lifecycle Conflict, Handling Event, Observed Consequence, and Claim-Relation Validation

## Scope, baseline, and source availability

Phase 19 continues from the accepted Phase 18 state and tests the smallest source-backed 2 Samuel
6:3-7 Ark lifecycle slice: the Ark of the Covenant transported on a new cart, Uzzah as the only
new named person needed for this phase, Uzzah's source-recorded physical interaction with the Ark,
and Uzzah's source-recorded death. The purpose is not to populate the broader Ark narrative, but
to validate that the existing generic model can preserve source observation separately from
interpretation, compliance, causation, contradiction, and pole/ring physical-state inference.

Before changing files, the repository state, Phase 14-18 reports, core schema, Phase 16-18
fixtures/validators, validation runner, predicate/event-type/role registrations, ClaimRelation
mechanism, and existing Ark entities/claims/evidence/events/source mappings were inspected. A
fresh PostgreSQL baseline run of `scripts/validation/run-postgres-validation.sh` passed cleanly in
the Phase 18 state. Baseline counts matched the accepted Phase 18 state:

| Object | Baseline count |
| --- | ---: |
| Source | 6 |
| Dataset | 6 |
| SourceRecord | 55 |
| Citation | 55 |
| Evidence | 57 |
| Entity | 42 |
| SourceIdentity | 10 |
| EntitySourceMapping | 10 |
| Event | 38 |
| Proposition | 129 |
| Claim | 140 |
| ClaimEvidence | 147 |
| ClaimRelation | 6 |
| Derivation | 3 |
| Projected `event_participation` rows | 95 |

Application baseline: after installing existing npm dependencies with `npm ci`, `npm run lint` and
`npm run typecheck` passed. `npm run test` requires `DATABASE_URL`; without it, the existing app
test suite stops with the documented environment error. Against a fresh PostgreSQL app database
using a socket `DATABASE_URL`, `npm run test` passed 7/7.

### Source availability

Phase 19 intentionally acquires exactly one bounded source locator under the established manually
entered reference-point convention:

- `2SA_MT` / `2SA_MT_REF`
- `MT_2SA_6_3_7` with `source_location = '2 Samuel 6:3-7'`
- `CITE_MT_2SA_6_3_7`, with `quoted_text IS NULL`
- `EV_MT_2SA_6_3_7`, a source observation only

No `raw_content`, `content_hash`, or Scripture quotation is stored. No translation, external
dataset, hash, or source text is fabricated. The fixture does not populate unrelated 2 Samuel
material, Numbers material, Joshua 6 material, later Ark lifecycle events, locations, routes,
durations, ownership, oxen, Ahio, David, priests, Levites, or Kohathites.

## Semantic question and registry sufficiency

The pre-change model was tested first. Existing capabilities proved sufficient:

- `OTHER` can represent bounded historical occurrences that are not `INSTRUCTION`,
  `CONSTRUCTION`, or `STANDING_REQUIREMENT`.
- Existing `DEATH` can represent Uzzah's death without adding a generic `CONSEQUENCE` event type.
- Existing `subjectOf` and `participatesIn` can represent the Ark/new-cart transport event and the
  Uzzah/Ark interaction without a direct participant table.
- Existing `ClaimRelation` is available for genuine claim relations, but no Phase 19 contradiction
  is justified.
- Phase 17's `standingRequirementIn` remains the correct representation for Exodus 25:15 and does
  not project event participation.

No reproducible schema deficiency was found. Therefore Phase 19 adds no schema, registry row,
participation role, JSON payload, artifact/lifecycle table, transport table, causation predicate,
compliance predicate, contradiction predicate, or participant store.

## Architecture decision

Phase 19 is a pure source-backed population and validation phase. It makes zero changes to
`schema/sql/001_core_schema.sql` and adds no `TRANSPORT`, `CARRIER`, `TOUCHED`, `CART`,
`HANDLED_BY`, `VIOLATED_REQUIREMENT`, `COMPLIANCE`, `CAUSE`, `CONSEQUENCE`, artifact-specific
column, graph database, ontology, or inference infrastructure.

The model represents the 2 Samuel 6:3-7 slice as three source-recorded events:

1. `ark_covenant_new_cart_transport_2sam6` (`OTHER`)
2. `uzzah_ark_physical_interaction_2sam6` (`OTHER`)
3. `uzzah_death_2sam6` (`DEATH`)

This is sufficient for the required source-backed assertions while explicitly preserving the fact
that the model does not derive compliance, violation, causation, contradiction, chronology, route,
or pole/ring state.

## Entities, source identities, and mappings

New entities:

- `uzzah` (`PERSON`) — the named person needed for the bounded 2 Samuel 6:3-7 slice.
- `new_cart_ark_transport` (`OBJECT`) — the source-recorded new cart used in the Ark transport
  event.

Reused entities:

- `ark_of_covenant` (`OBJECT`) — exactly one canonical Ark entity, reused from Phase 16.
- `poles_ark_covenant` and `rings_ark_covenant` (`OBJECT`) — reused unchanged; no Phase 19 claim
  asserts their physical state, transport role, presence, absence, removal, or compliance.
- `priests_levites_ark_bearers` from Phase 18 remains scoped only to Joshua 3:6 and does not
  participate in the 2 Samuel event.

Source identities/mappings:

- No new `SourceIdentity` or `EntitySourceMapping` rows are required or added for Phase 19.
- Existing active mappings remain unchanged and evidence-backed.
- Negative validation rejects unsupported source-identity reconciliation for Uzzah or the new cart.

## Source records, citations, evidence, propositions, claims, and ClaimEvidence

One new source observation supports all six direct Phase 19 claims:

```text
Source (2SA_MT) -> Dataset (2SA_MT_REF) -> SourceRecord (MT_2SA_6_3_7)
  -> Citation (CITE_MT_2SA_6_3_7) -> Evidence (EV_MT_2SA_6_3_7)
  -> ClaimEvidence (SUPPORTS) -> Claim -> Proposition
```

New propositions/claims:

| Claim | Proposition |
| --- | --- |
| `CLAIM_ARK_COVENANT_SUBJECT_NEW_CART_TRANSPORT_2SAM6` | `ark_of_covenant subjectOf ark_covenant_new_cart_transport_2sam6` |
| `CLAIM_NEW_CART_PARTICIPANT_ARK_TRANSPORT_2SAM6` | `new_cart_ark_transport participatesIn ark_covenant_new_cart_transport_2sam6` |
| `CLAIM_UZZAH_PARTICIPANT_ARK_TRANSPORT_2SAM6` | `uzzah participatesIn ark_covenant_new_cart_transport_2sam6` |
| `CLAIM_UZZAH_SUBJECT_ARK_INTERACTION_2SAM6` | `uzzah subjectOf uzzah_ark_physical_interaction_2sam6` |
| `CLAIM_ARK_COVENANT_PARTICIPANT_UZZAH_INTERACTION_2SAM6` | `ark_of_covenant participatesIn uzzah_ark_physical_interaction_2sam6` |
| `CLAIM_UZZAH_SUBJECT_DEATH_2SAM6` | `uzzah subjectOf uzzah_death_2sam6` |

All six are `DIRECT_SOURCE_CLAIM`s and have `ClaimEvidence` rows pointing to `EV_MT_2SA_6_3_7`.
The optional `claim.statement` values are display labels only; the authoritative semantics remain
in the propositions plus event records and provenance.

## Events and projected participation

Projected Phase 19 participation is produced only by claim-backed propositions through the
`event_participation` view:

- `ark_covenant_new_cart_transport_2sam6`: Ark (`SUBJECT`), new cart (`PARTICIPANT`), Uzzah
  (`PARTICIPANT`).
- `uzzah_ark_physical_interaction_2sam6`: Uzzah (`SUBJECT`), Ark (`PARTICIPANT`).
- `uzzah_death_2sam6`: Uzzah (`SUBJECT`).

No direct insertion into `event_participation` is possible or used. The view remains the sole
participation projection. Poles, rings, priests, Levites, Kohathites, Noah's Ark, Moses, and
Bezalel do not project into any Phase 19 event.

## Observed-state and consequence treatment

Phase 19 records only observed source facts:

- Ark transport on a new cart is represented as a historical `OTHER` event.
- Uzzah's physical interaction with the Ark is represented as a historical `OTHER` event.
- Uzzah's death is represented as a `DEATH` event.

It does not convert these facts into any of the following:

- compliance with Exodus 25:15;
- violation of Exodus 25:15;
- proof that poles were present or absent;
- proof that poles remained in, or were removed from, rings;
- causation between the new cart/interaction and Uzzah's death;
- punishment, improper transport, ownership, route, duration, or chronology;
- contradiction with Joshua 3:6.

## Contradiction and ClaimRelation analysis

No Phase 19 `ClaimRelation` is added. The existing Phase 16 Bezalel/Moses builder disagreement
relations remain unchanged, and total `claim_relation` count remains 6.

The distinct source-backed facts are:

- Exodus 25:15 records a standing requirement about poles.
- Joshua 3:6 records an Ark transport by priests.
- 2 Samuel 6:3-7 records an Ark transport on a new cart and Uzzah's interaction/death.

Different transport descriptions are not, by themselves, a logical contradiction. Phase 19
therefore documents the relationship as unresolved and rejects any `ClaimRelation` involving Phase
19 claims unless a future source-backed and semantically justified relation is established.

## Compliance and inference exclusions

The following are intentionally excluded and runtime-validated as rejected:

- Uzzah violated Exodus 25:15.
- Anyone complied with Exodus 25:15 during 2 Samuel 6:3-7.
- The standing requirement caused, explained, or contradicts the 2 Samuel event.
- Joshua 3:6 and 2 Samuel 6:3-7 contradict each other solely because transport methods differ.
- Poles/rings physical state can be derived from either the standing requirement or the new-cart
  transport.
- Uzzah's death is causally modeled as resulting from a violation, cart transport, or physical
  interaction.

No `DERIVED_CLAIM`, `Derivation`, or `DerivationInput` is added by this phase.

## Negative validation results

`tests/validation/phase19-negative-cases.sh` adds 18 transaction-scoped corruption cases. All pass
by being blocked for intended reasons:

1. inferring Uzzah violated Exodus 25:15 without source-backed basis;
2. contradiction solely because transport methods differ;
3. ClaimRelation without valid underlying claims;
4. ClaimRelation without preserving both source-backed claims;
5. claim without ClaimEvidence;
6. evidence without Citation;
7. fabricated Scripture text/hash/quotation;
8. duplicate canonical Ark;
9. duplicate Uzzah;
10. unsupported participant;
11. fabricated pole/ring physical state;
12. fabricated causal relationship;
13. derived claim without DerivationInput;
14. derived claim used as its own input;
15. direct `event_participation` insertion;
16. arbitrary JSON artifact semantics;
17. unsupported predicate/event type;
18. unjustified SourceIdentity/EntitySourceMapping.

Some cases are blocked directly by the existing schema (for example invalid ClaimRelation foreign
keys and direct insertion into the projection view); this is documented by the negative suite and
does not require weakening validation.

## Final validation results and counts

A fresh PostgreSQL database run of `scripts/validation/run-postgres-validation.sh` passed after
adding Phase 19. The run included schema/blocking validation, negative fixture validation, both
blocking-case passes, Genesis 1 validators, Phases 6-18, STEP Bible checks, the Phase 19 fixture,
Phase 19 positive validation, Phase 19 coverage report, Phase 19 negative cases, and the final
integrity rerun.

Final counts after Phase 19:

| Object | Final count | Delta |
| --- | ---: | ---: |
| Source | 7 | +1 |
| Dataset | 7 | +1 |
| SourceRecord | 56 | +1 |
| Citation | 56 | +1 |
| Evidence | 58 | +1 |
| Entity | 44 | +2 |
| SourceIdentity | 10 | 0 |
| EntitySourceMapping | 10 | 0 |
| Event | 41 | +3 |
| Proposition | 135 | +6 |
| Claim | 146 | +6 |
| ClaimEvidence | 153 | +6 |
| ClaimRelation | 6 | 0 |
| Derivation | 3 | 0 |
| Projected `event_participation` rows | 101 | +6 |

Application validation after changes:

- `npm run test` against a fresh PostgreSQL app database: 7/7 passed.
- `npm run lint`: passed.
- `npm run typecheck`: passed.

## Coverage classifications

The Phase 19 coverage report classifies:

- 2 Samuel 6:3-7 source availability: **SOURCE-BACKED**.
- Ark transport on a new cart: **SOURCE-BACKED**.
- New cart / transport method: **SOURCE-BACKED**.
- Uzzah: **SOURCE-BACKED**.
- Uzzah physical interaction: **SOURCE-BACKED**.
- Uzzah death/consequence occurrence: **SOURCE-BACKED**.
- Exodus 25:15 requirement: **SUPPORTED**, unchanged.
- Joshua 3:6 transport: **SUPPORTED**, unchanged.
- Relationship among Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7: **DOCUMENTED UNRESOLVED DECISION**.
- Contradiction: **NOT DERIVED**.
- Compliance/violation inference: **INTENTIONALLY EXCLUDED**.
- Pole/ring state: **SOURCE AVAILABILITY GAP**.
- Causation/punishment interpretation: **INTENTIONALLY EXCLUDED**.
- Derived knowledge: **NOT DERIVED**.
- Deferred lifecycle events: **ACQUISITION PENDING**.
- Generic model sufficiency: **RUNTIME VERIFIED**.
- Query-level touched/cart/consequence vocabulary: **SEMANTIC PRECISION GAP**, deliberately not
  extended because no failing validation required it.

## Changed files

- `tests/fixtures/090-phase19-ark-lifecycle-conflict-fixture.sql`
- `tests/validation/phase19-ark-lifecycle-conflict-slice.sql`
- `tests/validation/phase19-coverage-report.sql`
- `tests/validation/phase19-negative-cases.sh`
- `scripts/validation/run-postgres-validation.sh`
- `docs/04-data/PHASE19_REPORT.md`

No schema file, prior fixture, prior validator, application source file, or package file was
changed.

## Final architectural classification

- **ARCHITECTURAL CAPABILITY**: Runtime verified. The existing generic architecture can represent
  the bounded source-backed 2 Samuel 6:3-7 lifecycle slice without schema or registry extension.
- **SOURCE AVAILABILITY**: Bounded to one manually-entered reference point. Broader Ark lifecycle
  material remains acquisition pending.
- **SEMANTIC PRECISION**: Preserved. Source assertion is distinguished from interpretation,
  compliance, causation, contradiction, temporal sequence, instruction, and completion. A reusable
  touched/cart/causal vocabulary remains a documented precision gap, not an implemented extension.
- **KNOWLEDGE POPULATION**: Adds only the required 2 Samuel 6:3-7 source record, two entities,
  three events, six propositions/claims, one evidence row, one citation, and six ClaimEvidence
  links.
- **DERIVED KNOWLEDGE**: None added. No compliance, violation, contradiction, pole/ring state, or
  causation is derived.

Final answer: Phase 19 confirms that Berean's generic provenance-first model can preserve the
source-backed 2 Samuel 6:3-7 Ark transport/handling/death slice while rejecting unsupported
interpretation, compliance, causation, and contradiction claims. No architectural deficiency
requiring schema change was found.
