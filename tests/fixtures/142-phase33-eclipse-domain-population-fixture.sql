-- Phase 33 Stage A: independent source-driven population of the 1919 solar-eclipse domain.
--
-- This fixture is a population pass only. It is driven by what the represented sources report,
-- not by any research question. It deliberately contains no research question, expected answer,
-- answer table, query result, ranking, consensus value, or interpretation verdict, and it adds no
-- schema, predicate, entity type, claim type, evidence type, or second knowledge store.
--
-- The Phase 33 population is independently keyed (`phase33_*`, `*_P33`, `CLAIM_P33_*`) so that it
-- stands on its own and does not depend on the Phase 32 fixture having been loaded. The four
-- bibliographic Source rows are shared with Phase 32 because they are the same works; every
-- dataset, source record, citation, evidence, entity, event, proposition, and claim below belongs
-- to the Phase 33 population pass.
--
-- Source-storage policy: locator-only. No raw_content, no content_hash, and no quoted_text is
-- stored for any Phase 33 source record; the datasets record NOT_STORED_BY_POLICY explicitly.
-- Absent source text is not source silence and is not a claim of nonexistence.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('ECLIPSE_1919_REPORT', 'Dyson, Eddington, and Davidson 1920 eclipse report', 'HISTORICAL_WORK',
     'Primary expedition report for the 1919 solar-eclipse observations. No source text is stored in this repository.'),
    ('OBSERVATORY_1919_ECLIPSE', 'The Observatory 1919 joint eclipse meeting report', 'HISTORICAL_WORK',
     'Near-primary contemporary report of the Royal Society/Royal Astronomical Society eclipse announcement. No source text is stored.'),
    ('EARMAN_GLYMOUR_1980', 'Earman and Glymour 1980 reassessment of the 1919 eclipse evidence', 'REFERENCE',
     'Published scholarly reassessment; retained as interpretation, not primary source fact.'),
    ('KENNEFICK_2007', 'Kennefick 2007 reassessment of 1919 eclipse expedition myths', 'REFERENCE',
     'Published scholarly reassessment; retained as interpretation, not primary source fact.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, d.dataset_key, d.name, d.edition_label, 'p33-1',
       'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manual Phase 33 bounded domain population pass', d.notes
FROM source s
JOIN (VALUES
        ('ECLIPSE_1919_REPORT', 'ECLIPSE_1919_REPORT_P33', 'Phase 33 1919 eclipse expedition report reference points',
         'Philosophical Transactions of the Royal Society A 220 (1920)',
         'Phase 33 population pass over the primary expedition report; locators only, no quoted text.'),
        ('OBSERVATORY_1919_ECLIPSE', 'OBSERVATORY_1919_P33', 'Phase 33 1919 joint eclipse meeting reference points',
         'The Observatory 42 (1919)',
         'Phase 33 population pass over the contemporary near-primary report; locators only.'),
        ('EARMAN_GLYMOUR_1980', 'EARMAN_GLYMOUR_1980_P33', 'Phase 33 Earman and Glymour 1980 reference point',
         'Historical Studies in the Physical Sciences 11.1',
         'Phase 33 population pass; scholarly-position candidate material only.'),
        ('KENNEFICK_2007', 'KENNEFICK_2007_P33', 'Phase 33 Kennefick 2007 reference point',
         'Einstein Studies 12',
         'Phase 33 population pass; scholarly-position candidate material only.')
     ) AS d(source_key, dataset_key, name, edition_label, notes) ON s.source_key = d.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'p33-1'
FROM dataset d
JOIN (VALUES
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_EXPEDITION_ORGANISATION',
         'Philosophical Transactions of the Royal Society A 220 (1920), account of the expedition arrangements'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_PRINCIPE_OBSERVATIONS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Principe observations and reductions'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_PRINCIPE_INSTRUMENTS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Principe instrumental equipment'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_SOBRAL_OBSERVATIONS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Sobral observations and reductions'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_SOBRAL_INSTRUMENTS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Sobral instrumental equipment'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_SOBRAL_ASTROGRAPHIC_CONCERN',
         'Philosophical Transactions of the Royal Society A 220 (1920), discussion of the Sobral astrographic plates'),
        ('ECLIPSE_1919_REPORT_P33', 'P33_REPORT_RESULTS_DISCUSSION',
         'Philosophical Transactions of the Royal Society A 220 (1920), discussion of the deflection results'),
        ('OBSERVATORY_1919_P33', 'P33_OBSERVATORY_JOINT_MEETING',
         'The Observatory 42 (1919), report of the Joint Eclipse Meeting of the Royal Society and the Royal Astronomical Society'),
        ('OBSERVATORY_1919_P33', 'P33_OBSERVATORY_MEETING_DISCUSSION',
         'The Observatory 42 (1919), discussion following the Joint Eclipse Meeting papers'),
        ('EARMAN_GLYMOUR_1980_P33', 'P33_EARMAN_GLYMOUR_49_85',
         'Historical Studies in the Physical Sciences 11.1 (1980): 49-85'),
        ('KENNEFICK_2007_P33', 'P33_KENNEFICK_EINSTEIN_STUDIES_12',
         'Einstein Studies 12 (2007), reassessment of the 1919 eclipse expedition')
     ) AS r(dataset_key, source_record_key, source_location) ON d.dataset_key = r.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_key IN (
    'ECLIPSE_1919_REPORT_P33', 'OBSERVATORY_1919_P33',
    'EARMAN_GLYMOUR_1980_P33', 'KENNEFICK_2007_P33'
)
ON CONFLICT (citation_key) DO NOTHING;

