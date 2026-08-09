#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$root/schema/sql/001_core_schema.sql"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$root/tests/fixtures/claim-evidence-fixture.sql"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$root/tests/fixtures/negative-integrity-fixture.sql"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$root/scripts/validation/validate.sql"
