# Phase 17 Report: Source-Backed Persistent Artifact Requirements and Lifecycle Relationships

## Scope, baseline, and source availability

Phase 17 tests whether the existing generic `Entity`/`SourceIdentity`/`EntitySourceMapping`/
`Proposition`/`Claim`/`Evidence`/`Event` architecture can faithfully represent the source-backed
Exodus 25:15 standing requirement -- "the poles shall be in the rings of the ark: they shall not
be taken from it" -- while preserving the distinction among an instruction, a standing
requirement, a historical/completed event, an observed state, a derived state, and an inferred
compliance claim.

The fresh-database baseline (before any Phase 17 change) passed the authoritative runner with no
blocking failures or warnings. Fresh final counts, matching Phase 16 exactly: 41 entities, 10
source identities, 10 active mappings, 53 source records/citations, 55 evidence rows, 124
propositions, 135 claims, 142 ClaimEvidence links, 35 events, 91 projected participation rows, 3
derivations, and 6 claim relations. `npm run test` (7/7), `npm run lint`, and `npm run typecheck`
all passed cleanly against a separate fresh database, matching the Phase 16 baseline.

Source availability was inspected before any change: the repository's Phase 16 fixture already
established the `EXO_MT` / `EXO_MT_REF` source and dataset, and the `poles_ark_covenant` and
`rings_ark_covenant` OBJECT entities, but had deliberately left Exodus 25:15 unpopulated as a
documented **SEMANTIC PRECISION GAP**. No other Ark-of-the-Covenant lifecycle material (Numbers
4/7/10 transport-by-Kohathites, 1-2 Samuel narrative, or any later event) is acquired in this
repository; none of it was inspected as newly available, so it remains **SOURCE AVAILABILITY GAP
/ ACQUISITION PENDING** and nothing was fabricated to populate it. The bounded population scope
for this phase is therefore exactly one new locator: **Exodus 25:15**.

## The semantic question and why a reproducible deficiency was demonstrated first

Before writing any fixture, a deficiency check was run against the existing predicate registry
(`schema/sql/001_core_schema.sql`, pre-Phase-17) to confirm that no existing predicate could
represent the requirement without misrepresenting it:

- Every existing ENTITY->EVENT predicate (`participatesIn`, `subjectOf`, `parentIn`, `childIn`,
  `builderIn`) carries a non-null `event_participation_role_code`, meaning each one asserts actual
  participation in an occurrence and projects into `event_participation`. Using any of them for
  Exodus 25:15 would misrepresent a standing, ongoing restriction as a single, already-occurred
  event fact -- exactly the false precision Phase 16 refused to introduce.
- No predicate existed that could assert "a source records that a requirement exists" without
  simultaneously asserting "this entity participated in / built / was the subject of a completed
  occurrence."

This confirmed a genuine, narrow semantic deficiency: the registry could represent *instructions*
(commanded acts, event_type `INSTRUCTION`) and *completed construction* (event_type
`CONSTRUCTION`), but had no way to represent a *standing/ongoing requirement* distinct from both,
without event-participation implications.

## Architecture decision: the smallest reusable generic extension

No table, JSON payload, artifact-specific store, or reconciliation mechanism was added. Following
the same registry-extension mechanism Phase 16 used, exactly two rows were added to
`schema/sql/001_core_schema.sql`:

- `event_type`: `STANDING_REQUIREMENT` -- "a source-recorded ongoing normative requirement or
  restriction, not a single occurrence; distinct from INSTRUCTION ... and CONSTRUCTION ...; must
  never be used to assert participation, compliance, transport, or historical occurrence."
- `predicate`: `standingRequirementIn` (ENTITY->EVENT) -- deliberately registered with
  `event_participation_role_code = NULL`, so it can **never** project into `event_participation`
  and can never be read as participation in a completed occurrence. It asserts only that the
  source records the requirement's existence.

No new `event_participation_role` was needed. This is the entirety of the generic-model change:
one event type, one predicate, zero tables, zero columns, zero participation roles.

### Why no specialized artifact table was needed

`poles_ark_covenant`, `rings_ark_covenant`, and `ark_of_covenant` already exist as canonical
OBJECT entities from Phase 16. The standing requirement is simply one more direct, source-backed
proposition about the already-canonical `poles_ark_covenant` entity, exactly like every other
Phase 16 claim -- it required no new entity, no new reconciliation, and no artifact-specific
schema. The only genuine gap was in the *predicate/event-type* vocabulary, not in the entity
model, and it was closed with the minimum possible registry addition.

## Entities, events, propositions, claims, evidence reused/added

- **Entities**: none added. `poles_ark_covenant`, `rings_ark_covenant`, and `ark_of_covenant`
  (all `OBJECT`, all pre-existing from Phase 16) are reused unchanged.
