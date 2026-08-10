-- Phase 17 source-backed standing requirement: Exodus 25:15 ("the poles shall be in the
-- rings of the ark: they shall not be taken from it").
--
-- This fixture extends the Phase 16 fixture (060) in place; it does not truncate any prior
-- phase. It reuses the existing `poles_ark_covenant`, `rings_ark_covenant`, and
-- `ark_of_covenant` OBJECT entities (introduced in Phase 16) and the existing `EXO_MT_REF`
-- dataset (introduced in Phase 16). No new entity, table, or source is required.
--
-- Phase 16 documented Exodus 25:15 as a SEMANTIC PRECISION GAP: forcing a standing/ongoing
-- requirement into `participatesIn` (or any other existing EVENT-typed predicate, all of
-- which carry a PARTICIPANT/SUBJECT/PARENT/CHILD/BUILDER role implying actual occurrence)
-- would misrepresent an ongoing restriction as a one-time, already-occurred event fact.
-- Phase 17 resolves that gap with the smallest possible generic extension: one new
-- `event_type` (`STANDING_REQUIREMENT`, distinct from `INSTRUCTION` and `CONSTRUCTION`) and
-- one new `predicate` (`standingRequirementIn`, ENTITY->EVENT, deliberately given NO
-- `event_participation_role_code` so it can never project into `event_participation` and
-- can never be mistaken for participation in a completed occurrence). No table, JSON
-- payload, participant store, or artifact-specific requirement schema was added.
--
-- This claim asserts only that the source records the requirement's existence. It does not
-- assert, and must never be read to imply: that the poles were physically present, that
-- they remained in the rings, that transport ever occurred, that removal did or did not
-- happen, or that the instruction was obeyed. Any such inference would require its own
-- source-backed observation or a documented Derivation, neither of which is added here.
--
-- Population scope: Exodus 25:15 is the sole new locator in this phase. No additional
-- Ark-of-the-Covenant lifecycle material (Numbers 4/7/10 transport, 1-2 Samuel narrative,
-- or any later event) was inspected as available and acquired; all remain SOURCE
-- AVAILABILITY GAP / ACQUISITION PENDING, as before, and none is fabricated here.
BEGIN;

-- 1. One new source record in the existing EXO_MT_REF dataset (introduced in Phase 16),
--    following the same "manually entered reference point" convention: locator recorded,
--    no verbatim source text, hash, or quotation.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, 'MT_EXO_25_15', 'Exodus 25:15', 'ref-1'
FROM dataset d WHERE d.dataset_key = 'EXO_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_MT_EXO_25_15', sr.source_record_id, sr.source_location
FROM source_record sr WHERE sr.source_record_key = 'MT_EXO_25_15';

-- 2. One new event, typed STANDING_REQUIREMENT (never INSTRUCTION or CONSTRUCTION), for the
--    ongoing pole-handling requirement Exodus 25:15 records.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_covenant_pole_standing_requirement', 'STANDING_REQUIREMENT',
     'Exodus 25:15 records a standing/ongoing requirement that the poles remain in the rings of the Ark of the Covenant and not be withdrawn. This is a continuing restriction, not a single occurrence, and is never evidence of compliance, transport, or historical occurrence.');

-- 3. One proposition: poles_ark_covenant is the subject of this standing requirement. No
--    proposition is made about rings_ark_covenant or ark_of_covenant directly participating
--    in an event, since only the poles are the grammatical and semantic subject of the
--    requirement; the rings and the ark are described only in the event's own text, not as
--    additional asserted propositions, to avoid inventing relationships beyond the source.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT e.entity_id, 'standingRequirementIn', ev.event_id
FROM entity e, event ev
WHERE e.entity_key = 'poles_ark_covenant'
  AND ev.event_key = 'ark_covenant_pole_standing_requirement';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_POLES_STANDING_REQUIREMENT', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Exodus 25:15 records a standing requirement that the poles remain in the rings of the ark and not be withdrawn from it.'
FROM proposition p
JOIN entity e ON e.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
WHERE e.entity_key = 'poles_ark_covenant'
  AND ev.event_key = 'ark_covenant_pole_standing_requirement'
  AND p.predicate = 'standingRequirementIn';

-- 4. Evidence: one source observation for the new locator, cited to it, and linked to the
--    claim as supporting evidence, completing the full provenance chain.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT 'EV_MT_EXO_25_15', sr.source_record_id,
       'Exodus 25:15 records that the poles shall be in the rings of the ark; they shall not be taken from it.',
       'SOURCE_OBSERVATION'
FROM source_record sr WHERE sr.source_record_key = 'MT_EXO_25_15';

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key = 'EV_MT_EXO_25_15';

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM claim c, evidence ev
WHERE c.claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT' AND ev.evidence_key = 'EV_MT_EXO_25_15';

COMMIT;
