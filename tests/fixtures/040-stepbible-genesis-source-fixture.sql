-- STEP Bible bounded Genesis source acquisition fixture.
--
-- Scope: exactly one acquired source record, Genesis 1:1 at STEP Bible locator `Gen.1.1`.
--
-- No upstream text is reproduced. `raw_content` stays NULL and citations carry a locator with no
-- `quoted_text`, because the acquired file's own notice asks downstream users not to redistribute
-- the data. `content_hash` records the SHA-256 of the acquired `Gen.1.1#` row block, which fixes
-- exactly what was inspected without distributing it. See data/external/stepbible/.
--
-- Attribution: Data from STEP Bible (www.STEPBible.org), based on work at Tyndale House,
-- Cambridge, licensed CC BY 4.0.
--
-- This fixture extends the Genesis 1-11 fixture in place and does not truncate it. STEP Bible
-- assertions stay source-specific: a distinct source, dataset, source record, citation, evidence,
-- and claims. The claims reuse the existing Genesis 1:1 propositions rather than duplicating the
-- GEN_MT_REF structural records, because the normalized semantics are the same and only the
-- source provenance differs.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('STEP_TAHOT', 'STEP Bible Translators Amalgamated Hebrew Old Testament', 'DATASET',
     'Acquired external dataset from STEPBible/STEPBible-Data at pinned commit '
     || 'b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39. Data from STEP Bible (www.STEPBible.org), '
     || 'based on work at Tyndale House, Cambridge, licensed CC BY 4.0. No upstream payload is '
     || 'stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, 'STEP_TAHOT_GEN', 'STEP Bible TAHOT, Genesis acquisition subset',
       'TAHOT Gen-Deu file at pinned commit b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39',
       'b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39',
       'CC BY 4.0 verified at file level on 2026-08-10. Attribution required: STEP Bible '
       || '(www.STEPBible.org) and Tyndale House, Cambridge. The file notice additionally asks '
       || 'that the data not be redistributed downstream, so no upstream payload is stored here.',
       'Pinned raw-file download of upstream commit b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39 on '
       || '2026-08-10; see scripts/acquisition/fetch-stepbible.sh and '
       || 'data/external/stepbible/ACQUISITION_MANIFEST.yaml.',
       'No transformation of upstream data. Only the SHA-256 of the acquired Gen.1.1 row block '
       || 'and its row count are recorded; no text, gloss, or transliteration is imported.'
FROM source WHERE source_key = 'STEP_TAHOT';

INSERT INTO source_record (dataset_id, source_record_key, source_location, content_hash, revision_label)
SELECT d.dataset_id, 'STEP_TAHOT_GEN_1_1',
       'Translators Amalgamated OT+NT/TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - '
       || 'STEPBible.org CC BY.txt @ b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39 :: Gen.1.1',
       '28cdf66fc9d5c6e913595bbba12adc2a8059fb066cbcb0019d677ae883836e11',
       'b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39'
FROM dataset d WHERE d.dataset_key = 'STEP_TAHOT_GEN';

-- The STEP Bible locator format is Book.Chapter.Verse; it is preserved rather than rewritten.
INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_STEP_TAHOT_GEN_1_1', sr.source_record_id, 'Gen.1.1'
FROM source_record sr WHERE sr.source_record_key = 'STEP_TAHOT_GEN_1_1';

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('EV_STEP_TAHOT_GEN_1_1_CREATION_SUBJECT',
         'The acquired STEP Bible TAHOT record for locator Gen.1.1 consists of seven word-level '
         || 'tagged rows in which a qal-perfect third-person-masculine-singular verb tagged '
         || 'H1254A (to create) is tagged together with the nominal H0430 (God), presenting God '
         || 'as the subject of the creation statement.',
         'Observation of published lexical and morphological tags only. No upstream text is '
         || 'reproduced and no theological conclusion is asserted.'),
        ('EV_STEP_TAHOT_GEN_1_1_CREATION_OBJECTS',
         'The acquired STEP Bible TAHOT record for locator Gen.1.1 tags two object-marked nominals '
         || 'within the same statement, H8064 (heaven/heavens) and H0776 (earth/land).',
         'Observation of published lexical and morphological tags only. No upstream text is '
         || 'reproduced and no theological conclusion is asserted.')
     ) AS m(evidence_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = 'STEP_TAHOT_GEN_1_1';

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key IN ('EV_STEP_TAHOT_GEN_1_1_CREATION_SUBJECT',
                         'EV_STEP_TAHOT_GEN_1_1_CREATION_OBJECTS');

-- Source-specific claims that reuse the already-normalized Genesis 1:1 propositions.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement,
       'STEP Bible assertion kept distinct from the GEN_MT_REF structural claim for the same '
       || 'proposition; only source provenance differs.'
FROM (VALUES
        ('gen1_god', 'subjectOf', 'gen1_1_creation_statement',
         'CLAIM_STEP_TAHOT_GEN_1_1_GOD_SUBJECT_CREATION',
         'The acquired STEP Bible TAHOT data presents God as the subject of the Genesis 1:1 '
         || 'creation statement.'),
        ('gen1_heavens', 'participatesIn', 'gen1_1_creation_statement',
         'CLAIM_STEP_TAHOT_GEN_1_1_HEAVENS_CREATION_PARTICIPANT',
         'The acquired STEP Bible TAHOT data presents the heavens within the Genesis 1:1 '
         || 'creation statement.'),
        ('gen1_earth', 'participatesIn', 'gen1_1_creation_statement',
         'CLAIM_STEP_TAHOT_GEN_1_1_EARTH_CREATION_PARTICIPANT',
         'The acquired STEP Bible TAHOT data presents the earth within the Genesis 1:1 '
         || 'creation statement.')
     ) AS m(subject_key, predicate, object_event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event ev ON ev.event_key = m.object_event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = ev.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', m.notes
FROM (VALUES
        ('CLAIM_STEP_TAHOT_GEN_1_1_GOD_SUBJECT_CREATION',
         'EV_STEP_TAHOT_GEN_1_1_CREATION_SUBJECT',
         'The acquired record supports only the source-presented subject role.'),
        ('CLAIM_STEP_TAHOT_GEN_1_1_HEAVENS_CREATION_PARTICIPANT',
         'EV_STEP_TAHOT_GEN_1_1_CREATION_OBJECTS',
         'The acquired record supports participation in the statement, not a semantic claim '
         || 'about the referent.'),
        ('CLAIM_STEP_TAHOT_GEN_1_1_EARTH_CREATION_PARTICIPANT',
         'EV_STEP_TAHOT_GEN_1_1_CREATION_OBJECTS',
         'The acquired record supports participation in the statement, not a semantic claim '
         || 'about the referent.')
     ) AS m(claim_key, evidence_key, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key;

COMMIT;
