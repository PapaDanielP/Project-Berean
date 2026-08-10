-- Phase 19 source-backed Ark lifecycle conflict/handling/consequence slice: 2 Samuel 6:3-7.
--
-- This fixture extends the Phase 16-18 Ark-of-the-Covenant data in place. It follows the
-- repository's established manually-entered reference-point convention: locators are recorded,
-- but raw_content, content_hash, and quoted_text remain NULL. No Scripture text, translation,
-- external dataset, hash, quotation, causation, compliance finding, or contradiction is fabricated.
--
-- The bounded source slice is exactly 2 Samuel 6:3-7. It reuses the single canonical
-- ark_of_covenant and the existing poles_ark_covenant/rings_ark_covenant entities. It adds only
-- the supported persistent referents needed for this phase: Uzzah (a named PERSON) and the new cart
-- (an OBJECT used in the selected transport occurrence). Ahio, oxen, locations, priests, Levites,
-- Kohathites, routes, duration, ownership, compliance, violation, and causal/punitive semantics are
-- intentionally not asserted by this minimal slice.
--
-- Registry sufficiency: no schema, event_type, predicate, role, ClaimRelation type, JSON payload,
-- artifact lifecycle table, participant table, TOUCHED/CART/HANDLED_BY/CAUSE/CONSEQUENCE predicate,
-- or TRANSPORT event type is added. The existing generic OTHER/DEATH event types and
-- subjectOf/participatesIn predicates are sufficient for the selected source observations.
BEGIN;

-- 1. Source and dataset for 2 Samuel, matching the EXO/JOS reference-point convention.
-- Phase 19 source-backed Ark lifecycle conflict/handling slice: 2 Samuel 6:3-7.
--
-- This fixture extends the Phase 18 state in place. It reuses the single canonical
-- ark_of_covenant entity and the existing poles_ark_covenant/rings_ark_covenant entities.
-- It introduces only the source locator, citation, observation, evidence, entities, events,
-- propositions, claims, and claim-evidence links needed for the bounded 2 Samuel 6:3-7
-- slice. No Scripture text, quotation, content hash, translation, source import, JSON
-- payload, artifact-specific table, direct participant store, causation predicate, compliance
-- assertion, or ClaimRelation is added.
--
-- Registry sufficiency: the existing generic model is sufficient. The cart transport,
-- Uzzah's physical interaction with the Ark, and Uzzah's death are represented as source-
-- recorded historical events using existing event types (OTHER and DEATH) and existing
-- subjectOf/participatesIn predicates. No TRANSPORT, CARRIER, TOUCHED, CART, HANDLED_BY,
-- VIOLATED_REQUIREMENT, COMPLIANCE, CAUSE, or CONSEQUENCE vocabulary is added.
--
-- Semantic boundary: this fixture records source assertions only. It does not infer that
-- Exodus 25:15 was violated, that Joshua 3:6 and 2 Samuel 6:3-7 contradict each other, that
-- poles were present or absent, that the new cart caused Uzzah's death, or that any participant
-- beyond the explicitly represented Uzzah/cart/Ark slice participated in transport.
BEGIN;

-- 1. New source/dataset/locator for the manually-entered 2 Samuel reference point.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('2SA_MT', '2 Samuel, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of 2 Samuel. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, '2SA_MT_REF', '2 Samuel reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and selected published ark-lifecycle content are recorded.',
       'Manually entered reference points',
       '2 Samuel 6:3-7 Ark transport/handling/consequence data recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '2SA_MT';

-- 2. Exact bounded locators: 2 Samuel 6:3, 6:4, 6:5, 6:6, and 6:7.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('MT_2SA_6_3', '2 Samuel 6:3'),
        ('MT_2SA_6_4', '2 Samuel 6:4'),
        ('MT_2SA_6_5', '2 Samuel 6:5'),
        ('MT_2SA_6_6', '2 Samuel 6:6'),
        ('MT_2SA_6_7', '2 Samuel 6:7')
     ) AS r(source_record_key, source_location)
  ON d.dataset_key = '2SA_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN ('MT_2SA_6_3', 'MT_2SA_6_4', 'MT_2SA_6_5', 'MT_2SA_6_6', 'MT_2SA_6_7');

