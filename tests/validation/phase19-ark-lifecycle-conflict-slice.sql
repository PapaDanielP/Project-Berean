\set ON_ERROR_STOP on

-- Phase 19 validates the bounded 2 Samuel 6:3-7 Ark lifecycle slice without extending the
-- registry or collapsing source observation into interpretation, compliance, causation, or
-- contradiction.
DO $$
DECLARE
    phase_claim_keys text[] := ARRAY[
        'CLAIM_ARK_COVENANT_SUBJECT_NEW_CART_TRANSPORT_2SAM6',
        'CLAIM_NEW_CART_PARTICIPANT_ARK_TRANSPORT_2SAM6',
        'CLAIM_UZZAH_PARTICIPANT_ARK_TRANSPORT_2SAM6',
        'CLAIM_UZZAH_SUBJECT_ARK_INTERACTION_2SAM6',
        'CLAIM_ARK_COVENANT_PARTICIPANT_UZZAH_INTERACTION_2SAM6',
        'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6'
    ];
BEGIN
    -- 1. Exact locator and source/citation integrity for the bounded 2 Samuel 6:3-7 slice.
    IF (SELECT count(*) FROM source WHERE source_key = '2SA_MT') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one 2SA_MT source';
    END IF;

    IF (SELECT count(*) FROM dataset WHERE dataset_key = '2SA_MT_REF') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one 2SA_MT_REF dataset';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = '2SA_MT_REF'
          AND sr.source_record_key = 'MT_2SA_6_3_7'
          AND sr.source_location = '2 Samuel 6:3-7'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one source locator for 2 Samuel 6:3-7';
    END IF;

    IF (
        SELECT count(*) FROM source_record
        WHERE dataset_id = (SELECT dataset_id FROM dataset WHERE dataset_key = '2SA_MT_REF')
    ) <> 1 THEN
        RAISE EXCEPTION 'phase19: forbids unintended 2 Samuel locators outside 2 Samuel 6:3-7';
    END IF;

    IF EXISTS (
        SELECT 1 FROM source_record sr
        WHERE sr.source_record_key = 'MT_2SA_6_3_7'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated raw_content or content_hash for 2 Samuel 6:3-7';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = 'MT_2SA_6_3_7'
          AND ci.citation_key = 'CITE_MT_2SA_6_3_7'
          AND ci.locator = sr.source_location
          AND ci.quoted_text IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase19: expected one matching unquoted citation for 2 Samuel 6:3-7';
    END IF;

    -- 2. Registry sufficiency: Phase 19 adds no event_type, predicate, role, JSON payload, or
    --    artifact/lifecycle/participant-specific table.
    IF (
        SELECT count(*) FROM event_type
    ) <> (SELECT count(*) FROM event_type WHERE event_type_code IN (
          'BIRTH', 'DEATH', 'GENEALOGICAL', 'CHRONOLOGICAL', 'OTHER',
          'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT'
    )) THEN
        RAISE EXCEPTION 'phase19: forbids new event_type rows such as TRANSPORT, CONSEQUENCE, or HANDLING';
    END IF;

    IF (
        SELECT count(*) FROM predicate
    ) <> (SELECT count(*) FROM predicate WHERE predicate_code IN (
          'fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt', 'precedes',
          'participatesIn', 'subjectOf', 'parentIn', 'childIn', 'builderIn',
          'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation',
          'lengthCubits', 'widthCubits', 'heightCubits', 'madeOfMaterial',
          'overlaidWithMaterial', 'hasComponent', 'containsContent', 'standingRequirementIn'
    )) THEN
        RAISE EXCEPTION 'phase19: forbids new predicates such as transportedOn, touched, causeOf, violatedRequirement, or complianceWith';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('artifact_transport', 'transport', 'carrier', 'transport_event',
                             'artifact_lifecycle', 'artifact_state', 'artifact_property',
                             'artifact_relationship', 'event_participant', 'participant',
                             'event_participation_store', 'object', 'thing', 'cart')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids artifact/transport/lifecycle-specific tables';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name IN ('entity', 'proposition', 'claim', 'event')
          AND data_type IN ('json', 'jsonb')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids arbitrary JSON artifact semantics';
    END IF;

    -- 3. Entity integrity: one canonical Ark, existing poles/rings reused, exactly one Uzzah and
    --    one new cart entity; no duplicate or unsupported participants.
    IF (SELECT count(*) FROM entity WHERE entity_key = 'ark_of_covenant' AND entity_type_code = 'OBJECT') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one canonical ark_of_covenant OBJECT entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key IN ('poles_ark_covenant', 'rings_ark_covenant') AND entity_type_code = 'OBJECT') <> 2 THEN
        RAISE EXCEPTION 'phase19: expected existing poles/rings OBJECT entities to remain present';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%ark of the covenant%') <> 1 THEN
        RAISE EXCEPTION 'phase19: forbids duplicate canonical Ark entities';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key = 'uzzah' AND entity_type_code = 'PERSON') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one Uzzah PERSON entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE lower(canonical_name) = 'uzzah') <> 1 THEN
        RAISE EXCEPTION 'phase19: forbids duplicate Uzzah entities';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key = 'new_cart_ark_transport' AND entity_type_code = 'OBJECT') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one new cart OBJECT entity';
    END IF;

    -- 4. Event typing: the 2 Samuel transport/interaction are historical OTHER events; death is
    --    the existing DEATH type. None is an instruction, construction, or standing requirement.
    IF (SELECT count(*) FROM event WHERE event_key = 'ark_covenant_new_cart_transport_2sam6' AND event_type_code = 'OTHER') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected new-cart Ark transport event typed OTHER';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key = 'uzzah_ark_physical_interaction_2sam6' AND event_type_code = 'OTHER') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected Uzzah-Ark physical interaction event typed OTHER';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key = 'uzzah_death_2sam6' AND event_type_code = 'DEATH') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected Uzzah death event typed DEATH';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event
        WHERE event_key IN ('ark_covenant_new_cart_transport_2sam6', 'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6')
          AND event_type_code IN ('INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT')
    ) THEN
        RAISE EXCEPTION 'phase19: Phase 19 historical events must not be typed INSTRUCTION, CONSTRUCTION, or STANDING_REQUIREMENT';
    END IF;

    -- 5. Participation projection remains authoritative and bounded to source-supported entities.
    IF (SELECT count(*) FROM information_schema.views WHERE table_name = 'event_participation') <> 1 THEN
        RAISE EXCEPTION 'phase19: event_participation must remain a projection view';
    END IF;

    IF (
        SELECT count(DISTINCT en.entity_key)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_new_cart_transport_2sam6'
    ) <> 3 THEN
        RAISE EXCEPTION 'phase19: expected exactly Ark, new cart, and Uzzah projected for the new-cart transport event';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_new_cart_transport_2sam6'
          AND en.entity_key NOT IN ('ark_of_covenant', 'new_cart_ark_transport', 'uzzah')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids unsupported transport participants in the 2 Samuel event';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_new_cart_transport_2sam6'
          AND en.entity_key = 'ark_of_covenant' AND ep.role_code = 'SUBJECT'
    ) THEN
        RAISE EXCEPTION 'phase19: Ark must be the SUBJECT of the new-cart transport event';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_new_cart_transport_2sam6'
          AND en.entity_key = 'new_cart_ark_transport' AND ep.role_code = 'PARTICIPANT'
    ) THEN
        RAISE EXCEPTION 'phase19: new cart must project as a PARTICIPANT in the transport event';
    END IF;

    IF (
        SELECT count(DISTINCT en.entity_key)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'uzzah_ark_physical_interaction_2sam6'
          AND en.entity_key IN ('uzzah', 'ark_of_covenant')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase19: expected Uzzah and the Ark only for the physical interaction event';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key IN ('ark_covenant_new_cart_transport_2sam6', 'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6')
          AND en.entity_key IN ('poles_ark_covenant', 'rings_ark_covenant', 'priests_levites_ark_bearers',
                                'noahs_ark', 'moses', 'bezalel')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated poles/rings/priest/Levite/Kohathite/earlier-entity participation';
    END IF;

    -- 6. Exact propositions/claims for the source-backed assertions and complete provenance.
    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(phase_claim_keys) AND claim_type_code = 'DIRECT_SOURCE_CLAIM') <> 6 THEN
        RAISE EXCEPTION 'phase19: expected all six Phase 19 claims as direct source claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (c.claim_key = ANY(phase_claim_keys)
               OR se.entity_key IN ('uzzah', 'new_cart_ark_transport')
               OR oe.entity_key IN ('uzzah', 'new_cart_ark_transport')
               OR ov.event_key IN ('ark_covenant_new_cart_transport_2sam6',
                                   'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6'))
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = e.source_record_id
                                    AND sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND e.evidence_key = 'EV_MT_2SA_6_3_7'
                AND sr.source_record_key = 'MT_2SA_6_3_7'
                AND d.dataset_key = '2SA_MT_REF'
                AND s.source_key = '2SA_MT'
          )
    ) THEN
        RAISE EXCEPTION 'phase19: a Phase 19 direct claim lacks complete source-to-proposition provenance';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE c.claim_key = ANY(phase_claim_keys)
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase19: every evidence row supporting a Phase 19 claim requires a citation';
    END IF;

    IF (SELECT count(*) FROM evidence WHERE evidence_key = 'EV_MT_2SA_6_3_7' AND evidence_type_code = 'SOURCE_OBSERVATION') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one source observation for 2 Samuel 6:3-7';
    END IF;

    -- 7. No compliance, violation, causation, pole/ring physical state, derived claim, or unjustified
    --    claim relation is introduced by this phase.
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(phase_claim_keys)
          AND c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase19: Phase 19 claims must be direct source claims only';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key ~* '(compliance|comply|violat|cause|punish|contradict|pole.*state|ring.*state|remained|removed)'
          AND c.claim_key !~* 'CLAIM_POLES_STANDING_REQUIREMENT'
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated compliance, violation, causation, contradiction, or pole/ring-state claim keys';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE (coalesce(se.entity_key, oe.entity_key) IN ('poles_ark_covenant', 'rings_ark_covenant')
               OR coalesce(sv.event_key, ov.event_key) IN ('ark_covenant_new_cart_transport_2sam6',
                                                           'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6'))
          AND p.predicate IN ('occursAt', 'precedes')
          AND coalesce(sv.event_key, ov.event_key) IN ('ark_covenant_new_cart_transport_2sam6',
                                                       'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated chronology/location semantics for the Phase 19 slice';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DERIVED_CLAIM'
          AND (coalesce(se.entity_key, oe.entity_key) IN ('ark_of_covenant', 'uzzah', 'new_cart_ark_transport',
                                                          'poles_ark_covenant', 'rings_ark_covenant')
               OR coalesce(sv.event_key, ov.event_key) IN ('ark_covenant_new_cart_transport_2sam6',
                                                           'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6',
                                                           'ark_covenant_pole_standing_requirement',
                                                           'ark_covenant_transport_jordan'))
    ) THEN
        RAISE EXCEPTION 'phase19: forbids derived claims about the Phase 19 lifecycle/conflict slice';
    END IF;

    IF EXISTS (
        SELECT 1 FROM derivation_input di
        JOIN claim c ON c.claim_id = di.input_claim_id
        WHERE c.derivation_id = di.derivation_id
    ) THEN
        RAISE EXCEPTION 'phase19: derived claims may never be used as their own derivation input';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key = ANY(phase_claim_keys) OR c2.claim_key = ANY(phase_claim_keys)
    ) THEN
        RAISE EXCEPTION 'phase19: no ClaimRelation is justified for the 2 Samuel 6:3-7 slice; transport-method difference is not a contradiction';
    END IF;

    IF (SELECT count(*) FROM claim_relation) <> 6 THEN
        RAISE EXCEPTION 'phase19: expected no new ClaimRelation rows beyond the accepted Phase 18 baseline';
    END IF;

    -- 8. Source identity/mapping discipline: no new source-identity reconciliation is required for
    --    this bounded slice; unsupported active mappings are forbidden.
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key IN ('uzzah', 'new_cart_ark_transport')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids unjustified SourceIdentity/EntitySourceMapping rows for Uzzah or the new cart';
    END IF;

    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        WHERE esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase19: active EntitySourceMapping rows require supporting evidence';
    END IF;

    -- 9. Phase 17 and Phase 18 semantics remain unchanged.
    IF (
        SELECT count(*) FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'standingRequirementIn'
          AND en.entity_key = 'poles_ark_covenant'
          AND ev.event_key = 'ark_covenant_pole_standing_requirement'
          AND ev.event_type_code = 'STANDING_REQUIREMENT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase19: Phase 17 Exodus 25:15 standing requirement must remain intact';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) THEN
        RAISE EXCEPTION 'phase19: standing requirement must remain projection-free';
    END IF;

    IF (
        SELECT count(*) FROM event
        WHERE event_key = 'ark_covenant_transport_jordan' AND event_type_code = 'OTHER'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase19: Phase 18 Joshua 3:6 transport event must remain intact';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_transport_jordan'
          AND en.entity_key NOT IN ('ark_of_covenant', 'priests_levites_ark_bearers')
    ) THEN
        RAISE EXCEPTION 'phase19: Phase 18 transport participants must remain bounded to the Ark and priests';
    END IF;
END $$;
