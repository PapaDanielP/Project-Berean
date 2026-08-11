-- Phase 35: generic, domain-agnostic semantic query interpreter.
--
-- Both Phase 35 validation scripts include this file with \ir, so exactly one interpreter exists and
-- no second query engine is introduced. The caller creates and populates the TEMP table
-- p35_question(question_key, question_group, variant, question_text) before including this file.
--
-- Everything created here is TEMP: normalized query plans and answer objects are transient working
-- state and never become authoritative persisted knowledge.
--
-- Pipeline:
--   natural language
--     -> generic semantic interpretation (domain-neutral lexicon + persisted-label resolution)
--     -> normalized query plan
--     -> capability check
--     -> domain-agnostic graph retrieval
--     -> evidence/provenance resolution
--     -> bounded synthesis
--
-- The interpreter contains no domain identifiers, no per-question SQL, no canned answers and no
-- dispatch on domain vocabulary. Concept anchors are resolved by matching question terms against
-- persisted Berean labels (entity, event, source, source identity); candidate predicates are
-- resolved from the predicate registry's own declared semantics.

-- ---------------------------------------------------------------------------
-- 0. Reset transient interpreter state (views first, then tables they depend on).
-- ---------------------------------------------------------------------------

SET client_min_messages = warning;

DROP VIEW IF EXISTS p35_answer;
DROP VIEW IF EXISTS p35_op_boundary_example;
DROP VIEW IF EXISTS p35_op_capability_inventory;
DROP VIEW IF EXISTS p35_op_identity_reconciliation;
DROP VIEW IF EXISTS p35_op_identity_equivalence;
DROP VIEW IF EXISTS p35_op_evidence_classification;
DROP VIEW IF EXISTS p35_op_interpretive_candidates;
DROP VIEW IF EXISTS p35_op_provenance;
DROP VIEW IF EXISTS p35_op_composition;
DROP VIEW IF EXISTS p35_op_single_predicate;
DROP VIEW IF EXISTS p35_claim_provenance;
DROP VIEW IF EXISTS p35_predicate_semantics;

DROP TABLE IF EXISTS p35_plan;
DROP TABLE IF EXISTS p35_plan_base;
DROP TABLE IF EXISTS p35_focus_anchor;
DROP TABLE IF EXISTS p35_scope_focus_evidence;
DROP TABLE IF EXISTS p35_scope_focus_event;
DROP TABLE IF EXISTS p35_scope_focus_entity;
DROP TABLE IF EXISTS p35_scope_evidence;
DROP TABLE IF EXISTS p35_scope_source;
DROP TABLE IF EXISTS p35_scope_event;
DROP TABLE IF EXISTS p35_scope_entity;
DROP TABLE IF EXISTS p35_anchor_role;
DROP TABLE IF EXISTS p35_anchor;
DROP TABLE IF EXISTS p35_feature;
DROP TABLE IF EXISTS p35_token;
DROP TABLE IF EXISTS p35_generic_term;
DROP TABLE IF EXISTS p35_lexicon;

RESET client_min_messages;

-- ---------------------------------------------------------------------------
-- 1. Registry-derived predicate semantics (no hard-coded predicate list).
-- ---------------------------------------------------------------------------

CREATE TEMP VIEW p35_predicate_semantics AS
SELECT p.predicate_code,
       p.subject_kind_code,
       p.object_kind_code,
       CASE
           WHEN p.event_participation_role_code IS NOT NULL THEN 'PARTICIPATION'
           WHEN p.description ILIKE '%located at%' OR p.description ILIKE '%occurs at%' THEN 'LOCATION'
           WHEN p.description ILIKE '%precedes%' THEN 'ORDERING'
           WHEN p.description ILIKE '%father%' OR p.description ILIKE '%mother%'
                OR p.description ILIKE '%sibling%' THEN 'KINSHIP'
           WHEN p.description ILIKE '%component%' OR p.description ILIKE '%contains%' THEN 'COMPOSITION'
           WHEN p.object_kind_code = 'VALUE' THEN 'ATTRIBUTE'
           ELSE 'OTHER'
       END AS semantic_role
FROM predicate p;

-- ---------------------------------------------------------------------------
-- 2. Generic semantic lexicon.
--
-- Terms are scholarly-question vocabulary: interrogatives and generic knowledge-architecture
-- concepts. No term names a domain, person, place, event or source represented in the substrate.
-- ---------------------------------------------------------------------------

CREATE TEMP TABLE p35_lexicon (
    term text NOT NULL,
    feature_kind text NOT NULL,
    feature_value text NOT NULL,
    PRIMARY KEY (term, feature_kind)
);

INSERT INTO p35_lexicon (term, feature_kind, feature_value) VALUES
    -- generic answer targets
    ('who', 'TARGET', 'AGENT'),
    ('which people', 'TARGET', 'AGENT'),
    ('which beings', 'TARGET', 'AGENT'),
    ('where', 'TARGET', 'PLACE'),
    ('what place', 'TARGET', 'PLACE'),
    ('which locations', 'TARGET', 'PLACE'),
    ('which events', 'TARGET', 'EVENT'),
    ('events', 'TARGET', 'EVENT'),
    ('which source identities', 'TARGET', 'IDENTITY'),
    ('source-specific identities', 'TARGET', 'IDENTITY'),
    ('which relationships', 'TARGET', 'RELATIONSHIP'),
    ('relationships are', 'TARGET', 'RELATIONSHIP'),
    ('source observations', 'TARGET', 'EVIDENCE'),
    ('recorded observations', 'TARGET', 'EVIDENCE'),
    ('example', 'TARGET', 'BOUNDARY_EXAMPLE'),
    -- generic semantic relationships
    ('where', 'RELATION', 'LOCATION'),
    ('what place', 'RELATION', 'LOCATION'),
    ('locations', 'RELATION', 'LOCATION'),
    ('located', 'RELATION', 'LOCATION'),
    ('place', 'RELATION', 'LOCATION'),
    ('held', 'RELATION', 'LOCATION'),
    ('participated', 'RELATION', 'PARTICIPATION'),
    ('participating', 'RELATION', 'PARTICIPATION'),
    ('took part', 'RELATION', 'PARTICIPATION'),
    ('before', 'RELATION', 'ORDERING'),
    ('after', 'RELATION', 'ORDERING'),
    ('the same', 'RELATION', 'IDENTITY_EQUIVALENCE'),
    ('same as', 'RELATION', 'IDENTITY_EQUIVALENCE'),
    ('reconciled', 'RELATION', 'IDENTITY_RECONCILIATION'),
    ('unreconciled', 'RELATION', 'IDENTITY_RECONCILIATION'),
    ('prove', 'RELATION', 'TRUTH_CONFIRMATION'),
    ('proven', 'RELATION', 'TRUTH_CONFIRMATION'),
    ('confirmed', 'RELATION', 'TRUTH_CONFIRMATION'),
    ('evidence-only', 'RELATION', 'EVIDENCE_CLASSIFICATION'),
    ('only as evidence', 'RELATION', 'EVIDENCE_CLASSIFICATION'),
    ('rather than claims', 'RELATION', 'EVIDENCE_CLASSIFICATION'),
    ('never promoted', 'RELATION', 'EVIDENCE_CLASSIFICATION'),
    ('what source supports', 'RELATION', 'PROVENANCE'),
    ('which source supports', 'RELATION', 'PROVENANCE'),
    ('trace the provenance', 'RELATION', 'PROVENANCE'),
    ('who were', 'RELATION', 'CONCEPT_IDENTITY'),
    ('identified as', 'RELATION', 'CONCEPT_IDENTITY'),
    ('support directly', 'RELATION', 'CAPABILITY_INVENTORY'),
    ('directly supported', 'RELATION', 'CAPABILITY_INVENTORY'),
    ('remain interpretive', 'RELATION', 'CAPABILITY_INVENTORY'),
    ('only interpretive', 'RELATION', 'CAPABILITY_INVENTORY'),
    ('knows something directly', 'RELATION', 'BOUNDARY_EXAMPLE'),
    ('interpretation is required', 'RELATION', 'BOUNDARY_EXAMPLE'),
    ('needing interpretation', 'RELATION', 'BOUNDARY_EXAMPLE'),
    ('direct knowledge', 'RELATION', 'BOUNDARY_EXAMPLE'),
    -- generic provenance requirement
    ('provenance', 'PROVENANCE', 'FULL_CHAIN'),
    ('what source supports', 'PROVENANCE', 'FULL_CHAIN'),
    ('supported by sources', 'PROVENANCE', 'FULL_CHAIN'),
    ('source-backed', 'PROVENANCE', 'FULL_CHAIN');

