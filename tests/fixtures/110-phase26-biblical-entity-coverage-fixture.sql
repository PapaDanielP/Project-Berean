-- Phase 26 bounded biblical entity coverage and provenance-aware ingestion slice.
--
-- This fixture extends the accepted Phase 19-25 baseline in place. It follows the repository's
-- established manually-entered reference-point convention: locators are recorded, but
-- raw_content, content_hash, and quoted_text remain NULL (NOT_STORED_BY_POLICY). No Scripture
-- text, translation, external dataset payload, hash, quotation, date, coordinate, chronology,
-- identity reconciliation across similarly named persons, harmonization, causation, compliance,
-- violation, or theological interpretation is fabricated.
--
-- Source boundary for this phase:
--   * Genesis 5:12, 5:15, 5:18, 5:21, 5:22, 5:23, 5:24 (Masoretic reference points, GEN_MT)
--   * 1 Samuel 4:4, 4:11, 5:1, 5:2, 7:1, 7:2 (Masoretic reference points, new 1SA_MT source)
-- Joshua 3, 2 Samuel 6, Exodus 25/37/40, Deuteronomy 10:3, 1 Kings 8:9, Hebrews 9:4, and the
-- Genesis 1-11 material already accepted in earlier phases are reused unchanged.
--
-- Tier policy applied here:
--   Tier 1 (ingested)   explicit source statements, asserted through existing predicates only.
--   Tier 2 (none added) no new derivation is introduced by this phase.
--   Tier 3 (not here)   interpretive/external material stays in data/candidates/ as
--                       CANDIDATE_REQUIRES_REVIEW and never enters this fixture.
--
-- Registry sufficiency: no schema change, no new entity_type, event_type, predicate,
-- participation role, claim relation type, or table. Observations that the current registry
-- cannot express without false precision are deliberately retained as cited Evidence only and
-- are listed in docs/04-data/PHASE26_BIBLICAL_ENTITY_COVERAGE_AND_INGESTION.md:
--   * Genesis 5:23 "365 years" (total recorded days; ageAtDeathYears would assert a death
--     Genesis 5:24 does not state).
--   * Genesis 5:22/5:24 walking with God and "was not, for God took him" (no non-interpretive
--     structural representation exists).
--   * 1 Samuel 5:1 origin/destination direction (occursAt records place association only).
--   * 1 Samuel 7:1 consecration/keeping of the ark (no custodial predicate exists).
--   * 1 Samuel 7:2 "some twenty years" (a duration, not a chronological position).
BEGIN;

