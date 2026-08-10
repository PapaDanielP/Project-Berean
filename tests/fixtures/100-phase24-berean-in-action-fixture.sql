-- Phase 24 Berean in Action real-knowledge demonstration fixture.
--
-- This fixture extends the accepted Phase 16-19 Ark-of-the-Covenant data in place. It adds a
-- bounded temple-placement source slice from 1 Kings 8:1-9 and 2 Chronicles 5:2-10, preserving
-- the established reference-point convention: source locators are recorded, but raw_content,
-- content_hash, and quoted_text remain NULL. No Scripture quotation, hash, source silence,
-- contradiction, compliance, causation, theology, or global factual-core promotion is inferred.
--
-- The slice demonstrates actual knowledge construction with the existing substrate: two new
-- sources, source records, citations, evidence, canonical/source identities, propositions,
-- direct claims, projected event participation, multiple source-backed claims for one normalized
-- proposition, and one genuine cross-source derived claim whose inputs are explicit direct claims.
BEGIN;

-- 1. Sources and datasets for the temple-placement comparison slice.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1KI_MT', '1 Kings, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 1 Kings. No text is stored in this repository.'),
    ('2CH_MT', '2 Chronicles, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 2 Chronicles. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, '1KI_MT_REF', '1 Kings reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected temple-placement content are recorded.',
       'Manually entered reference points',
       '1 Kings 8:1-9 Ark-of-the-Covenant temple-placement observations recorded with existing predicates; no text imported.'
FROM source WHERE source_key = '1KI_MT'
UNION ALL
SELECT source_id, '2CH_MT_REF', '2 Chronicles reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected temple-placement content are recorded.',
       'Manually entered reference points',
       '2 Chronicles 5:2-10 Ark-of-the-Covenant temple-placement observations recorded with existing predicates; no text imported.'
FROM source WHERE source_key = '2CH_MT';

-- 2. Bounded source records and unquoted citations.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('1KI_MT_REF', 'MT_1KI_8_1', '1 Kings 8:1'),
        ('1KI_MT_REF', 'MT_1KI_8_3', '1 Kings 8:3'),
        ('1KI_MT_REF', 'MT_1KI_8_4', '1 Kings 8:4'),
        ('1KI_MT_REF', 'MT_1KI_8_6', '1 Kings 8:6'),
        ('1KI_MT_REF', 'MT_1KI_8_9', '1 Kings 8:9'),
        ('2CH_MT_REF', 'MT_2CH_5_2', '2 Chronicles 5:2'),
        ('2CH_MT_REF', 'MT_2CH_5_4', '2 Chronicles 5:4'),
        ('2CH_MT_REF', 'MT_2CH_5_5', '2 Chronicles 5:5'),
        ('2CH_MT_REF', 'MT_2CH_5_7', '2 Chronicles 5:7'),
        ('2CH_MT_REF', 'MT_2CH_5_10', '2 Chronicles 5:10')
     ) AS r(dataset_key, source_record_key, source_location)
  ON r.dataset_key = d.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'MT_1KI_8_1', 'MT_1KI_8_3', 'MT_1KI_8_4', 'MT_1KI_8_6', 'MT_1KI_8_9',
    'MT_2CH_5_2', 'MT_2CH_5_4', 'MT_2CH_5_5', 'MT_2CH_5_7', 'MT_2CH_5_10');

-- 3. New persistent referents required by the selected slice.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('solomon', 'PERSON', 'Solomon', 'The king who assembles Israel in the selected 1 Kings 8 / 2 Chronicles 5 temple-placement slice.'),
    ('elders_of_israel_solomon_assembly', 'ORGANIZATION', 'elders of Israel assembled by Solomon', 'The collective Israelite elders/heads/chiefs assembled in the selected temple-placement source slice.'),
    ('priests_levites_temple_ark_bearers', 'ORGANIZATION', 'priests and Levites bearing the ark in the temple-placement slice', 'The priestly/Levitical group recorded as bringing up and placing the Ark in 1 Kings 8 and 2 Chronicles 5.'),
    ('solomon_temple_inner_sanctuary', 'PLACE', 'inner sanctuary of Solomon''s temple', 'The inner sanctuary / most holy place named as the Ark placement location in the selected source slice.'),
    ('tent_of_meeting', 'OBJECT', 'tent of meeting', 'The tent of meeting brought up with the Ark in the selected 1 Kings 8 / 2 Chronicles 5 source slice.'),
    ('sanctuary_vessels_temporal_slice', 'OBJECT', 'holy vessels in the temple-placement slice', 'The holy vessels brought up with the Ark and tent in the selected temple-placement source slice.');

