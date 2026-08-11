-- Phase 32 cross-domain scholarly research generalization fixture.
--
-- This fixture uses the 1919 solar-eclipse expedition as a bounded non-Genesis
-- research problem. It preserves independently sourced observation layers,
-- competing scholarship, and registry limits without adding schema, predicates,
-- claim types, evidence types, interpretation persistence, or reconciliation logic.
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
SELECT s.source_id, d.dataset_key, d.name, d.edition_label, 'ref-1',
       'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manually entered bounded research references', d.notes
FROM source s
JOIN (VALUES
        ('ECLIPSE_1919_REPORT', 'ECLIPSE_1919_REPORT_REF', '1919 eclipse expedition report reference points',
         'Philosophical Transactions of the Royal Society A 220 (1920)',
         'Phase 32 primary report observations only; no quoted text is stored.'),
        ('OBSERVATORY_1919_ECLIPSE', 'OBSERVATORY_1919_REF', '1919 joint eclipse meeting reference point',
         'The Observatory 42 (1919)',
         'Phase 32 near-primary announcement/chronology reference only.'),
        ('EARMAN_GLYMOUR_1980', 'EARMAN_GLYMOUR_1980_REF', 'Earman and Glymour 1980 reference point',
         'Historical Studies in the Physical Sciences 11.1',
         'Phase 32 scholarly-position candidate only.'),
        ('KENNEFICK_2007', 'KENNEFICK_2007_REF', 'Kennefick 2007 reference point',
         'Einstein Studies 12',
         'Phase 32 scholarly-position candidate only.')
     ) AS d(source_key, dataset_key, name, edition_label, notes) ON s.source_key = d.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('ECLIPSE_1919_REPORT_REF', 'ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Principe observations and reductions'),
        ('ECLIPSE_1919_REPORT_REF', 'ECLIPSE_1919_SOBRAL_OBSERVATIONS',
         'Philosophical Transactions of the Royal Society A 220 (1920), Sobral observations and reductions'),
        ('ECLIPSE_1919_REPORT_REF', 'ECLIPSE_1919_RESULTS_DISCUSSION',
         'Philosophical Transactions of the Royal Society A 220 (1920), discussion of deflection results'),
        ('OBSERVATORY_1919_REF', 'OBSERVATORY_1919_JOINT_MEETING',
         'The Observatory 42 (1919), Joint Eclipse Meeting report'),
        ('EARMAN_GLYMOUR_1980_REF', 'EARMAN_GLYMOUR_1980_49_85',
         'Historical Studies in the Physical Sciences 11.1 (1980): 49-85'),
        ('KENNEFICK_2007_REF', 'KENNEFICK_2007_EINSTEIN_STUDIES_12',
         'Einstein Studies 12 (2007), reassessment of the 1919 eclipse expedition')
     ) AS r(dataset_key, source_record_key, source_location) ON d.dataset_key = r.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
    'ECLIPSE_1919_SOBRAL_OBSERVATIONS',
    'ECLIPSE_1919_RESULTS_DISCUSSION',
    'OBSERVATORY_1919_JOINT_MEETING',
    'EARMAN_GLYMOUR_1980_49_85',
    'KENNEFICK_2007_EINSTEIN_STUDIES_12'
)
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, m.evidence_type_code, m.notes
FROM (VALUES
        ('EV_ECLIPSE_1919_PRINCIPE_OBS_P32', 'ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
         'The 1920 expedition report treats the Principe eclipse plates as a distinct observational tradition and associates Eddington with the Principe station.',
         'SOURCE_OBSERVATION',
         'Primary-source observation layer only; no theory-confirmation or truth verdict is asserted.'),
        ('EV_ECLIPSE_1919_SOBRAL_OBS_P32', 'ECLIPSE_1919_SOBRAL_OBSERVATIONS',
         'The 1920 expedition report treats the Sobral observations as a distinct observational tradition and associates Davidson and Crommelin with the Sobral station.',
         'SOURCE_OBSERVATION',
         'Primary-source observation layer only; no identity merger with Principe data is asserted.'),
        ('EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32', 'ECLIPSE_1919_RESULTS_DISCUSSION',
         'The 1920 report distinguishes the Sobral astrographic plates from the smaller-telescope Sobral result because of an instrumental/focus concern.',
         'SOURCE_OBSERVATION',
         'Records a source-reported ambiguity without converting data weighting into bias, contradiction, or theory confirmation.'),
        ('EV_OBSERVATORY_1919_ANNOUNCEMENT_P32', 'OBSERVATORY_1919_JOINT_MEETING',
         'The contemporary joint-meeting report presents the eclipse announcement after the May 1919 observations and frames the result in relation to Einstein''s predicted deflection.',
         'SOURCE_OBSERVATION',
         'Near-primary chronology and announcement layer; later source is not treated as a plate-level observation.'),
        ('EV_EARMAN_GLYMOUR_1980_INTERPRETATION_P32', 'EARMAN_GLYMOUR_1980_49_85',
         'Earman and Glymour reassess the 1919 eclipse evidence and question simplified accounts of decisiveness and data handling.',
         'ANALYTICAL_OBSERVATION',
         'Competing scholarly interpretation retained without promotion to primary source fact.'),
        ('EV_KENNEFICK_2007_INTERPRETATION_P32', 'KENNEFICK_2007_EINSTEIN_STUDIES_12',
         'Kennefick presents a competing reassessment that resists simple accusations of theory-driven data rejection.',
         'ANALYTICAL_OBSERVATION',
         'Competing scholarly interpretation retained without consensus ranking.')
     ) AS m(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN citation c ON c.source_record_id = sr.source_record_id
WHERE e.evidence_key LIKE 'EV\_%\_P32' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('phase32_arthur_eddington', 'PERSON', 'Arthur Stanley Eddington',
     'Astronomer associated with the Principe 1919 eclipse observations in the bounded Phase 32 corpus.'),
    ('phase32_charles_davidson', 'PERSON', 'Charles R. Davidson',
     'Astronomer associated with the Sobral 1919 eclipse observations in the bounded Phase 32 corpus.'),
    ('phase32_andrew_crommelin', 'PERSON', 'Andrew C. D. Crommelin',
     'Astronomer associated with the Sobral 1919 eclipse observations in the bounded Phase 32 corpus.'),
    ('phase32_principe', 'PLACE', 'Principe eclipse station',
     'Canonical place entity for the Principe observation station, preserving source-specific identity separately.'),
    ('phase32_sobral', 'PLACE', 'Sobral eclipse station',
     'Canonical place entity for the Sobral observation station, preserving source-specific identity separately.'),
    ('phase32_general_relativity_deflection', 'CONCEPT', 'General-relativity light-deflection prediction',
     'Concept used for research comparison only; no supportsTheory predicate or truth verdict is introduced.'),
    ('phase32_newtonian_deflection', 'CONCEPT', 'Newtonian light-deflection comparison value',
     'Concept used for research comparison only; no ranking or theory-disproof claim is introduced.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('phase32_principe_eclipse_observation_1919', 'OTHER',
     'The Principe observational station activity during the 1919 solar eclipse expedition.'),
    ('phase32_sobral_eclipse_observation_1919', 'OTHER',
     'The Sobral observational station activity during the 1919 solar eclipse expedition.'),
    ('phase32_joint_eclipse_announcement_1919', 'OTHER',
     'The contemporary joint meeting announcing and discussing the 1919 eclipse results.')
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT ev.event_id, 'occursAt', place.entity_id
FROM (VALUES
        ('phase32_principe_eclipse_observation_1919', 'phase32_principe'),
        ('phase32_sobral_eclipse_observation_1919', 'phase32_sobral')
     ) AS m(event_key, place_key)
JOIN event ev ON ev.event_key = m.event_key
JOIN entity place ON place.entity_key = m.place_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_event_id = ev.event_id AND p.predicate = 'occursAt' AND p.object_entity_id = place.entity_id
);

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT person.entity_id, 'participatesIn', ev.event_id
FROM (VALUES
        ('phase32_arthur_eddington', 'phase32_principe_eclipse_observation_1919'),
        ('phase32_charles_davidson', 'phase32_sobral_eclipse_observation_1919'),
        ('phase32_andrew_crommelin', 'phase32_sobral_eclipse_observation_1919')
     ) AS m(entity_key, event_key)
