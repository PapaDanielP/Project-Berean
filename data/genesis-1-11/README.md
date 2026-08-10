# Genesis 1–11 Test Dataset

This directory is a regression/stress-test area for the Berean model.

It should distinguish:

- canonical entities
- source identities
- source records
- evidence
- claims
- propositions
- events
- relationships
- derived assertions

The dataset should not be treated as an authoritative transcription of Scripture merely because it exists in the repository.

## Recommended ingestion order

1. source
2. dataset
3. source records
4. canonical entities
5. source identities
6. reconciliation mappings
7. evidence
8. propositions
9. claims
10. claim/evidence associations
11. validation

## Important

Do not manufacture historical or textual claims to fill gaps.

Every source-backed record should retain its source location and provenance.

## Genesis 1:1–9 validation slices

The executable fixture includes conservative Genesis 1:1–5 and Genesis 1:6–9 validation slices. They use nine structural Masoretic source-record boundaries, citation locators, evidence observations, direct source claims, and existing proposition predicates to validate the provenance graph without storing source text or resolving ambiguous details.

See `docs/04-data/GENESIS_1_1-5_SLICE.md` for the scope, limitations, intentionally deferred items, and validation command.
See `docs/04-data/PHASE7_REPORT.md` for the Phase 7 source-availability assessment and chapter coverage matrix.
See `docs/04-data/PHASE8_REPORT.md` for the Phase 8 Genesis 1:10–13 extension, validation results, and remaining deferrals.
See `docs/04-data/PHASE9_REPORT.md` for the Phase 9 Genesis 1:14–19 extension, validation results, and remaining deferrals.
See `docs/04-data/PHASE10_REPORT.md` for the Phase 10 Genesis 1:20–31 extension, validation results, and semantic exclusions.