-- 4. Events. These are descriptive historical occurrences, not compliance, causation, or theology.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_temple_assembly', 'OTHER',
     '1 Kings 8:1 and 2 Chronicles 5:2 record Solomon assembling Israelite leaders for bringing up the Ark. This asserts assembly only, not political theory or theology.'),
    ('ark_covenant_temple_transfer', 'OTHER',
     '1 Kings 8:3-4 and 2 Chronicles 5:4-5 record the Ark, tent of meeting, and holy vessels being brought up by priestly/Levitical participants. This asserts no route, duration, compliance, or pole/ring state.'),
    ('ark_covenant_temple_placement', 'OTHER',
     '1 Kings 8:6 and 2 Chronicles 5:7 record the Ark being brought into its place in the inner sanctuary. This is distinct from construction, standing requirement, Joshua transport, and 2 Samuel new-cart transport events.');

-- 5. Propositions: event participation and location using only existing predicates.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('solomon', 'subjectOf', 'ark_covenant_temple_assembly'),
        ('elders_of_israel_solomon_assembly', 'participatesIn', 'ark_covenant_temple_assembly'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_temple_transfer'),
        ('tent_of_meeting', 'participatesIn', 'ark_covenant_temple_transfer'),
        ('sanctuary_vessels_temporal_slice', 'participatesIn', 'ark_covenant_temple_transfer'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_transfer'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_temple_placement'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_placement')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT e.event_id, 'occursAt', pl.entity_id
FROM event e
JOIN entity pl ON pl.entity_key = 'solomon_temple_inner_sanctuary'
WHERE e.event_key = 'ark_covenant_temple_placement';

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT ark.entity_id, 'locatedAt', pl.entity_id
FROM entity ark
JOIN entity pl ON pl.entity_key = 'solomon_temple_inner_sanctuary'
WHERE ark.entity_key = 'ark_of_covenant';

-- 6. Direct source claims. The existing ark_of_covenant containsContent tablets_of_testimony
--    proposition is reused instead of duplicating semantic authority.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('solomon', 'subjectOf', 'ark_covenant_temple_assembly', 'CLAIM_1KI_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY',
         '1 Kings 8:1 records Solomon assembling Israelite leaders for bringing up the Ark.'),
        ('elders_of_israel_solomon_assembly', 'participatesIn', 'ark_covenant_temple_assembly', 'CLAIM_1KI_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY',
         '1 Kings 8:1 records Israelite leaders assembled in the Ark temple-placement context.'),
        ('solomon', 'subjectOf', 'ark_covenant_temple_assembly', 'CLAIM_2CH_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY',
         '2 Chronicles 5:2 records Solomon assembling Israelite leaders for bringing up the Ark.'),
        ('elders_of_israel_solomon_assembly', 'participatesIn', 'ark_covenant_temple_assembly', 'CLAIM_2CH_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY',
         '2 Chronicles 5:2 records Israelite leaders assembled in the Ark temple-placement context.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_1KI_ARK_PARTICIPANT_TEMPLE_TRANSFER',
         '1 Kings 8:4 records the Ark being brought up in the temple-placement sequence.'),
        ('tent_of_meeting', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_1KI_TENT_PARTICIPANT_TEMPLE_TRANSFER',
         '1 Kings 8:4 records the tent of meeting being brought up with the Ark.'),
        ('sanctuary_vessels_temporal_slice', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_1KI_VESSELS_PARTICIPANT_TEMPLE_TRANSFER',
         '1 Kings 8:4 records holy vessels being brought up with the Ark and tent.'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_1KI_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
         '1 Kings 8:3-4 records priestly/Levitical participants bringing up the Ark and related sanctuary objects.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_2CH_ARK_PARTICIPANT_TEMPLE_TRANSFER',
         '2 Chronicles 5:5 records the Ark being brought up in the temple-placement sequence.'),
        ('tent_of_meeting', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_2CH_TENT_PARTICIPANT_TEMPLE_TRANSFER',
         '2 Chronicles 5:5 records the tent of meeting being brought up with the Ark.'),
        ('sanctuary_vessels_temporal_slice', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_2CH_VESSELS_PARTICIPANT_TEMPLE_TRANSFER',
         '2 Chronicles 5:5 records holy vessels being brought up with the Ark and tent.'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_transfer', 'CLAIM_2CH_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
         '2 Chronicles 5:4-5 records Levitical priests bringing up the Ark and related sanctuary objects.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_temple_placement', 'CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT',
         '1 Kings 8:6 records the Ark being brought into its place in the inner sanctuary.'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_placement', 'CLAIM_1KI_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT',
         '1 Kings 8:6 records priests bringing the Ark into its place.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_temple_placement', 'CLAIM_2CH_ARK_SUBJECT_TEMPLE_PLACEMENT',
         '2 Chronicles 5:7 records priests bringing the Ark into its place.'),
        ('priests_levites_temple_ark_bearers', 'participatesIn', 'ark_covenant_temple_placement', 'CLAIM_2CH_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT',
         '2 Chronicles 5:7 records priests bringing the Ark into its place.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('ark_covenant_temple_placement', 'occursAt', 'solomon_temple_inner_sanctuary', 'CLAIM_1KI_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY',
         '1 Kings 8:6 records the Ark placement event as occurring in the inner sanctuary.'),
        ('ark_covenant_temple_placement', 'occursAt', 'solomon_temple_inner_sanctuary', 'CLAIM_2CH_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY',
         '2 Chronicles 5:7 records the Ark placement event as occurring in the inner sanctuary.')
     ) AS m(event_key, predicate, object_key, claim_key, statement)
JOIN event e ON e.event_key = m.event_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_event_id = e.event_id AND p.object_entity_id = o.entity_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('CLAIM_1KI_ARK_LOCATED_INNER_SANCTUARY',
         '1 Kings 8:6 records the Ark as placed in the inner sanctuary.'),
        ('CLAIM_2CH_ARK_LOCATED_INNER_SANCTUARY',
         '2 Chronicles 5:7 records the Ark as placed in the inner sanctuary.')
     ) AS m(claim_key, statement)
