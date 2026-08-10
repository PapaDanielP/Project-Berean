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
run "$root/tests/fixtures/030-negative-integrity-fixture.sql"
run "$root/scripts/validation/validate.sql"
"$root/tests/validation/blocking-cases.sh"
