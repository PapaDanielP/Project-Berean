# Berean Architecture

## Conceptual layers

```text
┌────────────────────────────────────────────┐
│ Knowledge Objects                          │
│ Entity • Event • Relationship • Value      │
└──────────────────────┬─────────────────────┘
                       │ asserted by
                       ▼
┌────────────────────────────────────────────┐
│ Claims                                     │
│ propositions / interpretations / derivation│
└──────────────────────┬─────────────────────┘
                       │ supported/challenged by
                       ▼
┌────────────────────────────────────────────┐
│ Evidence                                   │
│ source-grounded observations               │
└──────────────────────┬─────────────────────┘
                       │ originates from
                       ▼
┌────────────────────────────────────────────┐
│ Source Records                             │
│ exact imported/source observations         │
└──────────────────────┬─────────────────────┘
                       ▼
┌────────────────────────────────────────────┐
│ Source / Dataset                           │
└────────────────────────────────────────────┘
```

## Core distinctions

- **Source** = origin
- **SourceRecord** = identifiable record/observation in a source dataset
- **Evidence** = source-grounded observation used in evaluating a claim
- **Claim** = proposition being asserted/evaluated
- **Proposition** = structured semantic content of a claim
- **Entity** = canonical thing/person/place/concept
- **Event** = occurrence/process
- **Relationship** = a semantic proposition predicate (a projection, not a table)

## Claim/Evidence

Claim ↔ Evidence is many-to-many.

The association must be explicit because:

- one claim can have many evidence records;
- one evidence record can support many claims;
- evidence can support, contradict, qualify, or otherwise relate to claims.

## Provenance

The preferred provenance chain is:

```text
Claim
  ↓
ClaimEvidence
  ↓
Evidence
  ↓
SourceRecord
  ↓
Dataset
  ↓
Source
```

Citation/source-location information belongs with the source-grounded layer: `Citation` belongs to `SourceRecord` and is linked to `Evidence`. This supports multiple locators for an evidence record.

## Reconciliation

Source-specific identities map to canonical entities through an explicit reconciliation layer:

```text
Source Identity A ─┐
Source Identity B ─┼→ Canonical Entity
Source Identity C ─┘
```

The mapping must preserve uncertainty/dispute where necessary.

## Graph readiness

The relational model should be able to project naturally into a graph:

```text
Entity → Relationship → Entity
Entity → participatesIn → Event
Claim → asserts → Proposition
Claim → supportedBy → Evidence
Evidence → derivedFrom → SourceRecord
SourceRecord → belongsTo → Source
```

A graph database is not required merely because the domain is graph-shaped.

## Physical baseline

The reference SQL physically implements the objects in the provenance chain, citation, typed values, event participation, claim relations, derivation, and their controlled vocabularies. It does not implement an application, API, ingestion pipeline, separate relationship table, generalized inference engine, or graph store.
