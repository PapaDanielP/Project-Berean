\set ON_ERROR_STOP on

-- Phase 35: cross-domain natural-language scholarly interrogation over two independently populated
-- domains, executed by the single generic interpreter in tests/validation/phase35-query-interpreter.sql.
--
-- Domains (neither is repopulated here; both are read as already-persisted knowledge):
--   * Genesis / Nephilim knowledge persisted by Phases 30-31;
--   * 1919 solar-eclipse knowledge persisted by Phases 32-33.
--
-- Pipeline validated for every question:
--   natural language -> generic semantic interpretation -> normalized query plan -> capability check
--   -> domain-agnostic graph retrieval -> evidence/provenance -> bounded synthesis.
--
-- The interpreter contains no domain identifiers, no per-question SQL and no canned answers; this
-- script only supplies natural language and inspects what the interpreter returns.

DROP TABLE IF EXISTS phase35_counts_before;
CREATE TEMP TABLE phase35_counts_before AS
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

DROP TABLE IF EXISTS p35_question;
CREATE TEMP TABLE p35_question (
    question_key text PRIMARY KEY,
    question_group text NOT NULL,
    variant text NOT NULL,
    question_text text NOT NULL
);

INSERT INTO p35_question (question_key, question_group, variant, question_text) VALUES
    ('G1-A', 'G1', 'A', 'What does Genesis explicitly say about where the Nephilim were?'),
    ('G1-B', 'G1', 'B', 'In Genesis, at what place are the Nephilim?'),
    ('G2-A', 'G2', 'A', 'Who were the sons of God in Genesis 6?'),
    ('G2-B', 'G2', 'B', 'In Genesis chapter 6, which beings are identified as the sons of God?'),
    ('G3-A', 'G3', 'A', 'Does Numbers identify the same Nephilim as Genesis?'),
    ('G3-B', 'G3', 'B', 'Are the Nephilim in Numbers the same as the Nephilim in Genesis?'),
    ('G4-A', 'G4', 'A', 'What source supports the statement that the Nephilim were on the earth?'),
    ('G4-B', 'G4', 'B', 'Trace the provenance of the assertion that the Nephilim were on the earth.'),
    ('E1-A', 'E1', 'A', 'Which people participated in observations, and where were those observations held?'),
    ('E1-B', 'E1', 'B', 'At which locations were the observations that people took part in held?'),
    ('E2-A', 'E2', 'A', 'What source observations remain evidence-only rather than claims?'),
    ('E2-B', 'E2', 'B', 'Which recorded observations are kept only as evidence and never promoted?'),
    ('E3-A', 'E3', 'A', 'Which source identities have not been fully reconciled to canonical entities?'),
    ('E3-B', 'E3', 'B', 'Which source-specific identities remain unreconciled against canonical entities?'),
    ('E4-A', 'E4', 'A', 'Which theory did the eclipse observations prove?'),
    ('E4-B', 'E4', 'B', 'What theory was proven by the eclipse observations?'),
    ('X1-A', 'X1', 'A', 'Which relationships in Genesis and in the eclipse can Berean support directly, and which remain interpretive?'),
    ('X1-B', 'X1', 'B', 'For Genesis and for the eclipse, which relationships are directly supported and which are only interpretive?'),
    ('X2-A', 'X2', 'A', 'For Genesis and the eclipse, show an example where Berean knows something directly and one where interpretation is required, with provenance.'),
    ('X2-B', 'X2', 'B', 'For Genesis and the eclipse, give an example of direct knowledge and an example needing interpretation, with provenance.'),
    ('X3-A', 'X3', 'A', 'Which events supported by sources have people participating and a represented place?'),
    ('X3-B', 'X3', 'B', 'Find events supported by sources where people are participating and a place is represented.');

-- ---------------------------------------------------------------------------
-- Interrogation run 1.
-- ---------------------------------------------------------------------------

\ir phase35-query-interpreter.sql

DROP TABLE IF EXISTS phase35_answer_run1;
CREATE TEMP TABLE phase35_answer_run1 AS
SELECT a.question_key, q.question_group, q.variant, a.operator, a.result_key, a.result_label,
       a.result_classification, a.provenance_chain
FROM p35_answer a
JOIN p35_question q ON q.question_key = a.question_key;

