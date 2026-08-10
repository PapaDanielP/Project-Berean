# Phase 19 Report: Source-Backed Ark Lifecycle Conflict, Handling Event, Observed Consequence, and Claim-Relation Validation

## Scope, baseline, and source availability

Phase 19 continues directly from the validated Phase 18 state and tests whether Berean's existing generic model can represent the smallest source-backed 2 Samuel 6:3-7 Ark-of-the-Covenant lifecycle slice without adding transport, touch, cart, cause, violation, compliance, artifact-lifecycle, or relationship infrastructure.

The clean Phase 18 baseline was established first on a fresh PostgreSQL 16 database. The authoritative runner passed with no blocking failures. Baseline counts were: 6 sources, 6 datasets, 55 source records, 55 citations, 57 evidence rows, 42 entities, 10 source identities, 10 active mappings, 38 events, 129 propositions, 140 claims, 147 ClaimEvidence links, 6 ClaimRelations, and 95 projected `event_participation` rows. Application baseline checks also passed against a fresh app database: `npm run test` (7/7), `npm run lint`, and `npm run typecheck`.

The selected source slice is exactly **2 Samuel 6:3-7**, following the repository's manually-entered reference-point convention. Phase 19 records locators and source observations only; `source_record.raw_content`, `source_record.content_hash`, and `citation.quoted_text` remain `NULL`. No Scripture text, quotation, translation, hash, external dataset, causation, compliance judgment, contradiction, route, duration, or pole/ring physical state was fabricated.

## Semantic question and registry sufficiency check

The question tested was whether the already-validated Phase 18 model can represent:

- the Ark transported on a new cart;
- only explicitly supported transport participants;
- Uzzah as a named person;
- Uzzah's source-recorded physical interaction with the Ark;
- Uzzah's source-recorded death as a historical consequence only to the extent directly supported;
- the distinction between Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7;
- observed source facts versus interpretation, compliance, causation, and contradiction.

The existing registry proved sufficient. Phase 19 uses the existing `OTHER` event type for the new-cart transport and physical-interaction occurrences, the existing `DEATH` event type for Uzzah's death, and the existing `subjectOf` / `participatesIn` predicates for projected participation. No new schema, table, column, event type, participation role, predicate, ClaimRelation type, JSON payload, graph subsystem, or inference mechanism was added.

## Architecture decision

Phase 19 is a pure source-backed population and validation phase. It deliberately does **not** add `TRANSPORT`, `CARRIER`, `TOUCHED`, `CART`, `HANDLED_BY`, `VIOLATED_REQUIREMENT`, `COMPLIANCE`, `CAUSE`, `CONSEQUENCE`, artifact/lifecycle/participant/relationship tables, JSON artifact semantics, artifact columns, or inference infrastructure.

The existing model can faithfully state that a source records an event and its participants. It cannot, and should not in this phase, add fine-grained physical-touch or causal/punitive semantics without unsupported false precision. That boundary is documented as a **SEMANTIC PRECISION GAP**, not as a reason to introduce speculative architecture.

## Entities, source identities, and mappings

Reused unchanged:

- `ark_of_covenant` — the single canonical Ark of the Covenant `OBJECT` entity.
- `poles_ark_covenant` and `rings_ark_covenant` — existing component `OBJECT` entities from Phase 16.
- Phase 17's `ark_covenant_pole_standing_requirement` and Phase 18's `ark_covenant_transport_jordan` remain unchanged.

Added:

- `uzzah` (`PERSON`) — justified because 2 Samuel 6:3-7 names Uzzah in the selected slice.
- `new_cart_2sam6` (`OBJECT`) — justified because 2 Samuel 6:3 records the new cart as the transport object.
- `mt-uzzah-2sam6` and `mt-new-cart-2sam6` source identities in `2SA_MT`, with evidence-backed ACTIVE mappings to `uzzah` and `new_cart_2sam6` respectively.

