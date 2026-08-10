-- Phase 24 Berean-in-action Ark-of-the-Covenant temple-placement slice: 1 Kings 8:3-4, 8:6-9
-- and 2 Chronicles 5:4-5, 5:7-10.
--
-- This fixture extends the Phase 16-19 Ark-of-the-Covenant data in place. It follows the
-- repository's established manually-entered reference-point convention: locators are recorded,
-- but raw_content, content_hash, and quoted_text remain NULL. No Scripture text, quotation,
-- translation, hash, contradiction, compliance finding, causal claim, or theological inference is
-- fabricated.
--
-- The bounded source slice is exactly 1 Kings 8:3-4, 8:6-9 and 2 Chronicles 5:4-5, 5:7-10. The
-- single canonical `ark_of_covenant` and `poles_ark_covenant` OBJECT entities are reused without
-- duplication. This phase also reuses the existing `priests_levites_ark_bearers` ORGANIZATION
-- entity from Phase 18 instead of manufacturing a second canonical bearer entity from the
-- source-level wording difference between 1 Kings 8:3 (priests took up the ark) and
-- 2 Chronicles 5:4 (Levites took up the ark). That wording difference is preserved in separate
-- direct claims, source observations, and source-identity mappings; it is not resolved by a
-- ClaimRelation and is not collapsed into a new truth core.
--
-- Registry sufficiency: no schema, event_type, predicate, role, table, JSON payload, or
-- relationship extension is added. The existing generic OTHER event_type and the existing
-- subjectOf / participatesIn predicates are sufficient for the bounded temple-placement,
-- pole-visibility, and tablets-only-content observations. One genuine DERIVED_CLAIM is added only
-- for the shared cross-source pole-visibility observation, following the existing Genesis
-- cross-source-comparison pattern: the inputs remain explicit, the bearer-wording difference stays
-- separate, and no compliance/violation or contradiction is inferred.
BEGIN;

-- 1. Sources and datasets for the bounded 1 Kings / 2 Chronicles reference-point slice.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1KI_MT', '1 Kings, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 1 Kings. No text is stored in this repository.'),
    ('2CH_MT', '2 Chronicles, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 2 Chronicles. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, '1KI_MT_REF', '1 Kings reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected published temple-placement content are recorded.',
       'Manually entered reference points',
       '1 Kings 8:3-4, 8:6-9 Ark temple-placement data recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '1KI_MT'
UNION ALL
SELECT source_id, '2CH_MT_REF', '2 Chronicles reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected published temple-placement content are recorded.',
       'Manually entered reference points',
       '2 Chronicles 5:4-5, 5:7-10 Ark temple-placement data recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '2CH_MT';

-- 2. Exact bounded locators and unquoted citations.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('1KI_MT_REF', 'MT_1KI_8_3', '1 Kings 8:3'),
        ('1KI_MT_REF', 'MT_1KI_8_4', '1 Kings 8:4'),
        ('1KI_MT_REF', 'MT_1KI_8_6', '1 Kings 8:6'),
        ('1KI_MT_REF', 'MT_1KI_8_7', '1 Kings 8:7'),
        ('1KI_MT_REF', 'MT_1KI_8_8', '1 Kings 8:8'),
        ('1KI_MT_REF', 'MT_1KI_8_9', '1 Kings 8:9'),
        ('2CH_MT_REF', 'MT_2CH_5_4', '2 Chronicles 5:4'),
        ('2CH_MT_REF', 'MT_2CH_5_5', '2 Chronicles 5:5'),
        ('2CH_MT_REF', 'MT_2CH_5_7', '2 Chronicles 5:7'),
        ('2CH_MT_REF', 'MT_2CH_5_8', '2 Chronicles 5:8'),
        ('2CH_MT_REF', 'MT_2CH_5_9', '2 Chronicles 5:9'),
        ('2CH_MT_REF', 'MT_2CH_5_10', '2 Chronicles 5:10')
     ) AS r(dataset_key, source_record_key, source_location)
  ON d.dataset_key = r.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'MT_1KI_8_3', 'MT_1KI_8_4', 'MT_1KI_8_6', 'MT_1KI_8_7', 'MT_1KI_8_8', 'MT_1KI_8_9',
    'MT_2CH_5_4', 'MT_2CH_5_5', 'MT_2CH_5_7', 'MT_2CH_5_8', 'MT_2CH_5_9', 'MT_2CH_5_10'
);