-- =====================================================================================
-- PART A. Genesis 5:12-24. Enoch end-to-end gap example on the existing GEN_MT source.
-- =====================================================================================

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('MT_GEN_5_12', 'Genesis 5:12'),
        ('MT_GEN_5_15', 'Genesis 5:15'),
        ('MT_GEN_5_18', 'Genesis 5:18'),
        ('MT_GEN_5_21', 'Genesis 5:21'),
        ('MT_GEN_5_22', 'Genesis 5:22'),
        ('MT_GEN_5_23', 'Genesis 5:23'),
        ('MT_GEN_5_24', 'Genesis 5:24')
     ) AS r(source_record_key, source_location)
  ON d.dataset_key = 'GEN_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN ('MT_GEN_5_12', 'MT_GEN_5_15', 'MT_GEN_5_18',
                               'MT_GEN_5_21', 'MT_GEN_5_22', 'MT_GEN_5_23', 'MT_GEN_5_24');

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('mahalalel', 'PERSON', 'Mahalalel',
     'The person named in Genesis 5:12 as begotten by Kenan and in Genesis 5:15 as the father of Jared.'),
    ('jared', 'PERSON', 'Jared',
     'The person named in Genesis 5:15 as begotten by Mahalalel and in Genesis 5:18 as the father of Enoch.'),
    ('enoch', 'PERSON', 'Enoch',
     'The person named in Genesis 5:18 as begotten by Jared and in Genesis 5:21 as the father of Methuselah. Deliberately not reconciled with the Enoch named in Genesis 4:17.'),
    ('methuselah', 'PERSON', 'Methuselah',
     'The person named in Genesis 5:21 as begotten by Enoch.');

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('mahalalel_begetting', 'GENEALOGICAL', 'The begetting of Mahalalel as recorded at Genesis 5:12.'),
    ('jared_begetting', 'GENEALOGICAL', 'The begetting of Jared as recorded at Genesis 5:15.'),
    ('enoch_begetting', 'GENEALOGICAL', 'The begetting of Enoch as recorded at Genesis 5:18.'),
    ('methuselah_begetting', 'GENEALOGICAL', 'The begetting of Methuselah as recorded at Genesis 5:21.');

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT s.entity_id, 'fatherOf', o.entity_id
FROM (VALUES ('kenan', 'mahalalel'), ('mahalalel', 'jared'),
             ('jared', 'enoch'), ('enoch', 'methuselah')) AS m(subject_key, object_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key;

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('kenan', 'parentIn', 'mahalalel_begetting'),
        ('mahalalel', 'childIn', 'mahalalel_begetting'),
        ('mahalalel', 'parentIn', 'jared_begetting'),
        ('jared', 'childIn', 'jared_begetting'),
        ('jared', 'parentIn', 'enoch_begetting'),
        ('enoch', 'childIn', 'enoch_begetting'),
        ('enoch', 'parentIn', 'methuselah_begetting'),
        ('methuselah', 'childIn', 'methuselah_begetting')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- Genesis 5:21 states Enoch's age at the begetting of Methuselah. This is the only Genesis
-- 5:12-24 numeral this phase models, because ageAtFatherhoodYears expresses it exactly.
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('YEAR', 65) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'ageAtFatherhoodYears', v.typed_value_id
FROM entity e, v WHERE e.entity_key = 'enoch';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('kenan', 'fatherOf', 'mahalalel', 'CLAIM_MT_KENAN_FATHER_MAHALALEL',
         'Genesis 5:12 records Mahalalel as begotten by Kenan.', NULL),
        ('mahalalel', 'fatherOf', 'jared', 'CLAIM_MT_MAHALALEL_FATHER_JARED',
         'Genesis 5:15 records Jared as begotten by Mahalalel.', NULL),
        ('jared', 'fatherOf', 'enoch', 'CLAIM_MT_JARED_FATHER_ENOCH',
         'Genesis 5:18 records Enoch as begotten by Jared.', NULL),
        ('enoch', 'fatherOf', 'methuselah', 'CLAIM_MT_ENOCH_FATHER_METHUSELAH',
         'Genesis 5:21 records Methuselah as begotten by Enoch.',
         'Records only the explicit begetting relation. No chronology, lifespan, or lineage completeness is asserted.')
     ) AS m(subject_key, predicate, object_key, claim_key, statement, notes)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_entity_id = o.entity_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('kenan', 'parentIn', 'mahalalel_begetting', 'CLAIM_KENAN_PARENT_MAHALALEL_BEGETTING',
         'Kenan is the parent participant in the begetting of Mahalalel.'),
        ('mahalalel', 'childIn', 'mahalalel_begetting', 'CLAIM_MAHALALEL_CHILD_MAHALALEL_BEGETTING',
         'Mahalalel is the child participant in the begetting of Mahalalel.'),
        ('mahalalel', 'parentIn', 'jared_begetting', 'CLAIM_MAHALALEL_PARENT_JARED_BEGETTING',
         'Mahalalel is the parent participant in the begetting of Jared.'),
        ('jared', 'childIn', 'jared_begetting', 'CLAIM_JARED_CHILD_JARED_BEGETTING',
         'Jared is the child participant in the begetting of Jared.'),
        ('jared', 'parentIn', 'enoch_begetting', 'CLAIM_JARED_PARENT_ENOCH_BEGETTING',
         'Jared is the parent participant in the begetting of Enoch.'),
        ('enoch', 'childIn', 'enoch_begetting', 'CLAIM_ENOCH_CHILD_ENOCH_BEGETTING',
         'Enoch is the child participant in the begetting of Enoch.'),
        ('enoch', 'parentIn', 'methuselah_begetting', 'CLAIM_ENOCH_PARENT_METHUSELAH_BEGETTING',
         'Enoch is the parent participant in the begetting of Methuselah.'),
        ('methuselah', 'childIn', 'methuselah_begetting', 'CLAIM_METHUSELAH_CHILD_METHUSELAH_BEGETTING',
         'Methuselah is the child participant in the begetting of Methuselah.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT 'CLAIM_MT_ENOCH_AGE_AT_METHUSELAH_65', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'The Masoretic tradition records Enoch as 65 years old at the begetting of Methuselah.',
       'Numeral recorded exactly as a typed value. No cumulative chronology is derived from it in this phase.'
FROM proposition p
JOIN entity s ON s.entity_id = p.subject_entity_id
JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
WHERE s.entity_key = 'enoch' AND p.predicate = 'ageAtFatherhoodYears' AND t.numeric_value = 65;

-- Evidence for every Genesis locator in the boundary, including the three locators that
-- deliberately support no claim. Their presence records source availability, never silence.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('MT_GEN_5_12', 'Genesis 5:12 records Kenan begetting Mahalalel.', NULL),
        ('MT_GEN_5_15', 'Genesis 5:15 records Mahalalel begetting Jared.', NULL),
        ('MT_GEN_5_18', 'Genesis 5:18 records Jared begetting Enoch.', NULL),
        ('MT_GEN_5_21', 'Genesis 5:21 records Enoch begetting Methuselah at 65 years.', NULL),
        ('MT_GEN_5_22', 'Genesis 5:22 records that Enoch walked with God after begetting Methuselah, and that he had other sons and daughters.',
         'Retained as a source observation only. The current predicate registry has no non-interpretive way to express walking with God, and unnamed other children are not modeled as entities.'),
        ('MT_GEN_5_23', 'Genesis 5:23 records that all the days of Enoch were 365 years.',
         'Retained as a source observation only. ageAtDeathYears would assert a death that Genesis 5:24 does not state, so the numeral is deliberately left unmodeled as a proposition.'),
        ('MT_GEN_5_24', 'Genesis 5:24 records that Enoch walked with God and was not, for God took him.',
         'Retained as a source observation only. Reading this as a death, translation, ascension, or non-death event would be interpretation rather than an explicit textual statement.')
     ) AS m(source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN citation ci ON ci.source_record_id = ev.source_record_id
WHERE ev.evidence_key IN ('EV_MT_GEN_5_12', 'EV_MT_GEN_5_15', 'EV_MT_GEN_5_18', 'EV_MT_GEN_5_21',
                          'EV_MT_GEN_5_22', 'EV_MT_GEN_5_23', 'EV_MT_GEN_5_24');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_MT_KENAN_FATHER_MAHALALEL', 'EV_MT_GEN_5_12'),
        ('CLAIM_KENAN_PARENT_MAHALALEL_BEGETTING', 'EV_MT_GEN_5_12'),
        ('CLAIM_MAHALALEL_CHILD_MAHALALEL_BEGETTING', 'EV_MT_GEN_5_12'),
        ('CLAIM_MT_MAHALALEL_FATHER_JARED', 'EV_MT_GEN_5_15'),
        ('CLAIM_MAHALALEL_PARENT_JARED_BEGETTING', 'EV_MT_GEN_5_15'),
        ('CLAIM_JARED_CHILD_JARED_BEGETTING', 'EV_MT_GEN_5_15'),
        ('CLAIM_MT_JARED_FATHER_ENOCH', 'EV_MT_GEN_5_18'),
        ('CLAIM_JARED_PARENT_ENOCH_BEGETTING', 'EV_MT_GEN_5_18'),
        ('CLAIM_ENOCH_CHILD_ENOCH_BEGETTING', 'EV_MT_GEN_5_18'),
        ('CLAIM_MT_ENOCH_FATHER_METHUSELAH', 'EV_MT_GEN_5_21'),
        ('CLAIM_ENOCH_PARENT_METHUSELAH_BEGETTING', 'EV_MT_GEN_5_21'),
        ('CLAIM_METHUSELAH_CHILD_METHUSELAH_BEGETTING', 'EV_MT_GEN_5_21'),
        ('CLAIM_MT_ENOCH_AGE_AT_METHUSELAH_65', 'EV_MT_GEN_5_21')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('mt-mahalalel', 'Mahalalel'),
        ('mt-jared', 'Jared'),
        ('mt-enoch-gen-5', 'Enoch'),
        ('mt-methuselah', 'Methuselah')
     ) AS m(source_identity_key, display_name)