-- Generic non-anchor vocabulary: function words plus knowledge-architecture concept words. They
-- describe how a question is asked, not which body of knowledge it concerns, so they are never used
-- as concept anchors against persisted labels.
CREATE TEMP TABLE p35_generic_term (term text PRIMARY KEY);
INSERT INTO p35_generic_term (term) VALUES
    ('what'), ('which'), ('who'), ('whom'), ('whose'), ('where'), ('when'), ('does'), ('did'),
    ('are'), ('was'), ('were'), ('have'), ('has'), ('that'), ('this'), ('these'), ('those'),
    ('with'), ('from'), ('into'), ('about'), ('and'), ('the'), ('for'), ('not'), ('never'),
    ('only'), ('rather'), ('than'), ('remain'), ('remains'), ('both'), ('give'), ('show'),
    ('find'), ('said'), ('say'), ('says'), ('behind'), ('including'), ('include'), ('includes'),
    ('chapter'), ('book'), ('explicitly'), ('statement'), ('assertion'), ('beings'), ('people'),
    ('person'), ('persons'), ('entity'), ('entities'), ('canonical'), ('event'), ('events'),
    ('place'), ('places'), ('location'), ('locations'), ('held'), ('took'), ('part'),
    ('source'), ('sources'), ('claim'), ('claims'), ('evidence'), ('evidence-only'),
    ('interpretation'), ('interpretive'), ('provenance'), ('identity'), ('identities'),
    ('source-specific'), ('relationship'), ('relationships'), ('participated'), ('participating'),
    ('participates'), ('located'), ('reconciled'), ('unreconciled'), ('promoted'), ('prove'),
    ('proven'), ('proved'), ('confirmed'), ('directly'), ('direct'), ('example'), ('examples'),
    ('knows'), ('know'), ('knowledge'), ('required'), ('requires'), ('requiring'), ('needing'),
    ('supports'), ('support'), ('supported'), ('source-backed'), ('persisted'), ('trace'),
    ('berean'), ('berean''s'), ('their'), ('there'), ('answer'), ('answers'),
    ('represented'), ('represent'), ('represents'), ('recorded'), ('kept'), ('occurrences');

-- ---------------------------------------------------------------------------
-- 3. Generic semantic interpretation of the natural-language input.
-- ---------------------------------------------------------------------------

-- 3a. Tokenization: purely lexical and domain-neutral. Tokens of at least four characters are
-- stemmed to six characters so morphological variants in question wording and in persisted labels
-- resolve to the same anchor term.
CREATE TEMP TABLE p35_token AS
SELECT DISTINCT
       q.question_key,
       t.tok,
       CASE WHEN length(t.tok) >= 6 THEN left(t.tok, 6) ELSE t.tok END AS stem
FROM p35_question q
CROSS JOIN LATERAL regexp_split_to_table(lower(q.question_text), '[^a-z0-9''-]+') AS t(tok)
WHERE length(t.tok) >= 4
  AND t.tok NOT IN (SELECT term FROM p35_generic_term);

-- 3b. Generic feature extraction from the semantic lexicon. Terms match on word boundaries so that
-- a term is never recognised inside an unrelated word (for example "prove" inside "provenance").
CREATE TEMP TABLE p35_feature AS
SELECT DISTINCT q.question_key, l.feature_kind, l.feature_value
FROM p35_question q
JOIN p35_lexicon l ON lower(q.question_text) ~ ('(^|[^a-z])' || l.term || '($|[^a-z])');

-- 3c. Concept-anchor resolution against persisted Berean labels only.
CREATE TEMP TABLE p35_anchor AS
SELECT DISTINCT question_key, stem AS anchor_term, anchor_kind, anchor_key, anchor_label
FROM (
    SELECT t.question_key, t.stem, 'ENTITY' AS anchor_kind, e.entity_key AS anchor_key,
           e.canonical_name AS anchor_label
    FROM p35_token t
    JOIN entity e ON lower(e.canonical_name) LIKE '%' || t.stem || '%'
    UNION ALL
    SELECT t.question_key, t.stem, 'EVENT', ev.event_key, ev.description
    FROM p35_token t
    JOIN event ev ON lower(coalesce(ev.description, '')) LIKE '%' || t.stem || '%'
                  OR replace(lower(ev.event_key), '_', ' ') LIKE '%' || t.stem || '%'
    UNION ALL
    SELECT t.question_key, t.stem, 'SOURCE', s.source_key, s.name
    FROM p35_token t
    JOIN source s ON lower(s.name) LIKE '%' || t.stem || '%'
                  OR lower(s.source_key) LIKE '%' || t.stem || '%'
    UNION ALL
    SELECT t.question_key, t.stem, 'SOURCE_IDENTITY', si.source_identity_key, si.display_name
    FROM p35_token t
    JOIN source_identity si ON lower(si.display_name) LIKE '%' || t.stem || '%'
) AS resolved;

-- 3c-ii. Anchor specificity. A term that resolves to only a few persisted labels identifies a concept
-- the researcher is asking about; a term that resolves to a large number of labels only delimits the
-- surrounding research scope. The rule is a cardinality heuristic over persisted labels; it is not
-- domain-specific and no term list is privileged.
CREATE TEMP TABLE p35_anchor_role AS
SELECT question_key,
       anchor_term,
       count(*) AS resolved_label_count,
       CASE WHEN count(*) <= 10 THEN 'CONCEPT' ELSE 'SCOPE' END AS anchor_role
FROM p35_anchor
GROUP BY question_key, anchor_term;

-- 3d. Domain-agnostic scope construction. Berean has no Domain table, so a research scope is derived
-- from resolved anchors plus one claim-asserted hop through the persisted graph. A question that
-- resolves no anchors is unscoped and searches the whole persisted substrate.
CREATE TEMP TABLE p35_scope_entity AS
SELECT DISTINCT a.question_key, a.anchor_term, e.entity_id
FROM p35_anchor a
JOIN entity e ON e.entity_key = a.anchor_key AND a.anchor_kind = 'ENTITY'
UNION
SELECT DISTINCT a.question_key, a.anchor_term, coalesce(p.subject_entity_id, p.object_entity_id)
FROM p35_anchor a
JOIN event ev ON ev.event_key = a.anchor_key AND a.anchor_kind = 'EVENT'
JOIN proposition p ON p.subject_event_id = ev.event_id OR p.object_event_id = ev.event_id
JOIN claim c ON c.proposition_id = p.proposition_id
WHERE coalesce(p.subject_entity_id, p.object_entity_id) IS NOT NULL
UNION
SELECT q.question_key, '*'::text, e.entity_id
FROM p35_question q
CROSS JOIN entity e
WHERE NOT EXISTS (SELECT 1 FROM p35_anchor a WHERE a.question_key = q.question_key);

