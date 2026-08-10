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

## External source acquisition

Declaring an external source is not acquisition, acquisition is not inspection, and inspection is not import. Each state is recorded separately and must not be conflated.

Maintainer permission to use a source is not permission to redistribute any particular file. Verify licensing at file level; when a file-level notice is more restrictive than the repository-level license, preserve the stricter terms. If a file may not be redistributed, keep the payload outside tracked source data and record an auditable acquisition manifest with the pinned revision, upstream path, acquisition date, SHA-256 hashes, license notice, attribution, and any transformation, plus a script that re-acquires and re-verifies it.

Attribution and license notices must be preserved wherever the source is described, including source and dataset metadata.

## Imported record revisions

Treat source records as append-only imports. Record the imported content hash and revision metadata, and link a replacement record to the record it supersedes rather than mutating source text in place.

## Conflicts

Conflicting claims remain representable simultaneously.

## Genesis 1–11

Genesis 1–11 is a test/stress dataset, not a declaration that the current data set is exhaustive or authoritative.
