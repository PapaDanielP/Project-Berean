#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/tests/validation/phase18-ark-transport-slice.sql" >/dev/null 2>&1
    then
        echo "FAIL: Phase 18 validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: Phase 18 blocked ${description}"
    fi
}

# 1. Standing requirement represented as a transport event.
expect_blocking "standing requirement represented as a transport event" \
    "UPDATE event SET event_type_code = 'OTHER'
     WHERE event_key = 'ark_covenant_pole_standing_requirement'"

# 2. Transport fabricated solely from the standing requirement.
expect_blocking "transport fabricated solely from the standing requirement" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'participatesIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'priests_levites_ark_bearers'
       AND ev.event_key = 'ark_covenant_pole_standing_requirement';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE18_TRANSPORT_FROM_REQUIREMENT', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'participatesIn'
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_covenant_pole_standing_requirement')"

# 3. Compliance inferred solely from the standing requirement.
expect_blocking "compliance inferred solely from the standing requirement" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE18_INFERRED_COMPLIANCE', proposition_id, 'INTERPRETIVE_CLAIM',
            'The priests carried the ark in compliance with the standing requirement.'
     FROM proposition WHERE predicate = 'standingRequirementIn' LIMIT 1"

# 4. Participant fabricated without evidence.
expect_blocking "participant fabricated without evidence" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase18_fabricated_kohathites', 'ORGANIZATION', 'fabricated unlisted carrier');
     INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'participatesIn', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'phase18_fabricated_kohathites'
       AND ev.event_key = 'ark_covenant_transport_jordan';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE18_FABRICATED_PARTICIPANT', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'participatesIn'
       AND subject_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'phase18_fabricated_kohathites')"

# 5. Transport claim without ClaimEvidence.
expect_blocking "transport claim without ClaimEvidence" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE18_TRANSPORT_NO_EVIDENCE', p.proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition p
     JOIN event ev ON ev.event_id = p.object_event_id
     WHERE ev.event_key = 'ark_covenant_transport_jordan' LIMIT 1"

# 6. Evidence without citation.
expect_blocking "evidence without citation" \
    "INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
     SELECT 'EV_PHASE18_NO_CITATION', sr.source_record_id, 'fabricated observation with no citation', 'SOURCE_OBSERVATION'
     FROM source_record sr WHERE sr.source_record_key = 'MT_JOS_3_6';
     INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
     SELECT c.claim_id, ev.evidence_id, 'SUPPORTS'
     FROM claim c, evidence ev
     WHERE c.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN' AND ev.evidence_key = 'EV_PHASE18_NO_CITATION'"

# 7. Fabricated source text/hash/quotation.
expect_blocking "fabricated source text, hash, or quotation for Joshua 3:6" \
    "UPDATE source_record SET raw_content = 'fabricated text', content_hash = repeat('a', 64)
     WHERE source_record_key = 'MT_JOS_3_6'"

# 8. Unsupported transport predicate.
expect_blocking "unsupported transport predicate" \
    "INSERT INTO predicate (predicate_code, description, subject_kind_code, object_kind_code, event_participation_role_code)
     VALUES ('transportedBy', 'fabricated unregistered predicate', 'ENTITY', 'EVENT', 'PARTICIPANT');
     INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT e.entity_id, 'transportedBy', ev.event_id
     FROM entity e, event ev
     WHERE e.entity_key = 'priests_levites_ark_bearers' AND ev.event_key = 'ark_covenant_transport_jordan';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE18_UNSUPPORTED_PREDICATE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE predicate = 'transportedBy'"

# 9. Direct participant-table insertion bypassing propositions.
expect_blocking "direct participant-table insertion" \
    "CREATE TABLE artifact_transport (entity_id bigint, event_id bigint, role text)"

# 10. Duplicate Ark entity.
expect_blocking "duplicate Ark entity" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase18_duplicate_ark', 'OBJECT', 'Ark of the Covenant')"

# 11. Duplicate pole/ring entity.
expect_blocking "duplicate pole/ring entity" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase18_duplicate_poles', 'OBJECT', 'poles of the ark')"

# 12. Unjustified source reconciliation.
expect_blocking "unjustified source reconciliation" \
    "INSERT INTO source_identity (source_id, source_identity_key, display_name)
     SELECT source_id, 'phase18-no-evidence-identity', 'unsupported identity'
     FROM source WHERE source_key = 'JOS_MT';
     INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
     SELECT si.source_identity_id, e.entity_id, 'ACTIVE', 0.99, 'no evidence', NULL
     FROM source_identity si, entity e
     WHERE si.source_identity_key = 'phase18-no-evidence-identity'
       AND e.entity_key = 'priests_levites_ark_bearers'"

# 13. Derived compliance claim without DerivationInput.
expect_blocking "derived compliance claim without DerivationInput" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase18 test', 'phase18 test');
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE18_DERIVED_NO_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p
     JOIN event ev ON ev.event_id = p.object_event_id
     CROSS JOIN derivation d
     WHERE ev.event_key = 'ark_covenant_transport_jordan'
     ORDER BY d.derivation_id DESC LIMIT 1"

# 14. Derived claim used as its own input.
expect_blocking "derived claim used as its own input" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase18 self-input test', 'phase18 self-input test');
     WITH new_claim AS (
         INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
         SELECT 'PHASE18_DERIVED_SELF_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
         FROM proposition p
         JOIN event ev ON ev.event_id = p.object_event_id
         CROSS JOIN derivation d
         WHERE ev.event_key = 'ark_covenant_transport_jordan'
         ORDER BY d.derivation_id DESC LIMIT 1
         RETURNING claim_id, derivation_id
     )
     INSERT INTO derivation_input (derivation_id, input_claim_id)
     SELECT derivation_id, claim_id FROM new_claim"

# 15. Transport event incorrectly typed as INSTRUCTION.
expect_blocking "transport event incorrectly typed as INSTRUCTION" \
    "UPDATE event SET event_type_code = 'INSTRUCTION' WHERE event_key = 'ark_covenant_transport_jordan'"

# 16. Transport event incorrectly typed as STANDING_REQUIREMENT.
expect_blocking "transport event incorrectly typed as STANDING_REQUIREMENT" \
    "UPDATE event SET event_type_code = 'STANDING_REQUIREMENT' WHERE event_key = 'ark_covenant_transport_jordan'"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
echo "All Phase 18 ark-transport-slice corruption cases passed."
