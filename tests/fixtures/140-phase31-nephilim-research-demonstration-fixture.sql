-- Phase 31 deterministic scholarly-research demonstration over the existing Phase 30 corpus.
-- This fixture adds explicit term-level observations and source-identity mappings without
-- promoting interpretive, later-tradition, or scholarly material to biblical claims.
BEGIN;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, m.evidence_type_code, m.notes
FROM (VALUES
        ('EV_MT_GEN_6_1_4_SONS_OF_GOD_P31', 'MT_GEN_6_1_4',
         'Genesis 6:1-4 explicitly mentions sons of God.', 'SOURCE_OBSERVATION',
         'No identity resolution is asserted (divine being, Sethite, or royal-human).'),
        ('EV_MT_GEN_6_1_4_DAUGHTERS_OF_MAN_P31', 'MT_GEN_6_1_4',
         'Genesis 6:1-4 explicitly mentions daughters of man.', 'SOURCE_OBSERVATION',
         'No theological or anthropological interpretation is promoted.'),
        ('EV_MT_GEN_6_4_MIGHTY_MEN_P31', 'MT_GEN_6_1_4',
         'Genesis 6:4 explicitly mentions mighty men.', 'SOURCE_OBSERVATION',
         'No identity equivalence with Nephilim is inferred.'),
        ('EV_MT_GEN_6_4_MEN_OF_RENOWN_P31', 'MT_GEN_6_1_4',
         'Genesis 6:4 explicitly mentions men of renown.', 'SOURCE_OBSERVATION',
         'No rank, chronology, or genealogical interpretation is promoted.'),
        ('EV_LXX_GEN_6_1_4_DISTINCT_TRADITION_P31', 'LXX_GEN_6_1_4',
         'The represented Septuagint locator for Genesis 6:1-4 is retained as a distinct textual tradition.',
         'SOURCE_OBSERVATION',
         'No harmonization, superiority, contradiction, or translation-error judgment is asserted.'),
        ('EV_MT_NUM_13_33_INDEPENDENT_REPORT_P31', 'MT_NUM_13_33',
         'Numbers 13:33 is retained as a later biblical report mentioning Nephilim.', 'SOURCE_OBSERVATION',
         'No automatic harmonization with Genesis 6:1-4 is asserted.'),
        ('EV_1EN_ETH_6_7_LATER_TRADITION_P31', '1EN_ETH_6_7',
         '1 Enoch 6-7 is retained as later Jewish tradition associated with Genesis 6 reception.',
         'SOURCE_OBSERVATION',
         'Later tradition is not promoted to a Genesis direct-source claim.'),
        ('EV_HENDEL_2004_DIVINE_BEING_P31', 'HENDEL_2004_13_26',
         'Hendel presents a divine-being reading for sons of God and treats the passage in demigod tradition.',
         'ANALYTICAL_OBSERVATION',
         'Competing scholarly interpretation retained without truth ranking.'),
        ('EV_KLINE_1962_ROYAL_HUMAN_P31', 'KLINE_1962_187_204',
         'Kline presents a Sethite/royal-human interpretation as an alternative reading.',
         'ANALYTICAL_OBSERVATION',
         'Competing scholarly interpretation retained without contradiction labeling.'),
        ('EV_WENHAM_1987_WATCHERS_GIANTS_CONTEXT_P31', 'WENHAM_1987_139_143',
         'Wenham discusses divine-being and giants-tradition interpretive context for Genesis 6:1-4.',
         'ANALYTICAL_OBSERVATION',
         'Competing scholarly interpretation retained without consensus ranking.')
     ) AS m(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN citation c ON c.source_record_id = sr.source_record_id
WHERE e.evidence_key LIKE 'EV\_%\_P31' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('sons_of_god_gen6', 'CONCEPT', 'Sons of God in Genesis 6:1-4',
     'Named term in Genesis 6:1-4 preserved without identity interpretation.'),
    ('daughters_of_man_gen6', 'CONCEPT', 'Daughters of man in Genesis 6:1-4',
     'Named term in Genesis 6:1-4 preserved without inferred relationships.'),
    ('mighty_men_gen6', 'CONCEPT', 'Mighty men in Genesis 6:4',
     'Named term in Genesis 6:4 preserved without identity resolution.'),
    ('men_of_renown_gen6', 'CONCEPT', 'Men of renown in Genesis 6:4',
     'Named term in Genesis 6:4 preserved without ranking or harmonization.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, x.source_identity_key, x.display_name
FROM source s
JOIN (VALUES
        ('mt-sons-of-god-gen-6-1-4', 'sons of God'),
        ('mt-daughters-of-man-gen-6-1-4', 'daughters of man'),
        ('mt-mighty-men-gen-6-4', 'mighty men'),
        ('mt-men-of-renown-gen-6-4', 'men of renown')
     ) AS x(source_identity_key, display_name) ON s.source_key = 'GEN_MT'
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, e.entity_id, 'ACTIVE', 0.9800, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-sons-of-god-gen-6-1-4', 'sons_of_god_gen6', 'EV_MT_GEN_6_1_4_SONS_OF_GOD_P31',
         'Genesis 6:1-4 explicitly names sons of God at the cited locator.'),
        ('mt-daughters-of-man-gen-6-1-4', 'daughters_of_man_gen6', 'EV_MT_GEN_6_1_4_DAUGHTERS_OF_MAN_P31',
         'Genesis 6:1-4 explicitly names daughters of man at the cited locator.'),
        ('mt-mighty-men-gen-6-4', 'mighty_men_gen6', 'EV_MT_GEN_6_4_MIGHTY_MEN_P31',
         'Genesis 6:4 explicitly names mighty men at the cited locator.'),
        ('mt-men-of-renown-gen-6-4', 'men_of_renown_gen6', 'EV_MT_GEN_6_4_MEN_OF_RENOWN_P31',
         'Genesis 6:4 explicitly names men of renown at the cited locator.')
     ) AS m(source_identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity e ON e.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key
WHERE NOT EXISTS (
    SELECT 1
    FROM entity_source_mapping esm
    WHERE esm.source_identity_id = si.source_identity_id
      AND esm.entity_id = e.entity_id
      AND esm.mapping_status_code = 'ACTIVE'
);

COMMIT;
