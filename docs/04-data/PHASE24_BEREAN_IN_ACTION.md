# Phase 24 — Berean in Action (Ark / Genesis-to-Israel demonstration)

## Status

- **Phase 24 scope:** implemented as a bounded, reproducible, source-backed knowledge-construction slice.
- **Baseline check before changes:** accepted Phase 19–23 artifacts are present on `main` (`PHASE19_REPORT`, `PHASE21_EXPLAIN_PROVENANCE`, `PHASE23_CHECK_DERIVATION_ELIGIBILITY`, existing schema, existing Genesis/Ark fixtures, existing read-only API routes).
- **Schema change:** none.
- **Registry change:** none.
- **Persistence/evaluator expansion:** none.
- **Automatic semantic inference:** none.

## What was built

Phase 24 adds a coherent Ark-content comparison slice that extends existing Ark/Genesis data with two additional bounded source records:

- `1 Kings 8:9` (`1KI_MT_REF` / `MT_1KI_8_9`)
- `Hebrews 9:4` (`HEB_GNT_REF` / `GNT_HEB_9_4`)

Using existing architecture only, it adds:

- source + dataset + source record + citation rows for those locators,
- evidence rows and citation links,
- two new canonical entities for source-backed Ark-content terms:
  - `golden_jar_manna`
  - `aarons_rod_budded`
- four direct source claims:
  - `CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS`
  - `CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS`
  - `CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA`
  - `CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD`
- source-identity reconciliation rows with evidence-backed `entity_source_mapping`.

No new tables, columns, predicates, event types, roles, claim-relation types, or ontology machinery were added.

## Why this demonstrates Berean

This slice demonstrates that Berean can preserve source-backed assertions and source differences in one substrate:

- existing Exodus material already attests Ark/tablets,
- 1 Kings 8:9 attests Ark/tablets at a later locator,
- Hebrews 9:4 attests Ark/tablets plus additional content items.

Berean stores these as claims with provenance and does **not** auto-resolve them into a single final truth, contradiction, compliance status, causation chain, or theological inference.

## Demonstration queries (SQL)

Run via PostgreSQL validation scripts:

- `tests/validation/phase24-berean-in-action-slice.sql` (assertions/regression checks)
- `tests/validation/phase24-coverage-report.sql` (exploration-oriented output)

Representative questions covered:

1. **Why does Berean contain this claim?**  
   Claim → ClaimEvidence → Evidence → Citation → SourceRecord → Dataset → Source chain output for each new Phase 24 claim.
2. **What do different sources say about Ark contents?**  
   Multi-source aggregation by `containsContent` object entity.
3. **What events are associated with Ark handling?**  
   Existing event participation projection for Phase 17–19 Ark events.
4. **What derivation/dependency structure exists?**  
   Existing `CLAIM_MT_ENOSH_YEAR_DERIVED` derivation + inputs (structural baseline from accepted phases).

## API demonstrations

Use existing routes; Phase 24 adds no API surface:

### `GET /api/provenance/explain`

```bash
# Example: explain one new Phase 24 claim
CLAIM_ID=$(psql "$DATABASE_URL" -Atc "SELECT claim_id FROM claim WHERE claim_key='CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA'")
curl "http://localhost:3000/api/provenance/explain?claim_id=${CLAIM_ID}"
```

Expected shape:

- `operation = EXPLAIN_PROVENANCE`
- `read_only = true`
- complete source chain through `HEB_GNT` / `HEB_GNT_REF` / `GNT_HEB_9_4`
- `raw_content_status = NOT_STORED_BY_POLICY`
- `quoted_text_status = NOT_STORED_BY_POLICY`

### `GET /api/derivations/check-eligibility`

```bash
# Example: existing genuine derived claim baseline (accepted prior phases)
DERIVATION_ID=$(psql "$DATABASE_URL" -Atc "SELECT derivation_id FROM claim WHERE claim_key='CLAIM_MT_ENOSH_YEAR_DERIVED'")
curl "http://localhost:3000/api/derivations/check-eligibility?derivation_id=${DERIVATION_ID}"
```

Expected shape:

- `operation = CHECK_DERIVATION_ELIGIBILITY`
- `read_only = true`
- stable structural checks
- no mutation/persistence side effects

## Coverage summary (what this phase contributes)

This phase adds:

- sources: +2
- datasets: +2
- source records: +2
- citations: +2
- evidence: +2
- propositions: +2 new (`containsContent` for manna jar and Aaron's rod)
- claims: +4 direct source claims
- entities: +2 objects
- source identities + mappings: +4 evidence-backed mappings
- derivations: +0 new (existing genuine derivations reused for demonstration)
- derivation inputs: +0 new

## Complete provenance examples (Phase 24 claims)

- `CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS`  
  → `EV_MT_1KI_8_9`  
  → `CITE_MT_1KI_8_9`  
  → `MT_1KI_8_9`  
  → `1KI_MT_REF`  
  → `1KI_MT`

- `CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA`  
  → `EV_GNT_HEB_9_4`  
  → `CITE_GNT_HEB_9_4`  
  → `GNT_HEB_9_4`  
  → `HEB_GNT_REF`  
  → `HEB_GNT`

- `CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD`  
  → same source chain as above (`HEB_GNT` path)

## Source-difference examples preserved (without forced resolution)

- `tablets_of_testimony` is asserted from multiple sources (`EXO_MT`, `1KI_MT`, `HEB_GNT`).
- `golden_jar_manna` and `aarons_rod_budded` are asserted from `HEB_GNT` in this slice.
- No automatic contradiction/supersession relation is created between these Phase 24 claims.
- Difference is preserved as source-backed coexistence, not auto-judged contradiction.

## Deliberately unmade conclusions

Phase 24 intentionally does **not** infer or persist:

- truth/falsity adjudication,
- contradiction detection,
- compliance/violation judgments,
- causation/punishment/theological interpretation,
- semantic entailment or factual-core promotion,
- new derived claims created only to exercise features.

## Problem classification (Phase 24 discovery rule)

- **Data entry / fixture problem:** solved by adding bounded source-backed Phase 24 fixture rows.
- **Query/API problem:** not found; existing API and query surfaces were sufficient.
- **Validation problem:** addressed with focused phase validation scripts.
- **Documentation problem:** addressed with this report and executable coverage report.
- **Actual schema insufficiency:** **not found** for this scope.

## Model sufficiency conclusion

For this Ark/Genesis-to-Israel demonstration slice, the existing model remains sufficient and should remain unchanged.

## Highest-value next question (based on actual use)

Within the current architecture, the next highest-value step is a larger but still bounded multi-source Ark timeline slice that increases source breadth while preserving the same deterministic provenance and non-inference boundaries.
