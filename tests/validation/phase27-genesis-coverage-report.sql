\set ON_ERROR_STOP on

-- Runnable both before and after Phase 27. The accepted Phase 26 totals are the reproducible
-- baseline; current totals are measured, never inferred from source silence.
\echo 'Phase 27 measurement state and current corpus totals'
SELECT CASE WHEN EXISTS (SELECT 1 FROM claim WHERE claim_key = 'CLAIM_P27_136')
            THEN 'AFTER INGESTION' ELSE 'BEFORE INGESTION' END AS measurement_state,
       (SELECT count(*) FROM source) AS sources,
       (SELECT count(*) FROM dataset) AS datasets,
       (SELECT count(*) FROM source_record) AS source_records,
       (SELECT count(*) FROM citation) AS citations,
       (SELECT count(*) FROM evidence) AS evidence,
       (SELECT count(*) FROM entity) AS entities,
       (SELECT count(*) FROM proposition) AS propositions,
       (SELECT count(*) FROM claim) AS claims,
       (SELECT count(*) FROM event) AS events,
       (SELECT count(*) FROM event_participation) AS projected_participations,
       (SELECT count(*) FROM derivation) AS derivations,
       (SELECT count(*) FROM derivation_input) AS derivation_inputs;

\echo 'Phase 27 before / current / delta table'
WITH baseline(metric, before_count) AS (VALUES
    ('sources',10), ('datasets',10), ('source_records',75), ('citations',75),
    ('evidence',77), ('entities',60), ('propositions',170), ('claims',183),
    ('events',52), ('projected_participations',122), ('derivations',3),
    ('derivation_inputs',6)
), current_counts(metric, current_count) AS (VALUES
    ('sources',(SELECT count(*)::int FROM source)),
    ('datasets',(SELECT count(*)::int FROM dataset)),
    ('source_records',(SELECT count(*)::int FROM source_record)),
    ('citations',(SELECT count(*)::int FROM citation)),
    ('evidence',(SELECT count(*)::int FROM evidence)),
    ('entities',(SELECT count(*)::int FROM entity)),
    ('propositions',(SELECT count(*)::int FROM proposition)),
    ('claims',(SELECT count(*)::int FROM claim)),
    ('events',(SELECT count(*)::int FROM event)),
    ('projected_participations',(SELECT count(*)::int FROM event_participation)),
    ('derivations',(SELECT count(*)::int FROM derivation)),
    ('derivation_inputs',(SELECT count(*)::int FROM derivation_input))
)
SELECT b.metric, b.before_count, c.current_count AS measured_count,
       c.current_count - b.before_count AS delta
FROM baseline b JOIN current_counts c USING (metric) ORDER BY b.metric;

\echo 'Phase 27 entities by type with accepted Phase 26 baseline'
WITH baseline(entity_type_code, before_count) AS (
    VALUES ('CONCEPT',24),('OBJECT',12),('ORGANIZATION',2),('PERSON',17),('PLACE',5)
)
SELECT et.entity_type_code, b.before_count, count(e.entity_id)::int AS measured_count,
       count(e.entity_id)::int - b.before_count AS delta
FROM entity_type et
JOIN baseline b USING (entity_type_code)
LEFT JOIN entity e USING (entity_type_code)
GROUP BY et.entity_type_code, b.before_count ORDER BY et.entity_type_code;

\echo 'Genesis references represented by chapter'
SELECT split_part(split_part(sr.source_location, ' ', 2), ':', 1)::int AS genesis_chapter,
       count(DISTINCT sr.source_record_id)::int AS source_record_count,
       count(DISTINCT ce.claim_id)
           FILTER (WHERE ce.relation_type_code = 'SUPPORTS')::int AS source_backed_claim_count,
       count(DISTINCT sr.source_record_id) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM evidence se
           JOIN claim_evidence sce ON sce.evidence_id = se.evidence_id
           WHERE se.source_record_id = sr.source_record_id
             AND sce.relation_type_code = 'SUPPORTS'
       ))::int AS evidence_only_count
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id AND d.dataset_key = 'GEN_MT_REF'
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE sr.source_location ~ '^Genesis [0-9]+:'
GROUP BY 1 ORDER BY 1;

\echo 'Phase 27 provenance completeness and storage policy'
SELECT count(*) FILTER (WHERE c.claim_type_code <> 'DERIVED_CLAIM')::int AS direct_claims,
       count(*) FILTER (WHERE c.claim_type_code <> 'DERIVED_CLAIM' AND EXISTS (
           SELECT 1 FROM claim_evidence ce
           JOIN evidence e ON e.evidence_id = ce.evidence_id
           JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
           JOIN citation ci ON ci.citation_id = ec.citation_id
           JOIN source_record sr ON sr.source_record_id = ci.source_record_id
           JOIN dataset d ON d.dataset_id = sr.dataset_id
           JOIN source s ON s.source_id = d.source_id
           WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
       ))::int AS complete_source_chains,
       count(*) FILTER (WHERE c.claim_type_code <> 'DERIVED_CLAIM' AND NOT EXISTS (
           SELECT 1 FROM claim_evidence ce
           JOIN evidence e ON e.evidence_id = ce.evidence_id
           JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
           JOIN citation ci ON ci.citation_id = ec.citation_id
           WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
       ))::int AS incomplete_provenance
FROM claim c;

SELECT count(*) FILTER (WHERE raw_content IS NULL AND content_hash IS NULL)::int
           AS source_records_not_stored_by_policy,
       count(*) FILTER (WHERE raw_content IS NOT NULL OR content_hash IS NOT NULL)::int
           AS source_records_with_stored_content