-- Source observations. Each records what a represented source reports, not what is true.
-- Analytical observations record later scholarship and are never attached to a claim.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, m.evidence_type_code, m.notes
FROM (VALUES
        ('EV_P33_EXPEDITION_ORGANISATION', 'P33_REPORT_EXPEDITION_ORGANISATION',
         'The 1920 report describes the eclipse expedition as arranged by a joint committee of the Royal Society and the Royal Astronomical Society and reports two separate observing stations.',
         'SOURCE_OBSERVATION',
         'Organisational observation only; no claim about expedition purpose, adequacy, or outcome is asserted.'),
        ('EV_P33_PRINCIPE_OBSERVATIONS', 'P33_REPORT_PRINCIPE_OBSERVATIONS',
         'The 1920 report treats the Principe eclipse plates as a distinct observational tradition and associates Eddington and Cottingham with the Principe station.',
         'SOURCE_OBSERVATION',
         'Primary-source observation layer only; no theory-confirmation or truth verdict is asserted.'),
        ('EV_P33_PRINCIPE_INSTRUMENTS', 'P33_REPORT_PRINCIPE_INSTRUMENTS',
         'The 1920 report describes an astrographic telescope object as the instrument in use at the Principe station.',
         'SOURCE_OBSERVATION',
         'Instrument location observation only; no instrument-quality or data-weighting assessment is asserted.'),
        ('EV_P33_SOBRAL_OBSERVATIONS', 'P33_REPORT_SOBRAL_OBSERVATIONS',
         'The 1920 report treats the Sobral eclipse plates as a distinct observational tradition and associates Davidson and Crommelin with the Sobral station.',
         'SOURCE_OBSERVATION',
         'Primary-source observation layer only; no identity merger with the Principe tradition is asserted.'),
        ('EV_P33_SOBRAL_INSTRUMENTS', 'P33_REPORT_SOBRAL_INSTRUMENTS',
         'The 1920 report describes two distinct instruments in use at the Sobral station: an astrographic telescope and a four-inch lens.',
         'SOURCE_OBSERVATION',
         'Instrument location observation only; the report''s later differential treatment of the two instruments is recorded separately.'),
        ('EV_P33_SOBRAL_ASTROGRAPHIC_CONCERN', 'P33_REPORT_SOBRAL_ASTROGRAPHIC_CONCERN',
         'The 1920 report distinguishes the Sobral astrographic plates from the Sobral four-inch result and reports an instrumental/focus concern about the astrographic plates.',
         'SOURCE_OBSERVATION',
         'Source-reported ambiguity retained as evidence only. It establishes neither data invalidity, nor selection motive, nor bias, nor contradiction, and no predicate expresses data weighting.'),
        ('EV_P33_RESULTS_DISCUSSION', 'P33_REPORT_RESULTS_DISCUSSION',
         'The 1920 report discusses the measured deflection results in relation to a predicted deflection value and a smaller comparison value.',
         'SOURCE_OBSERVATION',
         'Numeric deflection values and their theoretical comparison are not represented as propositions; no registered predicate expresses a measured deflection or a theory relation.'),
        ('EV_P33_OBSERVATORY_JOINT_MEETING', 'P33_OBSERVATORY_JOINT_MEETING',
         'The contemporary joint-meeting report places the announcement of the eclipse results after the May 1919 observations, at a meeting of the Royal Society and the Royal Astronomical Society held at Burlington House and chaired in the presence of the Astronomer Royal.',
         'SOURCE_OBSERVATION',
         'Near-primary chronology, venue, and convener layer; the later source is not treated as a plate-level observation.'),
        ('EV_P33_OBSERVATORY_MEETING_DISCUSSION', 'P33_OBSERVATORY_MEETING_DISCUSSION',
         'The contemporary report records that reservations and requests for further confirmation were expressed in the discussion following the announcement.',
         'SOURCE_OBSERVATION',
         'A contemporary difference of emphasis from the expedition report. Difference is not contradiction and is not resolved here.'),
        ('EV_P33_EARMAN_GLYMOUR_INTERPRETATION', 'P33_EARMAN_GLYMOUR_49_85',
         'Earman and Glymour reassess the 1919 eclipse evidence and question simplified accounts of its decisiveness and of the expedition''s data handling.',
         'ANALYTICAL_OBSERVATION',
         'Competing later scholarship retained as an analytical observation; never promoted to a source-backed claim and never ranked.'),
        ('EV_P33_KENNEFICK_INTERPRETATION', 'P33_KENNEFICK_EINSTEIN_STUDIES_12',
         'Kennefick presents a competing reassessment that resists simple accusations of theory-driven data rejection by the expedition.',
         'ANALYTICAL_OBSERVATION',
         'Competing later scholarship retained as an analytical observation; difference from Earman and Glymour is not persisted as contradiction.')
     ) AS m(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('phase33_arthur_eddington', 'PERSON', 'Arthur Stanley Eddington',
     'Person reported by the 1920 expedition report in connection with the Principe station.'),
    ('phase33_edwin_cottingham', 'PERSON', 'Edwin T. Cottingham',
     'Person reported by the 1920 expedition report in connection with the Principe station.'),
    ('phase33_charles_davidson', 'PERSON', 'Charles R. Davidson',
     'Person reported by the 1920 expedition report in connection with the Sobral station.'),
    ('phase33_andrew_crommelin', 'PERSON', 'Andrew C. D. Crommelin',
     'Person reported by the 1920 expedition report in connection with the Sobral station.'),
    ('phase33_frank_dyson', 'PERSON', 'Frank Watson Dyson',
     'Person reported by the represented sources in connection with the expedition arrangements and the joint meeting.'),
    ('phase33_principe_station', 'PLACE', 'Principe eclipse station',
     'Canonical place entity for the Principe observing station; the source-specific station identity is preserved separately.'),
    ('phase33_sobral_station', 'PLACE', 'Sobral eclipse station',
     'Canonical place entity for the Sobral observing station; the source-specific station identity is preserved separately.'),
    ('phase33_burlington_house', 'PLACE', 'Burlington House',
     'Canonical place entity for the reported venue of the 1919 joint eclipse meeting.'),
    ('phase33_royal_society', 'ORGANIZATION', 'Royal Society',
     'Organization reported by the represented sources as a convener of the expedition arrangements and the joint meeting.'),
    ('phase33_royal_astronomical_society', 'ORGANIZATION', 'Royal Astronomical Society',
     'Organization reported by the represented sources as a convener of the expedition arrangements and the joint meeting.'),
    ('phase33_principe_astrographic_telescope', 'OBJECT', 'Principe astrographic telescope',
     'Instrument object reported by the 1920 report as in use at the Principe station.'),
    ('phase33_sobral_astrographic_telescope', 'OBJECT', 'Sobral astrographic telescope',
     'Instrument object reported by the 1920 report as in use at the Sobral station.'),
    ('phase33_sobral_four_inch_lens', 'OBJECT', 'Sobral four-inch lens',
     'Instrument object reported by the 1920 report as in use at the Sobral station, distinct from the astrographic telescope.'),
    ('phase33_predicted_deflection_value', 'CONCEPT', 'Predicted light-deflection value',
     'Concept retained for corpus description only. It participates in no proposition; no predicate expresses prediction, confirmation, or comparison.'),
    ('phase33_smaller_comparison_deflection_value', 'CONCEPT', 'Smaller comparison deflection value',
     'Concept retained for corpus description only. It participates in no proposition; no ranking or refutation predicate is introduced.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('phase33_principe_observation_1919', 'OTHER',
     'The observing activity reported at the Principe station during the 1919 solar eclipse.'),
    ('phase33_sobral_observation_1919', 'OTHER',
     'The observing activity reported at the Sobral station during the 1919 solar eclipse.'),
    ('phase33_joint_eclipse_meeting_1919', 'OTHER',
     'The joint meeting at which the represented sources report the eclipse results were announced and discussed.')
ON CONFLICT (event_key) DO NOTHING;

-- Propositions are the authoritative structured content of the claims below. Only relationships
-- that a registered predicate expresses faithfully are created here.
INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT ev.event_id, 'occursAt', place.entity_id
FROM (VALUES
        ('phase33_principe_observation_1919', 'phase33_principe_station'),
        ('phase33_sobral_observation_1919', 'phase33_sobral_station'),
        ('phase33_joint_eclipse_meeting_1919', 'phase33_burlington_house')
     ) AS m(event_key, place_key)
JOIN event ev ON ev.event_key = m.event_key
JOIN entity place ON place.entity_key = m.place_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_event_id = ev.event_id AND p.predicate = 'occursAt' AND p.object_entity_id = place.entity_id
);

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT subj.entity_id, 'participatesIn', ev.event_id
FROM (VALUES
        ('phase33_arthur_eddington', 'phase33_principe_observation_1919'),
        ('phase33_edwin_cottingham', 'phase33_principe_observation_1919'),
        ('phase33_charles_davidson', 'phase33_sobral_observation_1919'),
        ('phase33_andrew_crommelin', 'phase33_sobral_observation_1919'),
        ('phase33_royal_society', 'phase33_joint_eclipse_meeting_1919'),
        ('phase33_royal_astronomical_society', 'phase33_joint_eclipse_meeting_1919')
     ) AS m(entity_key, event_key)
