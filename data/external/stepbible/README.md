# STEP Bible External Source

This directory declares an external upstream source and records what has been acquired,
inspected, and imported from it.

| State | Result |
| --- | --- |
| Permission / license verification | Verified 2026-08-10 (maintainer permission; file-level notice recorded) |
| Acquisition | One pinned file acquired 2026-08-10, hash-verified, kept untracked |
| Inspection | Completed; see `INSPECTION.md` |
| Import | Partial: one Genesis locator (`Gen.1.1`) imported as provenance metadata only |
| Redistribution | None; no upstream payload is stored in this repository |

- Upstream source repository identifier: `STEPBible/STEPBible-Data`
- Upstream repository is **not vendored** into Project Berean.
- The pinned upstream commit is the reproducible reference point for acquisition and ingestion.

## Acquisition

`scripts/acquisition/fetch-stepbible.sh` re-fetches the exact pinned artifacts declared in
`ACQUISITION_MANIFEST.yaml` into the untracked `.acquired/` workspace and verifies every recorded
SHA-256 hash. The script fails rather than proceeding if a hash does not match.

Run `STEPBIBLE_VERIFY_ONLY=1 scripts/acquisition/fetch-stepbible.sh` to verify an existing local
copy without network access.

## Provenance and licensing expectations

Future imports from this upstream source must preserve Berean provenance requirements (source origin, edition/version, acquisition method, source location format, import date, and transformation rules).

The upstream repository README states a repository-wide CC BY 4.0 position, but dataset/file-level licensing can differ and must be verified per dataset/file before ingestion. Do not assume one license applies to all upstream content.

The project maintainer verified on 2026-08-10 that Berean may use this source with attribution. Maintainer permission is not by itself permission to redistribute any particular file.

The acquired file carries its own notice: it declares CC BY 4.0, credits STEP Bible and Tyndale
House Cambridge, and asks downstream users not to redistribute the data themselves but to refer
others to `github.com/STEPBible`. Berean preserves that stricter file-level condition, so the
acquired payload is deliberately kept out of tracked source data.

Raw upstream material remains source data and must not be treated as canonical entities, evidence, claims, propositions, relationships, events, or derived knowledge unless explicitly modeled through Berean's provenance workflow.

No full copy of `STEPBible/STEPBible-Data` is included here, and no upstream payload of any size
is committed.

## Attribution

> Data from STEP Bible (www.STEPBible.org), based on work at Tyndale House, Cambridge,
> licensed CC BY 4.0.
