-- Phase 36 Stage A: an independently keyed, source-driven population of the
-- bounded 1848 Seneca Falls Convention domain. This file contains no research
-- question, expected answer, ranking, or interpretation verdict.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('SENECA_FALLS_PROCEEDINGS_1848', 'Report of the Woman''s Rights Convention, Held at Seneca Falls, N.Y., July 19th and 20th, 1848', 'HISTORICAL_WORK',
     'Contemporary published convention proceedings; locator-only reference.'),
    ('NORTH_STAR_1848_SENECA_FALLS', 'The North Star report on the Seneca Falls Convention', 'HISTORICAL_WORK',
     'Contemporary newspaper account by Frederick Douglass; locator-only reference.'),
    ('WELLMAN_2004_SENECA_FALLS', 'Judith Wellman, The Road to Seneca Falls', 'REFERENCE',
     'Later historical analysis retained as an analytical observation, not as source fact.'),
    ('TETRAULT_2014_SENECA_FALLS', 'Lisa Tetrault, The Myth of Seneca Falls', 'REFERENCE',
     'Later historiographical analysis retained as an analytical observation, not as source fact.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, v.dataset_key, v.name, v.edition_label, 'p36-1',
       'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manual Phase 36 bounded domain population pass', v.notes
FROM source s
JOIN (VALUES
    ('SENECA_FALLS_PROCEEDINGS_1848', 'SENECA_FALLS_PROCEEDINGS_P36', 'Phase 36 convention proceedings reference points', '1848 proceedings',
     'Contemporary proceedings; locators only, no quoted text.'),
    ('NORTH_STAR_1848_SENECA_FALLS', 'NORTH_STAR_SENECA_FALLS_P36', 'Phase 36 North Star reference point', 'The North Star, 28 July 1848',
     'Contemporary newspaper account; locators only, no quoted text.'),
    ('WELLMAN_2004_SENECA_FALLS', 'WELLMAN_2004_P36', 'Phase 36 Wellman reference point', 'University of Illinois Press, 2004',
     'Later scholarly interpretation only.'),
    ('TETRAULT_2014_SENECA_FALLS', 'TETRAULT_2014_P36', 'Phase 36 Tetrault reference point', 'University of North Carolina Press, 2014',
     'Later scholarly interpretation only.')
) AS v(source_key, dataset_key, name, edition_label, notes) ON s.source_key = v.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, v.source_record_key, v.source_location, 'p36-1'
FROM dataset d
JOIN (VALUES
    ('SENECA_FALLS_PROCEEDINGS_P36', 'P36_PROCEEDINGS_DAY_ONE', 'Report of the Woman''s Rights Convention (1848), first day proceedings'),
    ('SENECA_FALLS_PROCEEDINGS_P36', 'P36_PROCEEDINGS_DAY_TWO', 'Report of the Woman''s Rights Convention (1848), second day proceedings'),
    ('NORTH_STAR_SENECA_FALLS_P36', 'P36_NORTH_STAR_CONVENTION_REPORT', 'The North Star, 28 July 1848, convention report'),
    ('WELLMAN_2004_P36', 'P36_WELLMAN_2004', 'Wellman (2004), The Road to Seneca Falls'),
    ('TETRAULT_2014_P36', 'P36_TETRAULT_2014', 'Tetrault (2014), The Myth of Seneca Falls')
) AS v(dataset_key, source_record_key, source_location) ON d.dataset_key = v.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_key IN ('SENECA_FALLS_PROCEEDINGS_P36', 'NORTH_STAR_SENECA_FALLS_P36', 'WELLMAN_2004_P36', 'TETRAULT_2014_P36')
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT v.evidence_key, sr.source_record_id, v.observation, v.evidence_type_code, v.notes
FROM (VALUES
    ('EV_P36_DAY_ONE', 'P36_PROCEEDINGS_DAY_ONE',
     'The proceedings report the first day of the convention at the Wesleyan Chapel in Seneca Falls and name Elizabeth Cady Stanton and Lucretia Mott in its proceedings.',
     'SOURCE_OBSERVATION', 'Contemporary observation; no claim about the convention''s historical primacy is asserted.'),
    ('EV_P36_DAY_TWO', 'P36_PROCEEDINGS_DAY_TWO',
     'The proceedings report a second day after the first day and record Frederick Douglass among participants.',
     'SOURCE_OBSERVATION', 'Contemporary observation; ordering only, not a calendar-date proposition.'),
    ('EV_P36_NORTH_STAR_ACCOUNT', 'P36_NORTH_STAR_CONVENTION_REPORT',
     'The North Star reports on the convention and identifies Frederick Douglass in its account.',
     'SOURCE_OBSERVATION', 'Independent contemporary account retained alongside the proceedings.'),
    ('EV_P36_WELLMAN_INTERPRETATION', 'P36_WELLMAN_2004',
     'Wellman analyzes the local networks and organizing context that preceded the convention.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted to a direct-source claim.'),
    ('EV_P36_TETRAULT_INTERPRETATION', 'P36_TETRAULT_2014',
     'Tetrault analyzes how later historical memory constructed Seneca Falls as an origin story.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted to a direct-source claim or ranked against Wellman.')
) AS v(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = v.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key LIKE 'EV\_P36\_%' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('phase36_elizabeth_cady_stanton', 'PERSON', 'Elizabeth Cady Stanton', 'Canonical person entity for the participant named in the proceedings.'),
    ('phase36_lucretia_mott', 'PERSON', 'Lucretia Mott', 'Canonical person entity for the participant named in the proceedings.'),
    ('phase36_frederick_douglass', 'PERSON', 'Frederick Douglass', 'Canonical person entity named in both represented contemporary accounts.'),
    ('phase36_wesleyan_chapel', 'PLACE', 'Wesleyan Chapel', 'Canonical place entity for the venue named in the proceedings.'),
    ('phase36_seneca_falls', 'PLACE', 'Seneca Falls', 'Canonical place entity for the town named in the proceedings.'),
    ('phase36_woman_rights_convention', 'ORGANIZATION', 'Woman''s Rights Convention', 'Convention body as described in the represented proceedings.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('phase36_seneca_falls_day_one_1848', 'OTHER', 'First day of the 1848 Seneca Falls convention as reported in the proceedings.'),
    ('phase36_seneca_falls_day_two_1848', 'OTHER', 'Second day of the 1848 Seneca Falls convention as reported in the proceedings.')
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT ev.event_id, 'occursAt', en.entity_id
FROM (VALUES
    ('phase36_seneca_falls_day_one_1848', 'phase36_wesleyan_chapel'),
    ('phase36_seneca_falls_day_two_1848', 'phase36_wesleyan_chapel')
) AS v(event_key, entity_key)
JOIN event ev ON ev.event_key = v.event_key JOIN entity en ON en.entity_key = v.entity_key
WHERE NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_event_id = ev.event_id AND p.predicate = 'occursAt' AND p.object_entity_id = en.entity_id);

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT en.entity_id, 'participatesIn', ev.event_id
FROM (VALUES
    ('phase36_elizabeth_cady_stanton', 'phase36_seneca_falls_day_one_1848'),
    ('phase36_lucretia_mott', 'phase36_seneca_falls_day_one_1848'),
    ('phase36_frederick_douglass', 'phase36_seneca_falls_day_two_1848'),
    ('phase36_woman_rights_convention', 'phase36_seneca_falls_day_one_1848')
) AS v(entity_key, event_key)
JOIN entity en ON en.entity_key = v.entity_key JOIN event ev ON ev.event_key = v.event_key
WHERE NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_entity_id = en.entity_id AND p.predicate = 'participatesIn' AND p.object_event_id = ev.event_id);

INSERT INTO proposition (subject_event_id, predicate, object_event_id)
SELECT first_day.event_id, 'precedes', second_day.event_id
FROM event first_day JOIN event second_day ON second_day.event_key = 'phase36_seneca_falls_day_two_1848'
WHERE first_day.event_key = 'phase36_seneca_falls_day_one_1848'
  AND NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_event_id = first_day.event_id AND p.predicate = 'precedes' AND p.object_event_id = second_day.event_id);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT v.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', v.statement, v.notes
