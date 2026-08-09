# Project Berean

Project Berean is a pre-beta, PostgreSQL-oriented reference data-model baseline for a provenance-aware knowledge system. It contains documentation, reference SQL, a small canonical CSV, and executable SQL fixtures; it does not provide an application, API, ingestion service, or production deployment.

The initial implementation uses biblical and historical material as a test domain. Genesis 1–11 is the first substantial validation dataset.

## Core principle

Berean deliberately distinguishes:

- Source
- Source Record / Dataset
- Evidence
- Claim
- Proposition
- Entity
- Event
- Relationship
- Source Entity Mapping
- Citation / Source Location

The fundamental epistemic chain is:

```text
Source
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

The repository is intentionally structured so that the data model can be reviewed and validated before substantial expansion. See the [developer guide](docs/00-project/DEVELOPER_GUIDE.md) for setup and validation.

## What is implemented

Physical PostgreSQL tables cover source, dataset (the imported edition/container), source record, citation, entity, source identity, reconciliation mapping, event, event participation, typed value, proposition, claim, evidence, claim/evidence relation, claim/claim relation, and derivation. Controlled vocabularies are lookup tables.

Relationships are represented by proposition predicates rather than a separate `relationship` table. Graph edges are a relational projection, not a graph database requirement. Canonical CSV loading and full ingestion workflows remain deferred.

## Guiding rule

Do not treat a represented claim as automatically true.

Source statements, evidence, claims, interpretations, and derived propositions must retain their provenance and epistemic distinctions.