JOIN entity ark ON ark.entity_key = 'ark_of_covenant'
JOIN entity pl ON pl.entity_key = 'solomon_temple_inner_sanctuary'
JOIN proposition p ON p.subject_entity_id = ark.entity_id AND p.object_entity_id = pl.entity_id
                  AND p.predicate = 'locatedAt';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
         '1 Kings 8:9 records the Ark contents in the temple-placement context as the two tablets of stone.'),
        ('CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
         '2 Chronicles 5:10 records the Ark contents in the temple-placement context as the two tablets.')
     ) AS m(claim_key, statement)
JOIN entity ark ON ark.entity_key = 'ark_of_covenant'
JOIN entity tablets ON tablets.entity_key = 'tablets_of_testimony'
JOIN proposition p ON p.subject_entity_id = ark.entity_id AND p.object_entity_id = tablets.entity_id
                  AND p.predicate = 'containsContent';

-- 7. Evidence and citations.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('MT_1KI_8_1', '1 Kings 8:1 records Solomon assembling Israelite leaders in Jerusalem in order to bring up the Ark.', NULL),
        ('MT_1KI_8_3', '1 Kings 8:3 records Israelite elders arriving and priests taking up the Ark.', NULL),
        ('MT_1KI_8_4', '1 Kings 8:4 records the Ark, tent of meeting, and holy vessels being brought up by priests and Levites.', NULL),
        ('MT_1KI_8_6', '1 Kings 8:6 records priests bringing the Ark into its place in the inner sanctuary.', NULL),
        ('MT_1KI_8_9', '1 Kings 8:9 records the Ark contents in the temple-placement context as the two stone tablets; no broader inventory conclusion is inferred.', 'The source description is preserved without inferring source silence from unstored text.'),
        ('MT_2CH_5_2', '2 Chronicles 5:2 records Solomon assembling Israelite leaders in Jerusalem to bring up the Ark.', NULL),
        ('MT_2CH_5_4', '2 Chronicles 5:4 records Israelite elders arriving and Levites taking up the Ark.', NULL),
        ('MT_2CH_5_5', '2 Chronicles 5:5 records the Ark, tent of meeting, and holy vessels being brought up by Levitical priests.', NULL),
        ('MT_2CH_5_7', '2 Chronicles 5:7 records priests bringing the Ark into its place in the inner sanctuary.', NULL),
        ('MT_2CH_5_10', '2 Chronicles 5:10 records the Ark contents in the temple-placement context as the two tablets; no broader inventory conclusion is inferred.', 'The source description is preserved without inferring source silence from unstored text.')
     ) AS m(source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key IN (
    'EV_MT_1KI_8_1', 'EV_MT_1KI_8_3', 'EV_MT_1KI_8_4', 'EV_MT_1KI_8_6', 'EV_MT_1KI_8_9',
    'EV_MT_2CH_5_2', 'EV_MT_2CH_5_4', 'EV_MT_2CH_5_5', 'EV_MT_2CH_5_7', 'EV_MT_2CH_5_10');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_1KI_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY', 'EV_MT_1KI_8_1'),
        ('CLAIM_1KI_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY', 'EV_MT_1KI_8_1'),
        ('CLAIM_2CH_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY', 'EV_MT_2CH_5_2'),
        ('CLAIM_2CH_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY', 'EV_MT_2CH_5_2'),
        ('CLAIM_1KI_ARK_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_1KI_8_4'),
        ('CLAIM_1KI_TENT_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_1KI_8_4'),
        ('CLAIM_1KI_VESSELS_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_1KI_8_4'),
        ('CLAIM_1KI_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_1KI_8_3'),
        ('CLAIM_1KI_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_1KI_8_4'),
        ('CLAIM_2CH_ARK_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_2CH_5_5'),
        ('CLAIM_2CH_TENT_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_2CH_5_5'),
        ('CLAIM_2CH_VESSELS_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_2CH_5_5'),
        ('CLAIM_2CH_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_2CH_5_4'),
        ('CLAIM_2CH_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER', 'EV_MT_2CH_5_5'),
        ('CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT', 'EV_MT_1KI_8_6'),
        ('CLAIM_1KI_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT', 'EV_MT_1KI_8_6'),
        ('CLAIM_2CH_ARK_SUBJECT_TEMPLE_PLACEMENT', 'EV_MT_2CH_5_7'),
        ('CLAIM_2CH_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT', 'EV_MT_2CH_5_7'),
        ('CLAIM_1KI_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY', 'EV_MT_1KI_8_6'),
        ('CLAIM_2CH_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY', 'EV_MT_2CH_5_7'),
        ('CLAIM_1KI_ARK_LOCATED_INNER_SANCTUARY', 'EV_MT_1KI_8_6'),
        ('CLAIM_2CH_ARK_LOCATED_INNER_SANCTUARY', 'EV_MT_2CH_5_7'),
        ('CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION', 'EV_MT_1KI_8_9'),
        ('CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION', 'EV_MT_2CH_5_10')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 8. Source-specific identities remain distinct from canonical entities.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('1KI_MT', 'mt1ki-solomon-8', 'Solomon'),
        ('1KI_MT', 'mt1ki-ark-8', 'the ark'),
        ('1KI_MT', 'mt1ki-priests-8', 'the priests and Levites'),
        ('1KI_MT', 'mt1ki-inner-sanctuary-8', 'the inner sanctuary'),
        ('2CH_MT', 'mt2ch-solomon-5', 'Solomon'),
        ('2CH_MT', 'mt2ch-ark-5', 'the ark'),
        ('2CH_MT', 'mt2ch-levitical-priests-5', 'the Levitical priests'),
        ('2CH_MT', 'mt2ch-inner-sanctuary-5', 'the most holy place')
     ) AS m(source_key, source_identity_key, display_name)