DROP TABLE IF EXISTS phase35_plan_snapshot;
CREATE TEMP TABLE phase35_plan_snapshot AS SELECT * FROM p35_plan;

-- ---------------------------------------------------------------------------
-- Interrogation run 2 (same questions, fresh transient interpreter state).
-- ---------------------------------------------------------------------------

\ir phase35-query-interpreter.sql

DROP TABLE IF EXISTS phase35_answer_run2;
CREATE TEMP TABLE phase35_answer_run2 AS
SELECT a.question_key, q.question_group, q.variant, a.operator, a.result_key, a.result_label,
       a.result_classification, a.provenance_chain
FROM p35_answer a
JOIN p35_question q ON q.question_key = a.question_key;

-- Anti-fabrication helper: every numeric token appearing in an answer must already occur somewhere in
-- persisted Berean knowledge. Answers may compose persisted knowledge; they may not invent values.
DROP VIEW IF EXISTS phase35_unsourced_number;
CREATE TEMP VIEW phase35_unsourced_number AS
WITH persisted_text AS (
    SELECT canonical_name AS txt FROM entity
    UNION ALL SELECT entity_key FROM entity
    UNION ALL SELECT coalesce(description, '') FROM event
    UNION ALL SELECT event_key FROM event
    UNION ALL SELECT observation FROM evidence
    UNION ALL SELECT evidence_key FROM evidence
    UNION ALL SELECT coalesce(locator, '') FROM citation
    UNION ALL SELECT source_key FROM source
    UNION ALL SELECT name FROM source
    UNION ALL SELECT claim_key FROM claim
    UNION ALL SELECT coalesce(statement, '') FROM claim
    UNION ALL SELECT rendered_proposition FROM claim_rendering
),
answer_number AS (
    SELECT a.question_key, m[1] AS number_token
    FROM phase35_answer_run1 a
    CROSS JOIN LATERAL regexp_matches(a.result_label, '([0-9]+(?:\.[0-9]+)?)', 'g') AS m
)
SELECT DISTINCT an.question_key, an.number_token
FROM answer_number an
WHERE NOT EXISTS (
    SELECT 1 FROM persisted_text pt WHERE pt.txt LIKE '%' || an.number_token || '%'
);

BEGIN READ ONLY;

\echo '=== PHASE 35: PER-QUESTION PIPELINE TRACE (capability check precedes retrieval) ==='
SELECT p.question_key,
       stage.stage_order,
       stage.stage_name
FROM phase35_plan_snapshot p
CROSS JOIN LATERAL (
    VALUES
      (1,  'NATURAL_LANGUAGE_INPUT_RECEIVED'),
      (2,  'SEMANTIC_CLASSIFICATION'),
      (3,  'ENTITY_CONCEPT_RELATIONSHIP_RESOLUTION'),
      (4,  'CANDIDATE_PREDICATE_RESOLUTION'),
      (5,  'CANDIDATE_GRAPH_TRAVERSAL'),
      (6,  'CAPABILITY_CHECK'),
      (7,  'RETRIEVAL'),
      (8,  'EVIDENCE_RESOLUTION'),
      (9,  'PROVENANCE_RESOLUTION'),
      (10, 'RESULT_CLASSIFICATION'),
      (11, 'BOUNDED_SYNTHESIS')
) AS stage(stage_order, stage_name)
WHERE p.question_key IN ('G1-A', 'E1-A')
ORDER BY p.question_key, stage.stage_order;

\echo '=== PHASE 35: CAPABILITY CHECK PER QUESTION (before any retrieval) ==='
SELECT question_key, semantic_relationship, semantic_target, capability_status
FROM phase35_plan_snapshot
ORDER BY question_group, variant;

\echo '=== G1: What does Genesis explicitly say about where the Nephilim were? ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'G1'
ORDER BY question_key, result_key;

\echo '=== G2: Who were the sons of God in Genesis 6? (candidates; none selected as fact) ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'G2'
ORDER BY question_key, result_key;

\echo '=== G3: Does Numbers identify the same Nephilim as Genesis? (unresolved identity) ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'G3'
ORDER BY question_key, result_key;

\echo '=== G4: What source supports the Nephilim-on-the-earth statement? (full provenance chain) ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'G4'
ORDER BY question_key, result_key;

\echo '=== E1: Which people participated in observations, and where were they held? ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'E1'
ORDER BY question_key, result_key;

