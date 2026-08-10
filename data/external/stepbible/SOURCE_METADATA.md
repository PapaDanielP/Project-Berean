# SOURCE METADATA — STEP Bible Data

## Source identity

- Source name: STEP Bible Data
- Upstream repository: `STEPBible/STEPBible-Data`
- Upstream branch: `master`
- Pinned commit: `b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`
- Pin/inspection date: 2026-08-10 (August 10, 2026)
- Upstream commit date: not asserted here; retrieve from upstream commit metadata when needed.

## Attribution

Upstream documentation attributes this material to STEP Bible and Tyndale House, Cambridge. Required attribution should credit STEP Bible, include Tyndale House, Cambridge as additional attribution, and appear in source metadata, dataset metadata, distributed data notices, and documentation.

## Licensing position and caveats

Upstream README states a repository-wide CC BY 4.0 licensing statement. This must be treated as an upstream repository statement, not as a blanket assertion that every dataset/file has identical licensing terms.

Dataset/file-level indicators may differ (for example, tagged Bible filenames can include dataset-specific indicators such as CC BY-NC). Each dataset/file must be license-verified and recorded before ingestion.

Any downstream modifications and differences from upstream source data must be recorded and made available as required by the upstream README and applicable dataset terms.

The project maintainer verified on 2026-08-10 that Berean may use this source with attribution, including copying, redistribution, adaptation, and commercial use subject to attribution, modification indication, preserved license notices, and source-difference records. Maintainer permission is permission metadata; it does not override a file-level condition.

## Acquisition and inspection state

One upstream file has been acquired at the pinned commit and inspected. See
`ACQUISITION_MANIFEST.yaml` for the auditable record and `INSPECTION.md` for the results.

- Acquired file: `Translators Amalgamated OT+NT/TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt`
- Acquisition date: 2026-08-10
- Acquisition method: pinned raw-file download at commit `b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`
- Local artifact path (untracked): `.acquired/stepbible/TAHOT_Gen-Deu.txt`
- SHA-256: `e9b8546ee48fe0bfc57c3b70f5f40e98d96580e803526d19026224e31753368b`
- Source locator format: `Book.Chapter.Verse#WordIndex` (Berean records the verse-level locator, e.g. `Gen.1.1`)
- File-level license: CC BY 4.0, declared in the filename and in the in-file header notice
- Transformation or modification: none

The acquired file's own notice adds a condition that is stricter than a bare CC BY 4.0 grant: it
asks downstream users not to redistribute the data themselves and to refer others to
`github.com/STEPBible`. Berean preserves that condition. The payload is therefore **not**
redistributed in this repository; the recorded hashes are the auditable substitute.

Every other upstream file remains unacquired and file-level-license-unverified.

## Import state

Imported into the reference model: exactly one Genesis source record, locator `Gen.1.1`, as
provenance metadata (`Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence →
Claim → Proposition`). The source record stores a content hash and no `raw_content`; the citation
stores a locator and no `quoted_text`. No upstream text, gloss, or transliteration is imported.

Not imported: every other Genesis locator, every other upstream dataset, and any upstream payload.

## Berean import policy

- No full copy of `STEPBible/STEPBible-Data` is included in this repository.
- Raw upstream material remains source data.
- Raw upstream material is not automatically a Berean Claim, Evidence, Proposition, Entity, Event, relationship assertion, or derived assertion.

Required provenance workflow for future ingestion:

`Source → Dataset → SourceRecord → Citation → Evidence → Proposition → Claim → ClaimEvidence → Entity/Event relationships → optional Derivation → validation`

All future ingestion work must keep source-origin data distinct from canonical entities, evidence, claims, propositions, and derived knowledge.
