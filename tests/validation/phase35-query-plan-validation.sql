\set ON_ERROR_STOP on

-- Phase 35: cross-domain natural-language -> normalized query-plan validation.
--
-- Phase 34 proved that one domain (the 1919 eclipse) could be interrogated in natural language by an
-- interpreter that knew that domain's vocabulary. Phase 35 asks a harder question: does the
-- interpretation stage generalize? This script drives the single generic interpreter in
-- tests/validation/phase35-query-interpreter.sql with materially different wordings of eleven
-- questions spanning two independently populated domains (Genesis/Nephilim from Phases 30-31 and the
-- 1919 eclipse from Phases 32-33) and validates that:
--
--   * plans are domain-neutral and inspectable (semantic target / filters / relationship / output /
--     provenance), never domain-specific SQL;
--   * materially different wordings of the same question normalize to the same plan;
--   * a capability check is computed before any retrieval and is bounded to declared states;
--   * retrieval scope is BEREAN_ONLY for every question;
--   * repeated interpretation is deterministic;
--   * plans are transient and never become persisted knowledge;
--   * planning is read-only.

DROP TABLE IF EXISTS phase35_plan_counts_before;
CREATE TEMP TABLE phase35_plan_counts_before AS
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

-- ---------------------------------------------------------------------------
-- Natural-language input. Variant A and variant B of each group are materially different wordings of
-- the same research question. The interpreter never sees the group label.
-- ---------------------------------------------------------------------------

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
-- Interpretation run 1.
-- ---------------------------------------------------------------------------

\ir phase35-query-interpreter.sql

DROP TABLE IF EXISTS phase35_plan_run1;
CREATE TEMP TABLE phase35_plan_run1 AS
SELECT question_key, question_group, variant, semantic_relationship, semantic_target,
       semantic_filters, candidate_predicates, traversal_shape, output_constraints,
       provenance_requirement, retrieval_scope, capability_status, capability_reason
FROM p35_plan;

DROP TABLE IF EXISTS phase35_anchor_run1;
CREATE TEMP TABLE phase35_anchor_run1 AS
SELECT question_key, anchor_term, anchor_kind, anchor_key FROM p35_anchor;

-- ---------------------------------------------------------------------------
-- Interpretation run 2 (identical input, fresh transient state).
-- ---------------------------------------------------------------------------

\ir phase35-query-interpreter.sql

DROP TABLE IF EXISTS phase35_plan_run2;
CREATE TEMP TABLE phase35_plan_run2 AS
SELECT question_key, question_group, variant, semantic_relationship, semantic_target,
       semantic_filters, candidate_predicates, traversal_shape, output_constraints,
       provenance_requirement, retrieval_scope, capability_status, capability_reason
FROM p35_plan;

DROP TABLE IF EXISTS phase35_anchor_run2;
CREATE TEMP TABLE phase35_anchor_run2 AS
SELECT question_key, anchor_term, anchor_kind, anchor_key FROM p35_anchor;

BEGIN READ ONLY;

\echo '=== PHASE 35: NORMALIZED CROSS-DOMAIN QUERY PLANS ==='
SELECT question_key,
       semantic_relationship,
       semantic_target,
       capability_status,
       provenance_requirement,
       retrieval_scope
FROM phase35_plan_run1
ORDER BY question_group, variant;

\echo '=== PHASE 35: PLAN INTERNALS (registry-resolved predicates and traversal shape) ==='
SELECT question_key,
       array_to_string(candidate_predicates, ',') AS candidate_predicates,
       traversal_shape,
       array_to_string(output_constraints, ',') AS output_constraints
FROM phase35_plan_run1
ORDER BY question_group, variant;

\echo '=== PHASE 35: SEMANTIC FILTERS RESOLVED AGAINST PERSISTED LABELS ONLY ==='
SELECT question_key,
       coalesce(array_length(semantic_filters, 1), 0) AS resolved_anchor_objects,
       (SELECT count(DISTINCT a.anchor_term) FROM phase35_anchor_run1 a
        WHERE a.question_key = p.question_key) AS anchor_terms
FROM phase35_plan_run1 p
ORDER BY question_group, variant;

