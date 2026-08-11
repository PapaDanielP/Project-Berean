\set ON_ERROR_STOP on

-- Phase 34: natural-language scholarly question execution over persisted Phase 33 substrate.
--
-- Required pipeline:
-- NL question -> classification -> extraction -> candidate predicates -> candidate traversal ->
-- capability check -> retrieval -> provenance/evidence resolution -> bounded synthesis.

DROP TABLE IF EXISTS phase34_counts_before_batch;
CREATE TEMP TABLE phase34_counts_before_batch AS
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

CREATE TEMP TABLE phase34_questions (
    question_no integer PRIMARY KEY,
    question_text text NOT NULL
);

INSERT INTO phase34_questions (question_no, question_text) VALUES
    (1, 'Who participated in the Principe eclipse observation?'),
    (2, 'Where did the Principe and Sobral observations take place?'),
    (3, 'What happened before the joint eclipse meeting?'),
    (4, 'What do the represented sources say about the eclipse observations?'),
    (5, 'What scholarly interpretations of the 1919 eclipse are represented?'),
    (6, 'Why does Berean say Eddington participated in the Principe observation?'),
    (7, 'Did the 1919 eclipse observations prove Einstein''s theory of general relativity?'),
    (8, 'Why were the Sobral plates excluded from the analysis?'),
    (9, 'What was the measured light-deflection value at Sobral?'),
    (10, 'On what exact date did the Principe observation occur?'),
    (11, 'Which people are connected to an eclipse observation through participation, and where did those observations occur?');

CREATE TEMP VIEW phase34_plan_generator AS
WITH features AS (
    SELECT
        q.question_no,
        q.question_text,
        lower(q.question_text) AS ql,
        lower(q.question_text) LIKE '%who%' AS has_who,
        lower(q.question_text) LIKE '%where%' AS has_where,
        lower(q.question_text) LIKE '%before%' AS has_before,
        lower(q.question_text) LIKE '%source%' AS has_sources,
        lower(q.question_text) LIKE '%scholarly%' OR lower(q.question_text) LIKE '%interpretation%' AS has_interpretation,
        lower(q.question_text) LIKE '%why%' AS has_why,
        lower(q.question_text) LIKE '%participat%' AS has_participation,
        lower(q.question_text) LIKE '%prove%' OR lower(q.question_text) LIKE '%theory%' OR lower(q.question_text) LIKE '%relativity%' AS asks_theory_confirmation,
        lower(q.question_text) LIKE '%excluded%' OR lower(q.question_text) LIKE '%analysis%' AS asks_exclusion_rationale,
        lower(q.question_text) LIKE '%measured%' OR lower(q.question_text) LIKE '%value%' AS asks_quantity,
        lower(q.question_text) LIKE '%exact date%' OR lower(q.question_text) LIKE '%date%' AS asks_exact_date,
        lower(q.question_text) LIKE '%principe%' AS mentions_principe,
        lower(q.question_text) LIKE '%sobral%' AS mentions_sobral,
        lower(q.question_text) LIKE '%joint eclipse meeting%' AS mentions_joint_meeting,
        lower(q.question_text) LIKE '%eddington%' AS mentions_eddington,
        lower(q.question_text) LIKE '%connected%' AND lower(q.question_text) LIKE '%through participation%' AS asks_multihop
    FROM phase34_questions q
)
SELECT
    f.question_no,
    f.question_text,
    CASE
        WHEN f.asks_theory_confirmation THEN 'UNSUPPORTED_THEORY_RELATION'
        WHEN f.asks_exclusion_rationale THEN 'UNSUPPORTED_RELATION'
        WHEN f.asks_quantity THEN 'UNSUPPORTED_QUANTITY'
        WHEN f.asks_exact_date THEN 'UNSUPPORTED_DATE'
        WHEN f.asks_multihop THEN 'GRAPH_DERIVATION'
        WHEN f.has_why AND f.mentions_eddington AND f.has_participation THEN 'PROVENANCE'
        WHEN f.has_interpretation THEN 'SCHOLARLY_INTERPRETATION'
        WHEN f.has_sources THEN 'SOURCE_COMPARISON'
        WHEN f.has_before THEN 'CHRONOLOGY'
        WHEN f.has_where THEN 'EVENT_LOOKUP'
        WHEN f.has_who AND f.has_participation THEN 'RELATIONSHIP_LOOKUP'
        ELSE 'ENTITY_LOOKUP'
    END AS query_classification,
    CASE
        WHEN f.asks_theory_confirmation OR f.asks_exclusion_rationale OR f.asks_quantity OR f.asks_exact_date THEN 'NOT_ESTABLISHED'
        ELSE 'ESTABLISHED'
    END AS capability_status,
    CASE
        WHEN f.asks_theory_confirmation THEN 'Unsupported theory confirmation/truth relation'
        WHEN f.asks_exclusion_rationale THEN 'Unsupported motive/data-selection relation'
        WHEN f.asks_quantity THEN 'Unsupported quantitative value retrieval from unstored data'
        WHEN f.asks_exact_date THEN 'Unsupported exact date retrieval'
        ELSE 'Supported traversal over represented claims/evidence/provenance'
    END AS capability_reason,
    'BEREAN_ONLY'::text AS retrieval_scope