CREATE TEMP TABLE p35_scope_event AS
SELECT DISTINCT a.question_key, a.anchor_term, ev.event_id
FROM p35_anchor a
JOIN event ev ON ev.event_key = a.anchor_key AND a.anchor_kind = 'EVENT'
UNION
SELECT DISTINCT a.question_key, a.anchor_term, coalesce(p.subject_event_id, p.object_event_id)
FROM p35_anchor a
JOIN entity e ON e.entity_key = a.anchor_key AND a.anchor_kind = 'ENTITY'
JOIN proposition p ON p.subject_entity_id = e.entity_id OR p.object_entity_id = e.entity_id
JOIN claim c ON c.proposition_id = p.proposition_id
WHERE coalesce(p.subject_event_id, p.object_event_id) IS NOT NULL
UNION
SELECT q.question_key, '*'::text, ev.event_id
FROM p35_question q
CROSS JOIN event ev
WHERE NOT EXISTS (SELECT 1 FROM p35_anchor a WHERE a.question_key = q.question_key);

CREATE TEMP TABLE p35_scope_source AS
SELECT DISTINCT a.question_key, a.anchor_term, s.source_id
FROM p35_anchor a
JOIN source s ON s.source_key = a.anchor_key AND a.anchor_kind = 'SOURCE'
UNION
SELECT DISTINCT a.question_key, a.anchor_term, si.source_id
FROM p35_anchor a
JOIN source_identity si ON si.source_identity_key = a.anchor_key
                       AND a.anchor_kind = 'SOURCE_IDENTITY'
UNION
SELECT q.question_key, '*'::text, s.source_id
FROM p35_question q
CROSS JOIN source s
WHERE NOT EXISTS (SELECT 1 FROM p35_anchor a WHERE a.question_key = q.question_key);

-- Evidence enters scope through its own source, or because its recorded observation mentions a
-- resolved anchor term. Both routes traverse persisted knowledge; neither is question-specific.
CREATE TEMP TABLE p35_scope_evidence AS
SELECT DISTINCT ss.question_key, ss.anchor_term, e.evidence_id
FROM p35_scope_source ss
JOIN dataset d ON d.source_id = ss.source_id
JOIN source_record sr ON sr.dataset_id = d.dataset_id
JOIN evidence e ON e.source_record_id = sr.source_record_id
UNION
SELECT DISTINCT a.question_key, a.anchor_term, e.evidence_id
FROM p35_anchor a
JOIN evidence e ON lower(e.observation) LIKE '%' || a.anchor_term || '%'
UNION
SELECT DISTINCT se.question_key, se.anchor_term, ce.evidence_id
FROM p35_scope_event se
JOIN proposition p ON p.subject_event_id = se.event_id OR p.object_event_id = se.event_id
JOIN claim c ON c.proposition_id = p.proposition_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id;

-- 3e. Focus scope. Operators that retrieve statements about a concept restrict themselves to the
-- concept anchors; when a question resolves no concept anchor the full derived scope is used.
CREATE TEMP TABLE p35_scope_focus_entity AS
SELECT se.question_key, se.anchor_term, se.entity_id
FROM p35_scope_entity se
LEFT JOIN p35_anchor_role ar
       ON ar.question_key = se.question_key AND ar.anchor_term = se.anchor_term
WHERE coalesce(ar.anchor_role, 'CONCEPT') = 'CONCEPT'
   OR NOT EXISTS (SELECT 1 FROM p35_anchor_role ar2
                  WHERE ar2.question_key = se.question_key AND ar2.anchor_role = 'CONCEPT');

CREATE TEMP TABLE p35_scope_focus_event AS
SELECT se.question_key, se.anchor_term, se.event_id
FROM p35_scope_event se
LEFT JOIN p35_anchor_role ar
       ON ar.question_key = se.question_key AND ar.anchor_term = se.anchor_term
WHERE coalesce(ar.anchor_role, 'CONCEPT') = 'CONCEPT'
   OR NOT EXISTS (SELECT 1 FROM p35_anchor_role ar2
                  WHERE ar2.question_key = se.question_key AND ar2.anchor_role = 'CONCEPT');

CREATE TEMP TABLE p35_scope_focus_evidence AS
SELECT se.question_key, se.anchor_term, se.evidence_id
FROM p35_scope_evidence se
LEFT JOIN p35_anchor_role ar
       ON ar.question_key = se.question_key AND ar.anchor_term = se.anchor_term
WHERE coalesce(ar.anchor_role, 'CONCEPT') = 'CONCEPT'
   OR NOT EXISTS (SELECT 1 FROM p35_anchor_role ar2
                  WHERE ar2.question_key = se.question_key AND ar2.anchor_role = 'CONCEPT');

CREATE TEMP TABLE p35_focus_anchor AS
SELECT ar.question_key, ar.anchor_term
FROM p35_anchor_role ar
WHERE ar.anchor_role = 'CONCEPT'
   OR NOT EXISTS (SELECT 1 FROM p35_anchor_role ar2
                  WHERE ar2.question_key = ar.question_key AND ar2.anchor_role = 'CONCEPT');

-- ---------------------------------------------------------------------------
-- 4. Normalized, inspectable, domain-neutral query plan.
-- ---------------------------------------------------------------------------

