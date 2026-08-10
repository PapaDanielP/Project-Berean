# Phase 14 Persistent Object/Artifact Population and Relationship Validation Report

## Scope and rationale

Phase 14 validates the smallest defensible source-backed artifact slice already present in the
repository: **Noah's Ark at Genesis 8:4** (`MT_GEN_8_4`). The repository has one acquired
Genesis 8:4 source record, citation, source observation, claims, source identity, active mapping,
event, and projected participation for this artifact. That is sufficient to runtime-verify
persistent artifact behavior without adding new source records or fabricating source text.

The selected artifact is **Noah's Ark** (`noahs_ark`). It qualifies as a persistent canonical
artifact Entity because the existing Genesis 8:4 source-backed slice treats "the ark" as an
identifiable object participant in the `ark_resting` event, and the same canonical Entity can be
reused by later source-backed claims if later source records are acquired.

No fixture data was added in Phase 14. The implementation adds validation and reporting around the
existing source-backed artifact slice. This preserves the accepted architecture and avoids
manufacturing Genesis 6-7 construction/dimension/material/occupant material that is not available in
the repository.

## Baseline validation

Baseline inspection covered the Phase 13 report, architecture/domain/schema documentation, ADRs,
Entity/SourceIdentity/EntitySourceMapping/Proposition/Claim/Evidence/Event/Derivation definitions,
predicate registry, Genesis fixture, Phase 6-13 validation reports, STEP Bible checks, and the
authoritative runner.

Baseline command, against a newly created PostgreSQL 16 database:

```sh
DATABASE_URL='postgresql://runner@/berean_phase14_baseline?host=/tmp&port=5433' \
  scripts/validation/run-postgres-validation.sh
```

Baseline result: **PASS**. The complete PostgreSQL validation emitted no blocking failure. A first
application test attempt without `DATABASE_URL` failed fast as designed; after setting a fresh test
database, `npm test -- --run` passed **7 tests**.

CI status was inspected through GitHub Actions. The initial workflow run for this PR was
`action_required` and exposed no jobs/logs to inspect; local baseline validation was therefore used
as the clean runtime baseline.

Baseline counts after loading `020-genesis-1-11-fixture.sql` and
`050-phase11-object-entity-fixture.sql`:

| Object | Count |
| --- | ---: |
| Entity | 32 |
| OBJECT entities | 2 |
| SourceIdentity | 9 |
| Active EntitySourceMapping | 9 |
| SourceRecord | 38 |
| Citation | 38 |
| Evidence | 39 |
| Proposition | 87 |
| Claim | 95 |
| ClaimEvidence | 102 |
| Event | 29 |
| Projected event participation | 74 |
| Derivation | 3 |
| ClaimRelation `CONTRADICTS` | 4 |

## Source availability and selected artifact

| Finding | Classification |
| --- | --- |
| Genesis 8:4 Masoretic source record exists as `MT_GEN_8_4` with locator `Genesis 8:4`. | SUPPORTED |
| `MT_GEN_8_4` has `raw_content`, `content_hash`, and citation `quoted_text` all NULL. | RUNTIME VERIFIED |
| Genesis 6-7 artifact construction, dimensions, materials, occupants, movement, and instructions are absent. | SOURCE AVAILABILITY GAP |
| Noah's Ark is selected only for the Genesis 8:4 resting/location slice. | POPULATED / SOURCE-BACKED |
| Ark of the Covenant remains validation-only and source-unpopulated in this repository. | ACQUISITION PENDING |

## Entity classification and persistence rationale

| Entity | Type | Classification | Rationale |
| --- | --- | --- | --- |
| `noahs_ark` | `OBJECT` | POPULATED / SOURCE-BACKED / STRUCTURALLY REPRESENTED | Canonical artifact Entity reused for the Genesis 8:4 source-backed participant claim. |
| `ark_of_covenant` | `OBJECT` | STRUCTURALLY REPRESENTED / ACQUISITION PENDING | Validation-only distinct artifact Entity with no source identity, mapping, claim, or evidence. |

Phase 14 validates **exactly one source-backed canonical artifact Entity**: `noahs_ark`.

## Source identity and reconciliation

| SourceIdentity | Source | Mapping | Status | Confidence | Evidence | Classification |
| --- | --- | --- | --- | ---: | --- | --- |
| `mt-ark` | `GEN_MT` | `noahs_ark` | `ACTIVE` | 0.9900 | `EV_MT_GEN_8_4` | SUPPORTED / RUNTIME VERIFIED |

The source identity is distinct from the canonical Entity. The active mapping has same-source
supporting evidence, non-empty justification, and confidence. Phase 14 adds regression checks for an
active mapping without evidence and a wrong canonical mapping.

## Relationships, event participation, and provenance

The artifact slice uses only registered predicates already present in the schema:

| Proposition | Claim | Evidence | Classification |
| --- | --- | --- | --- |
| `noahs_ark participatesIn ark_resting` | `CLAIM_MT_GEN_8_4_ARK_PARTICIPANT` | `EV_MT_GEN_8_4` | SOURCE-BACKED |
| `noah subjectOf ark_resting` | `CLAIM_NOAH_ARK_RESTING` | `EV_MT_GEN_8_4` | SOURCE-BACKED |
| `ark_resting occursAt ararat` | `CLAIM_ARK_RESTING_ARARAT` | `EV_MT_GEN_8_4` | SOURCE-BACKED |