-- 3. Events shared across the two source traditions. The propositions stay generic; the source-
--    specific wording differences remain in the claims/evidence layer.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_taken_up_temple_placement', 'OTHER',
     'The selected 1 Kings 8:3 and 2 Chronicles 5:4 locators record the Ark of the Covenant being taken up during the temple-placement sequence. The sources differ in whether the named bearers are priests or Levites, and that wording difference is preserved in separate direct claims/evidence rather than resolved here.'),
    ('ark_covenant_brought_up_temple_placement', 'OTHER',
     'The selected 1 Kings 8:4 and 2 Chronicles 5:5 locators record the Ark of the Covenant being brought up in the temple-placement sequence, alongside other sanctuary items named only in the source observations.'),
    ('ark_covenant_placed_inner_sanctuary_solomon_temple', 'OTHER',
     'The selected 1 Kings 8:6 and 2 Chronicles 5:7 locators record the Ark of the Covenant being brought into the inner sanctuary under the wings of the cherubim. No place entity or additional location graph is added in this bounded phase.'),
    ('ark_covenant_covered_under_cherubim_solomon_temple', 'OTHER',
     'The selected 1 Kings 8:7 and 2 Chronicles 5:8 locators record the Ark of the Covenant and its poles under the covering of the cherubim. No separate temple-cherubim entity is introduced in this bounded phase.'),
    ('ark_covenant_poles_visible_holy_place_solomon_temple', 'OTHER',
     'The selected 1 Kings 8:8 and 2 Chronicles 5:9 locators record the Ark''s poles as visible from the Holy Place before the inner sanctuary but not from outside, and each source presents that observation as true at the time of its own writing.'),
    ('ark_covenant_tablets_only_content_solomon_temple', 'OTHER',
     'The selected 1 Kings 8:9 and 2 Chronicles 5:10 locators record that nothing was in the Ark except the two stone tablets Moses had placed there at Horeb. This bounded phase records the source-backed content observation only; it adds no broader inventory, compliance, or temporal inference.');

