\set ON_ERROR_STOP on

-- Phase 26 biblical entity coverage inventory.
--
-- This report is intentionally runnable both BEFORE and AFTER the Phase 26 ingestion fixture is
-- loaded, so the same query set produces the before/after coverage comparison.
--
-- Absence is never source silence and never nonexistence. A row reported as NOT_YET_MODELED or
-- CANDIDATE_REQUIRES_REVIEW states only what Berean currently represents.

\echo 'Phase 26 coverage summary counts'
SELECT
    (SELECT count(*) FROM source) AS source_count,
    (SELECT count(*) FROM dataset) AS dataset_count,
    (SELECT count(*) FROM source_record) AS source_record_count,
    (SELECT count(*) FROM citation) AS citation_count,
    (SELECT count(*) FROM evidence) AS evidence_count,
    (SELECT count(*) FROM entity) AS entity_count,
    (SELECT count(*) FROM proposition) AS proposition_count,
    (SELECT count(*) FROM claim) AS claim_count,
    (SELECT count(*) FROM event) AS event_count,
    (SELECT count(*) FROM event_participation) AS projected_participation_count,
    (SELECT count(*) FROM derivation) AS derivation_count,
    (SELECT count(*) FROM derivation_input) AS derivation_input_count;

\echo 'Phase 26 entities by type'
SELECT entity_type_code, count(*)::int AS entity_count
FROM entity GROUP BY entity_type_code ORDER BY entity_type_code;

\echo 'Phase 26 claims by type and status'
SELECT claim_type_code, claim_status_code, count(*)::int AS claim_count
FROM claim GROUP BY claim_type_code, claim_status_code ORDER BY claim_type_code, claim_status_code;

\echo 'Phase 26 source / dataset / source-record coverage'
SELECT s.source_key,
       d.dataset_key,
       count(DISTINCT sr.source_record_id)::int AS source_record_count,
       count(DISTINCT ci.citation_id)::int AS citation_count,
       count(DISTINCT e.evidence_id)::int AS evidence_count,
       count(DISTINCT ce.claim_id)::int AS claim_count,
       count(DISTINCT sr.source_record_id) FILTER (WHERE sr.raw_content IS NOT NULL)::int AS stored_source_text_count
FROM source s
JOIN dataset d ON d.source_id = s.source_id
LEFT JOIN source_record sr ON sr.dataset_id = d.dataset_id
LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
GROUP BY s.source_key, d.dataset_key
ORDER BY s.source_key, d.dataset_key;

\echo 'Phase 26 represented books and passages'
SELECT left(split_part(sr.source_location, ' ', 1) ||
       CASE WHEN sr.source_location ~ '^[12] ' THEN ' ' || split_part(sr.source_location, ' ', 2) ELSE '' END, 40) AS book_label,
       count(DISTINCT sr.source_record_id)::int AS locator_count,
       count(DISTINCT ce.claim_id)::int AS modeled_claim_count,
       count(DISTINCT sr.source_record_id) FILTER (WHERE ce.claim_id IS NULL)::int AS locators_without_modeled_claim,
       left(min(sr.source_location), 40) AS first_locator,
       left(max(sr.source_location), 40) AS last_locator
FROM source_record sr
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE sr.source_location IS NOT NULL
GROUP BY 1
ORDER BY 1;

\echo 'Phase 26 entity reachability: source records, propositions, and projected events'
SELECT en.entity_key,
       en.entity_type_code,
       count(DISTINCT p.proposition_id)::int AS proposition_count,
       count(DISTINCT c.claim_id)::int AS claim_count,
       count(DISTINCT ep.event_id)::int AS projected_event_count,
       count(DISTINCT sr.source_record_id)::int AS source_record_count,
       count(DISTINCT esm.entity_source_mapping_id) FILTER (WHERE esm.mapping_status_code = 'ACTIVE')::int AS active_mapping_count,
       CASE
           WHEN count(DISTINCT c.claim_id) = 0 THEN 'ENTITY_EXISTS_NO_CLAIMS'
           WHEN count(DISTINCT sr.source_record_id) = 0 THEN 'CLAIMS_EXIST_NO_PROVENANCE'
           WHEN count(DISTINCT ep.event_id) = 0 THEN 'ENTITY_EXISTS_NO_EVENTS'
           ELSE 'EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED'
       END AS coverage_status
FROM entity en
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
GROUP BY en.entity_key, en.entity_type_code
ORDER BY en.entity_key;