Every direct artifact-event assertion has the required path:

```text
Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
```

Event participation remains projection-only through the existing `event_participation` view. No
participant truth table, relationship truth table, object table, artifact table, or object-source
mapping table was introduced.

## Counts for the selected artifact slice

| Metric | Count | Classification |
| --- | ---: | --- |
| Artifact entities | 1 | POPULATED |
| Artifact source identities | 1 | SOURCE-BACKED |
| Artifact active mappings | 1 | SOURCE-BACKED |
| Artifact source records | 1 | SOURCE-BACKED |
| Artifact citations | 1 | SOURCE-BACKED |
| Artifact evidence | 1 | SOURCE-BACKED |
| Artifact propositions | 3 | SOURCE-BACKED |
| Artifact claims | 3 | SOURCE-BACKED |
| Artifact ClaimEvidence links | 3 | SOURCE-BACKED |
| Artifact events | 1 | STRUCTURALLY REPRESENTED |
| Artifact projected participation rows | 1 | RUNTIME VERIFIED |
| Artifact derivations | 0 | NOT DERIVED |
| Artifact contradictions | 0 | INTENTIONALLY EXCLUDED |
| Total preserved contradictions | 4 | RUNTIME VERIFIED |

## Contradictions and derivations

No artifact contradiction was invented. Existing genuine Masoretic/Septuagint and derived chronology
contradictions remain preserved (`CONTRADICTS` count 4). No derivation was added for Noah's Ark, and
the validation rejects any derived artifact claim in this slice.

## Semantic exclusions and gaps

| Exclusion | Classification | Finding |
| --- | --- | --- |
| Ark construction, dimensions, material, occupants, movement, survival, and instructions | SOURCE AVAILABILITY GAP | Genesis 6-7 records are not available in the repository. |
| Artifact attributes such as material, dimensions, ownership, taxonomy, or modern identification | SEMANTIC PRECISION GAP / INTENTIONALLY EXCLUDED | Genesis 8:4 only supports the bounded resting/location participation slice. |
| Chronology, event ordering, causality, geography architecture, theology, and archaeology | INTENTIONALLY EXCLUDED | No registered source-backed predicate and no acquired source support justify these assertions here. |
| Additional artifact predicates for later source material | DOCUMENTED UNRESOLVED DECISION | Future phases may propose predicates only with source-backed failing validation. |

## Validation and negative tests

Added validation files:

- `tests/validation/genesis-artifact-slice.sql`
- `tests/validation/phase14-coverage-report.sql`

The authoritative runner now executes Phase 14 immediately after Phase 13 and before the STEP Bible
checks. Phase 14 regression protections reject these deliberately corrupted cases:

- duplicate canonical Noah's Ark artifact Entity;
- direct artifact claim without supporting evidence;
- active `mt-ark` mapping without supporting evidence;
- `mt-ark` mapped to the wrong canonical Entity;
- direct event-participation bypass or replacement of the projection view;
- unsupported artifact predicate;
- fabricated `raw_content`, hash, or quoted source text for `MT_GEN_8_4`;
- removed existing contradiction relation.

## Final validation

Final command, against a newly created PostgreSQL 16 database:

```sh
DATABASE_URL='postgresql://runner@/berean_phase14_final?host=/tmp&port=5433' \
  scripts/validation/run-postgres-validation.sh
```

Final result: **PASS**. The complete PostgreSQL validation ran the schema/blocking suites, negative
fixture, both `blocking-cases.sh` runs, Genesis 1:1-5, 1:6-9, 1:10-13, 1:14-19, 1:20-31, Phase
6-13, Phase 14, STEP Bible manifest/source checks, and final validation with no blocking failure.
`npm test -- --run` passed **7 tests** against a fresh database.

Final counts for the selected artifact slice match the baseline counts above. No warnings required
data repair.

## Repository integrity and architecture assessment

| Assessment item | Classification | Finding |
| --- | --- | --- |
| Existing Entity model for persistent artifacts | SUPPORTED / RUNTIME VERIFIED | `noahs_ark` is represented as an `OBJECT` Entity, with source identity, mapping, propositions, claims, evidence, and projected event participation. |
| Need for Object/Artifact/Thing tables | ARCHITECTURAL DEFICIENCY: none found | The existing model represented the bounded artifact slice without new tables. |
| Provenance completeness | RUNTIME VERIFIED | Every direct artifact assertion has Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition. |
| Source availability | CONTENT GAP / SOURCE AVAILABILITY GAP | Later ark material cannot be populated until source records are acquired. |
| Semantic precision | SEMANTIC PRECISION GAP | Genesis 8:4 supports resting/location participation, not dimensions/materials/occupants. |
| Future artifact population | DOCUMENTED UNRESOLVED DECISION | Later phases should acquire source records before adding artifact semantics. |

**Answer:** based on runtime validation, the existing Entity model is sufficient for persistent
artifacts in this bounded source-backed slice. Phase 14 found no architectural deficiency requiring
an Object, Artifact, Thing, specialized mapping, participant table, graph layer, or inference system.

## Changed files

- `tests/validation/genesis-artifact-slice.sql`
- `tests/validation/phase14-coverage-report.sql`
- `scripts/validation/run-postgres-validation.sh`
- `data/genesis-1-11/README.md`
- `docs/04-data/PHASE14_REPORT.md`
