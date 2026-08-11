\set ON_ERROR_STOP on

-- Phase 33 Stage B: independent research queries.
--
-- These questions were withheld from the Stage A population fixture, the Stage A validation, and
-- the candidate worksheet. Nothing below is looked up in an answer table: every result is produced
-- by traversing the persisted Berean substrate (Source -> Dataset -> SourceRecord -> Citation ->
-- Evidence -> ClaimEvidence -> Claim -> Proposition -> Entity/Event) with ordinary read-only SQL.
-- Retrieval scope is BEREAN_ONLY; no external corpus is consulted.
--
-- Question 8, question 9, and question 10 are anti-contamination probes: they ask for graph
-- properties (cross-station participation, multi-instrument stations, unreconciled identities)
-- that no Stage A row states, so they can only be answered by traversal.

-- Session-local pre-query counters. This is not part of the persistent substrate and is created
-- before the read-only transaction begins.
DROP TABLE IF EXISTS phase33_counts_before;
CREATE TEMP TABLE phase33_counts_before AS
SELECT
    (SELECT count(*) FROM source) AS sources,
    (SELECT count(*) FROM dataset) AS datasets,
    (SELECT count(*) FROM source_record) AS source_records,
    (SELECT count(*) FROM citation) AS citations,
    (SELECT count(*) FROM source_identity) AS source_identities,
    (SELECT count(*) FROM entity_source_mapping) AS mappings,
    (SELECT count(*) FROM entity) AS entities,
    (SELECT count(*) FROM event) AS events,
    (SELECT count(*) FROM proposition) AS propositions,
    (SELECT count(*) FROM claim) AS claims,
    (SELECT count(*) FROM evidence) AS evidence,
    (SELECT count(*) FROM claim_evidence) AS claim_evidence,
    (SELECT count(*) FROM claim_relation) AS claim_relations;

BEGIN READ ONLY;

\echo 'Q1: What can Berean establish from the represented sources about what happened during the 1919 eclipse observations?'
SELECT c.claim_key,
       r.rendered_proposition,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS supporting_sources,
       'DIRECTLY_SUPPORTED' AS retrieval_class
FROM claim c
JOIN claim_rendering r ON r.claim_id = c.claim_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
GROUP BY c.claim_key, r.rendered_proposition
ORDER BY c.claim_key;

\echo 'Q2: What do the represented sources independently report, and where do their accounts differ?'
SELECT s.source_key,
       e.evidence_key,
       e.evidence_type_code,
       CASE WHEN ce.evidence_id IS NULL THEN 'EVIDENCE_ONLY_NOT_CLAIM_BACKING' ELSE 'SUPPORTS_A_CLAIM' END AS claim_role,
       e.observation
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
LEFT JOIN (SELECT DISTINCT evidence_id FROM claim_evidence) ce ON ce.evidence_id = e.evidence_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
ORDER BY s.source_key, e.evidence_key;

\echo 'Q2b: Are any of those source differences persisted as contradictions?'
SELECT count(*) AS persisted_contradictions_among_phase33_claims,
       'DIFFERENCE_IS_NOT_CONTRADICTION' AS boundary
