# Phase 15 Rich Persistent Object Semantics and Source-Backed Artifact Modeling

## Scope, source availability, and baseline

Phase 15 tests the accepted generic model using the sole acquired, source-backed artifact
slice: Noah's Ark at `MT_GEN_8_4` / Genesis 8:4. It adds no source data. The fresh-database
baseline passed the authoritative runner with no blocking failures or warnings. Its final
STEP Bible fixture counts were 32 entities (2 `OBJECT`), 9 source identities, 9 active mappings,
39 source records/citations, 41 evidence rows, 87 propositions, 98 claims, 105 ClaimEvidence
links, 29 events, 77 projected participation rows, 3 derivations, and 5 claim relations.

| Material | Classification | Finding |
| --- | --- | --- |
| Noah's Ark resting participation | SUPPORTED / RUNTIME VERIFIED | `noahs_ark`, `mt-ark`, and `MT_GEN_8_4` provide an auditable bounded slice. |
| Construction, instruction, dimensions, materials, components, contents, handling, transport, builders | SOURCE AVAILABILITY GAP | Genesis 6–7 records are not acquired; no assertion is manufactured. |
| Ark of the Covenant semantics | ACQUISITION PENDING | Its distinct validation-only `OBJECT` Entity has no acquired supporting source record. |
| Modern-unit conversion or inferred artifact attributes | SEMANTIC PRECISION GAP | No documented source-backed derivation exists. |

## Artifact and semantic coverage

Exactly one canonical source-backed artifact is validated: `noahs_ark` (`OBJECT`). Its source
identity `mt-ark` remains distinct and maps actively to the canonical Entity with confidence,
justification, and same-source supporting evidence. `ark_of_covenant` remains distinct and
unmapped. The only supported assertions are `noahs_ark participatesIn ark_resting`,
`noah subjectOf ark_resting`, and `ark_resting occursAt ararat`.

These are direct claims, not construction, completion, observation, instruction, or
specification claims. Thus Phase 15 does not confuse an instruction with completion, does not
represent dimensions/materials/components/contents as Entity columns or attributes, and adds no
derivation. Every direct assertion retains:

```text
Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
```

`event_participation` remains a projection of the artifact's asserted proposition. No
authoritative participant table exists. No artifact contradiction is manufactured; existing
contradictions remain preserved.

## Validation and integrity

Phase 15 adds a focused semantics validator, coverage report, and transaction-scoped corruption
tests. They reject a duplicate canonical artifact, direct artifact claim without evidence,
fabricated text/hash/quotation, fabricated dimension, direct chronology assertion, derived claim
without inputs, wrong mapping, direct participant store, and JSON semantic payload. Registered
predicates, complete direct provenance, source identity separation, and projection-only
participation are verified.

Final validation is recorded after the final fresh-database run. Application tests, Phase 6–14,
schema/blocking tests, Genesis suites, and STEP Bible checks remain in the authoritative runner.

## Architecture assessment and exclusions

The existing `Entity → SourceIdentity → EntitySourceMapping → Proposition → Claim → Evidence`
architecture faithfully represents the actual acquired artifact requirement: a persistent object
with source-specific identity, reconciliation, claims, provenance, event participation, and
separate canonical identity. It does not yet demonstrate rich construction/dimension/material/
component/content requirements because those source records are unavailable, not because an
artifact-specific architecture is needed.

No schema, predicate, artifact/object table, Entity attribute, relationship truth table, graph
infrastructure, inference engine, UI structure, or source fixture was changed. Future UI may
navigate the existing Entity, claim rendering, evidence, and projected participation paths only.
The smallest justified future extension, if acquired sources demonstrate an unrepresentable
semantic requirement, is a source-backed predicate proposal with a reproducible validation case;
none is justified now.