-- 3. New canonical entities justified by the selected source slice and persistence conventions.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('uzzah', 'PERSON', 'Uzzah', 'The named person in 2 Samuel 6:3-7 associated with the new-cart transport of the Ark and the recorded handling/death occurrence.'),
    ('new_cart_2sam6', 'OBJECT', 'new cart in the 2 Samuel 6 ark transport', 'The new cart on which 2 Samuel 6:3 records the Ark was set during the selected transport slice.');

-- 4. Events. OTHER is the existing generic event type used for historical lifecycle occurrences;
--    DEATH is already registered. These events assert occurrence only, not cause, violation,
--    compliance, contradiction, route, duration, or pole/ring state.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_transport_new_cart_2sam6', 'OTHER',
     '2 Samuel 6:3 records the Ark being set on a new cart. This historical transport occurrence is distinct from Exodus 25:15 STANDING_REQUIREMENT and Joshua 3:6 carrying; it asserts no compliance, violation, contradiction, route, duration, or pole/ring state.'),
    ('ark_covenant_physical_interaction_uzzah_2sam6', 'OTHER',
     '2 Samuel 6:6 records Uzzah physically interacting with the Ark. This is represented only as a source-recorded handling occurrence with Uzzah and the Ark; no TOUCHED predicate, violation claim, or cause is inferred.'),
    ('uzzah_death_2sam6', 'DEATH',
     '2 Samuel 6:7 records Uzzah dying there. This represents the source-recorded historical consequence only as a death occurrence, without inferring cause, punishment, violation, or compliance.');

