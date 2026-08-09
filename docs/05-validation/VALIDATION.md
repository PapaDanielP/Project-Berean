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
