-- Phase 37 Stage A: an independently keyed, source-driven population of the
-- bounded 1893 World's Columbian Exposition domain. This file contains no research
-- question, expected answer, ranking, or interpretation verdict.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'Official Catalogue of the World''s Columbian Exposition', 'HISTORICAL_WORK',
     'Contemporary exposition source published for the fair; locator-only reference.'),
    ('CHICAGO_TRIBUNE_1893_EXPOSITION_OPENING', 'Chicago Tribune report on the World''s Columbian Exposition Opening Day', 'HISTORICAL_WORK',
     'Independent contemporary newspaper account; locator-only reference.'),
    ('BADGER_1979_GREAT_AMERICAN_FAIR', 'Reid Badger, The Great American Fair: The World''s Columbian Exposition and American Culture', 'REFERENCE',
     'Later historical analysis retained as an analytical observation, not as source fact.'),
    ('RYDELL_1984_ALL_THE_WORLDS_A_FAIR', 'Robert Rydell, All the World''s a Fair', 'REFERENCE',
     'Later historiographical/critical analysis retained as an analytical observation, not as source fact.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, v.dataset_key, v.name, v.edition_label, 'p37-1',
       'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manual Phase 37 bounded domain population pass', v.notes
FROM source s
JOIN (VALUES
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'WCE_OFFICIAL_CATALOGUE_P37', 'Phase 37 Official Catalogue reference points', '1893 official catalogue',
     'Contemporary exposition source; locators only, no quoted text.'),
    ('CHICAGO_TRIBUNE_1893_EXPOSITION_OPENING', 'CHICAGO_TRIBUNE_P37', 'Phase 37 Chicago Tribune reference point', 'Chicago Tribune, 1 May 1893',
     'Independent contemporary newspaper account; locators only, no quoted text.'),
    ('BADGER_1979_GREAT_AMERICAN_FAIR', 'BADGER_1979_P37', 'Phase 37 Badger reference point', 'Nelson-Hall, 1979',
     'Later scholarly interpretation only.'),
    ('RYDELL_1984_ALL_THE_WORLDS_A_FAIR', 'RYDELL_1984_P37', 'Phase 37 Rydell reference point', 'University of Chicago Press, 1984',
     'Later scholarly interpretation only.')
) AS v(source_key, dataset_key, name, edition_label, notes) ON s.source_key = v.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, v.source_record_key, v.source_location, 'p37-1'
FROM dataset d
JOIN (VALUES
    ('WCE_OFFICIAL_CATALOGUE_P37', 'P37_CATALOGUE_DEDICATION_DAY', 'Official Catalogue (1893), Dedication Day ceremonies account'),
    ('WCE_OFFICIAL_CATALOGUE_P37', 'P37_CATALOGUE_OPENING_DAY', 'Official Catalogue (1893), Opening Day ceremonies account'),
    ('WCE_OFFICIAL_CATALOGUE_P37', 'P37_CATALOGUE_LADY_MANAGERS_NOTE', 'Official Catalogue (1893), Board of Lady Managers biographical note'),
    ('CHICAGO_TRIBUNE_P37', 'P37_TRIBUNE_OPENING_DAY_REPORT', 'Chicago Tribune, 1 May 1893, Opening Day report'),
    ('BADGER_1979_P37', 'P37_BADGER_1979', 'Badger (1979), The Great American Fair'),
    ('RYDELL_1984_P37', 'P37_RYDELL_1984', 'Rydell (1984), All the World''s a Fair')
) AS v(dataset_key, source_record_key, source_location) ON d.dataset_key = v.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_key IN ('WCE_OFFICIAL_CATALOGUE_P37', 'CHICAGO_TRIBUNE_P37', 'BADGER_1979_P37', 'RYDELL_1984_P37')
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT v.evidence_key, sr.source_record_id, v.observation, v.evidence_type_code, v.notes
FROM (VALUES
    ('EV_P37_DEDICATION_DAY', 'P37_CATALOGUE_DEDICATION_DAY',
     'The Official Catalogue reports the Dedication Day ceremonies at the Manufactures and Liberal Arts Building in Jackson Park and names Daniel Burnham and the Board of Lady Managers among participants.',
     'SOURCE_OBSERVATION', 'Contemporary observation; no claim about whether Dedication Day was the fair''s true opening is asserted.'),
    ('EV_P37_OPENING_DAY', 'P37_CATALOGUE_OPENING_DAY',
     'The Official Catalogue reports an Opening Day after the Dedication Day ceremonies and records President Grover Cleveland, Bertha Palmer, and Frederick Douglass among participants at Jackson Park.',
     'SOURCE_OBSERVATION', 'Contemporary observation; ordering only, not a calendar-date proposition.'),
    ('EV_P37_TRIBUNE_OPENING_DAY', 'P37_TRIBUNE_OPENING_DAY_REPORT',
     'The Chicago Tribune reports on the Opening Day ceremonies at Jackson Park and independently names Bertha Palmer among the participants.',
     'SOURCE_OBSERVATION', 'Independent contemporary account retained alongside the Official Catalogue.'),
    ('EV_P37_LADY_MANAGERS_NOTE', 'P37_CATALOGUE_LADY_MANAGERS_NOTE',
     'The Official Catalogue''s biographical note for the Board of Lady Managers president uses the married honorific ''Mrs. Potter Palmer'' rather than a full personal name.',
     'SOURCE_OBSERVATION', 'Honorific-only note; retained separately as an unresolved source identity, not merged into the participation claim.'),
    ('EV_P37_BADGER_INTERPRETATION', 'P37_BADGER_1979',
     'Badger analyzes the exposition''s architectural and civic unity as a deliberate expression of American cultural aspiration.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted to a direct-source claim.'),
    ('EV_P37_RYDELL_INTERPRETATION', 'P37_RYDELL_1984',
     'Rydell analyzes the exposition''s ethnographic exhibits and Midway Plaisance as an expression of contemporary racial and imperial ideology.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted to a direct-source claim or ranked against Badger.')
) AS v(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = v.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key LIKE 'EV\_P37\_%' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('phase37_daniel_burnham', 'PERSON', 'Daniel Burnham', 'Canonical person entity for the Director of Works named in the Official Catalogue.'),
    ('phase37_bertha_palmer', 'PERSON', 'Bertha Palmer', 'Canonical person entity for the President of the Board of Lady Managers named in both represented contemporary accounts.'),
    ('phase37_frederick_douglass', 'PERSON', 'Frederick Douglass', 'Canonical person entity for the Haitian commissioner named in the Official Catalogue.'),
    ('phase37_grover_cleveland', 'PERSON', 'Grover Cleveland', 'Canonical person entity for the President of the United States named in the Official Catalogue.'),
    ('phase37_jackson_park', 'PLACE', 'Jackson Park', 'Canonical place entity for the exposition grounds named in both represented contemporary accounts.'),
    ('phase37_board_of_lady_managers', 'ORGANIZATION', 'Board of Lady Managers', 'Convention body as described in the represented Official Catalogue.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('phase37_dedication_day_1892', 'OTHER', 'Dedication Day of the World''s Columbian Exposition as reported in the Official Catalogue.'),
    ('phase37_opening_day_1893', 'OTHER', 'Opening Day of the World''s Columbian Exposition as reported in the represented contemporary accounts.')
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT ev.event_id, 'occursAt', en.entity_id
FROM (VALUES
    ('phase37_dedication_day_1892', 'phase37_jackson_park'),
    ('phase37_opening_day_1893', 'phase37_jackson_park')
) AS v(event_key, entity_key)
JOIN event ev ON ev.event_key = v.event_key JOIN entity en ON en.entity_key = v.entity_key
WHERE NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_event_id = ev.event_id AND p.predicate = 'occursAt' AND p.object_entity_id = en.entity_id);

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT en.entity_id, 'participatesIn', ev.event_id
FROM (VALUES
    ('phase37_daniel_burnham', 'phase37_dedication_day_1892'),
    ('phase37_board_of_lady_managers', 'phase37_dedication_day_1892'),
    ('phase37_bertha_palmer', 'phase37_dedication_day_1892'),
    ('phase37_bertha_palmer', 'phase37_opening_day_1893'),
    ('phase37_frederick_douglass', 'phase37_opening_day_1893'),
    ('phase37_grover_cleveland', 'phase37_opening_day_1893')
) AS v(entity_key, event_key)
JOIN entity en ON en.entity_key = v.entity_key JOIN event ev ON ev.event_key = v.event_key
WHERE NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_entity_id = en.entity_id AND p.predicate = 'participatesIn' AND p.object_event_id = ev.event_id);

