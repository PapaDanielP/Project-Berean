# Project Berean

Project Berean is a provenance-first, PostgreSQL-oriented knowledge foundation for representing source-backed information without collapsing sources, evidence, claims, interpretations, and derived knowledge into one undifferentiated fact store.

The initial test domain is biblical and historical material. Genesis 1–11 and the bounded Ark-of-the-Covenant phases are regression and stress-test data for the model; the repository is not an authoritative transcription of Scripture or a replacement for primary source editions.

## Core principle

> Berean persists provenance-bearing assertions; evaluation explains what those assertions support and how they are connected. A represented claim is not automatically truth.

Berean deliberately keeps these concepts distinct:

```text
Source
  ↓
Dataset
  ↓
SourceRecord
  ↓
Citation
  ↓
Evidence
  ↓
ClaimEvidence
  ↓
Claim
  ↓
Proposition
  ↓
Entity / Event / TypedValue
```

Claims may be direct source claims, derived claims, interpretive claims, or competing claims. Source-specific identities and canonical entities are also preserved separately so reconciliation does not erase source context.

## What the repository contains

- PostgreSQL 16 reference schema and controlled registries.
- Source, dataset, source-record, citation, evidence, claim, proposition, entity, event, derivation, and claim-relation structures.
- Read-only projection views, including `claim_rendering` and `event_participation`.
- Executable SQL fixtures and validation suites for the populated phases.
- Genesis 1–11 regression/stress-test data and bounded Ark-of-the-Covenant source slices.
- Metadata-only declarations for selected external sources; upstream payloads are not automatically treated as Berean evidence.
- A small read-only TypeScript/Express web explorer over the PostgreSQL model.
- Phase documentation describing source availability, semantic boundaries, validation results, and deferred decisions.

## Current architectural status

The current repository establishes a provenance-bearing relational substrate and a read-only exploration layer. Phase 19 is the runtime-validated baseline for the bounded 2 Samuel 6:3–7 Ark lifecycle slice. Phase 20 specifies the future provenance evaluation boundary. Phase 21 documents the first deterministic provenance explanation operation and its architectural constraints.

Evaluation remains separate from persisted knowledge:

```text
Persistent Berean substrate
        ↓
Read-only queries and explanations
        ↓
Ephemeral structural results
```

The repository does not currently implement a generalized inference engine, truth oracle, contradiction engine, compliance or violation reasoning, causal reasoning, modal-logic persistence, or evaluation-result persistence.

## Architectural invariants

```text
SOURCE-BACKED
≠ TRUE

COMPLETE PROVENANCE
≠ TRUE

UNKNOWN
≠ FALSE

NOT_ESTABLISHED
≠ FALSE

DIFFERENCE
≠ CONTRADICTION

EVENT OCCURRENCE
≠ CAUSATION

STANDING REQUIREMENT
≠ COMPLIANCE OR VIOLATION

EVALUATION RESULT
≠ CLAIM
```

A missing record is not automatically evidence that the underlying fact is false. A NULL `raw_content` or `quoted_text` value indicates that source text is not stored under the repository's source and distribution policy; it does not establish source silence.

## Read-only web explorer

The web layer consumes the existing PostgreSQL model directly and does not create a duplicate authoritative store. It currently provides read-only search and views for entities, events, claims, propositions, evidence, sources, datasets, citations, locators, graph neighborhoods, Genesis coverage, quality information, and claim provenance.

There are no application write endpoints. The application is an explorer over persisted knowledge, not an ingestion or mutation service.

The versioned interface is available under `/api/v1`. It exposes bounded reads of
the existing source, dataset, record, citation, evidence, claim, proposition,
entity, event, identity, mapping, and registry structures, along with transient
research, graph, and provenance operations. `/openapi.json` and `/api-docs`
describe that interface. Corpus administration, discovery workflows, candidate
decisions, jobs, audit records, imports, exports, and knowledge mutations return
an explicit `NOT_REPRESENTED` response: the authoritative schema has no
corresponding workflow structures, and the API does not invent a second store.

## Validation

The authoritative model validation command is:

```sh
export DATABASE_URL='postgresql://localhost/berean_reference'
scripts/validation/run-postgres-validation.sh
```

Run it against a fresh PostgreSQL 16 database. The suite applies the reference schema, loads the bounded fixtures, runs generic integrity checks, executes phase-specific positive and negative validation, and reruns final integrity validation.

Application checks are:

```sh
npm run test
npm run typecheck
npm run lint
npm run build
```

The application tests require `DATABASE_URL` and use a disposable database.