JOIN entity person ON person.entity_key = m.entity_key
JOIN event ev ON ev.event_key = m.event_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_entity_id = person.entity_id AND p.predicate = 'participatesIn' AND p.object_event_id = ev.event_id
);

INSERT INTO proposition (subject_event_id, predicate, object_event_id)
SELECT observation.event_id, 'precedes', announcement.event_id
FROM (VALUES
        ('phase32_principe_eclipse_observation_1919'),
        ('phase32_sobral_eclipse_observation_1919')
     ) AS m(event_key)
JOIN event observation ON observation.event_key = m.event_key
JOIN event announcement ON announcement.event_key = 'phase32_joint_eclipse_announcement_1919'
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_event_id = observation.event_id AND p.predicate = 'precedes' AND p.object_event_id = announcement.event_id
);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P32_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE', 'phase32_principe_eclipse_observation_1919', 'occursAt', 'phase32_principe',
         'The Principe 1919 eclipse observation event occurs at the Principe station.',
         'Direct source-backed location proposition; it is not a verdict about the observation''s correctness.'),
        ('CLAIM_P32_SOBRAL_OBSERVATION_OCCURS_AT_SOBRAL', 'phase32_sobral_eclipse_observation_1919', 'occursAt', 'phase32_sobral',
         'The Sobral 1919 eclipse observation event occurs at the Sobral station.',
         'Direct source-backed location proposition; it is not a merger with the Principe observation tradition.')
     ) AS m(claim_key, subject_event_key, predicate, object_entity_key, statement, notes)