-- 5. Propositions using only existing subjectOf/participatesIn predicates.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_transport_new_cart_2sam6'),
        ('new_cart_2sam6', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6'),
        ('uzzah', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_physical_interaction_uzzah_2sam6'),
        ('uzzah', 'participatesIn', 'ark_covenant_physical_interaction_uzzah_2sam6'),
       'No source text reproduced; only the locator and bounded Ark lifecycle observations are recorded.',
       'Manually entered reference points',
       'Ark transport, Uzzah interaction, and Uzzah death observations recorded via existing generic predicates; no text imported.'
FROM source WHERE source_key = '2SA_MT';

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, 'MT_2SA_6_3_7', '2 Samuel 6:3-7', 'ref-1'
FROM dataset d WHERE d.dataset_key = '2SA_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_MT_2SA_6_3_7', sr.source_record_id, sr.source_location
FROM source_record sr WHERE sr.source_record_key = 'MT_2SA_6_3_7';

-- 2. New entities justified by this bounded locator: Uzzah as a named PERSON and the new cart
--    as a source-recorded OBJECT. Ahio, David, locations, oxen, priests, Levites, and
--    Kohathites are intentionally not asserted as transport participants in this minimal slice.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('uzzah', 'PERSON', 'Uzzah',
     'The named person Uzzah in the bounded 2 Samuel 6:3-7 Ark transport and handling slice.'),
    ('new_cart_ark_transport', 'OBJECT', 'new cart used for the Ark transport',
     'The new cart on which 2 Samuel 6:3-7 records the Ark of the Covenant being transported.');

-- 3. Historical events. OTHER is sufficient for the bounded transport/interaction occurrences;
--    DEATH is an existing generic event type for Uzzah''s source-recorded death. None of these
--    events is an INSTRUCTION, CONSTRUCTION, or STANDING_REQUIREMENT event.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_new_cart_transport_2sam6', 'OTHER',
     '2 Samuel 6:3-7 records the Ark of the Covenant being transported on a new cart. This is a historical occurrence, not an instruction, standing requirement, compliance claim, or contradiction with another transport account.'),
    ('uzzah_ark_physical_interaction_2sam6', 'OTHER',
     '2 Samuel 6:3-7 records Uzzah physically interacting with the Ark of the Covenant. This records the observed interaction without adding a touched/handled-by predicate or inferring violation.'),
    ('uzzah_death_2sam6', 'DEATH',
     '2 Samuel 6:3-7 records Uzzah''s death in the same bounded source slice. This event is represented without a causal, punishment, violation, or compliance predicate.');

-- 4. Propositions use only subjectOf/participatesIn. Event descriptions and evidence observations
--    carry the bounded source-observation context; claim.statement remains display text only.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_new_cart_transport_2sam6'),
        ('new_cart_ark_transport', 'participatesIn', 'ark_covenant_new_cart_transport_2sam6'),
        ('uzzah', 'participatesIn', 'ark_covenant_new_cart_transport_2sam6'),
        ('uzzah', 'subjectOf', 'uzzah_ark_physical_interaction_2sam6'),
        ('ark_of_covenant', 'participatesIn', 'uzzah_ark_physical_interaction_2sam6'),
        ('uzzah', 'subjectOf', 'uzzah_death_2sam6')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- 6. Claims: one direct source claim per proposition.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_transport_new_cart_2sam6',
         'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6',
         '2 Samuel 6:3 records the Ark as the object set on a new cart.'),
        ('new_cart_2sam6', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6',
         'CLAIM_NEW_CART_PARTICIPANT_TRANSPORT_2SAM6',
         '2 Samuel 6:3 records a new cart as the transport object involved with the Ark.'),
        ('uzzah', 'participatesIn', 'ark_covenant_transport_new_cart_2sam6',
         'CLAIM_UZZAH_PARTICIPANT_TRANSPORT_2SAM6',
         '2 Samuel 6:3 records Uzzah as involved with the new-cart transport of the Ark.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_physical_interaction_uzzah_2sam6',
         'CLAIM_ARK_COVENANT_SUBJECT_UZZAH_INTERACTION_2SAM6',
         '2 Samuel 6:6 records the Ark as the object of Uzzah''s physical interaction.'),
        ('uzzah', 'participatesIn', 'ark_covenant_physical_interaction_uzzah_2sam6',
         'CLAIM_UZZAH_PARTICIPANT_INTERACTION_2SAM6',
         '2 Samuel 6:6 records Uzzah physically interacting with the Ark.'),
        ('uzzah', 'subjectOf', 'uzzah_death_2sam6',
         'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6',
         '2 Samuel 6:7 records Uzzah dying there.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

-- 7. Evidence: source observations for each bounded locator, all cited. Only 6:3, 6:6, and 6:7
--    are used as support for direct semantic claims in this phase; 6:4 and 6:5 remain available
--    source observations without additional claims to avoid broadening the slice.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('MT_2SA_6_3', '2 Samuel 6:3 records the Ark being set on a new cart and Uzzah associated with that cart transport.', NULL),
        ('MT_2SA_6_4', '2 Samuel 6:4 is present in the bounded 2 Samuel 6:3-7 source slice; no distinct Phase 19 claim is populated from this locator.', 'Source availability only for this phase.'),
        ('MT_2SA_6_5', '2 Samuel 6:5 is present in the bounded 2 Samuel 6:3-7 source slice; no distinct Phase 19 claim is populated from this locator.', 'Source availability only for this phase.'),
        ('MT_2SA_6_6', '2 Samuel 6:6 records Uzzah putting out his hand to the Ark and taking hold of it.', NULL),
        ('MT_2SA_6_7', '2 Samuel 6:7 records Uzzah dying there after the source-recorded incident.', NULL)
     ) AS m(source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;
-- 5. Claims: one direct source claim for each proposition.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_new_cart_transport_2sam6',
         'CLAIM_ARK_COVENANT_SUBJECT_NEW_CART_TRANSPORT_2SAM6',
         '2 Samuel 6:3-7 records the Ark of the Covenant as the object transported on a new cart.'),
        ('new_cart_ark_transport', 'participatesIn', 'ark_covenant_new_cart_transport_2sam6',
         'CLAIM_NEW_CART_PARTICIPANT_ARK_TRANSPORT_2SAM6',
         '2 Samuel 6:3-7 records a new cart as part of the Ark transport occurrence.'),
        ('uzzah', 'participatesIn', 'ark_covenant_new_cart_transport_2sam6',
         'CLAIM_UZZAH_PARTICIPANT_ARK_TRANSPORT_2SAM6',
         '2 Samuel 6:3-7 identifies Uzzah in the bounded Ark transport context.'),
        ('uzzah', 'subjectOf', 'uzzah_ark_physical_interaction_2sam6',
         'CLAIM_UZZAH_SUBJECT_ARK_INTERACTION_2SAM6',
         '2 Samuel 6:3-7 records Uzzah physically interacting with the Ark of the Covenant.'),
        ('ark_of_covenant', 'participatesIn', 'uzzah_ark_physical_interaction_2sam6',
         'CLAIM_ARK_COVENANT_PARTICIPANT_UZZAH_INTERACTION_2SAM6',
         '2 Samuel 6:3-7 records the Ark of the Covenant as the object involved in Uzzah''s physical interaction.'),
        ('uzzah', 'subjectOf', 'uzzah_death_2sam6',
         'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6',
         '2 Samuel 6:3-7 records Uzzah''s death in the bounded Ark lifecycle slice.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

-- 6. Evidence: one bounded source observation, cited to the locator, linked to every claim.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_MT_2SA_6_3_7', sr.source_record_id,
       '2 Samuel 6:3-7 records the Ark of the Covenant transported on a new cart, identifies Uzzah in that transport context, records Uzzah physically interacting with the Ark, and records Uzzah''s death in the same bounded source slice.',
       'SOURCE_OBSERVATION',
       'Manually entered source observation only; no Scripture text, translation, quotation, or content hash is stored.'
FROM source_record sr WHERE sr.source_record_key = 'MT_2SA_6_3_7';

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key IN ('EV_MT_2SA_6_3', 'EV_MT_2SA_6_4', 'EV_MT_2SA_6_5', 'EV_MT_2SA_6_6', 'EV_MT_2SA_6_7');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6', 'EV_MT_2SA_6_3'),
        ('CLAIM_NEW_CART_PARTICIPANT_TRANSPORT_2SAM6', 'EV_MT_2SA_6_3'),
        ('CLAIM_UZZAH_PARTICIPANT_TRANSPORT_2SAM6', 'EV_MT_2SA_6_3'),
        ('CLAIM_ARK_COVENANT_SUBJECT_UZZAH_INTERACTION_2SAM6', 'EV_MT_2SA_6_6'),
        ('CLAIM_UZZAH_PARTICIPANT_INTERACTION_2SAM6', 'EV_MT_2SA_6_6'),
        ('CLAIM_UZZAH_SUBJECT_DEATH_2SAM6', 'EV_MT_2SA_6_7')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 8. Source identities and evidence-backed mappings for the two new source-supported referents.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('mt-uzzah-2sam6', 'Uzzah'),
        ('mt-new-cart-2sam6', 'new cart')
     ) AS m(source_identity_key, display_name)
