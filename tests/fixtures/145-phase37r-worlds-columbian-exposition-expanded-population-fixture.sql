-- Phase 37R Stage A: independently keyed, question-free expansion of the 1893
-- World's Columbian Exposition electrical corpus. Source text remains locator-only.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('WCE_OFFICIAL_DIRECTORY_1893', 'Official Directory of the World''s Columbian Exposition', 'HISTORICAL_WORK',
     'Primary official exhibitor directory; locator-only Phase 37R authority.'),
    ('BARRETT_ELECTRICITY_COLUMBIAN_1894', 'J. P. Barrett, Electricity at the Columbian Exposition', 'HISTORICAL_WORK',
     'Contemporary technical account; locator-only Phase 37R authority.'),
    ('ELECTRICAL_INDUSTRIES_WCE_1893', 'Electrical Industries: World''s Columbian Exposition', 'HISTORICAL_WORK',
     'Contemporary electrical-industry publication; locator-only Phase 37R authority.'),
    ('BADGER_1979_GREAT_AMERICAN_FAIR', 'Reid Badger, The Great American Fair: The World''s Columbian Exposition and American Culture', 'REFERENCE',
     'Later historical analysis retained as an analytical observation.'),
    ('RYDELL_1984_ALL_THE_WORLDS_A_FAIR', 'Robert Rydell, All the World''s a Fair', 'REFERENCE',
     'Later historiographical analysis retained as an analytical observation.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset
    (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, v.dataset_key, v.name, v.edition_label, 'p37r-1',
       'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manual Phase 37R discovery, verification, and bounded population pass', v.notes
FROM source s
JOIN (VALUES
    ('WCE_OFFICIAL_DIRECTORY_1893', 'WCE_OFFICIAL_DIRECTORY_P37R', 'Phase 37R official directory reference points', '1893 directory',
     'PRIMARY_OFFICIAL; exhibitor and Electricity Building locators only.'),
    ('BARRETT_ELECTRICITY_COLUMBIAN_1894', 'BARRETT_ELECTRICITY_P37R', 'Phase 37R Barrett reference points', '1894 contemporary account',
     'PRIMARY_CONTEMPORARY_TECHNICAL; exhibit and apparatus locators only.'),
    ('ELECTRICAL_INDUSTRIES_WCE_1893', 'ELECTRICAL_INDUSTRIES_P37R', 'Phase 37R electrical-industry reference points', '1893 trade publication',
     'PRIMARY_CONTEMPORARY_TRADE; independent electrical exhibit locators only.'),
    ('BADGER_1979_GREAT_AMERICAN_FAIR', 'BADGER_1979_P37R', 'Phase 37R Badger interpretation reference', 'Nelson-Hall, 1979',
     'SCHOLARLY_INTERPRETATION; never direct-source claim support.'),
    ('RYDELL_1984_ALL_THE_WORLDS_A_FAIR', 'RYDELL_1984_P37R', 'Phase 37R Rydell interpretation reference', 'University of Chicago Press, 1984',
     'SCHOLARLY_INTERPRETATION; never direct-source claim support.')
) AS v(source_key, dataset_key, name, edition_label, notes) ON s.source_key = v.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, v.record_key, v.locator, 'p37r-1'
FROM dataset d
JOIN (VALUES
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_ELECTRICITY_BUILDING', 'Official Directory (1893), Electricity Building and classified exhibitor directory'),
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_TESLA', 'Official Directory (1893), classified exhibitor entry for Nikola Tesla'),
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_WESTINGHOUSE', 'Official Directory (1893), classified exhibitor entry for Westinghouse Electric and Manufacturing Company'),
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_GENERAL_ELECTRIC', 'Official Directory (1893), classified exhibitor entry for General Electric Company'),
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_WESTERN_ELECTRIC', 'Official Directory (1893), classified exhibitor entry for Western Electric Company'),
    ('WCE_OFFICIAL_DIRECTORY_P37R', 'P37R_DIRECTORY_EDISON_NAME', 'Official Directory (1893), index entry using the Edison name; identity context unresolved'),
    ('BARRETT_ELECTRICITY_P37R', 'P37R_BARRETT_TESLA_EXHIBIT', 'Barrett (1894), discussion of the Tesla exhibit and electrical apparatus'),
    ('BARRETT_ELECTRICITY_P37R', 'P37R_BARRETT_WESTINGHOUSE_EXHIBIT', 'Barrett (1894), discussion of the Westinghouse exhibit and polyphase apparatus'),
    ('BARRETT_ELECTRICITY_P37R', 'P37R_BARRETT_GENERAL_ELECTRIC_EXHIBIT', 'Barrett (1894), discussion of the General Electric exhibit and incandescent lamps'),
    ('BARRETT_ELECTRICITY_P37R', 'P37R_BARRETT_WESTERN_ELECTRIC_EXHIBIT', 'Barrett (1894), discussion of the Western Electric exhibit and telephone apparatus'),
    ('ELECTRICAL_INDUSTRIES_P37R', 'P37R_ELECTRICAL_INDUSTRIES_TESLA', 'Electrical Industries (1893), Tesla exhibit and apparatus coverage'),
    ('ELECTRICAL_INDUSTRIES_P37R', 'P37R_ELECTRICAL_INDUSTRIES_WESTINGHOUSE', 'Electrical Industries (1893), Westinghouse exhibit and polyphase apparatus coverage'),
    ('BADGER_1979_P37R', 'P37R_BADGER_ELECTRICAL_INTERPRETATION', 'Badger (1979), exposition technology and cultural-aspiration analysis'),
    ('RYDELL_1984_P37R', 'P37R_RYDELL_ELECTRICAL_INTERPRETATION', 'Rydell (1984), exposition ordering and imperial-display analysis')
) AS v(dataset_key, record_key, locator) ON d.dataset_key = v.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_key LIKE '%\_P37R' ESCAPE '\'
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT v.evidence_key, sr.source_record_id, v.observation, v.evidence_type_code, v.notes
FROM (VALUES
    ('EV_P37R_DIRECTORY_ELECTRICITY_BUILDING', 'P37R_DIRECTORY_ELECTRICITY_BUILDING',
     'The official directory groups the selected electrical exhibitors and exhibits in the Electricity Building.',
     'SOURCE_OBSERVATION', 'Official locator-level observation; no claim of technological rank or superiority.'),
    ('EV_P37R_DIRECTORY_TESLA', 'P37R_DIRECTORY_TESLA',
     'The official directory''s classified electrical-exhibitor material generated a Nikola Tesla verification candidate.',
     'SOURCE_OBSERVATION', 'Candidate locator only; exact individual listing requires page verification and backs no claim.'),
    ('EV_P37R_DIRECTORY_WESTINGHOUSE', 'P37R_DIRECTORY_WESTINGHOUSE',
     'The official directory identifies the Westinghouse Electric and Manufacturing Company as an electrical exhibitor.',
     'SOURCE_OBSERVATION', 'Organization-level exhibit observation.'),
    ('EV_P37R_DIRECTORY_GENERAL_ELECTRIC', 'P37R_DIRECTORY_GENERAL_ELECTRIC',
     'The official directory identifies the General Electric Company as an electrical exhibitor.',
     'SOURCE_OBSERVATION', 'Organization-level exhibit observation.'),
    ('EV_P37R_DIRECTORY_WESTERN_ELECTRIC', 'P37R_DIRECTORY_WESTERN_ELECTRIC',
     'The official directory identifies the Western Electric Company as an electrical exhibitor.',
     'SOURCE_OBSERVATION', 'Organization-level exhibit observation.'),
    ('EV_P37R_DIRECTORY_EDISON_NAME', 'P37R_DIRECTORY_EDISON_NAME',
     'The directory index uses the Edison name in electrical exhibit context without resolving whether a reference denotes the person, named apparatus, or a company display.',
     'SOURCE_OBSERVATION', 'Identity context deliberately unresolved; backs no claim.'),
    ('EV_P37R_BARRETT_TESLA', 'P37R_BARRETT_TESLA_EXHIBIT',
     'Barrett describes Nikola Tesla''s electrical exhibit with alternating-current induction motors and high-frequency apparatus in the Electricity Building.',
     'SOURCE_OBSERVATION', 'Contemporary technical account; represents presence only, not superiority.'),
    ('EV_P37R_BARRETT_WESTINGHOUSE', 'P37R_BARRETT_WESTINGHOUSE_EXHIBIT',
     'Barrett describes George Westinghouse, the Westinghouse company exhibit, and polyphase alternating-current apparatus in the Electricity Building.',
     'SOURCE_OBSERVATION', 'Contemporary technical account; no employment predicate or victory claim.'),
    ('EV_P37R_BARRETT_GENERAL_ELECTRIC', 'P37R_BARRETT_GENERAL_ELECTRIC_EXHIBIT',
     'Barrett describes the General Electric Company exhibit and its incandescent electric lamps in the Electricity Building.',
     'SOURCE_OBSERVATION', 'Contemporary technical account; does not establish Thomas Edison''s personal participation.'),
    ('EV_P37R_BARRETT_WESTERN_ELECTRIC', 'P37R_BARRETT_WESTERN_ELECTRIC_EXHIBIT',
     'Barrett describes the Western Electric Company exhibit and telephone apparatus in the Electricity Building.',
     'SOURCE_OBSERVATION', 'Contemporary technical account.'),
    ('EV_P37R_ELECTRICAL_INDUSTRIES_TESLA', 'P37R_ELECTRICAL_INDUSTRIES_TESLA',
     'The contemporary electrical-industry publication independently covers Tesla''s induction-motor and high-frequency apparatus exhibit.',
     'SOURCE_OBSERVATION', 'Independent trade-source corroboration; no significance judgment.'),
    ('EV_P37R_ELECTRICAL_INDUSTRIES_WESTINGHOUSE', 'P37R_ELECTRICAL_INDUSTRIES_WESTINGHOUSE',
     'The contemporary electrical-industry publication independently covers the Westinghouse exhibit and polyphase apparatus.',
     'SOURCE_OBSERVATION', 'Independent trade-source corroboration; no victory or superiority judgment.'),
    ('EV_P37R_BADGER_INTERPRETATION', 'P37R_BADGER_ELECTRICAL_INTERPRETATION',
     'Badger treats the exposition''s technological display within an interpretation emphasizing civic and cultural aspiration.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted to a direct-source claim.'),
    ('EV_P37R_RYDELL_INTERPRETATION', 'P37R_RYDELL_ELECTRICAL_INTERPRETATION',
     'Rydell treats the exposition''s displays within an interpretation emphasizing racialized ordering and imperial ideology.',
     'ANALYTICAL_OBSERVATION', 'Later scholarship; never promoted, ranked, or merged.')
) AS v(evidence_key, record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = v.record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key LIKE 'EV\_P37R\_%' ESCAPE '\'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('phase37r_nikola_tesla', 'PERSON', 'Nikola Tesla', 'Person independently selected through the Phase 37R discovery and verification workflow.'),
    ('phase37r_westinghouse_company', 'ORGANIZATION', 'Westinghouse Electric and Manufacturing Company', 'Organization represented as an electrical exhibitor.'),
    ('phase37r_general_electric_company', 'ORGANIZATION', 'General Electric Company', 'Organization represented as an electrical exhibitor.'),
    ('phase37r_western_electric_company', 'ORGANIZATION', 'Western Electric Company', 'Organization represented as an electrical exhibitor.'),
    ('phase37r_electricity_building', 'PLACE', 'Electricity Building', 'Place containing the represented electrical exhibition and exhibits.'),
    ('phase37r_polyphase_ac_system', 'CONCEPT', 'Polyphase alternating-current system', 'Electrical technology represented only in its source-backed exhibit context.'),
    ('phase37r_induction_motors', 'OBJECT', 'Alternating-current induction motors', 'Electrical apparatus represented only in its source-backed exhibit context.'),
    ('phase37r_high_frequency_apparatus', 'OBJECT', 'High-frequency electrical apparatus', 'Electrical apparatus represented only in its source-backed exhibit context.'),
    ('phase37r_incandescent_lamps', 'OBJECT', 'Incandescent electric lamps', 'Electrical apparatus represented only in its source-backed exhibit context.'),
    ('phase37r_telephone_apparatus', 'OBJECT', 'Telephone apparatus', 'Electrical apparatus represented only in its source-backed exhibit context.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('phase37r_electrical_exhibition_1893', 'OTHER', 'Bounded electrical exhibition represented by the selected Electricity Building corpus.'),
    ('phase37r_tesla_electrical_exhibit_1893', 'OTHER', 'Nikola Tesla personal electrical exhibit.'),
    ('phase37r_westinghouse_electrical_exhibit_1893', 'OTHER', 'Westinghouse electrical exhibit.'),
    ('phase37r_general_electric_exhibit_1893', 'OTHER', 'General Electric exhibit.'),
    ('phase37r_western_electric_exhibit_1893', 'OTHER', 'Western Electric exhibit.')
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT ev.event_id, 'occursAt', place.entity_id
FROM (VALUES
    ('phase37r_electrical_exhibition_1893'),
    ('phase37r_tesla_electrical_exhibit_1893'),
    ('phase37r_westinghouse_electrical_exhibit_1893'),
    ('phase37r_general_electric_exhibit_1893'),
    ('phase37r_western_electric_exhibit_1893')
) AS v(event_key)
JOIN event ev ON ev.event_key = v.event_key
JOIN entity place ON place.entity_key = 'phase37r_electricity_building'
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_event_id = ev.event_id AND p.predicate = 'occursAt'
      AND p.object_entity_id = place.entity_id
);

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT en.entity_id, 'participatesIn', ev.event_id
FROM (VALUES
    ('phase37r_nikola_tesla', 'phase37r_tesla_electrical_exhibit_1893'),
    ('phase37r_nikola_tesla', 'phase37r_westinghouse_electrical_exhibit_1893'),
    ('phase37r_westinghouse_company', 'phase37r_westinghouse_electrical_exhibit_1893'),
    ('phase37r_general_electric_company', 'phase37r_general_electric_exhibit_1893'),
    ('phase37r_western_electric_company', 'phase37r_western_electric_exhibit_1893'),
    ('phase37r_polyphase_ac_system', 'phase37r_westinghouse_electrical_exhibit_1893'),
    ('phase37r_induction_motors', 'phase37r_tesla_electrical_exhibit_1893'),
    ('phase37r_high_frequency_apparatus', 'phase37r_tesla_electrical_exhibit_1893'),
    ('phase37r_incandescent_lamps', 'phase37r_general_electric_exhibit_1893'),
    ('phase37r_telephone_apparatus', 'phase37r_western_electric_exhibit_1893')
) AS v(entity_key, event_key)
JOIN entity en ON en.entity_key = v.entity_key
JOIN event ev ON ev.event_key = v.event_key
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_entity_id = en.entity_id AND p.predicate = 'participatesIn'
      AND p.object_event_id = ev.event_id
);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT v.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', v.statement, v.notes
FROM (VALUES
    ('CLAIM_P37R_ELECTRICAL_EXHIBITION_AT_ELECTRICITY_BUILDING', 'phase37r_electrical_exhibition_1893', 'phase37r_electricity_building', 'The represented electrical exhibition occurs at the Electricity Building.', 'Bounded context only.'),
    ('CLAIM_P37R_TESLA_EXHIBIT_AT_ELECTRICITY_BUILDING', 'phase37r_tesla_electrical_exhibit_1893', 'phase37r_electricity_building', 'The Tesla electrical exhibit occurs at the Electricity Building.', 'Exhibit location only.'),
    ('CLAIM_P37R_WESTINGHOUSE_EXHIBIT_AT_ELECTRICITY_BUILDING', 'phase37r_westinghouse_electrical_exhibit_1893', 'phase37r_electricity_building', 'The Westinghouse electrical exhibit occurs at the Electricity Building.', 'Exhibit location only.'),
    ('CLAIM_P37R_GENERAL_ELECTRIC_EXHIBIT_AT_ELECTRICITY_BUILDING', 'phase37r_general_electric_exhibit_1893', 'phase37r_electricity_building', 'The General Electric exhibit occurs at the Electricity Building.', 'Exhibit location only.'),
    ('CLAIM_P37R_WESTERN_ELECTRIC_EXHIBIT_AT_ELECTRICITY_BUILDING', 'phase37r_western_electric_exhibit_1893', 'phase37r_electricity_building', 'The Western Electric exhibit occurs at the Electricity Building.', 'Exhibit location only.')
) AS v(claim_key, event_key, place_key, statement, notes)
JOIN event ev ON ev.event_key = v.event_key
JOIN entity place ON place.entity_key = v.place_key
JOIN proposition p ON p.subject_event_id = ev.event_id AND p.predicate = 'occursAt'
                  AND p.object_entity_id = place.entity_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT v.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', v.statement, v.notes
FROM (VALUES
    ('CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT', 'phase37r_nikola_tesla', 'phase37r_tesla_electrical_exhibit_1893', 'Nikola Tesla participates in the Tesla electrical exhibit.', 'No company membership or historical-significance claim.'),
    ('CLAIM_P37R_TESLA_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', 'phase37r_nikola_tesla', 'phase37r_westinghouse_electrical_exhibit_1893', 'Nikola Tesla participates in the Westinghouse electrical exhibit.', 'Source-backed polyphase exhibit context; no company membership or historical-victory claim.'),
    ('CLAIM_P37R_WESTINGHOUSE_COMPANY_PARTICIPATES_IN_EXHIBIT', 'phase37r_westinghouse_company', 'phase37r_westinghouse_electrical_exhibit_1893', 'Westinghouse Electric and Manufacturing Company participates in the Westinghouse exhibit.', 'Organization-level exhibit participation.'),
    ('CLAIM_P37R_GENERAL_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'phase37r_general_electric_company', 'phase37r_general_electric_exhibit_1893', 'General Electric Company participates in the General Electric exhibit.', 'Organization-level exhibit participation.'),
    ('CLAIM_P37R_WESTERN_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'phase37r_western_electric_company', 'phase37r_western_electric_exhibit_1893', 'Western Electric Company participates in the Western Electric exhibit.', 'Organization-level exhibit participation.'),
    ('CLAIM_P37R_POLYPHASE_SYSTEM_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', 'phase37r_polyphase_ac_system', 'phase37r_westinghouse_electrical_exhibit_1893', 'The polyphase alternating-current system participates in the Westinghouse exhibit.', 'Technology-in-exhibit context only.'),
    ('CLAIM_P37R_INDUCTION_MOTORS_PARTICIPATE_IN_TESLA_EXHIBIT', 'phase37r_induction_motors', 'phase37r_tesla_electrical_exhibit_1893', 'Alternating-current induction motors participate in the Tesla exhibit.', 'Apparatus-in-exhibit context only.'),
    ('CLAIM_P37R_HIGH_FREQUENCY_APPARATUS_PARTICIPATES_IN_TESLA_EXHIBIT', 'phase37r_high_frequency_apparatus', 'phase37r_tesla_electrical_exhibit_1893', 'High-frequency electrical apparatus participates in the Tesla exhibit.', 'Apparatus-in-exhibit context only.'),
    ('CLAIM_P37R_INCANDESCENT_LAMPS_PARTICIPATE_IN_GENERAL_ELECTRIC_EXHIBIT', 'phase37r_incandescent_lamps', 'phase37r_general_electric_exhibit_1893', 'Incandescent electric lamps participate in the General Electric exhibit.', 'Apparatus-in-exhibit context only.'),
    ('CLAIM_P37R_TELEPHONE_APPARATUS_PARTICIPATES_IN_WESTERN_ELECTRIC_EXHIBIT', 'phase37r_telephone_apparatus', 'phase37r_western_electric_exhibit_1893', 'Telephone apparatus participates in the Western Electric exhibit.', 'Apparatus-in-exhibit context only.')
) AS v(claim_key, entity_key, event_key, statement, notes)
JOIN entity en ON en.entity_key = v.entity_key
JOIN event ev ON ev.event_key = v.event_key
JOIN proposition p ON p.subject_entity_id = en.entity_id AND p.predicate = 'participatesIn'
                  AND p.object_event_id = ev.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Phase 37R locator-only source support.'
FROM (VALUES
    ('CLAIM_P37R_ELECTRICAL_EXHIBITION_AT_ELECTRICITY_BUILDING', 'EV_P37R_DIRECTORY_ELECTRICITY_BUILDING'),
    ('CLAIM_P37R_TESLA_EXHIBIT_AT_ELECTRICITY_BUILDING', 'EV_P37R_DIRECTORY_ELECTRICITY_BUILDING'),
    ('CLAIM_P37R_WESTINGHOUSE_EXHIBIT_AT_ELECTRICITY_BUILDING', 'EV_P37R_DIRECTORY_ELECTRICITY_BUILDING'),
    ('CLAIM_P37R_GENERAL_ELECTRIC_EXHIBIT_AT_ELECTRICITY_BUILDING', 'EV_P37R_DIRECTORY_ELECTRICITY_BUILDING'),
    ('CLAIM_P37R_WESTERN_ELECTRIC_EXHIBIT_AT_ELECTRICITY_BUILDING', 'EV_P37R_DIRECTORY_ELECTRICITY_BUILDING'),
    ('CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT', 'EV_P37R_BARRETT_TESLA'),
    ('CLAIM_P37R_TESLA_PARTICIPATES_IN_TESLA_EXHIBIT', 'EV_P37R_ELECTRICAL_INDUSTRIES_TESLA'),
    ('CLAIM_P37R_TESLA_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', 'EV_P37R_BARRETT_WESTINGHOUSE'),
    ('CLAIM_P37R_WESTINGHOUSE_COMPANY_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_DIRECTORY_WESTINGHOUSE'),
    ('CLAIM_P37R_WESTINGHOUSE_COMPANY_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_BARRETT_WESTINGHOUSE'),
    ('CLAIM_P37R_GENERAL_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_DIRECTORY_GENERAL_ELECTRIC'),
    ('CLAIM_P37R_GENERAL_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_BARRETT_GENERAL_ELECTRIC'),
    ('CLAIM_P37R_WESTERN_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_DIRECTORY_WESTERN_ELECTRIC'),
    ('CLAIM_P37R_WESTERN_ELECTRIC_PARTICIPATES_IN_EXHIBIT', 'EV_P37R_BARRETT_WESTERN_ELECTRIC'),
    ('CLAIM_P37R_POLYPHASE_SYSTEM_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', 'EV_P37R_BARRETT_WESTINGHOUSE'),
    ('CLAIM_P37R_POLYPHASE_SYSTEM_PARTICIPATES_IN_WESTINGHOUSE_EXHIBIT', 'EV_P37R_ELECTRICAL_INDUSTRIES_WESTINGHOUSE'),
    ('CLAIM_P37R_INDUCTION_MOTORS_PARTICIPATE_IN_TESLA_EXHIBIT', 'EV_P37R_BARRETT_TESLA'),
    ('CLAIM_P37R_INDUCTION_MOTORS_PARTICIPATE_IN_TESLA_EXHIBIT', 'EV_P37R_ELECTRICAL_INDUSTRIES_TESLA'),
    ('CLAIM_P37R_HIGH_FREQUENCY_APPARATUS_PARTICIPATES_IN_TESLA_EXHIBIT', 'EV_P37R_BARRETT_TESLA'),
    ('CLAIM_P37R_HIGH_FREQUENCY_APPARATUS_PARTICIPATES_IN_TESLA_EXHIBIT', 'EV_P37R_ELECTRICAL_INDUSTRIES_TESLA'),
    ('CLAIM_P37R_INCANDESCENT_LAMPS_PARTICIPATE_IN_GENERAL_ELECTRIC_EXHIBIT', 'EV_P37R_BARRETT_GENERAL_ELECTRIC'),
    ('CLAIM_P37R_TELEPHONE_APPARATUS_PARTICIPATES_IN_WESTERN_ELECTRIC_EXHIBIT', 'EV_P37R_BARRETT_WESTERN_ELECTRIC')
) AS v(claim_key, evidence_key)
JOIN claim c ON c.claim_key = v.claim_key
JOIN evidence e ON e.evidence_key = v.evidence_key
ON CONFLICT DO NOTHING;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, v.identity_key, v.display_name
FROM source s
JOIN (VALUES
    ('BARRETT_ELECTRICITY_COLUMBIAN_1894', 'phase37r-barrett-nikola-tesla', 'Nikola Tesla'),
    ('BARRETT_ELECTRICITY_COLUMBIAN_1894', 'phase37r-barrett-george-westinghouse', 'George Westinghouse'),
    ('WCE_OFFICIAL_DIRECTORY_1893', 'phase37r-directory-westinghouse-company', 'Westinghouse Electric and Manufacturing Company'),
    ('WCE_OFFICIAL_DIRECTORY_1893', 'phase37r-directory-general-electric-company', 'General Electric Company'),
    ('WCE_OFFICIAL_DIRECTORY_1893', 'phase37r-directory-western-electric-company', 'Western Electric Company'),
    ('WCE_OFFICIAL_DIRECTORY_1893', 'phase37r-directory-edison-name', 'Edison')
) AS v(source_key, identity_key, display_name) ON s.source_key = v.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping
    (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9800, v.justification, e.evidence_id
FROM (VALUES
    ('phase37r-barrett-nikola-tesla', 'phase37r_nikola_tesla', 'EV_P37R_BARRETT_TESLA', 'The contemporary technical account identifies Nikola Tesla and his exhibit.'),
    ('phase37r-directory-westinghouse-company', 'phase37r_westinghouse_company', 'EV_P37R_DIRECTORY_WESTINGHOUSE', 'The official directory supplies the company exhibitor identity.'),
    ('phase37r-directory-general-electric-company', 'phase37r_general_electric_company', 'EV_P37R_DIRECTORY_GENERAL_ELECTRIC', 'The official directory supplies the company exhibitor identity.'),
    ('phase37r-directory-western-electric-company', 'phase37r_western_electric_company', 'EV_P37R_DIRECTORY_WESTERN_ELECTRIC', 'The official directory supplies the company exhibitor identity.')
) AS v(identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = v.identity_key
JOIN entity en ON en.entity_key = v.entity_key
JOIN evidence e ON e.evidence_key = v.evidence_key
WHERE NOT EXISTS (
    SELECT 1 FROM entity_source_mapping esm
    WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id
      AND esm.mapping_status_code = 'ACTIVE'
);

COMMIT;
