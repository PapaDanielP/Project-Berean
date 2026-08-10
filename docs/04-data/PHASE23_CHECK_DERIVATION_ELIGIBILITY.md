# Phase 23 — `CHECK_DERIVATION_ELIGIBILITY` (structural, read-only)

**OPERATION:** `GET /api/derivations/check-eligibility?derivation_id=<id>`  
**MODE:** read-only, ephemeral  
**SCHEMA CHANGE:** none  
**REGISTRY CHANGE:** none

## Purpose and input

Phase 23 implements the structural subset recommended by Phase 22. It accepts one
positive-integer `derivation_id`. Missing or invalid input returns `400`; an identifier
with no stored `Derivation` returns `404`.

For an existing Derivation, the operation resolves the linked derived Claim, its
authoritative target Proposition, registered predicate and term kinds, stored method and
assumptions metadata, `DerivationInput` rows, referenced Claim/Evidence rows, and their
structural provenance chains. It reuses the Phase 21 source-chain shape:

`Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`

## Output

The response contains `structurally_eligible`, `checks`, `input_status`, stored
Derivation/Claim/Proposition metadata, and:

`license_status: REQUIRES_HUMAN_METHOD_JUSTIFICATION`

Checks have `PASS`, `FAIL`, or `NOT_APPLICABLE` status. Stable check identifiers are:

- `DERIVATION_EXISTS`
- `DERIVED_CLAIM_EXISTS`
- `DERIVED_CLAIM_TYPE_VALID`
- `DERIVATION_LINK_VALID`
- `METHOD_PRESENT`
- `ASSUMPTIONS_PRESENT`
- `DERIVATION_INPUT_EXISTS`
- `DERIVATION_INPUT_KIND_VALID`
- `DERIVATION_INPUT_REFERENCE_VALID`
- `INPUT_PROVENANCE_STRUCTURALLY_COMPLETE`
- `SELF_INPUT_ABSENT`
- `TARGET_PROPOSITION_EXISTS`
- `TARGET_PREDICATE_VALID`
- `TARGET_TERM_KINDS_VALID`

`structurally_eligible` is true only when no applicable structural check fails.
Method and assumptions are returned as stored metadata, including text that makes a
semantic assertion, without interpretation.

## Boundary and persistence

The endpoint performs deterministic relational retrieval only. It issues no
`INSERT`, `UPDATE`, `DELETE`, or other mutation, creates no artifact or evaluation
record, and changes neither schema nor registries. Structural eligibility is not
logical entailment. The operation does not assess method justification, assumptions,
evidence sufficiency, semantic applicability, truth, contradiction, compliance,
causation, or any other semantic conclusion.

This preserves the Phase 20 derivation boundary, the accepted Phase 21 provenance
traversal, and Phase 19 behavior. It does not implement a Phase 24 evaluator.

## Tests and schema-prevented cases

`tests/app/app.test.ts` covers an accepted derivation, missing request/nonexistent
Derivation, absent Claim linkage, absent inputs, self-input, metadata returned without
interpretation, and before/after counts for all public persistent and registry tables.
The existing Phase 21 tests remain in the same suite.

The schema prevents temporary creation of an invalid input kind (the `CHECK` requires
exactly one Claim or Evidence input), an invalid input reference (foreign keys), a
missing target Proposition (non-null foreign key), and an unregistered predicate or
term-kind pairing (composite foreign key). These cases remain reported by checks for
defensive read-only inspection but cannot be manufactured without weakening constraints.