## Local development

Prerequisites:

- PostgreSQL 16 server and client tools.
- Node.js and npm.

Install dependencies:

```sh
npm install
```

Start the read-only explorer:

```sh
export DATABASE_URL='postgresql://localhost/berean_reference'
export PORT=3000 # optional
npm run dev
```

Then open `http://localhost:3000`.

For the complete setup and contribution rules, see [`docs/00-project/DEVELOPER_GUIDE.md`](docs/00-project/DEVELOPER_GUIDE.md).

## Documentation map

- [Knowledge administration and research workflow architecture](docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md)
- [`docs/api/API_DEVELOPER_GUIDE.md`](docs/api/API_DEVELOPER_GUIDE.md) — complete implemented API surface, boundaries, workflows, and roadmap.
- [`docs/api/API_CAPABILITY_MATRIX.md`](docs/api/API_CAPABILITY_MATRIX.md) — route-by-route capability classification matrix.
- [`docs/api/API_WORKFLOWS.md`](docs/api/API_WORKFLOWS.md) — workflow and composition recipes across implemented administration lifecycle routes, including asynchronous and conflict semantics.
- [`docs/api/API_SECURITY_MODEL.md`](docs/api/API_SECURITY_MODEL.md) — authentication, roles, input handling, transactionality, and audit.
- [`docs/api/API_EPISTEMIC_BOUNDARIES.md`](docs/api/API_EPISTEMIC_BOUNDARIES.md) — epistemic distinctions and where each is enforced.
- [`docs/api/API_LIMITATIONS.md`](docs/api/API_LIMITATIONS.md) — exhaustive API limitations and non-capabilities.
- [`docs/api/OPENAPI_GAP_REPORT.md`](docs/api/OPENAPI_GAP_REPORT.md) — OpenAPI coverage status against the implemented API surface.
- [`docs/api/VERIFICATION_REPORT.md`](docs/api/VERIFICATION_REPORT.md) — commands run and manual verification evidence for this audit.
- [`docs/00-project/CHARTER.md`](docs/00-project/CHARTER.md) — mission and architectural principles.
- [`docs/00-project/PROJECT_OVERVIEW.md`](docs/00-project/PROJECT_OVERVIEW.md) — project purpose, capabilities, and non-goals.
- [`docs/00-project/DEVELOPER_GUIDE.md`](docs/00-project/DEVELOPER_GUIDE.md) — setup, validation, application checks, and contribution guidance.
- [`docs/01-architecture/ARCHITECTURE.md`](docs/01-architecture/ARCHITECTURE.md) — architectural boundaries.
- [`docs/02-domain/DOMAIN_MODEL.md`](docs/02-domain/DOMAIN_MODEL.md) — domain vocabulary.
- [`docs/03-schema/INFORMATION_SCHEMA.md`](docs/03-schema/INFORMATION_SCHEMA.md) — persistent objects and projections.
- [`docs/04-data/PHASE19_REPORT.md`](docs/04-data/PHASE19_REPORT.md) — runtime-validated Phase 19 baseline.
- [`docs/04-data/PHASE20_CAPABILITY_SPECIFICATION.md`](docs/04-data/PHASE20_CAPABILITY_SPECIFICATION.md) — provenance-engine capability contract.
- [`docs/04-data/PHASE21_EXPLAIN_PROVENANCE.md`](docs/04-data/PHASE21_EXPLAIN_PROVENANCE.md) — deterministic provenance explanation boundary.
- [`docs/04-data/PHASE22_CAPABILITY_ASSESSMENT.md`](docs/04-data/PHASE22_CAPABILITY_ASSESSMENT.md) — next-capability discovery and architectural assessment.

## Data and contribution rules

- Do not manufacture source text, quotations, hashes, historical facts, or semantic claims to fill gaps.
- Preserve source locations and provenance for source-backed assertions.
- Keep source identities distinct from canonical entities.
- Keep evidence, claims, propositions, interpretations, and derived assertions distinct.
- Preserve competing claims rather than overwriting them.
- Add controlled vocabulary only when a bounded source-backed requirement demonstrates that it is necessary.
- Do not add schema, ontology, inference, or persistence structures speculatively.
- Do not commit copyrighted source material without compatible rights and documented provenance.

## Non-goals

Project Berean is not currently:

- an automated truth oracle;
- a generalized inference engine;
- a replacement for primary source editions;
- a document-management system;
- a sovereign data-residency platform;
- an access-control or identity platform;
- a blockchain or decentralized knowledge graph;
- a modal-logic or cognitive-world persistence system.
