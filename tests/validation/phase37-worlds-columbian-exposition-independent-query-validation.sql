\set ON_ERROR_STOP on

-- Phase 37 Stage B: independent research queries over the 1893 World's Columbian Exposition
-- domain populated by tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql.
--
-- These ten questions were withheld from the Stage A population fixture, the Stage A validation,
-- and the candidate worksheet in data/candidates/phase37-worlds-columbian-exposition-candidates.csv.
-- Nothing below is looked up in an answer table: every result is produced by traversing the
-- persisted Berean substrate (Source -> Dataset -> SourceRecord -> Citation -> Evidence ->
-- ClaimEvidence -> Claim -> Proposition -> Entity/Event) with ordinary read-only SQL. Retrieval
-- scope is BEREAN_ONLY; no external corpus is consulted.
--
-- Q1, Q2, Q3, Q4, Q5, Q9, and Q10 are anti-contamination probes: no Stage A row states a multi-event
-- person, a shared venue between two named events, a person-pair, a person/event/place chain, an
-- ordered-plus-participant view, a multi-source-tradition person, or a same-venue different-event
-- pair. Each is derived solely by traversing persisted rows and is itself DERIVED_FROM_STORED_GRAPH,
-- not a stored proposition or claim.

DROP TABLE IF EXISTS phase37_counts_before;
CREATE TEMP TABLE phase37_counts_before AS
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

\echo 'Q1 (run 1): Which represented people participate in more than one represented event?'
SELECT person.canonical_name,
       count(DISTINCT ev.event_id) AS distinct_events,
       string_agg(DISTINCT ev.event_key, ', ' ORDER BY ev.event_key) AS events,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep
JOIN entity person ON person.entity_id = ep.entity_id
JOIN event ev ON ev.event_id = ep.event_id
WHERE person.entity_key LIKE 'phase37\_%' ESCAPE '\'
  AND person.entity_type_code = 'PERSON'
GROUP BY person.canonical_name
HAVING count(DISTINCT ev.event_id) > 1
ORDER BY person.canonical_name;

\echo 'Q1 (run 2, repeated to prove identical output): same query.'
SELECT person.canonical_name,
       count(DISTINCT ev.event_id) AS distinct_events,
       string_agg(DISTINCT ev.event_key, ', ' ORDER BY ev.event_key) AS events,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep
JOIN entity person ON person.entity_id = ep.entity_id
JOIN event ev ON ev.event_id = ep.event_id
WHERE person.entity_key LIKE 'phase37\_%' ESCAPE '\'
  AND person.entity_type_code = 'PERSON'
GROUP BY person.canonical_name
HAVING count(DISTINCT ev.event_id) > 1
ORDER BY person.canonical_name;

\echo 'Q2 (run 1): Which represented events share a venue (Event -> occursAt -> Place)?'
SELECT a.event_key AS event_a, b.event_key AS event_b, place.canonical_name AS shared_place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM proposition pa
JOIN event a ON a.event_id = pa.subject_event_id
JOIN entity place ON place.entity_id = pa.object_entity_id
JOIN proposition pb ON pb.predicate = 'occursAt' AND pb.object_entity_id = place.entity_id
JOIN event b ON b.event_id = pb.subject_event_id
WHERE pa.predicate = 'occursAt'
  AND a.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND b.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND a.event_id < b.event_id
ORDER BY a.event_key, b.event_key;

\echo 'Q2 (run 2, repeated to prove identical output): same query.'
SELECT a.event_key AS event_a, b.event_key AS event_b, place.canonical_name AS shared_place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM proposition pa
JOIN event a ON a.event_id = pa.subject_event_id
JOIN entity place ON place.entity_id = pa.object_entity_id
JOIN proposition pb ON pb.predicate = 'occursAt' AND pb.object_entity_id = place.entity_id
JOIN event b ON b.event_id = pb.subject_event_id
WHERE pa.predicate = 'occursAt'
  AND a.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND b.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND a.event_id < b.event_id
ORDER BY a.event_key, b.event_key;

\echo 'Q3 (run 1): Which pairs of people are connected through a common represented event, via a two-sided participation join? Berean stores no knows/associatedWith predicate; this is a derived pairing only.'
SELECT p1.canonical_name AS person_a, p2.canonical_name AS person_b, ev.event_key AS common_event,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep1
JOIN event_participation ep2 ON ep2.event_id = ep1.event_id AND ep2.entity_id > ep1.entity_id
JOIN entity p1 ON p1.entity_id = ep1.entity_id
JOIN entity p2 ON p2.entity_id = ep2.entity_id
JOIN event ev ON ev.event_id = ep1.event_id
WHERE p1.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p1.entity_type_code = 'PERSON'
  AND p2.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p2.entity_type_code = 'PERSON'
