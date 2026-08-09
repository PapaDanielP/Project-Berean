# Berean Information Schema

## Core objects

| Object | Purpose |
|---|---|
| Source | Originating work or information source |
| Dataset | Imported edition, version, or structured import container for a Source |
| SourceRecord | Append-only imported record revision with hash and supersession metadata |
| Citation | Precise locator for a SourceRecord; reusable by multiple Evidence records |
| Evidence | Source-grounded observation |
| Claim | Assertion being evaluated |
| ClaimEvidence | Typed many-to-many association between Claim and Evidence |
| ClaimRelation | Typed relation between Claims, separate from evidence relations |
| Proposition | Structured semantic content of a Claim |
| Entity | Canonical knowledge object |
| SourceIdentity | Source-specific representation of an entity |
| EntitySourceMapping | Reconciliation between SourceIdentity and Entity |
| Event | Modeled occurrence/process |
| EventParticipation | Entity role in an Event, asserted by a Claim |
| Derivation / DerivationInput | Method, assumptions, and claim/evidence inputs for a derived Claim |
| TypedValue | Typed text, numeric/year, date, or duration value with numeric uncertainty bounds |

All entries above are physical tables except **Relationship**: relationship is a proposition predicate and a relational/graph projection, not a table. The lookup tables for types, statuses, roles, and relation types are also physical tables.

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

## Controlled relation types

- `SUPPORTS`
- `CONTRADICTS`
- `QUALIFIES`

Claim-to-claim relation types are `CONTRADICTS`, `QUALIFIES`, `REFINES`, `DUPLICATES`, and `SUPERSEDES`. Derived claims use `Derivation` and `DerivationInput`, not a claim/evidence relation type.

Every proposition has exactly one entity or event subject and exactly one entity, event, or typed-value object. Free-text predicates are intentionally retained at this baseline; values cannot silently become text because `TypedValue` requires a declared type and type-appropriate payload.