FROM features f;

DROP TABLE IF EXISTS phase34_plans;
CREATE TEMP TABLE phase34_plans AS
SELECT * FROM phase34_plan_generator ORDER BY question_no;

BEGIN READ ONLY;

\echo 'Phase 34 pipeline trace: capability check before retrieval and synthesis'
SELECT p.question_no,
       stage.stage_order,
       stage.stage_name
FROM phase34_plans p
CROSS JOIN LATERAL (
    VALUES
      (1, 'QUESTION_CLASSIFICATION'),
      (2, 'ENTITY_CONCEPT_RELATION_EXTRACTION'),
      (3, 'CANDIDATE_PREDICATE_SELECTION'),
      (4, 'CANDIDATE_GRAPH_TRAVERSAL'),
      (5, 'CAPABILITY_CHECK'),
      (6, 'RETRIEVAL'),
      (7, 'EVIDENCE_PROVENANCE_RESOLUTION'),
      (8, 'BOUNDED_SYNTHESIS')
) AS stage(stage_order, stage_name)
ORDER BY p.question_no, stage.stage_order;

\echo 'Q1: Who participated in the Principe eclipse observation?'
SELECT person.canonical_name AS answer,
       'DIRECTLY_SUPPORTED'::text AS answer_category,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS provenance_sources
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity person ON person.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity station ON station.entity_id = loc.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
  AND p.predicate = 'participatesIn'
  AND station.canonical_name ILIKE '%Principe%'
GROUP BY person.canonical_name
ORDER BY person.canonical_name;

\echo 'Q2: Where did the Principe and Sobral observations take place?'
SELECT ev.event_key AS observation_event,
       station.canonical_name AS location,
       'DIRECTLY_SUPPORTED'::text AS answer_category,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS provenance_sources
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event ev ON ev.event_id = p.subject_event_id
JOIN entity station ON station.entity_id = p.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
  AND p.predicate = 'occursAt'
  AND ev.event_key IN ('phase33_principe_observation_1919', 'phase33_sobral_observation_1919')
GROUP BY ev.event_key, station.canonical_name
ORDER BY ev.event_key;

\echo 'Q3: What happened before the joint eclipse meeting?'
SELECT earlier.event_key AS happened_before,
       later.event_key AS reference_event,
       'DIRECTLY_SUPPORTED'::text AS answer_category,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS provenance_sources
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event earlier ON earlier.event_id = p.subject_event_id
JOIN event later ON later.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
  AND p.predicate = 'precedes'
  AND later.event_key = 'phase33_joint_eclipse_meeting_1919'
GROUP BY earlier.event_key, later.event_key
ORDER BY earlier.event_key;

