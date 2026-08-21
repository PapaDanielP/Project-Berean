# Project Berean Documentation Index

This index defines documentation authority and placement for the current repository.

## Authority hierarchy and conflict resolution

When repository materials disagree, resolve conflicts in this order:

1. **Implementation, schema, code, and executable tests** — `src/`, `schema/sql/`, `tests/`, and `scripts/validation/` define current behavior.
2. **Authoritative current documentation** — architecture, schema, domain, API, security, workflow, and repository-structure documents listed below explain the current system.
3. **Reference documentation** — developer guides, capability matrices, OpenAPI gap status, verification notes, and adapter notes support current work but do not override authoritative docs or code.
4. **Phase records** — historical implementation and validation reports record what was done and concluded at a point in time.
5. **Validation records** — validation methodology and executable validation evidence support current and historical claims about integrity.
6. **Historical/archive/review material** — review prompts, remediation notes, proposals, and older reports provide context only.

If a phase or validation record conflicts with current implementation or authoritative documentation, preserve the record as historical evidence and update/link the authoritative documentation instead of rewriting the historical conclusion into a current specification.

## Documentation authority map

### AUTHORITATIVE
- [`00-project/CHARTER.md`](./00-project/CHARTER.md) — mission and invariants.
- [`01-architecture/ARCHITECTURE.md`](./01-architecture/ARCHITECTURE.md) — conceptual architecture boundaries.
- [`01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](./01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md) — management/workflow boundary vs authoritative knowledge.
- [`01-architecture/REPOSITORY_STRUCTURE.md`](./01-architecture/REPOSITORY_STRUCTURE.md) — where to place code, schema, tests, fixtures, docs, and history.
- [`02-domain/DOMAIN_MODEL.md`](./02-domain/DOMAIN_MODEL.md) — domain semantics.
- [`03-schema/INFORMATION_SCHEMA.md`](./03-schema/INFORMATION_SCHEMA.md) — physical schema and projections.
- [`api/API_DEVELOPER_GUIDE.md`](./api/API_DEVELOPER_GUIDE.md) — complete implemented endpoint surface.
- [`api/API_EPISTEMIC_BOUNDARIES.md`](./api/API_EPISTEMIC_BOUNDARIES.md) — enforced epistemic boundaries.
- [`api/API_WORKFLOWS.md`](./api/API_WORKFLOWS.md) — supported route compositions.
- [`api/API_SECURITY_MODEL.md`](./api/API_SECURITY_MODEL.md) — authentication, authorization, transaction and audit controls.
- [`api/API_LIMITATIONS.md`](./api/API_LIMITATIONS.md) — explicit non-capabilities and maturity limits.

### REFERENCE
- [`00-project/DEVELOPER_GUIDE.md`](./00-project/DEVELOPER_GUIDE.md) — environment setup and development commands.
- [`00-project/PROJECT_OVERVIEW.md`](./00-project/PROJECT_OVERVIEW.md) — concise project framing.
- [`api/API_CAPABILITY_MATRIX.md`](./api/API_CAPABILITY_MATRIX.md) — route-by-route capability matrix.
- [`api/API_EXPLORER_INTEGRATION_MATRIX.md`](./api/API_EXPLORER_INTEGRATION_MATRIX.md) — canonical Explorer/API integration matrix (capability, request, response, epistemic interpretation, auth, tests).
- [`api/OPENAPI_GAP_REPORT.md`](./api/OPENAPI_GAP_REPORT.md) — OpenAPI/documentation/test coverage gap status.
- [`api/VERIFICATION_REPORT.md`](./api/VERIFICATION_REPORT.md) — verification evidence and command logs.
- [`01-architecture/EXPLORER_READ_ONLY_ADAPTER.md`](./01-architecture/EXPLORER_READ_ONLY_ADAPTER.md) — Explorer-specific read-only behavior.

### VALIDATION RECORD
- [`05-validation/VALIDATION.md`](./05-validation/VALIDATION.md)
- SQL/bash validations under `tests/validation/` and `scripts/validation/`.

### DESIGN PROPOSAL / DECISION RECORD
- [`06-decisions/ADR-0001-claim-evidence.md`](./06-decisions/ADR-0001-claim-evidence.md)
- [`06-decisions/ADR-0002-epistemic-separation.md`](./06-decisions/ADR-0002-epistemic-separation.md)
- [`06-decisions/ADR-0003-reference-schema-boundaries.md`](./06-decisions/ADR-0003-reference-schema-boundaries.md)
- [`06-decisions/ADR-0004-durable-system-worker.md`](./06-decisions/ADR-0004-durable-system-worker.md)
- [`06-decisions/ADR-0005-local-export-artifacts.md`](./06-decisions/ADR-0005-local-export-artifacts.md)

### PHASE RECORD (historical, non-authoritative for current architecture)
- [`phases/README.md`](./phases/README.md) — canonical phase-history index (Phase 6–37R/37B).
- Legacy Phase 6–32 implementation history in [`04-data/`](./04-data/) (see [`04-data/README.md`](./04-data/README.md) for its index).
- Later independent phase studies (Phase 33–37R/37B) in [`phases/`](./phases/).

### REVIEW / AUDIT
- [`07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](./07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md) — repository-wide platform, API, administration, provenance, Explorer, and coverage audit (includes browser-tested Explorer workflow results).
- [`07-review/EXPLORER_API_INTEGRATION_AUDIT.md`](./07-review/EXPLORER_API_INTEGRATION_AUDIT.md) — Explorer/API integration audit: architecture, request/response contract, auth/authz, epistemic-safety review, defects fixed, and remaining findings.
- [`07-review/EXPLORER_TEST_REPORT.md`](./07-review/EXPLORER_TEST_REPORT.md) — exact database/startup/test/browser commands and results for the Explorer/API integration audit.
- [`07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md`](./07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md) — current documentation governance, authority, link-integrity, and API-coverage audit.
- [`07-review/REPOSITORY_CONSOLIDATION_REPORT.md`](./07-review/REPOSITORY_CONSOLIDATION_REPORT.md) — repository-wide documentation and structural integrity audit (predecessor pass).
- [`07-review/REMEDIATION-REPORT.md`](./07-review/REMEDIATION-REPORT.md) — architecture alignment and remediation record.
- [`07-review/WEB_APP_MVP_REPORT.md`](./07-review/WEB_APP_MVP_REPORT.md) — MVP review record.
- [`07-review/COPILOT_PEER_REVIEW_PROMPT.md`](./07-review/COPILOT_PEER_REVIEW_PROMPT.md) — historical peer-review prompt used to commission an independent review; not a specification.

