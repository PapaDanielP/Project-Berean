# Phase 11 Object/Artifact Entity Slice Report

## Purpose

Demonstrate that tangible things, artifacts, structures, and other non-person/non-place entities
can be represented with the existing Entity-centered architecture, **without** introducing a
Thing/Artifact/Object table or a speculative ontology.

## Entity modeling decision

The `entity_type` controlled vocabulary already included an `OBJECT` value
(`schema/sql/001_core_schema.sql`: `('OBJECT', 'A physical object')`), but no fixture had ever
populated it. Phase 11 confirms the existing `entity` table is sufficient:

- **Category used:** the existing `OBJECT` `entity_type_code`. No new controlled value was added,
  because `OBJECT` already exists and is semantically adequate for a tangible artifact.
- **No new table introduced.** Both object entities (`noahs_ark`, `ark_of_covenant`) are ordinary
  rows in the existing `entity` table, addressed by the same `entity_key`/`entity_type_code`/
  `canonical_name`/`description` columns used for `PERSON`, `PLACE`, and `CONCEPT` entities.
- **No new architecture was introduced.** Reconciliation reuses the existing `source_identity` /
  `entity_source_mapping` tables; provenance reuses the existing `source` → `dataset` →
  `source_record` → `citation` → `evidence` → `claim_evidence` → `claim` → `proposition` chain;
  participation reuses the existing `event_participation` projection. No reproducible failure
  forced any schema change, so none was made.

## What was populated

### Noah's Ark (`noahs_ark`, entity_type `OBJECT`) — source-backed

