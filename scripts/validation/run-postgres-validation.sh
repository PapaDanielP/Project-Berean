#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

run() {
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$1"
}

run "$root/schema/sql/001_core_schema.sql"
run "$root/schema/sql/003_administration_workflow.sql"

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

# Phase 26 populates a bounded, source-backed biblical entity corpus using existing architecture
# only: Genesis 5:12-24 (the Enoch end-to-end gap example) and 1 Samuel 4:4-7:2 Ark material.
# The same coverage report runs immediately before and after ingestion, so the before/after
# inventory is reproducible. No schema, registry, or persistence change is introduced.
echo '--- Phase 26 coverage inventory BEFORE ingestion ---'
run "$root/tests/validation/phase26-coverage-report.sql"
run "$root/tests/fixtures/110-phase26-biblical-entity-coverage-fixture.sql"
run "$root/tests/validation/phase26-biblical-entity-coverage-slice.sql"
echo '--- Phase 26 coverage inventory AFTER ingestion ---'
run "$root/tests/validation/phase26-coverage-report.sql"
run "$root/scripts/validation/validate.sql"

# Phase 27 substantially expands the existing Genesis reference-point corpus through chapter 50.
# It reuses GEN_MT / GEN_MT_REF and accepted Genesis entities, adds no registry or schema rows, and
# runs the same inventory before and after ingestion to expose measured deltas.
echo '--- Phase 27 Genesis 1-50 coverage BEFORE ingestion ---'
run "$root/tests/validation/phase27-genesis-coverage-report.sql"
run "$root/tests/fixtures/120-phase27-genesis-1-50-fixture.sql"
run "$root/tests/validation/phase27-genesis-validation.sql"
echo '--- Phase 27 Genesis 1-50 coverage AFTER ingestion ---'
run "$root/tests/validation/phase27-genesis-coverage-report.sql"
run "$root/scripts/validation/validate.sql"

# Phase 28 converts the manual Phase 26-27 ingestion workflow into a deterministic, transactional,
# idempotent Tier-1 pipeline. It runs the shipped manifest twice against the state established
# above: the first run reports every classification, the second must change nothing. The step needs
# the Node toolchain, so it is skipped when dependencies are absent; the SQL validation above is
# unaffected either way.
if command -v node >/dev/null 2>&1 && [ -d "$root/node_modules" ]; then
    echo '--- Phase 28 automated Tier-1 ingestion (first run) ---'
    (cd "$root" && node_modules/.bin/tsx src/ingestion/run-ingestion.ts \
        data/ingestion/phase28-genesis-manifest.csv --fail-on-invalid)
    echo '--- Phase 28 automated Tier-1 ingestion (second run, idempotency) ---'
    (cd "$root" && node_modules/.bin/tsx src/ingestion/run-ingestion.ts \
        data/ingestion/phase28-genesis-manifest.csv --fail-on-invalid)
    run "$root/tests/validation/phase28-ingestion-validation.sql"
    run "$root/scripts/validation/validate.sql"
else
    echo 'skip: Phase 28 ingestion requires Node dependencies (npm ci).'
fi