CREATE TEMP TABLE p35_plan_base AS
WITH relation AS (
    SELECT f.question_key,
           f.feature_value AS relation_value,
           CASE f.feature_value
               WHEN 'TRUTH_CONFIRMATION' THEN 10
               WHEN 'BOUNDARY_EXAMPLE' THEN 12
               WHEN 'CAPABILITY_INVENTORY' THEN 15
               WHEN 'IDENTITY_RECONCILIATION' THEN 20
               WHEN 'IDENTITY_EQUIVALENCE' THEN 30
               WHEN 'EVIDENCE_CLASSIFICATION' THEN 40
               WHEN 'PROVENANCE' THEN 50
               WHEN 'PARTICIPATION' THEN 60
               WHEN 'ORDERING' THEN 65
               WHEN 'LOCATION' THEN 70
               WHEN 'CONCEPT_IDENTITY' THEN 80
               ELSE 99
           END AS precedence
    FROM p35_feature f
    WHERE f.feature_kind = 'RELATION'
),
chosen AS (
    SELECT DISTINCT ON (question_key) question_key, relation_value
    FROM relation
    ORDER BY question_key, precedence, relation_value
),
composed AS (
    SELECT q.question_key,
           q.question_group,
           q.variant,
           q.question_text,
           CASE
               WHEN c.relation_value = 'PARTICIPATION'
                    AND EXISTS (SELECT 1 FROM relation r
                                WHERE r.question_key = q.question_key
                                  AND r.relation_value = 'LOCATION')
                   THEN 'PARTICIPATION_LOCATION_COMPOSITION'
               ELSE coalesce(c.relation_value, 'UNCLASSIFIED')
           END AS semantic_relationship,
           EXISTS (SELECT 1 FROM p35_feature f
                   WHERE f.question_key = q.question_key
                     AND f.feature_kind = 'TARGET' AND f.feature_value = 'EVENT') AS target_event,
           EXISTS (SELECT 1 FROM p35_feature f
                   WHERE f.question_key = q.question_key
                     AND f.feature_kind = 'PROVENANCE') AS wants_provenance
    FROM p35_question q
    LEFT JOIN chosen c ON c.question_key = q.question_key
)
SELECT
    co.question_key,
    co.question_group,
    co.variant,
    co.question_text,
    co.semantic_relationship,
    CASE co.semantic_relationship
        WHEN 'LOCATION' THEN 'PLACE_SET'
        WHEN 'ORDERING' THEN 'EVENT_ORDER_SET'
        WHEN 'PARTICIPATION' THEN 'AGENT_SET'
        WHEN 'PARTICIPATION_LOCATION_COMPOSITION' THEN
            CASE WHEN co.target_event THEN 'EVENT_SET' ELSE 'AGENT_PLACE_PAIR_SET' END
        WHEN 'CONCEPT_IDENTITY' THEN 'CONCEPT_CANDIDATE_SET'
        WHEN 'IDENTITY_EQUIVALENCE' THEN 'IDENTITY_EQUIVALENCE_STATUS'
        WHEN 'IDENTITY_RECONCILIATION' THEN 'IDENTITY_MAPPING_SET'
        WHEN 'EVIDENCE_CLASSIFICATION' THEN 'EVIDENCE_SET'
        WHEN 'PROVENANCE' THEN 'PROVENANCE_CHAIN'
        WHEN 'TRUTH_CONFIRMATION' THEN 'TRUTH_ASSERTION'
        WHEN 'CAPABILITY_INVENTORY' THEN 'RELATIONSHIP_CAPABILITY_SET'
        WHEN 'BOUNDARY_EXAMPLE' THEN 'KNOWLEDGE_BOUNDARY_EXAMPLE_SET'
        ELSE 'UNDETERMINED'
    END AS semantic_target,
    (SELECT coalesce(array_agg(DISTINCT a.anchor_kind || ':' || a.anchor_key ORDER BY
                               a.anchor_kind || ':' || a.anchor_key), ARRAY[]::text[])
     FROM p35_anchor a WHERE a.question_key = co.question_key) AS semantic_filters,
    (SELECT coalesce(array_agg(DISTINCT ps.predicate_code ORDER BY ps.predicate_code),
                     ARRAY[]::text[])
     FROM p35_predicate_semantics ps
     WHERE ps.semantic_role = ANY (
         CASE co.semantic_relationship
             WHEN 'LOCATION' THEN ARRAY['LOCATION']
             WHEN 'ORDERING' THEN ARRAY['ORDERING']
             WHEN 'PARTICIPATION' THEN ARRAY['PARTICIPATION']
             WHEN 'PARTICIPATION_LOCATION_COMPOSITION' THEN ARRAY['PARTICIPATION', 'LOCATION']
             ELSE ARRAY[]::text[]
         END)) AS candidate_predicates,
    CASE co.semantic_relationship
        WHEN 'LOCATION' THEN 'Claim->Proposition(LOCATION predicate)->Entity'
        WHEN 'ORDERING' THEN 'Claim->Proposition(ORDERING predicate)->Event'
        WHEN 'PARTICIPATION' THEN 'Claim->Proposition(PARTICIPATION predicate)->Event'
        WHEN 'PARTICIPATION_LOCATION_COMPOSITION'
            THEN 'Claim->Proposition(PARTICIPATION)->Event<-Proposition(LOCATION)->Entity'
        WHEN 'CONCEPT_IDENTITY'
            THEN 'Evidence->EvidenceCitation->Citation->SourceRecord->Dataset->Source'
        WHEN 'IDENTITY_EQUIVALENCE' THEN 'SourceIdentity->EntitySourceMapping->Entity (cross-source)'
        WHEN 'IDENTITY_RECONCILIATION' THEN 'SourceIdentity->EntitySourceMapping(status)->Entity'
        WHEN 'EVIDENCE_CLASSIFICATION' THEN 'Evidence->[ClaimEvidence]->Claim'
        WHEN 'PROVENANCE'
            THEN 'Claim->ClaimEvidence->Evidence->EvidenceCitation->Citation->SourceRecord->Dataset->Source'
        WHEN 'TRUTH_CONFIRMATION' THEN 'NONE'
        WHEN 'CAPABILITY_INVENTORY'
            THEN 'Predicate registry x claim-asserted propositions x evidence classification'
        WHEN 'BOUNDARY_EXAMPLE'
            THEN 'Claim->...->Source (direct) | Evidence(ANALYTICAL_OBSERVATION)->...->Source (interpretive)'
        ELSE 'NONE'
    END AS traversal_shape,
    CASE co.semantic_relationship
        WHEN 'EVIDENCE_CLASSIFICATION' THEN ARRAY['CLAIM_LINKAGE=NONE']
        WHEN 'IDENTITY_RECONCILIATION' THEN ARRAY['MAPPING_STATUS<>ACTIVE']
        WHEN 'CONCEPT_IDENTITY' THEN ARRAY['NO_SINGLE_CANDIDATE_SELECTION']
        WHEN 'IDENTITY_EQUIVALENCE' THEN ARRAY['NO_INVENTED_EQUIVALENCE']
        WHEN 'TRUTH_CONFIRMATION' THEN ARRAY['NO_INVENTED_PREDICATE']
        ELSE ARRAY[]::text[]
    END AS output_constraints,
    CASE
        WHEN co.semantic_relationship IN ('PROVENANCE', 'BOUNDARY_EXAMPLE') THEN 'FULL_CHAIN'
        WHEN co.semantic_relationship = 'TRUTH_CONFIRMATION' THEN 'NOT_APPLICABLE'
        WHEN co.wants_provenance THEN 'FULL_CHAIN'
        ELSE 'SOURCE_ATTRIBUTION'
    END AS provenance_requirement,
    'BEREAN_ONLY'::text AS retrieval_scope
FROM composed co;

-- ---------------------------------------------------------------------------
-- 5. Capability check, performed before any answer is produced.
--
-- Every branch is computed from the predicate registry, the schema's representation mechanisms and
-- the scoped persisted graph. No branch is keyed to a question, a domain or an expected answer.
-- ---------------------------------------------------------------------------