-- 4. Propositions using only existing subjectOf / participatesIn predicates.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_taken_up_temple_placement'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_taken_up_temple_placement'),
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_brought_up_temple_placement'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_brought_up_temple_placement'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_placed_inner_sanctuary_solomon_temple'),
        ('priests_levites_ark_bearers', 'participatesIn', 'ark_covenant_placed_inner_sanctuary_solomon_temple'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_covered_under_cherubim_solomon_temple'),
        ('poles_ark_covenant', 'participatesIn', 'ark_covenant_covered_under_cherubim_solomon_temple'),
        ('poles_ark_covenant', 'subjectOf', 'ark_covenant_poles_visible_holy_place_solomon_temple'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_tablets_only_content_solomon_temple'),
        ('tablets_of_testimony', 'participatesIn', 'ark_covenant_tablets_only_content_solomon_temple')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- 5. Direct source claims for every selected locator, kept separate by source even when the
--    normalized proposition is shared.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_taken_up_temple_placement',
         'CLAIM_1KI_BEARERS_SUBJECT_TAKE_UP_TEMPLE',
         '1 Kings 8:3 records the priests as taking up the ark.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_taken_up_temple_placement',
         'CLAIM_1KI_ARK_PARTICIPANT_TAKE_UP_TEMPLE',
         '1 Kings 8:3 records the ark as the object taken up by the priests.'),
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_brought_up_temple_placement',
         'CLAIM_1KI_BEARERS_SUBJECT_BRING_UP_TEMPLE',
         '1 Kings 8:4 records the priests and the Levites bringing up the ark along with the other sanctuary items named in that locator.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_brought_up_temple_placement',
         'CLAIM_1KI_ARK_PARTICIPANT_BRING_UP_TEMPLE',
         '1 Kings 8:4 records the ark as among the things brought up in the temple-placement sequence.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_placed_inner_sanctuary_solomon_temple',
         'CLAIM_1KI_ARK_SUBJECT_INNER_SANCTUARY_PLACEMENT_TEMPLE',
         '1 Kings 8:6 records the ark being brought into the inner sanctuary under the wings of the cherubim.'),
        ('priests_levites_ark_bearers', 'participatesIn', 'ark_covenant_placed_inner_sanctuary_solomon_temple',
         'CLAIM_1KI_BEARERS_PARTICIPANT_INNER_SANCTUARY_PLACEMENT_TEMPLE',
         '1 Kings 8:6 records the priests as bringing the ark into the inner sanctuary.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_covered_under_cherubim_solomon_temple',
         'CLAIM_1KI_ARK_SUBJECT_CHERUBIM_COVERING_TEMPLE',
         '1 Kings 8:7 records the ark as beneath the cherubim covering.'),
        ('poles_ark_covenant', 'participatesIn', 'ark_covenant_covered_under_cherubim_solomon_temple',
         'CLAIM_1KI_POLES_PARTICIPANT_CHERUBIM_COVERING_TEMPLE',
         '1 Kings 8:7 records the ark''s poles within the same cherubim-covering observation.'),
        ('poles_ark_covenant', 'subjectOf', 'ark_covenant_poles_visible_holy_place_solomon_temple',
         'CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE',
         '1 Kings 8:8 records the ark''s poles as visible from the Holy Place before the inner sanctuary but not from outside, and as remaining there at the time of that source''s own writing.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_tablets_only_content_solomon_temple',
         'CLAIM_1KI_ARK_SUBJECT_TABLETS_ONLY_TEMPLE',
         '1 Kings 8:9 records the ark as containing no item other than the two stone tablets Moses had placed there at Horeb.'),
        ('tablets_of_testimony', 'participatesIn', 'ark_covenant_tablets_only_content_solomon_temple',
         'CLAIM_1KI_TABLETS_PARTICIPANT_TABLETS_ONLY_TEMPLE',
         '1 Kings 8:9 records the two stone tablets Moses had placed at Horeb as the only named contents of the ark at this locator.'),
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_taken_up_temple_placement',
         'CLAIM_2CH_BEARERS_SUBJECT_TAKE_UP_TEMPLE',
         '2 Chronicles 5:4 records the Levites as taking up the ark.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_taken_up_temple_placement',
         'CLAIM_2CH_ARK_PARTICIPANT_TAKE_UP_TEMPLE',
         '2 Chronicles 5:4 records the ark as the object taken up by the Levites.'),
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_brought_up_temple_placement',
         'CLAIM_2CH_BEARERS_SUBJECT_BRING_UP_TEMPLE',
         '2 Chronicles 5:5 records the priests and the Levites bringing up the ark along with the other sanctuary items named in that locator.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_brought_up_temple_placement',
         'CLAIM_2CH_ARK_PARTICIPANT_BRING_UP_TEMPLE',
         '2 Chronicles 5:5 records the ark as among the things brought up in the temple-placement sequence.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_placed_inner_sanctuary_solomon_temple',
         'CLAIM_2CH_ARK_SUBJECT_INNER_SANCTUARY_PLACEMENT_TEMPLE',
         '2 Chronicles 5:7 records the ark being brought into the inner sanctuary under the wings of the cherubim.'),
        ('priests_levites_ark_bearers', 'participatesIn', 'ark_covenant_placed_inner_sanctuary_solomon_temple',
         'CLAIM_2CH_BEARERS_PARTICIPANT_INNER_SANCTUARY_PLACEMENT_TEMPLE',
         '2 Chronicles 5:7 records the priests as bringing the ark into the inner sanctuary.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_covered_under_cherubim_solomon_temple',
         'CLAIM_2CH_ARK_SUBJECT_CHERUBIM_COVERING_TEMPLE',
         '2 Chronicles 5:8 records the ark as beneath the cherubim covering.'),
        ('poles_ark_covenant', 'participatesIn', 'ark_covenant_covered_under_cherubim_solomon_temple',
         'CLAIM_2CH_POLES_PARTICIPANT_CHERUBIM_COVERING_TEMPLE',
         '2 Chronicles 5:8 records the ark''s poles within the same cherubim-covering observation.'),
        ('poles_ark_covenant', 'subjectOf', 'ark_covenant_poles_visible_holy_place_solomon_temple',
         'CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE',
         '2 Chronicles 5:9 records the ark''s poles as visible from the Holy Place before the inner sanctuary but not from outside, and as remaining there at the time of that source''s own writing.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_tablets_only_content_solomon_temple',
         'CLAIM_2CH_ARK_SUBJECT_TABLETS_ONLY_TEMPLE',
         '2 Chronicles 5:10 records the ark as containing no item other than the two stone tablets Moses had placed there at Horeb.'),
        ('tablets_of_testimony', 'participatesIn', 'ark_covenant_tablets_only_content_solomon_temple',
         'CLAIM_2CH_TABLETS_PARTICIPANT_TABLETS_ONLY_TEMPLE',
         '2 Chronicles 5:10 records the two stone tablets Moses had placed at Horeb as the only named contents of the ark at this locator.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

-- 6. Source observations and citations, one per selected locator.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION'
FROM (VALUES
        ('MT_1KI_8_3', '1 Kings 8:3 records the priests taking up the ark.'),
        ('MT_1KI_8_4', '1 Kings 8:4 records the priests and the Levites bringing up the ark, together with the tent of meeting and the holy vessels.'),
        ('MT_1KI_8_6', '1 Kings 8:6 records the priests bringing the ark into the inner sanctuary, under the wings of the cherubim.'),
        ('MT_1KI_8_7', '1 Kings 8:7 records the cherubim covering the ark and its poles.'),
        ('MT_1KI_8_8', '1 Kings 8:8 records the poles as extending far enough that their ends could be seen from the Holy Place before the inner sanctuary but not from outside, and the source presents them as remaining there at the time of its own writing.'),
        ('MT_1KI_8_9', '1 Kings 8:9 records that nothing was in the ark except the two stone tablets Moses had placed there at Horeb.'),
        ('MT_2CH_5_4', '2 Chronicles 5:4 records the Levites taking up the ark.'),
        ('MT_2CH_5_5', '2 Chronicles 5:5 records the priests and the Levites bringing up the ark, together with the tent of meeting and the sacred vessels.'),
        ('MT_2CH_5_7', '2 Chronicles 5:7 records the priests bringing the ark into the inner sanctuary, under the wings of the cherubim.'),
        ('MT_2CH_5_8', '2 Chronicles 5:8 records the cherubim covering the ark and its poles.'),
        ('MT_2CH_5_9', '2 Chronicles 5:9 records the poles as extending far enough that their ends could be seen from the Holy Place before the inner sanctuary but not from outside, and the source presents them as remaining there at the time of its own writing.'),
        ('MT_2CH_5_10', '2 Chronicles 5:10 records that nothing was in the ark except the two stone tablets Moses had placed there at Horeb.')
     ) AS m(source_record_key, observation)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key IN (
    'EV_MT_1KI_8_3', 'EV_MT_1KI_8_4', 'EV_MT_1KI_8_6', 'EV_MT_1KI_8_7', 'EV_MT_1KI_8_8', 'EV_MT_1KI_8_9',
    'EV_MT_2CH_5_4', 'EV_MT_2CH_5_5', 'EV_MT_2CH_5_7', 'EV_MT_2CH_5_8', 'EV_MT_2CH_5_9', 'EV_MT_2CH_5_10'
);

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_1KI_BEARERS_SUBJECT_TAKE_UP_TEMPLE', 'EV_MT_1KI_8_3'),
        ('CLAIM_1KI_ARK_PARTICIPANT_TAKE_UP_TEMPLE', 'EV_MT_1KI_8_3'),
        ('CLAIM_1KI_BEARERS_SUBJECT_BRING_UP_TEMPLE', 'EV_MT_1KI_8_4'),
        ('CLAIM_1KI_ARK_PARTICIPANT_BRING_UP_TEMPLE', 'EV_MT_1KI_8_4'),
        ('CLAIM_1KI_ARK_SUBJECT_INNER_SANCTUARY_PLACEMENT_TEMPLE', 'EV_MT_1KI_8_6'),
        ('CLAIM_1KI_BEARERS_PARTICIPANT_INNER_SANCTUARY_PLACEMENT_TEMPLE', 'EV_MT_1KI_8_6'),
        ('CLAIM_1KI_ARK_SUBJECT_CHERUBIM_COVERING_TEMPLE', 'EV_MT_1KI_8_7'),
        ('CLAIM_1KI_POLES_PARTICIPANT_CHERUBIM_COVERING_TEMPLE', 'EV_MT_1KI_8_7'),
        ('CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE', 'EV_MT_1KI_8_8'),
        ('CLAIM_1KI_ARK_SUBJECT_TABLETS_ONLY_TEMPLE', 'EV_MT_1KI_8_9'),
        ('CLAIM_1KI_TABLETS_PARTICIPANT_TABLETS_ONLY_TEMPLE', 'EV_MT_1KI_8_9'),
        ('CLAIM_2CH_BEARERS_SUBJECT_TAKE_UP_TEMPLE', 'EV_MT_2CH_5_4'),
        ('CLAIM_2CH_ARK_PARTICIPANT_TAKE_UP_TEMPLE', 'EV_MT_2CH_5_4'),
        ('CLAIM_2CH_BEARERS_SUBJECT_BRING_UP_TEMPLE', 'EV_MT_2CH_5_5'),
        ('CLAIM_2CH_ARK_PARTICIPANT_BRING_UP_TEMPLE', 'EV_MT_2CH_5_5'),
        ('CLAIM_2CH_ARK_SUBJECT_INNER_SANCTUARY_PLACEMENT_TEMPLE', 'EV_MT_2CH_5_7'),
        ('CLAIM_2CH_BEARERS_PARTICIPANT_INNER_SANCTUARY_PLACEMENT_TEMPLE', 'EV_MT_2CH_5_7'),
        ('CLAIM_2CH_ARK_SUBJECT_CHERUBIM_COVERING_TEMPLE', 'EV_MT_2CH_5_8'),
        ('CLAIM_2CH_POLES_PARTICIPANT_CHERUBIM_COVERING_TEMPLE', 'EV_MT_2CH_5_8'),
        ('CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE', 'EV_MT_2CH_5_9'),
        ('CLAIM_2CH_ARK_SUBJECT_TABLETS_ONLY_TEMPLE', 'EV_MT_2CH_5_10'),
        ('CLAIM_2CH_TABLETS_PARTICIPANT_TABLETS_ONLY_TEMPLE', 'EV_MT_2CH_5_10')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 7. Genuine cross-source derivation for the shared pole-visibility observation only.
INSERT INTO derivation (method, assumptions)
VALUES ('Cross-source comparison of the shared pole-visibility observation at the Ark''s placement in the temple',
        '1 Kings 8:8 and 2 Chronicles 5:9 are compared only for the shared observation that the Ark''s poles were visible from the Holy Place before the inner sanctuary but not from outside, and that each source presents that observation as true at the time of its own writing; the sources'' differing description of who took up the ark (priests in 1 Kings 8:3, Levites in 2 Chronicles 5:4) is preserved in separate direct claims and is not merged or resolved by this derivation.');

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED',
       p.proposition_id,
       'DERIVED_CLAIM',
       'The selected 1 Kings and 2 Chronicles temple-placement records share the normalized observation that the Ark''s poles were visible from the Holy Place before the inner sanctuary but not from outside at the time each source was written.',
       d.derivation_id
FROM proposition p
JOIN entity s ON s.entity_id = p.subject_entity_id
JOIN event e ON e.event_id = p.object_event_id
CROSS JOIN derivation d
WHERE s.entity_key = 'poles_ark_covenant'
  AND p.predicate = 'subjectOf'
  AND e.event_key = 'ark_covenant_poles_visible_holy_place_solomon_temple'
  AND d.method = 'Cross-source comparison of the shared pole-visibility observation at the Ark''s placement in the temple';

INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, c.claim_id, m.notes
FROM (VALUES
        ('CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE', '1 Kings direct source claim for the shared pole-visibility observation.'),
        ('CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE', '2 Chronicles direct source claim for the shared pole-visibility observation.')
     ) AS m(claim_key, notes)
JOIN derivation d ON d.method = 'Cross-source comparison of the shared pole-visibility observation at the Ark''s placement in the temple'
JOIN claim c ON c.claim_key = m.claim_key;

-- 8. Source identities and evidence-backed mappings: source-specific identities remain distinct
--    from canonical entities even when reconciled to the same Ark, poles, and bearer referents.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('1KI_MT', 'mt-ark-1ki8', 'the ark'),
        ('1KI_MT', 'mt-poles-1ki8', 'the poles'),
        ('1KI_MT', 'mt-ark-bearers-1ki8', 'the priests'),
        ('2CH_MT', 'mt-ark-2ch5', 'the ark'),
        ('2CH_MT', 'mt-poles-2ch5', 'the poles'),
        ('2CH_MT', 'mt-ark-bearers-2ch5', 'the Levites')
     ) AS m(source_key, source_identity_key, display_name)