JOIN source s ON s.source_key = m.source_key;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt1ki-solomon-8', 'solomon', 0.9900, '1 Kings 8:1 names Solomon in the selected temple-placement slice.', 'EV_MT_1KI_8_1'),
        ('mt1ki-ark-8', 'ark_of_covenant', 0.9900, '1 Kings 8:1 identifies the Ark as the object being brought up.', 'EV_MT_1KI_8_1'),
        ('mt1ki-priests-8', 'priests_levites_temple_ark_bearers', 0.9800, '1 Kings 8:3-4 identifies the priestly/Levitical participants in the selected slice.', 'EV_MT_1KI_8_4'),
        ('mt1ki-inner-sanctuary-8', 'solomon_temple_inner_sanctuary', 0.9900, '1 Kings 8:6 identifies the inner sanctuary as the Ark placement location.', 'EV_MT_1KI_8_6'),
        ('mt2ch-solomon-5', 'solomon', 0.9900, '2 Chronicles 5:2 names Solomon in the selected temple-placement slice.', 'EV_MT_2CH_5_2'),
        ('mt2ch-ark-5', 'ark_of_covenant', 0.9900, '2 Chronicles 5:2 identifies the Ark as the object being brought up.', 'EV_MT_2CH_5_2'),
        ('mt2ch-levitical-priests-5', 'priests_levites_temple_ark_bearers', 0.9800, '2 Chronicles 5:4-5 identifies Levitical priests in the selected slice.', 'EV_MT_2CH_5_5'),
        ('mt2ch-inner-sanctuary-5', 'solomon_temple_inner_sanctuary', 0.9900, '2 Chronicles 5:7 identifies the inner sanctuary / most holy place as the Ark placement location.', 'EV_MT_2CH_5_7')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 9. Genuine derived claim: a normalized cross-source comparison of the two source-backed
