# Phase 18 Report: Source-Backed Ark of the Covenant Transport and Handling Lifecycle

## Scope, baseline, and source availability

Phase 18 tests whether the existing generic `Entity`/`SourceIdentity`/`EntitySourceMapping`/
`Proposition`/`Claim`/`Evidence`/`Event` architecture -- as it stood after Phase 17, with no
further extension -- can faithfully represent a small, source-backed historical transport/
handling occurrence involving the Ark of the Covenant, while preserving the Phase 17 Exodus
25:15 standing requirement and never inferring compliance from it.

The fresh-database baseline (before any Phase 18 change) passed the authoritative runner with
no blocking failures or warnings. Fresh baseline counts, matching the Phase 17 report exactly:
41 entities, 10 source identities, 10 active mappings, 54 source records/citations, 56 evidence
rows, 125 propositions, 136 claims, 143 ClaimEvidence links, 36 events, 91 projected
participation rows, 3 derivations, and 6 claim relations. `npm run test` (7/7), `npm run lint`,
and `npm run typecheck` all passed cleanly against a separate fresh database, matching the
Phase 17 baseline.

### Source availability

Candidate transport/handling passages named in the phase mandate were investigated: Numbers
4:15, Numbers 7:9, Numbers 10:21, Joshua 3:3-6, Joshua 6:6-13, and 2 Samuel 6:3-7. None of
these locators was previously acquired in this repository; all were evaluated fresh against the
repository's "manually entered reference point" convention (locator recorded, no verbatim
source text, hash, or quotation stored -- the same convention Phase 16/17 used for Genesis,
Exodus, and Deuteronomy).

- **Numbers 4:15, 7:9, 10:21** describe the Kohathites bearing "the sanctuary" / "the holy
  things" upon their shoulders. In the plain text, none of these locators explicitly names "the
  ark of the covenant" as the specific object borne; asserting the Ark as their object would
  require an inference beyond the bare locator text (that "the sanctuary"/"the holy things"
  necessarily and exclusively denotes the Ark in that verse), which this repository's
  no-fabrication convention forbids. Classified **SOURCE AVAILABILITY GAP / ACQUISITION
  PENDING**.
- **Joshua 6:6-13** (the Ark carried around Jericho) and **2 Samuel 6:3-7** (the Ark transported
  on a new cart, with Uzzah) are legitimate candidates but are not the smallest bounded slice:
  Joshua 6 spans multiple verses and repeated circuits, and 2 Samuel 6 introduces a distinct
  cart-based transport method in tension with pole-based carrying -- a broader semantic surface
  than warranted for a single bounded phase. Classified **SOURCE AVAILABILITY GAP / ACQUISITION
  PENDING** for this phase.
- **Joshua 3:6** is the smallest bounded, coherent, explicitly-supported locator: in one verse
  it (a) explicitly names "the ark of the covenant" as the object commanded to be taken up and
  carried, (b) explicitly identifies "the priests" as those commanded and as those who carried
  it, and (c) contains both a command clause and a distinct, completed-action clause in the same
  verse, exactly mirroring the instruction/completed-event distinction Phase 16 already
  established for Noah's Ark (Genesis 6:14-16 vs. 6:22) and the Ark of the Covenant's
  construction (Exodus 25:10-22 vs. 37:1). It was selected as the sole new locator for this
  phase.

The bounded population scope for this phase is therefore exactly one new locator: **Joshua
3:6**.

## The semantic question and registry-sufficiency check performed first

Before writing any fixture, the phase mandate required attempting the transport slice using
only current registry capabilities (`participatesIn`, `subjectOf`, existing event types,
existing event roles), adding nothing if sufficient. That check was performed directly against
the pre-Phase-18 registry (`schema/sql/001_core_schema.sql`, unchanged since Phase 17):

- The registry already contains a generic `OTHER` event type, used previously (Phase 16) for
  `ark_entering` and `ark_covenant_contents_placement` -- both already-precedented, non-
  `INSTRUCTION`/`CONSTRUCTION`/`STANDING_REQUIREMENT` historical occurrences. `OTHER` is
  already unambiguously distinct from `INSTRUCTION`, `CONSTRUCTION`, and `STANDING_REQUIREMENT`,
  which is exactly the distinction the phase mandate required.
- The registry already contains `subjectOf` (SUBJECT role: the primary subject/thing acted
  upon) and `participatesIn` (PARTICIPANT role: a general participant), used previously (Phase
  16) in exactly the subject/participant shape needed here: the recipient of an instruction is
  `subjectOf` the `INSTRUCTION` event and the artifact affected is `participatesIn` it; the
  artifact that is the completed subject of an action is `subjectOf` the completed event and
  the acting party is `participatesIn` it.