\echo 'Phase 26 entities with no claims'
SELECT en.entity_key, en.entity_type_code
FROM entity en
WHERE NOT EXISTS (
    SELECT 1 FROM proposition p
    JOIN claim c ON c.proposition_id = p.proposition_id
    WHERE p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
)
ORDER BY en.entity_key;

\echo 'Phase 26 claims with incomplete provenance (non-derived claims lacking a full source chain)'
SELECT c.claim_key, c.claim_type_code,
       CASE WHEN c.claim_type_code = 'DERIVED_CLAIM' THEN 'DERIVATION_BACKED' ELSE 'INCOMPLETE_SOURCE_CHAIN' END AS provenance_status
FROM claim c
WHERE c.claim_type_code <> 'DERIVED_CLAIM'
  AND NOT EXISTS (
      SELECT 1
      FROM claim_evidence ce
      JOIN evidence e ON e.evidence_id = ce.evidence_id
      JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
      JOIN citation ci ON ci.citation_id = ec.citation_id
      JOIN source_record sr ON sr.source_record_id = ci.source_record_id
      JOIN dataset d ON d.dataset_id = sr.dataset_id
      JOIN source s ON s.source_id = d.source_id
      WHERE ce.claim_id = c.claim_id
  )
ORDER BY c.claim_key;

\echo 'Phase 26 source records with no modeled claim (source availability, never source silence)'
SELECT sr.source_record_key, sr.source_location,
       CASE WHEN e.evidence_id IS NULL THEN 'NO_EVIDENCE_MODELED' ELSE 'EVIDENCE_ONLY_NO_CLAIM' END AS modeling_status,
       'NOT_YET_MODELED' AS coverage_classification
FROM source_record sr
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE ce.claim_id IS NULL
ORDER BY sr.source_record_key;