JOIN event ev ON ev.event_key = m.subject_event_key
JOIN entity obj ON obj.entity_key = m.object_entity_key
JOIN proposition p ON p.subject_event_id = ev.event_id AND p.predicate = m.predicate AND p.object_entity_id = obj.entity_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'phase32_arthur_eddington', 'participatesIn', 'phase32_principe_eclipse_observation_1919',
         'Eddington participates in the Principe 1919 eclipse observation event.',
         'Direct source-backed participation proposition only; no success, bias, or theory-confirmation claim is asserted.'),
        ('CLAIM_P32_DAVIDSON_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'phase32_charles_davidson', 'participatesIn', 'phase32_sobral_eclipse_observation_1919',
         'Davidson participates in the Sobral 1919 eclipse observation event.',
         'Direct source-backed participation proposition only; no weighting or instrument conclusion is asserted.'),
        ('CLAIM_P32_CROMMELIN_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'phase32_andrew_crommelin', 'participatesIn', 'phase32_sobral_eclipse_observation_1919',
         'Crommelin participates in the Sobral 1919 eclipse observation event.',
         'Direct source-backed participation proposition only; no weighting or instrument conclusion is asserted.')
     ) AS m(claim_key, subject_entity_key, predicate, object_event_key, statement, notes)
JOIN entity subj ON subj.entity_key = m.subject_entity_key
JOIN event obj ON obj.event_key = m.object_event_key
JOIN proposition p ON p.subject_entity_id = subj.entity_id AND p.predicate = m.predicate AND p.object_event_id = obj.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('CLAIM_P32_PRINCIPE_OBSERVATION_PRECEDES_ANNOUNCEMENT', 'phase32_principe_eclipse_observation_1919', 'phase32_joint_eclipse_announcement_1919',
         'The Principe 1919 eclipse observation event precedes the joint eclipse announcement event.',
         'Chronological source-backed proposition only; it does not model data-selection sequence or motive.'),
        ('CLAIM_P32_SOBRAL_OBSERVATION_PRECEDES_ANNOUNCEMENT', 'phase32_sobral_eclipse_observation_1919', 'phase32_joint_eclipse_announcement_1919',
         'The Sobral 1919 eclipse observation event precedes the joint eclipse announcement event.',
         'Chronological source-backed proposition only; it does not model data-selection sequence or motive.')
     ) AS m(claim_key, subject_event_key, object_event_key, statement, notes)
