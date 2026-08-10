\set ON_ERROR_STOP on

\echo 'Phase 13 Genesis genealogical locator coverage'
WITH locators AS (
    SELECT * FROM (VALUES
        ('MT_GEN_5_3', 'Genesis 5:3', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('LXX_GEN_5_3', 'Genesis 5:3', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('MT_GEN_5_6', 'Genesis 5:6', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('LXX_GEN_5_6', 'Genesis 5:6', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('MT_GEN_5_9', 'Genesis 5:9', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('LXX_GEN_5_9', 'Genesis 5:9', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED'),
        ('MT_GEN_8_4', 'Genesis 8:4', 'POPULATED', 'SOURCE-BACKED', 'NOT DERIVED', 'SUPPORTED')
    ) AS v(source_record_key, locator, coverage_status, provenance_status, derivation_status,
           semantic_status)
)
SELECT v.locator,
       v.source_record_key,
       count(DISTINCT ci.citation_id) AS citations,
       count(DISTINCT e.evidence_id) AS evidence,
       count(DISTINCT c.claim_id) AS claims,
       v.coverage_status,
       v.provenance_status,
       v.derivation_status,
       v.semantic_status
FROM locators v
JOIN source_record sr ON sr.source_record_key = v.source_record_key
LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim c ON c.claim_id = ce.claim_id
GROUP BY v.locator, v.source_record_key, v.coverage_status, v.provenance_status,
         v.derivation_status, v.semantic_status
ORDER BY v.locator, v.source_record_key;

\echo 'Phase 13 persistent entity coverage'
SELECT en.entity_key,
       en.entity_type_code,
       count(DISTINCT esm.source_identity_id) FILTER (WHERE esm.mapping_status_code = 'ACTIVE')
           AS active_source_identities,
       count(DISTINCT sr.source_record_key) AS supporting_source_records,
       count(DISTINCT ep.event_id) AS projected_event_participations,
       'RECONCILED' AS reconciliation_status,
       'SOURCE-BACKED' AS provenance_status,
       'NOT DERIVED' AS derivation_status
FROM entity en
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key IN ('adam', 'seth', 'enosh', 'kenan')
GROUP BY en.entity_key, en.entity_type_code
ORDER BY en.entity_key;

\echo 'Phase 13 deferred Genesis chapter coverage'
SELECT chapter,
       'SOURCE UNAVAILABLE' AS coverage_status,
       'UNRESOLVED' AS semantic_status,
       'ACQUISITION PENDING' AS acquisition_status
FROM generate_series(2, 11) AS chapter
WHERE chapter IN (2, 3, 4, 6, 7, 9, 10, 11)
ORDER BY chapter;

DO $$
BEGIN
    -- Genesis 5:9 must be semantically populated in both traditions, not merely structural.
    IF (
        SELECT count(DISTINCT sr.source_record_key)
        FROM source_record sr
        JOIN evidence e ON e.source_record_id = sr.source_record_id
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN claim c ON c.claim_id = ce.claim_id AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
        WHERE sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase13 coverage: both Genesis 5:9 records must carry supported direct source claims';
    END IF;

    -- Each persistent genealogical PERSON entity must remain reconciled and source-backed.
    IF EXISTS (
        SELECT 1
        FROM entity en
        WHERE en.entity_key IN ('adam', 'seth', 'enosh', 'kenan')
          AND NOT EXISTS (
              SELECT 1 FROM entity_source_mapping esm
              WHERE esm.entity_id = en.entity_id AND esm.mapping_status_code = 'ACTIVE'
                AND esm.supporting_evidence_id IS NOT NULL
          )
    ) THEN
        RAISE EXCEPTION 'phase13 coverage: every populated genealogical entity must keep an evidence-backed active reconciliation';
    END IF;

    -- Genesis 1 and the deferred chapters keep their prior classification.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key LIKE 'MT\_GEN\_1\_%' ESCAPE '\'
    ) <> 31 THEN
        RAISE EXCEPTION 'phase13 coverage: Genesis 1 must retain exactly 31 structural locators';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF')
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (2, 3, 4, 6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'phase13 coverage: deferred Genesis chapters must remain source unavailable';
    END IF;

    -- Genesis 5:12 onward stays deferred: this phase advances the genealogy one locator only.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF')
          AND sr.source_location ~ '^Genesis 5:'
          AND substring(sr.source_location FROM '^Genesis 5:([0-9]+)$')::int NOT IN (3, 6, 9)
    ) THEN
        RAISE EXCEPTION 'phase13 coverage: Genesis 5 locators beyond 5:9 must remain deferred';
    END IF;
END $$;