JOIN source s ON s.source_key = '2SA_MT';

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-uzzah-2sam6', 'uzzah', 0.9900, '2 Samuel 6:3 names Uzzah in the selected ark transport slice.', 'EV_MT_2SA_6_3'),
        ('mt-new-cart-2sam6', 'new_cart_2sam6', 0.9900, '2 Samuel 6:3 identifies a new cart involved in the selected ark transport slice.', 'EV_MT_2SA_6_3')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;
WHERE ev.evidence_key = 'EV_MT_2SA_6_3_7';

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this bounded 2 Samuel 6:3-7 claim.'
FROM claim c, evidence ev
WHERE c.claim_key IN (
    'CLAIM_ARK_COVENANT_SUBJECT_NEW_CART_TRANSPORT_2SAM6',
    'CLAIM_NEW_CART_PARTICIPANT_ARK_TRANSPORT_2SAM6',
    'CLAIM_UZZAH_PARTICIPANT_ARK_TRANSPORT_2SAM6',
    'CLAIM_UZZAH_SUBJECT_ARK_INTERACTION_2SAM6',
    'CLAIM_ARK_COVENANT_PARTICIPANT_UZZAH_INTERACTION_2SAM6',
    'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6'
  ) AND ev.evidence_key = 'EV_MT_2SA_6_3_7';

COMMIT;
