# Project Berean

Project Berean is a pre-beta, PostgreSQL-oriented reference data-model baseline for a provenance-aware knowledge system. It contains documentation, reference SQL, a small canonical CSV, and executable PostgreSQL fixtures and validation scripts; it is not yet an application or ingestion service.

The initial implementation uses biblical and historical material as a test domain. Genesis 1–11 is the first substantial validation dataset.

## Core principle

Berean deliberately distinguishes:

- Source
- Dataset
- Source Record
- Evidence
- Claim
- Proposition
- Entity
- Event
- Relationship
- Source Entity Mapping
- Citation / Source Location
- Derived Knowledge

The fundamental epistemic chain is:

```text
Source
  ↓
Dataset
  ↓
Source Record
  ↓
Evidence
  ↓
Claim
  ↓
Proposition
  ↓
Entity / Event / Relationship
```

## Status

Current baseline: pre-beta reference data model.

The repository is intentionally structured so that the data model can be reviewed and validated before substantial expansion. See the [developer guide](docs/00-project/DEVELOPER_GUIDE.md) for setup and validation and the [remediation report](docs/07-review/REMEDIATION-REPORT.md) for implemented decisions, deferred work, and limitations.

## What is implemented

The PostgreSQL reference schema includes controlled vocabularies, source/dataset/source-record provenance, citations, evidence, canonical entities, source identities, reconciliation mappings, events, typed values, propositions, claims, typed Claim–Evidence associations, claim-to-claim relations, and derivation inputs.

`event_participation` and `claim_rendering` are views. Event participation is projected from claim-asserted propositions; the proposition is the authoritative semantic representation. Relationships are represented by registered proposition predicates rather than a separate `relationship` table. Graph edges are relational projections, not a graph database requirement.

The Genesis canonical CSV is a non-executable catalog. The SQL fixtures are the executable structural and stress-test data; no copyrighted or fabricated source text is included.

## Guiding rule

Do not treat a represented claim as automatically true.

Source statements, evidence, claims, interpretations, and derived propositions must retain their provenance and epistemic distinctions.