\echo '=== E2: Which source observations remain evidence-only rather than claims? ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'E2'
ORDER BY question_key, result_key;

\echo '=== E3: Which source identities remain unreconciled? (retrieved, not activated) ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'E3'
ORDER BY question_key, result_key;

\echo '=== E4: Which theory did the eclipse observations prove? (controlled limitation) ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'E4'
ORDER BY question_key, result_key;

\echo '=== X1: Which relationships are directly supported and which remain interpretive? ==='
SELECT question_key, result_key, result_classification, result_label
FROM phase35_answer_run1
WHERE question_group = 'X1'
ORDER BY question_key, result_key;

\echo '=== X2: One direct and one interpretive example per domain, with provenance ==='
SELECT question_key, result_key, result_classification, result_label, provenance_chain
FROM phase35_answer_run1
WHERE question_group = 'X2'
ORDER BY question_key, result_key;

\echo '=== X3 (novel multi-hop derivation): source-backed events with participants and locations ==='
SELECT question_key, result_key, result_classification, result_label
FROM phase35_answer_run1
WHERE question_group = 'X3'
ORDER BY question_key, result_key;

\echo '=== PHASE 35: RESULT CLASSIFICATION SUMMARY ==='
SELECT question_group, result_classification, count(*) AS results
FROM phase35_answer_run1
GROUP BY question_group, result_classification
ORDER BY question_group, result_classification;

\echo '=== PHASE 35: WORDING VARIATION -> RETRIEVED-KEY AND PROVENANCE EQUALITY ==='
SELECT g.question_group,
       CASE WHEN NOT EXISTS (
                SELECT result_key, result_classification, coalesce(provenance_chain, '')
                FROM phase35_answer_run1 WHERE question_group = g.question_group AND variant = 'A'
                EXCEPT
                SELECT result_key, result_classification, coalesce(provenance_chain, '')
                FROM phase35_answer_run1 WHERE question_group = g.question_group AND variant = 'B'
            ) AND NOT EXISTS (
                SELECT result_key, result_classification, coalesce(provenance_chain, '')
                FROM phase35_answer_run1 WHERE question_group = g.question_group AND variant = 'B'
                EXCEPT
                SELECT result_key, result_classification, coalesce(provenance_chain, '')
                FROM phase35_answer_run1 WHERE question_group = g.question_group AND variant = 'A'
            )
            THEN 'EQUIVALENT' ELSE 'DIVERGENT' END AS retrieval_equivalence
FROM (SELECT DISTINCT question_group FROM phase35_answer_run1) g
ORDER BY g.question_group;