ORDER BY ev.event_key, p1.canonical_name, p2.canonical_name;

\echo 'Q3 (run 2, repeated to prove identical output): same query.'
SELECT p1.canonical_name AS person_a, p2.canonical_name AS person_b, ev.event_key AS common_event,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep1
JOIN event_participation ep2 ON ep2.event_id = ep1.event_id AND ep2.entity_id > ep1.entity_id
JOIN entity p1 ON p1.entity_id = ep1.entity_id
JOIN entity p2 ON p2.entity_id = ep2.entity_id
JOIN event ev ON ev.event_id = ep1.event_id
WHERE p1.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p1.entity_type_code = 'PERSON'
  AND p2.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p2.entity_type_code = 'PERSON'
ORDER BY ev.event_key, p1.canonical_name, p2.canonical_name;

\echo 'Q4 (run 1): For each represented person, which event do they participate in and where does that event occur (Person -> participatesIn -> Event -> occursAt -> Place)?'
SELECT person.canonical_name, ev.event_key, place.canonical_name AS place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep
JOIN entity person ON person.entity_id = ep.entity_id
JOIN event ev ON ev.event_id = ep.event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity place ON place.entity_id = loc.object_entity_id
WHERE person.entity_key LIKE 'phase37\_%' ESCAPE '\' AND person.entity_type_code = 'PERSON'
ORDER BY person.canonical_name, ev.event_key;

\echo 'Q4 (run 2, repeated to prove identical output): same query.'
SELECT person.canonical_name, ev.event_key, place.canonical_name AS place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation ep
JOIN entity person ON person.entity_id = ep.entity_id
JOIN event ev ON ev.event_id = ep.event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity place ON place.entity_id = loc.object_entity_id
WHERE person.entity_key LIKE 'phase37\_%' ESCAPE '\' AND person.entity_type_code = 'PERSON'
ORDER BY person.canonical_name, ev.event_key;

\echo 'Q5 (run 1): What established event ordering exists, and who participated in each ordered event? Uses only precedes and participation; no exact calendar date is invented.'
SELECT earlier.event_key AS earlier_event,
       later.event_key AS later_event,
       string_agg(DISTINCT ep_earlier.canonical_name, ', ' ORDER BY ep_earlier.canonical_name) AS earlier_participants,
       string_agg(DISTINCT ep_later.canonical_name, ', ' ORDER BY ep_later.canonical_name) AS later_participants,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM proposition p
JOIN event earlier ON earlier.event_id = p.subject_event_id
JOIN event later ON later.event_id = p.object_event_id
LEFT JOIN event_participation eparl ON eparl.event_id = earlier.event_id
LEFT JOIN entity ep_earlier ON ep_earlier.entity_id = eparl.entity_id
LEFT JOIN event_participation epalr ON epalr.event_id = later.event_id
LEFT JOIN entity ep_later ON ep_later.entity_id = epalr.entity_id
WHERE p.predicate = 'precedes'
  AND earlier.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND later.event_key LIKE 'phase37\_%' ESCAPE '\'
GROUP BY earlier.event_key, later.event_key
ORDER BY earlier.event_key, later.event_key;

\echo 'Q5 (run 2, repeated to prove identical output): same query.'
SELECT earlier.event_key AS earlier_event,
       later.event_key AS later_event,
       string_agg(DISTINCT ep_earlier.canonical_name, ', ' ORDER BY ep_earlier.canonical_name) AS earlier_participants,
       string_agg(DISTINCT ep_later.canonical_name, ', ' ORDER BY ep_later.canonical_name) AS later_participants,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM proposition p
JOIN event earlier ON earlier.event_id = p.subject_event_id
JOIN event later ON later.event_id = p.object_event_id
LEFT JOIN event_participation eparl ON eparl.event_id = earlier.event_id
LEFT JOIN entity ep_earlier ON ep_earlier.entity_id = eparl.entity_id
LEFT JOIN event_participation epalr ON epalr.event_id = later.event_id
LEFT JOIN entity ep_later ON ep_later.entity_id = epalr.entity_id
WHERE p.predicate = 'precedes'
  AND earlier.event_key LIKE 'phase37\_%' ESCAPE '\'
  AND later.event_key LIKE 'phase37\_%' ESCAPE '\'