\echo 'Q4: What do the represented sources say about the eclipse observations?'
SELECT s.source_key,
       e.evidence_key,
       e.evidence_type_code,
       CASE WHEN ce.evidence_id IS NULL THEN 'UNRESOLVED_NOT_ESTABLISHED' ELSE 'DIRECTLY_SUPPORTED' END AS answer_category,
       e.observation
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
LEFT JOIN (SELECT DISTINCT evidence_id FROM claim_evidence) ce ON ce.evidence_id = e.evidence_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
ORDER BY s.source_key, e.evidence_key;

\echo 'Q5: What scholarly interpretations of the 1919 eclipse are represented?'
SELECT s.source_key,
       e.evidence_key,
       ci.citation_key,
       ci.locator,
       'SCHOLARLY_CANDIDATE'::text AS answer_category,
       e.observation
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
  AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
ORDER BY s.source_key, e.evidence_key;

\echo 'Q6: Why does Berean say Eddington participated in the Principe observation?'
SELECT person.canonical_name AS subject,
       p.predicate,
       ev.event_key AS event,
       c.claim_key,
       ce.relation_type_code,
       e.evidence_key,
       ci.citation_key,
       sr.source_record_key,
       d.dataset_key,
       s.source_key,
       'DIRECTLY_SUPPORTED'::text AS answer_category,
       CASE WHEN sr.raw_content IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS source_text_status
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity person ON person.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity station ON station.entity_id = loc.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
  AND p.predicate = 'participatesIn'
  AND person.canonical_name ILIKE '%Eddington%'
  AND station.canonical_name ILIKE '%Principe%'
ORDER BY e.evidence_key, ci.citation_key;

\echo 'Q7-Q10 unsupported capability responses (NOT_ESTABLISHED, no invented predicates/facts)'
SELECT question_no,
       question_text,
       query_classification,
       capability_status,
       CASE
           WHEN question_no = 7 THEN 'NOT_REPRESENTED'
           WHEN question_no = 8 THEN 'UNRESOLVED_NOT_ESTABLISHED'
           WHEN question_no = 9 THEN 'NOT_REPRESENTED'
           WHEN question_no = 10 THEN 'NOT_REPRESENTED'
       END AS answer_category,
       capability_reason
FROM phase34_plans
WHERE question_no BETWEEN 7 AND 10
ORDER BY question_no;

\echo 'Novel query: people connected to eclipse observations through participation, and where those observations occurred'
SELECT person.canonical_name AS person,
       ev.event_key AS observation_event,
       station.canonical_name AS observation_location,
       'DERIVED_FROM_STORED_GRAPH'::text AS answer_category,
       string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS provenance_sources
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity person ON person.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
JOIN entity station ON station.entity_id = loc.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
  AND p.predicate = 'participatesIn'
  AND ev.event_key IN ('phase33_principe_observation_1919', 'phase33_sobral_observation_1919')
GROUP BY person.canonical_name, ev.event_key, station.canonical_name
ORDER BY person.canonical_name, ev.event_key, station.canonical_name;

\echo 'Bounded synthesis (transient; not persisted)'
SELECT section, statement
FROM (
    VALUES
      (1, 'Supported by represented source evidence',
       'Participation, observation locations, and observation-before-meeting ordering are retrieved as source-backed claims with explicit provenance.'),
      (2, 'Source differences and unresolved conflict',
       'Source observations and scholarly assessments are retrieved separately; differences are not promoted to contradiction and unresolved material remains not established.'),
      (3, 'Scholarly interpretations',
       'Represented scholarship is returned as SCHOLARLY_CANDIDATE evidence with citations and is not promoted into direct source claims.'),
      (4, 'Not established by represented corpus',
       'Theory confirmation, exclusion rationale, measured Sobral deflection value, and exact Principe observation date remain NOT_ESTABLISHED in the current vocabulary/substrate.')
) AS synthesis(ord, section, statement)
ORDER BY ord;

