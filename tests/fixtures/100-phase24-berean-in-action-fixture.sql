-- Phase 24 Berean-in-action knowledge slice: Ark of the Covenant lifecycle from
-- Shiloh through Philistine capture and Kiriath-jearim (1 Samuel 4-7).
--
-- This fixture extends the accepted Phase 19 Ark lifecycle baseline in place. It
-- deliberately adds no schema, registry, event type, predicate, claim-relation
-- type, inference machinery, evaluator output, or persistence behavior. It uses
-- the existing generic OTHER event type and the existing subjectOf,
-- participatesIn, and occursAt predicates.
--
-- Source policy: locators are recorded, but raw_content, content_hash, and
-- quoted_text remain NULL. No verbatim Scripture text, translation, source hash,
-- contradiction, compliance/violation finding, theological conclusion, or
-- causation is fabricated. The source observations summarize well-known public
-- locator content in the same reference-point style as the accepted Genesis,
-- Exodus, Joshua, and 2 Samuel fixtures.
--
-- Source differences preserved: Joshua 3:6 records priestly carrying before the
-- people; 1 Samuel 4-7 records capture, Philistine movement, and custody at
-- Kiriath-jearim; 2 Samuel 6:3 records a new-cart transport. Phase 24 records
-- these as distinct source-backed events. Difference is not automatically
-- classified as contradiction, violation, compliance, causation, or punishment.
BEGIN;

-- 1. Source and dataset for 1 Samuel.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1SA_MT', '1 Samuel, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 1 Samuel. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, '1SA_MT_REF', '1 Samuel reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected published Ark lifecycle content are recorded.',
       'Manually entered reference points',
       '1 Samuel 4-7 Ark capture/movement/custody data recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '1SA_MT';

-- 2. Bounded locators.
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
WHERE sr.source_record_key IN (
    'MT_1SA_4_4', 'MT_1SA_4_11', 'MT_1SA_5_1',
    'MT_1SA_5_2', 'MT_1SA_7_1', 'MT_1SA_7_2');

-- 3. Persistent referents justified by the selected source slice.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('philistines', 'ORGANIZATION', 'Philistines',
     'The collective Philistine group explicitly associated with the Ark capture and movement in 1 Samuel 4-5.'),
    ('men_kiriath_jearim', 'ORGANIZATION', 'men of Kiriath-jearim',
     'The group in 1 Samuel 7:1 recorded as bringing up the Ark to the house of Abinadab.'),
    ('eleazar_son_abinadab', 'PERSON', 'Eleazar son of Abinadab',
     'The named person in 1 Samuel 7:1 set apart to keep the Ark.'),
    ('ashdod', 'PLACE', 'Ashdod',
     'The Philistine city named in 1 Samuel 5:1 as the destination after the Ark was taken from Ebenezer.'),
    ('house_dagon_ashdod', 'PLACE', 'house of Dagon at Ashdod',
     'The source-identified place in 1 Samuel 5:2 where the Ark was brought and set beside Dagon.'),
    ('house_abinadab_kiriath_jearim', 'PLACE', 'house of Abinadab at Kiriath-jearim',
     'The source-identified place in 1 Samuel 7:1 where the Ark was brought.'),
    ('kiriath_jearim', 'PLACE', 'Kiriath-jearim',
     'The place named in 1 Samuel 7:1-2 in connection with the Ark.');

-- 4. Events. OTHER is sufficient: these are historical source-recorded
--    occurrences/custody states, not construction, instruction, death, or standing requirements.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_brought_from_shiloh_1sam4', 'OTHER',
     '1 Samuel 4:4 records the Ark of the Covenant/Ark of God being brought from Shiloh to the Israelite camp context. This does not assert route, carrier identity, compliance, or pole state.'),
    ('ark_covenant_captured_1sam4', 'OTHER',
     '1 Samuel 4:11 records the Ark of God being taken. This capture event does not infer theological cause, punishment, or contradiction with any transport requirement.'),
    ('ark_covenant_moved_to_ashdod_1sam5', 'OTHER',
     '1 Samuel 5:1 records the Philistines taking the Ark of God from Ebenezer to Ashdod. This is represented as a source-recorded movement occurrence, not as permanent location truth.'),
    ('ark_covenant_set_in_house_dagon_1sam5', 'OTHER',
     '1 Samuel 5:2 records the Ark being brought into the house of Dagon and set there. This records source-backed placement only, without theological inference.'),
    ('ark_covenant_brought_to_abinadab_house_1sam7', 'OTHER',
     '1 Samuel 7:1 records the men of Kiriath-jearim bringing the Ark to the house of Abinadab.'),
    ('ark_covenant_care_eleazar_1sam7', 'OTHER',
     '1 Samuel 7:1 records Eleazar son of Abinadab being set apart in connection with keeping the Ark. This does not infer office, duration, or sufficiency.'),
    ('ark_covenant_stay_kiriath_jearim_1sam7', 'OTHER',
     '1 Samuel 7:2 records the Ark remaining at Kiriath-jearim for a long period. The twenty-year duration is preserved in evidence text but not promoted to a typed proposition because no duration predicate exists.');

