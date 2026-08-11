# Phase 28 ingestion manifests

`phase28-genesis-manifest.csv` is the deterministic, machine-readable input to the Phase 28
automated Tier-1 ingestion pipeline (`npm run ingest`). It reconciles the Phase 27 Genesis 1–50
candidate worksheet in `data/candidates/` into an executable form.

A manifest is an ingestion instruction sheet, not Berean knowledge. Nothing here is a Source,
Evidence, Claim, Proposition, or Entity until the pipeline accepts a row and persists it through the
ordinary Source → Dataset → SourceRecord → Citation → Evidence → Claim path.

## Columns

The worksheet columns carried forward from Phase 27 keep their meaning
(`data/candidates/README.md`): `candidate_key`, `entity_type`, `candidate_name`,
`biblical_references`, `explicit_textual_description`, `proposed_proposition`, `source_status`,
`external_source`, `external_identifier`, `review_status`, `exclusion_reason`, `review_notes`, and
`proposed_mapping_decision`.

The additional columns make a row executable:

| Column | Meaning |
| --- | --- |
| `inference_flag` | `NONE`, or the prohibited-inference category that keeps the row out of the graph. |
| `source_key` / `dataset_key` | Existing source and dataset the row is read from. |
| `source_record_key` / `source_location` | Reference-point record and locator; source text is never stored. |
| `subject_kind` / `subject_key` / `subject_type` / `subject_name` / `subject_description` | Subject term of the proposition. |
| `predicate` | Registered predicate code. Unregistered predicates are `INVALID`. |
| `object_kind` / `object_key` / `object_type` / `object_name` / `object_description` | Object term when it is an entity or event. |
| `object_value_type` / `object_value` | Typed value when the object is a value. |
| `mapping_source_identity_key` / `mapping_display_name` / `mapping_justification` | Proposed source identity reconciliation for the row's entity term. |

`review_status` is one of `PROPOSED_AUTO_ACCEPT`, `REQUIRES_REVIEW`, or `EXCLUDED`. The pipeline,
not the manifest, decides the final classification.

## Boundaries

- `external_source` and `external_identifier` are discovery metadata only and are never persisted.
- `EXCLUDED` and `REQUIRES_REVIEW` describe Berean's representation status, not the source.
- Absence of a row is not source silence.
- `raw_content`, `content_hash`, and `quoted_text` stay `NULL` (`NOT_STORED_BY_POLICY`).

See `docs/04-data/PHASE28_INGESTION_PIPELINE.md` for the classification rules, transaction and
idempotency behaviour, provenance path, and measured metrics.