--    temple contents claims. This does not assert truth, sufficiency, source silence, or a global
--    factual core; it records that these selected source claims assert the same proposition.
INSERT INTO derivation (method, assumptions)
VALUES ('Cross-source comparison of normalized Ark contents propositions in the temple-placement slice',
        'Only the selected 1 Kings 8:9 and 2 Chronicles 5:10 direct source claims are compared; the result is structural agreement on the existing ark_of_covenant containsContent tablets_of_testimony proposition and does not infer exhaustive inventory, truth, source silence, or contradiction.');

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED', p.proposition_id, 'DERIVED_CLAIM',
       'The selected 1 Kings 8:9 and 2 Chronicles 5:10 claims share the normalized proposition that the Ark of the Covenant contains the tablets of the testimony.',
       d.derivation_id
FROM proposition p
JOIN entity ark ON ark.entity_id = p.subject_entity_id
JOIN entity tablets ON tablets.entity_id = p.object_entity_id
CROSS JOIN derivation d
WHERE ark.entity_key = 'ark_of_covenant'
  AND tablets.entity_key = 'tablets_of_testimony'
  AND p.predicate = 'containsContent'
  AND d.method = 'Cross-source comparison of normalized Ark contents propositions in the temple-placement slice';

INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, c.claim_id, m.notes
FROM (VALUES
        ('CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION', '1 Kings direct source claim for the shared normalized proposition.'),
        ('CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION', '2 Chronicles direct source claim for the shared normalized proposition.')
     ) AS m(claim_key, notes)
JOIN derivation d ON d.method = 'Cross-source comparison of normalized Ark contents propositions in the temple-placement slice'
JOIN claim c ON c.claim_key = m.claim_key;

COMMIT;
