# INSPECTION — STEP Bible pinned artifact

Inspection date: 2026-08-10
Upstream revision inspected: `STEPBible/STEPBible-Data` @ `b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`

Inspection was performed on a hash-verified local copy fetched by
`scripts/acquisition/fetch-stepbible.sh`. No upstream text is reproduced in this document or
anywhere else in this repository.

## Artifact inspected

- Upstream path: `Translators Amalgamated OT+NT/TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt`
- Size: 18,190,455 bytes
- SHA-256: `e9b8546ee48fe0bfc57c3b70f5f40e98d96580e803526d19026224e31753368b`
- Local artifact path (untracked): `.acquired/stepbible/TAHOT_Gen-Deu.txt`

Genesis is only distributed upstream inside this Gen–Deu book-range file; there is no smaller
Genesis-only upstream file at the pinned revision.

## File-level licensing and attribution notice

The filename and the in-file header both declare CC BY 4.0. The header notice credits
`www.STEPBible.org` and work at Tyndale House Cambridge, and it adds a downstream request that
is more restrictive than a bare CC BY 4.0 grant:

> Refer others to github.com/STEPBible as the source of the data. Please do not redistribute it
> yourself.

It also requires that self-made changes carry a note of changes visible to downstream users.

**Decision:** Berean preserves the stricter file-level request. The payload is not committed to
this repository, is not vendored, and is not reproduced in fixtures or documentation. Maintainer
permission to *use* the source is not treated as permission to override a file-level
redistribution request.

## Structural findings (metadata only)

- Format: tab-delimited, one row per word occurrence, preceded by a documentation/licence header.
- Total lines in artifact: 140,041.
- Source locator format: `Book.Chapter.Verse#WordIndex` with a text-witness suffix, for example
  `Gen.1.1#01=L`. Berean records the verse-level locator `Gen.1.1`.
- Genesis chapter 1 is represented by 31 distinct verse locators.
- Verse `Gen.1.1` is represented by 7 word-level rows; `Gen.1.2` by 14.
- Word rows carry Strong's-number tagging (extended for BDB, with prefix/suffix tags) and ETCBC
  morphology codes in separate columns.
- For `Gen.1.1` the tagging includes a qal-perfect 3ms verb tagged `H1254A` (to create), the
  nominal tag `H0430` (God), and two object-marked nominal tags, `H8064` (heaven/heavens) and
  `H0776` (earth/land).
- SHA-256 of the ordered `Gen.1.1#` row block (newline-terminated):
  `28cdf66fc9d5c6e913595bbba12adc2a8059fb066cbcb0019d677ae883836e11`.

## What this inspection does and does not establish

Established:

- The pinned revision exists and is retrievable, and the selected file's bytes are fixed by hash.
- The file's own licence notice and attribution requirements are recorded verbatim.
- The `Gen.1.1` record boundary, row count, and tag content are directly observed, not assumed.

Not established:

- Nothing about upstream files that were not fetched. Every other upstream dataset remains
  acquisition-pending and license-unverified at file level.
- No translation, meaning, or theological conclusion. The tags above are lexical/morphological
  identifiers published by the dataset, not Berean semantic assertions.