JOIN entity subj ON subj.entity_key = m.entity_key
JOIN event ev ON ev.event_key = m.event_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_entity_id = subj.entity_id AND p.predicate = 'participatesIn' AND p.object_event_id = ev.event_id
);

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT instrument.entity_id, 'locatedAt', station.entity_id
FROM (VALUES
        ('phase33_principe_astrographic_telescope', 'phase33_principe_station'),
        ('phase33_sobral_astrographic_telescope', 'phase33_sobral_station'),
        ('phase33_sobral_four_inch_lens', 'phase33_sobral_station')
     ) AS m(instrument_key, station_key)
JOIN entity instrument ON instrument.entity_key = m.instrument_key
JOIN entity station ON station.entity_key = m.station_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_entity_id = instrument.entity_id AND p.predicate = 'locatedAt' AND p.object_entity_id = station.entity_id
);

INSERT INTO proposition (subject_event_id, predicate, object_event_id)
SELECT observation.event_id, 'precedes', meeting.event_id
FROM (VALUES
        ('phase33_principe_observation_1919'),
        ('phase33_sobral_observation_1919')
     ) AS m(event_key)
JOIN event observation ON observation.event_key = m.event_key
JOIN event meeting ON meeting.event_key = 'phase33_joint_eclipse_meeting_1919'
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_event_id = observation.event_id AND p.predicate = 'precedes' AND p.object_event_id = meeting.event_id
);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P33_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE', 'phase33_principe_observation_1919', 'phase33_principe_station',
         'The Principe 1919 eclipse observation event occurs at the Principe station.',
         'Source-backed location proposition; it is not a verdict about the observation''s correctness.'),
        ('CLAIM_P33_SOBRAL_OBSERVATION_OCCURS_AT_SOBRAL', 'phase33_sobral_observation_1919', 'phase33_sobral_station',
         'The Sobral 1919 eclipse observation event occurs at the Sobral station.',
         'Source-backed location proposition; it asserts no merger with the Principe observing tradition.'),
        ('CLAIM_P33_JOINT_MEETING_OCCURS_AT_BURLINGTON_HOUSE', 'phase33_joint_eclipse_meeting_1919', 'phase33_burlington_house',
         'The 1919 joint eclipse meeting occurs at Burlington House.',
         'Source-backed venue proposition reported by the contemporary near-primary source only.')
     ) AS m(claim_key, subject_event_key, object_entity_key, statement, notes)