- **Source identities / mappings**: none added. The existing `mt-ark-covenant` ACTIVE mapping
  (source identity -> `ark_of_covenant`) is verified unchanged. No new source identity or
  reconciliation was created for `poles_ark_covenant` or `rings_ark_covenant`, since the standing
  requirement is a direct claim about an already-canonical entity, not a new identity to
  reconcile.
- **New source record**: `MT_EXO_25_15` (Exodus 25:15), in the existing `EXO_MT_REF` dataset,
  with exactly one matching, unquoted citation -- following the repository's established
  "manually entered reference point" convention (locator recorded; no verbatim text, hash, or
  quotation).
- **New event**: `ark_covenant_pole_standing_requirement`, typed `STANDING_REQUIREMENT`.
- **New proposition/claim**: `poles_ark_covenant standingRequirementIn
  ark_covenant_pole_standing_requirement`, asserted by the single new
  `CLAIM_POLES_STANDING_REQUIREMENT` (`DIRECT_SOURCE_CLAIM`).
- **New evidence**: `EV_MT_EXO_25_15`, a single source observation, cited to `MT_EXO_25_15`, and
  linked to the claim via `claim_evidence` (`SUPPORTS`).

Complete provenance for the standing requirement:

```text
Source (EXO_MT) -> Dataset (EXO_MT_REF) -> SourceRecord (MT_EXO_25_15) -> Citation (CITE_MT_EXO_25_15)
  -> Evidence (EV_MT_EXO_25_15) -> ClaimEvidence (SUPPORTS) -> Claim (CLAIM_POLES_STANDING_REQUIREMENT)
  -> Proposition (poles_ark_covenant standingRequirementIn ark_covenant_pole_standing_requirement)
```

## Standing-requirement semantics and the instruction/event/compliance distinctions

- **Instruction vs. standing requirement vs. historical event**: `ark_covenant_instruction`
  (`INSTRUCTION`), `ark_covenant_pole_standing_requirement` (`STANDING_REQUIREMENT`), and
  `ark_covenant_construction` (`CONSTRUCTION`) are three distinct, non-conflated event types. The
  standing-requirement event carries exactly one proposition (`standingRequirementIn`) and no
  `participatesIn`/`subjectOf`/`builderIn`/`parentIn`/`childIn` proposition of any kind; it never
  appears in the `event_participation` projection (verified at runtime: the projected-participation
  row count is unchanged at 91, identical to the Phase 16 baseline).
- **Observed state**: not asserted. No claim states that the poles were ever physically located
  in the rings; that would require its own source observation, which is not recorded.
  Classified **NOT DERIVED**.
- **Derived state**: not asserted. No `Derivation` or `DERIVED_CLAIM` exists for the standing
  requirement, its poles, or its rings. Classified **NOT DERIVED**.
- **Inferred compliance claim**: not asserted. Nothing in this phase infers that the instruction
  was obeyed, that the poles remained in the rings, that removal did or did not occur, or that
  transport occurred. Classified **INTENTIONALLY EXCLUDED** -- only a future source-backed
  observation could establish any of those facts.

## Validation and integrity

Phase 17 adds:

- `tests/fixtures/070-phase17-standing-requirement-fixture.sql` -- the bounded data fixture,
  loaded last in the pipeline (after Phase 16 and the STEP Bible slice), extending the Phase 16
  fixture in place without truncating any prior phase.
- `tests/validation/phase17-standing-requirement-slice.sql` -- positive validation covering
  locator/citation integrity (no fabricated text/hash), the generic extension itself (exactly the
  two new registry rows, no artifact/requirement-specific table, no JSON payload), reused entity
  integrity, event typing, the absence of any participation/construction/compliance/transport
  proposition on the standing-requirement event, the projection-only guarantee (zero
  `event_participation` rows for the new event), complete provenance, preserved Phase 16 semantics
  (`hasComponent`, materials, the active `ark_of_covenant` mapping), the absence of any new
  source-identity mapping for poles/rings, and that Noah's Ark and its projected participation
  are entirely unaffected.
- `tests/validation/phase17-coverage-report.sql` -- the required coverage/classification report,
  distinguishing SOURCE-BACKED, STRUCTURALLY REPRESENTED, SUPPORTED, SOURCE AVAILABILITY GAP,
  INTENTIONALLY EXCLUDED, and NOT DERIVED for every item in scope.
- `tests/validation/phase17-negative-cases.sh` -- 13 transaction-scoped negative cases: standing
  requirement represented as completed construction (`builderIn` against the
  `STANDING_REQUIREMENT` event), historical `participatesIn` fabricated solely from the
  requirement, `standingRequirementIn` misapplied to a `CONSTRUCTION` event, a claim without
  evidence, evidence without a citation, fabricated source text/hash for Exodus 25:15,
  compliance/non-removal inferred from the requirement, a fabricated transport/historical claim,
  an arbitrary JSON artifact-property payload, a direct `artifact_requirement` participant table
  bypassing propositions, an unsupported fabricated predicate, an unjustified reconciliation
  (mapping without evidence), and a derived claim without derivation inputs. All 13 pass.

