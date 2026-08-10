-- Phase 18 source-backed Ark of the Covenant transport/handling slice: Joshua 3:6.
--
-- This fixture extends the Phase 16 (060) and Phase 17 (070) fixtures in place; it does not
-- truncate any prior phase. It reuses the existing `ark_of_covenant` OBJECT entity (Phase 16)
-- unchanged; it adds no new pole/ring entity (`poles_ark_covenant` and `rings_ark_covenant`
-- are also reused, untouched -- Joshua 3:6 makes no assertion about them).
--
-- Source availability was investigated before writing this fixture. Candidate transport/
-- handling passages considered: Numbers 4:15, Numbers 7:9, Numbers 10:21, Joshua 3:3-6,
-- Joshua 6:6-13, and 2 Samuel 6:3-7. Numbers 4:15/7:9/10:21 describe the Kohathites bearing
-- "the sanctuary"/"the holy things" generically and do not, in the plain text, explicitly name
-- "the ark of the covenant" as the object borne; asserting the Ark specifically as their object
-- would require an inference beyond the bare locator text, which this repository's convention
-- does not allow. Joshua 6:6-13 and 2 Samuel 6:3-7 were also not selected: they are not the
-- smallest bounded slice available, and 2 Samuel 6 additionally introduces a cart/oxen
-- transport method in tension with pole-based carrying, which is out of scope for this bounded
-- phase. Joshua 3:6 is the smallest bounded, coherent, explicitly-supported locator: in one
-- verse it explicitly names "the ark of the covenant" as the object taken up and carried,
-- explicitly identifies "the priests" as those who carry it, and contains both a command
-- (instruction) clause and a distinct, completed-action (historical transport) clause, letting
-- this phase test the same instruction/historical-event distinction Phase 16 and 17 established
-- without fabricating anything beyond it. All other candidate passages remain SOURCE
-- AVAILABILITY GAP / ACQUISITION PENDING; none is populated or fabricated here.
--
-- Following the established "manually entered reference point" convention (used for Genesis,
-- Exodus, and Deuteronomy locators in Phase 16/17): the locator is recorded, but no verbatim
-- source text, hash, or quotation is stored. The evidence observation reflects the well-known
-- published content of this public-domain scriptural locator, exactly as Phase 16/17 did.
--
-- Registry sufficiency: this fixture adds NO new event_type and NO new predicate. The
-- historical transport occurrence is represented with the existing generic `OTHER` event_type
-- (already distinct from INSTRUCTION, CONSTRUCTION, and STANDING_REQUIREMENT) and the existing
-- `subjectOf`/`participatesIn` predicates (already used by Phase 16 for exactly this
-- subject/participant shape). No table, column, JSON payload, or participation role was added.
-- This confirms the existing registry, extended through Phase 17, is already sufficient for
-- this bounded transport slice; no TRANSPORT event_type or CARRIER role was needed or added.
--
-- Standing requirement preserved: the Exodus 25:15 `standingRequirementIn` proposition and its
-- `STANDING_REQUIREMENT`-typed event (Phase 17) are untouched. This fixture asserts nothing
-- about whether the poles were in the rings during this transport, and nothing about
-- compliance with, or violation of, that requirement -- Joshua 3:6 makes no such assertion, so
-- none is recorded.
BEGIN;