- Reuses the already-accepted Genesis 8:4 structural source record (`MT_GEN_8_4`, `GEN_MT_REF`
  dataset, `GEN_MT` source) and its existing evidence (`EV_MT_GEN_8_4`, "Genesis 8:4 records the
  ark as resting on the mountains of Ararat.") that Phase 6 already populated for the `ark_resting`
  event.
- Added a `mt-ark` `source_identity` under the existing `GEN_MT` source, and an `ACTIVE`
  `entity_source_mapping` from `mt-ark` to `noahs_ark`, justified by and citing `EV_MT_GEN_8_4`
  (the same evidence Genesis 8:4 already supplied), demonstrating
  SourceIdentity → EntitySourceMapping → Entity for an object.
- Added one proposition, `noahs_ark participatesIn ark_resting`, using the existing
  `participatesIn` predicate (already registered as `ENTITY → EVENT` with `PARTICIPANT` role). No
  new predicate was introduced.
- Added one `DIRECT_SOURCE_CLAIM` (`CLAIM_MT_GEN_8_4_ARK_PARTICIPANT`) for that proposition,
  supported (`SUPPORTS`) by the existing `EV_MT_GEN_8_4` evidence — the same evidence row that
  already supports `CLAIM_NOAH_ARK_RESTING` and `CLAIM_ARK_RESTING_ARARAT`, exercising the existing
  `claim_evidence` many-to-many relationship (evidence shared by three distinct claims).
- Object event participation is verified purely through the existing `event_participation` view
  projection (`ark_resting` / `noahs_ark` / `PARTICIPANT`); no new join table was added.

### Ark of the Covenant (`ark_of_covenant`, entity_type `OBJECT`) — validation-only

- The Ark of the Covenant narrative belongs to Exodus and later books, outside this repository's
  Genesis 1–11 dataset and outside any source material acquired or inspected here (see Phase 9's
  STEP Bible acquisition, which is itself bounded to Genesis).
- It is added as a **validation-only canonical Entity** with **no** `source_record`, `citation`,
  `evidence`, `claim`, `proposition`, or `entity_source_mapping` row. No source text, quotation,
  hash, citation, or "inspected source" status is fabricated for it.
- Its sole purpose is to prove, alongside `noahs_ark`, that two canonical Entity records sharing
  the generic term "ark" remain distinct — distinct `entity_id`, distinct (or absent) source
  identity, and no possibility of claims/evidence from one silently attaching to the other.

## Semantic precision

All source-described characteristics (dimensions, materials, gopher wood, acacia wood, gold
plating, contents, etc.) remain **outside** the canonical entity. They are not stored as entity
attributes and were not introduced as claims either, since Genesis 8:4 (the only in-scope source
record touching Noah's Ark) does not describe those characteristics and no such text was acquired
or fabricated. `canonical_name`/`description` on both entities are limited to identification and
an explicit note of population status; they encode no dimension, material, or content assertion.
The Phase 11 validation slice (`tests/validation/phase11-object-entity-slice.sql`, check 8)
enforces this by rejecting entity descriptions that encode dimension/material/content language.

## Baseline and final validation

Baseline (pre-change) authoritative run:

```sh
DATABASE_URL=postgresql:///berean_phase11_baseline?host=/var/run/postgresql&user=<role> \
  scripts/validation/run-postgres-validation.sh
```

Result: **passed** (existing blocking validation, Phase 6–10 slices/reports, STEP Bible checks,
negative integrity checks — no Phase 11 files existed yet).

Final (post-change) authoritative run:

```sh
DATABASE_URL=postgresql:///berean_phase11_final?host=/var/run/postgresql&user=<role> \
  scripts/validation/run-postgres-validation.sh
```

Result: **passed**, including the new Phase 11 checks:

- `tests/fixtures/050-phase11-object-entity-fixture.sql`
- `tests/validation/phase11-object-entity-slice.sql`
- `tests/validation/phase11-coverage-report.sql`

and all prior Phase 6–10 regressions, the general `scripts/validation/validate.sql` blocking
checks, `tests/validation/blocking-cases.sh` negative-test suite, and the STEP Bible acquisition
manifest checks remained green.

## Negative-test results

`phase11-object-entity-slice.sql` asserts (all passed):

1. `noahs_ark` and `ark_of_covenant` are distinct `OBJECT` entities with distinct `entity_id`.
2. `noahs_ark` has exactly one `ACTIVE` `entity_source_mapping`; `ark_of_covenant` has none.
3. `ark_of_covenant` participates in no proposition; the `mt-ark` source identity maps only to
   `noahs_ark`.
4. Every proposition with `noahs_ark` as subject has a `DIRECT_SOURCE_CLAIM` with a complete
   Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
   chain.
5. The `mt-ark` SourceIdentity → EntitySourceMapping → Entity chain is complete (active status,
   justification, supporting evidence).
6. `noahs_ark` appears in the `event_participation` projection for `ark_resting`;
   `ark_of_covenant` appears in it nowhere.
7. `EV_MT_GEN_8_4` continues to support 3 distinct claims (ClaimEvidence many-to-many intact); the
   pre-existing competing Masoretic/Septuagint claims remain untouched.
8. No entity description encodes a dimension/material/content attribute.
9. `ark_resting` keeps its existing `OTHER` event type; the new claim introduces no
   `claim_relation`; no `thing`/`artifact`/`object`/`physical_object` table exists in the schema.
10. All prior Genesis 1–11 structural source records (Genesis 1:1–31, 5:3, 5:6, 8:4) remain
    unaltered.

## Rows added by object type (Phase 11 delta)

Measured immediately after loading `020-genesis-1-11-fixture.sql` and
`050-phase11-object-entity-fixture.sql` (before the unrelated STEP Bible fixture), compared to the
same point before this phase's changes:

| Table | Before | After | Delta |
|---|---|---|---|
| Entity | 30 | 32 | +2 (`noahs_ark`, `ark_of_covenant`) |
| SourceIdentity | 4 | 5 | +1 (`mt-ark`) |
| EntitySourceMapping | 4 | 5 | +1 (`mt-ark` → `noahs_ark`) |
| Proposition | 94 | 95 | +1 (`noahs_ark participatesIn ark_resting`) |
| Claim | 100 | 101 | +1 (`CLAIM_MT_GEN_8_4_ARK_PARTICIPANT`) |
| ClaimEvidence | 104 | 105 | +1 |
| Event | 34 | 34 | +0 (reuses existing `ark_resting`) |
| EventParticipation (projection rows) | 84 | 85 | +1 |
| Source / Dataset / SourceRecord / Citation / Evidence / Derivation / DerivationInput | unchanged | unchanged | +0 |

No new `source`, `dataset`, `source_record`, `citation`, or `evidence` row was created for
`noahs_ark`; it reuses the Genesis 8:4 records Phase 6 already populated. `ark_of_covenant` adds
only its single `entity` row.

## Source completeness

- Noah's Ark: structural Masoretic locator (`Genesis 8:4`) only; no source text reproduced; the
  same conservative posture as Phase 6–10.
- Ark of the Covenant: **source unavailable within this repository's scope.** No Exodus source
  material has been acquired, inspected, or fabricated. Documented as validation-only.

## Unresolved modeling questions

- Whether a future phase populating Exodus-era material would justify acquiring/inspecting an
  actual Ark-of-the-Covenant source record, converting it from validation-only to source-backed —
  this remains a genuinely open, unforced question and is explicitly out of scope here.
- Whether additional object-bearing predicates (e.g., a controlled `locatedAt`-style relation
  between an object and a place, already registered for `ENTITY → ENTITY`) will be needed for
  future object entities; none was needed for this bounded slice.

## Files changed

- `tests/fixtures/020-genesis-1-11-fixture.sql` (added `noahs_ark` entity, `mt-ark` source
  identity/mapping, proposition, and claim — reusing existing Genesis 8:4 provenance)
- `tests/fixtures/050-phase11-object-entity-fixture.sql` (new; validation-only `ark_of_covenant`)
- `tests/validation/phase11-object-entity-slice.sql` (new)
- `tests/validation/phase11-coverage-report.sql` (new)
- `scripts/validation/run-postgres-validation.sh`
- `data/genesis-1-11/README.md`
- `docs/04-data/PHASE11_REPORT.md` (this file)

## Classification

- **Architectural capability:** SUPPORTED
- **Runtime demonstration:** SUPPORTED / RUNTIME VERIFIED
- **Confirmed architectural deficiency:** NONE
- **Knowledge population:** `noahs_ark` (source-backed, Genesis 8:4) and `ark_of_covenant`
  (validation-only, distinctness demonstration) populated as distinct `OBJECT` entities
- **Source completeness:** structural Masoretic Genesis 8:4 locator only for Noah's Ark; Ark of
  the Covenant source material unavailable/not acquired, explicitly labeled validation-only
- **Semantic precision:** source-described characteristics remain claims/evidence, not canonical
  entity attributes; no dimension/material/content attribute was introduced on either entity
- **New modeling questions:** whether a future phase should acquire actual Ark-of-the-Covenant
  source material; no controlled predicate gap was found for this slice
- **Validation result:** PASS (baseline and final authoritative runs)
- **Repository integrity:** PASS (no new table, predicate, event type, or provenance layer
  introduced; existing Entity/SourceIdentity/EntitySourceMapping/Proposition/Claim/Evidence/
  event_participation architecture fully sufficient)