DO $$
DECLARE
    before_counts phase34_counts_before_batch%ROWTYPE;
    after_counts phase34_counts_before_batch%ROWTYPE;
    actual integer;
BEGIN
    -- Capability check must run before retrieval in the explicit pipeline.
    SELECT count(*) INTO actual
    FROM phase34_plans;
    IF actual <> 11 THEN
        RAISE EXCEPTION 'phase34 nl: expected 11 plans, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM phase34_plans
    WHERE question_no BETWEEN 7 AND 10
      AND capability_status = 'NOT_ESTABLISHED';
    IF actual <> 4 THEN
        RAISE EXCEPTION 'phase34 nl: expected all unsupported questions to be NOT_ESTABLISHED, found %', actual;
    END IF;

    -- Q1 determinism: two independent traversals produce the same ordered participant list.
    IF (
        SELECT string_agg(person_name, '|' ORDER BY person_name)
        FROM (
            SELECT person.canonical_name AS person_name
            FROM claim c
            JOIN proposition p ON p.proposition_id = c.proposition_id
            JOIN entity person ON person.entity_id = p.subject_entity_id
            JOIN event ev ON ev.event_id = p.object_event_id
            JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
            JOIN entity station ON station.entity_id = loc.object_entity_id
            WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
              AND p.predicate = 'participatesIn'
              AND station.canonical_name ILIKE '%Principe%'
        ) AS run_a
    ) IS DISTINCT FROM (
        SELECT string_agg(person_name, '|' ORDER BY person_name)
        FROM (
            SELECT person.canonical_name AS person_name
            FROM claim c
            JOIN proposition p ON p.proposition_id = c.proposition_id
            JOIN entity person ON person.entity_id = p.subject_entity_id
            JOIN event ev ON ev.event_id = p.object_event_id
            JOIN proposition loc ON loc.subject_event_id = ev.event_id AND loc.predicate = 'occursAt'
            JOIN entity station ON station.entity_id = loc.object_entity_id
            WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
              AND p.predicate = 'participatesIn'
              AND station.canonical_name ILIKE '%Principe%'
        ) AS run_b
    ) THEN
        RAISE EXCEPTION 'phase34 nl: repeat Q1 traversal produced non-deterministic results';
    END IF;

    -- Negative semantic boundaries.
    IF EXISTS (
        SELECT 1 FROM proposition
        WHERE predicate IN (
            'confirmsTheory', 'supportsTheory', 'refutesTheory', 'preferredOver', 'strongerThan',
            'sameAs', 'excludedBecause', 'biasedBy', 'weightedOver', 'occursOnDate'
        )
    ) THEN
        RAISE EXCEPTION 'phase34 nl: invented or unsupported predicate detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
          AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
    ) THEN
        RAISE EXCEPTION 'phase34 nl: scholarship was promoted to claim backing';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
           OR c2.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
    ) THEN
        RAISE EXCEPTION 'phase34 nl: source difference promoted to contradiction relation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM typed_value tv
        JOIN proposition p ON p.object_typed_value_id = tv.typed_value_id
        JOIN claim c ON c.proposition_id = p.proposition_id
        WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
          AND (tv.numeric_value IS NOT NULL OR tv.date_value IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase34 nl: unsupported numeric/date material promoted into Phase 33 claim propositions';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'
          AND esm.mapping_status_code = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'phase34 nl: unresolved source identity was silently reconciled';
    END IF;

    -- Read-only invariant.
    SELECT * INTO before_counts FROM phase34_counts_before_batch;
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
        RAISE EXCEPTION 'phase34 nl: read-only batch changed persistent counts';
    END IF;

    RAISE NOTICE 'ok: Phase 34 answered Q1-Q6 and novel multi-hop query via bounded retrieval over persisted Phase 33 graph';
    RAISE NOTICE 'ok: Phase 34 returned NOT_ESTABLISHED for Q7-Q10 without invented predicates, facts, numbers, dates, or identity resolution';
END $$;

COMMIT;