JOIN event ev ON ev.event_key = m.subject_event_key
JOIN entity obj ON obj.entity_key = m.object_entity_key
JOIN proposition p ON p.subject_event_id = ev.event_id AND p.predicate = 'occursAt' AND p.object_entity_id = obj.entity_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'phase33_arthur_eddington', 'phase33_principe_observation_1919',
         'Eddington participates in the Principe 1919 eclipse observation event.',
         'Source-backed participation proposition only; no success, bias, or theory-confirmation claim is asserted.'),
        ('CLAIM_P33_COTTINGHAM_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'phase33_edwin_cottingham', 'phase33_principe_observation_1919',
         'Cottingham participates in the Principe 1919 eclipse observation event.',
         'Source-backed participation proposition only; no role hierarchy is asserted.'),
        ('CLAIM_P33_DAVIDSON_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'phase33_charles_davidson', 'phase33_sobral_observation_1919',
         'Davidson participates in the Sobral 1919 eclipse observation event.',
         'Source-backed participation proposition only; no instrument or weighting conclusion is asserted.'),
        ('CLAIM_P33_CROMMELIN_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'phase33_andrew_crommelin', 'phase33_sobral_observation_1919',
         'Crommelin participates in the Sobral 1919 eclipse observation event.',
         'Source-backed participation proposition only; no instrument or weighting conclusion is asserted.'),
        ('CLAIM_P33_ROYAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'phase33_royal_society', 'phase33_joint_eclipse_meeting_1919',
         'The Royal Society participates in the 1919 joint eclipse meeting.',
         'Source-backed organizational participation only; no institutional endorsement is asserted.'),
        ('CLAIM_P33_ROYAL_ASTRONOMICAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'phase33_royal_astronomical_society', 'phase33_joint_eclipse_meeting_1919',
         'The Royal Astronomical Society participates in the 1919 joint eclipse meeting.',
         'Source-backed organizational participation only; no institutional endorsement is asserted.')
     ) AS m(claim_key, subject_entity_key, object_event_key, statement, notes)