JOIN source s ON s.source_key = 'GEN_MT';

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id, notes)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id, m.notes
FROM (VALUES
        ('mt-mahalalel', 'mahalalel', 0.9900,
         'Genesis 5:12 names Mahalalel in the selected Masoretic genealogical slice.', 'EV_MT_GEN_5_12', NULL),
        ('mt-jared', 'jared', 0.9900,
         'Genesis 5:15 names Jared in the selected Masoretic genealogical slice.', 'EV_MT_GEN_5_15', NULL),
        ('mt-enoch-gen-5', 'enoch', 0.9900,
         'Genesis 5:18 names Enoch as begotten by Jared in the selected Masoretic genealogical slice.', 'EV_MT_GEN_5_18',
         'This reconciliation covers the Genesis 5 Enoch only. No reconciliation with the Genesis 4:17 Enoch is asserted in either direction.'),
        ('mt-methuselah', 'methuselah', 0.9900,
         'Genesis 5:21 names Methuselah as begotten by Enoch in the selected Masoretic genealogical slice.', 'EV_MT_GEN_5_21', NULL)
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key, notes)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- =====================================================================================
-- PART B. 1 Samuel 4-7 Ark material, on a new 1 Samuel reference-point source.
-- =====================================================================================

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1SA_MT', '1 Samuel, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 1 Samuel. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, '1SA_MT_REF', '1 Samuel reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected explicit ark-lifecycle content are recorded.',
       'Manually entered reference points',
       '1 Samuel 4:4-7:2 ark presence, capture, movement, and relocation data recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '1SA_MT';

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('MT_1SA_4_4', '1 Samuel 4:4'),
        ('MT_1SA_4_11', '1 Samuel 4:11'),
        ('MT_1SA_5_1', '1 Samuel 5:1'),
        ('MT_1SA_5_2', '1 Samuel 5:2'),
        ('MT_1SA_7_1', '1 Samuel 7:1'),
        ('MT_1SA_7_2', '1 Samuel 7:2')
     ) AS r(source_record_key, source_location)
  ON d.dataset_key = '1SA_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN ('MT_1SA_4_4', 'MT_1SA_4_11', 'MT_1SA_5_1',
                               'MT_1SA_5_2', 'MT_1SA_7_1', 'MT_1SA_7_2');

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('eli', 'PERSON', 'Eli', 'The person named in 1 Samuel 4:4 as the father of Hophni and Phinehas.'),
    ('hophni', 'PERSON', 'Hophni', 'The son of Eli named in 1 Samuel 4:4 and 4:11.'),
    ('phinehas_son_of_eli', 'PERSON', 'Phinehas son of Eli',
     'The son of Eli named in 1 Samuel 4:4 and 4:11. Deliberately not reconciled with any other person named Phinehas.'),
    ('philistines', 'ORGANIZATION', 'Philistines',
     'The collective referent named in 1 Samuel 5:1-2 as taking the ark from Ebenezer to Ashdod and bringing it into the house of Dagon.'),
    ('ebenezer', 'PLACE', 'Ebenezer', 'The place named in 1 Samuel 5:1 in relation to the movement of the ark.'),
    ('ashdod', 'PLACE', 'Ashdod', 'The place named in 1 Samuel 5:1 in relation to the movement of the ark.'),
    ('house_of_dagon_ashdod', 'PLACE', 'house of Dagon',
     'The location named in 1 Samuel 5:2 into which the ark was brought. Only the named location is modeled.'),
    ('kiriath_jearim', 'PLACE', 'Kiriath-jearim',
     'The place named in 1 Samuel 7:1-2 in relation to the ark.'),
    ('abinadab', 'PERSON', 'Abinadab',
     'The person named in 1 Samuel 7:1 to whose house the ark was brought. Deliberately not reconciled with any other person named Abinadab.'),
    ('eleazar_son_of_abinadab', 'PERSON', 'Eleazar son of Abinadab',
     'The son of Abinadab named in 1 Samuel 7:1. Deliberately not reconciled with any other person named Eleazar.');

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_presence_1sam4', 'OTHER',
     '1 Samuel 4:4 records the ark of the covenant of God being brought, with Hophni and Phinehas there with it. Presence only; no compliance, authority, or handling requirement is asserted.'),
    ('ark_capture_1sam4', 'OTHER',
     '1 Samuel 4:11 records the ark of God being captured. The locator does not name the captors, so none are asserted here.'),
    ('hophni_death_1sam4', 'DEATH',
     '1 Samuel 4:11 records the death of Hophni. Cause, judgment, and any relation to ark handling are not asserted.'),
    ('phinehas_son_of_eli_death_1sam4', 'DEATH',
     '1 Samuel 4:11 records the death of Phinehas son of Eli. Cause, judgment, and any relation to ark handling are not asserted.'),
    ('ark_transport_ashdod_1sam5', 'OTHER',
     '1 Samuel 5:1 records the Philistines taking the ark of God from Ebenezer to Ashdod. Direction, route, and duration are not representable and are not asserted.'),
    ('ark_placement_house_dagon_1sam5', 'OTHER',
     '1 Samuel 5:2 records the ark being brought into the house of Dagon. Placement only; no religious interpretation is asserted.'),
    ('ark_relocation_kiriath_jearim_1sam7', 'OTHER',
     '1 Samuel 7:1 records the ark being brought to the house of Abinadab at Kiriath-jearim. Custody, consecration, and duration are not asserted.');

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_presence_1sam4'),
        ('hophni', 'participatesIn', 'ark_presence_1sam4'),
        ('phinehas_son_of_eli', 'participatesIn', 'ark_presence_1sam4'),
        ('ark_of_covenant', 'subjectOf', 'ark_capture_1sam4'),
        ('hophni', 'subjectOf', 'hophni_death_1sam4'),
        ('phinehas_son_of_eli', 'subjectOf', 'phinehas_son_of_eli_death_1sam4'),
        ('ark_of_covenant', 'subjectOf', 'ark_transport_ashdod_1sam5'),
        ('philistines', 'participatesIn', 'ark_transport_ashdod_1sam5'),
        ('ark_of_covenant', 'subjectOf', 'ark_placement_house_dagon_1sam5'),
        ('philistines', 'participatesIn', 'ark_placement_house_dagon_1sam5'),
        ('ark_of_covenant', 'subjectOf', 'ark_relocation_kiriath_jearim_1sam7'),
        ('abinadab', 'participatesIn', 'ark_relocation_kiriath_jearim_1sam7'),
        ('eleazar_son_of_abinadab', 'participatesIn', 'ark_relocation_kiriath_jearim_1sam7')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT e.event_id, 'occursAt', o.entity_id
