#!/usr/bin/env sh
# Asserts that scripts/validation/validate.sql actually blocks. Each case injects one
# defect inside a transaction that is never committed, so the database is left unchanged.
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/scripts/validation/validate.sql" >/dev/null 2>&1
    then
        echo "FAIL: validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: blocked ${description}"
    fi
}

expect_clean() {
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -f "$root/scripts/validation/validate.sql" >/dev/null 2>&1
    then
        echo "ok: loaded fixture data passes validation"
    else
        echo "FAIL: loaded fixture data does not pass validation"
        failures=$((failures + 1))
    fi
}

expect_clean

expect_blocking "a claim with no evidence" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
     SELECT a.entity_id, 'siblingOf', b.entity_id FROM entity a CROSS JOIN entity b
     WHERE a.entity_id <> b.entity_id LIMIT 1;
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'UNSUPPORTED_CLAIM', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'siblingOf'"

expect_blocking "source-observation evidence with no citation" \
    "DELETE FROM evidence_citation WHERE evidence_id = (SELECT min(evidence_id) FROM evidence)"

expect_blocking "an active reconciliation with no justification" \
    "UPDATE entity_source_mapping SET justification = NULL WHERE mapping_status_code = 'ACTIVE'"

expect_blocking "reconciliation justified by evidence from another source" \
    "UPDATE entity_source_mapping esm
     SET supporting_evidence_id = (
        SELECT e.evidence_id FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.source_id <> (SELECT si.source_id FROM source_identity si
                              WHERE si.source_identity_id = esm.source_identity_id)
        LIMIT 1)
     WHERE esm.mapping_status_code = 'ACTIVE'"

expect_blocking "a derivation with no inputs" \
    "DELETE FROM derivation_input"

expect_blocking "a derived claim used as its own derivation input" \
    "INSERT INTO derivation_input (derivation_id, input_claim_id)
     SELECT c.derivation_id, c.claim_id FROM claim c WHERE c.derivation_id IS NOT NULL LIMIT 1"

if [ "$failures" -ne 0 ]; then
    echo "${failures} validation self-test case(s) failed."
    exit 1
fi
echo "All validation self-test cases passed."