JOIN entity subj ON subj.entity_key = m.subject_entity_key
JOIN event obj ON obj.event_key = m.object_event_key
JOIN proposition p ON p.subject_entity_id = subj.entity_id AND p.predicate = 'participatesIn' AND p.object_event_id = obj.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P33_PRINCIPE_ASTROGRAPHIC_TELESCOPE_LOCATED_AT_PRINCIPE', 'phase33_principe_astrographic_telescope', 'phase33_principe_station',
         'The Principe astrographic telescope is located at the Principe station.',
         'Source-backed instrument location only; no instrument quality or reliability assessment is asserted.'),
        ('CLAIM_P33_SOBRAL_ASTROGRAPHIC_TELESCOPE_LOCATED_AT_SOBRAL', 'phase33_sobral_astrographic_telescope', 'phase33_sobral_station',
         'The Sobral astrographic telescope is located at the Sobral station.',
         'Source-backed instrument location only; the reported focus concern is preserved as evidence, not as a claim.'),
        ('CLAIM_P33_SOBRAL_FOUR_INCH_LENS_LOCATED_AT_SOBRAL', 'phase33_sobral_four_inch_lens', 'phase33_sobral_station',
         'The Sobral four-inch lens is located at the Sobral station.',
         'Source-backed instrument location only; no preference between the Sobral instruments is asserted.')
     ) AS m(claim_key, subject_entity_key, object_entity_key, statement, notes)
