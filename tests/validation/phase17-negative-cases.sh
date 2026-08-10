#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/tests/validation/phase17-standing-requirement-slice.sql" >/dev/null 2>&1
    then
        echo "FAIL: Phase 17 validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: Phase 17 blocked ${description}"
    fi
}

expect_blocking "standing requirement represented as completed construction (builderIn against the STANDING_REQUIREMENT event)" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'builderIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'poles_ark_covenant' AND ev.event_key = 'ark_covenant_pole_standing_requirement';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE17_STANDING_AS_CONSTRUCTION', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'builderIn'
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_covenant_pole_standing_requirement')"

expect_blocking "historical participatesIn fabricated solely from the standing requirement" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'participatesIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'poles_ark_covenant' AND ev.event_key = 'ark_covenant_pole_standing_requirement';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE17_FABRICATED_PARTICIPATION', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'participatesIn'
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_covenant_pole_standing_requirement')"

expect_blocking "standingRequirementIn misapplied to a CONSTRUCTION event" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'standingRequirementIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'poles_ark_covenant' AND ev.event_key = 'ark_covenant_construction';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE17_STANDING_ON_CONSTRUCTION', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'standingRequirementIn'
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_covenant_construction')"

expect_blocking "claim without evidence" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE17_NO_EVIDENCE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'standingRequirementIn' LIMIT 1"

expect_blocking "evidence without a citation" \
    "INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
     SELECT 'EV_PHASE17_NO_CITATION', sr.source_record_id, 'fabricated observation with no citation', 'SOURCE_OBSERVATION'
     FROM source_record sr WHERE sr.source_record_key = 'MT_EXO_25_15';
     INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
     SELECT c.claim_id, ev.evidence_id, 'SUPPORTS'
     FROM claim c, evidence ev
     WHERE c.claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT' AND ev.evidence_key = 'EV_PHASE17_NO_CITATION'"

expect_blocking "fabricated source text, hash, or quotation for Exodus 25:15" \
    "UPDATE source_record SET raw_content = 'fabricated text', content_hash = repeat('a', 64)
     WHERE source_record_key = 'MT_EXO_25_15'"

expect_blocking "compliance/non-removal inferred from the standing requirement" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE17_INFERRED_COMPLIANCE', proposition_id, 'INTERPRETIVE_CLAIM',
            'The poles remained in the rings and were never removed.'
     FROM proposition WHERE predicate = 'standingRequirementIn' LIMIT 1"

expect_blocking "transport/completed-event historical claim fabricated from the requirement" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE17_FABRICATED_TRANSPORT', proposition_id, 'INTERPRETIVE_CLAIM',
            'The ark was transported using the poles.'
     FROM proposition WHERE predicate = 'standingRequirementIn' LIMIT 1"

expect_blocking "arbitrary JSON artifact-property payload" \
    "ALTER TABLE entity ADD COLUMN requirement_payload jsonb"

expect_blocking "direct participant/requirement table bypassing propositions" \
    "CREATE TABLE artifact_requirement (entity_id bigint, event_id bigint, requirement_text text)"

expect_blocking "unsupported fabricated predicate for the standing requirement" \
    "INSERT INTO predicate (predicate_code, description, subject_kind_code, object_kind_code)
     VALUES ('mustRemainIn', 'fabricated unregistered predicate', 'ENTITY', 'EVENT');
     INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'mustRemainIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'rings_ark_covenant' AND ev.event_key = 'ark_covenant_pole_standing_requirement';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE17_UNSUPPORTED_PREDICATE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'mustRemainIn'"

expect_blocking "unjustified reconciliation (new source identity for poles_ark_covenant without evidence)" \
    "INSERT INTO source_identity (source_id, source_identity_key, display_name)
     SELECT source_id, 'phase17-no-evidence-identity', 'unsupported identity'
     FROM source WHERE source_key = 'EXO_MT';
     INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
     SELECT si.source_identity_id, e.entity_id, 'ACTIVE', 0.99, 'no evidence', NULL
     FROM source_identity si, entity e
     WHERE si.source_identity_key = 'phase17-no-evidence-identity' AND e.entity_key = 'poles_ark_covenant'"

expect_blocking "derived claim without derivation inputs" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase17 test', 'phase17 test');
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE17_DERIVED_NO_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p CROSS JOIN derivation d
     WHERE p.predicate = 'standingRequirementIn'
     ORDER BY d.derivation_id DESC LIMIT 1"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
echo "All Phase 17 standing-requirement corruption cases passed."
