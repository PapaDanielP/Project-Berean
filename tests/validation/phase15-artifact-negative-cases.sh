#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/tests/validation/phase15-artifact-semantics.sql" >/dev/null 2>&1
    then
        echo "FAIL: Phase 15 validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: Phase 15 blocked ${description}"
    fi
}

expect_blocking "duplicate canonical artifact" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('duplicate_noahs_ark', 'OBJECT', 'Noah''s Ark')"
expect_blocking "artifact claim without evidence" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE15_NO_EVIDENCE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition p JOIN entity e ON e.entity_id = p.subject_entity_id
     WHERE e.entity_key = 'noahs_ark' LIMIT 1"
expect_blocking "fabricated source text, quotation, or hash" \
    "UPDATE source_record SET raw_content = 'fabricated', content_hash = repeat('a', 64)
     WHERE source_record_key = 'MT_GEN_8_4'"
expect_blocking "unsupported fabricated dimension" \
    "INSERT INTO predicate (predicate_code, description, subject_kind_code, object_kind_code)
     VALUES ('length', 'fabricated artifact dimension', 'ENTITY', 'VALUE');
     INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 300);
     INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
     SELECT e.entity_id, 'length', tv.typed_value_id FROM entity e CROSS JOIN typed_value tv
     WHERE e.entity_key = 'noahs_ark' ORDER BY tv.typed_value_id DESC LIMIT 1;
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE15_FABRICATED_LENGTH', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'length' ORDER BY proposition_id DESC LIMIT 1"
expect_blocking "direct chronology claim that must be derived" \
    "INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('YEAR', 1);
     INSERT INTO proposition (subject_event_id, predicate, object_typed_value_id)
     SELECT ev.event_id, 'yearsFromCreation', tv.typed_value_id FROM event ev CROSS JOIN typed_value tv
     WHERE ev.event_key = 'ark_resting' ORDER BY tv.typed_value_id DESC LIMIT 1;
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE15_DIRECT_CHRONOLOGY', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'yearsFromCreation' ORDER BY proposition_id DESC LIMIT 1"
expect_blocking "derived artifact claim without inputs" \
    "INSERT INTO derivation (method, assumptions) VALUES ('test', 'test');
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE15_DERIVED_NO_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p CROSS JOIN derivation d JOIN entity e ON e.entity_id = p.subject_entity_id
     WHERE e.entity_key = 'noahs_ark' ORDER BY d.derivation_id DESC LIMIT 1"
expect_blocking "wrong source identity mapping" \
    "UPDATE entity_source_mapping SET entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'ark_of_covenant')
     WHERE source_identity_id = (SELECT source_identity_id FROM source_identity WHERE source_identity_key = 'mt-ark')"
expect_blocking "direct event-participation bypass" \
    "CREATE TABLE event_participant (entity_id bigint, event_id bigint)"
expect_blocking "arbitrary JSON semantic payload" \
    "ALTER TABLE entity ADD COLUMN artifact_payload jsonb"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
echo "All Phase 15 artifact corruption cases passed."
