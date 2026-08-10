# Phase 27 — Genesis 1–50 Source-Backed Corpus Expansion

Phase 27 expands Berean's accepted Genesis demonstration into a substantial, inspectable
Genesis 1–50 corpus. It is a data-only extension: no schema, foreign key, registry, controlled
vocabulary, provenance, Claim/Evidence, Event, Derivation, source-identity, or exploration semantic
changed.

The governing boundaries remain:

```text
SOURCE-BACKED IS NOT TRUE
ABSENCE IS NOT SOURCE SILENCE
PROPOSITION IS THE AUTHORITATIVE CLAIM CONTENT
```

## Source and ingestion boundary

The fixture reuses `GEN_MT` and `GEN_MT_REF`, including all Genesis 1–11 and Phase 26 records. It
creates only missing reference-point records and does not reproduce source text.

```text
tests/fixtures/120-phase27-genesis-1-50-fixture.sql
```

All 55 new `source_record.raw_content`, `source_record.content_hash`, and
`citation.quoted_text` values are `NULL`, reported as `NOT_STORED_BY_POLICY`. This is storage
policy, never evidence of source silence.

Selected locators cover explicit assertions in Genesis chapters 2, 4, 6, 11–16, 18–26, 28–30,
32–33, 35, 37, and 39–50. Existing records provide chapters 1, 5, 7, and 8. Chapter 32 currently
has an evidence-only locator. Chapters 3, 9, 10, 17, 27, 31, 34, 36, and 38 have no locator in the
reference corpus and are `NOT_YET_MODELED`, not source silence.

The expansion includes the named people and locations requested by the phase, including Adam,
Eve, Cain, Abel, Seth, Noah, Shem, Ham, Japheth, Abraham, Sarah, Lot, Isaac, Rebekah, Jacob, Esau,
Leah, Rachel, Joseph, Judah, Benjamin, Eden, Nod, Ararat, Babel, Shinar, Ur, Haran, Canaan, Bethel,
Hebron, Beersheba, Gerar, Egypt, Shechem, and Dothan. Existing Adam, Seth, Noah, and Ararat records
are reused rather than duplicated.

## Representation policy

The fixture uses only the existing 22 predicates, 8 event types, 5 entity types, and 5 projected
participation roles.

- Explicit parentage uses `fatherOf` / `motherOf`.
- Birth and genealogical roles use `parentIn` / `childIn`.
- Explicit event subjects and participants use `subjectOf` / `participatesIn`.
- Named event locations use `occursAt`; it does not encode route direction or modern geography.
- Explicit ages at death use `ageAtDeathYears` with `YEAR` typed values.
- Event participation remains the `event_participation` view projected from claim-asserted
  propositions. No second participant store is created.
- Every new entity has a justified, evidence-backed `ACTIVE` `GEN_MT` source-identity mapping.
- No Phase 27 derivation is added. The three accepted deterministic derivations and six inputs are
  preserved unchanged.

The fixture uses transaction-local temporary tables only to assemble repeated fixture rows. They
are dropped at commit and add no persistent schema or ingestion architecture.

## Measured coverage

The same report runs before and after ingestion:

```text
tests/validation/phase27-genesis-coverage-report.sql
```

| Metric | Before (accepted Phase 26) | After | Delta |
| --- | ---: | ---: | ---: |
| Sources | 10 | 10 | 0 |
| Datasets | 10 | 10 | 0 |
| Source records | 75 | 130 | +55 |
| Citations | 75 | 130 | +55 |
| Evidence | 77 | 132 | +55 |
| Entities | 60 | 108 | +48 |
| Propositions | 170 | 296 | +126 |
| Claims | 183 | 309 | +126 |
| Events | 52 | 100 | +48 |
| Projected participations | 122 | 193 | +71 |
| Derivations | 3 | 3 | 0 |
| Derivation inputs | 6 | 6 | 0 |

Entity deltas are 31 `PERSON`, 16 `PLACE`, and 1 `ORGANIZATION`; `CONCEPT` and `OBJECT` are
unchanged. The post-ingestion inventory contains 48 people, 21 places, 3 organizations, 12
objects, and 24 concepts.

### How much Genesis is represented?

- 102 `GEN_MT_REF` reference points, plus three accepted `GEN_LXX_REF` comparison records.
- At least one locator in 41 of 50 Genesis chapters.
- Source-backed structured claims in 40 chapters.
- 238 direct claims backed specifically by `GEN_MT_REF` through `SUPPORTS`.
- 126 new direct claims, 126 new propositions, and 48 new events in Phase 27.

This is substantial representative coverage, not verse-complete transcription. The report emits
every represented chapter and locator count so the boundary is inspectable.

### How much is source-backed?

After ingestion, all 306 non-derived claims in the database resolve through:

```text
Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation
      → SourceRecord → Dataset → Source
```

Completeness is **306 / 306**, with **0 incomplete** direct-claim provenance chains. All 126 Phase
27 claims are `DIRECT_SOURCE_CLAIM`; none is interpretive or derived. The three pre-existing
`DERIVED_CLAIM` rows retain six explicit derivation inputs.