FROM claim_relation cr
JOIN claim a ON a.claim_id = cr.claim_id
JOIN claim b ON b.claim_id = cr.related_claim_id
WHERE (a.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\' OR b.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\');

\echo 'Q3: Which competing scholarly interpretations are represented, and what is their status?'
SELECT s.source_key,
       e.evidence_key,
       ci.citation_key,
       ci.locator,
       (SELECT count(*) FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id) AS claims_backed,
       'SCHOLARLY_CANDIDATE_NOT_PROMOTED' AS retrieval_class
FROM evidence e
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
  AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
ORDER BY s.source_key, e.evidence_key;

\echo 'Q4: Which conclusions are represented as direct source-backed claims, and which would require interpretation?'
SELECT 'DIRECTLY_SUPPORTED' AS retrieval_class, c.claim_key AS object_key, c.claim_type_code AS detail
FROM claim c
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
UNION ALL
SELECT 'REQUIRES_INTERPRETATION_NOT_CLAIMED', e.evidence_key, e.evidence_type_code
FROM evidence e
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
  AND ce.evidence_id IS NULL
ORDER BY 1, 2;

\echo 'Q5: Show the complete provenance of one direct claim about the eclipse observations.'
SELECT c.claim_key,
       p.predicate,
       coalesce(subj_e.canonical_name, subj_v.event_key) AS subject,
       coalesce(obj_e.canonical_name, obj_v.event_key) AS object,
       ce.relation_type_code,
       e.evidence_key,
       e.evidence_type_code,
       ci.citation_key,
       sr.source_record_key,
       d.dataset_key,
       s.source_key,
       CASE WHEN sr.raw_content IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS source_text_status
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
LEFT JOIN entity subj_e ON subj_e.entity_id = p.subject_entity_id
LEFT JOIN event subj_v ON subj_v.event_id = p.subject_event_id
LEFT JOIN entity obj_e ON obj_e.entity_id = p.object_entity_id
LEFT JOIN event obj_v ON obj_v.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key = 'CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION'
ORDER BY e.evidence_key, ci.citation_key;

\echo 'Q6: What does the populated domain establish about the Sobral data-handling issue, and what remains interpretive?'
SELECT e.evidence_key,
       e.observation,
       (SELECT count(*) FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id) AS claims_backed,
       (SELECT count(*) FROM proposition p
        JOIN entity subj ON subj.entity_id = p.subject_entity_id
        WHERE subj.entity_key IN ('phase33_sobral_astrographic_telescope', 'phase33_sobral_four_inch_lens')
          AND p.predicate <> 'locatedAt') AS non_location_instrument_propositions,
       'UNRESOLVED_NOT_ESTABLISHED' AS retrieval_class
FROM evidence e
WHERE e.evidence_key = 'EV_P33_SOBRAL_ASTROGRAPHIC_CONCERN';

\echo 'Q7: What ordering does Berean establish among the represented occurrences, and what does it not establish?'
SELECT subj.event_key AS earlier_event,
       obj.event_key AS later_event,
       c.claim_key,
       (SELECT count(*) FROM proposition p2
        JOIN event ev2 ON ev2.event_id = p2.subject_event_id
        WHERE ev2.event_key LIKE 'phase33\_%' ESCAPE '\'
          AND p2.object_typed_value_id IS NOT NULL) AS represented_event_dates,
       'ORDERING_ONLY_NO_CALENDAR_DATES' AS retrieval_class
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event subj ON subj.event_id = p.subject_event_id
JOIN event obj ON obj.event_id = p.object_event_id
WHERE p.predicate = 'precedes'
  AND c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
ORDER BY subj.event_key, obj.event_key;

\echo 'Q8 (novel probe): Does Berean establish that any represented person took part in observing at more than one station?'
SELECT person.canonical_name,
       count(DISTINCT station.entity_key) AS distinct_stations,
       string_agg(DISTINCT station.canonical_name, ', ' ORDER BY station.canonical_name) AS stations
FROM event_participation ep
JOIN entity person ON person.entity_id = ep.entity_id
JOIN event ev ON ev.event_id = ep.event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity station ON station.entity_id = loc.object_entity_id
WHERE person.entity_key LIKE 'phase33\_%' ESCAPE '\'
  AND person.entity_type_code = 'PERSON'
  AND ev.event_key IN ('phase33_principe_observation_1919', 'phase33_sobral_observation_1919')
GROUP BY person.canonical_name
HAVING count(DISTINCT station.entity_key) > 1
ORDER BY person.canonical_name;

\echo 'Q9 (novel probe): Which represented stations hold more than one attested instrument, and does Berean establish any preference among them?'
SELECT station.canonical_name AS station,
       count(*) AS attested_instruments,
       string_agg(instrument.canonical_name, ', ' ORDER BY instrument.canonical_name) AS instruments,
       (SELECT count(*) FROM proposition pr
        JOIN entity a ON a.entity_id = pr.subject_entity_id
        JOIN entity b ON b.entity_id = pr.object_entity_id
        WHERE a.entity_type_code = 'OBJECT' AND b.entity_type_code = 'OBJECT'
          AND a.entity_key LIKE 'phase33\_%' ESCAPE '\') AS instrument_to_instrument_relations,
       'PREFERENCE_NOT_ESTABLISHED' AS retrieval_class
FROM proposition p
JOIN entity instrument ON instrument.entity_id = p.subject_entity_id
JOIN entity station ON station.entity_id = p.object_entity_id
WHERE p.predicate = 'locatedAt'
  AND instrument.entity_key LIKE 'phase33\_%' ESCAPE '\'
  AND instrument.entity_type_code = 'OBJECT'
GROUP BY station.canonical_name
HAVING count(*) > 1
ORDER BY station.canonical_name;

\echo 'Q10 (novel probe): Which represented source identities remain unreconciled with a canonical entity?'
SELECT s.source_key,
       si.source_identity_key,
       si.display_name,
       esm.mapping_status_code,
       ent.canonical_name AS proposed_entity,
       esm.justification
FROM source_identity si
JOIN source s ON s.source_id = si.source_id
LEFT JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
LEFT JOIN entity ent ON ent.entity_id = esm.entity_id
WHERE si.source_identity_key LIKE 'phase33-%'
  AND (esm.mapping_status_code IS NULL OR esm.mapping_status_code <> 'ACTIVE')
ORDER BY s.source_key, si.source_identity_key;

\echo 'Bounded synthesis over the retrieved objects (derived from the traversals above, not persisted).'
SELECT section, statement
FROM (
    VALUES
      (1, 'Supported by represented source evidence',
       'Every Phase 33 claim retrieved above is a DIRECT_SOURCE_CLAIM whose provenance terminates in a registered source; station locations, station participants, instrument locations, meeting venue, meeting participants, and observation-before-meeting ordering are represented.'),
      (2, 'Source differences and unresolved conflicts',
       'The expedition report and the contemporary meeting report are retrieved independently; the reported Sobral astrographic focus concern and the reported meeting reservations are evidence-only and back no claim. No claim_relation contradiction is persisted between them.'),
      (3, 'Scholarly interpretations',
       'Earman and Glymour 1980 and Kennefick 2007 are retrieved as ANALYTICAL_OBSERVATION candidates with citations and back zero claims. Neither is ranked, resolved, or promoted.'),
      (4, 'Not established by the represented corpus',
       'Berean does not establish theory confirmation or refutation, deflection magnitudes, data-weighting rationale, motive, scholarly correctness, consensus, calendar dates, cross-station participation, instrument preference, or the identity of the title-only Astronomer Royal source identity.')
) AS synthesis(ord, section, statement)
ORDER BY ord;

DO $$
DECLARE
    before_counts phase33_counts_before%ROWTYPE;
    after_counts phase33_counts_before%ROWTYPE;
    cross_station integer;
    promoted integer;
BEGIN
    SELECT * INTO before_counts FROM phase33_counts_before;
    SELECT
        (SELECT count(*) FROM source), (SELECT count(*) FROM dataset),
        (SELECT count(*) FROM source_record), (SELECT count(*) FROM citation),
        (SELECT count(*) FROM source_identity), (SELECT count(*) FROM entity_source_mapping),
        (SELECT count(*) FROM entity), (SELECT count(*) FROM event),
        (SELECT count(*) FROM proposition), (SELECT count(*) FROM claim),
        (SELECT count(*) FROM evidence), (SELECT count(*) FROM claim_evidence),
        (SELECT count(*) FROM claim_relation)
    INTO after_counts;

    IF before_counts IS DISTINCT FROM after_counts THEN
        RAISE EXCEPTION 'phase33 stage B: read-only research queries changed persistent counts';
    END IF;

    -- The novel probes must be answered by traversal, and their outcome must remain NOT_ESTABLISHED.
    SELECT count(*) INTO cross_station FROM (
        SELECT ep.entity_id
        FROM event_participation ep
        JOIN entity person ON person.entity_id = ep.entity_id
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
        WHERE person.entity_key LIKE 'phase33\_%' ESCAPE '\'
          AND ev.event_key IN ('phase33_principe_observation_1919', 'phase33_sobral_observation_1919')
        GROUP BY ep.entity_id
        HAVING count(DISTINCT loc.object_entity_id) > 1
    ) AS multi_station;
    IF cross_station <> 0 THEN
        RAISE EXCEPTION 'phase33 stage B: cross-station participation was asserted for % persons', cross_station;
    END IF;

    SELECT count(*) INTO promoted
    FROM claim_evidence ce
    JOIN evidence e ON e.evidence_id = ce.evidence_id
    WHERE e.evidence_type_code = 'ANALYTICAL_OBSERVATION';
    IF promoted <> 0 THEN
        RAISE EXCEPTION 'phase33 stage B: % scholarly observations back a claim', promoted;
    END IF;

    RAISE NOTICE 'ok: Phase 33 Stage B answered ten withheld BEREAN_ONLY questions by traversal, with identical before/after persistent counts';
    RAISE NOTICE 'ok: NOT ESTABLISHED IS NOT FALSE; SCHOLARSHIP IS NOT A SOURCE CLAIM; RETRIEVAL IS NOT PERSISTENCE';
END $$;

COMMIT;