Only two pre-existing files required a change, both additive and neither weakening any prior
assertion:

- `tests/validation/genesis-1-20-31-slice.sql` -- extended the predicate allow-list to include
  `standingRequirementIn`, for the same reason Phase 16 extended it: the predicate registry is
  loaded before any fixture regardless of ordering, so this check would otherwise see the new
  predicate immediately.
- `scripts/validation/run-postgres-validation.sh` -- appended the five new Phase 17 lines after
  the Phase 16 block and before the final negative-integrity rerun.

`tests/validation/phase16-artifact-construction-slice.sql` required **no change**: its existing
check (line 355-359) asserts that `MT_EXO_25_15` does not yet exist, and because the Phase 16
fixture and validation run entirely before the new Phase 17 fixture in the pipeline, that
assertion continues to hold true and pass at the point it runs -- it correctly describes the
state of the world as of Phase 16, before Phase 17's fixture is loaded later in the same run.

Fresh final PostgreSQL validation (`scripts/validation/run-postgres-validation.sh` against a newly
created database) **passed with no blocking failure or warning**, running: schema/blocking
validation, the negative fixture (both the early and final reruns), `blocking-cases.sh` (both
runs), Genesis 1:1-5 through 1:20-31, Phase 6-10, Phase 11 object/artifact slice, Phase 12-16
(including the Phase 15 and Phase 16 corruption suites), STEP Bible acquisition manifest and
source slice, and the new Phase 17 fixture, positive slice, coverage report, and 13/13 negative
cases. Final counts: 41 entities (unchanged), 10 source identities (unchanged), 10 active
mappings (unchanged), 54 source records/citations (+1), 56 evidence rows (+1), 125 propositions
(+1), 136 claims (+1), 143 ClaimEvidence links (+1), 36 events (+1), **91 projected participation
rows (unchanged)** -- confirming the standing requirement introduced zero new participation
projections -- 3 derivations (unchanged), and 6 claim relations (unchanged).

`npm run test` (7/7), `npm run lint`, and `npm run typecheck` all passed against a separate fresh
application database; the application layer was not modified.

## Source gaps and unresolved questions

- Numbers 4/7/10's transport-by-Kohathites narrative, 1 Samuel/2 Samuel narrative material, and
  any later Ark-of-the-Covenant lifecycle event remain **SOURCE AVAILABILITY GAP / ACQUISITION
  PENDING**; none was fabricated.
- Whether the poles were ever physically observed in the rings, whether that state persisted, and
  whether the instruction/requirement was obeyed are all **unresolved and intentionally
  unrepresented**; only a future source-backed observation (its own Source -> ... -> Claim chain,
  or a properly-inputted Derivation) could establish any of them.

## Changed files

- `schema/sql/001_core_schema.sql` -- registered 1 `event_type` row (`STANDING_REQUIREMENT`) and
  1 `predicate` row (`standingRequirementIn`, no participation role): the entire generic-model
  change.
- `tests/fixtures/070-phase17-standing-requirement-fixture.sql` -- new Phase 17 data fixture.
- `tests/validation/phase17-standing-requirement-slice.sql` -- new positive validation.
- `tests/validation/phase17-coverage-report.sql` -- new coverage report.
- `tests/validation/phase17-negative-cases.sh` -- new negative-case suite.
- `tests/validation/genesis-1-20-31-slice.sql` -- extended the predicate allow-list to include
  `standingRequirementIn`; no check weakened.
- `scripts/validation/run-postgres-validation.sh` -- added the five new Phase 17 lines after the
  Phase 16 block and before the final negative-integrity rerun.
- `docs/04-data/PHASE17_REPORT.md` -- this report.

## Final architectural classification

**The existing generic architecture, extended with the smallest possible reusable addition (one
event_type, one predicate, zero participation roles, zero tables), faithfully represents the
Exodus 25:15 standing requirement** while strictly preserving every required distinction: an
instruction (`INSTRUCTION`) remains distinct from a standing requirement
(`STANDING_REQUIREMENT`), which remains distinct from a completed/historical event
(`CONSTRUCTION`/other event types with participation roles); no observed state, derived state, or
inferred compliance claim was introduced. **No confirmed architectural deficiency required a new
table, attribute column, JSON payload, or participant store.** The reproducible deficiency that
was found and closed was narrowly a *predicate/event-type vocabulary* gap, not an entity-model
gap -- consistent with every prior phase's finding that `Entity`/`SourceIdentity`/
`EntitySourceMapping`/`Proposition`/`Claim`/`Evidence`/`Event` remains sufficient for persistent
artifacts and their lifecycle relationships.
