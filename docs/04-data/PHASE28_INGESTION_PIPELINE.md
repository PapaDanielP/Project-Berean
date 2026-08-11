# Phase 28 — Automated Tier-1 Biblical Ingestion Pipeline

Phase 28 converts the manual Phase 26–27 Genesis ingestion workflow into a deterministic,
provenance-preserving, idempotent Tier-1 ingestion pipeline. It adds an ingestion mechanism, not a
new persistence architecture: every accepted candidate is written through the existing
entity / event / typed value / proposition / claim / evidence / citation / source record / dataset /
source / source-identity structures.

No schema definition, migration, foreign key, registry row, controlled vocabulary, derivation,
source-identity architecture, or exploration semantic changed in this phase.

The governing boundaries remain:

```text
SOURCE-BACKED IS NOT TRUE
EXPLICIT SOURCE ASSERTION IS NOT INTERPRETATION
STRUCTURAL DERIVATION IS NOT SOURCE ASSERTION
ABSENCE IS NOT SOURCE SILENCE
PROPOSITION IS THE AUTHORITATIVE CLAIM CONTENT
```

## Components

```text
data/ingestion/phase28-genesis-manifest.csv   deterministic machine-readable manifest
src/ingestion/types.ts                        manifest columns, enums, report shape
src/ingestion/manifest.ts                     strict CSV parser
src/ingestion/classifier.ts                   pure deterministic classifier
src/ingestion/pipeline.ts                     transactional, idempotent ingestion + reporting
src/ingestion/run-ingestion.ts                CLI entry point
tests/app/phase28-ingestion.test.ts           automated ingestion tests
tests/validation/phase28-ingestion-validation.sql  post-ingestion SQL invariants
```

Run it with:

```sh
DATABASE_URL=postgresql://... npm run ingest -- [manifest path] [--dry-run] [--fail-on-invalid]
```

The command prints a JSON report of every classification, including candidates it deliberately did
not import, and exits non-zero only if the run fails or `--fail-on-invalid` is set and the manifest
contains malformed rows.

## Manifest format

The manifest is a CSV with an exact header. Any deviation in the header or in a row's column count
is a hard parse error, so a truncated or reordered file can never be partially ingested.

It preserves the Phase 27 candidate worksheet columns:

```text
candidate_key, entity_type, candidate_name, biblical_references,
explicit_textual_description, proposed_proposition, source_status, external_source,
external_identifier, review_status, exclusion_reason, review_notes, proposed_mapping_decision
```

and adds the machine-readable columns needed to construct a claim graph:

```text
inference_flag,
source_key, dataset_key, source_record_key, source_location,
```

The revised Phase 28 deterministic source contract also carries explicit replay/reporting keys:

```text
citation_key,
entity_key, entity_type_code, entity_name,
proposition_definition, predicate_code, subject_entity, object_entity,
event_key, event_type_code, event_participation_role, typed_value,
claim_key, claim_type_code, acceptance_tier, acceptance_basis,
subject_kind, subject_key, subject_type, subject_name, subject_description,
predicate,
object_kind, object_key, object_type, object_name, object_description,
object_value_type, object_value,
mapping_source_identity_key, mapping_display_name, mapping_justification
```

`external_source` and `external_identifier` are discovery metadata only. They are reported as
`DISCOVERY_METADATA_ONLY` and are never written into the graph or used as identifiers.

The shipped manifest reconciles the Phase 27 Genesis 1–50 candidate worksheet
(`data/candidates/phase27-genesis-candidates.csv`) and is used as the demonstration corpus.

## Classification rules

Every row receives exactly one outcome.

| Outcome | Meaning |
| --- | --- |
| `AUTO_ACCEPT` | Explicit, fully constructible, source-backed; persisted with complete provenance. |
| `CANDIDATE_REQUIRES_REVIEW` | Well-formed but not automatically importable; stays outside the graph. |
| `EXCLUDED` | Deliberately held back with a recorded exclusion reason. |
| `INVALID` | Malformed or unconstructible; rejected and reported. |

`AUTO_ACCEPT` requires **all** of:

- a known source, a dataset belonging to that source, and a source-record locator;
- a registered predicate whose subject/object term kinds match the row;
- registered entity types, event types, and value types, with numeric typed values that parse;
- no prohibited inference flag (`inference_flag = NONE`);
- `source_status = EXPLICIT_IN_SELECTED_CORPUS`;
- no duplicate canonical entity (same entity type and canonical name under a different key) and no
  entity/event type conflict with existing rows;
- a complete, justified source identity mapping when the row proposes one;
- a constructible, verifiable provenance chain after persistence.

A biblical reference alone never authorizes acceptance. The proposed assertion itself is evaluated;
rows that cite Genesis but propose an unregistered predicate, an inferred identity, or an
interpretive statement are rejected or deferred.

`CANDIDATE_REQUIRES_REVIEW` and `EXCLUDED` rows carry their manifest reasons into the report, and
inference-flagged rows additionally report `PROHIBITED_INFERENCE_FLAG:<flag>`.

## Transaction and idempotency behaviour

