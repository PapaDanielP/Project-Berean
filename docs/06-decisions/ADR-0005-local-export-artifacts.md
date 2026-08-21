# ADR-0005: Local Deterministic Export Artifacts

## Status

Accepted for R2-03 — 2026-08-21

## Context

An export is an operational reproducibility artifact. It is not a source acquisition, evidence or
claim creation path, truth decision, contradiction resolution, reconciliation, or repair process.
The durable SYSTEM worker already provides lease-token ownership, cancellation, recovery, and a
closed executor registry.

## Decision

The first export implementation uses only the absolute server-configured
`EXPORT_ARTIFACT_DIR`. The worker creates a missing root with mode `0700`, but rejects missing,
relative, non-directory, symlinked, or differently resolved roots. Clients cannot provide a path,
locator, filename, storage backend, query language, or destination.

The executable request shape is `JSONL` with `includeRawContent=false`. It exports at most 1,000
deterministically ordered source-backed Claim → ClaimEvidence → Evidence → SourceRecord → Dataset
→ Source rows and is capped at 8 MiB. The first line carries version, scope, bounds, truncation,
and the non-adjudicative notice. Subsequent lines preserve proposition structure, claim/evidence
classifications, typed evidence relations, citations, and provenance identifiers. No dynamic
timestamp appears in the canonical bytes.

The worker:

1. generates opaque UUID identifiers and a safe relative `.jsonl` locator;
2. writes exact canonical bytes to an exclusive no-follow temporary file inside the root;
3. fsyncs the file, computes SHA-256 and byte length over those exact bytes, atomically renames,
   and fsyncs the directory;
4. in one PostgreSQL transaction guarded by the active unexpired lease and cancellation state,
   marks the job complete and inserts immutable artifact metadata;
5. removes the final file if metadata publication loses the lease, observes cancellation, or
   fails.

`export_artifact` is immutable and unique by producing job and export request. Completed jobs
cannot be retried through the API; a recovered or manually re-executed job that already has
metadata fails `EXPORT_ALREADY_EXECUTED`. Equivalent new requests against identical state produce
byte-identical payloads and checksums, while retaining distinct opaque artifact identities.

Authenticated `ADMINISTRATOR` routes expose metadata and an optional download by artifact UUID.
Download resolves UUID → persisted locator → configured root, uses no-follow reads, and verifies
size and checksum. It never accepts a filesystem locator.

## Retention and limitations

Artifacts are retained until manual operational cleanup. R2-03 adds no automatic deletion,
expiry, cloud/object storage, external fetch/upload, arbitrary browsing, remote access,
subprocess, shell, database dump, or generic export language. Operators must coordinate manual
file cleanup with immutable metadata; unavailable files fail integrity-safe rather than exposing
another path.

Exported rows retain represented provenance and epistemic labels. Their presence in an artifact
does not verify a claim, establish truth, select among interpretations, or confer redistribution
rights beyond recorded dataset policy.
