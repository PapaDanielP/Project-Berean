#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

run() {
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$1"
}

run "$root/schema/sql/001_core_schema.sql"

# Each fixture resets reference-model data, so validation runs once per loaded fixture.
run "$root/tests/fixtures/010-synthetic-structural-fixture.sql"
run "$root/tests/fixtures/030-negative-integrity-fixture.sql"
run "$root/scripts/validation/validate.sql"
"$root/tests/validation/blocking-cases.sh"

run "$root/tests/fixtures/020-genesis-1-11-fixture.sql"
run "$root/tests/validation/genesis-1-1-5-slice.sql"
run "$root/tests/validation/phase6-regression.sql"
run "$root/tests/validation/phase6-coverage-report.sql"
run "$root/tests/validation/genesis-1-6-9-slice.sql"
run "$root/tests/validation/phase7-coverage-report.sql"
run "$root/tests/validation/genesis-1-10-13-slice.sql"
run "$root/tests/validation/phase8-coverage-report.sql"
run "$root/tests/validation/genesis-1-14-19-slice.sql"
run "$root/tests/validation/phase9-coverage-report.sql"
run "$root/tests/validation/genesis-1-20-31-slice.sql"
run "$root/tests/validation/phase10-coverage-report.sql"

# Phase 11 bounded object/artifact entity slice: extends the Genesis 1-11 fixture in place with
# the source-backed noahs_ark OBJECT entity, then adds the validation-only ark_of_covenant entity.
run "$root/tests/fixtures/050-phase11-object-entity-fixture.sql"
run "$root/tests/validation/phase11-object-entity-slice.sql"
run "$root/tests/validation/phase11-coverage-report.sql"

# Bounded STEP Bible acquisition: manifest integrity offline, then the imported Genesis subset.
"$root/tests/validation/stepbible-acquisition-manifest.sh"
run "$root/tests/fixtures/040-stepbible-genesis-source-fixture.sql"
run "$root/tests/validation/stepbible-source-slice.sql"
run "$root/scripts/validation/validate.sql"

run "$root/tests/fixtures/030-negative-integrity-fixture.sql"
run "$root/scripts/validation/validate.sql"
"$root/tests/validation/blocking-cases.sh"