## Exploration

No API was added. `GET /api/exploration/timeline` is exercised for Adam, Noah, Abraham, Sarah,
Isaac, Jacob, Joseph, and Egypt. Joseph demonstrates an entity with multiple source-backed claims.
Noah's Genesis 6:10 genealogy demonstrates a four-participant event: Noah, Shem, Ham, and Japheth.
Tests verify each explored direct claim retains the complete Entity → Event → Claim → Proposition
→ Evidence → Citation → SourceRecord → Dataset → Source chain and reports source text and
quotation as `NOT_STORED_BY_POLICY`. Exploration leaves all persistent table counts unchanged.

Source comparison continues to emit only `SOURCE_DESCRIPTION`, `SINGLE_SOURCE_DESCRIPTION`, or
`DIFFERING_SOURCE_DESCRIPTION`. Phase 27 creates no `ClaimRelation` and makes no automatic
contradiction, error, compliance, or truth classification.

## Candidate layer and actual unmodeled examples

```text
data/candidates/phase27-genesis-candidates.csv
```

The worksheet is non-authoritative and records review status, coverage classification, obstacle
classification, proposed mapping decision, and final disposition. The SQL report reconciles its
principal statuses to actual database state.

Actual examples:

| Observation | Classification | Disposition |
| --- | --- | --- |
| Jacob/Israel naming at Genesis 32:28 | `CANDIDATE_REQUIRES_REVIEW` | cited evidence only; no rename predicate |
| Detailed cupbearer, baker, and Pharaoh dream symbols | `NOT_YET_MODELED` | occurrences/participants modeled; detailed content deferred |
| Abram/Sarai name changes | `CANDIDATE_REQUIRES_REVIEW` | candidate only; no identity claim |
| Dinah and the multi-event Genesis 34 narrative | `NOT_YET_MODELED` | deferred for careful bounded data entry |
| Joseph's garment | `NOT_YET_MODELED` | representable object deferred to a bounded object pass |
| Genesis wells | `NOT_YET_MODELED` | deferred to prevent accidental identity merging |
| Modern equivalents/coordinates for places | `EXCLUDED` | outside source boundary and prohibited |
| Causal/theological reading of Joseph's sale | `EXCLUDED` | sale event retained without inferred causal edge |
| New calculated chronology | `EXCLUDED` | no new derivation required; direct observations are not calculations |

Ten Genesis evidence records currently back no claim. They remain cited, queryable source
observations and must not be interpreted as orphans or silence.

## Obstacle classification

| Classification | Finding |
| --- | --- |
| `DATA_ENTRY` | Genesis 34, garment, and well material is representable but needs a careful bounded pass. |
| `INGESTION` | Candidate review and fixture authoring remain manual; the CSV is deliberately not an authoritative loader. |
| `QUERY` | Chapter coverage currently parses the established human-readable locator format; no normalized locator structure was added. |
| `USABILITY` | Large entity timelines are available through the existing API but the browser UI has no corpus-specific navigation. |
| `DOCUMENTATION` | Coverage must explicitly distinguish locator coverage, structured-claim coverage, and source silence; this document and report do so. |
| `REGISTRY_EXPRESSIVENESS` | Naming/renaming and detailed dream semantics cannot be represented without adding predicates merely for coverage. They remain candidates/evidence. |
| `SCHEMA` | **No obstacle found.** Existing relational structures represented every accepted assertion with complete provenance. |

## Did ingestion expose an architectural deficiency?

**NO.**

Evidence:

1. 126 new propositions and direct claims load under existing foreign keys and predicate-kind
   constraints.
2. All 126 new claims have complete provenance.
3. All 71 new participations are projections, not a duplicate authoritative store.
4. Existing source identity mappings support 48 new source referents with justification and
   evidence.
5. No schema, registry, event, derivation, or exploration semantic changed.
6. Unsupported observations are expressiveness or data-entry candidates; none requires a new
   relational relationship to preserve the accepted epistemic boundaries.

## Validation

`tests/validation/phase27-genesis-validation.sql` verifies:

- duplicate canonical entities: 0;
- duplicate source records: 0;
- incomplete Phase 27 provenance: 0;
- structurally orphaned claims/evidence: 0;
- invalid foreign keys: 0 (enforced during fixture load);
- registry modifications: 0;
- unexpected derivations/inputs: 0;
- Phase 27 storage-policy violations: 0;
- automatic source-difference relations: 0;
- required explorer subjects and the multi-participant event are reachable.

Verified commands:

| Command | Result |
| --- | --- |
| `npm run lint` | PASS |
| `npm run typecheck` | PASS |
| `npm run build` | PASS |
| `npm test` | PASS (36/36) |
| Phase 27 fixture + validation + coverage report | PASS |

The complete PostgreSQL runner also executes the accepted Phase 19, 21, 23, 24, 25, and 26
regression validations before Phase 27.