\echo 'Phase 26 named-entity coverage for the selected corpus (candidate worksheet reconciliation)'
WITH corpus_named_entity(candidate_key, candidate_name, entity_key, expected_status, boundary_reference) AS (
    VALUES
        ('CAND_MAHALALEL', 'Mahalalel', 'mahalalel', 'DIRECTLY_REPRESENTED', 'Genesis 5:12'),
        ('CAND_JARED', 'Jared', 'jared', 'DIRECTLY_REPRESENTED', 'Genesis 5:15'),
        ('CAND_ENOCH_GEN5', 'Enoch', 'enoch', 'DIRECTLY_REPRESENTED', 'Genesis 5:18'),
        ('CAND_METHUSELAH', 'Methuselah', 'methuselah', 'DIRECTLY_REPRESENTED', 'Genesis 5:21'),
        ('CAND_ELI', 'Eli', 'eli', 'DIRECTLY_REPRESENTED', '1 Samuel 4:4'),
        ('CAND_HOPHNI', 'Hophni', 'hophni', 'DIRECTLY_REPRESENTED', '1 Samuel 4:4'),
        ('CAND_PHINEHAS_SON_OF_ELI', 'Phinehas son of Eli', 'phinehas_son_of_eli', 'DIRECTLY_REPRESENTED', '1 Samuel 4:4'),
        ('CAND_PHILISTINES', 'Philistines', 'philistines', 'DIRECTLY_REPRESENTED', '1 Samuel 5:1'),
        ('CAND_EBENEZER', 'Ebenezer', 'ebenezer', 'DIRECTLY_REPRESENTED', '1 Samuel 5:1'),
        ('CAND_ASHDOD', 'Ashdod', 'ashdod', 'DIRECTLY_REPRESENTED', '1 Samuel 5:1'),
        ('CAND_HOUSE_OF_DAGON', 'house of Dagon', 'house_of_dagon_ashdod', 'DIRECTLY_REPRESENTED', '1 Samuel 5:2'),
        ('CAND_KIRIATH_JEARIM', 'Kiriath-jearim', 'kiriath_jearim', 'DIRECTLY_REPRESENTED', '1 Samuel 7:1'),
        ('CAND_ABINADAB', 'Abinadab', 'abinadab', 'DIRECTLY_REPRESENTED', '1 Samuel 7:1'),
        ('CAND_ELEAZAR_SON_OF_ABINADAB', 'Eleazar son of Abinadab', 'eleazar_son_of_abinadab', 'DIRECTLY_REPRESENTED', '1 Samuel 7:1'),
        ('CAND_DAGON', 'Dagon', NULL, 'CANDIDATE_REQUIRES_REVIEW', '1 Samuel 5:2'),
        ('CAND_AHIO', 'Ahio', NULL, 'CANDIDATE_REQUIRES_REVIEW', '2 Samuel 6:3'),
        ('CAND_ENOCH_365_YEARS', '365 years of Enoch', NULL, 'CANDIDATE_REQUIRES_REVIEW', 'Genesis 5:23'),
        ('CAND_ARK_KIRIATH_JEARIM_20_YEARS', 'twenty years at Kiriath-jearim', NULL, 'CANDIDATE_REQUIRES_REVIEW', '1 Samuel 7:2'),
        ('CAND_ENOCH_EXTERNAL_ID', 'External identifier for Enoch', NULL, 'CANDIDATE_REQUIRES_REVIEW', 'Genesis 5:18'),
        ('CAND_ENOCH_CAIN_LINE', 'Enoch son of Cain', NULL, 'EXCLUDED', 'Genesis 4:17'),
        ('CAND_ENOCH_TRANSLATION', 'Enoch did not die / was translated', NULL, 'EXCLUDED', 'Genesis 5:24'),
        ('CAND_ENOCH_BOOK_AUTHORSHIP', 'Enoch as author of 1 Enoch', NULL, 'EXCLUDED', 'outside source boundary'),
        ('CAND_ENOCH_EXTERNAL_CHRONOLOGY', 'External chronological dating for Enoch', NULL, 'EXCLUDED', 'outside source boundary')
)
SELECT cne.candidate_key,
       cne.candidate_name,
       cne.boundary_reference,
       cne.expected_status AS worksheet_status,
       CASE
           WHEN cne.expected_status IN ('EXCLUDED', 'CANDIDATE_REQUIRES_REVIEW') THEN cne.expected_status
           WHEN en.entity_id IS NULL THEN 'NOT_YET_MODELED'
           WHEN EXISTS (
               SELECT 1 FROM proposition p
               JOIN claim c ON c.proposition_id = p.proposition_id
               WHERE (p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id)
                 AND c.claim_type_code = 'DERIVED_CLAIM'
           ) AND NOT EXISTS (
               SELECT 1 FROM proposition p
               JOIN claim c ON c.proposition_id = p.proposition_id
               WHERE (p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id)
                 AND c.claim_type_code <> 'DERIVED_CLAIM'
           ) THEN 'DERIVED_STRUCTURALLY'
           WHEN EXISTS (
               SELECT 1 FROM proposition p
               JOIN claim c ON c.proposition_id = p.proposition_id
               WHERE p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
           ) THEN 'DIRECTLY_REPRESENTED'
           ELSE 'ENTITY_EXISTS_NO_CLAIMS'
       END AS actual_status
FROM corpus_named_entity cne
LEFT JOIN entity en ON en.entity_key = cne.entity_key
ORDER BY cne.candidate_key;

\echo 'Phase 26 Enoch end-to-end provenance chain'
SELECT c.claim_key,
       c.claim_type_code,
       COALESCE(se.entity_key, sv.event_key) AS subject,
       p.predicate,
       COALESCE(oe.entity_key, ov.event_key, tv.numeric_value::text) AS object,
       e.evidence_key,
       ci.citation_key,
       sr.source_record_key,
       sr.source_location,
       d.dataset_key,
       s.source_key,
       CASE WHEN sr.raw_content IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS raw_content_status,
       CASE WHEN ci.quoted_text IS NULL THEN 'NOT_STORED_BY_POLICY' ELSE 'STORED' END AS quoted_text_status
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
LEFT JOIN event sv ON sv.event_id = p.subject_event_id
LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
LEFT JOIN event ov ON ov.event_id = p.object_event_id
LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE se.entity_key = 'enoch' OR oe.entity_key = 'enoch'
ORDER BY c.claim_key, ci.citation_key;

\echo 'Phase 26 unmodeled source observations retained as evidence (documented limitations)'
SELECT e.evidence_key, sr.source_location, e.notes
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
WHERE e.evidence_key IN ('EV_MT_GEN_5_22', 'EV_MT_GEN_5_23', 'EV_MT_GEN_5_24',
                         'EV_MT_1SA_5_1', 'EV_MT_1SA_5_2', 'EV_MT_1SA_7_1', 'EV_MT_1SA_7_2')
ORDER BY e.evidence_key;