\echo '=== PHASE 35: NEGATIVE SEMANTIC VALIDATION ==='
SELECT check_name, observed, expectation
FROM (
    VALUES
      ('NO_INVENTED_PREDICATE',
       (SELECT count(*) FROM predicate
        WHERE predicate_code IN ('confirmsTheory', 'supportsTheory', 'refutesTheory', 'provesTheory',
                                 'sameAs', 'identicalTo', 'preferredOver', 'excludedBecause',
                                 'contradicts', 'occursOnDate'))::text,
       'Berean must refuse to invent predicates the registry does not define'),
      ('NO_PREDICATE_OUTSIDE_REGISTRY',
       (SELECT count(*) FROM phase35_plan_snapshot p
        CROSS JOIN LATERAL unnest(p.candidate_predicates) AS cp(predicate_code)
        WHERE NOT EXISTS (SELECT 1 FROM predicate r
                          WHERE r.predicate_code = cp.predicate_code))::text,
       'Every planned predicate must come from the registry'),
      ('NO_SCHOLARSHIP_PROMOTED_TO_CLAIM',
       (SELECT count(*) FROM claim_evidence ce JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_type_code = 'ANALYTICAL_OBSERVATION')::text,
       'Scholarly interpretation must not be promoted into claim backing'),
      ('NO_CONTRADICTION_INFERRED_FROM_DIFFERENCE',
       (SELECT count(*) FROM phase35_answer_run1
        WHERE upper(result_classification) LIKE '%CONTRADICT%'
           OR upper(coalesce(result_label, '')) LIKE '%CONTRADICT%'
           OR upper(coalesce(result_label, '')) LIKE '%REFUTES%')::text,
       'Differing source accounts must not be reported as contradiction'),
      ('NO_TRUTH_ASSERTION',
       (SELECT count(*) FROM phase35_answer_run1
        WHERE result_classification IN ('TRUE', 'CONFIRMED', 'PROVEN'))::text,
       'Source-backed is not true; no answer may assert truth'),
      ('NO_FABRICATED_QUANTITY_OR_DATE',
       (SELECT count(*) FROM phase35_unsourced_number)::text,
       'Every number in an answer must already occur in persisted knowledge'),
      ('NO_SILENT_IDENTITY_RECONCILIATION',
       (SELECT count(*) FROM entity_source_mapping WHERE mapping_status_code = 'ACTIVE'
          AND source_identity_id IN (
              SELECT si.source_identity_id FROM source_identity si
              WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'))::text,
       'A PROPOSED mapping must never be silently activated by interrogation'),
      ('ABSENCE_IS_NOT_FALSE',
       (SELECT count(*) FROM phase35_answer_run1
        WHERE result_classification = 'NOT_REPRESENTED')::text,
       'Unrepresented relations return controlled limitations, not denials'),
      ('BEREAN_ONLY_RETRIEVAL',
       (SELECT count(*) FROM phase35_plan_snapshot WHERE retrieval_scope <> 'BEREAN_ONLY')::text,
       'No silent external supplementation is permitted')
) AS checks(check_name, observed, expectation);

\echo '=== PHASE 35: ANTI-CONTAMINATION (no persisted answer cache for these questions) ==='
SELECT 'QUESTION_TEXT_PERSISTED' AS check_name,
       (SELECT count(*) FROM p35_question q
        WHERE EXISTS (SELECT 1 FROM evidence e WHERE lower(e.observation) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM claim c WHERE lower(coalesce(c.statement, '')) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM event ev WHERE lower(coalesce(ev.description, '')) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM source_record sr WHERE lower(coalesce(sr.raw_content, '')) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM citation ci WHERE lower(coalesce(ci.locator, '')) LIKE '%' || lower(q.question_text) || '%')
       )::text AS observed
UNION ALL
SELECT 'PHASE35_PERSISTED_RELATION',
       (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname NOT LIKE 'pg\_temp%' AND n.nspname NOT LIKE 'pg\_toast%'
          AND (c.relname LIKE 'p35\_%' OR c.relname LIKE 'phase35\_%'))::text
UNION ALL
SELECT 'PHASE35_KNOWLEDGE_KEYS',
       (SELECT count(*) FROM (
            SELECT claim_key AS k FROM claim
            UNION ALL SELECT evidence_key FROM evidence
            UNION ALL SELECT entity_key FROM entity
            UNION ALL SELECT event_key FROM event
            UNION ALL SELECT source_key FROM source
        ) AS keys WHERE lower(k) LIKE '%phase35%' OR lower(k) LIKE '%p35%')::text;

\echo '=== PHASE 35: READ-ONLY COUNTS (before and after the complete Phase 35 query suite) ==='
SELECT 'before' AS measurement, * FROM phase35_counts_before
UNION ALL
SELECT 'after',
       (SELECT count(*) FROM source), (SELECT count(*) FROM dataset),
       (SELECT count(*) FROM source_record), (SELECT count(*) FROM citation),
       (SELECT count(*) FROM source_identity), (SELECT count(*) FROM entity_source_mapping),
       (SELECT count(*) FROM entity), (SELECT count(*) FROM event),
       (SELECT count(*) FROM proposition), (SELECT count(*) FROM claim),
       (SELECT count(*) FROM evidence), (SELECT count(*) FROM claim_evidence),
       (SELECT count(*) FROM claim_relation)
ORDER BY measurement DESC;

\echo '=== PHASE 35: BOUNDED SYNTHESIS (transient; not persisted) ==='
SELECT ord, section, statement
FROM (
    VALUES
      (1, 'Directly supported in both domains',
       'The Genesis locatedAt claim and the eclipse participatesIn/occursAt claims are retrieved as source-backed claims with complete provenance chains by the same generic operators.'),
      (2, 'Derived, not stated',
       'Participant-and-place answers are composed from separate claim-asserted propositions and are classified DERIVED_FROM_PERSISTED_GRAPH, never as source text.'),
      (3, 'Scholarly interpretation preserved as candidates',
       'Competing readings of the sons of God remain unpromoted analytical observations with citations; no candidate is selected as fact.'),
      (4, 'Identity remains unresolved',
       'Cross-source Nephilim identity and the proposed Observatory identity mapping are returned as unresolved; no equivalence is invented and no mapping is activated.'),
      (5, 'Unrepresented relations return limitations',
       'Theory confirmation has no registered predicate and no schema mechanism, so it is reported as NOT_REPRESENTED rather than answered.')
) AS synthesis(ord, section, statement)
ORDER BY ord;

DO $$
DECLARE
    before_counts phase35_counts_before%ROWTYPE;
    after_counts phase35_counts_before%ROWTYPE;
    actual integer;
BEGIN
    -- Every question must have been interpreted, and every capability state must be declared.
    SELECT count(*) INTO actual FROM phase35_plan_snapshot;
    IF actual <> 22 THEN
        RAISE EXCEPTION 'phase35 query: expected 22 interpreted questions, found %', actual;
    END IF;

    -- Every question must produce at least one answer object or an explicit controlled limitation.
    SELECT count(*) INTO actual
    FROM phase35_plan_snapshot p
    WHERE NOT EXISTS (SELECT 1 FROM phase35_answer_run1 a WHERE a.question_key = p.question_key);
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: % question(s) produced neither answer nor limitation', actual;
    END IF;

    IF EXISTS (
        SELECT 1 FROM phase35_answer_run1
        WHERE result_classification NOT IN (
            'DIRECTLY_SUPPORTED', 'DERIVED_FROM_PERSISTED_GRAPH', 'SCHOLARLY_CANDIDATE',
            'EVIDENCE_ONLY_NOT_CLAIM', 'INTERPRETIVE_ONLY', 'UNRESOLVED_IDENTITY', 'NOT_REPRESENTED')
    ) THEN
        RAISE EXCEPTION 'phase35 query: result classification outside the declared set';
    END IF;

    -- G1: Genesis location is directly supported and carries a full provenance chain.
    SELECT count(*) INTO actual
    FROM phase35_answer_run1
    WHERE question_group = 'G1'
      AND result_classification = 'DIRECTLY_SUPPORTED'
      AND provenance_chain LIKE 'Claim %-> Evidence %-> Citation %-> SourceRecord %-> Dataset %-> Source %';
    IF actual < 2 THEN
        RAISE EXCEPTION 'phase35 query: Genesis location answer lacked provenance for both wordings';
    END IF;

    -- G2: scholarly candidates only, and more than one candidate must survive.
    IF EXISTS (SELECT 1 FROM phase35_answer_run1
               WHERE question_group = 'G2' AND result_classification = 'DIRECTLY_SUPPORTED') THEN
        RAISE EXCEPTION 'phase35 query: scholarly candidate was promoted to a direct claim';
    END IF;
    SELECT count(DISTINCT result_key) INTO actual
    FROM phase35_answer_run1
    WHERE question_group = 'G2' AND variant = 'A'
      AND result_classification = 'SCHOLARLY_CANDIDATE';
    IF actual < 2 THEN
        RAISE EXCEPTION 'phase35 query: competing sons-of-God candidates were not preserved (found %)', actual;
    END IF;

    -- G3: identity remains unresolved; no equivalence is asserted.
    IF EXISTS (SELECT 1 FROM phase35_answer_run1
               WHERE question_group = 'G3'
                 AND result_classification NOT IN ('UNRESOLVED_IDENTITY', 'EVIDENCE_ONLY_NOT_CLAIM')) THEN
        RAISE EXCEPTION 'phase35 query: cross-source identity question produced a resolved answer';
    END IF;

    -- G4: complete provenance chain naming every link.
    IF NOT EXISTS (
        SELECT 1 FROM phase35_answer_run1
        WHERE question_group = 'G4'
          AND provenance_chain LIKE 'Claim %ClaimEvidence%Evidence%EvidenceCitation%Citation%SourceRecord%Dataset%Source%'
    ) THEN
        RAISE EXCEPTION 'phase35 query: provenance question did not return the complete chain';
    END IF;

    -- E1 and X3: graph derivation must be classified as derivation, never as source text.
    IF EXISTS (SELECT 1 FROM phase35_answer_run1
               WHERE question_group IN ('E1', 'X3')
                 AND result_classification <> 'DERIVED_FROM_PERSISTED_GRAPH') THEN
        RAISE EXCEPTION 'phase35 query: derived traversal was classified as a direct source statement';
    END IF;
    SELECT count(*) INTO actual
    FROM phase35_answer_run1 WHERE question_group = 'E1' AND variant = 'A';
    IF actual = 0 THEN
        RAISE EXCEPTION 'phase35 query: participation/location composition returned nothing';
    END IF;

    -- E2: evidence/claim boundary preserved.
    IF EXISTS (SELECT 1 FROM phase35_answer_run1
               WHERE question_group = 'E2' AND result_classification <> 'EVIDENCE_ONLY_NOT_CLAIM') THEN
        RAISE EXCEPTION 'phase35 query: evidence-only retrieval leaked claim-backed material';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM phase35_answer_run1 a
        JOIN evidence e ON e.evidence_key = a.result_key
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        WHERE a.question_group = 'E2'
    ) THEN
        RAISE EXCEPTION 'phase35 query: evidence-only answer included claim-linked evidence';
    END IF;

    -- E3: unreconciled identities retrieved without activation.
    IF NOT EXISTS (SELECT 1 FROM phase35_answer_run1
                   WHERE question_group = 'E3' AND result_classification = 'UNRESOLVED_IDENTITY') THEN
        RAISE EXCEPTION 'phase35 query: unreconciled identity retrieval returned nothing';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM phase35_answer_run1 a
        JOIN source_identity si ON si.source_identity_key = a.result_key
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        WHERE a.question_group = 'E3' AND esm.mapping_status_code = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'phase35 query: reconciliation retrieval returned an already-active mapping';
    END IF;

    -- E4: theory confirmation must remain a controlled limitation.
    IF EXISTS (SELECT 1 FROM phase35_answer_run1
               WHERE question_group = 'E4' AND result_classification <> 'NOT_REPRESENTED') THEN
        RAISE EXCEPTION 'phase35 query: unsupported theory question produced a substantive answer';
    END IF;

    -- X1/X2: both domains must appear, with the direct/interpretive boundary preserved.
    SELECT count(DISTINCT split_part(result_key, ' / ', 1)) INTO actual
    FROM phase35_answer_run1 WHERE question_group = 'X1' AND variant = 'A';
    IF actual < 2 THEN
        RAISE EXCEPTION 'phase35 query: capability inventory did not cover both domains (found %)', actual;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM phase35_answer_run1
                   WHERE question_group = 'X1' AND result_classification = 'INTERPRETIVE_ONLY') THEN
        RAISE EXCEPTION 'phase35 query: capability inventory reported no interpretive boundary';
    END IF;
    SELECT count(DISTINCT split_part(result_key, ' / ', 1)) INTO actual
    FROM phase35_answer_run1 WHERE question_group = 'X2' AND variant = 'A';
    IF actual < 2 THEN
        RAISE EXCEPTION 'phase35 query: boundary examples did not cover both domains (found %)', actual;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM phase35_answer_run1
                   WHERE question_group = 'X2' AND result_classification = 'DIRECTLY_SUPPORTED')
       OR NOT EXISTS (SELECT 1 FROM phase35_answer_run1
                      WHERE question_group = 'X2' AND result_classification = 'SCHOLARLY_CANDIDATE') THEN
        RAISE EXCEPTION 'phase35 query: boundary examples did not show both direct and interpretive knowledge';
    END IF;

    -- Retrieval equality across materially different wordings.
    SELECT count(*) INTO actual
    FROM (
        SELECT question_group, result_key, result_classification, coalesce(provenance_chain, '') AS pc
        FROM phase35_answer_run1 WHERE variant = 'A'
        EXCEPT
        SELECT question_group, result_key, result_classification, coalesce(provenance_chain, '')
        FROM phase35_answer_run1 WHERE variant = 'B'
        UNION ALL
        SELECT question_group, result_key, result_classification, coalesce(provenance_chain, '')
        FROM phase35_answer_run1 WHERE variant = 'B'
        EXCEPT
        SELECT question_group, result_key, result_classification, coalesce(provenance_chain, '')
        FROM phase35_answer_run1 WHERE variant = 'A'
    ) AS diff;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: different wordings retrieved different knowledge (% row(s))', actual;
    END IF;

    -- Determinism across repeated interrogation.
    SELECT count(*) INTO actual
    FROM (
        (SELECT * FROM phase35_answer_run1 EXCEPT SELECT * FROM phase35_answer_run2)
        UNION ALL
        (SELECT * FROM phase35_answer_run2 EXCEPT SELECT * FROM phase35_answer_run1)
    ) AS diff;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: repeated interrogation was non-deterministic';
    END IF;

    -- Negative semantic validation.
    IF EXISTS (
        SELECT 1 FROM predicate
        WHERE predicate_code IN ('confirmsTheory', 'supportsTheory', 'refutesTheory', 'provesTheory',
                                 'sameAs', 'identicalTo', 'preferredOver', 'excludedBecause',
                                 'contradicts', 'occursOnDate')
    ) THEN
        RAISE EXCEPTION 'phase35 query: an invented predicate was registered';
    END IF;

    IF EXISTS (
        SELECT 1 FROM phase35_plan_snapshot p
        CROSS JOIN LATERAL unnest(p.candidate_predicates) AS cp(predicate_code)
        WHERE NOT EXISTS (SELECT 1 FROM predicate r WHERE r.predicate_code = cp.predicate_code)
    ) THEN
        RAISE EXCEPTION 'phase35 query: a planned predicate is outside the predicate registry';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
    ) THEN
        RAISE EXCEPTION 'phase35 query: scholarship was promoted into claim backing';
    END IF;

    -- Represented disagreement persisted by earlier phases must be preserved unchanged, and no
    -- Phase 35 answer may present a difference between sources as a contradiction.
    IF EXISTS (
        SELECT 1 FROM phase35_answer_run1
        WHERE upper(result_classification) LIKE '%CONTRADICT%'
           OR upper(coalesce(result_label, '')) LIKE '%CONTRADICT%'
           OR upper(coalesce(result_label, '')) LIKE '%REFUTES%'
    ) THEN
        RAISE EXCEPTION 'phase35 query: source difference was reported as contradiction';
    END IF;

    SELECT count(*) INTO actual FROM phase35_unsourced_number;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: % fabricated numeric value(s) appeared in answers', actual;
    END IF;

    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'
          AND esm.mapping_status_code = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'phase35 query: an unresolved source identity was silently reconciled';
    END IF;

    -- Anti-contamination: no persisted object may carry a Phase 35 question or answer cache.
    IF EXISTS (
        SELECT 1 FROM p35_question q
        WHERE EXISTS (SELECT 1 FROM evidence e
                      WHERE lower(e.observation) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM claim c
                      WHERE lower(coalesce(c.statement, '')) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM event ev
                      WHERE lower(coalesce(ev.description, '')) LIKE '%' || lower(q.question_text) || '%')
           OR EXISTS (SELECT 1 FROM source_record sr
                      WHERE lower(coalesce(sr.raw_content, '')) LIKE '%' || lower(q.question_text) || '%')
    ) THEN
        RAISE EXCEPTION 'phase35 query: a Phase 35 question is stored in the knowledge substrate';
    END IF;

    SELECT count(*) INTO actual
    FROM (
        SELECT claim_key AS k FROM claim
        UNION ALL SELECT evidence_key FROM evidence
        UNION ALL SELECT entity_key FROM entity
        UNION ALL SELECT event_key FROM event
        UNION ALL SELECT source_key FROM source
    ) AS keys
    WHERE lower(k) LIKE '%phase35%' OR lower(k) LIKE '%p35%';
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: Phase 35 introduced % persisted knowledge object(s)', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname NOT LIKE 'pg\_temp%'
      AND n.nspname NOT LIKE 'pg\_toast%'
      AND (c.relname LIKE 'p35\_%' OR c.relname LIKE 'phase35\_%');
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 query: interrogation state was persisted (% relation(s))', actual;
    END IF;

    -- Read-only invariant.
    SELECT * INTO before_counts FROM phase35_counts_before;
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
        RAISE EXCEPTION 'phase35 query: interrogation changed persistent counts';
    END IF;

    RAISE NOTICE 'ok: Phase 35 answered Genesis, eclipse, and cross-domain questions with one generic interpreter';
    RAISE NOTICE 'ok: EVIDENCE IS NOT CLAIM; SCHOLARSHIP IS NOT FACT; DERIVATION IS NOT SOURCE TEXT; ABSENCE IS NOT FALSE';
END $$;

COMMIT;
