#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/tests/validation/phase16-artifact-construction-slice.sql" >/dev/null 2>&1
    then
        echo "FAIL: Phase 16 validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: Phase 16 blocked ${description}"
    fi
}

expect_blocking "artifact claim without evidence" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_NO_EVIDENCE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition p JOIN entity e ON e.entity_id = p.subject_entity_id
     WHERE e.entity_key = 'ark_of_covenant' LIMIT 1"

expect_blocking "dimension without unit (bare 'length' predicate)" \
    "INSERT INTO predicate (predicate_code, description, subject_kind_code, object_kind_code)
     VALUES ('length', 'fabricated unitless dimension', 'ENTITY', 'VALUE');
     INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 2.5);
     INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
     SELECT e.entity_id, 'length', tv.typed_value_id FROM entity e CROSS JOIN typed_value tv
     WHERE e.entity_key = 'ark_of_covenant' ORDER BY tv.typed_value_id DESC LIMIT 1;
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_UNITLESS_LENGTH', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'length' ORDER BY proposition_id DESC LIMIT 1"

expect_blocking "fabricated modern-unit conversion" \
    "INSERT INTO derivation (method, assumptions) VALUES ('cubit-to-meter conversion', 'assumed 1 cubit = 0.4572 m');
     INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 137.16);
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE16_LENGTH_METER_CONVERSION', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p CROSS JOIN derivation d
     JOIN entity e ON e.entity_id = p.subject_entity_id
     WHERE e.entity_key = 'noahs_ark' AND p.predicate = 'lengthCubits'
     ORDER BY d.derivation_id DESC LIMIT 1"

expect_blocking "unsupported fabricated material" \
    "WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'unsupported fabricated bronze') RETURNING typed_value_id)
     INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
     SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_FABRICATED_MATERIAL', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'madeOfMaterial'
     ORDER BY proposition_id DESC LIMIT 1"

expect_blocking "unsupported fabricated component" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('fabricated_ark_component', 'OBJECT', 'fabricated ark component');
     INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
     SELECT s.entity_id, 'hasComponent', o.entity_id
     FROM entity s, entity o
     WHERE s.entity_key = 'noahs_ark' AND o.entity_key = 'fabricated_ark_component';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_FABRICATED_COMPONENT', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'hasComponent'
       AND object_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'fabricated_ark_component')"

expect_blocking "unsupported fabricated content" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('fabricated_ark_content', 'OBJECT', 'fabricated ark content');
     INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
     SELECT s.entity_id, 'containsContent', o.entity_id
     FROM entity s, entity o
     WHERE s.entity_key = 'noahs_ark' AND o.entity_key = 'fabricated_ark_content';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_FABRICATED_CONTENT', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'containsContent'
       AND object_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'fabricated_ark_content')"

expect_blocking "unsupported fabricated builder" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('fabricated_builder', 'PERSON', 'fabricated builder');
     INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT s.entity_id, 'builderIn', ev.event_id
     FROM entity s, event ev
     WHERE s.entity_key = 'fabricated_builder' AND ev.event_key = 'ark_construction_completed';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_FABRICATED_BUILDER', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'builderIn'
       AND subject_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'fabricated_builder')"

expect_blocking "instruction represented as completed construction" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'builderIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'noah' AND ev.event_key = 'ark_building_instruction';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE16_INSTRUCTION_AS_CONSTRUCTION', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'builderIn'
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_building_instruction')"

expect_blocking "arbitrary JSON semantic payload" \
    "ALTER TABLE entity ADD COLUMN artifact_payload jsonb"

expect_blocking "direct participant-table insertion bypass" \
    "CREATE TABLE artifact_participation (entity_id bigint, event_id bigint)"

expect_blocking "unjustified reconciliation (mapping ark_of_covenant identity to noahs_ark)" \
    "UPDATE entity_source_mapping SET entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'noahs_ark')
     WHERE source_identity_id = (SELECT source_identity_id FROM source_identity WHERE source_identity_key = 'mt-ark-covenant')"

expect_blocking "mapping without evidence" \
    "INSERT INTO source_identity (source_id, source_identity_key, display_name)
     SELECT source_id, 'phase16-no-evidence-identity', 'unsupported identity'
     FROM source WHERE source_key = 'EXO_MT';
     INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
     SELECT si.source_identity_id, e.entity_id, 'ACTIVE', 0.99, 'no evidence', NULL
     FROM source_identity si, entity e
     WHERE si.source_identity_key = 'phase16-no-evidence-identity' AND e.entity_key = 'ark_of_covenant'"

expect_blocking "derived claim without derivation inputs" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase16 test', 'phase16 test');
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE16_DERIVED_NO_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p CROSS JOIN derivation d
     JOIN entity e ON e.entity_id = p.subject_entity_id
     WHERE e.entity_key = 'ark_of_covenant' ORDER BY d.derivation_id DESC LIMIT 1"

expect_blocking "derived claim used as its own derivation input" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase16 self-input test', 'phase16 self-input test');
     WITH new_claim AS (
         INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
         SELECT 'PHASE16_SELF_INPUT_DERIVED', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
         FROM proposition p CROSS JOIN derivation d
         JOIN entity e ON e.entity_id = p.subject_entity_id
         WHERE e.entity_key = 'ark_of_covenant' AND d.method = 'phase16 self-input test'
         ORDER BY d.derivation_id DESC LIMIT 1
         RETURNING claim_id, derivation_id
     )
     INSERT INTO derivation_input (derivation_id, input_claim_id)
     SELECT derivation_id, claim_id FROM new_claim"

expect_blocking "fabricated source text, hash, or quotation" \
    "UPDATE source_record SET raw_content = 'fabricated text', content_hash = repeat('a', 64)
     WHERE source_record_key = 'MT_EXO_37_1'"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
echo "All Phase 16 artifact corruption cases passed."