FROM source_record;
SELECT count(*) FILTER (WHERE quoted_text IS NULL)::int AS citations_not_stored_by_policy,
       count(*) FILTER (WHERE quoted_text IS NOT NULL)::int AS citations_with_quotation
FROM citation;

\echo 'Claims without evidence'
SELECT c.claim_key, c.claim_type_code
FROM claim c
WHERE c.claim_type_code <> 'DERIVED_CLAIM'
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id)
ORDER BY c.claim_key;

\echo 'Evidence without claim (available source observations, never source silence)'
SELECT e.evidence_key, sr.source_location, 'NOT_YET_MODELED' AS coverage_classification, e.notes
FROM evidence e JOIN source_record sr ON sr.source_record_id = e.source_record_id
WHERE NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id)
ORDER BY e.evidence_key;

\echo 'Source records without claims'
SELECT sr.source_record_key, sr.source_location,
       CASE WHEN EXISTS (SELECT 1 FROM evidence e WHERE e.source_record_id = sr.source_record_id)
            THEN 'EVIDENCE_ONLY_NO_CLAIM' ELSE 'NO_EVIDENCE_MODELED' END AS disposition,
       'NOT_YET_MODELED' AS coverage_classification
FROM source_record sr
WHERE NOT EXISTS (
    SELECT 1 FROM evidence e JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
    WHERE e.source_record_id = sr.source_record_id
) ORDER BY sr.source_record_key;

\echo 'Per-entity Genesis coverage'
SELECT en.entity_key, en.entity_type_code,
       count(DISTINCT p.proposition_id)::int AS proposition_count,
       count(DISTINCT c.claim_id)::int AS claim_count,
       count(DISTINCT ep.event_id)::int AS projected_event_count,
       count(DISTINCT sr.source_record_id)::int AS source_record_count,
       count(DISTINCT esm.entity_source_mapping_id)
           FILTER (WHERE esm.mapping_status_code = 'ACTIVE')::int AS active_mapping_count,
       CASE WHEN count(DISTINCT c.claim_id) = 0 THEN 'NOT_YET_MODELED'
            WHEN count(DISTINCT sr.source_record_id) = 0 THEN 'CANDIDATE_REQUIRES_REVIEW'
            WHEN bool_or(c.claim_type_code = 'DIRECT_SOURCE_CLAIM') THEN 'DIRECTLY_REPRESENTED'
            ELSE 'DERIVED_STRUCTURALLY' END AS coverage_classification
FROM entity en
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
LEFT JOIN evidence ev ON ev.evidence_id = ce.evidence_id
LEFT JOIN source_record sr ON sr.source_record_id = ev.source_record_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
GROUP BY en.entity_key, en.entity_type_code ORDER BY en.entity_key;

\echo 'Candidate worksheet status versus database status and disposition'
WITH worksheet(candidate_key, entity_key, worksheet_status, disposition) AS (VALUES
    ('P27_ADAM','adam','DIRECTLY_REPRESENTED','REUSED_ACCEPTED_ENTITY'),
    ('P27_NOAH','noah','DIRECTLY_REPRESENTED','REUSED_ACCEPTED_ENTITY'),
    ('P27_ABRAHAM','abraham','DIRECTLY_REPRESENTED','INGESTED'),
    ('P27_SARAH','sarah','DIRECTLY_REPRESENTED','INGESTED'),
    ('P27_ISAAC','isaac','DIRECTLY_REPRESENTED','INGESTED'),
    ('P27_JACOB','jacob','DIRECTLY_REPRESENTED','INGESTED'),
    ('P27_JOSEPH','joseph','DIRECTLY_REPRESENTED','INGESTED'),
    ('P27_ISRAEL_RENAME',NULL,'CANDIDATE_REQUIRES_REVIEW','EVIDENCE_ONLY'),
    ('P27_DREAM_CONTENT',NULL,'NOT_YET_MODELED','EVIDENCE_ONLY'),
    ('P27_MODERN_LOCATIONS',NULL,'EXCLUDED','CANDIDATE_ONLY'),
    ('P27_JOSEPH_SALE_CAUSATION',NULL,'EXCLUDED','CANDIDATE_ONLY')
)
SELECT w.candidate_key, w.worksheet_status,
       CASE WHEN w.entity_key IS NULL THEN w.worksheet_status
            WHEN EXISTS (
                SELECT 1 FROM entity en
                JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
                JOIN claim c ON c.proposition_id = p.proposition_id
                WHERE en.entity_key = w.entity_key AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
            ) THEN 'DIRECTLY_REPRESENTED'
            ELSE 'NOT_YET_MODELED' END AS actual_database_status,
       w.disposition
FROM worksheet w ORDER BY w.candidate_key;

\echo 'Required exploration provenance chains'
SELECT en.entity_key, ev.event_key, c.claim_key, p.predicate, e.evidence_key, ci.citation_key,
       sr.source_record_key, d.dataset_key, s.source_key,
       CASE WHEN sr.raw_content IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS raw_content_status,
       CASE WHEN ci.quoted_text IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS quoted_text_status
FROM entity en
JOIN event_participation ep ON ep.entity_id = en.entity_id
JOIN event ev ON ev.event_id = ep.event_id
JOIN claim c ON c.claim_id = ep.asserting_claim_id
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE en.entity_key IN ('adam','noah','abraham','sarah','isaac','jacob','joseph','egypt')
ORDER BY en.entity_key, ev.event_key, c.claim_key;
