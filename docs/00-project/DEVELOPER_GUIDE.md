# Developer Guide

## Scope and prerequisites

This is a pre-beta PostgreSQL 16 reference baseline, not an application or ingestion tool. Install a PostgreSQL 16 server and client (`psql`), create an empty database, and set `DATABASE_URL` to its connection URL.

## Clean setup and validation

From the repository root:

```sh
createdb berean_reference
export DATABASE_URL='postgresql://localhost/berean_reference'
scripts/validation/run-postgres-validation.sh
```

The script applies `schema/sql/001_core_schema.sql`, loads the deterministic fixture, runs constraint-negative cases, then runs the blocking/warning validation. It exits nonzero on SQL or blocking validation errors. Run it only against an empty disposable database: the schema DDL is intentionally a clean setup, while the fixture transaction resets reference-model data so it can be rerun after setup.

`schema/sql/002_validation_queries.sql` contains read-only diagnostic queries. The GitHub Actions workflow runs the same script against PostgreSQL 16.

## Model boundaries

`source` identifies an originating work or source; `dataset` is the imported edition, version, or structured import container for that source; `source_record` is an append-only imported record revision. A revised record links to its predecessor with `supersedes_source_record_id`; do not update imported content in place. `content_hash` records the imported content fingerprint, and `imported_at` records its import time.

Citation is first-class: a citation belongs to a source record, and evidence can have multiple citations. A `SOURCE_OBSERVATION` requires at least one citation in validation.

## Contributions and data

Keep claims, evidence, source identities, and canonical entities distinct. Do not overwrite competing claims. Add controlled vocabulary values deliberately with their meaning.

Contributors must have the right to submit code and data. Do not commit copyrighted source text or data without a distribution-compatible license and provenance. Record the source, edition, licensing status, acquisition method, locator format, and transformations for any distributed source data.

## Read-only web explorer (MVP)

This repository now includes a small read-only web application layer that consumes the existing PostgreSQL reference schema without changing model semantics.

### Environment

```sh
export DATABASE_URL='postgresql://localhost:55432/berean_reference'
export PORT=3000 # optional
```

### Install

```sh
npm install
```

### Run authoritative model validation (separate, required)

```sh
scripts/validation/run-postgres-validation.sh
```

### Run application checks

```sh
npm run test
npm run typecheck
npm run lint
npm run build
```

### Start the web app

```sh
npm run dev
# open http://localhost:3000
```

The app is read-only and exposes no write endpoints.