\echo '=== PHASE 35: WORDING VARIATION -> PLAN EQUIVALENCE ==='
SELECT a.question_group,
       a.semantic_relationship,
       a.semantic_target,
       a.capability_status,
       CASE WHEN (a.semantic_relationship, a.semantic_target, a.semantic_filters,
                  a.candidate_predicates, a.traversal_shape, a.output_constraints,
                  a.provenance_requirement, a.retrieval_scope, a.capability_status)
                 IS NOT DISTINCT FROM
                 (b.semantic_relationship, b.semantic_target, b.semantic_filters,
                  b.candidate_predicates, b.traversal_shape, b.output_constraints,
                  b.provenance_requirement, b.retrieval_scope, b.capability_status)
            THEN 'EQUIVALENT' ELSE 'DIVERGENT' END AS variant_normalization
FROM phase35_plan_run1 a
JOIN phase35_plan_run1 b ON b.question_group = a.question_group AND b.variant = 'B'
WHERE a.variant = 'A'
ORDER BY a.question_group;

\echo '=== PHASE 35: CAPABILITY CHECK REASONS ==='
SELECT DISTINCT question_group, capability_status, capability_reason
FROM phase35_plan_run1
ORDER BY question_group;

COMMIT;

DO $$
DECLARE
    actual integer;
    before_counts phase35_plan_counts_before%ROWTYPE;
    after_counts phase35_plan_counts_before%ROWTYPE;
