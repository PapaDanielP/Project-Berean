\set ON_ERROR_STOP on

-- Phase 30 verifies the bounded research corpus's layer separation and complete provenance.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity n ON n.entity_id = p.subject_entity_id
        JOIN entity earth ON earth.entity_id = p.object_entity_id
        WHERE c.claim_key = 'CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30'
          AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND n.entity_key = 'nephilim_gen6'
          AND p.predicate = 'locatedAt'
          AND earth.entity_key = 'gen1_earth'
    ) THEN
        RAISE EXCEPTION 'phase30: the explicit Genesis 6:4 Nephilim assertion is missing or altered';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE '%P30%'
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'phase30: a Phase 30 claim lacks a complete provenance chain';
    END IF;

    -- Scholarship and later tradition are kept as separately cited observations, never biblical claims.
    IF (SELECT count(*) FROM evidence WHERE evidence_key IN
          ('EV_HENDEL_2004_P30', 'EV_KLINE_1962_P30', 'EV_WENHAM_1987_P30', 'EV_1EN_ETH_6_7_P30')) <> 4 THEN
        RAISE EXCEPTION 'phase30: bounded scholarly/later-tradition observations are incomplete';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key IN
              ('EV_HENDEL_2004_P30', 'EV_KLINE_1962_P30', 'EV_WENHAM_1987_P30', 'EV_1EN_ETH_6_7_P30')
    ) THEN
        RAISE EXCEPTION 'phase30: scholarly or later-tradition material was promoted to a claim';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key IN ('CLAIM_P30_SONS_OF_GOD_DIVINE', 'CLAIM_P30_NEPHILIM_OFFSPRING',
                            'CLAIM_P30_1ENOCH_EXPANSION', 'CLAIM_P30_INTERPRETATION_RANKING')
    ) THEN
        RAISE EXCEPTION 'phase30: an interpretive, later-tradition, or research conclusion was promoted';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF', 'NUM_MT_REF', '1EN_ETH_REF',
                                'HENDEL_2004_REF', 'KLINE_1962_REF', 'WENHAM_1987_REF')
          AND sr.source_record_key IN ('MT_GEN_6_1_4', 'LXX_GEN_6_1_4', 'MT_NUM_13_33', '1EN_ETH_6_7',
                                       'HENDEL_2004_13_26', 'KLINE_1962_187_204', 'WENHAM_1987_139_143')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) OR EXISTS (
        SELECT 1 FROM citation
        WHERE citation_key IN ('CITE_MT_GEN_6_1_4', 'CITE_LXX_GEN_6_1_4', 'CITE_MT_NUM_13_33',
                               'CITE_1EN_ETH_6_7', 'CITE_HENDEL_2004_13_26', 'CITE_KLINE_1962_187_204',
                               'CITE_WENHAM_1987_139_143')
          AND quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase30: locator-only source storage policy violated';
    END IF;

    RAISE NOTICE 'ok: Phase 30 preserves direct biblical, textual-comparison, later-tradition, scholarly, and unresolved layers without promotion';
END $$;
