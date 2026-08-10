# STEP Bible acquisition and inspection report

Scope: a bounded acquisition, inspection, and minimal import of the permitted STEP Bible external
source, beginning from the pinned revision already declared in `data/external/stepbible/`. This is
not a Genesis population phase and does not extend the Genesis 1:1–19 population.

Upstream revision: `STEPBible/STEPBible-Data`, branch `master`, commit
`b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`.

Attribution: Data from STEP Bible (www.STEPBible.org), based on work at Tyndale House, Cambridge,
licensed CC BY 4.0.

## State summary

| State | Result |
| --- | --- |
| Permission / license verification | Verified. Maintainer permission recorded 2026-08-10; file-level notice verified independently. |
| Acquired | One upstream file, fetched at the pinned commit on 2026-08-10 and hash-verified. |
| Inspected | Yes. Structural findings recorded in `data/external/stepbible/INSPECTION.md`. |
| Imported | Partial. One Genesis locator (`Gen.1.1`) imported as provenance metadata only. |
| Redistributed | None. No upstream payload of any size is committed. |
| Pending | Every other upstream file and every other Genesis locator. |

## What was acquired

- Upstream path: `Translators Amalgamated OT+NT/TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt`
- Size: 18,190,455 bytes; SHA-256 `e9b8546ee48fe0bfc57c3b70f5f40e98d96580e803526d19026224e31753368b`
- Local artifact path (untracked): `.acquired/stepbible/TAHOT_Gen-Deu.txt`
- Acquisition method: pinned raw-file download; no clone, no unpinned branch, no model knowledge
- Transformation: none

Genesis is only published upstream inside this Gen–Deu book-range file, so this is the smallest
upstream unit that contains Genesis. No other upstream file was fetched.

`scripts/acquisition/fetch-stepbible.sh` reproduces the acquisition from
`data/external/stepbible/ACQUISITION_MANIFEST.yaml` and fails on any hash mismatch.

## License and attribution finding

The filename and the in-file header both declare CC BY 4.0 and credit STEP Bible and Tyndale House
Cambridge. The header adds a condition that is stricter than a bare CC BY 4.0 grant:

> Refer others to github.com/STEPBible as the source of the data. Please do not redistribute it
> yourself.

Maintainer permission covers use, not the overriding of this file-level request. Berean therefore
records the decision `not_redistributed`: the acquired payload stays outside tracked source data,
and the recorded SHA-256 hashes are the auditable substitute for redistribution.

## What was inspected

See `data/external/stepbible/INSPECTION.md`. Summary: 140,041 lines; tab-delimited word-level rows;
locator format `Book.Chapter.Verse#WordIndex`; Genesis 1 present as 31 distinct verse locators;
`Gen.1.1` present as 7 word-level rows with Strong's and ETCBC morphology tagging; SHA-256 of the
ordered `Gen.1.1#` row block is
`28cdf66fc9d5c6e913595bbba12adc2a8059fb066cbcb0019d677ae883836e11`.

## What was imported

`tests/fixtures/040-stepbible-genesis-source-fixture.sql` extends the Genesis fixture in place and
adds exactly one bounded, provenance-complete path:

| Object | Count | Detail |
| --- | --- | --- |
| Source | 1 | `STEP_TAHOT` (`DATASET`) |
| Dataset | 1 | `STEP_TAHOT_GEN`, version = pinned commit, license and attribution recorded |
| SourceRecord | 1 | `STEP_TAHOT_GEN_1_1`, `content_hash` of the inspected block, `raw_content` NULL |
| Citation | 1 | `CITE_STEP_TAHOT_GEN_1_1`, locator `Gen.1.1`, `quoted_text` NULL |
| Evidence | 2 | Source observations of published lexical/morphological tags |
| EvidenceCitation | 2 | Each observation cites its own source record |
| Claim | 3 | Source-specific STEP Bible direct claims |
| ClaimEvidence | 3 | All `SUPPORTS` |
| Proposition | 0 new | The three existing Genesis 1:1 propositions are reused |
| Entity / Event / Predicate / Derivation / ClaimRelation / SourceIdentity | 0 | None added |

The STEP Bible claims are kept distinct from the `GEN_MT_REF` structural claims: separate source,
dataset, source record, citation, evidence, and claim keys. They reuse the existing Genesis 1:1
propositions because the normalized semantics are the same and only source provenance differs,
which is the modeled `Claim A → Proposition P`, `Claim B → Proposition P` pattern. No GEN_MT_REF
record was modified and no Genesis fixture content was duplicated.

No upstream text, gloss, transliteration, or translation was imported, and no theological,
chronological, or interpretive assertion was added.

## Validation

Authoritative command: `scripts/validation/run-postgres-validation.sh` against a clean disposable
PostgreSQL 16 database.

- Baseline (before changes): PASS, exit 0.
- Final (after changes): PASS, exit 0.

New focused checks, wired into the runner:

- `tests/validation/stepbible-acquisition-manifest.sh` — offline manifest integrity: the pinned
  commit is identical across the declaration, acquisition manifest, inspection record, and fixture;
  all required acquisition fields are present; attribution appears in every file that describes the
  source; the file-level redistribution condition and decision are preserved; every recorded hash
  is a well-formed SHA-256 digest; the fixture uses the manifest's record hash; no upstream payload
  is tracked and the acquisition workspace is git-ignored. When the artifact is present locally its
  hashes are re-verified, otherwise that single check is skipped so the suite stays offline-safe.
- `tests/validation/stepbible-source-slice.sql` — imported-record integrity: source/dataset/source
  record linkage, pinned revision and license/attribution recorded on the dataset, the inspected
  content hash on the source record, no `raw_content` or `quoted_text`, citation locator preserved,
  complete evidence provenance and citations, every claim direct and supported, no new predicate,
  propositions reused rather than duplicated, the Masoretic Genesis 1:1 record unchanged, the batch
  bounded to `Gen.1.1`, and no reconciliation, derivation, or claim relation introduced.

## Limitations

- Only one upstream file was acquired. All other upstream datasets remain unacquired and
  file-level-license-unverified; their metadata manifests are not evidence of acquisition.
- The acquired payload is not redistributable under its own notice, so a fresh clone cannot inspect
  it without running the acquisition script with network access. The offline manifest checks are
  designed to pass in that state and report the artifact as absent rather than fail.
- The import is deliberately one locator. It demonstrates a provenance-complete external-source path;
  it is not Genesis coverage and does not change the Genesis population status.
- The evidence records observe published lexical and morphological tags only. They are not
  translations and assert no semantics beyond participation in the Genesis 1:1 statement.
- The upstream `Gen.1.1` record hash is stable only for the pinned commit; a different revision
  would require a new acquisition record rather than an edit in place.
