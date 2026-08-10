# Source metadata: BibleData

## Source identity

- Source name: BibleData
- Repository: `BradyStephenson/bible-data`
- Repository URL: <https://github.com/BradyStephenson/bible-data>
- Default branch: `main`
- Exact pin commit: `c6bf7893c78352effad1c32dcc4dc2c0ffbb4ee1`
- Pin/inspection date: August 10, 2026
- Upstream commit timestamp observed separately: August 2, 2026
- Repository description: Information from the Bible as structured data.
- Project title in README/CITATION: BibleData: Structured Datasets from the Holy Bible
- Author/attribution: Brady Stephenson
- Copyright statement observed in README: copyright 2021–2026 Brady Stephenson

## Release and citation metadata

- Version: 1.0
- Date released: 2026-04-12
- DOI: `10.5281/zenodo.19539956`
- Repository code: <https://github.com/BradyStephenson/bible-data>

## Observed license declarations

These are upstream observations, not a Berean license determination:

- README displays/claims Creative Commons Attribution 4.0 International (CC BY 4.0).
- LICENSE file is Creative Commons Attribution 4.0 International Public License.
- `CITATION.cff` declares license `CC-BY-NC-SA-4.0`.
- GitHub repository metadata reports license key `other`.

License status: `CONFLICTING_UPSTREAM_DECLARATIONS`.

Berean must not resolve this discrepancy on behalf of the upstream author. Clarification and verification are required before any ingestion, redistribution, or adapted database publication. Attribution, modification notices, and any applicable license, share-alike, or noncommercial restrictions must be reviewed before redistributing upstream material or publishing adapted database content.

## Berean import policy

This directory contains metadata only. It does not contain upstream CSV files, raw data exports, derived fixtures, canonical knowledge records, import code, or schema changes.

A future import must record:

- source origin
- licensing status and verification notes
- edition/version
- acquisition method
- source location format
- import date
- transformation rules
- preservation of source-specific identifiers and observations

Raw upstream material must remain distinct from canonical Berean records until explicitly imported and validated. Source-specific identities and observations must not be collapsed into canonical Entity, Event, Evidence, Claim, Proposition, relationship, or derived-knowledge records without provenance-preserving import steps.

Required future workflow:

Source → Dataset → SourceRecord → Citation → Evidence → Proposition → Claim → ClaimEvidence → Entity/Event relationships → optional Derivation → validation
