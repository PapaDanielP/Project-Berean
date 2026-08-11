\set ON_ERROR_STOP on

-- Phase 31 validates end-to-end scholarly research layering over the existing Phase 30 corpus.
DO $$
DECLARE
    direct_claim_count integer;
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
        RAISE EXCEPTION 'phase31: direct Nephilim locatedAt earth claim missing';
    END IF;

    SELECT count(*)
    INTO direct_claim_count
    FROM claim c
    JOIN proposition p ON p.proposition_id = c.proposition_id
    JOIN entity n ON n.entity_id = p.subject_entity_id
    WHERE n.entity_key = 'nephilim_gen6' AND p.predicate = 'locatedAt';
    IF direct_claim_count <> 1 THEN
        RAISE EXCEPTION 'phase31: expected exactly one Nephilim locatedAt proposition/claim pair, found %', direct_claim_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        LEFT JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE s.entity_key IN ('sons_of_god_gen6', 'daughters_of_man_gen6', 'mighty_men_gen6', 'men_of_renown_gen6', 'nephilim_gen6')
          AND NOT (
              s.entity_key = 'nephilim_gen6'
              AND p.predicate = 'locatedAt'
              AND o.entity_key = 'gen1_earth'
          )
    ) THEN
        RAISE EXCEPTION 'phase31: an unapproved identity/parentage/equivalence relationship was introduced';
    END IF;

    IF (SELECT count(*) FROM evidence WHERE evidence_key IN (
            'EV_MT_GEN_6_1_4_SONS_OF_GOD_P31',
            'EV_MT_GEN_6_1_4_DAUGHTERS_OF_MAN_P31',
            'EV_MT_GEN_6_4_MIGHTY_MEN_P31',
            'EV_MT_GEN_6_4_MEN_OF_RENOWN_P31',
            'EV_LXX_GEN_6_1_4_DISTINCT_TRADITION_P31',
            'EV_MT_NUM_13_33_INDEPENDENT_REPORT_P31',
            'EV_1EN_ETH_6_7_LATER_TRADITION_P31',
            'EV_HENDEL_2004_DIVINE_BEING_P31',
            'EV_KLINE_1962_ROYAL_HUMAN_P31',
            'EV_WENHAM_1987_WATCHERS_GIANTS_CONTEXT_P31'
        )) <> 10 THEN
        RAISE EXCEPTION 'phase31: expected Phase 31 evidence rows are missing';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM evidence e
        LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        WHERE e.evidence_key LIKE 'EV\_%\_P31' ESCAPE '\'
          AND ec.evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase31: a Phase 31 evidence row lacks citation linkage';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key IN (
            'EV_LXX_GEN_6_1_4_P30',
            'EV_MT_NUM_13_33_P30',
            'EV_1EN_ETH_6_7_P30',
            'EV_HENDEL_2004_P30',
            'EV_KLINE_1962_P30',
            'EV_WENHAM_1987_P30',
            'EV_LXX_GEN_6_1_4_DISTINCT_TRADITION_P31',
            'EV_MT_NUM_13_33_INDEPENDENT_REPORT_P31',
            'EV_1EN_ETH_6_7_LATER_TRADITION_P31',
            'EV_HENDEL_2004_DIVINE_BEING_P31',
            'EV_KLINE_1962_ROYAL_HUMAN_P31',
            'EV_WENHAM_1987_WATCHERS_GIANTS_CONTEXT_P31'
        )
    ) THEN
        RAISE EXCEPTION 'phase31: textual-comparison, later-tradition, or scholarly observations were promoted to claims';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key IN (
            'CLAIM_P31_SONS_OF_GOD_DIVINE_IDENTITY',
            'CLAIM_P31_SONS_OF_GOD_SETHITE_IDENTITY',
            'CLAIM_P31_NEPHILIM_OFFSPRING',
            'CLAIM_P31_GENESIS_NUMBERS_HARMONIZATION',
            'CLAIM_P31_GENESIS_1ENOCH_EQUIVALENCE'
        )
    ) THEN
        RAISE EXCEPTION 'phase31: interpretive or harmonization claims were persisted as authoritative claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN (
            'MT_GEN_6_1_4', 'LXX_GEN_6_1_4', 'MT_NUM_13_33', '1EN_ETH_6_7',
            'HENDEL_2004_13_26', 'KLINE_1962_187_204', 'WENHAM_1987_139_143'
        )
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) OR EXISTS (
        SELECT 1
        FROM citation
        WHERE citation_key IN (
            'CITE_MT_GEN_6_1_4', 'CITE_LXX_GEN_6_1_4', 'CITE_MT_NUM_13_33',
            'CITE_1EN_ETH_6_7', 'CITE_HENDEL_2004_13_26', 'CITE_KLINE_1962_187_204',
            'CITE_WENHAM_1987_139_143'
        )
          AND quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase31: locator-only policy violated (must remain NOT_STORED_BY_POLICY)';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        JOIN citation ci ON ci.citation_id = ec.citation_id
        JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key = 'CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30'
          AND ce.relation_type_code = 'SUPPORTS'
          AND e.evidence_key = 'EV_MT_GEN_6_1_4_P30'
          AND ci.citation_key = 'CITE_MT_GEN_6_1_4'
          AND s.source_key = 'GEN_MT'
    ) THEN
        RAISE EXCEPTION 'phase31: direct claim provenance chain is incomplete';
    END IF;

    IF (SELECT count(*) FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key IN (
            'mt-nephilim-gen-6-4',
            'mt-sons-of-god-gen-6-1-4',
            'mt-daughters-of-man-gen-6-1-4',
            'mt-mighty-men-gen-6-4',
            'mt-men-of-renown-gen-6-4'
        )
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NOT NULL
          AND COALESCE(esm.justification, '') <> '') <> 5 THEN
        RAISE EXCEPTION 'phase31: expected active source-identity mappings with evidence and justification';
    END IF;

    RAISE NOTICE 'ok: Phase 31 preserves MT/LXX distinction, independent Numbers 13:33 retrieval, and 1 Enoch/scholarship isolation';
    RAISE NOTICE 'ok: SOURCE-BACKED IS NOT TRUE; DIRECT SOURCE CLAIM IS NOT SCHOLARLY INTERPRETATION; STRUCTURAL DERIVATION IS NOT INTERPRETATION';
END $$;

-- Deterministic synthesis output (stable order, no truth ranking).
SELECT *
FROM (
    VALUES
      ('Supported by represented source evidence', 'Nephilim are explicitly mentioned in Genesis 6:4 and are represented as locatedAt earth.', 'PASS'),
      ('Interpretive possibilities', 'Sons of God identity remains contested across divine-being and Sethite/royal-human readings without ranking.', 'PASS'),
      ('Interpretive possibilities', 'Nephilim-as-offspring, relation to mighty men, and chronology remain unresolved interpretive candidates.', 'PASS WITH INTENTIONAL LIMITATION'),
      ('Not established by represented corpus', 'Genesis 6 and Numbers 13:33 are both represented but not harmonized into one population/event chronology.', 'PASS WITH INTENTIONAL LIMITATION'),
      ('Not established by represented corpus', 'Genesis 6 and 1 Enoch 6-7 are represented as distinct layers without evidentiary promotion.', 'PASS'),
      ('Not established by represented corpus', 'Truth-ranking among scholarly positions is intentionally out of scope.', 'PASS')
) AS synthesis(section, assessment, classification)
ORDER BY section, assessment;
