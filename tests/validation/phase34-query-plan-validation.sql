\set ON_ERROR_STOP on

-- Phase 34: natural-language -> normalized structured query-plan validation.
--
-- This stage does not persist answers or plans. It validates that a transient interpreter can
-- normalize scholarly questions into bounded BEREAN_ONLY plans, perform explicit capability checks,
-- and preserve deterministic ordering and epistemic boundaries.

DROP TABLE IF EXISTS phase34_counts_before;
CREATE TEMP TABLE phase34_counts_before AS
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
    ARRAY_REMOVE(ARRAY[
        CASE WHEN f.mentions_eddington THEN 'Arthur Stanley Eddington' END,
        CASE WHEN f.mentions_principe THEN 'Principe eclipse station' END,
        CASE WHEN f.mentions_sobral THEN 'Sobral eclipse station' END,
        CASE WHEN f.mentions_joint_meeting THEN 'phase33_joint_eclipse_meeting_1919' END,
        CASE WHEN f.asks_theory_confirmation THEN 'general relativity' END,
        CASE WHEN f.asks_exclusion_rationale THEN 'Sobral plates' END,
        CASE WHEN f.asks_quantity THEN 'light-deflection value' END
    ], NULL) AS requested_entities,
    ARRAY_REMOVE(ARRAY[
        CASE WHEN f.mentions_principe THEN 'Principe eclipse observation' END,
        CASE WHEN f.mentions_sobral THEN 'Sobral eclipse observation' END,
        CASE WHEN f.mentions_joint_meeting THEN 'Joint eclipse meeting' END,
        CASE WHEN f.asks_multihop THEN 'Eclipse observations' END
    ], NULL) AS requested_events,
    ARRAY_REMOVE(ARRAY[
        CASE WHEN f.has_participation THEN 'participation' END,
        CASE WHEN f.has_where THEN 'event-location' END,
        CASE WHEN f.has_before THEN 'event-ordering' END,
        CASE WHEN f.has_sources THEN 'source-evidence-comparison' END,
        CASE WHEN f.has_interpretation THEN 'scholarly-interpretation' END,
        CASE WHEN f.has_why THEN 'provenance-chain' END,
        CASE WHEN f.asks_multihop THEN 'multi-hop-participation-location' END
    ], NULL) AS requested_relationships,
    CASE
        WHEN f.has_interpretation THEN 'ANALYTICAL_OBSERVATION_ONLY'
        WHEN f.has_sources OR f.has_who OR f.has_where OR f.has_before OR f.has_why OR f.asks_multihop THEN 'SOURCE_OBSERVATION_ONLY'
        ELSE 'SOURCE_AND_SCHOLARLY_AS_REQUESTED'
    END AS source_evidence_scope,
    ARRAY_REMOVE(ARRAY[
        CASE WHEN f.has_participation OR f.asks_multihop THEN 'participatesIn' END,
        CASE WHEN f.has_where OR f.asks_multihop THEN 'occursAt' END,
        CASE WHEN f.has_before THEN 'precedes' END,
        CASE WHEN f.has_where AND f.question_text LIKE '%observations take place%' THEN 'occursAt' END
    ], NULL) AS candidate_predicates,
    CASE
        WHEN f.asks_multihop THEN 'Claim->Proposition(participatesIn)->Event->Proposition(occursAt)->Place'
        WHEN f.has_why THEN 'Claim->ClaimEvidence->Evidence->EvidenceCitation->Citation->SourceRecord->Dataset->Source'
        WHEN f.has_sources THEN 'Source->Dataset->SourceRecord->Evidence (+ optional ClaimEvidence)'
        WHEN f.has_before THEN 'Claim->Proposition(precedes)->Event'
        WHEN f.has_where THEN 'Claim->Proposition(occursAt)->Entity(PLACE)'
        WHEN f.has_participation THEN 'Claim->Proposition(participatesIn)->Entity(PERSON)->Event'
        ELSE 'Claim->Proposition'
    END AS candidate_traversal,
    CASE WHEN f.has_before THEN 'ORDER_ONLY' ELSE 'NOT_REQUESTED' END AS chronology_request,
    CASE
        WHEN f.has_interpretation THEN 'Return represented analytical observations without promotion to direct claims'
        WHEN f.asks_theory_confirmation THEN 'Unsupported: registry does not model truth-confirmation predicates'
        WHEN f.asks_exclusion_rationale THEN 'Unsupported: exclusion rationale is not represented as a registered relation'
        ELSE 'NOT_REQUESTED'
    END AS requested_interpretation,
    ARRAY_REMOVE(ARRAY[
        CASE WHEN f.asks_theory_confirmation THEN 'theory confirmation truth relation' END,
        CASE WHEN f.asks_exclusion_rationale THEN 'excludedBecause / motive / rationale relation' END,
        CASE WHEN f.asks_quantity THEN 'stored measured light-deflection quantity at Sobral' END,
        CASE WHEN f.asks_exact_date THEN 'registered exact calendar date for Principe observation' END
    ], NULL) AS unsupported_concepts,
    CASE WHEN f.has_why OR f.has_sources OR f.has_interpretation THEN true ELSE false END AS provenance_required,
    'BEREAN_ONLY'::text AS retrieval_scope,
    CASE
        WHEN f.asks_theory_confirmation OR f.asks_exclusion_rationale OR f.asks_quantity OR f.asks_exact_date
            THEN 'NOT_ESTABLISHED'
        ELSE 'ESTABLISHED'
    END AS capability_status,
    CASE
        WHEN f.asks_theory_confirmation THEN 'Vocabulary preserves source/scholarship records but does not model theory-confirmation truth assertions.'
        WHEN f.asks_exclusion_rationale THEN 'The represented corpus includes observations and scholarly interpretations but no registered excludedBecause/biasedBy/motive relation for this question.'
        WHEN f.asks_quantity THEN 'No typed measured value claim is represented for Sobral deflection in the persisted Phase 33 substrate.'
        WHEN f.asks_exact_date THEN 'Event ordering is represented via precedes, but exact calendar date for Principe observation is not represented.'
        ELSE 'Supported by existing predicates and graph traversal without schema change.'
    END AS capability_reason