JOIN event subj ON subj.event_key = m.subject_event_key
JOIN event obj ON obj.event_key = m.object_event_key
JOIN proposition p ON p.subject_event_id = subj.event_id AND p.predicate = 'precedes' AND p.object_event_id = obj.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', m.notes
FROM (VALUES
        ('CLAIM_P32_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE', 'EV_ECLIPSE_1919_PRINCIPE_OBS_P32',
         'Primary report support for the Principe observation station.'),
        ('CLAIM_P32_SOBRAL_OBSERVATION_OCCURS_AT_SOBRAL', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'Primary report support for the Sobral observation station.'),
        ('CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION', 'EV_ECLIPSE_1919_PRINCIPE_OBS_P32',
         'Primary report support for Eddington association with Principe.'),
        ('CLAIM_P32_DAVIDSON_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'Primary report support for Davidson association with Sobral.'),
        ('CLAIM_P32_CROMMELIN_PARTICIPATES_IN_SOBRAL_OBSERVATION', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'Primary report support for Crommelin association with Sobral.'),
        ('CLAIM_P32_PRINCIPE_OBSERVATION_PRECEDES_ANNOUNCEMENT', 'EV_OBSERVATORY_1919_ANNOUNCEMENT_P32',
         'Near-primary chronology support for the observation preceding announcement.'),
        ('CLAIM_P32_SOBRAL_OBSERVATION_PRECEDES_ANNOUNCEMENT', 'EV_OBSERVATORY_1919_ANNOUNCEMENT_P32',
         'Near-primary chronology support for the observation preceding announcement.')
     ) AS m(claim_key, evidence_key, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key
ON CONFLICT DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, x.source_identity_key, x.display_name
FROM source s
JOIN (VALUES
        ('ECLIPSE_1919_REPORT', 'phase32-report-eddington', 'A. S. Eddington'),
        ('ECLIPSE_1919_REPORT', 'phase32-report-davidson', 'C. R. Davidson'),
        ('ECLIPSE_1919_REPORT', 'phase32-report-crommelin', 'A. C. D. Crommelin'),
        ('ECLIPSE_1919_REPORT', 'phase32-report-principe-station', 'Principe'),
        ('ECLIPSE_1919_REPORT', 'phase32-report-sobral-station', 'Sobral')
     ) AS x(source_key, source_identity_key, display_name) ON s.source_key = x.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, ent.entity_id, 'ACTIVE', 0.9700, m.justification, ev.evidence_id
FROM (VALUES
        ('phase32-report-eddington', 'phase32_arthur_eddington', 'EV_ECLIPSE_1919_PRINCIPE_OBS_P32',
         'The bounded primary report observation associates Eddington with the Principe station.'),
        ('phase32-report-davidson', 'phase32_charles_davidson', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'The bounded primary report observation associates Davidson with the Sobral station.'),
        ('phase32-report-crommelin', 'phase32_andrew_crommelin', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'The bounded primary report observation associates Crommelin with the Sobral station.'),
        ('phase32-report-principe-station', 'phase32_principe', 'EV_ECLIPSE_1919_PRINCIPE_OBS_P32',
         'The bounded primary report observation identifies Principe as the source-specific station.'),
        ('phase32-report-sobral-station', 'phase32_sobral', 'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
         'The bounded primary report observation identifies Sobral as the source-specific station.')
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

COMMIT;
