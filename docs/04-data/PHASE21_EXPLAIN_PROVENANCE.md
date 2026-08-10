# Phase 21 — `EXPLAIN_PROVENANCE` (read-only, deterministic)

Phase 21 implements the smallest bounded operation justified by `docs/04-data/PHASE20_CAPABILITY_SPECIFICATION.md`: a read-only provenance explanation endpoint.

## Route

- `GET /api/provenance/explain`
- Accepts exactly one query parameter:
  - `claim_id` (positive integer), or
  - `proposition_id` (positive integer)

### Response behavior

- `400` when both or neither identifiers are supplied, or when an identifier is not a positive integer.
- `404` when the requested claim/proposition does not exist.
- `200` for existing artifacts, including structurally incomplete provenance.

## Deterministic traversal

For selected claims, the operation traverses:

`Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`

It also resolves:

- authoritative `Proposition` + predicate registry metadata;
- projected `event_participation` rows for the asserting claim;
- derived-claim structure (`Derivation`, `DerivationInput`) when applicable.

Returned `NULL` `source_record.raw_content` and `citation.quoted_text` are explicitly reported as `NOT_STORED_BY_POLICY` (storage policy), not source silence.

## Structural gap reporting (deterministic only)

The operation reports only structural gaps, including:

- `MISSING_CLAIM_EVIDENCE`
- `MISSING_CITATION`
- `MISSING_SOURCE_RECORD`
- `MISSING_DATASET`
- `MISSING_SOURCE`
- `MISSING_DERIVATION`
- `MISSING_DERIVATION_INPUT`
- `INVALID_DERIVATION_INPUT`
- `SELF_INPUT_DERIVATION`
- `MISSING_PROJECTED_RELATIONSHIP`
- `MISSING_PROPOSITION_CLAIM` (when a proposition exists but has no claims)

No truth assignment, contradiction/compliance/causation/theological/modal inference, or artifact mutation is performed.

## Test coverage

`tests/app/app.test.ts` includes Phase 21 endpoint coverage for:

- complete direct-claim provenance;
- proposition-to-claims resolution;
- missing claim evidence;
- uncited evidence;
- source chain traversal;
- event-participation projection explanation;
- structurally valid derived claim inputs;
- missing and self-input derivation edge cases;
- invalid request and nonexistent artifact handling.