CREATE TEMP TABLE p35_plan AS
WITH support AS (
    SELECT b.question_key,
           EXISTS (
               SELECT 1
               FROM claim c
               JOIN proposition p ON p.proposition_id = c.proposition_id
               JOIN p35_scope_entity se ON se.question_key = b.question_key
                                       AND se.entity_id IN (p.subject_entity_id, p.object_entity_id)
               WHERE p.predicate = ANY (b.candidate_predicates)
           ) OR EXISTS (
               SELECT 1
               FROM claim c
               JOIN proposition p ON p.proposition_id = c.proposition_id
               JOIN p35_scope_event sv ON sv.question_key = b.question_key
                                      AND sv.event_id IN (p.subject_event_id, p.object_event_id)
               WHERE p.predicate = ANY (b.candidate_predicates)
           ) AS direct_rows,
           EXISTS (
               SELECT 1
               FROM p35_scope_evidence sev
               JOIN evidence e ON e.evidence_id = sev.evidence_id
               WHERE sev.question_key = b.question_key
                 AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
                 AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
           ) AS scholarly_rows,
           EXISTS (
               SELECT 1 FROM p35_scope_evidence sev WHERE sev.question_key = b.question_key
           ) AS evidence_rows,
           EXISTS (
               SELECT 1
               FROM claim c
               JOIN proposition p ON p.proposition_id = c.proposition_id
               JOIN claim_evidence ce ON ce.claim_id = c.claim_id
               JOIN evidence_citation ec ON ec.evidence_id = ce.evidence_id
               JOIN p35_scope_entity se ON se.question_key = b.question_key
                                       AND se.entity_id IN (p.subject_entity_id, p.object_entity_id)
           ) AS provenance_rows,
           EXISTS (
               SELECT 1
               FROM entity_source_mapping esm
               JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
               JOIN p35_scope_source ss ON ss.question_key = b.question_key
                                       AND ss.source_id = si.source_id
               WHERE esm.mapping_status_code <> 'ACTIVE'
           ) AS unreconciled_rows,
           EXISTS (
               SELECT 1
               FROM claim cpart
               JOIN proposition ppart ON ppart.proposition_id = cpart.proposition_id
               JOIN p35_predicate_semantics psp ON psp.predicate_code = ppart.predicate
                                               AND psp.semantic_role = 'PARTICIPATION'
               JOIN proposition ploc ON ploc.subject_event_id = ppart.object_event_id
               JOIN p35_predicate_semantics psl ON psl.predicate_code = ploc.predicate
                                               AND psl.semantic_role = 'LOCATION'
               JOIN claim cloc ON cloc.proposition_id = ploc.proposition_id
               JOIN p35_scope_event sv ON sv.question_key = b.question_key
                                      AND sv.event_id = ppart.object_event_id
           ) AS composed_rows,
           EXISTS (
               SELECT 1
               FROM entity_source_mapping esm1
               JOIN source_identity si1 ON si1.source_identity_id = esm1.source_identity_id
               JOIN entity_source_mapping esm2 ON esm2.entity_id = esm1.entity_id
               JOIN source_identity si2 ON si2.source_identity_id = esm2.source_identity_id
                                       AND si2.source_id <> si1.source_id
               JOIN p35_scope_source ss1 ON ss1.question_key = b.question_key
                                        AND ss1.source_id = si1.source_id
               JOIN p35_scope_source ss2 ON ss2.question_key = b.question_key
                                        AND ss2.source_id = si2.source_id
               JOIN p35_anchor a1 ON a1.question_key = b.question_key
                                 AND lower(si1.display_name) LIKE '%' || a1.anchor_term || '%'
               JOIN p35_anchor a2 ON a2.question_key = b.question_key
                                 AND lower(si2.display_name) LIKE '%' || a2.anchor_term || '%'
               WHERE esm1.mapping_status_code = 'ACTIVE'
                 AND esm2.mapping_status_code = 'ACTIVE'
           ) AS shared_identity_rows
    FROM p35_plan_base b
)
SELECT b.*,
       CASE
           -- no registered predicate and no schema mechanism represents the requested relation
           WHEN b.semantic_relationship IN ('TRUTH_CONFIRMATION', 'UNCLASSIFIED') THEN 'NOT_REPRESENTED'
           -- equivalence is representable only by reconciliation to a shared canonical entity;
           -- the absence of such a representation is unresolved, never false
           WHEN b.semantic_relationship = 'IDENTITY_EQUIVALENCE' THEN
               CASE WHEN s.shared_identity_rows THEN 'ESTABLISHED' ELSE 'UNRESOLVED' END
           WHEN b.semantic_relationship = 'IDENTITY_RECONCILIATION' THEN
               CASE WHEN s.unreconciled_rows THEN 'ESTABLISHED' ELSE 'NOT_REPRESENTED' END
           WHEN b.semantic_relationship = 'EVIDENCE_CLASSIFICATION' THEN
               CASE WHEN s.evidence_rows THEN 'ESTABLISHED' ELSE 'NOT_REPRESENTED' END
           WHEN b.semantic_relationship = 'PROVENANCE' THEN
               CASE WHEN s.provenance_rows THEN 'ESTABLISHED' ELSE 'NOT_REPRESENTED' END
           WHEN b.semantic_relationship = 'CONCEPT_IDENTITY' THEN
               CASE WHEN s.scholarly_rows THEN 'SCHOLARLY_CANDIDATE' ELSE 'UNRESOLVED' END
           WHEN b.semantic_relationship = 'PARTICIPATION_LOCATION_COMPOSITION' THEN
               CASE WHEN s.composed_rows THEN 'DERIVABLE' ELSE 'NOT_REPRESENTED' END
           WHEN b.semantic_relationship IN ('CAPABILITY_INVENTORY', 'BOUNDARY_EXAMPLE') THEN
               CASE WHEN s.direct_rows OR s.scholarly_rows OR s.evidence_rows
                    THEN 'DERIVABLE' ELSE 'NOT_REPRESENTED' END
           WHEN s.direct_rows THEN 'ESTABLISHED'
           WHEN s.scholarly_rows THEN 'SCHOLARLY_CANDIDATE'
           ELSE 'NOT_REPRESENTED'
       END AS capability_status,
       CASE
           WHEN b.semantic_relationship IN ('TRUTH_CONFIRMATION', 'UNCLASSIFIED') THEN
               'No registered predicate and no schema mechanism represents the requested relation; '
               || 'absence of representation is not a denial.'
           WHEN b.semantic_relationship = 'IDENTITY_EQUIVALENCE' AND NOT s.shared_identity_rows THEN
               'Identity is represented per source; no reconciliation links the scoped source '
               || 'identities to one canonical entity, so equivalence stays unresolved.'
           WHEN b.semantic_relationship = 'CONCEPT_IDENTITY' AND s.scholarly_rows THEN
               'No claim-asserted proposition identifies the concept; scoped analytical observations '
               || 'supply competing candidates that are not promoted to claims.'
           WHEN b.semantic_relationship = 'PARTICIPATION_LOCATION_COMPOSITION' AND s.composed_rows THEN
               'Answer requires composing registered predicate roles over claim-asserted propositions.'
           WHEN b.semantic_relationship IN ('CAPABILITY_INVENTORY', 'BOUNDARY_EXAMPLE') THEN
               'Answer is derived by inspecting registry coverage and persisted classification '
               || 'boundaries in the resolved scope.'
           WHEN s.direct_rows OR s.provenance_rows OR s.evidence_rows OR s.unreconciled_rows THEN
               'Requested relation is registered and instantiated in the scoped persisted graph.'
           ELSE 'The scoped persisted graph contains no representation of the requested relation.'
       END AS capability_reason
FROM p35_plan_base b
JOIN support s ON s.question_key = b.question_key;

-- ---------------------------------------------------------------------------
-- 6. Domain-agnostic retrieval operators.
--
-- Each operator is selected by the normalized plan's semantic relationship, is parameterized by the
-- plan's scope and registry-resolved predicates, and emits one uniform transient answer shape:
--   (question_key, operator, result_key, result_label, result_classification, provenance_chain)
-- ---------------------------------------------------------------------------