JOIN source s ON s.source_key = m.source_key;

INSERT INTO source_identity_alternate_name (source_identity_id, alternate_name)
SELECT si.source_identity_id, m.alternate_name
FROM (VALUES
        ('mt-ark-bearers-1ki8', 'the priests and the Levites'),
        ('mt-ark-bearers-2ch5', 'the priests and the Levites')
     ) AS m(source_identity_key, alternate_name)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-ark-1ki8', 'ark_of_covenant', 0.9900, '1 Kings 8:6 identifies the ark in the selected temple-placement slice.', 'EV_MT_1KI_8_6'),
        ('mt-poles-1ki8', 'poles_ark_covenant', 0.9900, '1 Kings 8:8 identifies the ark''s poles in the selected temple-placement slice.', 'EV_MT_1KI_8_8'),
        ('mt-ark-bearers-1ki8', 'priests_levites_ark_bearers', 0.9300, '1 Kings 8:3 names priests taking up the ark in the same bounded temple-placement sequence later described at 8:4 with priests and Levites bringing it up; this slice preserves that wording difference while reusing the overlapping canonical bearer organization.', 'EV_MT_1KI_8_3'),
        ('mt-ark-2ch5', 'ark_of_covenant', 0.9900, '2 Chronicles 5:7 identifies the ark in the selected temple-placement slice.', 'EV_MT_2CH_5_7'),
        ('mt-poles-2ch5', 'poles_ark_covenant', 0.9900, '2 Chronicles 5:9 identifies the ark''s poles in the selected temple-placement slice.', 'EV_MT_2CH_5_9'),
        ('mt-ark-bearers-2ch5', 'priests_levites_ark_bearers', 0.9300, '2 Chronicles 5:4 names Levites taking up the ark in the same bounded temple-placement sequence later described at 5:5 with priests and Levites bringing it up; this slice preserves that wording difference while reusing the overlapping canonical bearer organization.', 'EV_MT_2CH_5_4')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

COMMIT;