This confirmed that **no genuine semantic deficiency exists** for this bounded slice: the
existing registry, unextended, can represent (a) Joshua's instruction to the priests, (b) the
priests' completed carrying of the ark, and (c) the ark and the priests as distinct participants
in each, without misrepresenting either as the other or as the Phase 17 standing requirement.
**No reproducible failing validation was created, because none was needed.** Per the phase
mandate ("add nothing if sufficient... possible extensions such as a generic TRANSPORT event
type or carrier role are not requirements and must not be added speculatively"), no new
`event_type` and no new `predicate` was added.

## Architecture decision: zero registry extension

**No table, column, JSON payload, participation role, event_type, or predicate was added.**
Phase 18 is a pure knowledge-population phase using the registry exactly as Phase 17 left it.
This is the "preferred outcome" contemplated by the phase mandate: the existing generic
architecture, unextended, already faithfully represents this bounded transport/handling slice.

### Why no specialized transport/carrier table or predicate was needed

`ark_of_covenant`, `poles_ark_covenant`, and `rings_ark_covenant` already exist as canonical
OBJECT entities from Phase 16, and the Phase 17 `standingRequirementIn`/`STANDING_REQUIREMENT`
extension already exists to represent the standing requirement without conflating it with any
occurrence. Joshua 3:6 requires only one new persistent entity (the priests, as carriers) and
two new events (one `INSTRUCTION`, one `OTHER`), all expressed with the pre-existing
`subjectOf`/`participatesIn` predicates. No artifact-specific, transport-specific, or
participant-specific schema was required, and none was added.

## Entities, source identities/mappings, events, propositions, claims, evidence added

- **Entities**: one new entity, `priests_levites_ark_bearers` (`ORGANIZATION` -- an
  already-registered, previously-unused `entity_type`; no new `entity_type` was added),
  "the priests who bore the ark of the covenant", explicitly identified by Joshua 3:6. No
  individual priest is named in this locator, so no individual `PERSON` entity was fabricated
  for any of them. `ark_of_covenant`, `poles_ark_covenant`, and `rings_ark_covenant` are reused
  unchanged; no duplicate was created for any of them.
- **Source identities / mappings**: none added. Joshua 3:6 is a direct claim about the
  already-canonical `ark_of_covenant` entity and a newly-introduced but directly-asserted
  `priests_levites_ark_bearers` entity; neither required a new source-identity reconciliation.
  The existing `mt-ark-covenant` ACTIVE mapping (source identity -> `ark_of_covenant`) is
  verified unchanged.
- **New source and dataset**: `JOS_MT` (Joshua, Masoretic textual tradition, `SCRIPTURE`) and
  `JOS_MT_REF` (Joshua reference points), following the exact `EXO_MT`/`EXO_MT_REF` pattern.
- **New source record**: `MT_JOS_3_6` (Joshua 3:6), with exactly one matching, unquoted
  citation, following the established "manually entered reference point" convention (locator
  recorded; no verbatim text, hash, or quotation).
- **New events**:
  - `ark_covenant_transport_instruction_jordan`, typed `INSTRUCTION` -- Joshua's command to the
    priests to take up the ark and pass over before the people; not itself an assertion of
    completed transport.
  - `ark_covenant_transport_jordan`, typed `OTHER` -- the distinct, completed historical
    transport/handling occurrence: the priests took up the ark of the covenant and went before
    the people.
- **New propositions/claims** (all `DIRECT_SOURCE_CLAIM`):
  - `priests_levites_ark_bearers subjectOf ark_covenant_transport_instruction_jordan`
    (`CLAIM_PRIESTS_RECIPIENT_ARK_TRANSPORT_INSTRUCTION`)
  - `ark_of_covenant participatesIn ark_covenant_transport_instruction_jordan`
    (`CLAIM_ARK_COVENANT_PARTICIPANT_TRANSPORT_INSTRUCTION`)
  - `ark_of_covenant subjectOf ark_covenant_transport_jordan`
    (`CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN`)
  - `priests_levites_ark_bearers participatesIn ark_covenant_transport_jordan`
    (`CLAIM_PRIESTS_PARTICIPANT_TRANSPORT_JORDAN`)
- **New evidence**: `EV_MT_JOS_3_6`, a single source observation, cited to `CITE_MT_JOS_3_6`,
  and linked to all four claims above via `claim_evidence` (`SUPPORTS`).

Complete provenance for each new direct claim:

```text
Source (JOS_MT) -> Dataset (JOS_MT_REF) -> SourceRecord (MT_JOS_3_6) -> Citation (CITE_MT_JOS_3_6)
  -> Evidence (EV_MT_JOS_3_6) -> ClaimEvidence (SUPPORTS) -> Claim -> Proposition
```

## Requirement/event distinction and compliance restriction

- **Instruction vs. historical transport event vs. standing requirement**:
  `ark_covenant_transport_instruction_jordan` (`INSTRUCTION`), `ark_covenant_transport_jordan`
  (`OTHER`), and `ark_covenant_pole_standing_requirement` (`STANDING_REQUIREMENT`, from Phase
  17, untouched) are three distinct, non-conflated events. The transport event carries exactly
  the `subjectOf` (ark) and `participatesIn` (priests) propositions; it carries no
  `standingRequirementIn` proposition, and the standing-requirement event carries no
  `subjectOf`/`participatesIn`/`builderIn` proposition of any kind.
- **Only explicitly source-supported participants**: exactly two entities project into
  `event_participation` for the transport event -- `ark_of_covenant` (`SUBJECT`) and
  `priests_levites_ark_bearers` (`PARTICIPANT`). No Kohathite, no individual priest, and no
  poles/rings participation was asserted; Numbers material was deliberately not used to name
  any participant, consistent with its classification as a source-availability gap.
- **Observed physical state**: not asserted. Joshua 3:6 makes no statement about the poles or
  the rings; no claim states anything about their state during this transport. Classified
  **SOURCE AVAILABILITY GAP** (no source observation exists to populate it).
- **Compliance**: not asserted, and never inferred. Nothing in this phase infers that the
  Exodus 25:15 requirement was obeyed, that the poles remained in the rings during this
  transport, or that this transport event is evidence of compliance with, or violation of, the
  standing requirement. Classified **INTENTIONALLY EXCLUDED** -- only a future source-backed
  observation could establish any of this.
- The Phase 17 `standingRequirementIn` proposition and its `STANDING_REQUIREMENT` event are
  untouched: the standing-requirement event still contains exactly one proposition, remains
  typed `STANDING_REQUIREMENT`, and still projects zero rows into `event_participation` (91
  before this phase, still 91 contributed by pre-Phase-18 events; the new count of 95 total
  projected rows is entirely due to the four new transport-slice `subjectOf`/`participatesIn`
  propositions -- 2 per event x 2 events -- not any change to the standing requirement).

## Validation and integrity

Phase 18 adds:

- `tests/fixtures/080-phase18-ark-transport-fixture.sql` -- the bounded data fixture, loaded
  last in the pipeline (after Phase 17), extending the Phase 16/17 fixtures in place without
  truncating any prior phase.
- `tests/validation/phase18-ark-transport-slice.sql` -- positive validation covering locator
  integrity (exactly one new locator, no unintended locator, no fabricated text/hash), registry
  sufficiency (exact event_type/predicate counts confirming no new row was added, no
  artifact/transport-specific table, no JSON payload), exactly one canonical Ark and reused,
  unduplicated poles/rings, the new priests entity, the instruction/historical-event/standing-
  requirement distinction (including that the standing-requirement event remains typed
  `STANDING_REQUIREMENT`), that only the ark and the priests project as transport participants
  (with the correct roles), that `event_participation` remains a view (never a directly-
  writable table), that the standing requirement generates no transport participation or
  compliance claim, that no compliance claim of any kind exists, complete provenance (including
  a per-claim citation-completeness check) for every new direct claim, that source
  identities/mappings are unchanged beyond the pre-existing `mt-ark-covenant` mapping, and that
  Noah's Ark and prior Phase 16 semantics are entirely unaffected.
- `tests/validation/phase18-coverage-report.sql` -- the required coverage/classification
  report, distinguishing SOURCE-BACKED, SUPPORTED, INTENTIONALLY EXCLUDED, SOURCE AVAILABILITY
  GAP, and DOCUMENTED UNRESOLVED DECISION for the Ark, poles, rings, the standing requirement,
  the transport event(s), the identified carriers, observed physical state, compliance, and
  deferred lifecycle material.
- `tests/validation/phase18-negative-cases.sh` -- 16 transaction-scoped negative cases, exactly
  matching the phase mandate's required list: (1) standing requirement represented as a
  transport event, (2) transport fabricated solely from the standing requirement, (3)
  compliance inferred solely from the standing requirement, (4) participant fabricated without
  evidence, (5) transport claim without ClaimEvidence, (6) evidence without citation, (7)
  fabricated source text/hash/quotation, (8) unsupported transport predicate, (9) direct
  participant-table insertion, (10) duplicate Ark entity, (11) duplicate pole/ring entity, (12)
  unjustified source reconciliation, (13) derived compliance claim without DerivationInput, (14)
  derived claim used as its own input, (15) transport event incorrectly typed as INSTRUCTION,
  (16) transport event incorrectly typed as STANDING_REQUIREMENT. All 16 pass, each failing for
  its intended reason.

Only one pre-existing file required a change, purely additive:

- `scripts/validation/run-postgres-validation.sh` -- appended the five new Phase 18 lines after
  the Phase 17 block and before the final negative-integrity rerun. No prior validation step was
  reordered, removed, or weakened.

No change was required to `tests/validation/genesis-1-20-31-slice.sql`'s predicate allow-list,
because this phase adds no new predicate.

Fresh final PostgreSQL validation (`scripts/validation/run-postgres-validation.sh` against a
newly created database) **passed with no blocking failure or warning**, running: schema/blocking
validation, the negative fixture (both the early and final reruns), `blocking-cases.sh` (both
runs), Genesis 1:1-5 through 1:20-31, Phase 6-10, Phase 11 object/artifact slice, Phase 12-17
(including the Phase 15/16 corruption suites and the Phase 17 standing-requirement suite),
STEP Bible acquisition manifest and source slice, and the new Phase 18 fixture, positive slice,
coverage report, and 16/16 negative cases. Final counts: 42 entities (+1: the priests entity),
10 source identities (unchanged), 10 active mappings (unchanged), 55 source records/citations
(+1), 57 evidence rows (+1), 129 propositions (+4), 140 claims (+4), 147 ClaimEvidence links
(+4), 38 events (+2), **95 projected participation rows (+4, entirely from the new transport
event's `subjectOf`/`participatesIn` propositions)**, 3 derivations (unchanged), and 6 claim
relations (unchanged).

`npm run test` (7/7), `npm run lint`, and `npm run typecheck` all passed against a separate
fresh application database; the application layer was not modified.

## Source gaps and unresolved questions

- Numbers 4:15, 7:9, and 10:21's Kohathite-bearing material remains **SOURCE AVAILABILITY GAP /
  ACQUISITION PENDING**: the plain text does not explicitly name the Ark as the object borne,
  so it was not used to name any participant in this phase.
- Joshua 6:6-13 (the Ark carried around Jericho) and 2 Samuel 6:3-7 (the Ark on a cart, with
  Uzzah) remain **SOURCE AVAILABILITY GAP / ACQUISITION PENDING**: legitimate future candidates,
  deliberately deferred to keep this phase to the smallest bounded slice.
- Whether the poles were physically in the rings during the Joshua 3:6 transport, and whether
  this transport complied with or violated the Exodus 25:15 standing requirement, are both
  **unresolved and intentionally unrepresented**; only a future source-backed observation (its
  own Source -> ... -> Claim chain, or a properly-inputted Derivation) could establish either.

## Changed files

- `tests/fixtures/080-phase18-ark-transport-fixture.sql` -- new Phase 18 data fixture.
- `tests/validation/phase18-ark-transport-slice.sql` -- new positive validation.
- `tests/validation/phase18-coverage-report.sql` -- new coverage report.
- `tests/validation/phase18-negative-cases.sh` -- new negative-case suite (16 cases).
- `scripts/validation/run-postgres-validation.sh` -- added the five new Phase 18 lines after the
  Phase 17 block and before the final negative-integrity rerun.
- `docs/04-data/PHASE18_REPORT.md` -- this report.

No change was made to `schema/sql/001_core_schema.sql`, to any Phase 6-17 fixture or
validation file, or to any other file. Architectural capability, source availability, semantic
precision, knowledge population, and derived knowledge are each addressed distinctly above: the
architecture required **zero** new capability (registry unextended); source availability was
the binding constraint (only Joshua 3:6 qualified among the candidates); semantic precision was
preserved by keeping the instruction/historical-event/standing-requirement distinction intact;
knowledge population added one bounded, fully-provenanced locator; and no derived knowledge
(compliance, observed state, or otherwise) was introduced.

## Final architectural classification

**The existing generic architecture, exactly as Phase 17 left it -- zero new tables, zero new
columns, zero new event_types, zero new predicates, zero new participation roles -- faithfully
represents the source-backed Joshua 3:6 Ark-of-the-Covenant transport/handling occurrence**
while strictly preserving every required distinction: an instruction
(`ark_covenant_transport_instruction_jordan`, `INSTRUCTION`) remains distinct from a completed
historical transport event (`ark_covenant_transport_jordan`, `OTHER`), which remains distinct
from the Exodus 25:15 standing requirement (`ark_covenant_pole_standing_requirement`,
`STANDING_REQUIREMENT`, untouched); only explicitly source-named participants (the ark, the
priests) were asserted; and no observed state, derived state, or inferred compliance claim was
introduced. **This phase confirms the "preferred outcome" contemplated by the mandate: no
confirmed architectural deficiency required any new registry row, table, attribute column, JSON
payload, or participant store.** Consistent with every prior phase's finding, `Entity`/
`SourceIdentity`/`EntitySourceMapping`/`Proposition`/`Claim`/`Evidence`/`Event` remains
sufficient for persistent artifacts and their lifecycle relationships -- including, in this
phase, a bounded historical transport/handling occurrence held distinct from a standing
requirement about the same artifact.
