# Berean Data Policy

## Source data

Preserve source-origin information and do not silently normalize away source-specific details.

## Canonical data

Canonical entities and semantic relationships are maintained separately from source-specific records.

## Evidence

Evidence should represent source-grounded observations. Avoid turning broad interpretation into evidence merely because it is plausible.

## Claims

Claims should express propositions that can be evaluated.

## Derived claims

If a claim requires calculation, interpretation, reconciliation, or assumptions beyond an explicit source statement, record that distinction.

The reference schema requires a derived claim to link to a derivation containing its method, assumptions, and at least one input during validation.

## Imported record revisions

Treat source records as append-only imports. Record the imported content hash and revision metadata, and link a replacement record to the record it supersedes rather than mutating source text in place.

## Conflicts

Conflicting claims remain representable simultaneously.

## Genesis 1–11

Genesis 1–11 is a test/stress dataset, not a declaration that the current data set is exhaustive or authoritative.