FROM (VALUES
        ('ark_transport_ashdod_1sam5', 'ebenezer'),
        ('ark_transport_ashdod_1sam5', 'ashdod'),
        ('ark_placement_house_dagon_1sam5', 'house_of_dagon_ashdod'),
        ('ark_relocation_kiriath_jearim_1sam7', 'kiriath_jearim')
     ) AS m(event_key, place_key)
JOIN event e ON e.event_key = m.event_key
JOIN entity o ON o.entity_key = m.place_key;

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT s.entity_id, 'fatherOf', o.entity_id
FROM (VALUES ('eli', 'hophni'), ('eli', 'phinehas_son_of_eli'),
             ('abinadab', 'eleazar_son_of_abinadab')) AS m(subject_key, object_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_presence_1sam4', 'CLAIM_ARK_COVENANT_SUBJECT_PRESENCE_1SAM4',
         '1 Samuel 4:4 records the ark of the covenant of God as the subject of the recorded presence.', NULL),
        ('hophni', 'participatesIn', 'ark_presence_1sam4', 'CLAIM_HOPHNI_PARTICIPANT_PRESENCE_1SAM4',
         '1 Samuel 4:4 records Hophni as present with the ark of the covenant of God.', NULL),
        ('phinehas_son_of_eli', 'participatesIn', 'ark_presence_1sam4', 'CLAIM_PHINEHAS_PARTICIPANT_PRESENCE_1SAM4',
         '1 Samuel 4:4 records Phinehas son of Eli as present with the ark of the covenant of God.', NULL),
        ('ark_of_covenant', 'subjectOf', 'ark_capture_1sam4', 'CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4',
         '1 Samuel 4:11 records the ark of God as the subject of the recorded capture.',
         'The locator does not name the captors, so no captor participation is asserted.'),
        ('hophni', 'subjectOf', 'hophni_death_1sam4', 'CLAIM_HOPHNI_SUBJECT_DEATH_1SAM4',
         '1 Samuel 4:11 records the death of Hophni.', NULL),
        ('phinehas_son_of_eli', 'subjectOf', 'phinehas_son_of_eli_death_1sam4', 'CLAIM_PHINEHAS_SUBJECT_DEATH_1SAM4',
         '1 Samuel 4:11 records the death of Phinehas son of Eli.', NULL),
        ('ark_of_covenant', 'subjectOf', 'ark_transport_ashdod_1sam5', 'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_ASHDOD_1SAM5',
         '1 Samuel 5:1 records the ark of God as the object taken from Ebenezer to Ashdod.', NULL),
        ('philistines', 'participatesIn', 'ark_transport_ashdod_1sam5', 'CLAIM_PHILISTINES_PARTICIPANT_TRANSPORT_ASHDOD_1SAM5',
         '1 Samuel 5:1 records the Philistines as taking the ark of God from Ebenezer to Ashdod.', NULL),
        ('ark_of_covenant', 'subjectOf', 'ark_placement_house_dagon_1sam5', 'CLAIM_ARK_COVENANT_SUBJECT_HOUSE_DAGON_1SAM5',
         '1 Samuel 5:2 records the ark of God as the object brought into the house of Dagon.', NULL),
        ('philistines', 'participatesIn', 'ark_placement_house_dagon_1sam5', 'CLAIM_PHILISTINES_PARTICIPANT_HOUSE_DAGON_1SAM5',
         '1 Samuel 5:2 records the Philistines as bringing the ark into the house of Dagon.', NULL),
        ('ark_of_covenant', 'subjectOf', 'ark_relocation_kiriath_jearim_1sam7', 'CLAIM_ARK_COVENANT_SUBJECT_RELOCATION_KIRIATH_JEARIM_1SAM7',
         '1 Samuel 7:1 records the ark of the LORD as the object brought to the house of Abinadab.', NULL),
        ('abinadab', 'participatesIn', 'ark_relocation_kiriath_jearim_1sam7', 'CLAIM_ABINADAB_PARTICIPANT_RELOCATION_1SAM7',
         '1 Samuel 7:1 records Abinadab as the person to whose house the ark was brought.', NULL),
        ('eleazar_son_of_abinadab', 'participatesIn', 'ark_relocation_kiriath_jearim_1sam7', 'CLAIM_ELEAZAR_PARTICIPANT_RELOCATION_1SAM7',
         '1 Samuel 7:1 records Eleazar son of Abinadab in relation to the ark at the house of Abinadab.',
         'Consecration and keeping remain unmodeled: the registry has no custodial or consecration predicate, and adding one merely to raise coverage is out of scope.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement, notes)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('ark_transport_ashdod_1sam5', 'ebenezer', 'CLAIM_TRANSPORT_ASHDOD_OCCURS_AT_EBENEZER_1SAM5',
         '1 Samuel 5:1 names Ebenezer in relation to the recorded movement of the ark.',
         'occursAt records place association only. The origin/destination direction stated by the locator is not representable by the current registry and is retained in evidence.'),
        ('ark_transport_ashdod_1sam5', 'ashdod', 'CLAIM_TRANSPORT_ASHDOD_OCCURS_AT_ASHDOD_1SAM5',
         '1 Samuel 5:1 names Ashdod in relation to the recorded movement of the ark.',
         'occursAt records place association only. The origin/destination direction stated by the locator is not representable by the current registry and is retained in evidence.'),
        ('ark_placement_house_dagon_1sam5', 'house_of_dagon_ashdod', 'CLAIM_HOUSE_DAGON_PLACEMENT_OCCURS_AT_1SAM5',
         '1 Samuel 5:2 names the house of Dagon as the location of the recorded placement.', NULL),
        ('ark_relocation_kiriath_jearim_1sam7', 'kiriath_jearim', 'CLAIM_RELOCATION_OCCURS_AT_KIRIATH_JEARIM_1SAM7',
         '1 Samuel 7:1 names Kiriath-jearim in relation to the recorded relocation of the ark.', NULL)
     ) AS m(event_key, place_key, claim_key, statement, notes)
