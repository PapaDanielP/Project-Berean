\set ON_ERROR_STOP on

DROP TABLE IF EXISTS phase37b_counts_before;
CREATE TEMP TABLE phase37b_counts_before AS
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

\echo 'Withheld prompt: Tell me about the people and electrical technologies represented at the 1893 World''s Columbian Exposition, and explain the relationships Berean can establish between them.'

\echo 'ESTABLISHED: represented people, organizations, exhibits, technologies, participation, and locations.'
SELECT c.claim_key, r.rendered_proposition, s.source_key, 'ESTABLISHED' AS classification
FROM claim c
JOIN claim_rendering r ON r.claim_id = c.claim_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
ORDER BY c.claim_key, s.source_key;

\echo 'DERIVED: person -> exhibit -> technology, using shared claim-asserted event participation.'
SELECT person.canonical_name AS person, exhibit.event_key AS exhibit,
       technology.canonical_name AS technology, 'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation pp
JOIN entity person ON person.entity_id = pp.entity_id AND person.entity_type_code = 'PERSON'
JOIN event exhibit ON exhibit.event_id = pp.event_id
JOIN event_participation tp ON tp.event_id = exhibit.event_id
JOIN entity technology ON technology.entity_id = tp.entity_id
    AND technology.entity_type_code IN ('OBJECT', 'CONCEPT')
WHERE person.entity_key LIKE 'phase37r\_%' ESCAPE '\'
ORDER BY person.canonical_name, exhibit.event_key, technology.canonical_name;

\echo 'DERIVED: person -> organization -> exhibit means co-participation only, not employment or membership.'
SELECT person.canonical_name AS person, organization.canonical_name AS organization,
       exhibit.event_key AS shared_exhibit, 'DERIVED_CO_PARTICIPATION_ONLY' AS classification
FROM event_participation pp
JOIN entity person ON person.entity_id = pp.entity_id AND person.entity_type_code = 'PERSON'
JOIN event_participation op ON op.event_id = pp.event_id
JOIN entity organization ON organization.entity_id = op.entity_id
    AND organization.entity_type_code = 'ORGANIZATION'
JOIN event exhibit ON exhibit.event_id = pp.event_id
WHERE person.entity_key LIKE 'phase37r\_%' ESCAPE '\'
ORDER BY person.canonical_name, organization.canonical_name;

\echo 'DERIVED: person -> event -> location.'
SELECT person.canonical_name AS person, exhibit.event_key AS exhibit, place.canonical_name AS location,
       'DERIVED_FROM_STORED_GRAPH' AS classification
FROM event_participation pp
JOIN entity person ON person.entity_id = pp.entity_id AND person.entity_type_code = 'PERSON'
JOIN event exhibit ON exhibit.event_id = pp.event_id
JOIN proposition location ON location.subject_event_id = exhibit.event_id AND location.predicate = 'occursAt'
JOIN entity place ON place.entity_id = location.object_entity_id
WHERE person.entity_key LIKE 'phase37r\_%' ESCAPE '\'
ORDER BY person.canonical_name, exhibit.event_key;

\echo 'DERIVED: claims supported by multiple source traditions.'
SELECT c.claim_key, count(DISTINCT s.source_id) AS source_count,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS sources,
       'MULTI_SOURCE_ESTABLISHED' AS classification
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
GROUP BY c.claim_key
HAVING count(DISTINCT s.source_id) > 1
ORDER BY c.claim_key;

\echo 'SCHOLARLY: interpretations remain cited analytical observations, not direct claims.'
SELECT s.source_key, e.observation, 'SCHOLARLY_INTERPRETATION' AS classification
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE e.evidence_key IN ('EV_P37R_BADGER_INTERPRETATION', 'EV_P37R_RYDELL_INTERPRETATION')
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
ORDER BY s.source_key;

\echo 'UNRESOLVED: source identities that cannot yet be reconciled.'
SELECT si.source_identity_key, si.display_name, 'UNRESOLVED' AS classification
FROM source_identity si
LEFT JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
WHERE si.source_identity_key LIKE 'phase37r-%' AND esm.source_identity_id IS NULL
ORDER BY si.source_identity_key;

\echo 'NOT REPRESENTED: victory, superiority, causal conclusions, and person-to-organization membership.'
SELECT category, reason, 'NOT_REPRESENTED' AS classification
FROM (VALUES
    ('AC/DC winner', 'No represented proposition ranks a winner in an AC/DC conflict.'),
    ('technological superiority', 'Presence in an exhibit does not establish superiority.'),
    ('historical causation', 'No represented proposition establishes that an exhibit caused later adoption.'),
    ('person-to-organization membership', 'Shared exhibit participation is not employment or membership.')
) AS boundary(category, reason)
ORDER BY category;

DO $$
DECLARE
    actual integer;
    before_counts phase37b_counts_before%ROWTYPE;
    after_counts phase37b_counts_before%ROWTYPE;
BEGIN
    SELECT count(*) INTO actual
    FROM event_participation pp
    JOIN entity person ON person.entity_id = pp.entity_id AND person.entity_type_code = 'PERSON'
    JOIN event_participation tp ON tp.event_id = pp.event_id
    JOIN entity technology ON technology.entity_id = tp.entity_id
        AND technology.entity_type_code IN ('OBJECT', 'CONCEPT')
    WHERE person.entity_key LIKE 'phase37r\_%' ESCAPE '\';
    IF actual <> 3 THEN RAISE EXCEPTION 'phase37b: expected 3 person-exhibit-technology paths, found %', actual; END IF;

    SELECT count(*) INTO actual
    FROM event_participation pp
    JOIN entity person ON person.entity_id = pp.entity_id AND person.entity_type_code = 'PERSON'
    JOIN event_participation op ON op.event_id = pp.event_id
    JOIN entity organization ON organization.entity_id = op.entity_id
        AND organization.entity_type_code = 'ORGANIZATION'
    WHERE person.entity_key LIKE 'phase37r\_%' ESCAPE '\';
    IF actual <> 1 THEN RAISE EXCEPTION 'phase37b: expected 1 person-organization-exhibit co-participation path, found %', actual; END IF;

    SELECT count(*) INTO actual
    FROM (
        SELECT c.claim_id
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
        GROUP BY c.claim_id
        HAVING count(DISTINCT s.source_id) > 1
    ) multi_source;
    IF actual <> 7 THEN RAISE EXCEPTION 'phase37b: expected 7 multi-source claims, found %', actual; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
          AND c.claim_type_code = 'DERIVED_CLAIM'
    ) THEN RAISE EXCEPTION 'phase37b: withheld derivation was precomputed in Stage A'; END IF;

    SELECT * INTO before_counts FROM phase37b_counts_before;
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
        RAISE EXCEPTION 'phase37b: read-only suite changed persistent counts';
    END IF;

    RAISE NOTICE 'ok: Phase 37B withheld suite distinguishes ESTABLISHED, DERIVED, SCHOLARLY, UNRESOLVED, and NOT_REPRESENTED results with unchanged persistent counts.';
END $$;

COMMIT;
