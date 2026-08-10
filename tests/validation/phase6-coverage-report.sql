\set ON_ERROR_STOP on

\echo 'Phase 6 coverage summary'
SELECT 'source' AS coverage_area, count(*) AS populated, 0 AS missing, count(*) AS structurally_represented,
       count(*) FILTER (WHERE source_type_code IS NOT NULL) AS source_backed, 0 AS derived, 0 AS unresolved,
       0 AS intentionally_excluded
FROM source
UNION ALL
SELECT 'dataset', count(*), 0, count(*), count(*) FILTER (WHERE source_id IS NOT NULL), 0, 0, 0 FROM dataset
UNION ALL
SELECT 'source_record', count(*), 0, count(*), count(*) FILTER (WHERE dataset_id IS NOT NULL), 0,
       count(*) FILTER (WHERE raw_content IS NULL), count(*) FILTER (WHERE raw_content IS NULL) FROM source_record
UNION ALL
SELECT 'citation', count(*), 0, count(*), count(*) FILTER (WHERE source_record_id IS NOT NULL), 0,
       count(*) FILTER (WHERE quoted_text IS NULL), count(*) FILTER (WHERE quoted_text IS NULL) FROM citation
UNION ALL
SELECT 'evidence', count(*), 0, count(*), count(*) FILTER (WHERE evidence_type_code = 'SOURCE_OBSERVATION'),
       count(*) FILTER (WHERE evidence_type_code = 'ANALYTICAL_OBSERVATION'), 0, 0 FROM evidence
UNION ALL
SELECT 'claim', count(*), 0, count(*),
       count(*) FILTER (WHERE claim_type_code <> 'DERIVED_CLAIM'),
       count(*) FILTER (WHERE claim_type_code = 'DERIVED_CLAIM'),
       count(*) FILTER (WHERE claim_status_code = 'UNDER_REVIEW'), 0 FROM claim
UNION ALL
SELECT 'proposition', count(*), 0, count(*), count(*), 0, 0, 0 FROM proposition
UNION ALL
SELECT 'entity', count(*), 0, count(*), 0, 0, 0, 0 FROM entity
UNION ALL
SELECT 'source_identity', count(*), 0, count(*), count(*), 0, 0, 0 FROM source_identity
UNION ALL
SELECT 'entity_mapping', count(*), 0, count(*), count(*) FILTER (WHERE supporting_evidence_id IS NOT NULL), 0,
       count(*) FILTER (WHERE mapping_status_code = 'PROPOSED'), 0 FROM entity_source_mapping
UNION ALL
SELECT 'event', count(*), 0, count(*), 0, 0, 0, 0 FROM event
UNION ALL
SELECT 'event_participation', count(*), 0, count(*), count(*), 0, 0, 0 FROM event_participation
UNION ALL
SELECT 'derivation', count(*), 0, count(*), 0, count(*), 0, 0 FROM derivation
ORDER BY coverage_area;

\echo 'Phase 6 Genesis locator coverage'
SELECT regexp_replace(sr.source_location, '^(Genesis) ([0-9]+):([0-9]+)$', '\1') AS book,
       regexp_replace(sr.source_location, '^Genesis ([0-9]+):([0-9]+)$', '\1') AS chapter,
       regexp_replace(sr.source_location, '^Genesis ([0-9]+):([0-9]+)$', '\2') AS verse,
       count(DISTINCT sr.source_record_id) AS source_records,
       count(DISTINCT c.citation_id) AS citations,
       count(DISTINCT e.evidence_id) AS evidence_items,
       count(DISTINCT cl.claim_id) AS claims,
       count(DISTINCT p.proposition_id) AS propositions,
       bool_or(sr.raw_content IS NULL) AS structurally_represented,
       bool_or(e.evidence_type_code = 'SOURCE_OBSERVATION') AS source_backed,
       bool_or(cl.claim_type_code = 'DERIVED_CLAIM') AS derived,
       bool_or(sr.raw_content IS NULL OR c.quoted_text IS NULL) AS intentionally_excluded_text
FROM source_record sr
LEFT JOIN citation c ON c.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim cl ON cl.claim_id = ce.claim_id
LEFT JOIN proposition p ON p.proposition_id = cl.proposition_id
WHERE sr.source_location LIKE 'Genesis %:%'
GROUP BY sr.source_location
ORDER BY string_to_array(replace(sr.source_location, 'Genesis ', ''), ':')::int[];

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM source_record WHERE source_location LIKE 'Genesis %:%') THEN
        RAISE EXCEPTION 'phase6 coverage: no Genesis locators represented';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM claim WHERE claim_type_code = 'DERIVED_CLAIM') THEN
        RAISE EXCEPTION 'phase6 coverage: no derived claims represented';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM event_participation) THEN
        RAISE EXCEPTION 'phase6 coverage: no event participation projection rows represented';
    END IF;
END $$;