-- 5. Entity/event propositions.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_brought_from_shiloh_1sam4'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_captured_1sam4'),
        ('philistines', 'participatesIn', 'ark_covenant_captured_1sam4'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_moved_to_ashdod_1sam5'),
        ('philistines', 'participatesIn', 'ark_covenant_moved_to_ashdod_1sam5'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_set_in_house_dagon_1sam5'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_brought_to_abinadab_house_1sam7'),
        ('men_kiriath_jearim', 'participatesIn', 'ark_covenant_brought_to_abinadab_house_1sam7'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_care_eleazar_1sam7'),
        ('eleazar_son_abinadab', 'participatesIn', 'ark_covenant_care_eleazar_1sam7'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_stay_kiriath_jearim_1sam7')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- 6. Event/place propositions.
INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT e.event_id, 'occursAt', p.entity_id
FROM (VALUES
        ('ark_covenant_moved_to_ashdod_1sam5', 'ashdod'),
        ('ark_covenant_set_in_house_dagon_1sam5', 'house_dagon_ashdod'),
        ('ark_covenant_brought_to_abinadab_house_1sam7', 'house_abinadab_kiriath_jearim'),
        ('ark_covenant_care_eleazar_1sam7', 'house_abinadab_kiriath_jearim'),
        ('ark_covenant_stay_kiriath_jearim_1sam7', 'kiriath_jearim')
     ) AS m(event_key, place_key)
JOIN event e ON e.event_key = m.event_key
JOIN entity p ON p.entity_key = m.place_key;

-- 7. Claims for entity/event propositions.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_brought_from_shiloh_1sam4',
         'CLAIM_ARK_COVENANT_SUBJECT_BROUGHT_FROM_SHILOH_1SAM4',
         '1 Samuel 4:4 records the Ark of the Covenant/Ark of God being brought from Shiloh.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_captured_1sam4',
         'CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4',
         '1 Samuel 4:11 records the Ark of God being taken.'),
        ('philistines', 'participatesIn', 'ark_covenant_captured_1sam4',
         'CLAIM_PHILISTINES_PARTICIPANT_CAPTURE_1SAM4',
         '1 Samuel 4:11 records the Philistines in the context of the Ark being taken.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_moved_to_ashdod_1sam5',
         'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5',
         '1 Samuel 5:1 records the Ark of God being taken from Ebenezer to Ashdod.'),
        ('philistines', 'participatesIn', 'ark_covenant_moved_to_ashdod_1sam5',
         'CLAIM_PHILISTINES_PARTICIPANT_MOVED_ASHDOD_1SAM5',
         '1 Samuel 5:1 records the Philistines moving the Ark from Ebenezer to Ashdod.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_set_in_house_dagon_1sam5',
         'CLAIM_ARK_COVENANT_SUBJECT_HOUSE_DAGON_1SAM5',
         '1 Samuel 5:2 records the Ark being brought into the house of Dagon and set there.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_brought_to_abinadab_house_1sam7',
         'CLAIM_ARK_COVENANT_SUBJECT_ABINADAB_HOUSE_1SAM7',
         '1 Samuel 7:1 records the Ark being brought to the house of Abinadab.'),
        ('men_kiriath_jearim', 'participatesIn', 'ark_covenant_brought_to_abinadab_house_1sam7',
         'CLAIM_MEN_KIRIATH_JEARIM_PARTICIPANT_ABINADAB_HOUSE_1SAM7',
         '1 Samuel 7:1 records the men of Kiriath-jearim bringing the Ark to the house of Abinadab.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_care_eleazar_1sam7',
         'CLAIM_ARK_COVENANT_SUBJECT_ELEAZAR_CARE_1SAM7',
         '1 Samuel 7:1 records Eleazar son of Abinadab being set apart in connection with keeping the Ark.'),
        ('eleazar_son_abinadab', 'participatesIn', 'ark_covenant_care_eleazar_1sam7',
         'CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7',
         '1 Samuel 7:1 records Eleazar son of Abinadab being set apart to keep the Ark.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_stay_kiriath_jearim_1sam7',
         'CLAIM_ARK_COVENANT_SUBJECT_STAY_KIRIATH_JEARIM_1SAM7',
         '1 Samuel 7:2 records the Ark remaining at Kiriath-jearim for a long period.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

-- 8. Claims for event/place propositions.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('ark_covenant_moved_to_ashdod_1sam5', 'ashdod',
         'CLAIM_ARK_MOVEMENT_ASHDOD_PLACE_1SAM5',
         '1 Samuel 5:1 records Ashdod as the destination in the Ark movement from Ebenezer.'),
        ('ark_covenant_set_in_house_dagon_1sam5', 'house_dagon_ashdod',
         'CLAIM_ARK_HOUSE_DAGON_PLACE_1SAM5',
         '1 Samuel 5:2 records the house of Dagon as the place where the Ark was brought and set.'),
        ('ark_covenant_brought_to_abinadab_house_1sam7', 'house_abinadab_kiriath_jearim',
         'CLAIM_ARK_ABINADAB_HOUSE_PLACE_1SAM7',
         '1 Samuel 7:1 records the house of Abinadab as the place to which the Ark was brought.'),
        ('ark_covenant_care_eleazar_1sam7', 'house_abinadab_kiriath_jearim',
         'CLAIM_ELEAZAR_CARE_ABINADAB_HOUSE_PLACE_1SAM7',
         '1 Samuel 7:1 records Eleazar son of Abinadab in the house-of-Abinadab Ark custody context.'),
        ('ark_covenant_stay_kiriath_jearim_1sam7', 'kiriath_jearim',
         'CLAIM_ARK_STAY_KIRIATH_JEARIM_PLACE_1SAM7',
         '1 Samuel 7:2 records Kiriath-jearim as the place where the Ark remained.')
     ) AS m(event_key, place_key, claim_key, statement)
JOIN event e ON e.event_key = m.event_key
JOIN entity place ON place.entity_key = m.place_key
JOIN proposition p ON p.subject_event_id = e.event_id
                  AND p.object_entity_id = place.entity_id
                  AND p.predicate = 'occursAt';

-- 9. Evidence: one cited source observation per locator.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('MT_1SA_4_4', '1 Samuel 4:4 records the people sending to Shiloh and bringing from there the Ark of the Covenant/Ark of God into the camp context.', NULL),
        ('MT_1SA_4_11', '1 Samuel 4:11 records the Ark of God being taken in the Philistine battle context.', 'Hophni and Phinehas are recorded in the locator but not modeled as Phase 24 entities because the bounded demonstration focuses on the Ark lifecycle path.'),
        ('MT_1SA_5_1', '1 Samuel 5:1 records the Philistines taking the Ark of God from Ebenezer and bringing it to Ashdod.', NULL),
        ('MT_1SA_5_2', '1 Samuel 5:2 records the Philistines bringing the Ark of God into the house of Dagon and setting it there.', 'No theological interpretation is recorded.'),
        ('MT_1SA_7_1', '1 Samuel 7:1 records the men of Kiriath-jearim bringing the Ark to the house of Abinadab and setting apart Eleazar son of Abinadab to keep it.', NULL),
        ('MT_1SA_7_2', '1 Samuel 7:2 records the Ark remaining at Kiriath-jearim for a long period, described in the source as twenty years.', 'The duration is intentionally not converted into a structured proposition because the current predicate registry has no event-duration predicate.')
     ) AS m(source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key IN (
    'EV_MT_1SA_4_4', 'EV_MT_1SA_4_11', 'EV_MT_1SA_5_1',
    'EV_MT_1SA_5_2', 'EV_MT_1SA_7_1', 'EV_MT_1SA_7_2');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_ARK_COVENANT_SUBJECT_BROUGHT_FROM_SHILOH_1SAM4', 'EV_MT_1SA_4_4'),
        ('CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4', 'EV_MT_1SA_4_11'),
        ('CLAIM_PHILISTINES_PARTICIPANT_CAPTURE_1SAM4', 'EV_MT_1SA_4_11'),
        ('CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_PHILISTINES_PARTICIPANT_MOVED_ASHDOD_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_ARK_MOVEMENT_ASHDOD_PLACE_1SAM5', 'EV_MT_1SA_5_1'),
        ('CLAIM_ARK_COVENANT_SUBJECT_HOUSE_DAGON_1SAM5', 'EV_MT_1SA_5_2'),
        ('CLAIM_ARK_HOUSE_DAGON_PLACE_1SAM5', 'EV_MT_1SA_5_2'),
        ('CLAIM_ARK_COVENANT_SUBJECT_ABINADAB_HOUSE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_MEN_KIRIATH_JEARIM_PARTICIPANT_ABINADAB_HOUSE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ARK_ABINADAB_HOUSE_PLACE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ARK_COVENANT_SUBJECT_ELEAZAR_CARE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ELEAZAR_CARE_ABINADAB_HOUSE_PLACE_1SAM7', 'EV_MT_1SA_7_1'),
        ('CLAIM_ARK_COVENANT_SUBJECT_STAY_KIRIATH_JEARIM_1SAM7', 'EV_MT_1SA_7_2'),
        ('CLAIM_ARK_STAY_KIRIATH_JEARIM_PLACE_1SAM7', 'EV_MT_1SA_7_2')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 10. Source identities and evidence-backed mappings. These mappings preserve
--     source-specific names ("Ark of God", group labels, and places) as distinct
--     source identities mapped to canonical entities; they do not merge sources.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('mt-ark-god-1sam4-7', 'Ark of God'),
        ('mt-philistines-1sam4-5', 'Philistines'),
        ('mt-men-kiriath-jearim-1sam7', 'men of Kiriath-jearim'),
        ('mt-eleazar-abinadab-1sam7', 'Eleazar son of Abinadab'),
        ('mt-ashdod-1sam5', 'Ashdod'),
        ('mt-house-dagon-1sam5', 'house of Dagon'),
        ('mt-house-abinadab-1sam7', 'house of Abinadab'),
        ('mt-kiriath-jearim-1sam7', 'Kiriath-jearim')
     ) AS m(source_identity_key, display_name)
JOIN source s ON s.source_key = '1SA_MT';

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-ark-god-1sam4-7', 'ark_of_covenant', 0.9600, '1 Samuel 4:4 names the Ark of the Covenant/Ark of God in the selected lifecycle slice.', 'EV_MT_1SA_4_4'),
        ('mt-philistines-1sam4-5', 'philistines', 0.9900, '1 Samuel 5:1 identifies the Philistines as the group moving the Ark.', 'EV_MT_1SA_5_1'),
        ('mt-men-kiriath-jearim-1sam7', 'men_kiriath_jearim', 0.9900, '1 Samuel 7:1 identifies the men of Kiriath-jearim as bringing up the Ark.', 'EV_MT_1SA_7_1'),
        ('mt-eleazar-abinadab-1sam7', 'eleazar_son_abinadab', 0.9900, '1 Samuel 7:1 names Eleazar son of Abinadab in the Ark custody context.', 'EV_MT_1SA_7_1'),
        ('mt-ashdod-1sam5', 'ashdod', 0.9900, '1 Samuel 5:1 names Ashdod in the Ark movement event.', 'EV_MT_1SA_5_1'),
        ('mt-house-dagon-1sam5', 'house_dagon_ashdod', 0.9900, '1 Samuel 5:2 identifies the house of Dagon as the place where the Ark was brought.', 'EV_MT_1SA_5_2'),
        ('mt-house-abinadab-1sam7', 'house_abinadab_kiriath_jearim', 0.9900, '1 Samuel 7:1 identifies the house of Abinadab as the place where the Ark was brought.', 'EV_MT_1SA_7_1'),
        ('mt-kiriath-jearim-1sam7', 'kiriath_jearim', 0.9900, '1 Samuel 7:2 names Kiriath-jearim as the place where the Ark remained.', 'EV_MT_1SA_7_2')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

COMMIT;
