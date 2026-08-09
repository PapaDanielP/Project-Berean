# Genesis 1:1–5 Conservative Validation Slice

## Summary

The Genesis 1:1–5 slice is a small, deterministic validation fixture inside `tests/fixtures/020-genesis-1-11-fixture.sql`. It exercises the Berean v0.6 provenance chain without adding schema columns, a relationship table, an inference engine, or an authoritative transcription of source text.

The slice validates this path:

```text
Source
  -> Dataset
  -> SourceRecord
  -> Citation
  -> Evidence
  -> Claim
  -> Proposition
  -> Entity / Event / Relationship predicate
```

## Source-data limitation

The repository does not currently distribute a licensed Genesis 1:1–5 source text. For that reason, the fixture uses structural Masoretic reference records only:

- `source_record.raw_content` is `NULL`.
- `source_record.content_hash` is `NULL`.
- `citation.quoted_text` is `NULL`.
- citations retain verse locators such as `Genesis 1:1`.
- evidence observations are conservative paraphrased test observations, not authoritative source transcription.

This follows the existing Genesis 1–11 fixture convention: locators and provenance are stored, but source text is not reproduced.

## What the slice validates

- Genesis 1:1, 1:2, 1:3, 1:4, and 1:5 are five distinct `source_record` boundaries.
- Every slice evidence item links to a citation, source record, dataset, and source.
- Every slice claim links through `claim_evidence` to supporting evidence and source provenance.
- Multiple evidence and claim/proposition records can attach to one verse boundary; Genesis 1:1 intentionally has multiple evidence records and multiple supported claims.
- Relationships are represented only as existing proposition predicates, primarily `subjectOf` and `participatesIn`.
- Event participation remains a projection from claim-asserted propositions through the `event_participation` view.

## What the slice intentionally does not claim

- It does not assert that any represented claim is universally true.
- It does not add theological conclusions about creation, divinity, goodness, cosmology, or doctrine.
- It does not infer historical chronology or elapsed time from the verse sequence.
- It does not resolve underdetermined or translation-sensitive details in Genesis 1:2, including the spirit/wind/breath wording.
- It does not model the "good" evaluation, the "called/named" ternary structure, or "evening and morning" as a derived chronology.
- It does not reconcile source identities for these terms into durable canonical identities.
- It does not claim to be an exhaustive representation of Genesis 1:1–5.

## Known limitations

- The current proposition model is binary, so source statements that are naturally ternary, such as "X called Y Z", are represented conservatively as participants in a naming statement rather than as a full naming relation.
- The fixture uses generic `OTHER` events because the controlled event vocabulary does not yet include creation, speech, naming, separation, or condition-state event types.
- Entities such as `gen1_light`, `gen1_darkness`, `gen1_day`, and `gen1_night` are validation-slice concepts used to test provenance and proposition structure, not a completed ontology.
- No licensed source text is included; source records are structural references.

## Intentionally deferred items

- A licensed, documented source-text import with content hashes.
- Translation-aware source identities and reconciliation mappings.
- Explicit modeling of source-language ambiguity for Genesis 1:2.
- A controlled decision on whether new predicates or event types are needed for creation, naming, evaluation, separation, and temporal sequence.
- Broader Genesis 1 validation beyond verses 1–5.

## Recommended next steps

1. Add a distribution-compatible source-text dataset only when licensing and provenance are documented.
2. Review whether the predicate registry needs carefully scoped additions for ternary-like source statements before modeling naming semantics more precisely.
3. Add translation-specific fixtures if the project needs to compare Masoretic, Septuagint, or other textual traditions for Genesis 1.
4. Keep using `tests/validation/genesis-1-1-5-slice.sql` as the regression check for this conservative slice.

## Validation command

Run the existing PostgreSQL validation pipeline against an empty disposable PostgreSQL 16 database:

```sh
scripts/validation/run-postgres-validation.sh
```