INSERT INTO proposition (subject_event_id, predicate, object_event_id)
SELECT dedication.event_id, 'precedes', opening.event_id
FROM event dedication JOIN event opening ON opening.event_key = 'phase37_opening_day_1893'
WHERE dedication.event_key = 'phase37_dedication_day_1892'
  AND NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_event_id = dedication.event_id AND p.predicate = 'precedes' AND p.object_event_id = opening.event_id);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT v.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', v.statement, v.notes
FROM (VALUES
    ('CLAIM_P37_DEDICATION_DAY_OCCURS_AT_JACKSON_PARK', 'phase37_dedication_day_1892', 'occursAt', 'phase37_jackson_park', 'Dedication Day occurs at Jackson Park.', 'Source-backed venue assertion only.'),
    ('CLAIM_P37_OPENING_DAY_OCCURS_AT_JACKSON_PARK', 'phase37_opening_day_1893', 'occursAt', 'phase37_jackson_park', 'Opening Day occurs at Jackson Park.', 'Source-backed venue assertion only.'),
    ('CLAIM_P37_BURNHAM_PARTICIPATES_IN_DEDICATION_DAY', 'phase37_daniel_burnham', 'participatesIn', 'phase37_dedication_day_1892', 'Daniel Burnham participates in Dedication Day.', 'No leadership hierarchy beyond the named role is asserted.'),
    ('CLAIM_P37_LADY_MANAGERS_PARTICIPATES_IN_DEDICATION_DAY', 'phase37_board_of_lady_managers', 'participatesIn', 'phase37_dedication_day_1892', 'The Board of Lady Managers participates in Dedication Day.', 'Organization-level participation only.'),
    ('CLAIM_P37_PALMER_PARTICIPATES_IN_DEDICATION_DAY', 'phase37_bertha_palmer', 'participatesIn', 'phase37_dedication_day_1892', 'Bertha Palmer participates in Dedication Day.', 'No leadership hierarchy beyond the named role is asserted.'),
    ('CLAIM_P37_PALMER_PARTICIPATES_IN_OPENING_DAY', 'phase37_bertha_palmer', 'participatesIn', 'phase37_opening_day_1893', 'Bertha Palmer participates in Opening Day.', 'Independently attested by two source traditions.'),
    ('CLAIM_P37_DOUGLASS_PARTICIPATES_IN_OPENING_DAY', 'phase37_frederick_douglass', 'participatesIn', 'phase37_opening_day_1893', 'Frederick Douglass participates in Opening Day.', 'Source-backed participation assertion only.'),
    ('CLAIM_P37_CLEVELAND_PARTICIPATES_IN_OPENING_DAY', 'phase37_grover_cleveland', 'participatesIn', 'phase37_opening_day_1893', 'Grover Cleveland participates in Opening Day.', 'Source-backed participation assertion only.'),
    ('CLAIM_P37_DEDICATION_DAY_PRECEDES_OPENING_DAY', 'phase37_dedication_day_1892', 'precedes', 'phase37_opening_day_1893', 'Dedication Day precedes Opening Day.', 'Ordering only; no date predicate is added.')
) AS v(claim_key, subject_key, predicate, object_key, statement, notes)
JOIN proposition p ON p.predicate = v.predicate
LEFT JOIN entity se ON se.entity_key = v.subject_key
LEFT JOIN event sv ON sv.event_key = v.subject_key
LEFT JOIN entity oe ON oe.entity_key = v.object_key
LEFT JOIN event ov ON ov.event_key = v.object_key
WHERE COALESCE(p.subject_entity_id, -1) = COALESCE(se.entity_id, -1)
  AND COALESCE(p.subject_event_id, -1) = COALESCE(sv.event_id, -1)
  AND COALESCE(p.object_entity_id, -1) = COALESCE(oe.entity_id, -1)
  AND COALESCE(p.object_event_id, -1) = COALESCE(ov.event_id, -1)
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Phase 37 source-backed support.'
FROM (VALUES
    ('CLAIM_P37_DEDICATION_DAY_OCCURS_AT_JACKSON_PARK', 'EV_P37_DEDICATION_DAY'),
    ('CLAIM_P37_OPENING_DAY_OCCURS_AT_JACKSON_PARK', 'EV_P37_OPENING_DAY'),
    ('CLAIM_P37_BURNHAM_PARTICIPATES_IN_DEDICATION_DAY', 'EV_P37_DEDICATION_DAY'),
    ('CLAIM_P37_LADY_MANAGERS_PARTICIPATES_IN_DEDICATION_DAY', 'EV_P37_DEDICATION_DAY'),
    ('CLAIM_P37_PALMER_PARTICIPATES_IN_DEDICATION_DAY', 'EV_P37_DEDICATION_DAY'),
    ('CLAIM_P37_PALMER_PARTICIPATES_IN_OPENING_DAY', 'EV_P37_OPENING_DAY'),
    ('CLAIM_P37_PALMER_PARTICIPATES_IN_OPENING_DAY', 'EV_P37_TRIBUNE_OPENING_DAY'),
    ('CLAIM_P37_DOUGLASS_PARTICIPATES_IN_OPENING_DAY', 'EV_P37_OPENING_DAY'),
    ('CLAIM_P37_CLEVELAND_PARTICIPATES_IN_OPENING_DAY', 'EV_P37_OPENING_DAY'),
    ('CLAIM_P37_DEDICATION_DAY_PRECEDES_OPENING_DAY', 'EV_P37_OPENING_DAY')
) AS v(claim_key, evidence_key)
JOIN claim c ON c.claim_key = v.claim_key JOIN evidence e ON e.evidence_key = v.evidence_key
ON CONFLICT DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, v.source_identity_key, v.display_name
FROM source s JOIN (VALUES
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'phase37-catalogue-burnham', 'Daniel Burnham'),
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'phase37-catalogue-mrs-potter-palmer', 'Mrs. Potter Palmer'),
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'phase37-catalogue-douglass', 'Frederick Douglass'),
    ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'phase37-catalogue-cleveland', 'Grover Cleveland'),
    ('CHICAGO_TRIBUNE_1893_EXPOSITION_OPENING', 'phase37-tribune-palmer', 'Bertha Palmer')
) AS v(source_key, source_identity_key, display_name) ON v.source_key = s.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9800, v.justification, e.evidence_id
FROM (VALUES
    ('phase37-catalogue-burnham', 'phase37_daniel_burnham', 'EV_P37_DEDICATION_DAY', 'The Official Catalogue names Daniel Burnham.'),
    ('phase37-catalogue-douglass', 'phase37_frederick_douglass', 'EV_P37_OPENING_DAY', 'The Official Catalogue names Frederick Douglass.'),
    ('phase37-catalogue-cleveland', 'phase37_grover_cleveland', 'EV_P37_OPENING_DAY', 'The Official Catalogue names Grover Cleveland.'),
    ('phase37-tribune-palmer', 'phase37_bertha_palmer', 'EV_P37_TRIBUNE_OPENING_DAY', 'The Chicago Tribune independently names Bertha Palmer.')
) AS v(source_identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = v.source_identity_key
JOIN entity en ON en.entity_key = v.entity_key JOIN evidence e ON e.evidence_key = v.evidence_key
WHERE NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id AND esm.mapping_status_code = 'ACTIVE');

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, justification, supporting_evidence_id, notes)
SELECT si.source_identity_id, en.entity_id, 'PROPOSED',
       'The represented biographical note uses a married honorific; the corpus does not itself supply the full-name reconciliation.',
       e.evidence_id, 'Deliberately unresolved: PROPOSED is not a denial of identity.'
FROM source_identity si JOIN entity en ON en.entity_key = 'phase37_bertha_palmer'
JOIN evidence e ON e.evidence_key = 'EV_P37_LADY_MANAGERS_NOTE'
WHERE si.source_identity_key = 'phase37-catalogue-mrs-potter-palmer'
  AND NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id);

COMMIT;
