#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?Set DATABASE_URL to a PostgreSQL database URL.}"
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
failures=0

expect_blocking() {
    description="$1"
    injection="$2"
    if psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 \
        -c "BEGIN; ${injection};" -f "$root/tests/validation/phase19-ark-lifecycle-conflict-slice.sql" >/dev/null 2>&1
    then
        echo "FAIL: Phase 19 validation did not block: ${description}"
        failures=$((failures + 1))
    else
        echo "ok: Phase 19 blocked ${description}"
    fi
}

# 1. Inferring Uzzah violated Exodus 25:15 without source-backed basis.
expect_blocking "Uzzah violation of Exodus 25:15 inferred without source-backed basis" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE19_UZZAH_VIOLATED_EXODUS_REQUIREMENT', proposition_id, 'INTERPRETIVE_CLAIM',
            'Uzzah violated Exodus 25:15.'
     FROM proposition WHERE predicate = 'standingRequirementIn' LIMIT 1;
     INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
     SELECT c.claim_id, ev.evidence_id, 'SUPPORTS'
     FROM claim c, evidence ev
     WHERE c.claim_key = 'PHASE19_UZZAH_VIOLATED_EXODUS_REQUIREMENT' AND ev.evidence_key = 'EV_MT_2SA_6_6'"

# 2. Contradiction solely because transport methods differ.
expect_blocking "contradiction solely because Joshua carrying and 2 Samuel cart transport differ" \
    "INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
     SELECT a.claim_id, b.claim_id, 'CONTRADICTS', 'fabricated contradiction from different transport methods'
     FROM claim a, claim b
     WHERE a.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN'
       AND b.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'"

# 3. ClaimRelation without valid underlying claims (schema FK blocks this directly).
expect_blocking "ClaimRelation without valid underlying claims" \
    "INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code)
     VALUES (999999999, 999999998, 'CONTRADICTS')"

# 4. ClaimRelation without preserving both source-backed claims.
expect_blocking "ClaimRelation without preserving both source-backed claims" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE19_UNBACKED_RELATION_CLAIM', proposition_id, 'DIRECT_SOURCE_CLAIM', 'unbacked relation target'
     FROM proposition LIMIT 1;
     INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code)
     SELECT a.claim_id, b.claim_id, 'CONTRADICTS'
     FROM claim a, claim b
     WHERE a.claim_key = 'PHASE19_UNBACKED_RELATION_CLAIM'
       AND b.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'"

# 5. Claim without ClaimEvidence.
expect_blocking "claim without ClaimEvidence" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE19_CLAIM_WITHOUT_EVIDENCE', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition p JOIN event ev ON ev.event_id = p.object_event_id
     WHERE ev.event_key = 'ark_covenant_transport_new_cart_2sam6' LIMIT 1"

# 6. Evidence without Citation.
expect_blocking "evidence without Citation" \
    "INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
     SELECT 'EV_PHASE19_WITHOUT_CITATION', source_record_id, 'uncited phase19 observation', 'SOURCE_OBSERVATION'
     FROM source_record WHERE source_record_key = 'MT_2SA_6_6';
     INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
     SELECT c.claim_id, ev.evidence_id, 'SUPPORTS'
     FROM claim c, evidence ev
     WHERE c.claim_key = 'CLAIM_UZZAH_PARTICIPANT_INTERACTION_2SAM6'
       AND ev.evidence_key = 'EV_PHASE19_WITHOUT_CITATION'"

# 7. Fabricated Scripture text/hash/quotation.
expect_blocking "fabricated Scripture text, hash, or quotation" \
    "UPDATE source_record SET raw_content = 'fabricated 2 Samuel text', content_hash = repeat('a', 64)
     WHERE source_record_key = 'MT_2SA_6_6'"

# 8. Duplicate canonical Ark.
expect_blocking "duplicate canonical Ark" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase19_duplicate_ark', 'OBJECT', 'Ark of the Covenant')"

# 9. Duplicate Uzzah.
expect_blocking "duplicate Uzzah" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase19_duplicate_uzzah', 'PERSON', 'Uzzah')"

# 10. Unsupported participant.
expect_blocking "unsupported participant in 2 Samuel transport" \
    "INSERT INTO entity (entity_key, entity_type_code, canonical_name)
     VALUES ('phase19_unsupported_ahio', 'PERSON', 'Ahio');
     INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT en.entity_id, 'participatesIn', ev.event_id
     FROM entity en, event ev
     WHERE en.entity_key = 'phase19_unsupported_ahio'
       AND ev.event_key = 'ark_covenant_transport_new_cart_2sam6';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE19_UNSUPPORTED_PARTICIPANT', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE subject_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'phase19_unsupported_ahio')"

