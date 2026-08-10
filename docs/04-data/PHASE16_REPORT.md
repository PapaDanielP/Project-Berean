# Phase 16 Report: Source-Backed Rich Artifact Semantics — Noah's Ark and Ark of the Covenant

## Scope, source availability, and baseline

Phase 16 extends the controlled knowledge population beyond the bounded Genesis 8:4 Noah's Ark
slice established by Phases 11/14/15, to determine through source-backed runtime validation
whether the existing generic `Entity`/`SourceIdentity`/`EntitySourceMapping`/`Proposition`/
`Claim`/`Evidence`/`Event` architecture can faithfully represent rich persistent-object semantics:
construction, builder relationships, instructions vs. completed events, dimensions and unit
preservation, materials (made-of vs. overlay), components, contents, and lifecycle events.

The fresh-database baseline (before any Phase 16 change) passed the authoritative runner with no
blocking failures or warnings, and `npm run test` (7/7), `npm run lint`, and `npm run typecheck`
all passed cleanly, matching the Phase 15 baseline exactly.

Selected bounded population slice, using only the repository's established "manually entered
reference point" convention (locator + citation recorded; no verbatim text, hash, or quotation —
identical to the convention already used for Genesis 1, Genesis 5, and Genesis 8:4):

- **Noah's Ark**: Genesis 6:14 (material/covering/rooms — instruction), Genesis 6:15 (dimensions
  — instruction), Genesis 6:16 (door/window components — instruction), Genesis 6:22 (construction
  completed), Genesis 7:7 (entering event). Genesis 8:4 (resting) is reused unchanged.
- **Ark of the Covenant**: Exodus 25:10 (dimensions/material — instruction), Exodus 25:11 (gold
  overlay — instruction), Exodus 25:12 (rings — instruction), Exodus 25:13 (poles — instruction),
  Exodus 25:17 (mercy seat — instruction), Exodus 25:18 (cherubim — instruction), Exodus 37:1
  (Bezalel's completed construction), Exodus 40:20 (Moses places the tablets of the testimony
  inside; sets the poles and mercy seat), Deuteronomy 10:3 (Moses' first-person account of
  personally making an ark).

Requirements not populated in this phase remain **SOURCE AVAILABILITY GAP / ACQUISITION PENDING**:
Numbers 4/7/10's transport-by-Kohathites narrative, 1 Samuel/2 Samuel narrative material, and any
later Ark-of-the-Covenant lifecycle events — none of these were fabricated.

## Architecture decision: the smallest justified generic extension

No table, JSON payload, artifact-specific store, or reconciliation mechanism was added. The
repository's own established mechanism for controlled generic extension — registering new rows
in the `predicate`, `event_type`, and `event_participation_role` tables in
`schema/sql/001_core_schema.sql` — was used, since no prior phase (6–15) had ever needed to add a
predicate and this is the first source-backed requirement that could not be represented by the
existing registry.

Added to the registry (schema only; no new table):