-- Shared provenance resolution:
-- Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source
CREATE TEMP VIEW p35_claim_provenance AS
SELECT c.claim_id,
       c.claim_key,
       e.evidence_key,
       e.evidence_type_code,
       ce.relation_type_code,
       ci.citation_key,
       ci.locator,
       sr.source_record_key,
       d.dataset_key,
       s.source_key,
       s.source_id
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id;

-- Operator 1: single registered predicate over claim-asserted propositions, restricted to scope.
CREATE TEMP VIEW p35_op_single_predicate AS
SELECT pl.question_key,
       'DIRECT_PREDICATE'::text AS operator,
       c.claim_key AS result_key,
       cr.rendered_proposition AS result_label,
       'DIRECTLY_SUPPORTED'::text AS result_classification,
       (SELECT string_agg('Claim ' || pv.claim_key || ' -> Evidence ' || pv.evidence_key
                          || ' -> Citation ' || pv.citation_key || ' (' || pv.locator || ')'
                          || ' -> SourceRecord ' || pv.source_record_key
                          || ' -> Dataset ' || pv.dataset_key || ' -> Source ' || pv.source_key, '; '
                          ORDER BY pv.evidence_key, pv.citation_key)
        FROM p35_claim_provenance pv WHERE pv.claim_id = c.claim_id) AS provenance_chain
FROM p35_plan pl
JOIN claim c ON true
JOIN proposition p ON p.proposition_id = c.proposition_id
                  AND p.predicate = ANY (pl.candidate_predicates)
JOIN claim_rendering cr ON cr.claim_id = c.claim_id
WHERE pl.semantic_relationship IN ('LOCATION', 'PARTICIPATION', 'ORDERING')
  AND pl.capability_status = 'ESTABLISHED'
  AND EXISTS (SELECT 1 FROM p35_claim_provenance pv WHERE pv.claim_id = c.claim_id)
  AND (
        EXISTS (SELECT 1 FROM p35_scope_focus_entity se
                WHERE se.question_key = pl.question_key
                  AND se.entity_id IN (p.subject_entity_id, p.object_entity_id))
     OR EXISTS (SELECT 1 FROM p35_scope_focus_event sv
                WHERE sv.question_key = pl.question_key
                  AND sv.event_id IN (p.subject_event_id, p.object_event_id))
      );

-- Operator 2: composition of two registered predicate roles (participation, then location).
CREATE TEMP VIEW p35_op_composition AS
SELECT pl.question_key,
       'PREDICATE_COMPOSITION'::text AS operator,
       CASE WHEN pl.semantic_target = 'EVENT_SET'
            THEN ev.event_key
            ELSE agent.entity_key || ' @ ' || ev.event_key END AS result_key,
       CASE WHEN pl.semantic_target = 'EVENT_SET'
            THEN ev.event_key || ' [participants: '
                 || (SELECT string_agg(DISTINCT a2.canonical_name, ', ')
                     FROM claim c2
                     JOIN proposition p2 ON p2.proposition_id = c2.proposition_id
                     JOIN p35_predicate_semantics ps2 ON ps2.predicate_code = p2.predicate
                                                     AND ps2.semantic_role = 'PARTICIPATION'
                     JOIN entity a2 ON a2.entity_id = p2.subject_entity_id
                     WHERE p2.object_event_id = ev.event_id)
                 || '] [location: ' || place.canonical_name || ']'
            ELSE agent.canonical_name || ' ' || ppart.predicate || ' ' || ev.event_key
                 || ' ' || ploc.predicate || ' ' || place.canonical_name END AS result_label,
       'DERIVED_FROM_PERSISTED_GRAPH'::text AS result_classification,
       (SELECT string_agg(DISTINCT 'Claim ' || pv.claim_key || ' -> Evidence ' || pv.evidence_key
                          || ' -> Citation ' || pv.citation_key || ' -> Source ' || pv.source_key, '; ')
        FROM p35_claim_provenance pv
        WHERE (pl.semantic_target = 'EVENT_SET'
               AND pv.claim_id IN (
                   SELECT cany.claim_id
                   FROM claim cany
                   JOIN proposition pany ON pany.proposition_id = cany.proposition_id
                   JOIN p35_predicate_semantics psany ON psany.predicate_code = pany.predicate
                   WHERE (psany.semantic_role = 'PARTICIPATION' AND pany.object_event_id = ev.event_id)
                      OR (psany.semantic_role = 'LOCATION' AND pany.subject_event_id = ev.event_id)))
           OR (pl.semantic_target <> 'EVENT_SET'
               AND pv.claim_id IN (cpart.claim_id, cloc.claim_id))) AS provenance_chain
FROM p35_plan pl
JOIN claim cpart ON true
JOIN proposition ppart ON ppart.proposition_id = cpart.proposition_id
JOIN p35_predicate_semantics psp ON psp.predicate_code = ppart.predicate
                                AND psp.semantic_role = 'PARTICIPATION'
JOIN entity agent ON agent.entity_id = ppart.subject_entity_id
JOIN event ev ON ev.event_id = ppart.object_event_id
JOIN proposition ploc ON ploc.subject_event_id = ev.event_id
JOIN p35_predicate_semantics psl ON psl.predicate_code = ploc.predicate
                                AND psl.semantic_role = 'LOCATION'
JOIN claim cloc ON cloc.proposition_id = ploc.proposition_id
JOIN entity place ON place.entity_id = ploc.object_entity_id
JOIN p35_scope_event sv ON sv.question_key = pl.question_key AND sv.event_id = ev.event_id
WHERE pl.semantic_relationship = 'PARTICIPATION_LOCATION_COMPOSITION'
  AND pl.capability_status = 'DERIVABLE'
  AND (pl.semantic_target <> 'AGENT_PLACE_PAIR_SET' OR agent.entity_type_code = 'PERSON')
  AND EXISTS (SELECT 1 FROM p35_claim_provenance pv WHERE pv.claim_id = cpart.claim_id)
  AND EXISTS (SELECT 1 FROM p35_claim_provenance pv WHERE pv.claim_id = cloc.claim_id);

-- Operator 3: provenance chain for the scoped claims with maximal anchor coverage.
CREATE TEMP VIEW p35_op_provenance AS
WITH scoped_claim AS (
    SELECT pl.question_key,
           c.claim_id,
           c.claim_key,
           (SELECT count(DISTINCT se.anchor_term)
            FROM p35_scope_focus_entity se
            WHERE se.question_key = pl.question_key
              AND se.entity_id IN (p.subject_entity_id, p.object_entity_id)) AS anchor_coverage
    FROM p35_plan pl
    JOIN claim c ON true
    JOIN proposition p ON p.proposition_id = c.proposition_id
    WHERE pl.semantic_relationship = 'PROVENANCE'
      AND pl.capability_status = 'ESTABLISHED'
),
best AS (
    SELECT question_key, max(anchor_coverage) AS max_coverage
    FROM scoped_claim
    GROUP BY question_key
)
SELECT sc.question_key,
       'PROVENANCE_CHAIN'::text AS operator,
       sc.claim_key AS result_key,
       cr.rendered_proposition || ' [' || pv.evidence_type_code || '/' || pv.relation_type_code || ']'
           AS result_label,
       'DIRECTLY_SUPPORTED'::text AS result_classification,
       'Claim ' || pv.claim_key || ' -> ClaimEvidence ' || pv.relation_type_code
       || ' -> Evidence ' || pv.evidence_key || ' -> EvidenceCitation -> Citation ' || pv.citation_key
       || ' (' || pv.locator || ') -> SourceRecord ' || pv.source_record_key
       || ' -> Dataset ' || pv.dataset_key || ' -> Source ' || pv.source_key AS provenance_chain
