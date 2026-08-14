# Berean Validation

## Core invariants

### Claim/Evidence

Every source-backed claim must have at least one ClaimEvidence association.

### Evidence provenance

Every evidence record must have identifiable provenance to a SourceRecord or an explicitly documented exception.

### Source provenance

Every SourceRecord must resolve to a Dataset and Source.

### Entity reconciliation

Source identities must not be silently substituted for canonical entities.

### No implicit truth

A relationship or claim record must not be interpreted as universally true merely because it exists.

## Validation categories

- Structural integrity
- Referential integrity
- Provenance integrity
- Semantic integrity
- Reconciliation integrity
- Duplicate detection
- Conflict detection
- Regression testing

## Executable reference validation

With PostgreSQL 16 and an empty disposable database, set `DATABASE_URL` and run:

```sh
scripts/validation/run-postgres-validation.sh
```

The script loads the schema and deterministic fixture, executes negative constraint cases, and then runs `scripts/validation/validate.sql`. The validation emits **blocking** exceptions for unsupported non-derived claims, broken provenance, duplicate active mappings, invalid confidence, uncontrolled relations, missing required citations, invalid proposition cardinality, and incomplete derivations. It emits **warnings** for reviewable quality conditions and exits nonzero only for SQL/blocking failures.

The fixture demonstrates shared evidence, multiple evidence for a claim, contrary evidence, competing claims, source-identity reconciliation, asserted event participation, and a derived chronology claim. It is transactional and resets reference-model data; use an isolated test database.

`tests/validation/genesis-1-1-5-slice.sql` runs after the Genesis fixture and checks the conservative Genesis 1:1–5 slice specifically. It verifies five verse source-record boundaries, citation-compatible structural records with no stored source text, evidence-to-source provenance, claim-to-evidence provenance, multiple records attached to Genesis 1:1, and direct source claims only.

`tests/validation/phase28-ingestion-validation.sql` runs after the Phase 28 automated Tier-1 ingestion step and checks that every ingested claim is a direct source claim with a complete provenance chain, that deferred and excluded candidates stayed outside the graph, that locator-only source storage held, that ingested source-identity mappings are `ACTIVE`, justified, and evidence-backed, and that ingestion produced no duplicate assertion. The ingestion step itself requires the Node toolchain and is skipped when dependencies are absent.

## Related validation records

- Current governance verification: [`../07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md`](../07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md)
- API verification evidence: [`../api/VERIFICATION_REPORT.md`](../api/VERIFICATION_REPORT.md)
- Legacy Phase 6–32 validation history: [`../04-data/README.md`](../04-data/README.md)
- Later phase validation records: [`../phases/README.md`](../phases/README.md)

## Genesis regression

Genesis 1–11 should include tests for:

- parent/child relationships
- births and deaths
- events
- places
- chronology
- multiple evidence records
- derived assertions
- conflicting assertions
- source identity reconciliation
