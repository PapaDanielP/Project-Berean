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
See `docs/04-data/PHASE11_REPORT.md` for the Phase 11 object/artifact entity slice (`noahs_ark`, sourced from the existing Genesis 8:4 record, and the validation-only `ark_of_covenant`), which demonstrates that tangible objects are represented with the existing Entity model rather than a new Thing/Artifact table.
See `docs/04-data/PHASE12_REPORT.md` for the Genesis 1:22–23 boundary: both locators remain structurally represented and source-backed, while blessing/multiplication and ordinal-day semantics remain intentionally excluded because the existing predicate/event model cannot express them without false precision. Genesis 1:24–27 remains populated; Genesis 1:28–31 and chapters 2–4, 6–7, and 9–11 remain deferred as documented.
See `docs/04-data/PHASE13_REPORT.md` for the Phase 13 persistent entity and relationship population at Genesis 5:9. It adds the Masoretic and Septuagint Genesis 5:9 structural records, the persistent `kenan` PERSON entity, four evidence-backed source identities and reconciliations, the shared `enosh fatherOf kenan` proposition with its tradition-neutral and source-specific claims, the projected `kenan_begetting` participation, and the competing 90/190 numerals. The already-existing `enosh` entity is reused across Genesis 5:6 and 5:9 rather than duplicated. No derivation, event ordering, chronology, or lineage inference is added, and Genesis 5:10 onward remains deferred.
See `docs/04-data/PHASE14_REPORT.md` for the Phase 14 persistent object/artifact validation. It validates the existing source-backed Noah's Ark slice at Genesis 8:4 (`MT_GEN_8_4`) without adding source records, object-specific tables, artifact predicates, or fabricated source text. The `noahs_ark` OBJECT entity remains the exactly one source-backed canonical artifact entity in the selected slice, `mt-ark` remains a distinct evidence-backed source identity mapping, event participation remains projected from claim-asserted propositions, and Genesis 6-7 artifact construction/dimension/material/occupant content remains source-unavailable and acquisition-pending.