JOIN event e ON e.event_key = m.event_key
JOIN entity o ON o.entity_key = m.place_key
JOIN proposition p ON p.subject_event_id = e.event_id
                  AND p.object_entity_id = o.entity_id
                  AND p.predicate = 'occursAt';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('eli', 'hophni', 'CLAIM_MT_ELI_FATHER_HOPHNI',
         '1 Samuel 4:4 records Hophni as a son of Eli.'),
        ('eli', 'phinehas_son_of_eli', 'CLAIM_MT_ELI_FATHER_PHINEHAS',
         '1 Samuel 4:4 records Phinehas as a son of Eli.'),
        ('abinadab', 'eleazar_son_of_abinadab', 'CLAIM_MT_ABINADAB_FATHER_ELEAZAR',
         '1 Samuel 7:1 records Eleazar as a son of Abinadab.')
     ) AS m(subject_key, object_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_entity_id = o.entity_id
                  AND p.predicate = 'fatherOf';

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('MT_1SA_4_4', '1 Samuel 4:4 records the ark of the covenant of God being brought, and names Hophni and Phinehas, the two sons of Eli, as there with it.', NULL),
        ('MT_1SA_4_11', '1 Samuel 4:11 records the ark of God being captured and the deaths of Hophni and Phinehas.', NULL),
        ('MT_1SA_5_1', '1 Samuel 5:1 records the Philistines taking the ark of God and bringing it from Ebenezer to Ashdod.',
         'The origin/destination direction is recorded here as a source observation because the current predicate registry expresses place association only.'),
        ('MT_1SA_5_2', '1 Samuel 5:2 records the ark being brought into the house of Dagon and set beside Dagon.',
         'The named referent Dagon is retained as a source observation. It has no non-interpretive entity_type in the current controlled vocabulary and remains a candidate.'),
        ('MT_1SA_7_1', '1 Samuel 7:1 records the men of Kiriath-jearim bringing the ark to the house of Abinadab and consecrating his son Eleazar to keep it.',
         'Consecration and keeping are retained as source observations because the registry has no custodial or consecration predicate.'),
        ('MT_1SA_7_2', '1 Samuel 7:2 records that the ark remained at Kiriath-jearim a long time, some twenty years.',
         'Retained as a source observation only. The twenty-year figure is a duration, and yearsFromCreation expresses a chronological position rather than a duration.')
     ) AS m(source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN citation ci ON ci.source_record_id = ev.source_record_id
WHERE ev.evidence_key IN ('EV_MT_1SA_4_4', 'EV_MT_1SA_4_11', 'EV_MT_1SA_5_1',
                          'EV_MT_1SA_5_2', 'EV_MT_1SA_7_1', 'EV_MT_1SA_7_2');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_ARK_COVENANT_SUBJECT_PRESENCE_1SAM4', 'EV_MT_1SA_4_4'),
        ('CLAIM_HOPHNI_PARTICIPANT_PRESENCE_1SAM4', 'EV_MT_1SA_4_4'),
        ('CLAIM_PHINEHAS_PARTICIPANT_PRESENCE_1SAM4', 'EV_MT_1SA_4_4'),
        ('CLAIM_MT_ELI_FATHER_HOPHNI', 'EV_MT_1SA_4_4'),
        ('CLAIM_MT_ELI_FATHER_PHINEHAS', 'EV_MT_1SA_4_4'),
        ('CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4', 'EV_MT_1SA_4_11'),
        ('CLAIM_HOPHNI_SUBJECT_DEATH_1SAM4', 'EV_MT_1SA_4_11'),
        ('CLAIM_PHINEHAS_SUBJECT_DEATH_1SAM4', 'EV_MT_1SA_4_11'),
        ('CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_ASHDOD_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_PHILISTINES_PARTICIPANT_TRANSPORT_ASHDOD_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_TRANSPORT_ASHDOD_OCCURS_AT_EBENEZER_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_TRANSPORT_ASHDOD_OCCURS_AT_ASHDOD_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_ARK_COVENANT_SUBJECT_HOUSE_DAGON_1SAM5', 'EV_MT_1SA_5_2'),
        ('CLAIM_PHILISTINES_PARTICIPANT_HOUSE_DAGON_1SAM5', 'EV_MT_1SA_5_2'),
        ('CLAIM_HOUSE_DAGON_PLACEMENT_OCCURS_AT_1SAM5', 'EV_MT_1SA_5_2'),
        ('CLAIM_ARK_COVENANT_SUBJECT_RELOCATION_KIRIATH_JEARIM_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ABINADAB_PARTICIPANT_RELOCATION_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ELEAZAR_PARTICIPANT_RELOCATION_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_MT_ABINADAB_FATHER_ELEAZAR', 'EV_MT_1SA_7_1'),
        ('CLAIM_RELOCATION_OCCURS_AT_KIRIATH_JEARIM_1SAM7', 'EV_MT_1SA_7_1')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('mt-eli-1sa-4-4', 'Eli'),
        ('mt-hophni-1sa-4-4', 'Hophni'),
        ('mt-phinehas-1sa-4-4', 'Phinehas'),
        ('mt-philistines-1sa-5-1', 'the Philistines'),
        ('mt-ebenezer-1sa-5-1', 'Ebenezer'),
        ('mt-ashdod-1sa-5-1', 'Ashdod'),
        ('mt-house-of-dagon-1sa-5-2', 'the house of Dagon'),
        ('mt-kiriath-jearim-1sa-7-1', 'Kiriath-jearim'),
        ('mt-abinadab-1sa-7-1', 'Abinadab'),
        ('mt-eleazar-1sa-7-1', 'Eleazar')
     ) AS m(source_identity_key, display_name)
