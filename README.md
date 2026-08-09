# Project Berean

Project Berean is a provenance-aware knowledge system designed to represent, reconcile, evaluate, and navigate information from multiple sources.

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

Current baseline: v0.6.1 conceptual/data-model remediation

The repository is intentionally structured so that the data model can be reviewed and validated before substantial expansion.

## Guiding rule

Do not treat a represented claim as automatically true.

Source statements, evidence, claims, interpretations, and derived propositions must retain their provenance and epistemic distinctions.
