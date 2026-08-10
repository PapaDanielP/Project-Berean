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

# Phase 12 preserves the existing Genesis 1:22-23 structural source observations while
# explicitly validating their deliberately unmodeled semantic boundary.
run "$root/tests/validation/genesis-1-22-23-slice.sql"
run "$root/tests/validation/phase12-coverage-report.sql"

# Phase 13 advances the genealogical line one locator, to Genesis 5:9, populating the persistent
# PERSON entities and their source-recorded relationship with complete provenance.
run "$root/tests/validation/genesis-5-9-slice.sql"
run "$root/tests/validation/phase13-coverage-report.sql"

# Phase 14 validates the persistent object/artifact invariant against the already source-backed
# Genesis 8:4 Noah's Ark slice without adding object-specific architecture or fabricated material.
run "$root/tests/validation/genesis-artifact-slice.sql"
run "$root/tests/validation/phase14-coverage-report.sql"

# Phase 15 re-verifies that the same source-backed artifact slice supports persistent
# object semantics without fabricating unavailable construction or attribute material.
run "$root/tests/validation/phase15-artifact-semantics.sql"
run "$root/tests/validation/phase15-coverage-report.sql"
"$root/tests/validation/phase15-artifact-negative-cases.sh"

# Bounded STEP Bible acquisition: manifest integrity offline, then the imported Genesis subset.
"$root/tests/validation/stepbible-acquisition-manifest.sh"
run "$root/tests/fixtures/040-stepbible-genesis-source-fixture.sql"
run "$root/tests/validation/stepbible-source-slice.sql"
run "$root/scripts/validation/validate.sql"

# Phase 16 extends the noahs_ark and ark_of_covenant OBJECT entities established in Phase 11
# with source-backed construction, builder, dimension, material, component, content, and
# instruction/completed-event semantics for Genesis 6-7 and Exodus 25/37/40 plus Deuteronomy
# 10:3. Loaded last so earlier phases' bounded coverage/deferral checks are unaffected.
run "$root/tests/fixtures/060-phase16-artifact-construction-fixture.sql"
run "$root/tests/validation/phase16-artifact-construction-slice.sql"
run "$root/tests/validation/phase16-coverage-report.sql"
"$root/tests/validation/phase16-artifact-negative-cases.sh"
run "$root/scripts/validation/validate.sql"

# Phase 17 tests whether the existing generic architecture can represent the source-backed
# Exodus 25:15 standing requirement that the poles remain in the rings of the Ark of the
# Covenant and are not withdrawn, without misrepresenting it as a completed event, transport,
# construction, or compliance inference. Phase 16 documented this as an unresolved semantic
# precision gap; Phase 17 resolves it with the smallest reusable generic extension (one
# event_type, one predicate; no participation role, no new table). Loaded last so earlier
# phases' bounded coverage/deferral checks, including Phase 16's own, are unaffected.
run "$root/tests/fixtures/070-phase17-standing-requirement-fixture.sql"
run "$root/tests/validation/phase17-standing-requirement-slice.sql"
run "$root/tests/validation/phase17-coverage-report.sql"
"$root/tests/validation/phase17-negative-cases.sh"
run "$root/scripts/validation/validate.sql"

# Phase 18 tests whether the existing generic architecture -- unextended, with no new
# event_type and no new predicate -- can represent the source-backed Joshua 3:6 Ark-of-the-
# Covenant transport/handling occurrence (Joshua's instruction to the priests, and the
# priests' completed carrying of the ark before the people), while preserving the Phase 17
# Exodus 25:15 standing requirement and never inferring compliance from it. The existing
# generic OTHER event_type and subjectOf/participatesIn predicates proved sufficient; no
# registry extension was added. Loaded last so earlier phases' bounded coverage/deferral
# checks, including Phase 17's own, are unaffected.
run "$root/tests/fixtures/080-phase18-ark-transport-fixture.sql"
run "$root/tests/validation/phase18-ark-transport-slice.sql"
run "$root/tests/validation/phase18-coverage-report.sql"
"$root/tests/validation/phase18-negative-cases.sh"
run "$root/scripts/validation/validate.sql"

# Phase 19 tests the source-backed 2 Samuel 6:3-7 Ark lifecycle conflict/handling/
# consequence slice after Phase 18, using the existing generic OTHER/DEATH event types
# and subjectOf/participatesIn predicates. It records the Ark on a new cart, Uzzah's
# source-recorded physical interaction with the Ark, and Uzzah's death as an observed
# consequence, while preserving Exodus 25:15 and Joshua 3:6 semantics and never
# inferring compliance, violation, causation, or contradiction. No registry/schema
# extension is added.
# Phase 19 tests whether the existing generic architecture can represent the bounded
# 2 Samuel 6:3-7 Ark lifecycle conflict/handling slice -- Ark transport on a new cart,
# Uzzah's source-recorded physical interaction with the Ark, and Uzzah's death -- without
# inferring Exodus 25:15 violation/compliance, causation, or contradiction with Joshua 3:6.
# No registry, schema, table, JSON payload, or ClaimRelation extension is added.
run "$root/tests/fixtures/090-phase19-ark-lifecycle-conflict-fixture.sql"
run "$root/tests/validation/phase19-ark-lifecycle-conflict-slice.sql"
run "$root/tests/validation/phase19-coverage-report.sql"
"$root/tests/validation/phase19-negative-cases.sh"
run "$root/scripts/validation/validate.sql"

 # Phase 24 builds a reproducible Ark/Genesis knowledge-construction demonstration using
 # existing architecture only. It extends the accepted Phase 19 slice with source-backed
 # Ark content attestations from 1 Kings 8:9 and Hebrews 9:4, preserves source differences
 # without automatic contradiction/compliance inference, and validates provenance and
 # derivation-readiness demonstrations without adding schema/registry/persistence behavior.
 run "$root/tests/fixtures/100-phase24-berean-in-action-fixture.sql"
 run "$root/tests/validation/phase24-berean-in-action-slice.sql"
 run "$root/tests/validation/phase24-coverage-report.sql"
 run "$root/scripts/validation/validate.sql"

run "$root/tests/fixtures/030-negative-integrity-fixture.sql"
run "$root/scripts/validation/validate.sql"
"$root/tests/validation/blocking-cases.sh"