No source identity or mapping was added for the Ark, poles, or rings from 2 Samuel. The existing Phase 16 `mt-ark-covenant` mapping remains the only Ark mapping.

## Source records, citations, evidence, events, propositions, claims, and ClaimEvidence

New source/dataset:

- `2SA_MT` — 2 Samuel, Masoretic textual tradition.
- `2SA_MT_REF` — manually-entered 2 Samuel reference points.

New source records and unquoted citations:

- `MT_2SA_6_3` / `CITE_MT_2SA_6_3`
- `MT_2SA_6_4` / `CITE_MT_2SA_6_4`
- `MT_2SA_6_5` / `CITE_MT_2SA_6_5`
- `MT_2SA_6_6` / `CITE_MT_2SA_6_6`
- `MT_2SA_6_7` / `CITE_MT_2SA_6_7`

New evidence rows:

- `EV_MT_2SA_6_3` supports the transport/cart/Uzzah transport claims.
- `EV_MT_2SA_6_6` supports the Uzzah-Ark physical-interaction claims.
- `EV_MT_2SA_6_7` supports the Uzzah death claim.
- `EV_MT_2SA_6_4` and `EV_MT_2SA_6_5` are source-availability observations only and support no claims in this phase.

New events and direct claims:

- `ark_covenant_transport_new_cart_2sam6` (`OTHER`)
  - `ark_of_covenant subjectOf ark_covenant_transport_new_cart_2sam6`
  - `new_cart_2sam6 participatesIn ark_covenant_transport_new_cart_2sam6`
  - `uzzah participatesIn ark_covenant_transport_new_cart_2sam6`
- `ark_covenant_physical_interaction_uzzah_2sam6` (`OTHER`)
  - `ark_of_covenant subjectOf ark_covenant_physical_interaction_uzzah_2sam6`
  - `uzzah participatesIn ark_covenant_physical_interaction_uzzah_2sam6`
- `uzzah_death_2sam6` (`DEATH`)
  - `uzzah subjectOf uzzah_death_2sam6`

All six new claims are `DIRECT_SOURCE_CLAIM`s and have complete provenance:

```text
Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence -> Claim -> Proposition
```

## ClaimRelations, contradiction analysis, and unresolved relationship decision

No Phase 19 `ClaimRelation` was added. The Exodus 25:15 standing requirement, Joshua 3:6 carrying event, and 2 Samuel 6:3 new-cart event are independent source-backed claims. Different transport descriptions do not by themselves constitute a logical contradiction, and Phase 19 does not infer non-compliance, violation, improper transport, or causation from their coexistence. This remains a **DOCUMENTED UNRESOLVED DECISION** rather than a modeled contradiction.

## Observed-state and consequence treatment

Phase 19 represents only source assertions:

- The Ark was set on a new cart: source-backed occurrence.
- Uzzah is named and involved in the selected slice: source-backed entity/participation.
- Uzzah physically interacted with the Ark: represented as a generic source-backed interaction occurrence, without a `TOUCHED` predicate.
- Uzzah died: represented as a `DEATH` event.

Phase 19 explicitly does **not** assert:

- the poles were present, absent, in the rings, removed, or not removed;
- the 2 Samuel event complied with or violated Exodus 25:15;
- Joshua 3:6 and 2 Samuel 6:3 contradict each other;
- Uzzah's interaction caused his death;
- the death was punishment for a violation;
- Ahio, oxen, locations, route, ownership, duration, or chronology beyond the selected locator order;
- derived knowledge of any kind.

## Validation added

New required files:

- `tests/fixtures/090-phase19-ark-lifecycle-conflict-fixture.sql`
- `tests/validation/phase19-ark-lifecycle-conflict-slice.sql`
- `tests/validation/phase19-coverage-report.sql`
- `tests/validation/phase19-negative-cases.sh`
- `docs/04-data/PHASE19_REPORT.md`

Modified runner:

