# Berean Information Schema

## Core objects

| Object | Purpose | Physical form |
|---|---|---|
| Source | Originating work or information source | Table |
| Dataset | Imported edition, version, or structured import container for a Source | Table |
| SourceRecord | Imported record reference with hash and supersession metadata | Table |
| Citation | Precise locator for a SourceRecord; reusable by multiple Evidence records | Table |
| Evidence | Source-grounded observation | Table |
| Claim | Assertion being evaluated | Table |
| ClaimEvidence | Typed many-to-many association between Claim and Evidence | Table |
| ClaimRelation | Typed relation between Claims, separate from evidence relations | Table |
| Proposition | Structured semantic content of a Claim | Table |
| Entity | Canonical knowledge object | Table |
| SourceIdentity | Source-specific representation of an entity | Table |
| EntitySourceMapping | Reconciliation between SourceIdentity and Entity | Table |
| Event | Modeled occurrence/process | Table |
| EventParticipation | Claim-asserted entity role in an Event | View/projection |
| Derivation / DerivationInput | Method, assumptions, and claim/evidence inputs for a derived Claim | Tables |
| TypedValue | Typed text, numeric/year, date, or duration value with uncertainty bounds | Table |
| Relationship | Semantic relation represented by a registered proposition predicate | Predicate/projection, not a table |
| ClaimRendering | Human-readable rendering of the authoritative proposition | View/projection |

## Authoritative representations

A Relationship is represented by a registered predicate on a Proposition. It is not stored in a second relationship table.

Event participation is projected by `event_participation` from claim-asserted propositions whose predicate carries an event-participation role. The proposition and its Claim are authoritative; the view is for traversal and graph projection.

`claim.statement` is an optional human-readable display label. The structured Proposition referenced by the Claim is authoritative. The `claim_rendering` view exposes a rendering derived from that Proposition so applications do not need to treat the label as semantic truth.

## Required provenance

A source-backed evidence record should be traceable:

```text
Evidence → SourceRecord → Dataset → Source
```

A source-backed claim should be traceable:

```text
Claim → ClaimEvidence → Evidence → SourceRecord → Dataset → Source
```

Source observations require citations during validation. Derived claims additionally require a Derivation with explicit inputs, method, and assumptions.

## Competing claims

Competing propositions are represented as distinct Claims. They must not overwrite one another. Claim-to-claim relations such as `CONTRADICTS`, `QUALIFIES`, `REFINES`, `DUPLICATES`, and `SUPERSEDES` are separate from Claim–Evidence relations.

## Controlled semantic mechanisms

Claim–Evidence relations include `SUPPORTS`, `CONTRADICTS`, and `QUALIFIES`. Proposition predicates are controlled by a deliberately small extensible registry that validates subject and object kinds. This is not a general ontology or inference engine.

Every Proposition has exactly one Entity or Event subject and exactly one Entity, Event, or TypedValue object.