FROM scoped_claim sc
JOIN best b ON b.question_key = sc.question_key AND b.max_coverage = sc.anchor_coverage
JOIN claim_rendering cr ON cr.claim_id = sc.claim_id
JOIN p35_claim_provenance pv ON pv.claim_id = sc.claim_id
WHERE sc.anchor_coverage > 0;

-- Operator 4: interpretive candidates for a concept whose identity is not claim-asserted.
CREATE TEMP VIEW p35_op_interpretive_candidates AS
SELECT pl.question_key,
       'INTERPRETIVE_CANDIDATES'::text AS operator,
       e.evidence_key AS result_key,
       e.observation AS result_label,
       CASE WHEN e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
            THEN 'SCHOLARLY_CANDIDATE'
            ELSE 'EVIDENCE_ONLY_NOT_CLAIM' END AS result_classification,
       'Evidence ' || e.evidence_key || ' -> Citation ' || ci.citation_key
       || ' (' || ci.locator || ') -> SourceRecord ' || sr.source_record_key
       || ' -> Dataset ' || d.dataset_key || ' -> Source ' || s.source_key
       || ' [no claim promotion]' AS provenance_chain
FROM p35_plan pl
JOIN p35_scope_focus_evidence sev ON sev.question_key = pl.question_key
JOIN evidence e ON e.evidence_id = sev.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE pl.semantic_relationship = 'CONCEPT_IDENTITY'
  AND pl.capability_status = 'SCHOLARLY_CANDIDATE'
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
  AND EXISTS (SELECT 1 FROM p35_focus_anchor a
              WHERE a.question_key = pl.question_key
                AND lower(e.observation) LIKE '%' || a.anchor_term || '%');

-- Operator 5: evidence/claim boundary classification.
CREATE TEMP VIEW p35_op_evidence_classification AS
SELECT pl.question_key,
       'EVIDENCE_CLASSIFICATION'::text AS operator,
       e.evidence_key AS result_key,
       e.evidence_type_code || ': ' || e.observation AS result_label,
       'EVIDENCE_ONLY_NOT_CLAIM'::text AS result_classification,
       'Evidence ' || e.evidence_key || ' -> Citation ' || ci.citation_key
       || ' -> SourceRecord ' || sr.source_record_key || ' -> Dataset ' || d.dataset_key
       || ' -> Source ' || s.source_key || ' [ClaimEvidence: none]' AS provenance_chain
FROM p35_plan pl
JOIN p35_scope_focus_evidence sev ON sev.question_key = pl.question_key
JOIN evidence e ON e.evidence_id = sev.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE pl.semantic_relationship = 'EVIDENCE_CLASSIFICATION'
  AND pl.capability_status = 'ESTABLISHED'
  AND 'CLAIM_LINKAGE=NONE' = ANY (pl.output_constraints)
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id);

-- Operator 6: cross-source identity equivalence status; never invents an equivalence assertion.
CREATE TEMP VIEW p35_op_identity_equivalence AS
SELECT pl.question_key,
       'IDENTITY_EQUIVALENCE'::text AS operator,
       s.source_key || ' / ' || si.source_identity_key AS result_key,
       'Source identity "' || si.display_name || '" in source ' || s.source_key
       || coalesce(' -> canonical entity ' || ent.entity_key || ' [' || esm.mapping_status_code || ']',
                   ' -> no canonical mapping') AS result_label,
       'UNRESOLVED_IDENTITY'::text AS result_classification,
       'SourceIdentity ' || si.source_identity_key || ' -> Source ' || s.source_key
       || ' [no cross-source equivalence representation]' AS provenance_chain
FROM p35_plan pl
JOIN p35_scope_source ss ON ss.question_key = pl.question_key
JOIN source s ON s.source_id = ss.source_id
JOIN source_identity si ON si.source_id = s.source_id
LEFT JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
LEFT JOIN entity ent ON ent.entity_id = esm.entity_id
WHERE pl.semantic_relationship = 'IDENTITY_EQUIVALENCE'
  AND pl.capability_status = 'UNRESOLVED'
  AND EXISTS (SELECT 1 FROM p35_focus_anchor a
              WHERE a.question_key = pl.question_key
                AND lower(si.display_name) LIKE '%' || a.anchor_term || '%')
UNION ALL
SELECT pl.question_key,
       'IDENTITY_EQUIVALENCE'::text,
       s.source_key || ' / ' || e.evidence_key,
       'Source observation retained without equivalence assertion: ' || e.observation,
       'EVIDENCE_ONLY_NOT_CLAIM'::text,
       'Evidence ' || e.evidence_key || ' -> Citation ' || ci.citation_key
       || ' (' || ci.locator || ') -> Source ' || s.source_key
FROM p35_plan pl
JOIN p35_scope_focus_evidence sev ON sev.question_key = pl.question_key
JOIN evidence e ON e.evidence_id = sev.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE pl.semantic_relationship = 'IDENTITY_EQUIVALENCE'
  AND pl.capability_status = 'UNRESOLVED'
  AND EXISTS (SELECT 1 FROM p35_focus_anchor a
              WHERE a.question_key = pl.question_key
                AND lower(e.observation) LIKE '%' || a.anchor_term || '%');

-- Operator 7: unreconciled source identities, retrieved without activation.
CREATE TEMP VIEW p35_op_identity_reconciliation AS
SELECT pl.question_key,
       'IDENTITY_RECONCILIATION'::text AS operator,
       si.source_identity_key AS result_key,
       'Source identity "' || si.display_name || '" (' || s.source_key || ')'
       || coalesce(' proposed for canonical entity ' || ent.entity_key, ' with no proposed entity')
       || ' [' || coalesce(esm.mapping_status_code, 'NO_MAPPING') || ']' AS result_label,
       'UNRESOLVED_IDENTITY'::text AS result_classification,
       'SourceIdentity ' || si.source_identity_key || ' -> EntitySourceMapping '
       || coalesce(esm.mapping_status_code, 'NO_MAPPING') || ' -> Source ' || s.source_key
           AS provenance_chain
FROM p35_plan pl
JOIN p35_scope_source ss ON ss.question_key = pl.question_key
JOIN source s ON s.source_id = ss.source_id
JOIN source_identity si ON si.source_id = s.source_id
LEFT JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
LEFT JOIN entity ent ON ent.entity_id = esm.entity_id
WHERE pl.semantic_relationship = 'IDENTITY_RECONCILIATION'
  AND pl.capability_status = 'ESTABLISHED'
  AND 'MAPPING_STATUS<>ACTIVE' = ANY (pl.output_constraints)
  AND NOT EXISTS (
      SELECT 1 FROM entity_source_mapping active
      WHERE active.source_identity_id = si.source_identity_id
        AND active.mapping_status_code = 'ACTIVE');

-- Operator 8: relationship capability inventory per resolved scope group.
CREATE TEMP VIEW p35_op_capability_inventory AS
SELECT pl.question_key,
       'CAPABILITY_INVENTORY'::text AS operator,
       scope.anchor_term || ' / ' || ps.semantic_role || ' / ' || p.predicate AS result_key,
       'Scope "' || scope.anchor_term || '": relationship role ' || ps.semantic_role
       || ' is claim-asserted via predicate ' || p.predicate
       || ' (' || count(DISTINCT c.claim_id)::text || ' claim(s))' AS result_label,
       'DIRECTLY_SUPPORTED'::text AS result_classification,
       'PredicateRegistry ' || p.predicate
       || ' -> claim-asserted propositions in resolved scope' AS provenance_chain