BEGIN
    SELECT count(*) INTO actual FROM phase35_plan_run1;
    IF actual <> 22 THEN
        RAISE EXCEPTION 'phase35 plan: expected 22 normalized plans (11 questions x 2 wordings), found %', actual;
    END IF;

    SELECT count(*) INTO actual FROM (
        SELECT question_group FROM phase35_plan_run1 GROUP BY question_group HAVING count(*) <> 2
    ) AS bad;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 plan: every question group must supply exactly two wordings';
    END IF;

    -- Materially different wording must normalize to the same domain-neutral plan.
    SELECT count(*) INTO actual
    FROM phase35_plan_run1 a
    JOIN phase35_plan_run1 b ON b.question_group = a.question_group AND b.variant = 'B'
    WHERE a.variant = 'A'
      AND (a.semantic_relationship, a.semantic_target, a.semantic_filters, a.candidate_predicates,
           a.traversal_shape, a.output_constraints, a.provenance_requirement, a.retrieval_scope,
           a.capability_status)
          IS DISTINCT FROM
          (b.semantic_relationship, b.semantic_target, b.semantic_filters, b.candidate_predicates,
           b.traversal_shape, b.output_constraints, b.provenance_requirement, b.retrieval_scope,
           b.capability_status);
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 plan: % question group(s) normalized differently under different wording', actual;
    END IF;

    IF EXISTS (
        SELECT 1 FROM phase35_plan_run1
        WHERE capability_status NOT IN ('ESTABLISHED', 'DERIVABLE', 'SCHOLARLY_CANDIDATE',
                                        'UNRESOLVED', 'NOT_REPRESENTED')
    ) THEN
        RAISE EXCEPTION 'phase35 plan: capability status outside the declared state set';
    END IF;

    IF EXISTS (SELECT 1 FROM phase35_plan_run1 WHERE retrieval_scope <> 'BEREAN_ONLY') THEN
        RAISE EXCEPTION 'phase35 plan: retrieval scope must be BEREAN_ONLY for every question';
    END IF;

    -- Both domains must be represented by established or derivable capability, otherwise the
    -- generalization claim is not being tested at all.
    IF NOT EXISTS (SELECT 1 FROM phase35_plan_run1
                   WHERE question_group = 'G1' AND capability_status = 'ESTABLISHED') THEN
        RAISE EXCEPTION 'phase35 plan: Genesis directly supported relation was not established';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM phase35_plan_run1
                   WHERE question_group = 'E1' AND capability_status = 'DERIVABLE') THEN
        RAISE EXCEPTION 'phase35 plan: eclipse graph derivation was not derivable';
    END IF;

    -- Unsupported theory confirmation must remain a controlled limitation, never a fabricated answer.
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'E4' AND capability_status <> 'NOT_REPRESENTED') THEN
        RAISE EXCEPTION 'phase35 plan: theory-confirmation question must remain NOT_REPRESENTED';
    END IF;
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'E4' AND array_length(candidate_predicates, 1) > 0) THEN
        RAISE EXCEPTION 'phase35 plan: theory-confirmation question must not resolve any predicate';
    END IF;

    -- Identity questions must not silently reconcile or assert equivalence.
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'G3' AND capability_status <> 'UNRESOLVED') THEN
        RAISE EXCEPTION 'phase35 plan: cross-source identity question must remain UNRESOLVED';
    END IF;
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'G3'
                 AND NOT ('NO_INVENTED_EQUIVALENCE' = ANY (output_constraints))) THEN
        RAISE EXCEPTION 'phase35 plan: identity equivalence plan must forbid invented equivalence';
    END IF;
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'E3'
                 AND NOT ('MAPPING_STATUS<>ACTIVE' = ANY (output_constraints))) THEN
        RAISE EXCEPTION 'phase35 plan: reconciliation plan must not activate proposed mappings';
    END IF;

    -- Scholarly candidates must never be planned as a single selected answer.
    IF EXISTS (SELECT 1 FROM phase35_plan_run1
               WHERE question_group = 'G2'
                 AND (capability_status <> 'SCHOLARLY_CANDIDATE'
                      OR NOT ('NO_SINGLE_CANDIDATE_SELECTION' = ANY (output_constraints)))) THEN
        RAISE EXCEPTION 'phase35 plan: scholarly candidate question must not select one candidate';
    END IF;

    -- Candidate predicates must come from the registry, never from a hard-coded literal list.
    IF EXISTS (
        SELECT 1
        FROM phase35_plan_run1 p
        CROSS JOIN LATERAL unnest(p.candidate_predicates) AS cp(predicate_code)
        WHERE NOT EXISTS (SELECT 1 FROM predicate r WHERE r.predicate_code = cp.predicate_code)
    ) THEN
        RAISE EXCEPTION 'phase35 plan: candidate predicate outside the registered predicate registry';
    END IF;

    -- Semantic filters must resolve to persisted Berean objects, never to question-specific literals.
    IF EXISTS (
        SELECT 1 FROM phase35_anchor_run1 a
        WHERE (a.anchor_kind = 'ENTITY'
               AND NOT EXISTS (SELECT 1 FROM entity e WHERE e.entity_key = a.anchor_key))
           OR (a.anchor_kind = 'EVENT'
               AND NOT EXISTS (SELECT 1 FROM event ev WHERE ev.event_key = a.anchor_key))
           OR (a.anchor_kind = 'SOURCE'
               AND NOT EXISTS (SELECT 1 FROM source s WHERE s.source_key = a.anchor_key))
           OR (a.anchor_kind = 'SOURCE_IDENTITY'
               AND NOT EXISTS (SELECT 1 FROM source_identity si
                               WHERE si.source_identity_key = a.anchor_key))
    ) THEN
        RAISE EXCEPTION 'phase35 plan: semantic filter did not resolve to a persisted Berean label';
    END IF;

    -- Determinism of interpretation.
    SELECT count(*) INTO actual FROM (
        (SELECT * FROM phase35_plan_run1 EXCEPT SELECT * FROM phase35_plan_run2)
        UNION ALL
        (SELECT * FROM phase35_plan_run2 EXCEPT SELECT * FROM phase35_plan_run1)
    ) AS diff;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 plan: repeated interpretation produced non-deterministic plans';
    END IF;

    SELECT count(*) INTO actual FROM (
        (SELECT * FROM phase35_anchor_run1 EXCEPT SELECT * FROM phase35_anchor_run2)
        UNION ALL
        (SELECT * FROM phase35_anchor_run2 EXCEPT SELECT * FROM phase35_anchor_run1)
    ) AS diff;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 plan: repeated anchor resolution was non-deterministic';
    END IF;

    -- Plans and interpreter state must remain transient.
    SELECT count(*) INTO actual
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname NOT LIKE 'pg\_temp%'
      AND n.nspname NOT LIKE 'pg\_toast%'
      AND (c.relname LIKE 'p35\_%' OR c.relname LIKE 'phase35\_%');
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase35 plan: query-plan state was persisted (% relation(s))', actual;
    END IF;

    SELECT * INTO before_counts FROM phase35_plan_counts_before;
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
        RAISE EXCEPTION 'phase35 plan: interpretation changed persistent counts';
    END IF;

    RAISE NOTICE 'ok: Phase 35 plans are generic, wording-stable, capability-bounded, deterministic and read-only';
    RAISE NOTICE 'ok: ONE INTERPRETER; PLAN IS NOT PERSISTENCE; ABSENCE IS NOT FALSE';
END $$;