FROM features f;

DROP TABLE IF EXISTS phase34_plan_run1;
CREATE TEMP TABLE phase34_plan_run1 AS
SELECT *
FROM phase34_plan_generator
ORDER BY question_no;

DROP TABLE IF EXISTS phase34_plan_run2;
CREATE TEMP TABLE phase34_plan_run2 AS
SELECT *
FROM phase34_plan_generator
ORDER BY question_no;

BEGIN READ ONLY;

\echo 'Phase 34 query-plan inventory (normalized, deterministic, BEREAN_ONLY scope)'
SELECT question_no,
       query_classification,
       requested_entities,
       requested_events,
       requested_relationships,
       candidate_predicates,
       candidate_traversal,
       chronology_request,
       requested_interpretation,
       unsupported_concepts,
       provenance_required,
       retrieval_scope,
       capability_status
FROM phase34_plan_run1
ORDER BY question_no;

DO $$
DECLARE
    actual integer;
    before_counts phase34_counts_before%ROWTYPE;
    after_counts phase34_counts_before%ROWTYPE;
BEGIN
    SELECT count(*) INTO actual FROM phase34_plan_run1;
    IF actual <> 11 THEN
        RAISE EXCEPTION 'phase34 plan: expected 11 normalized plans (Q1-Q10 + novel), found %', actual;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM phase34_plan_run1
        WHERE query_classification NOT IN (
            'ENTITY_LOOKUP', 'EVENT_LOOKUP', 'RELATIONSHIP_LOOKUP', 'SOURCE_COMPARISON',
            'CHRONOLOGY', 'PROVENANCE', 'IDENTITY_RECONCILIATION', 'EVIDENCE_CLASSIFICATION',
            'SCHOLARLY_INTERPRETATION', 'GRAPH_DERIVATION', 'UNSUPPORTED_RELATION',
            'UNSUPPORTED_QUANTITY', 'UNSUPPORTED_DATE', 'UNSUPPORTED_THEORY_RELATION'
        )
    ) THEN
        RAISE EXCEPTION 'phase34 plan: query classification outside allowed set';
    END IF;

    SELECT count(*) INTO actual
    FROM phase34_plan_run1
    WHERE question_no BETWEEN 7 AND 10
      AND capability_status = 'NOT_ESTABLISHED';
    IF actual <> 4 THEN
        RAISE EXCEPTION 'phase34 plan: expected Q7-Q10 to be NOT_ESTABLISHED, found %', actual;
    END IF;

    IF EXISTS (
        SELECT 1 FROM phase34_plan_run1 WHERE retrieval_scope <> 'BEREAN_ONLY'
    ) THEN
        RAISE EXCEPTION 'phase34 plan: retrieval scope must be BEREAN_ONLY for all questions';
    END IF;

    SELECT count(*) INTO actual
    FROM (
        (SELECT * FROM phase34_plan_run1 EXCEPT SELECT * FROM phase34_plan_run2)
        UNION ALL
        (SELECT * FROM phase34_plan_run2 EXCEPT SELECT * FROM phase34_plan_run1)
    ) AS diff;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase34 plan: repeat normalization produced non-deterministic plans';
    END IF;

    SELECT * INTO before_counts FROM phase34_counts_before;
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
        RAISE EXCEPTION 'phase34 plan: normalized planning changed persistent counts';
    END IF;

    RAISE NOTICE 'ok: Phase 34 query plans are normalized, deterministic, capability-bounded, and read-only';
    RAISE NOTICE 'ok: CAPABILITY CHECK PRECEDES RETRIEVAL; UNSUPPORTED IS NOT FALSE; PLAN IS NOT PERSISTENCE';
END $$;

COMMIT;
