\set ON_ERROR_STOP on

\echo 'Phase 24 Berean-in-action validation: source-backed 1 Samuel Ark lifecycle slice'

DO $$
DECLARE
    phase24_claim_keys text[] := ARRAY[
        'CLAIM_ARK_COVENANT_SUBJECT_BROUGHT_FROM_SHILOH_1SAM4',
        'CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4',
        'CLAIM_PHILISTINES_PARTICIPANT_CAPTURE_1SAM4',
        'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5',
        'CLAIM_PHILISTINES_PARTICIPANT_MOVED_ASHDOD_1SAM5',
        'CLAIM_ARK_COVENANT_SUBJECT_HOUSE_DAGON_1SAM5',
        'CLAIM_ARK_COVENANT_SUBJECT_ABINADAB_HOUSE_1SAM7',
        'CLAIM_MEN_KIRIATH_JEARIM_PARTICIPANT_ABINADAB_HOUSE_1SAM7',
        'CLAIM_ARK_COVENANT_SUBJECT_ELEAZAR_CARE_1SAM7',
        'CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7',
        'CLAIM_ARK_COVENANT_SUBJECT_STAY_KIRIATH_JEARIM_1SAM7',
        'CLAIM_ARK_MOVEMENT_ASHDOD_PLACE_1SAM5',
        'CLAIM_ARK_HOUSE_DAGON_PLACE_1SAM5',
        'CLAIM_ARK_ABINADAB_HOUSE_PLACE_1SAM7',
        'CLAIM_ELEAZAR_CARE_ABINADAB_HOUSE_PLACE_1SAM7',
        'CLAIM_ARK_STAY_KIRIATH_JEARIM_PLACE_1SAM7'
    ];