GROUP BY earlier.event_key, later.event_key
ORDER BY earlier.event_key, later.event_key;

\echo 'Q6: Which represented claims are supported by more than one independent source through full provenance joins?'
SELECT c.claim_key,
       r.rendered_proposition,
       count(DISTINCT s.source_id) AS distinct_supporting_sources,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS sources,
       'DIRECTLY_SUPPORTED' AS classification
FROM claim c
JOIN claim_rendering r ON r.claim_id = c.claim_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\'
GROUP BY c.claim_key, r.rendered_proposition
HAVING count(DISTINCT s.source_id) > 1
ORDER BY c.claim_key;

\echo 'Q7: Which represented source observations carry relevant information but back no claim_evidence link?'
SELECT s.source_key, e.evidence_key, e.evidence_type_code, e.observation,
       'SCHOLARLY_CANDIDATE_NOT_PROMOTED' AS classification
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE e.evidence_key LIKE 'EV\_P37\_%' ESCAPE '\'
  AND ce.evidence_id IS NULL
ORDER BY s.source_key, e.evidence_key;

\echo 'Q8: Which represented source identities remain unresolved, and what canonical mapping has been proposed?'
SELECT s.source_key,
       si.source_identity_key,
       si.display_name,
       esm.mapping_status_code,
       ent.canonical_name AS proposed_entity,
       esm.justification,
       'UNRESOLVED' AS classification
FROM source_identity si
JOIN source s ON s.source_id = si.source_id
LEFT JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
LEFT JOIN entity ent ON ent.entity_id = esm.entity_id
WHERE si.source_identity_key LIKE 'phase37-%'
  AND (esm.mapping_status_code IS NULL OR esm.mapping_status_code <> 'ACTIVE')
ORDER BY s.source_key, si.source_identity_key;

\echo 'Q9 (run 1): Which represented people have source-backed participation established through more than one source tradition, using only active/established mappings?'
SELECT person.canonical_name,
       count(DISTINCT s.source_id) AS distinct_source_traditions,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS sources,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id AND p.predicate = 'participatesIn'
JOIN entity person ON person.entity_id = p.subject_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\'
  AND person.entity_key LIKE 'phase37\_%' ESCAPE '\'
GROUP BY person.canonical_name
HAVING count(DISTINCT s.source_id) > 1
ORDER BY person.canonical_name;

\echo 'Q9 (run 2, repeated to prove identical output): same query.'
SELECT person.canonical_name,
       count(DISTINCT s.source_id) AS distinct_source_traditions,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS sources,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id AND p.predicate = 'participatesIn'
JOIN entity person ON person.entity_id = p.subject_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\'
  AND person.entity_key LIKE 'phase37\_%' ESCAPE '\'
GROUP BY person.canonical_name
HAVING count(DISTINCT s.source_id) > 1
ORDER BY person.canonical_name;

\echo 'Q10 (run 1): Which represented people participate in different events (Event A <> Event B) that share the same represented place?'
SELECT p1.canonical_name AS person_a, ea.event_key AS event_a,
       p2.canonical_name AS person_b, eb.event_key AS event_b,
       place.canonical_name AS shared_place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation epa
JOIN entity p1 ON p1.entity_id = epa.entity_id
JOIN event ea ON ea.event_id = epa.event_id
JOIN proposition loca ON loca.subject_event_id = ea.event_id AND loca.predicate = 'occursAt'
JOIN entity place ON place.entity_id = loca.object_entity_id
JOIN proposition locb ON locb.predicate = 'occursAt' AND locb.object_entity_id = place.entity_id
JOIN event eb ON eb.event_id = locb.subject_event_id
JOIN event_participation epb ON epb.event_id = eb.event_id
JOIN entity p2 ON p2.entity_id = epb.entity_id
WHERE p1.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p1.entity_type_code = 'PERSON'
  AND p2.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p2.entity_type_code = 'PERSON'
  AND ea.event_id <> eb.event_id
  AND NOT (ea.event_id = eb.event_id AND p1.entity_id = p2.entity_id)
ORDER BY person_a, event_a, person_b, event_b;