FROM p35_plan pl
JOIN (
    SELECT question_key, anchor_term, entity_id, NULL::bigint AS event_id FROM p35_scope_entity
    UNION ALL
    SELECT question_key, anchor_term, NULL::bigint, event_id FROM p35_scope_event
) AS scope ON scope.question_key = pl.question_key AND scope.anchor_term <> '*'
JOIN proposition p ON (scope.entity_id IS NOT NULL
                       AND scope.entity_id IN (p.subject_entity_id, p.object_entity_id))
                   OR (scope.event_id IS NOT NULL
                       AND scope.event_id IN (p.subject_event_id, p.object_event_id))
JOIN claim c ON c.proposition_id = p.proposition_id
JOIN p35_predicate_semantics ps ON ps.predicate_code = p.predicate
WHERE pl.semantic_relationship = 'CAPABILITY_INVENTORY'
  AND pl.capability_status = 'DERIVABLE'
GROUP BY pl.question_key, scope.anchor_term, ps.semantic_role, p.predicate
UNION ALL
SELECT pl.question_key,
       'CAPABILITY_INVENTORY'::text,
       sev.anchor_term || ' / INTERPRETIVE / ' || s.source_key,
       'Scope "' || sev.anchor_term || '": ' || count(DISTINCT e.evidence_id)::text
       || ' analytical observation(s) from source ' || s.source_key
       || ' remain interpretive and are not claim-asserted',
       'INTERPRETIVE_ONLY'::text,
       'Evidence(ANALYTICAL_OBSERVATION) -> Source ' || s.source_key || ' [no ClaimEvidence]'
FROM p35_plan pl
JOIN p35_scope_evidence sev ON sev.question_key = pl.question_key AND sev.anchor_term <> '*'
JOIN evidence e ON e.evidence_id = sev.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE pl.semantic_relationship = 'CAPABILITY_INVENTORY'
  AND pl.capability_status = 'DERIVABLE'
  AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
GROUP BY pl.question_key, sev.anchor_term, s.source_key;

-- Operator 9: dynamically selected knowledge-boundary examples per resolved scope group.
CREATE TEMP VIEW p35_op_boundary_example AS
WITH direct_candidate AS (
    SELECT DISTINCT ON (pl.question_key, scope.anchor_term)
           pl.question_key,
           scope.anchor_term,
           c.claim_key,
           cr.rendered_proposition,
           pv.evidence_key,
           pv.citation_key,
           pv.locator,
           pv.source_record_key,
           pv.dataset_key,
           pv.source_key
    FROM p35_plan pl
    JOIN (
        SELECT question_key, anchor_term, entity_id, NULL::bigint AS event_id FROM p35_scope_entity
        UNION ALL
        SELECT question_key, anchor_term, NULL::bigint, event_id FROM p35_scope_event
    ) AS scope ON scope.question_key = pl.question_key AND scope.anchor_term <> '*'
    JOIN proposition p ON (scope.entity_id IS NOT NULL
                           AND scope.entity_id IN (p.subject_entity_id, p.object_entity_id))
                       OR (scope.event_id IS NOT NULL
                           AND scope.event_id IN (p.subject_event_id, p.object_event_id))
    JOIN claim c ON c.proposition_id = p.proposition_id
    JOIN claim_rendering cr ON cr.claim_id = c.claim_id
    JOIN p35_claim_provenance pv ON pv.claim_id = c.claim_id
    WHERE pl.semantic_relationship = 'BOUNDARY_EXAMPLE'
      AND pl.capability_status = 'DERIVABLE'
    ORDER BY pl.question_key, scope.anchor_term, c.claim_key, pv.evidence_key, pv.citation_key
),
interpretive_candidate AS (
    SELECT DISTINCT ON (pl.question_key, sev.anchor_term)
           pl.question_key,
           sev.anchor_term,
           e.evidence_key,
           e.observation,
           ci.citation_key,
           ci.locator,
           sr.source_record_key,
           d.dataset_key,
           s.source_key
    FROM p35_plan pl
    JOIN p35_scope_evidence sev ON sev.question_key = pl.question_key AND sev.anchor_term <> '*'
    JOIN evidence e ON e.evidence_id = sev.evidence_id
    JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
    JOIN citation ci ON ci.citation_id = ec.citation_id
    JOIN source_record sr ON sr.source_record_id = ci.source_record_id
    JOIN dataset d ON d.dataset_id = sr.dataset_id
    JOIN source s ON s.source_id = d.source_id
    WHERE pl.semantic_relationship = 'BOUNDARY_EXAMPLE'
      AND pl.capability_status = 'DERIVABLE'
      AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
      AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
    ORDER BY pl.question_key, sev.anchor_term, e.evidence_key, ci.citation_key
)
SELECT question_key,
       'BOUNDARY_EXAMPLE'::text AS operator,
       anchor_term || ' / DIRECT' AS result_key,
       'Scope "' || anchor_term || '" knows directly: ' || rendered_proposition AS result_label,
       'DIRECTLY_SUPPORTED'::text AS result_classification,
       'Claim ' || claim_key || ' -> Evidence ' || evidence_key || ' -> Citation ' || citation_key
       || ' (' || locator || ') -> SourceRecord ' || source_record_key
       || ' -> Dataset ' || dataset_key || ' -> Source ' || source_key AS provenance_chain
FROM direct_candidate
UNION ALL
SELECT question_key,
       'BOUNDARY_EXAMPLE'::text,
       anchor_term || ' / INTERPRETIVE',
       'Scope "' || anchor_term || '" requires interpretation: ' || observation,
       'SCHOLARLY_CANDIDATE'::text,
       'Evidence ' || evidence_key || ' -> Citation ' || citation_key || ' (' || locator
       || ') -> SourceRecord ' || source_record_key || ' -> Dataset ' || dataset_key
       || ' -> Source ' || source_key || ' [no claim promotion]'
FROM interpretive_candidate;

-- ---------------------------------------------------------------------------
-- 7. Unified transient answer object.
--
-- A question whose capability check does not establish a supported relation yields a controlled
-- limitation row instead of fabricated content.
-- ---------------------------------------------------------------------------

-- UNION (not UNION ALL) so that a knowledge object reached through several resolved anchors is
-- reported once; answers are sets of retrieved knowledge, not traversal tallies.
CREATE TEMP VIEW p35_answer AS
SELECT * FROM p35_op_single_predicate
UNION
SELECT * FROM p35_op_composition
UNION
SELECT * FROM p35_op_provenance
UNION
SELECT * FROM p35_op_interpretive_candidates
UNION
SELECT * FROM p35_op_evidence_classification
UNION
SELECT * FROM p35_op_identity_equivalence
UNION
SELECT * FROM p35_op_identity_reconciliation
UNION
SELECT * FROM p35_op_capability_inventory
UNION
SELECT * FROM p35_op_boundary_example
UNION
SELECT pl.question_key,
       'CONTROLLED_LIMITATION'::text,
       pl.semantic_relationship || ' / ' || pl.capability_status,
       pl.capability_reason,
       pl.capability_status,
       'NONE [BEREAN_ONLY; no external supplementation]'::text
FROM p35_plan pl
WHERE pl.capability_status = 'NOT_REPRESENTED';