The whole run executes inside one transaction. Each accepted candidate is persisted inside its own
`SAVEPOINT`; if any part of its graph cannot be written, or its provenance cannot be verified, the
candidate is rolled back completely, reported as `INVALID` (or `INCOMPLETE_PROVENANCE`), and the run
continues. No partial candidate graph ever survives. `--dry-run` rolls the whole transaction back
after reporting.

Idempotency uses stable natural keys:

```text
source record   <source_record_key> within <dataset_key>
citation        CITE_<source_record_key>
evidence        EV_<source_record_key>
claim           CLAIM_<candidate_key>
source identity <mapping_source_identity_key>
entity / event  <subject_key> / <object_key>
proposition     matched on its full (subject, predicate, object) tuple
typed value     matched on value type and value
```

Running the same manifest twice creates no duplicate entity, proposition, claim, event, evidence,
citation, or mapping, and produces zero deltas. A claim whose key is absent but whose proposition is
already asserted from the same evidence is reused and reported as `DUPLICATES_PREVENTED`. A claim
key that already exists but asserts a different proposition is a conflict, and the candidate is
rolled back rather than silently rewritten.

## Provenance path

Every accepted direct claim is persisted with the complete path:

```text
Claim -> ClaimEvidence(SUPPORTS) -> Evidence -> EvidenceCitation -> Citation
      -> SourceRecord -> Dataset -> Source
```

The pipeline verifies this path after writing each candidate and refuses to keep a claim that does
not have it. Accepted source identity mappings are written `ACTIVE`, with justification and a
supporting evidence id drawn from the same source, satisfying the existing blocking rules.

Source storage stays locator-only: `source_record.raw_content`, `source_record.content_hash`, and
`citation.quoted_text` remain `NULL` and are reported as `NOT_STORED_BY_POLICY`. That is storage
policy, never evidence that the source says nothing.

## Enoch acceptance and rejection demonstration

Auto-accepted with complete provenance:

```text
P28_GEN_5_18_JARED_FATHER_ENOCH          jared fatherOf enoch                (Genesis 5:18)
P28_GEN_5_21_ENOCH_FATHER_METHUSELAH     enoch fatherOf methuselah           (Genesis 5:21)
P28_GEN_5_21_ENOCH_AGE_AT_FATHERHOOD_65  enoch ageAtFatherhoodYears 65       (Genesis 5:21)
P28_GEN_5_18_ENOCH_CHILD_IN_BEGETTING    enoch childIn enoch_begetting       (Genesis 5:18)
P28_GEN_5_21_ENOCH_PARENT_IN_BEGETTING   enoch parentIn methuselah_begetting (Genesis 5:21)
```

Deliberately not auto-approved:

```text
P28_GEN_5_23_ENOCH_AGE_AT_DEATH_365  CANDIDATE_REQUIRES_REVIEW  DEATH_INFERENCE
P28_GEN_5_24_ENOCH_ASCENSION         EXCLUDED                   THEOLOGICAL_INFERENCE
P28_GEN_4_17_ENOCH_SON_OF_CAIN       EXCLUDED                   IDENTITY_INFERENCE
P28_EXT_ENOCH_AUTHORED_1_ENOCH       EXCLUDED                   EXTERNAL_ATTRIBUTION
```

Genesis 5:23 states that the days of Enoch were 365 years; it does not state a death, so the
pipeline will not import an age-at-death claim. Genesis 4:17 names an Enoch begotten by Cain; the
pipeline will not merge that referent with the Enoch of Genesis 5. Neither decision is a statement
about the source or about truth.

The corpus also contains one intentionally rejected identity inference
(`P28_GEN_32_28_ISRAEL_RENAME`, Jacob/Israel) and intentionally deferred observations, including
`P28_GEN_21_26_WELLS`, `P28_GEN_37_JOSEPH_GARMENT`, `P28_GEN_34_DINAH_NARRATIVE`,
`P28_GEN_40_41_DREAM_CONTENT`, and `P28_GEN_17_5_ABRAM_SARAI_NAMES`.

## Measured Phase 28 metrics

Against the accepted Genesis 1–11 baseline (`020-genesis-1-11-fixture.sql`):

```text
TOTAL_CANDIDATES            53
ASSERTIONS_CONSIDERED       53
SOURCE_RECORDS_CONSIDERED   28
AUTO_ACCEPTED               38
SOURCE_BACKED_AUTO_ACCEPTED 38
SOURCE_BACKED_MANUAL         0
DERIVED_STRUCTURALLY         0
CANDIDATE_REQUIRES_REVIEW    7
REQUIRES_HUMAN_REVIEW        7
EXCLUDED                     8
NOT_YET_MODELED              5
INVALID                      0
ALREADY_PRESENT              0
NEW_ENTITIES                19
NEW_PROPOSITIONS            38
NEW_CLAIMS                  38
NEW_EVENTS                  11
NEW_EVIDENCE                17
NEW_CITATIONS               17
NEW_SOURCE_RECORDS          17
NEW_TYPED_VALUES             6
NEW_MAPPINGS                19
COMPLETE_PROVENANCE         38
INCOMPLETE_PROVENANCE        0
DUPLICATES_PREVENTED         0
DUPLICATES_CREATED           0
NEW_RECORDS                256
PROJECTED_EVENT_PARTICIPATION 16
```

