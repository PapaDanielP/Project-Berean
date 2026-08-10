\set ON_ERROR_STOP on

DO $$
DECLARE
    phase27_entity_count integer;
BEGIN
    SELECT count(*) INTO phase27_entity_count
    FROM entity_source_mapping esm
    JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
    WHERE si.source_identity_key LIKE 'mt-p27-%' AND esm.mapping_status_code = 'ACTIVE';

    IF phase27_entity_count <> 48 THEN
        RAISE EXCEPTION 'phase27: expected 48 evidence-backed Phase 27 entity mappings, got %',
            phase27_entity_count;
    END IF;
    IF (SELECT count(*) FROM source_record WHERE source_record_key IN (
        SELECT replace(evidence_key, 'EV_', '') FROM evidence WHERE evidence_key LIKE 'EV_MT_GEN_%'
    ) AND source_record_key IN (
        'MT_GEN_2_8','MT_GEN_2_22','MT_GEN_4_1','MT_GEN_4_2','MT_GEN_4_8','MT_GEN_4_16',
        'MT_GEN_6_10','MT_GEN_11_2','MT_GEN_11_9','MT_GEN_11_26','MT_GEN_11_31',
        'MT_GEN_12_5','MT_GEN_12_8','MT_GEN_13_12','MT_GEN_14_18','MT_GEN_15_18',
        'MT_GEN_16_15','MT_GEN_18_1','MT_GEN_19_24','MT_GEN_20_1','MT_GEN_21_2',
        'MT_GEN_21_31','MT_GEN_22_2','MT_GEN_23_1','MT_GEN_23_2','MT_GEN_24_67',
        'MT_GEN_25_7','MT_GEN_25_25','MT_GEN_25_26','MT_GEN_26_6','MT_GEN_28_19',
        'MT_GEN_29_32','MT_GEN_29_35','MT_GEN_30_24','MT_GEN_32_28','MT_GEN_33_18',
        'MT_GEN_35_18','MT_GEN_35_28','MT_GEN_35_29','MT_GEN_37_17','MT_GEN_37_28',
        'MT_GEN_39_20','MT_GEN_40_5','MT_GEN_40_12','MT_GEN_41_1','MT_GEN_41_50',
        'MT_GEN_42_6','MT_GEN_43_15','MT_GEN_44_18','MT_GEN_45_1','MT_GEN_46_6',
        'MT_GEN_47_28','MT_GEN_48_14','MT_GEN_49_33','MT_GEN_50_26'
    )) <> 55 THEN
        RAISE EXCEPTION 'phase27: expected 55 new Genesis source records with evidence';
    END IF;
    IF (SELECT count(*) FROM claim WHERE claim_key LIKE 'CLAIM_P27_%') <> 126 THEN
        RAISE EXCEPTION 'phase27: expected 126 Phase 27 direct claims';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim WHERE claim_key LIKE 'CLAIM_P27_%'
        AND claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN RAISE EXCEPTION 'phase27: unexpected non-direct Phase 27 claim'; END IF;

    -- Duplicate canonical entities and source records.
    IF EXISTS (
        SELECT 1 FROM entity GROUP BY entity_type_code, lower(canonical_name) HAVING count(*) > 1
    ) THEN RAISE EXCEPTION 'phase27: duplicate canonical entities'; END IF;
    IF EXISTS (
        SELECT 1 FROM source_record GROUP BY source_record_key HAVING count(*) > 1
    ) THEN RAISE EXCEPTION 'phase27: duplicate source records'; END IF;

    -- Complete provenance, no structural orphans, and locator-only storage policy.
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.claim_key LIKE 'CLAIM_P27_%' AND NOT EXISTS (
            SELECT 1 FROM claim_evidence ce
            JOIN evidence e ON e.evidence_id = ce.evidence_id
            JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
            JOIN citation ci ON ci.citation_id = ec.citation_id
            JOIN source_record sr ON sr.source_record_id = ci.source_record_id
            JOIN dataset d ON d.dataset_id = sr.dataset_id AND d.dataset_key = 'GEN_MT_REF'
            JOIN source s ON s.source_id = d.source_id AND s.source_key = 'GEN_MT'
            WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        )
    ) THEN RAISE EXCEPTION 'phase27: incomplete provenance'; END IF;
    IF EXISTS (
        SELECT 1 FROM evidence e WHERE e.evidence_key LIKE 'EV_MT_GEN_%'
        AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN RAISE EXCEPTION 'phase27: orphan evidence'; END IF;
    IF EXISTS (
        SELECT 1 FROM source_record sr LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN (
            SELECT replace(evidence_key, 'EV_', '') FROM evidence WHERE evidence_key LIKE 'EV_MT_GEN_%'
        ) AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN RAISE EXCEPTION 'phase27: source storage policy violated'; END IF;

    -- Registry immutability and no Phase 27 derivation.
    IF (SELECT count(*) FROM predicate) <> 22
       OR (SELECT count(*) FROM event_type) <> 8
       OR (SELECT count(*) FROM entity_type) <> 5
       OR (SELECT count(*) FROM event_participation_role) <> 5 THEN
        RAISE EXCEPTION 'phase27: registry modification detected';
    END IF;
    IF (SELECT count(*) FROM derivation) <> 3 OR (SELECT count(*) FROM derivation_input) <> 6 THEN
        RAISE EXCEPTION 'phase27: unexpected derived claims or inputs';
    END IF;

    -- Required explorer subjects and a multi-participant event are fully projected.
    IF EXISTS (
        SELECT 1 FROM unnest(ARRAY['adam','noah','abraham','sarah','isaac','jacob','joseph','egypt']) k
        WHERE NOT EXISTS (
            SELECT 1 FROM entity en
            JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
            JOIN claim c ON c.proposition_id = p.proposition_id
            JOIN claim_evidence ce ON ce.claim_id = c.claim_id
            WHERE en.entity_key = k
        )
    ) THEN RAISE EXCEPTION 'phase27: required explorer subject lacks source-backed claims'; END IF;
    IF (SELECT count(DISTINCT entity_id) FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'noah_sons_genealogy') <> 4 THEN
        RAISE EXCEPTION 'phase27: expected four explicitly named participants in Noah genealogy';
    END IF;

    -- Explicitly retained observations must not be transformed into unsupported claims.
    IF EXISTS (
        SELECT 1 FROM claim_evidence ce JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key = 'EV_MT_GEN_32_28'
    ) THEN RAISE EXCEPTION 'phase27: intentional evidence-only candidates were modeled'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim_relation cr JOIN claim c ON c.claim_id = cr.claim_id
        WHERE c.claim_key LIKE 'CLAIM_P27_%'
    ) THEN RAISE EXCEPTION 'phase27: source comparison was classified automatically'; END IF;
END $$;

\echo 'ok: Phase 27 Genesis 1-50 corpus passes provenance, integrity, registry, and restraint validation'