- `scripts/validation/run-postgres-validation.sh` appends Phase 19 after Phase 18 and before the final negative-integrity rerun. No earlier suite was reordered, removed, skipped, or weakened.

Positive validation covers exact 2 Samuel 6:3-7 locators, no fabricated text/hash/quotation, source/citation/evidence/claim integrity, canonical Ark reuse, poles/rings reuse, Uzzah/new-cart bounded entities and mappings, event distinctions, source-backed interaction and death, projection-only event participation, preserved Phase 17/18 semantics, no Phase 19 ClaimRelation, no derived claims, and no artifact/JSON/transport-specific infrastructure.

Negative validation includes 18 transaction-scoped cases:

1. inferred Uzzah violation of Exodus 25:15;
2. contradiction solely because transport methods differ;
3. ClaimRelation without valid claims;
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

Cases blocked by schema constraints are documented by the negative script output (for example invalid ClaimRelation foreign keys and direct insertion into the `event_participation` view). All negative cases failed for intended reasons.

## Coverage classification

`phase19-coverage-report.sql` classifies the required items using the mandated vocabulary:

- **SOURCE-BACKED**: 2 Samuel 6:3-7 source availability, Ark new-cart transport, Uzzah-Ark interaction, Uzzah death.
- **SUPPORTED**: Uzzah and `new_cart_2sam6` entities/mappings.
- **RUNTIME VERIFIED**: Exodus 25:15 standing requirement remains projection-free; Joshua 3:6 transport remains distinct.
- **STRUCTURALLY REPRESENTED**: event/proposition/claim/evidence representation via existing generic model.
- **SOURCE AVAILABILITY GAP**: 2 Samuel 6:4-5 details are available as locators/evidence but not populated as distinct claims in this minimal phase.
- **ACQUISITION PENDING**: Ahio, oxen, locations, route, chronology, duration, ownership, and deferred lifecycle events.
- **INTENTIONALLY EXCLUDED**: compliance inference, causal interpretation, artifact lifecycle infrastructure.
- **NOT DERIVED**: contradiction between transport methods, pole/ring state, derived knowledge.
- **DOCUMENTED UNRESOLVED DECISION**: relationship among Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7.
- **SEMANTIC PRECISION GAP**: fine-grained physical touch and causal consequence semantics beyond generic occurrence representation.

## Final validation results and counts

Fresh final PostgreSQL validation (`scripts/validation/run-postgres-validation.sh`) passed on a newly created database, running schema/blocking validation, early and final negative fixture validation, `blocking-cases.sh`, Genesis 1 validations, Phases 6-18, STEP Bible checks, Phase 19 positive/coverage validation, Phase 19 negative cases, and final integrity rerun.

Final counts after Phase 19:

- sources: 7 (+1)
- datasets: 7 (+1)
- source records: 60 (+5)
- citations: 60 (+5)
- evidence rows: 62 (+5)
- entities: 44 (+2)
- active mappings: 12 (+2)
- events: 41 (+3)
- propositions: 135 (+6)
- claims: 146 (+6)
- ClaimEvidence links: 153 (+6)
- ClaimRelations: 6 (unchanged)
- projected `event_participation` rows: 101 (+6)

Application checks on a fresh app database passed: `npm run test` (7/7), `npm run lint`, and `npm run typecheck`.

## Source gaps and deferred decisions

Phase 19 intentionally leaves unpopulated: Ahio, oxen, places, route, duration, ownership, later Ark material, Joshua 6, Numbers transport material, compliance/violation, contradiction, causal explanation, and theological interpretation. These require separate source-backed phases and must not be inferred from this slice.

## Final architectural classification

Phase 19 is **SUPPORTED / RUNTIME VERIFIED** for the bounded source-backed 2 Samuel 6:3-7 lifecycle conflict/handling/consequence question using the existing Berean architecture. It confirms that Berean can preserve source-backed observed facts while excluding unsupported interpretation, compliance, causation, contradiction, and derived knowledge. No schema or registry extension was necessary.
