\set ON_ERROR_STOP on

\echo 'Phase 24 coverage summary counts'
SELECT
    (SELECT count(*) FROM source) AS source_count,
    (SELECT count(*) FROM dataset) AS dataset_count,
    (SELECT count(*) FROM source_record) AS source_record_count,
    (SELECT count(*) FROM citation) AS citation_count,
    (SELECT count(*) FROM evidence) AS evidence_count,
    (SELECT count(*) FROM proposition) AS proposition_count,
    (SELECT count(*) FROM claim) AS claim_count,
    (SELECT count(*) FROM event) AS event_count,
    (SELECT count(*) FROM claim_relation) AS claim_relation_count,
    (SELECT count(*) FROM derivation) AS derivation_count,
    (SELECT count(*) FROM derivation_input) AS derivation_input_count;

\echo 'Phase 24 source-backed Ark content claims and complete provenance chain'
SELECT
    c.claim_key,
    c.claim_type_code,
    se.entity_key AS subject_entity,
    p.predicate,
    oe.entity_key AS object_entity,
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
JOIN entity se ON se.entity_id = p.subject_entity_id
JOIN entity oe ON oe.entity_id = p.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ci.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN (
    'CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS',
    'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS',
    'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA',
    'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD'
)
ORDER BY c.claim_key;

\echo 'Phase 24 source-difference example: multi-source claims about Ark contents'
SELECT
    oe.entity_key AS asserted_content_entity,
    count(DISTINCT c.claim_id)::int AS claim_count,
    string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS supporting_sources,
    string_agg(DISTINCT c.claim_key, ', ' ORDER BY c.claim_key) AS claim_keys
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity se ON se.entity_id = p.subject_entity_id
JOIN entity oe ON oe.entity_id = p.object_entity_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE se.entity_key = 'ark_of_covenant'
  AND p.predicate = 'containsContent'
  AND oe.entity_key IN ('tablets_of_testimony', 'golden_jar_manna', 'aarons_rod_budded')
GROUP BY oe.entity_key
ORDER BY oe.entity_key;

\echo 'Phase 24 event exploration example via projected participation (existing Ark events)'
SELECT ev.event_key, ev.event_type_code, en.entity_key, ep.role_code, c.claim_key
FROM event ev
JOIN event_participation ep ON ep.event_id = ev.event_id
JOIN entity en ON en.entity_id = ep.entity_id
JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key IN (
    'ark_covenant_transport_new_cart_2sam6',
    'ark_covenant_transport_jordan',
    'ark_covenant_pole_standing_requirement'
)
ORDER BY ev.event_key, en.entity_key, c.claim_key;

\echo 'Phase 24 dependency and derivation demonstration anchors'
SELECT c.claim_key AS derived_claim_key,
       d.derivation_id,
       d.method,
       d.assumptions,
       count(di.derivation_input_id)::int AS derivation_input_count
FROM claim c
JOIN derivation d ON d.derivation_id = c.derivation_id
JOIN derivation_input di ON di.derivation_id = d.derivation_id
WHERE c.claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED'
GROUP BY c.claim_key, d.derivation_id, d.method, d.assumptions;
