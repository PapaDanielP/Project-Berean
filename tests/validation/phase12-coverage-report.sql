\set ON_ERROR_STOP on

\echo 'Phase 12 Genesis 1:22-23 bounded coverage'
WITH verses AS (
    SELECT * FROM (VALUES
        (22, 'MT_GEN_1_22', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED: blessing/multiplication is a SEMANTIC PRECISION GAP'),
        (23, 'MT_GEN_1_23', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED: ordinal-day semantics is a SEMANTIC PRECISION GAP'),
        (24, 'MT_GEN_1_24', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        (25, 'MT_GEN_1_25', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        (26, 'MT_GEN_1_26', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        (27, 'MT_GEN_1_27', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        (28, 'MT_GEN_1_28', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED'),
        (29, 'MT_GEN_1_29', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED'),
        (30, 'MT_GEN_1_30', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED'),
        (31, 'MT_GEN_1_31', 'STRUCTURALLY REPRESENTED', 'SOURCE-BACKED', 'NOT DERIVED',
         'INTENTIONALLY EXCLUDED')
    ) AS v(verse, source_record_key, coverage_status, provenance_status, derivation_status, semantic_status)
)
SELECT v.verse,
       v.source_record_key,
       count(DISTINCT ci.citation_id) AS citations,
       count(DISTINCT e.evidence_id) AS evidence,
       count(DISTINCT c.claim_id) AS claims,
       v.coverage_status,
       v.provenance_status,
       v.derivation_status,
       v.semantic_status
FROM verses v
JOIN source_record sr ON sr.source_record_key = v.source_record_key
LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim c ON c.claim_id = ce.claim_id
GROUP BY v.verse, v.source_record_key, v.coverage_status, v.provenance_status,
         v.derivation_status, v.semantic_status
ORDER BY v.verse;

\echo 'Phase 12 deferred Genesis chapter coverage'
SELECT chapter,
       'SOURCE UNAVAILABLE' AS coverage_status,
       'UNRESOLVED' AS semantic_status,
       'ACQUISITION PENDING' AS acquisition_status
FROM generate_series(2, 11) AS chapter
WHERE chapter IN (2, 3, 4, 6, 7, 9, 10, 11)
ORDER BY chapter;

DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN evidence e ON e.source_record_id = sr.source_record_id
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
    ) <> 0 THEN
        RAISE EXCEPTION 'phase12 coverage: Genesis 1:22-23 must remain structural rather than semantically complete';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key LIKE 'MT_GEN_1\_%' ESCAPE '\'
    ) <> 31 THEN
        RAISE EXCEPTION 'phase12 coverage: Genesis 1 must retain exactly 31 structural locators';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (2, 3, 4, 6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'phase12 coverage: deferred Genesis chapters must remain source unavailable';
    END IF;
END $$;