BEGIN
    -- Phase 24 must be a data/demo phase only: no schema or registry expansion.
    IF (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') <> 31 THEN
        RAISE EXCEPTION 'phase24: unexpected base-table count; schema expansion is forbidden';
    END IF;

    IF (SELECT count(*) FROM event_type) <> (SELECT count(*) FROM event_type WHERE event_type_code IN (
        'BIRTH', 'DEATH', 'GENEALOGICAL', 'CHRONOLOGICAL', 'OTHER',
        'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT'
    )) THEN
        RAISE EXCEPTION 'phase24: forbids new event_type registry values';
    END IF;

    IF (SELECT count(*) FROM predicate) <> (SELECT count(*) FROM predicate WHERE predicate_code IN (
        'fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt', 'precedes',
        'participatesIn', 'subjectOf', 'parentIn', 'childIn', 'builderIn',
        'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation',
        'lengthCubits', 'widthCubits', 'heightCubits', 'madeOfMaterial',
        'overlaidWithMaterial', 'hasComponent', 'containsContent', 'standingRequirementIn'
    )) THEN
        RAISE EXCEPTION 'phase24: forbids new predicate registry values';
    END IF;

    -- Exact source/dataset/source-record/citation shape for the 1 Samuel slice.
    IF (SELECT count(*) FROM source WHERE source_key = '1SA_MT') <> 1 THEN
        RAISE EXCEPTION 'phase24: expected one 1SA_MT source';
    END IF;

    IF (SELECT count(*) FROM dataset WHERE dataset_key = '1SA_MT_REF') <> 1 THEN
        RAISE EXCEPTION 'phase24: expected one 1SA_MT_REF dataset';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = '1SA_MT_REF'
    ) <> 6 THEN
        RAISE EXCEPTION 'phase24: expected exactly six 1 Samuel source records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            ('MT_1SA_4_4', '1 Samuel 4:4'), ('MT_1SA_4_11', '1 Samuel 4:11'),
            ('MT_1SA_5_1', '1 Samuel 5:1'), ('MT_1SA_5_2', '1 Samuel 5:2'),
            ('MT_1SA_7_1', '1 Samuel 7:1'), ('MT_1SA_7_2', '1 Samuel 7:2')
        ) AS expected(source_record_key, locator)
        WHERE NOT EXISTS (
            SELECT 1
            FROM source_record sr
            JOIN dataset d ON d.dataset_id = sr.dataset_id
            JOIN citation ci ON ci.source_record_id = sr.source_record_id
            WHERE d.dataset_key = '1SA_MT_REF'
              AND sr.source_record_key = expected.source_record_key
              AND sr.source_location = expected.locator
              AND ci.locator = expected.locator
              AND sr.raw_content IS NULL
              AND sr.content_hash IS NULL
              AND ci.quoted_text IS NULL
        )
    ) THEN
        RAISE EXCEPTION 'phase24: each 1 Samuel locator requires one unquoted citation and no fabricated text/hash';
    END IF;

    -- Entities, events, propositions, claims, and projected relationships.
    IF (SELECT count(*) FROM entity WHERE entity_key IN (
        'philistines', 'men_kiriath_jearim', 'eleazar_son_abinadab', 'ashdod',
        'house_dagon_ashdod', 'house_abinadab_kiriath_jearim', 'kiriath_jearim'
    )) <> 7 THEN
        RAISE EXCEPTION 'phase24: expected seven new source-supported referent entities';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key IN (
        'ark_covenant_brought_from_shiloh_1sam4',
        'ark_covenant_captured_1sam4',
        'ark_covenant_moved_to_ashdod_1sam5',
        'ark_covenant_set_in_house_dagon_1sam5',
        'ark_covenant_brought_to_abinadab_house_1sam7',
        'ark_covenant_care_eleazar_1sam7',
        'ark_covenant_stay_kiriath_jearim_1sam7'
    ) AND event_type_code = 'OTHER') <> 7 THEN
        RAISE EXCEPTION 'phase24: expected seven generic OTHER lifecycle events';
    END IF;

    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(phase24_claim_keys) AND claim_type_code = 'DIRECT_SOURCE_CLAIM') <> 16 THEN
        RAISE EXCEPTION 'phase24: expected sixteen direct source claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
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
                AND s.source_key = '1SA_MT'
                AND d.dataset_key = '1SA_MT_REF'
          )
    ) THEN
        RAISE EXCEPTION 'phase24: a Phase 24 claim lacks complete source-backed provenance';
    END IF;

    IF (
        SELECT count(DISTINCT en.entity_key)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_moved_to_ashdod_1sam5'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase24: Ashdod movement must project exactly Ark and Philistines as participants/subject';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN event ev ON ev.event_id = p.subject_event_id
        JOIN entity place ON place.entity_id = p.object_entity_id
        JOIN claim c ON c.proposition_id = p.proposition_id
        WHERE p.predicate = 'occursAt'
          AND ev.event_key IN (
              'ark_covenant_moved_to_ashdod_1sam5',
              'ark_covenant_set_in_house_dagon_1sam5',
              'ark_covenant_brought_to_abinadab_house_1sam7',
              'ark_covenant_care_eleazar_1sam7',
              'ark_covenant_stay_kiriath_jearim_1sam7'
          )
          AND place.entity_key IN ('ashdod', 'house_dagon_ashdod', 'house_abinadab_kiriath_jearim', 'kiriath_jearim')
    ) <> 5 THEN
        RAISE EXCEPTION 'phase24: expected five source-backed event/place propositions';
    END IF;

    -- Preserve source differences without automatic classifications or conclusions.
    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key = ANY(phase24_claim_keys) OR c2.claim_key = ANY(phase24_claim_keys)
    ) THEN
        RAISE EXCEPTION 'phase24: Phase 24 must not manufacture claim relations for source differences';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
          AND (c.claim_type_code = 'DERIVED_CLAIM' OR c.derivation_id IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase24: Phase 24 direct source claims must not be artificial derivations';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
          AND (
              c.claim_key ~* '(COMPLI|OBEY|VIOLAT|CAUSE|PUNISH|CONTRADICT|THEOLOG|INFER)'
              OR coalesce(c.statement, '') ~* '(compliance|obey|violat|cause|causation|punish|contradict|theolog|infer)'
          )
    ) THEN
        RAISE EXCEPTION 'phase24: forbids semantic inference claims in the demonstration slice';
    END IF;

    -- Source-specific identities must remain distinct from canonical entities and be auditable.
    IF (
        SELECT count(*)
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN source s ON s.source_id = si.source_id
        WHERE s.source_key = '1SA_MT'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NOT NULL
    ) <> 8 THEN
        RAISE EXCEPTION 'phase24: expected eight evidence-backed active 1 Samuel source-identity mappings';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN source s ON s.source_id = si.source_id
        JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE s.source_key = '1SA_MT'
          AND d.source_id <> s.source_id
    ) THEN
        RAISE EXCEPTION 'phase24: 1 Samuel mappings must be supported by 1 Samuel evidence';
    END IF;

    -- Frozen Phase 19/21/23 boundaries remain visible after the Phase 24 fixture.
    IF NOT EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT'
          AND NOT EXISTS (
              SELECT 1 FROM event_participation ep
              WHERE ep.asserting_claim_id = c.claim_id
          )
    ) THEN
        RAISE EXCEPTION 'phase24: Phase 17/19 standing requirement boundary must remain non-participatory';
    END IF;

    IF (SELECT count(*) FROM claim WHERE claim_type_code = 'DERIVED_CLAIM') < 3 THEN
        RAISE EXCEPTION 'phase24: accepted Genesis derivations must remain available for Phase 23 demonstration';
    END IF;
END $$;

\echo 'Phase 24 provenance examples'
SELECT c.claim_key, ev.evidence_key, ci.locator, sr.source_record_key, d.dataset_key, s.source_key
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN (
    'CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4',
    'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5',
    'CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7'
)
ORDER BY c.claim_key;

\echo 'Phase 24 source-difference examples preserved as separate events'
SELECT s.source_key, c.claim_key, ev.event_key, ev.event_type_code, c.statement
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN (
    'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
    'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5',
    'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'
)
ORDER BY s.source_key, c.claim_key;

\echo 'Phase 24 event exploration'
SELECT ev.event_key, ev.event_type_code, en.entity_key, ep.role_code, c.claim_key
FROM event ev
JOIN event_participation ep ON ep.event_id = ev.event_id
JOIN entity en ON en.entity_id = ep.entity_id
JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key IN (
    'ark_covenant_moved_to_ashdod_1sam5',
    'ark_covenant_brought_to_abinadab_house_1sam7',
    'ark_covenant_care_eleazar_1sam7'
)
ORDER BY ev.event_key, en.entity_key;

\echo 'Phase 24 dependency exploration: claims depending on 1 Samuel evidence'
SELECT ev.evidence_key, c.claim_key, ce.relation_type_code
FROM evidence ev
JOIN claim_evidence ce ON ce.evidence_id = ev.evidence_id
JOIN claim c ON c.claim_id = ce.claim_id
WHERE ev.evidence_key LIKE 'EV_MT_1SA_%'
ORDER BY ev.evidence_key, c.claim_key;