- `event_type`: `INSTRUCTION` (a commanded/specified act, not evidence of completion) and
  `CONSTRUCTION` (the source's own assertion of completed building) — kept semantically distinct
  so an instruction is never treated as a completed-construction claim.
- `event_participation_role`: `BUILDER`.
- `predicate`: `builderIn` (ENTITY→EVENT, role BUILDER; only valid against a CONSTRUCTION event),
  `lengthCubits`, `widthCubits`, `heightCubits` (ENTITY→VALUE; unit preserved in the predicate name,
  following the exact existing `ageAtDeathYears`/`yearsFromCreation` convention — no separate unit
  column and no modern-unit conversion), `madeOfMaterial` (primary/structural material, distinct
  from) `overlaidWithMaterial` (covering/coating material), `hasComponent` and `containsContent`
  (ENTITY→ENTITY, for persistent components/contents the source individually specifies).

This is the entirety of the generic model change. It is deliberately minimal: no artifact table,
no attribute columns on `Entity`, no participant table, and no new reconciliation infrastructure.

### Documented unresolved decision / semantic precision gap

Exodus 25:15 ("the poles shall be in the rings of the ark: they shall not be taken from it") is a
**standing handling/transport requirement**, not a single event occurrence. Forcing it into
`participatesIn` would misrepresent an ongoing restriction as a one-time event fact, so it is
intentionally **not** modeled as any claim or proposition in this phase. This is documented as a
**SEMANTIC PRECISION GAP** rather than silently omitted or forced into an ill-fitting predicate.

## Artifact and semantic coverage

| Item | Classification | Finding |
| --- | --- | --- |
| Noah's Ark construction/instruction/dimensions/materials/components (Genesis 6:14–16, 6:22) | SUPPORTED / RUNTIME VERIFIED | Direct, fully provenanced claims against `noahs_ark`. |
| Noah's Ark entering event (Genesis 7:7) | SUPPORTED / RUNTIME VERIFIED | Reuses the existing `noahs_ark`/`noah` entities. |
| Ark of the Covenant construction/instruction/dimensions/materials/components/contents (Exodus 25, 37, 40) | SUPPORTED / RUNTIME VERIFIED | `ark_of_covenant` now has an active, evidence-backed source-identity mapping (`mt-ark-covenant`), resolving the Phase 11/14/15 "structurally represented, unmapped" status. |
| Bezalel vs. Moses builder attribution (Exodus 37:1 vs. Deuteronomy 10:3) | DOCUMENTED UNRESOLVED DECISION | A genuine source disagreement, preserved via `claim_relation` `CONTRADICTS` rather than resolved — mirrors the existing MT/LXX genealogy contradiction pattern. |
| Exodus 25:15 pole-handling/transport restriction | SEMANTIC PRECISION GAP | A standing requirement, not a single event; intentionally left unpopulated rather than forced into `participatesIn`. |
| Modern-unit dimension conversion | INTENTIONALLY EXCLUDED | No derivation was created; original cubit units are preserved via unit-suffixed predicates. |
| Numbers/1–2 Samuel transport and later lifecycle events | SOURCE AVAILABILITY GAP | Not populated in this phase; would require its own bounded slice and source records. |
| Artifact-specific tables, JSON semantic payloads, or a participant store | INTENTIONALLY EXCLUDED | The existing `Entity`/`SourceIdentity`/`Proposition`/`Claim`/`Evidence`/`Event` architecture proved sufficient. |

New entities (all qualify as persistent referents because the source individually specifies and/or
repeatedly addresses them as distinct things): `moses`, `bezalel` (`PERSON`); `door_noahs_ark`,
`window_noahs_ark`, `mercy_seat`, `cherubim_kapporet`, `rings_ark_covenant`, `poles_ark_covenant`,
`tablets_of_testimony` (`OBJECT`).

New events: `ark_building_instruction`, `ark_construction_completed`, `ark_entering` (Noah's Ark);
`ark_covenant_instruction`, `ark_covenant_construction`, `ark_covenant_contents_placement` (Ark of
the Covenant). `INSTRUCTION` and `CONSTRUCTION` event types are never conflated; `builderIn` is
only ever asserted against a `CONSTRUCTION` event, never an `INSTRUCTION` event.

New `entity_source_mapping`: `ark_of_covenant` now has one active, evidence-backed mapping from a
new `source_identity` (`mt-ark-covenant`, source `EXO_MT`), justified by Exodus 25:10 evidence. It
remains a distinct canonical Entity from `noahs_ark`; no merge was performed.

Every direct assertion retains the complete provenance chain:

```text
Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
```

`event_participation` remains a pure projection of asserted propositions; no authoritative
participant table exists. Materials distinguish `madeOfMaterial` (e.g. acacia wood, gopher wood)
from `overlaidWithMaterial` (e.g. pure gold, pitch), exactly where the source itself draws that
distinction (Exodus 25:10–11; Genesis 6:14). Components (`hasComponent`) and contents
(`containsContent`) are recorded only for referents the source individually specifies (door,
window, rings, poles, mercy seat, cherubim, tablets of the testimony) — no invented component or
content was added.

## Validation and integrity

Phase 16 adds:

- `tests/fixtures/060-phase16-artifact-construction-fixture.sql` — the bounded data fixture,
  loaded last in the pipeline (after Phase 15 and the STEP Bible slice) so that earlier phases'
  bounded coverage/deferral checks, which were written before this data existed, are unaffected.
- `tests/validation/phase16-artifact-construction-slice.sql` — positive validation covering
  locator integrity, source/citation integrity (no fabricated text/hash), complete provenance,
  entity/mapping integrity, instruction-vs-construction event typing, builder relationships
  (including the preserved Bezalel/Moses contradiction), unit-preserving dimensions (and rejection
  of any bare/unitless or modern-unit predicate), made-of-vs-overlay materials, components/
  contents, the intentionally-absent handling-restriction gap, event-participation projection, no
  JSON payload, and no derivation.
- `tests/validation/phase16-coverage-report.sql` — the required coverage/classification report.
- `tests/validation/phase16-artifact-negative-cases.sh` — 15 transaction-scoped negative cases:
  artifact claim without evidence, dimension without unit, fabricated modern-unit conversion,
  unsupported fabricated material/component/content/builder, instruction represented as completed
  construction, arbitrary JSON semantic payload, direct participant-table insertion, unjustified
  reconciliation, mapping without evidence, derived claim without inputs, derived claim used as
  its own input, and fabricated source text/hash/quotation. All 15 pass.

Only one pre-existing file required a change: `tests/validation/genesis-1-20-31-slice.sql`'s
predicate allow-list, because the predicate registry (`schema/sql/001_core_schema.sql`) is loaded
before any fixture regardless of ordering, so this check would otherwise see the new Phase 16
predicates immediately. The check was extended to explicitly permit them, with a comment
explaining why; no check was weakened, removed, or bypassed. No other Phase 6–15 or STEP Bible
validator required modification, because the Phase 16 fixture and validators run at the very end
of `scripts/validation/run-postgres-validation.sh`, after every earlier phase's checks.

Fresh final PostgreSQL validation (`scripts/validation/run-postgres-validation.sh` against a newly
created database) **passed with no blocking failure or warning**, running: schema/blocking
validation, the negative fixture (both the early and final reruns), `blocking-cases.sh` (both
runs), Genesis 1:1–5 through 1:20–31, Phase 6–10, Phase 11 object/artifact slice, Phase 12–15
(including the Phase 15 corruption suite, 9/9), STEP Bible acquisition manifest and source slice,
and the new Phase 16 fixture, positive slice, coverage report, and 15/15 negative cases. Final
counts: 41 entities (9 `OBJECT` entities among the Phase 16 additions plus `noahs_ark`/
`ark_of_covenant`), 10 source identities, 10 active mappings, 53 source records/citations, 55
evidence rows, 124 propositions, 135 claims, 142 ClaimEvidence links, 35 events, 91 projected
participation rows, 3 derivations, and 6 claim relations (5 pre-existing + 1 new Bezalel/Moses
contradiction).

`npm run test` (7/7), `npm run lint`, and `npm run typecheck` all passed against a separate fresh
application database; the application layer was not modified.

## Architecture assessment

**The existing generic architecture faithfully represents every source-backed requirement tested
in this phase** — construction, builder relationships (including a genuine, preserved builder
disagreement), the instruction-vs-completed-event distinction, unit-preserving dimensions,
made-of-vs-overlay materials, source-specified components and contents, and multi-event lifecycle
participation for a persistent artifact — using only `Entity`, `SourceIdentity`,
`EntitySourceMapping`, `Proposition`, `Claim`, `Evidence`, `Event`, `event_participation`, and 8
newly registered predicates plus 2 event types and 1 participation role, added through the
repository's existing predicate-registry extension mechanism. **No confirmed architectural
deficiency was found; no new table, attribute column, JSON payload, or participant store was
required.** The one intentionally unrepresented item (Exodus 25:15's pole-handling restriction) is
a documented semantic precision gap by deliberate design choice, not evidence that the
architecture cannot represent it — a future bounded extension using a Derivation-free, standing-
requirement-appropriate predicate remains possible if warranted, but none is proposed now.

## Changed files

- `schema/sql/001_core_schema.sql` — registered 2 `event_type` rows, 1 `event_participation_role`
  row, and 8 `predicate` rows (the entire generic-model change).
- `tests/fixtures/060-phase16-artifact-construction-fixture.sql` — new Phase 16 data fixture.
- `tests/validation/phase16-artifact-construction-slice.sql` — new positive validation.
- `tests/validation/phase16-coverage-report.sql` — new coverage report.
- `tests/validation/phase16-artifact-negative-cases.sh` — new negative-case suite.
- `tests/validation/genesis-1-20-31-slice.sql` — extended the predicate allow-list to include the
  8 new Phase 16 predicates (unavoidable given schema-first loading order); no check weakened.
- `scripts/validation/run-postgres-validation.sh` — added the four new Phase 16 lines at the end
  of the pipeline, after STEP Bible validation and before the final negative-integrity rerun.
- `docs/04-data/PHASE16_REPORT.md` — this report.
