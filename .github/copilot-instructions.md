# Project Berean Copilot Instructions

## Project identity

Berean is a provenance-aware knowledge architecture and pre-beta PostgreSQL reference data model.

## Core semantic rules

Never assume:

- a Source is Evidence;
- Evidence is a Claim;
- a Claim is Truth;
- a Relationship is Truth;
- a Source Identity is a Canonical Entity;
- Derived Knowledge is a Direct Source Observation.

## Authoritative model rules

- Claim ↔ Evidence is an explicit typed many-to-many relationship.
- Source-backed claims trace through Evidence → SourceRecord → Dataset → Source.
- A Proposition is the authoritative structured semantic content of a Claim.
- `claim.statement` is optional human-readable display text; it must not become a second semantic authority.
- Relationships are registered Proposition predicates and graph projections, not a duplicate relationship truth table.
- `event_participation` is a view projected from claim-asserted propositions. Do not create a second authoritative event-participant store.
- Derived Claims require Derivation metadata and explicit Claim/Evidence inputs.
- Source-specific identities must remain distinct from Canonical Entities; reconciliation must preserve justification, status, confidence, and provenance.
- Source observations require citations/source locators.

## Scope

Focus on:

- knowledge representation
- provenance
- claims
- evidence
- entities
- events
- relationships
- source reconciliation
- citations
- validation

Do not introduce sovereign geography, residency, security classifications, sovereign access-control concepts, graph databases, microservices, ontology engines, or inference systems unless the established Berean architecture explicitly requires them.

## Data integrity

Prefer explicit foreign keys, controlled vocabularies, typed values, and executable validation over implicit conventions. Preserve competing claims and never overwrite disagreement to manufacture a single truth.

## Changes

Before changing the model, inspect the charter, architecture documentation, information schema, and ADRs. Favor incremental corrections over speculative abstraction. Update documentation whenever the physical schema or authoritative representation changes.