JOIN entity subj ON subj.entity_key = m.subject_entity_key
JOIN entity obj ON obj.entity_key = m.object_entity_key
JOIN proposition p ON p.subject_entity_id = subj.entity_id AND p.predicate = 'locatedAt' AND p.object_entity_id = obj.entity_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P33_PRINCIPE_OBSERVATION_PRECEDES_JOINT_MEETING', 'phase33_principe_observation_1919', 'phase33_joint_eclipse_meeting_1919',
         'The Principe 1919 eclipse observation event precedes the joint eclipse meeting.',
         'Source-backed ordering only; it models neither calendar dates nor data-selection sequence nor motive.'),
        ('CLAIM_P33_SOBRAL_OBSERVATION_PRECEDES_JOINT_MEETING', 'phase33_sobral_observation_1919', 'phase33_joint_eclipse_meeting_1919',
         'The Sobral 1919 eclipse observation event precedes the joint eclipse meeting.',
         'Source-backed ordering only; it models neither calendar dates nor data-selection sequence nor motive.')
     ) AS m(claim_key, subject_event_key, object_event_key, statement, notes)
JOIN event subj ON subj.event_key = m.subject_event_key
JOIN event obj ON obj.event_key = m.object_event_key
JOIN proposition p ON p.subject_event_id = subj.event_id AND p.predicate = 'precedes' AND p.object_event_id = obj.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', m.notes
FROM (VALUES
        ('CLAIM_P33_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'Primary report support for the Principe observing station.'),
        ('CLAIM_P33_SOBRAL_OBSERVATION_OCCURS_AT_SOBRAL', 'EV_P33_SOBRAL_OBSERVATIONS',
         'Primary report support for the Sobral observing station.'),
        ('CLAIM_P33_JOINT_MEETING_OCCURS_AT_BURLINGTON_HOUSE', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'Near-primary contemporary support for the reported meeting venue.'),
        ('CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'Primary report support for the Eddington/Principe association.'),
        ('CLAIM_P33_COTTINGHAM_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'Primary report support for the Cottingham/Principe association.'),
        ('CLAIM_P33_DAVIDSON_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'EV_P33_SOBRAL_OBSERVATIONS',
         'Primary report support for the Davidson/Sobral association.'),
        ('CLAIM_P33_CROMMELIN_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'EV_P33_SOBRAL_OBSERVATIONS',
         'Primary report support for the Crommelin/Sobral association.'),
        ('CLAIM_P33_ROYAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'Near-primary contemporary support for Royal Society participation in the meeting.'),
        ('CLAIM_P33_ROYAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'EV_P33_EXPEDITION_ORGANISATION',
         'Independent expedition-report support for the Royal Society''s role in the joint arrangements.'),
        ('CLAIM_P33_ROYAL_ASTRONOMICAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'Near-primary contemporary support for Royal Astronomical Society participation in the meeting.'),
        ('CLAIM_P33_ROYAL_ASTRONOMICAL_SOCIETY_PARTICIPATES_IN_JOINT_MEETING', 'EV_P33_EXPEDITION_ORGANISATION',
         'Independent expedition-report support for the Royal Astronomical Society''s role in the joint arrangements.'),
        ('CLAIM_P33_PRINCIPE_ASTROGRAPHIC_TELESCOPE_LOCATED_AT_PRINCIPE', 'EV_P33_PRINCIPE_INSTRUMENTS',
         'Primary report support for the Principe instrument location.'),
        ('CLAIM_P33_SOBRAL_ASTROGRAPHIC_TELESCOPE_LOCATED_AT_SOBRAL', 'EV_P33_SOBRAL_INSTRUMENTS',
         'Primary report support for the Sobral astrographic instrument location.'),
        ('CLAIM_P33_SOBRAL_FOUR_INCH_LENS_LOCATED_AT_SOBRAL', 'EV_P33_SOBRAL_INSTRUMENTS',
         'Primary report support for the Sobral four-inch lens location.'),
        ('CLAIM_P33_PRINCIPE_OBSERVATION_PRECEDES_JOINT_MEETING', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'Near-primary chronology support for observation before announcement.'),
        ('CLAIM_P33_SOBRAL_OBSERVATION_PRECEDES_JOINT_MEETING', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'Near-primary chronology support for observation before announcement.')
     ) AS m(claim_key, evidence_key, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key
ON CONFLICT DO NOTHING;

-- Source-specific identities remain distinct from canonical entities.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, x.source_identity_key, x.display_name
FROM source s
JOIN (VALUES
        ('ECLIPSE_1919_REPORT', 'phase33-report-eddington', 'A. S. Eddington'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-cottingham', 'E. T. Cottingham'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-davidson', 'C. R. Davidson'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-crommelin', 'A. C. D. Crommelin'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-dyson', 'F. W. Dyson'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-principe-station', 'Principe'),
        ('ECLIPSE_1919_REPORT', 'phase33-report-sobral-station', 'Sobral'),
        ('OBSERVATORY_1919_ECLIPSE', 'phase33-observatory-astronomer-royal', 'The Astronomer Royal'),
        ('OBSERVATORY_1919_ECLIPSE', 'phase33-observatory-burlington-house', 'Burlington House')
     ) AS x(source_key, source_identity_key, display_name) ON s.source_key = x.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, ent.entity_id, 'ACTIVE', 0.9700, m.justification, ev.evidence_id
FROM (VALUES
        ('phase33-report-eddington', 'phase33_arthur_eddington', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'The bounded expedition-report observation names Eddington in connection with the Principe station.'),
        ('phase33-report-cottingham', 'phase33_edwin_cottingham', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'The bounded expedition-report observation names Cottingham in connection with the Principe station.'),
        ('phase33-report-davidson', 'phase33_charles_davidson', 'EV_P33_SOBRAL_OBSERVATIONS',
         'The bounded expedition-report observation names Davidson in connection with the Sobral station.'),
        ('phase33-report-crommelin', 'phase33_andrew_crommelin', 'EV_P33_SOBRAL_OBSERVATIONS',
         'The bounded expedition-report observation names Crommelin in connection with the Sobral station.'),
        ('phase33-report-dyson', 'phase33_frank_dyson', 'EV_P33_EXPEDITION_ORGANISATION',
         'The bounded expedition-report observation names Dyson in connection with the expedition arrangements.'),
        ('phase33-report-principe-station', 'phase33_principe_station', 'EV_P33_PRINCIPE_OBSERVATIONS',
         'The bounded expedition-report observation identifies Principe as the source-specific observing station.'),
        ('phase33-report-sobral-station', 'phase33_sobral_station', 'EV_P33_SOBRAL_OBSERVATIONS',
         'The bounded expedition-report observation identifies Sobral as the source-specific observing station.'),
        ('phase33-observatory-burlington-house', 'phase33_burlington_house', 'EV_P33_OBSERVATORY_JOINT_MEETING',
         'The bounded contemporary observation identifies Burlington House as the reported meeting venue.')
     ) AS m(source_identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity ent ON ent.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key
WHERE NOT EXISTS (
    SELECT 1
    FROM entity_source_mapping esm
    WHERE esm.source_identity_id = si.source_identity_id
      AND esm.entity_id = ent.entity_id
      AND esm.mapping_status_code = 'ACTIVE'
);

-- Unresolved source identity: the contemporary report's title-only "Astronomer Royal" is not
-- automatically merged with the expedition report's named person. The candidate reconciliation is
-- preserved as PROPOSED with its justification and supporting evidence, and is never activated.
INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id, notes)
SELECT si.source_identity_id, ent.entity_id, 'PROPOSED', NULL,
       'The contemporary report refers to an office title rather than a named person. Identifying the title with the named individual would be a reconciliation judgement that the represented sources do not state.',
       ev.evidence_id,
       'Deliberately left PROPOSED. PROPOSED is not FALSE and is not a denial of identity; it records an unresolved source-identity question.'
FROM source_identity si
JOIN entity ent ON ent.entity_key = 'phase33_frank_dyson'
JOIN evidence ev ON ev.evidence_key = 'EV_P33_OBSERVATORY_JOINT_MEETING'
WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'
  AND NOT EXISTS (
    SELECT 1
    FROM entity_source_mapping esm
    WHERE esm.source_identity_id = si.source_identity_id
      AND esm.entity_id = ent.entity_id
);

COMMIT;