\echo 'Q10 (run 2, repeated to prove identical output): same query.'
SELECT p1.canonical_name AS person_a, ea.event_key AS event_a,
       p2.canonical_name AS person_b, eb.event_key AS event_b,
       place.canonical_name AS shared_place,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation epa
JOIN entity p1 ON p1.entity_id = epa.entity_id
JOIN event ea ON ea.event_id = epa.event_id
JOIN proposition loca ON loca.subject_event_id = ea.event_id AND loca.predicate = 'occursAt'
JOIN entity place ON place.entity_id = loca.object_entity_id
JOIN proposition locb ON locb.predicate = 'occursAt' AND locb.object_entity_id = place.entity_id
JOIN event eb ON eb.event_id = locb.subject_event_id
JOIN event_participation epb ON epb.event_id = eb.event_id
JOIN entity p2 ON p2.entity_id = epb.entity_id
WHERE p1.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p1.entity_type_code = 'PERSON'
  AND p2.entity_key LIKE 'phase37\_%' ESCAPE '\' AND p2.entity_type_code = 'PERSON'
  AND ea.event_id <> eb.event_id
  AND NOT (ea.event_id = eb.event_id AND p1.entity_id = p2.entity_id)
ORDER BY person_a, event_a, person_b, event_b;

\echo 'Unsupported Q11: Does the represented corpus establish which scholar (Badger or Rydell) is correct about the exposition''s meaning?'
SELECT 'NOT_REPRESENTED' AS classification,
       'No registered predicate or capability adjudicates scholarly correctness; scholarly disagreement is retained as two isolated ANALYTICAL_OBSERVATION rows, never ranked, merged, or resolved.' AS reason;

\echo 'Unsupported Q12: What is the exact calendar date of Opening Day, and did the exposition confirm or refute a historical theory?'
SELECT 'NOT_REPRESENTED' AS classification,
       'Berean registers no general calendar-date predicate for this phase and no confirmsTheory/refutesTheory/supportsTheory predicate exists in the registry; the represented corpus only establishes precedes ordering.' AS reason;

\echo 'Bounded synthesis over the retrieved objects (derived from the traversals above, not persisted).'
SELECT section, statement
FROM (
    VALUES
      (1, 'Supported by represented source evidence',
       'Every Phase 37 claim retrieved above is a DIRECT_SOURCE_CLAIM whose provenance terminates in a registered source; Dedication Day and Opening Day venues, their participants, and their ordering are represented.'),
      (2, 'Derived from the stored graph, not separately persisted',
       'Cross-event participation (Q1), shared venue (Q2), person pairs (Q3), the person/event/place chain (Q4), ordering with participants (Q5), multi-source participation (Q9), and same-venue different-event pairs (Q10) are all produced solely by traversal; none of these relationships is itself stored as a proposition or claim.'),
      (3, 'Scholarly interpretations',
       'Badger 1979 and Rydell 1984 are retrieved as ANALYTICAL_OBSERVATION candidates with citations and back zero claims. Neither is ranked, resolved, or promoted.'),
      (4, 'Not established by the represented corpus',
       'Berean does not establish theory confirmation or refutation, scholarly correctness, consensus, exact calendar dates, or an active reconciliation for the Mrs. Potter Palmer honorific-only identity.')
) AS synthesis(ord, section, statement)
ORDER BY ord;

DO $$
DECLARE
    before_counts phase37_counts_before%ROWTYPE;
    after_counts phase37_counts_before%ROWTYPE;
    promoted integer;
BEGIN
    SELECT * INTO before_counts FROM phase37_counts_before;
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
        RAISE EXCEPTION 'phase37 stage B: read-only research queries changed persistent counts';
    END IF;

    SELECT count(*) INTO promoted
    FROM claim_evidence ce
    JOIN evidence e ON e.evidence_id = ce.evidence_id
    WHERE e.evidence_key LIKE 'EV\_P37\_%' ESCAPE '\'
      AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION';
    IF promoted <> 0 THEN
        RAISE EXCEPTION 'phase37 stage B: % scholarly observations back a claim', promoted;
    END IF;

    RAISE NOTICE 'ok: Phase 37 Stage B answered ten withheld BEREAN_ONLY questions plus two unsupported probes by traversal, with identical before/after persistent counts';
    RAISE NOTICE 'ok: DERIVED IS NOT STORED; NOT_REPRESENTED IS NOT FALSE; SCHOLARSHIP IS NOT A SOURCE CLAIM; RETRIEVAL IS NOT PERSISTENCE';
END $$;

COMMIT;