FROM (VALUES
    ('CLAIM_P36_DAY_ONE_OCCURS_AT_WESLEYAN_CHAPEL', 'phase36_seneca_falls_day_one_1848', 'occursAt', 'phase36_wesleyan_chapel', 'The first day occurs at Wesleyan Chapel.', 'Source-backed venue assertion only.'),
    ('CLAIM_P36_DAY_TWO_OCCURS_AT_WESLEYAN_CHAPEL', 'phase36_seneca_falls_day_two_1848', 'occursAt', 'phase36_wesleyan_chapel', 'The second day occurs at Wesleyan Chapel.', 'Source-backed venue assertion only.'),
    ('CLAIM_P36_STANTON_PARTICIPATES_IN_DAY_ONE', 'phase36_elizabeth_cady_stanton', 'participatesIn', 'phase36_seneca_falls_day_one_1848', 'Elizabeth Cady Stanton participates in the first day.', 'No leadership hierarchy is asserted.'),
    ('CLAIM_P36_MOTT_PARTICIPATES_IN_DAY_ONE', 'phase36_lucretia_mott', 'participatesIn', 'phase36_seneca_falls_day_one_1848', 'Lucretia Mott participates in the first day.', 'No leadership hierarchy is asserted.'),
    ('CLAIM_P36_DOUGLASS_PARTICIPATES_IN_DAY_TWO', 'phase36_frederick_douglass', 'participatesIn', 'phase36_seneca_falls_day_two_1848', 'Frederick Douglass participates in the second day.', 'Source-backed participation assertion only.'),
    ('CLAIM_P36_DAY_ONE_PRECEDES_DAY_TWO', 'phase36_seneca_falls_day_one_1848', 'precedes', 'phase36_seneca_falls_day_two_1848', 'The first day precedes the second day.', 'Ordering only; no date predicate is added.')
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
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Phase 36 source-backed support.'
FROM (VALUES
    ('CLAIM_P36_DAY_ONE_OCCURS_AT_WESLEYAN_CHAPEL', 'EV_P36_DAY_ONE'),
    ('CLAIM_P36_DAY_TWO_OCCURS_AT_WESLEYAN_CHAPEL', 'EV_P36_DAY_TWO'),
    ('CLAIM_P36_STANTON_PARTICIPATES_IN_DAY_ONE', 'EV_P36_DAY_ONE'),
    ('CLAIM_P36_MOTT_PARTICIPATES_IN_DAY_ONE', 'EV_P36_DAY_ONE'),
    ('CLAIM_P36_DOUGLASS_PARTICIPATES_IN_DAY_TWO', 'EV_P36_DAY_TWO'),
    ('CLAIM_P36_DOUGLASS_PARTICIPATES_IN_DAY_TWO', 'EV_P36_NORTH_STAR_ACCOUNT'),
    ('CLAIM_P36_DAY_ONE_PRECEDES_DAY_TWO', 'EV_P36_DAY_TWO')
) AS v(claim_key, evidence_key)
JOIN claim c ON c.claim_key = v.claim_key JOIN evidence e ON e.evidence_key = v.evidence_key
ON CONFLICT DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, v.source_identity_key, v.display_name
FROM source s JOIN (VALUES
    ('SENECA_FALLS_PROCEEDINGS_1848', 'phase36-proceedings-stanton', 'Elizabeth Cady Stanton'),
    ('SENECA_FALLS_PROCEEDINGS_1848', 'phase36-proceedings-mrs-mott', 'Mrs. Mott'),
    ('NORTH_STAR_1848_SENECA_FALLS', 'phase36-north-star-douglass', 'Frederick Douglass')
) AS v(source_key, source_identity_key, display_name) ON v.source_key = s.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9800, v.justification, e.evidence_id
FROM (VALUES
    ('phase36-proceedings-stanton', 'phase36_elizabeth_cady_stanton', 'EV_P36_DAY_ONE', 'The proceedings name Elizabeth Cady Stanton.'),
    ('phase36-north-star-douglass', 'phase36_frederick_douglass', 'EV_P36_NORTH_STAR_ACCOUNT', 'The North Star account names Frederick Douglass.')
) AS v(source_identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = v.source_identity_key
JOIN entity en ON en.entity_key = v.entity_key JOIN evidence e ON e.evidence_key = v.evidence_key
WHERE NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id AND esm.mapping_status_code = 'ACTIVE');

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, justification, supporting_evidence_id, notes)
SELECT si.source_identity_id, en.entity_id, 'PROPOSED',
       'The represented proceedings use an honorific and surname; the corpus does not itself supply the full-name reconciliation.',
       e.evidence_id, 'Deliberately unresolved: PROPOSED is not a denial of identity.'
FROM source_identity si JOIN entity en ON en.entity_key = 'phase36_lucretia_mott'
JOIN evidence e ON e.evidence_key = 'EV_P36_DAY_ONE'
WHERE si.source_identity_key = 'phase36-proceedings-mrs-mott'
  AND NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id);

COMMIT;
