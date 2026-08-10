\set ON_ERROR_STOP on

\echo 'Phase 24 coverage summary by persistent structure'
SELECT 'sources' AS item, count(*)::int AS count FROM source WHERE source_key IN ('1KI_MT', '2CH_MT')
UNION ALL SELECT 'datasets', count(*)::int FROM dataset WHERE dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
UNION ALL SELECT 'source_records', count(*)::int FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
UNION ALL SELECT 'citations', count(*)::int FROM citation ci JOIN source_record sr ON sr.source_record_id = ci.source_record_id JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
UNION ALL SELECT 'evidence', count(*)::int FROM evidence ev JOIN source_record sr ON sr.source_record_id = ev.source_record_id JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
UNION ALL SELECT 'direct_claims', count(*)::int FROM claim WHERE claim_key LIKE 'CLAIM_1KI_%' OR claim_key LIKE 'CLAIM_2CH_%'
UNION ALL SELECT 'derived_claims', count(*)::int FROM claim WHERE claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED'
UNION ALL SELECT 'derivation_inputs', count(*)::int FROM derivation_input di JOIN claim c ON c.derivation_id = di.derivation_id WHERE c.claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED'
ORDER BY item;

\echo 'Phase 24 complete provenance examples: Claim -> Evidence -> Citation -> SourceRecord -> Dataset -> Source'
SELECT c.claim_key, ev.evidence_key, ci.citation_key, ci.locator,
       sr.source_record_key, d.dataset_key, s.source_key,
       sr.raw_content IS NULL AS raw_content_not_stored_by_policy,
       ci.quoted_text IS NULL AS quoted_text_not_stored_by_policy
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN ('CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT',
                      'CLAIM_2CH_ARK_SUBJECT_TEMPLE_PLACEMENT',
                      'CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
                      'CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION')
ORDER BY c.claim_key, ev.evidence_key;

\echo 'Phase 24 proposition exploration: multiple source-backed and derived claims coexist'
SELECT p.proposition_id, se.entity_key AS subject_entity, p.predicate, oe.entity_key AS object_entity,
       c.claim_key, c.claim_type_code, s.source_key
FROM proposition p
JOIN entity se ON se.entity_id = p.subject_entity_id
JOIN entity oe ON oe.entity_id = p.object_entity_id
JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
LEFT JOIN evidence ev ON ev.evidence_id = ce.evidence_id
LEFT JOIN source_record sr ON sr.source_record_id = ev.source_record_id
LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
LEFT JOIN source s ON s.source_id = d.source_id
WHERE se.entity_key = 'ark_of_covenant'
  AND oe.entity_key = 'tablets_of_testimony'
  AND p.predicate = 'containsContent'
ORDER BY c.claim_type_code, c.claim_key, s.source_key;

\echo 'Phase 24 source comparison preserving differences without automatic contradiction'
SELECT c.claim_key, ev.evidence_key, ev.observation
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
WHERE c.claim_key IN ('CLAIM_1KI_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
                      'CLAIM_2CH_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
                      'CLAIM_BEZALEL_BUILDER_ARK_COVENANT',
                      'CLAIM_MOSES_BUILDER_ARK_COVENANT')
ORDER BY c.claim_key, ev.evidence_key;

\echo 'Phase 24 event exploration using projected participation and explicit location claim'
SELECT ev.event_key, ev.event_type_code, en.entity_key, ep.role_code, c.claim_key
FROM event ev
JOIN event_participation ep ON ep.event_id = ev.event_id
JOIN entity en ON en.entity_id = ep.entity_id
JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key IN ('ark_covenant_temple_assembly', 'ark_covenant_temple_transfer', 'ark_covenant_temple_placement')
ORDER BY ev.event_key, en.entity_key, c.claim_key;

SELECT c.claim_key, src_event.event_key AS event_key, p.predicate, place.entity_key AS place_key
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event src_event ON src_event.event_id = p.subject_event_id
JOIN entity place ON place.entity_id = p.object_entity_id
WHERE c.claim_key IN ('CLAIM_1KI_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY',
                      'CLAIM_2CH_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY')
ORDER BY c.claim_key;

\echo 'Phase 24 derivation explanation inputs'
SELECT dc.claim_key AS derived_claim, d.method, d.assumptions,
       ic.claim_key AS input_claim, di.notes
FROM claim dc
JOIN derivation d ON d.derivation_id = dc.derivation_id
JOIN derivation_input di ON di.derivation_id = d.derivation_id
JOIN claim ic ON ic.claim_id = di.input_claim_id
WHERE dc.claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED'
ORDER BY ic.claim_key;