# Phase 30 is a bounded scholarly research validation rather than another ingestion mechanism.
# It adds only the directly representable Genesis 6:4 assertion and separately cited textual,
# later-tradition, and scholarly observations. No interpretation is promoted to a biblical claim.
run "$root/tests/fixtures/130-phase30-nephilim-research-fixture.sql"
run "$root/tests/validation/phase30-nephilim-research-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 31 runs an end-to-end scholarly research demonstration over the Phase 30 corpus:
# explicit term-level observations, preserved MT/LXX distinction, independent Numbers retrieval,
# later-tradition and scholarship isolation, and deterministic synthesis constraints.
echo '--- Phase 31 scholarly demonstration (first run) ---'
run "$root/tests/fixtures/140-phase31-nephilim-research-demonstration-fixture.sql"
run "$root/tests/validation/phase31-nephilim-research-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 31 scholarly demonstration (second run, determinism/idempotency) ---'
run "$root/tests/fixtures/140-phase31-nephilim-research-demonstration-fixture.sql"
run "$root/tests/validation/phase31-nephilim-research-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 32 generalizes the scholarly research demonstration to a non-Genesis historical
# case: the 1919 solar-eclipse expedition. It adds only source-backed observation,
# event/participation/chronology claims, and isolated scholarly observations using existing
# schema and registries.
echo '--- Phase 32 eclipse research generalization (first run) ---'
run "$root/tests/fixtures/141-phase32-eclipse-research-generalization-fixture.sql"
run "$root/tests/validation/phase32-eclipse-research-generalization-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 32 eclipse research generalization (second run, determinism/idempotency) ---'
run "$root/tests/fixtures/141-phase32-eclipse-research-generalization-fixture.sql"
run "$root/tests/validation/phase32-eclipse-research-generalization-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 33 separates acquisition from interrogation. Stage A is an independently keyed,
# source-driven population of the bounded 1919 eclipse domain that contains no research question
# and no expected answer. Stage B introduces the withheld questions afterwards and answers them by
# read-only traversal of the persisted substrate. Both stages replay twice: the population must not
# create duplicates and the queries must not change persistent counts.
echo '--- Phase 33 eclipse population and independent research (first run) ---'
run "$root/tests/fixtures/142-phase33-eclipse-domain-population-fixture.sql"
run "$root/tests/validation/phase33-eclipse-domain-population-validation.sql"
run "$root/tests/validation/phase33-eclipse-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 33 eclipse population and independent research (second run) ---'
run "$root/tests/fixtures/142-phase33-eclipse-domain-population-fixture.sql"
run "$root/tests/validation/phase33-eclipse-domain-population-validation.sql"
run "$root/tests/validation/phase33-eclipse-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 34 reuses the persisted Phase 33 eclipse substrate and validates natural-language
# scholarly-question interpretation into normalized, deterministic, capability-bounded
# BEREAN_ONLY query plans and bounded read-only answer retrieval. No schema or fixture changes.
echo '--- Phase 34 natural-language scholarly query interpretation (first run) ---'
run "$root/tests/validation/phase34-query-plan-validation.sql"
run "$root/tests/validation/phase34-natural-language-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 34 natural-language scholarly query interpretation (second run) ---'
run "$root/tests/validation/phase34-query-plan-validation.sql"
run "$root/tests/validation/phase34-natural-language-query-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 35 reuses the persisted Phase 30-31 Genesis substrate and the persisted Phase 32-33 eclipse
# substrate without repopulating either, and drives both through one generic semantic interpreter.
# It proves that natural-language interrogation generalizes across independently populated domains:
# plans stay domain-neutral, materially different wordings normalize identically, capability checks
# precede retrieval, and interrogation stays read-only and deterministic.
echo '--- Phase 35 cross-domain natural-language research (first run) ---'
run "$root/tests/validation/phase35-query-plan-validation.sql"
run "$root/tests/validation/phase35-cross-domain-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 35 cross-domain natural-language research (second run) ---'
run "$root/tests/validation/phase35-query-plan-validation.sql"
run "$root/tests/validation/phase35-cross-domain-query-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 36 repeats the independent two-stage lifecycle for a new, bounded historical domain.
# Population stays question-free; later read-only interrogation traverses only persisted substrate.
echo '--- Phase 36 repeatable Seneca Falls domain lifecycle (first run) ---'
run "$root/tests/fixtures/143-phase36-seneca-falls-domain-population-fixture.sql"
run "$root/tests/validation/phase36-seneca-falls-domain-population-validation.sql"
run "$root/tests/validation/phase36-seneca-falls-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo '--- Phase 36 repeatable Seneca Falls domain lifecycle (second run) ---'
run "$root/tests/fixtures/143-phase36-seneca-falls-domain-population-fixture.sql"
run "$root/tests/validation/phase36-seneca-falls-domain-population-validation.sql"
run "$root/tests/validation/phase36-seneca-falls-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 37 repeats the independent two-stage lifecycle for a new, bounded historical domain: the
# 1893 World's Columbian Exposition. Population stays question-free; later read-only interrogation
# traverses only persisted substrate to derive previously unstored multi-hop relationships.
echo "--- Phase 37 World's Columbian Exposition independent research lifecycle (first run) ---"
run "$root/tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql"
run "$root/tests/validation/phase37-worlds-columbian-exposition-population-validation.sql"
run "$root/tests/validation/phase37-worlds-columbian-exposition-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo "--- Phase 37 World's Columbian Exposition independent research lifecycle (second run) ---"
run "$root/tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql"
run "$root/tests/validation/phase37-worlds-columbian-exposition-population-validation.sql"
run "$root/tests/validation/phase37-worlds-columbian-exposition-independent-query-validation.sql"
run "$root/scripts/validation/validate.sql"

# Phase 37R/37B preserves Phase 37 and independently expands the same domain from an auditable,
# discovery-driven candidate review. Stage A remains question-free; Stage B introduces the withheld
# synthesis prompt and tests established, derived, scholarly, unresolved, and absent boundaries.
"$root/tests/validation/phase37r-candidate-audit-validation.sh"
echo "--- Phase 37R/37B expanded exposition lifecycle (first run) ---"
run "$root/tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql"
run "$root/tests/validation/phase37r-worlds-columbian-exposition-population-validation.sql"
run "$root/tests/validation/phase37b-worlds-columbian-exposition-withheld-query-validation.sql"
run "$root/scripts/validation/validate.sql"
echo "--- Phase 37R/37B expanded exposition lifecycle (second run) ---"
run "$root/tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql"
run "$root/tests/validation/phase37r-worlds-columbian-exposition-population-validation.sql"
run "$root/tests/validation/phase37b-worlds-columbian-exposition-withheld-query-validation.sql"
run "$root/scripts/validation/validate.sql"

run "$root/tests/fixtures/030-negative-integrity-fixture.sql"
run "$root/scripts/validation/validate.sql"
"$root/tests/validation/blocking-cases.sh"
