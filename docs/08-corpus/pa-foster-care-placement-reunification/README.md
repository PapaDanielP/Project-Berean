# Pennsylvania Foster-Care Placement and Reunification Corpus

This directory contains the documentation and source inventory for the focused Project Berean MVP corpus:

> Pennsylvania foster-care placement stability and family reunification, 2018–2025.

This corpus is intentionally separate from application code, ingestion code, generic fixtures, and unrelated research topics. The documents here define scope and source-selection decisions before additional ingestion work begins.

## Contents

- [`CORPUS_CHARTER.md`](./CORPUS_CHARTER.md) — authoritative scope, boundaries, definitions, and acceptance criteria.
- [`SOURCE_INVENTORY.csv`](./SOURCE_INVENTORY.csv) — reviewable catalog of candidate and selected sources.

## Folder policy

When source files are later downloaded, place them under a corpus-specific data directory rather than mixing them with application fixtures:

```text
data/corpora/pa-foster-care-placement-reunification/
├── raw/
│   ├── laws-regulations/
│   ├── state-performance-reports/
│   ├── oversight-reviews/
│   ├── county-pilot/
│   └── contextual-research/
├── manifests/
├── extracted/
└── README.md
```

The present milestone creates only the charter and inventory. It does not add downloaded documents or modify ingestion behavior.
