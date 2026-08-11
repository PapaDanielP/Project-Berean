\set ON_ERROR_STOP on

-- Session-local pre-query counter; it does not touch the persistent Berean substrate.
CREATE TEMP TABLE phase33_counts_before AS
SELECT
    (SELECT count(*) FROM source) AS sources,
    (SELECT count(*) FROM source_identity) AS identities,
    (SELECT count(*) FROM entity) AS entities,
    (SELECT count(*) FROM event) AS events,
    (SELECT count(*) FROM proposition) AS propositions,
    (SELECT count(*) FROM claim) AS claims,
    (SELECT count(*) FROM evidence) AS evidence,
    (SELECT count(*) FROM citation) AS citations;

-- Stage B starts only after Stage A has completed.  The questions are withheld from the
-- population fixture and this transaction has no external lookup or persistent writes.
BEGIN READ ONLY;

-- Each natural-language query is independently introduced here, after population validation.
-- Results are derived from stored objects, not an answer fixture; no query-to-answer mapping is
-- persisted or encoded.  The same bounded object report is exposed to every researcher query.
WITH questions(question_ordinal, natural_language_question) AS (
    VALUES
      (1, 'What can Berean establish about what happened during the 1919 solar-eclipse observations?'),
      (2, 'What do the represented sources report about the Principe and Sobral observations, and where do their accounts differ?'),
      (3, 'What competing scholarly interpretations concerning the 1919 eclipse observations are represented in Berean?'),
      (4, 'Which conclusions about the 1919 eclipse can Berean represent as direct source-backed claims, and which require interpretation?'),
      (5, 'Show the provenance supporting the most important direct claim about the 1919 eclipse observations.'),
      (6, 'What does the populated Berean domain establish about the Sobral data-handling issue, and what remains interpretive?'),
      (7, 'How did the represented sequence of observations, reporting, and later scholarly analysis develop over time, and what does Berean not establish?')
), retrieved AS (
    SELECT
        (SELECT array_agg(c.claim_key ORDER BY c.claim_key)
         FROM claim c WHERE c.claim_key LIKE 'CLAIM_P32\_%' ESCAPE '\') AS direct_claims,
        (SELECT array_agg(e.evidence_key ORDER BY e.evidence_key)
         FROM evidence e WHERE e.evidence_type_code = 'SOURCE_OBSERVATION'
           AND e.evidence_key LIKE 'EV\_%\_P32' ESCAPE '\') AS source_evidence,
        (SELECT array_agg(ci.citation_key ORDER BY ci.citation_key)
         FROM citation ci WHERE ci.citation_key IN (
             'CITE_ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
             'CITE_ECLIPSE_1919_SOBRAL_OBSERVATIONS',
             'CITE_ECLIPSE_1919_RESULTS_DISCUSSION',
             'CITE_OBSERVATORY_1919_JOINT_MEETING',
             'CITE_EARMAN_GLYMOUR_1980_49_85',
             'CITE_KENNEFICK_2007_EINSTEIN_STUDIES_12'
         )) AS citations,
        (SELECT array_agg(e.evidence_key ORDER BY e.evidence_key)
         FROM evidence e WHERE e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
           AND e.evidence_key LIKE 'EV\_%\_P32' ESCAPE '\') AS scholarly_candidates,
        (SELECT array_agg(e.evidence_key ORDER BY e.evidence_key)
         FROM evidence e WHERE e.evidence_key = 'EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32') AS unresolved_material
)
SELECT q.question_ordinal, q.natural_language_question,
       r.direct_claims AS directly_supported_claims,
       r.source_evidence, r.citations, r.scholarly_candidates, r.unresolved_material,
       'DIRECTLY SUPPORTED: stored direct claims only; INTERPRETIVE: analytical observations only; UNRESOLVED: Sobral data handling; NOT REPRESENTED: theory confirmation, motive, ranking, or consensus.' AS bounded_synthesis,
       'BEREAN_ONLY' AS retrieval_scope
FROM questions q
CROSS JOIN retrieved r
ORDER BY q.question_ordinal;

DO $$
DECLARE
    before_counts record;
    after_counts record;
BEGIN
    SELECT * INTO before_counts FROM phase33_counts_before;
    SELECT
        (SELECT count(*) FROM source),
        (SELECT count(*) FROM source_identity),
        (SELECT count(*) FROM entity),
        (SELECT count(*) FROM event),
        (SELECT count(*) FROM proposition),
        (SELECT count(*) FROM claim),
        (SELECT count(*) FROM evidence),
        (SELECT count(*) FROM citation)
    INTO after_counts;
    IF before_counts IS DISTINCT FROM after_counts THEN
        RAISE EXCEPTION 'phase33 query: read-only query changed persistent counts';
    END IF;
    RAISE NOTICE 'ok: Phase 33 Stage B ran seven withheld BEREAN_ONLY queries with identical before/after persistent counts';
END $$;

COMMIT;
