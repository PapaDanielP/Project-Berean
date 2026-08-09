# Berean Information Schema

## Core objects

| Object | Purpose |
|---|---|
| Source | Identifies an information source |
| Dataset | Structured representation/import container |
| SourceRecord | Exact source-derived record/location |
| Evidence | Source-grounded observation |
| Claim | Assertion being evaluated |
| ClaimEvidence | Many-to-many association between Claim and Evidence |
| Proposition | Structured semantic content of a Claim |
| Entity | Canonical knowledge object |
| SourceIdentity | Source-specific representation of an entity |
| EntitySourceMapping | Reconciliation between SourceIdentity and Entity |
| Event | Modeled occurrence/process |
| Relationship | Semantic relationship |
| Citation | Precise source locator |

## Required provenance

A source-backed evidence record should be traceable:

```text
Evidence → SourceRecord → Dataset → Source
```

## Required claim support

A source-backed claim should be traceable:

```text
Claim → ClaimEvidence → Evidence → SourceRecord → Dataset → Source
```

## Competing claims

Competing propositions are represented as distinct Claims. They must not overwrite one another.

## Recommended claim/evidence relation types

- `SUPPORTS`
- `CONTRADICTS`
- `QUALIFIES`
- `DERIVED_FROM`

The vocabulary should remain controlled and small until actual data demonstrates the need for expansion.