# 11. Fabricated pole/ring physical state.
expect_blocking "fabricated pole/ring physical state" \
    "INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
     SELECT en.entity_id, 'participatesIn', ev.event_id
     FROM entity en, event ev
     WHERE en.entity_key = 'poles_ark_covenant'
       AND ev.event_key = 'ark_covenant_transport_new_cart_2sam6';
     INSERT INTO claim (claim_key, proposition_id, claim_type_code)
     SELECT 'PHASE19_POLE_STATE_FABRICATED', proposition_id, 'DIRECT_SOURCE_CLAIM'
     FROM proposition WHERE subject_entity_id = (SELECT entity_id FROM entity WHERE entity_key = 'poles_ark_covenant')
       AND object_event_id = (SELECT event_id FROM event WHERE event_key = 'ark_covenant_transport_new_cart_2sam6')"

# 12. Fabricated causal relationship.
expect_blocking "fabricated causal relationship" \
    "INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
     SELECT 'PHASE19_CAUSE_UZZAH_DEATH', proposition_id, 'INTERPRETIVE_CLAIM',
            'Uzzah touching the Ark caused his death.'
     FROM proposition p JOIN event ev ON ev.event_id = p.object_event_id
     WHERE ev.event_key = 'uzzah_death_2sam6' LIMIT 1;
     INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
     SELECT c.claim_id, ev.evidence_id, 'SUPPORTS'
     FROM claim c, evidence ev
     WHERE c.claim_key = 'PHASE19_CAUSE_UZZAH_DEATH' AND ev.evidence_key = 'EV_MT_2SA_6_7'"

# 13. Derived claim without DerivationInput.
expect_blocking "derived claim without DerivationInput" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase19 test', 'phase19 test');
     INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
     SELECT 'PHASE19_DERIVED_NO_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
     FROM proposition p
     JOIN event ev ON ev.event_id = p.object_event_id
     CROSS JOIN derivation d
     WHERE ev.event_key = 'uzzah_death_2sam6'
     ORDER BY d.derivation_id DESC LIMIT 1"

# 14. Derived claim used as its own input.
expect_blocking "derived claim used as its own input" \
    "INSERT INTO derivation (method, assumptions) VALUES ('phase19 self-input test', 'phase19 self-input test');
     WITH new_claim AS (
         INSERT INTO claim (claim_key, proposition_id, claim_type_code, derivation_id)
         SELECT 'PHASE19_DERIVED_SELF_INPUT', p.proposition_id, 'DERIVED_CLAIM', d.derivation_id
         FROM proposition p
         JOIN event ev ON ev.event_id = p.object_event_id
         CROSS JOIN derivation d
         WHERE ev.event_key = 'uzzah_death_2sam6'
         ORDER BY d.derivation_id DESC LIMIT 1
         RETURNING claim_id, derivation_id
     )
     INSERT INTO derivation_input (derivation_id, input_claim_id)
     SELECT derivation_id, claim_id FROM new_claim"

# 15. Direct event_participation insertion (view blocks this directly).
expect_blocking "direct event_participation insertion" \
    "INSERT INTO event_participation (event_id, entity_id, role_code, asserting_claim_id)
     SELECT ev.event_id, en.entity_id, 'PARTICIPANT', c.claim_id
     FROM event ev, entity en, claim c
     WHERE ev.event_key = 'ark_covenant_transport_new_cart_2sam6'
       AND en.entity_key = 'poles_ark_covenant'
       AND c.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'"

# 16. Arbitrary JSON artifact semantics.
expect_blocking "arbitrary JSON artifact semantics" \
    "CREATE TABLE artifact_json_semantics (entity_id bigint, payload jsonb)"

# 17. Unsupported predicate/event type.
expect_blocking "unsupported predicate/event type" \
    "INSERT INTO event_type (event_type_code, description) VALUES ('TRANSPORT', 'fabricated transport type');
     INSERT INTO predicate (predicate_code, description, subject_kind_code, object_kind_code, event_participation_role_code)
     VALUES ('touched', 'fabricated touch predicate', 'ENTITY', 'EVENT', 'PARTICIPANT')"

# 18. Unjustified SourceIdentity/EntitySourceMapping.
expect_blocking "unjustified SourceIdentity/EntitySourceMapping" \
    "INSERT INTO source_identity (source_id, source_identity_key, display_name)
     SELECT source_id, 'mt-ark-2sam6-unsupported', 'the ark'
     FROM source WHERE source_key = '2SA_MT';
     INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
     SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.99, 'unsupported duplicate ark mapping', NULL
     FROM source_identity si, entity en
     WHERE si.source_identity_key = 'mt-ark-2sam6-unsupported'
       AND en.entity_key = 'ark_of_covenant'"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
echo "All Phase 19 ark-lifecycle-conflict corruption cases passed."