-- 1. New source and dataset for Joshua, following the EXO_MT/EXO_MT_REF reference-point
--    pattern established in Phase 16.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('JOS_MT', 'Joshua, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of Joshua. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, 'JOS_MT_REF', 'Joshua reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only the locator and published transport-event content are recorded.',
       'Manually entered reference points',
       'Ark of the Covenant transport instruction/completed-event data recorded via existing predicates; no text imported.'
FROM source WHERE source_key = 'JOS_MT';

-- 2. One new source record: Joshua 3:6, the sole new locator in this phase.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, 'MT_JOS_3_6', 'Joshua 3:6', 'ref-1'
FROM dataset d WHERE d.dataset_key = 'JOS_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_MT_JOS_3_6', sr.source_record_id, sr.source_location
FROM source_record sr WHERE sr.source_record_key = 'MT_JOS_3_6';

-- 3. One new entity: the priests who carry the ark, explicitly identified by Joshua 3:6
--    ("Joshua spake unto the priests ... And they took up the ark of the covenant"). Modeled
--    as ORGANIZATION (a collective office/role), an already-registered, previously-unused
--    entity_type; no new entity_type is added. No individual priest is named in this locator,
--    so no PERSON entity is fabricated for any of them individually.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('priests_levites_ark_bearers', 'ORGANIZATION', 'the priests who bore the ark of the covenant',
     'The priests explicitly identified in Joshua 3:6 as those commanded to, and who did, take up the ark of the covenant and go before the people at the Jordan.');

-- 4. Two new events. INSTRUCTION records Joshua's command; the distinct, completed carrying
--    action is recorded with the existing generic OTHER event_type -- already distinct from
--    INSTRUCTION, CONSTRUCTION, and STANDING_REQUIREMENT, so no new event_type is required.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_transport_instruction_jordan', 'INSTRUCTION',
     'Joshua 3:6 records Joshua commanding the priests: take up the ark of the covenant and pass over before the people. Not itself an assertion of completed transport.'),
    ('ark_covenant_transport_jordan', 'OTHER',
     'Joshua 3:6 records that the priests took up the ark of the covenant and went before the people. A historical, completed transport/handling occurrence, distinct from the Exodus 25:15 STANDING_REQUIREMENT and from any INSTRUCTION or CONSTRUCTION event; asserts nothing about the poles, the rings, or compliance with the standing requirement.');

-- 5. Propositions: entity/event predicates, reusing only the existing subjectOf/participatesIn
--    predicates in the same subject/participant shape Phase 16 already used for
--    instruction (recipient subjectOf; artifact participatesIn) and for a completed action
--    (artifact subjectOf; other participant participatesIn).
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_transport_instruction_jordan'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_transport_instruction_jordan'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_transport_jordan'),
        ('priests_levites_ark_bearers', 'participatesIn', 'ark_covenant_transport_jordan')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- 6. Claims: direct source claims for every proposition created above.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('priests_levites_ark_bearers', 'subjectOf', 'ark_covenant_transport_instruction_jordan',
         'CLAIM_PRIESTS_RECIPIENT_ARK_TRANSPORT_INSTRUCTION',
         'Joshua 3:6 presents the priests as the recipients of Joshua''s command to take up the ark of the covenant.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_transport_instruction_jordan',
         'CLAIM_ARK_COVENANT_PARTICIPANT_TRANSPORT_INSTRUCTION',
         'Joshua 3:6 presents the ark of the covenant as the object of the command to take it up and pass over.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_transport_jordan',
         'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
         'Joshua 3:6 presents the ark of the covenant as the thing taken up and carried before the people.'),
        ('priests_levites_ark_bearers', 'participatesIn', 'ark_covenant_transport_jordan',
         'CLAIM_PRIESTS_PARTICIPANT_TRANSPORT_JORDAN',
         'Joshua 3:6 presents the priests as those who took up the ark of the covenant and went before the people.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

-- 7. Evidence: one source observation for Joshua 3:6, cited to it, and linked to every claim
--    above as supporting evidence, completing the full provenance chain for each.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT 'EV_MT_JOS_3_6', sr.source_record_id,
       'Joshua 3:6 records Joshua commanding the priests to take up the ark of the covenant and pass over before the people, and that the priests took up the ark of the covenant and went before the people.',
       'SOURCE_OBSERVATION'
FROM source_record sr WHERE sr.source_record_key = 'MT_JOS_3_6';

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key = 'EV_MT_JOS_3_6';

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM claim c, evidence ev
WHERE c.claim_key IN (
    'CLAIM_PRIESTS_RECIPIENT_ARK_TRANSPORT_INSTRUCTION',
    'CLAIM_ARK_COVENANT_PARTICIPANT_TRANSPORT_INSTRUCTION',
    'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
    'CLAIM_PRIESTS_PARTICIPANT_TRANSPORT_JORDAN'
  ) AND ev.evidence_key = 'EV_MT_JOS_3_6';

COMMIT;
