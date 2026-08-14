# Project Berean

Project Berean is a provenance-aware PostgreSQL knowledge architecture and pre-beta reference model.

## What Berean is

Berean preserves strict semantic separation:

- Source ≠ Evidence
- Evidence ≠ Claim
- Claim ≠ Truth
- Claim.statement ≠ authoritative proposition
- Source identity ≠ canonical entity
- Derived result ≠ stored fact

Authoritative chain: `Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence -> Claim -> Proposition`.

## Current implementation

This repository currently contains:

- a TypeScript/Express Explorer and API implementation in [`src/`](src/);
- the PostgreSQL reference schema in [`schema/sql/`](schema/sql/);
- application/API tests in [`tests/app/`](tests/app/);
- deterministic fixtures in [`tests/fixtures/`](tests/fixtures/);
- SQL and shell validation suites in [`tests/validation/`](tests/validation/) and [`scripts/validation/`](scripts/validation/);
- candidate and ingestion inputs in [`data/`](data/).

The implementation, schema, executable tests, and validation scripts are the behavioral authority. Documentation explains and indexes that behavior; historical phase reports do not supersede current architecture, schema, or API documentation.

## Start here

- Documentation index: [`docs/README.md`](docs/README.md)
- Charter: [`docs/00-project/CHARTER.md`](docs/00-project/CHARTER.md)
- Architecture: [`docs/01-architecture/ARCHITECTURE.md`](docs/01-architecture/ARCHITECTURE.md)
- Schema: [`docs/03-schema/INFORMATION_SCHEMA.md`](docs/03-schema/INFORMATION_SCHEMA.md)
- Workflow boundaries: [`docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md)

## API and operations

- API reference (implemented endpoints): [`docs/api/API_DEVELOPER_GUIDE.md`](docs/api/API_DEVELOPER_GUIDE.md)
- API workflows: [`docs/api/API_WORKFLOWS.md`](docs/api/API_WORKFLOWS.md)
- API limitations / non-capabilities: [`docs/api/API_LIMITATIONS.md`](docs/api/API_LIMITATIONS.md)
- API security model: [`docs/api/API_SECURITY_MODEL.md`](docs/api/API_SECURITY_MODEL.md)
- OpenAPI gap status: [`docs/api/OPENAPI_GAP_REPORT.md`](docs/api/OPENAPI_GAP_REPORT.md)

## Development and validation

- Developer setup and commands: [`docs/00-project/DEVELOPER_GUIDE.md`](docs/00-project/DEVELOPER_GUIDE.md)
- Validation reference: [`docs/05-validation/VALIDATION.md`](docs/05-validation/VALIDATION.md)
- CI workflow: [`.github/workflows/postgres-validation.yml`](.github/workflows/postgres-validation.yml)

Run from repository root:

```sh
npm install
npm run typecheck
npm run lint
npm run build
npm test
bash scripts/validation/run-postgres-validation.sh
```

## Data, ingestion, research, and history

- Ingestion manifests and guidance: [`data/ingestion/README.md`](data/ingestion/README.md)
- Candidate review inputs: [`data/candidates/README.md`](data/candidates/README.md)
- External source metadata: [`data/external/README.md`](data/external/README.md)
- Historical phase records: [`docs/04-data/`](docs/04-data/) and [`docs/phases/`](docs/phases/) (see [`docs/phases/README.md`](docs/phases/README.md) for the canonical index)
- Documentation governance audit: [`docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md`](docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md)
- Final platform architecture audit (API, administration, provenance, Explorer, coverage): [`docs/07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md`](docs/07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md)
- Prior consolidation record: [`docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md`](docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md)

## Current limitations

- Berean is pre-beta and does not adjudicate truth, prove propositions, infer contradictions, or treat absence as falsehood.
- Discovery, ingestion, validation, and export job APIs persist queue state; execution beyond queued workflow records requires scripts or a system worker as documented.
- Source acquisition, external research, fixture authoring, registry/schema changes, and historical phase interpretation remain reviewed developer or human workflows, not automatic API capabilities.