Before/after counts for that run:

| Table | Before | After | Delta |
| --- | ---: | ---: | ---: |
| entity | 31 | 50 | +19 |
| event | 29 | 40 | +11 |
| typed_value | 8 | 14 | +6 |
| proposition | 87 | 125 | +38 |
| claim | 95 | 133 | +38 |
| claim_evidence | 102 | 140 | +38 |
| evidence | 39 | 56 | +17 |
| evidence_citation | 39 | 56 | +17 |
| citation | 38 | 55 | +17 |
| source_record | 38 | 55 | +17 |
| source_identity | 9 | 28 | +19 |
| entity_source_mapping | 9 | 28 | +19 |
| source | 2 | 2 | 0 |
| dataset | 2 | 2 | 0 |
| source_type | 4 | 4 | 0 |
| entity_type | 5 | 5 | 0 |
| claim_type | 3 | 3 | 0 |
| claim_status | 4 | 4 | 0 |
| evidence_type | 2 | 2 | 0 |
| claim_evidence_relation_type | 3 | 3 | 0 |
| mapping_status | 4 | 4 | 0 |
| event_type | 8 | 8 | 0 |
| event_participation_role | 5 | 5 | 0 |
| claim_relation_type | 5 | 5 | 0 |
| value_type | 6 | 6 | 0 |
| term_kind | 3 | 3 | 0 |
| predicate | 22 | 22 | 0 |
| derivation | 3 | 3 | 0 |
| derivation_input | 6 | 6 | 0 |

A second execution of the same manifest reports `ALREADY_PRESENT = 38`, all `NEW_*` counters at 0,
`NEW_RECORDS = 0`, `DUPLICATES_CREATED = 0`, and zero deltas. This demonstrates rerun safety on a
clean database: repeated execution creates no duplicate entities, source records, citations,
evidence, propositions, claims, events, typed values, or source identity mappings.

Against the full accepted Phase 19–27 validation state, the same manifest reports
`AUTO_ACCEPTED = 38`, `ALREADY_PRESENT = 38`, `DUPLICATES_CREATED = 0`, no new claims, and two
new records for the remaining source-backed reconciliation: a `GEN_MT` source identity plus its
`ACTIVE`, evidence-backed entity source mapping for `noah`, which the manual corpus had not
reconciled. A second run there is also a complete no-op.

## Limitations and obstacle classification

Nothing in this phase exposed an architectural deficiency. Every obstacle encountered classified as
`DATA_ENTRY` or `DATA_ACQUISITION`, not `SCHEMA` or `REGISTRY_EXPRESSIVENESS`:

| Obstacle | Classification | Note |
| --- | --- | --- |
| Deferred candidates (wells, garment, dream content, Dinah narrative, renaming) | `DATA_ENTRY` | Representable in principle; each needs a human decision about the exact assertion. |
| Chapters without a reference-point locator | `DATA_ACQUISITION` | `NOT_YET_MODELED`, never source silence. |
| Object-position places with no proposed mapping row (for example `nod`) | `DATA_ENTRY` | The manifest maps one entity term per row; the remaining reconciliations are worksheet work. |
| Locator-only storage | `DOCUMENTATION` | `NOT_STORED_BY_POLICY` is reported explicitly by design. |
| Causation, harmonization, chronology, modern geography, external attribution | not an obstacle | Outside the Tier-1 boundary by design. |

The pipeline performs no semantic evaluation: no truth or falsity, entailment, contradiction,
source reliability, theology, causation, harmonization, chronology inference, geography inference,
or identity reconciliation beyond an explicit source statement declared in the manifest.

## Boundary semantics

```text
AUTO_ACCEPT               != TRUE
SOURCE_BACKED_AUTO_ACCEPTED != TRUE
SOURCE_BACKED_MANUAL      != TRUE
DERIVED_STRUCTURALLY      != TRUE
CANDIDATE_REQUIRES_REVIEW != FALSE
REQUIRES_HUMAN_REVIEW     != FALSE
EXCLUDED                  != FALSE
NOT_YET_MODELED           != ABSENT
NOT_STORED_BY_POLICY      != source silence
```

Every report repeats these boundaries in its `boundary_notes`.

## Validation

`scripts/validation/run-postgres-validation.sh` runs the manifest twice after the Phase 27 step and
then executes `tests/validation/phase28-ingestion-validation.sql` plus the standard
`scripts/validation/validate.sql`. The ingestion step requires the Node toolchain and is skipped
with a message when `node_modules` is absent, so the pure-SQL validation path is unchanged.

`tests/app/phase28-ingestion.test.ts` exercises the pipeline in an isolated `phase28_ingestion`
schema: acceptance of explicit people, places, objects, events, parentage, event participation and
ages with complete provenance; rejection of inferred identity, death, geography, chronology,
theology, causation, harmonization and external-only assertions; duplicate prevention; incomplete
provenance detection; invalid predicate, entity type, typed value, enum, and source reference;
per-candidate rollback; dry runs; idempotent second execution; and the boundary semantics above.
