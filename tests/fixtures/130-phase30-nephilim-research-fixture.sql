-- Phase 30 bounded Genesis 6:1-4 / Nephilim research corpus.
--
-- This fixture records one directly representable biblical assertion and preserves
-- textual, later-tradition, and scholarly materials as separately sourced observations.
-- No quoted source text is stored, and no interpretation is promoted to a biblical claim.
BEGIN;

-- Biblical reference points: Genesis traditions for comparison and the later biblical reference.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('NUM_MT', 'Numbers, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic textual tradition of Numbers. No source text is stored in this repository.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, 'NUM_MT_REF', 'Numbers reference points, Masoretic tradition', 'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected source observations are recorded.',
       'Manually entered reference points',
       'Phase 30 records Numbers 13:33 as a later biblical reference without harmonization.'
FROM source s WHERE s.source_key = 'NUM_MT'
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('GEN_MT_REF', 'MT_GEN_6_1_4', 'Genesis 6:1-4'),
        ('GEN_LXX_REF', 'LXX_GEN_6_1_4', 'Genesis 6:1-4'),
        ('NUM_MT_REF', 'MT_NUM_13_33', 'Numbers 13:33')
     ) AS r(dataset_key, source_record_key, source_location) ON d.dataset_key = r.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

-- Later tradition and published scholarship are source records, not biblical knowledge.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1EN_ETH', '1 Enoch, Ethiopic textual tradition', 'HISTORICAL_WORK',
     'Later Jewish tradition reference point used for bounded comparison; no source text is stored.'),
    ('HENDEL_2004', 'Ronald S. Hendel, Of Demigods and the Deluge', 'REFERENCE',
     'Published scholarly interpretation reference; not a biblical source.'),
    ('KLINE_1962', 'Meredith G. Kline, Divine Kingship and Genesis 6:1-4', 'REFERENCE',
     'Published scholarly interpretation reference; not a biblical source.'),
    ('WENHAM_1987', 'Gordon J. Wenham, Genesis 1-15', 'REFERENCE',
     'Published scholarly interpretation reference; not a biblical source.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, d.dataset_key, d.name, d.edition_label, 'ref-1',
       'Locator-only bibliography; no quoted source text is reproduced.',
       'Manually entered bounded research references', d.notes
FROM source s
JOIN (VALUES
        ('1EN_ETH', '1EN_ETH_REF', '1 Enoch reference points', 'Ethiopic textual tradition',
         'Phase 30 later-tradition observation only.'),
        ('HENDEL_2004', 'HENDEL_2004_REF', 'Hendel 2004 reference points', 'Journal of Biblical Literature 123.1',
         'Phase 30 scholarly-position candidate only.'),
        ('KLINE_1962', 'KLINE_1962_REF', 'Kline 1962 reference points', 'Westminster Theological Journal 24',
         'Phase 30 scholarly-position candidate only.'),
        ('WENHAM_1987', 'WENHAM_1987_REF', 'Wenham 1987 reference points', 'Word Biblical Commentary 1',
         'Phase 30 scholarly-position candidate only.')
     ) AS d(source_key, dataset_key, name, edition_label, notes) ON s.source_key = d.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('1EN_ETH_REF', '1EN_ETH_6_7', '1 Enoch 6-7'),
        ('HENDEL_2004_REF', 'HENDEL_2004_13_26', 'Journal of Biblical Literature 123.1 (2004): 13-26'),
        ('KLINE_1962_REF', 'KLINE_1962_187_204', 'Westminster Theological Journal 24 (1962): 187-204'),
        ('WENHAM_1987_REF', 'WENHAM_1987_139_143', 'Genesis 1-15 (1987), pages 139-143')
     ) AS r(dataset_key, source_record_key, source_location) ON d.dataset_key = r.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'MT_GEN_6_1_4', 'LXX_GEN_6_1_4', 'MT_NUM_13_33', '1EN_ETH_6_7',
    'HENDEL_2004_13_26', 'KLINE_1962_187_204', 'WENHAM_1987_139_143'
)
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, m.evidence_type_code, m.notes
FROM (VALUES
        ('EV_MT_GEN_6_1_4_P30', 'MT_GEN_6_1_4',
         'Genesis 6:1-4 explicitly mentions the Nephilim and states that they were on the earth.',
         'SOURCE_OBSERVATION', 'No identity, origin, chronology, or offspring conclusion is asserted.'),
        ('EV_LXX_GEN_6_1_4_P30', 'LXX_GEN_6_1_4',
         'The selected Septuagint Genesis 6:1-4 reference point is retained for textual-tradition comparison.',
         'SOURCE_OBSERVATION', 'No translation equivalence or contradiction judgment is asserted.'),
        ('EV_MT_NUM_13_33_P30', 'MT_NUM_13_33',
         'Numbers 13:33 contains a later biblical reference to Nephilim in the speakers'' report.',
         'SOURCE_OBSERVATION', 'This later report is not harmonized with Genesis or evaluated as historical fact.'),
        ('EV_1EN_ETH_6_7_P30', '1EN_ETH_6_7',
         '1 Enoch 6-7 develops a Watchers-and-giants account associated with the Genesis passage.',
         'SOURCE_OBSERVATION', 'Later tradition is not the Genesis primary source and is not a biblical direct claim.'),
        ('EV_HENDEL_2004_P30', 'HENDEL_2004_13_26',
         'Hendel presents a divine-being reading of the sons of God and treats the passage in a demigod tradition.',
         'ANALYTICAL_OBSERVATION', 'Scholarly-position candidate; not a biblical source observation or a claim about biblical truth.'),
        ('EV_KLINE_1962_P30', 'KLINE_1962_187_204',
         'Kline presents an alternative royal-human interpretation of the sons of God.',
         'ANALYTICAL_OBSERVATION', 'Scholarly-position candidate; it coexists with other readings without resolution.'),
        ('EV_WENHAM_1987_P30', 'WENHAM_1987_139_143',
         'Wenham discusses the divine-being interpretation and the passage''s relation to ancient tradition.',
         'ANALYTICAL_OBSERVATION', 'Scholarly-position candidate; no consensus or truth status is inferred.')
     ) AS m(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN citation c ON c.source_record_id = sr.source_record_id
WHERE e.evidence_key LIKE 'EV\_%\_P30' ESCAPE '\'
ON CONFLICT DO NOTHING;

-- The only direct biblical proposition added: the source explicitly places the named Nephilim on earth.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description)
VALUES ('nephilim_gen6', 'CONCEPT', 'Nephilim in Genesis 6:4',
        'The named referent in Genesis 6:4; its identity, origin, and relation to other groups remain unresolved.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT n.entity_id, 'locatedAt', earth.entity_id
FROM entity n
JOIN entity earth ON earth.entity_key = 'gen1_earth'
WHERE n.entity_key = 'nephilim_gen6'
  AND NOT EXISTS (
      SELECT 1 FROM proposition p
      WHERE p.subject_entity_id = n.entity_id AND p.predicate = 'locatedAt' AND p.object_entity_id = earth.entity_id
  );

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT 'CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Genesis 6:4 explicitly mentions the Nephilim and states that they were on the earth.',
       'Direct source assertion only. It does not identify the Nephilim, infer their origin, or decide the relation of the clause to other terms in the passage.'
FROM proposition p
JOIN entity n ON n.entity_id = p.subject_entity_id
JOIN entity earth ON earth.entity_id = p.object_entity_id
WHERE n.entity_key = 'nephilim_gen6' AND earth.entity_key = 'gen1_earth' AND p.predicate = 'locatedAt'
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Direct Genesis 6:4 source observation support.'
FROM claim c
JOIN evidence e ON e.evidence_key = 'EV_MT_GEN_6_1_4_P30'
WHERE c.claim_key = 'CLAIM_MT_GEN_6_4_NEPHILIM_ON_EARTH_P30'
ON CONFLICT DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, 'mt-nephilim-gen-6-4', 'Nephilim'
FROM source s WHERE s.source_key = 'GEN_MT'
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, n.entity_id, 'ACTIVE', 0.9800,
       'Genesis 6:4 explicitly names the Nephilim at the cited reference point.',
       e.evidence_id
FROM source_identity si
JOIN entity n ON n.entity_key = 'nephilim_gen6'
JOIN evidence e ON e.evidence_key = 'EV_MT_GEN_6_1_4_P30'
WHERE si.source_identity_key = 'mt-nephilim-gen-6-4'
  AND NOT EXISTS (
      SELECT 1 FROM entity_source_mapping esm
      WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = n.entity_id
        AND esm.mapping_status_code = 'ACTIVE'
  );

COMMIT;