JOIN source s ON s.source_key = '1SA_MT';

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id, notes)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id, m.notes
FROM (VALUES
        ('mt-eli-1sa-4-4', 'eli', 0.9900, '1 Samuel 4:4 names Eli as the father of the two named sons.', 'EV_MT_1SA_4_4', NULL),
        ('mt-hophni-1sa-4-4', 'hophni', 0.9900, '1 Samuel 4:4 names Hophni with the ark.', 'EV_MT_1SA_4_4', NULL),
        ('mt-phinehas-1sa-4-4', 'phinehas_son_of_eli', 0.9500,
         '1 Samuel 4:4 names Phinehas as a son of Eli, which fixes this source identity to the Eli-son referent only.', 'EV_MT_1SA_4_4',
         'Deliberately not reconciled with any other person named Phinehas. Similar naming is not identity.'),
        ('mt-philistines-1sa-5-1', 'philistines', 0.9900, '1 Samuel 5:1 names the Philistines as taking the ark.', 'EV_MT_1SA_5_1', NULL),
        ('mt-ebenezer-1sa-5-1', 'ebenezer', 0.9900, '1 Samuel 5:1 names Ebenezer in relation to the movement of the ark.', 'EV_MT_1SA_5_1', NULL),
        ('mt-ashdod-1sa-5-1', 'ashdod', 0.9900, '1 Samuel 5:1 names Ashdod in relation to the movement of the ark.', 'EV_MT_1SA_5_1', NULL),
        ('mt-house-of-dagon-1sa-5-2', 'house_of_dagon_ashdod', 0.9500,
         '1 Samuel 5:2 names the house of Dagon as the location the ark was brought into.', 'EV_MT_1SA_5_2',
         'The referent Dagon itself remains a reviewer candidate and is not created as an entity.'),
        ('mt-kiriath-jearim-1sa-7-1', 'kiriath_jearim', 0.9900, '1 Samuel 7:1 names Kiriath-jearim in relation to the ark.', 'EV_MT_1SA_7_1', NULL),
        ('mt-abinadab-1sa-7-1', 'abinadab', 0.9500,
         '1 Samuel 7:1 names Abinadab as the person to whose house the ark was brought.', 'EV_MT_1SA_7_1',
         'Deliberately not reconciled with any other person named Abinadab.'),
        ('mt-eleazar-1sa-7-1', 'eleazar_son_of_abinadab', 0.9500,
         '1 Samuel 7:1 names Eleazar as a son of Abinadab, which fixes this source identity to the Abinadab-son referent only.', 'EV_MT_1SA_7_1',
         'Deliberately not reconciled with any other person named Eleazar.')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key, notes)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

COMMIT;
