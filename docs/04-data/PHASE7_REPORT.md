# Phase 7 Genesis 1:6–9 Expansion Report

## Batch and architectural assessment

Phase 7 extends the existing `tests/fixtures/020-genesis-1-11-fixture.sql`; it does not introduce a competing Genesis fixture. The bounded batch adds Genesis 1:6–9 to the existing Genesis 1:1–5 structural Masoretic slice.

Architecture remains **SUPPORTED / RUNTIME VERIFIED**. No reproducible architectural deficiency was found. This batch uses existing source, dataset, citation, evidence, proposition, claim, event, and predicate capabilities; it does not add schema, predicates, event identities, relationship tables, or inference.

## Source availability assessment and coverage matrix

| Source | Dataset | Genesis coverage | Source text available | Citation available | Evidence possibility | Import status |
| --- | --- | --- | --- | --- | --- | --- |
| Genesis, Masoretic textual tradition | `GEN_MT_REF` | 1:1–9, 5:3, 5:6, 8:4 | No; structural locators only | Yes; locators only, no quoted text | Limited to conservative structural source observations under the existing fixture convention | POPULATED for represented locators; text intentionally excluded |
| Genesis, Septuagint textual tradition | `GEN_LXX_REF` | 5:3, 5:6 | No; structural locators only | Yes; locators only, no quoted text | Limited to existing genealogy observations | POPULATED for represented locators; text intentionally excluded |
| STEP Bible Data | None | None | Not acquired in Berean; external repository pinned and permission verified | No Berean citations | Possible only after acquisition, dataset/file verification, and provenance-preserving import | ACQUISITION PENDING |
| Theographic Bible Metadata | None | None | Not acquired in Berean; external repository pinned and permission verified | No Berean citations | Possible only after acquisition and provenance-preserving import | ACQUISITION PENDING |
| BibleData | None | None | Not acquired in Berean; external repository pinned, permission verified, and upstream license discrepancy preserved | No Berean citations | Possible only after acquisition, dataset/file term recording, and provenance-preserving import | ACQUISITION PENDING |

The external declarations in `data/external/*` contain no vendored source material, so they did not support new evidence, citations, or claims in this completed Phase 7 batch. Their manifests now distinguish maintainer-confirmed permission and attribution requirements from actual acquisition, inspection, hashing, and import. Future batches may use the pinned external repositories only after acquisition and provenance-preserving import work is performed.

## Chapter coverage

`tests/validation/phase7-coverage-report.sql` reports all Genesis 1–11 chapters after fixture loading. Its status terms mean:

- **POPULATED**: chapter has source records and supported claims.
- **STRUCTURALLY REPRESENTED**: chapter has source records but no supported claim.
- **SOURCE-BACKED**: a source observation is linked through a citation, source record, dataset, and source. Structural source-backed observations are not source-text imports.
- **DERIVED**: a claim has explicit derivation metadata and inputs.
- **UNRESOLVED**: no modeled semantic assertion is available for the chapter.
- **INTENTIONALLY EXCLUDED**: source text and quoted citation text remain absent.
- **ACQUISITION PENDING**: permission and source metadata may be recorded, but no local source payload or imported SourceRecord supports population yet.
- **SOURCE UNAVAILABLE**: no locally available source material or existing structural record supports population.

Chapter 1 is **POPULATED**, **STRUCTURALLY REPRESENTED**, **SOURCE-BACKED**, and has text **INTENTIONALLY EXCLUDED**. Chapters 5 and 8 are populated by the prior Phase 6 fixture. Chapters 2–4, 6–7, and 9–11 are **SOURCE UNAVAILABLE** and **UNRESOLVED** for this batch. The report retains locator-level counts for the represented verses.

## Population changes and statistics

Genesis 1:6–9 adds four Masoretic structural source records, citations, source observations, generic statement events, conservative direct claims, and the concept entities needed by those claims. Each direct claim has the complete `Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition` path. No SourceIdentity, EntitySourceMapping, Derivation, or DerivationInput is invented where the batch does not require one.

| Object | Before | After |
| --- | ---: | ---: |
| Source | 2 | 2 |
| Dataset | 2 | 2 |
| SourceRecord | 10 | 14 |
| Citation | 10 | 14 |
| Evidence | 11 | 15 |
| Proposition | 31 | 39 |
| Claim | 37 | 45 |
| ClaimEvidence | 41 | 49 |
| Entity | 13 | 17 |
| SourceIdentity | 4 | 4 |
| EntitySourceMapping | 4 | 4 |
| Event | 8 | 12 |
| Event participation | 21 | 29 |
| Derivation | 3 | 3 |
| DerivationInput | 6 | 6 |

## Semantic and source limitations

- The batch preserves only source-presented participant and subject roles. It does not encode creation, separation, naming, evaluation, time sequence, theology, or a relationship truth table.
- The events are existing generic `OTHER` statement placeholders. Event participation remains the `event_participation` projection from asserted propositions.
- No source-specific identity or canonical mapping is asserted for the new concepts.
- No source text, content hash, quoted text, translation comparison, harmonization, numerical inference, chronology, or event correspondence is added.
- Genesis 1:10–31 was deliberately deferred to retain a small validated batch. It is not represented as complete coverage.

## Validation and repository integrity

The authoritative command is:

```sh
DATABASE_URL=postgresql:///berean_phase6 scripts/validation/run-postgres-validation.sh
```

It runs blocking validation, the Genesis 1:1–5 and 1:6–9 checks, Phase 6 regression and coverage, Phase 7 coverage, and negative integrity cases. The command passed against a clean local PostgreSQL 16 database; the reports showed the expected Genesis 1:1–9 locator coverage and all 11 chapter rows.

Intentional changed files:

- `tests/fixtures/020-genesis-1-11-fixture.sql`
- `tests/validation/genesis-1-6-9-slice.sql`
- `tests/validation/phase7-coverage-report.sql`
- `scripts/validation/run-postgres-validation.sh`
- `data/genesis-1-11/README.md`
- `docs/04-data/PHASE7_REPORT.md`
