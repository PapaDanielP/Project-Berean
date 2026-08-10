\set ON_ERROR_STOP on

-- Phase 19 validates the source-backed 2 Samuel 6:3-7 Ark lifecycle slice without adding schema,
-- registry, JSON, artifact-specific, transport-specific, causation, compliance, or contradiction
-- infrastructure. The authoritative semantics remain Proposition/Claim/Evidence/Event; event
-- participation remains a projection of claim-asserted propositions.
DO $$
DECLARE
    phase19_claim_keys text[] := ARRAY[
        'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6',
        'CLAIM_NEW_CART_PARTICIPANT_TRANSPORT_2SAM6',
        'CLAIM_UZZAH_PARTICIPANT_TRANSPORT_2SAM6',
        'CLAIM_ARK_COVENANT_SUBJECT_UZZAH_INTERACTION_2SAM6',
        'CLAIM_UZZAH_PARTICIPANT_INTERACTION_2SAM6',
        'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6'
    ];
BEGIN
    -- 1. Exact bounded source availability: 2 Samuel 6:3-7, no text/hash/quotation.
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
    ) <> 5 THEN
        RAISE EXCEPTION 'phase19: expected exactly five 2 Samuel 6:3-7 source records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES ('MT_2SA_6_3', '2 Samuel 6:3'), ('MT_2SA_6_4', '2 Samuel 6:4'),
                     ('MT_2SA_6_5', '2 Samuel 6:5'), ('MT_2SA_6_6', '2 Samuel 6:6'),
                     ('MT_2SA_6_7', '2 Samuel 6:7')) AS expected(source_record_key, locator)
        WHERE NOT EXISTS (
            SELECT 1
            FROM source_record sr
            JOIN dataset d ON d.dataset_id = sr.dataset_id
            JOIN citation ci ON ci.source_record_id = sr.source_record_id
            WHERE d.dataset_key = '2SA_MT_REF'
              AND sr.source_record_key = expected.source_record_key
              AND sr.source_location = expected.locator
              AND ci.locator = expected.locator
              AND sr.raw_content IS NULL
              AND sr.content_hash IS NULL
              AND ci.quoted_text IS NULL
        )
    ) THEN
        RAISE EXCEPTION 'phase19: each exact 2 Samuel 6:3-7 locator requires one unquoted citation and no fabricated text/hash';
    END IF;

    IF EXISTS (
        SELECT 1 FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE d.dataset_key = '2SA_MT_REF'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated Scripture text, hash, or quotation for 2 Samuel 6:3-7';
    END IF;

    -- 2. Registry sufficiency: no new event_type, predicate, role, or specialized table/JSON.
    IF (SELECT count(*) FROM event_type) <> (SELECT count(*) FROM event_type WHERE event_type_code IN (
        'BIRTH', 'DEATH', 'GENEALOGICAL', 'CHRONOLOGICAL', 'OTHER',
        'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT'
    )) THEN
        RAISE EXCEPTION 'phase19: forbids any new event_type such as TRANSPORT or CONSEQUENCE';
    END IF;

    IF (SELECT count(*) FROM predicate) <> (SELECT count(*) FROM predicate WHERE predicate_code IN (
        'fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt', 'precedes',
        'participatesIn', 'subjectOf', 'parentIn', 'childIn', 'builderIn',
        'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation',
        'lengthCubits', 'widthCubits', 'heightCubits', 'madeOfMaterial',
        'overlaidWithMaterial', 'hasComponent', 'containsContent', 'standingRequirementIn'
    )) THEN
        RAISE EXCEPTION 'phase19: forbids unsupported predicates such as TOUCHED, CART, HANDLED_BY, CAUSE, or VIOLATED_REQUIREMENT';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('artifact_transport', 'transport', 'carrier', 'transport_event',
                             'artifact_participation', 'event_participant', 'artifact', 'object',
                             'thing', 'artifact_attribute', 'artifact_component', 'artifact_content',
                             'object_relationship', 'requirement', 'artifact_lifecycle',
                             'artifact_json_semantics')
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

    -- 3. Canonical entities: one Ark, reused poles/rings, exactly one Uzzah and one new cart.
    IF (SELECT count(*) FROM entity WHERE entity_key = 'ark_of_covenant' AND entity_type_code = 'OBJECT') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one canonical ark_of_covenant OBJECT entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%ark of the covenant%') <> 1 THEN
        RAISE EXCEPTION 'phase19: forbids duplicate canonical Ark entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key IN ('poles_ark_covenant', 'rings_ark_covenant') AND entity_type_code = 'OBJECT') <> 2 THEN
        RAISE EXCEPTION 'phase19: expected existing poles and rings OBJECT entities unchanged';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%poles of the ark%') <> 1
       OR (SELECT count(*) FROM entity WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%rings of the ark%') <> 1 THEN
        RAISE EXCEPTION 'phase19: forbids duplicate pole/ring entities';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key = 'uzzah' AND entity_type_code = 'PERSON') <> 1
       OR (SELECT count(*) FROM entity WHERE canonical_name = 'Uzzah') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one supported Uzzah PERSON entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key = 'new_cart_2sam6' AND entity_type_code = 'OBJECT') <> 1
       OR (SELECT count(*) FROM entity WHERE canonical_name ILIKE '%new cart%2 Samuel 6%') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected exactly one supported new-cart OBJECT entity';
    END IF;

    -- 4. Events are distinct from standing requirement, instruction, construction, and each other.
    IF (SELECT count(*) FROM event WHERE event_key = 'ark_covenant_transport_new_cart_2sam6' AND event_type_code = 'OTHER') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected new-cart transport event typed OTHER';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key = 'ark_covenant_physical_interaction_uzzah_2sam6' AND event_type_code = 'OTHER') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected Uzzah-Ark physical interaction event typed OTHER';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key = 'uzzah_death_2sam6' AND event_type_code = 'DEATH') <> 1 THEN
        RAISE EXCEPTION 'phase19: expected Uzzah death/consequence event typed DEATH';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event
        WHERE event_key IN ('ark_covenant_transport_new_cart_2sam6',
                            'ark_covenant_physical_interaction_uzzah_2sam6', 'uzzah_death_2sam6')
          AND event_type_code IN ('INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT')
    ) THEN
        RAISE EXCEPTION 'phase19: 2 Samuel 6 historical events must not be instruction/construction/standing-requirement events';
    END IF;

    -- Phase 17 and 18 semantics remain unchanged.
    IF (SELECT count(*) FROM event WHERE event_key = 'ark_covenant_pole_standing_requirement' AND event_type_code = 'STANDING_REQUIREMENT') <> 1 THEN
        RAISE EXCEPTION 'phase19: Exodus 25:15 standing requirement must remain unchanged';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key = 'ark_covenant_transport_jordan' AND event_type_code = 'OTHER') <> 1 THEN
        RAISE EXCEPTION 'phase19: Joshua 3:6 transport event must remain unchanged';
    END IF;

    -- 5. Exact Phase 19 propositions/claims and projected participation.
    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(phase19_claim_keys) AND claim_type_code = 'DIRECT_SOURCE_CLAIM') <> 6 THEN
        RAISE EXCEPTION 'phase19: expected exactly six Phase 19 direct source claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            ('ark_of_covenant', 'subjectOf', 'ark_covenant_transport_new_cart_2sam6'),
            ('new_cart_2sam6', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6'),
            ('uzzah', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6'),
            ('ark_of_covenant', 'subjectOf', 'ark_covenant_physical_interaction_uzzah_2sam6'),
            ('uzzah', 'participatesIn', 'ark_covenant_physical_interaction_uzzah_2sam6'),
            ('uzzah', 'subjectOf', 'uzzah_death_2sam6')
        ) AS expected(subject_key, predicate, event_key)
        WHERE NOT EXISTS (
            SELECT 1 FROM proposition p
            JOIN entity en ON en.entity_id = p.subject_entity_id
            JOIN event ev ON ev.event_id = p.object_event_id
            JOIN claim c ON c.proposition_id = p.proposition_id
            WHERE en.entity_key = expected.subject_key
              AND p.predicate = expected.predicate
              AND ev.event_key = expected.event_key
              AND c.claim_key = ANY(phase19_claim_keys)
        )
    ) THEN
        RAISE EXCEPTION 'phase19: missing expected Phase 19 proposition/claim shape';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_transport_new_cart_2sam6'
          AND en.entity_key NOT IN ('ark_of_covenant', 'new_cart_2sam6', 'uzzah')
    ) THEN
        RAISE EXCEPTION 'phase19: transport event has unsupported participant';
    END IF;

    IF (SELECT count(DISTINCT en.entity_key) FROM event_participation ep JOIN event ev ON ev.event_id = ep.event_id JOIN entity en ON en.entity_id = ep.entity_id WHERE ev.event_key = 'ark_covenant_transport_new_cart_2sam6') <> 3 THEN
        RAISE EXCEPTION 'phase19: transport event must project exactly ark, new cart, and Uzzah';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_physical_interaction_uzzah_2sam6'
          AND en.entity_key NOT IN ('ark_of_covenant', 'uzzah')
    ) THEN
        RAISE EXCEPTION 'phase19: physical-interaction event has unsupported participant';
    END IF;

    IF (SELECT count(DISTINCT en.entity_key) FROM event_participation ep JOIN event ev ON ev.event_id = ep.event_id JOIN entity en ON en.entity_id = ep.entity_id WHERE ev.event_key = 'ark_covenant_physical_interaction_uzzah_2sam6') <> 2 THEN
        RAISE EXCEPTION 'phase19: physical-interaction event must project exactly ark and Uzzah';
    END IF;

    IF (SELECT count(*) FROM event_participation ep JOIN event ev ON ev.event_id = ep.event_id JOIN entity en ON en.entity_id = ep.entity_id WHERE ev.event_key = 'uzzah_death_2sam6' AND en.entity_key = 'uzzah' AND ep.role_code = 'SUBJECT') <> 1 THEN
        RAISE EXCEPTION 'phase19: Uzzah death event must project Uzzah as SUBJECT';
    END IF;

    IF (SELECT count(*) FROM information_schema.views WHERE table_name = 'event_participation') <> 1 THEN
        RAISE EXCEPTION 'phase19: event_participation must remain a projection view';
    END IF;

    -- 6. Provenance completeness and citation integrity.
    IF EXISTS (
        SELECT 1 FROM evidence ev
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = '2SA_MT_REF'
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = ev.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase19: every 2 Samuel evidence row requires a citation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key = ANY(phase19_claim_keys)
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence ev ON ev.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ev.source_record_id
                                    AND sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND s.source_key = '2SA_MT'
                AND d.dataset_key = '2SA_MT_REF'
                AND sr.source_record_key IN ('MT_2SA_6_3', 'MT_2SA_6_6', 'MT_2SA_6_7')
          )
    ) THEN
        RAISE EXCEPTION 'phase19: a Phase 19 direct claim lacks complete Source->Dataset->SourceRecord->Citation->Evidence->ClaimEvidence provenance';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence ev ON ev.evidence_id = ce.evidence_id
        WHERE c.claim_key = ANY(phase19_claim_keys)
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = ev.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase19: every evidence row supporting a Phase 19 claim requires citation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'PHASE19_%'
          AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id)
    ) THEN
        RAISE EXCEPTION 'phase19: rejects Phase 19 claim without ClaimEvidence';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_evidence ce
        JOIN evidence ev ON ev.evidence_id = ce.evidence_id
        WHERE ev.evidence_key LIKE 'EV_PHASE19_%'
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = ev.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase19: rejects Phase 19 evidence without Citation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_evidence ce
        JOIN evidence ev ON ev.evidence_id = ce.evidence_id
        WHERE ev.evidence_key IN ('EV_MT_2SA_6_4', 'EV_MT_2SA_6_5')
    ) THEN
        RAISE EXCEPTION 'phase19: 2 Samuel 6:4-5 evidence is source availability only and must not support direct claims in this phase';
    END IF;

    -- 7. SourceIdentity / EntitySourceMapping is justified and bounded to Uzzah/new cart.
    IF (SELECT count(*) FROM source_identity si JOIN source s ON s.source_id = si.source_id WHERE s.source_key = '2SA_MT') <> 2 THEN
        RAISE EXCEPTION 'phase19: expected exactly two 2 Samuel source identities (Uzzah and new cart)';
    END IF;

    IF (SELECT count(*) FROM entity_source_mapping esm JOIN source_identity si ON si.source_identity_id = esm.source_identity_id JOIN source s ON s.source_id = si.source_id WHERE s.source_key = '2SA_MT' AND esm.mapping_status_code = 'ACTIVE' AND esm.supporting_evidence_id IS NOT NULL) <> 2 THEN
        RAISE EXCEPTION 'phase19: expected exactly two evidence-backed active 2 Samuel mappings';
    END IF;

    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN source s ON s.source_id = si.source_id
        WHERE s.source_key = '2SA_MT'
          AND en.entity_key NOT IN ('uzzah', 'new_cart_2sam6')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids unjustified 2 Samuel mapping to Ark, poles, rings, or unsupported entities';
    END IF;

    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        WHERE esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NULL
          AND EXISTS (SELECT 1 FROM source_identity si JOIN source s ON s.source_id = si.source_id WHERE si.source_identity_id = esm.source_identity_id AND s.source_key = '2SA_MT')
    ) THEN
        RAISE EXCEPTION 'phase19: 2 Samuel mappings require supporting evidence';
    END IF;

    -- 8. No fabricated pole/ring state, compliance, causation, contradiction, or derived knowledge.
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        WHERE ev.event_key IN ('ark_covenant_transport_new_cart_2sam6',
                               'ark_covenant_physical_interaction_uzzah_2sam6', 'uzzah_death_2sam6')
          AND se.entity_key IN ('poles_ark_covenant', 'rings_ark_covenant')
    ) THEN
        RAISE EXCEPTION 'phase19: forbids fabricated pole/ring physical state or participation in 2 Samuel events';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key ~* '(COMPLI|OBEY|VIOLAT|CAUSE|PUNISH|CONTRADICT|POLE_STATE|RING_STATE|REMAIN|NON_REMOVAL)'
           OR coalesce(c.statement, '') ~* '(compliance|obey|violat|cause|causation|punish|contradict|poles remained|rings remained|non-removal)'
    ) THEN
        RAISE EXCEPTION 'phase19: forbids compliance, violation, causation, contradiction, and fabricated pole/ring-state claims';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_type_code = 'DERIVED_CLAIM'
          AND (c.claim_key LIKE '%2SAM6%' OR c.claim_key LIKE 'PHASE19_%')
    ) THEN
        RAISE EXCEPTION 'phase19: no Phase 19 derived claim is populated';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key = ANY(phase19_claim_keys) OR c2.claim_key = ANY(phase19_claim_keys)
           OR c1.claim_key LIKE 'PHASE19_%' OR c2.claim_key LIKE 'PHASE19_%'
    ) THEN
        RAISE EXCEPTION 'phase19: no ClaimRelation is justified for the Phase 19 slice';
    END IF;

    -- All derivations must remain complete and acyclic with respect to self-inputs.
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_type_code = 'DERIVED_CLAIM'
          AND c.derivation_id IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM derivation_input di WHERE di.derivation_id = c.derivation_id)
    ) THEN
        RAISE EXCEPTION 'phase19: rejects derived claim without DerivationInput';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN derivation_input di ON di.derivation_id = c.derivation_id
        WHERE di.input_claim_id = c.claim_id
    ) THEN
        RAISE EXCEPTION 'phase19: rejects derived claim used as its own input';
    END IF;
END $$;