### HISTORICAL PLAN
- [`00-project/WEB_APP_MVP_PLAN.md`](./00-project/WEB_APP_MVP_PLAN.md) — original read-only web MVP assessment and plan. Historical; superseded for current behavior by [`api/API_DEVELOPER_GUIDE.md`](./api/API_DEVELOPER_GUIDE.md) and [`01-architecture/ARCHITECTURE.md`](./01-architecture/ARCHITECTURE.md).

### GENERATED / TEST ARTIFACTS
- SQL fixtures: `tests/fixtures/`
- Validation SQL and shell checks: `tests/validation/`
- Candidate review CSVs: `data/candidates/`
- External source metadata index: [`../data/external/README.md`](../data/external/README.md)

## API documentation set (canonical location: `docs/api/`)

The canonical API docs are:
- `API_CAPABILITY_MATRIX.md`
- `API_DEVELOPER_GUIDE.md`
- `API_EPISTEMIC_BOUNDARIES.md`
- `API_LIMITATIONS.md`
- `API_SECURITY_MODEL.md`
- `API_WORKFLOWS.md`
- `OPENAPI_GAP_REPORT.md`
- `VERIFICATION_REPORT.md`

Do not create duplicate API guides in other folders; link back to `docs/api/`.

## Repository sections
- `src/` implementation (Explorer, API v1 routes, administration routes, ingestion pipeline)
- `schema/sql/` authoritative SQL schema and validation queries
- `tests/app/` HTTP behavior and OpenAPI coverage tests
- `tests/fixtures/` deterministic population fixtures
- `tests/validation/` SQL validation suites
- `scripts/validation/` validation runners
- `data/` candidate and ingestion input data, plus external-source metadata
- `.github/workflows/` CI validation workflow definitions

## Supported workflows (implemented)
- Read: search → detail → graph/timeline → provenance
- Research: scope → research → inspect detail → provenance/source
- Discovery: request → job queue row → candidates → review
- Ingestion ops: reviewed source + manifest-driven ingestion job queueing and SQL/script validation
- Identity: source identity → proposed mapping → review → active/rejected
- Derivation: derivation metadata + explicit inputs → eligibility check → optional derived claim creation
- Operations: queue job → status list → retry/cancel → audit review

For unsupported capabilities and intentional limits, see [`api/API_LIMITATIONS.md`](./api/API_LIMITATIONS.md).
