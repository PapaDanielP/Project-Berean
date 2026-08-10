\set ON_ERROR_STOP on

\echo 'Phase 24 provenance trace: one 1 Kings claim and one 2 Chronicles claim'
SELECT c.claim_key,
       ce.relation_type_code,
       ev.evidence_key,
       ci.citation_key,
       ci.locator,
       sr.source_record_key,
       d.dataset_key,
       s.source_key
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN ('CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE',
                      'CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE')
ORDER BY c.claim_key;

\echo 'Phase 24 preserved source difference: 1 Kings priests vs 2 Chronicles Levites for the same take-up event, with no ClaimRelation added'
SELECT s.source_key,
       sr.source_location,
       c.claim_key,
       c.statement,
       en.entity_key,
       ev.event_key,
       cr.claim_relation_id,
       cr.relation_type_code
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity en ON en.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
LEFT JOIN claim_relation cr ON cr.claim_id = c.claim_id OR cr.related_claim_id = c.claim_id
WHERE c.claim_key IN ('CLAIM_1KI_BEARERS_SUBJECT_TAKE_UP_TEMPLE',
                      'CLAIM_2CH_BEARERS_SUBJECT_TAKE_UP_TEMPLE')
ORDER BY s.source_key;

\echo 'Phase 24 event and projected participation exploration'
SELECT ev.event_key,
       ev.event_type_code,
       en.entity_key,
       ep.role_code,
       c.claim_key
FROM event ev
LEFT JOIN event_participation ep ON ep.event_id = ev.event_id
LEFT JOIN entity en ON en.entity_id = ep.entity_id
LEFT JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key IN (
    'ark_covenant_taken_up_temple_placement',
    'ark_covenant_brought_up_temple_placement',
    'ark_covenant_placed_inner_sanctuary_solomon_temple',
    'ark_covenant_covered_under_cherubim_solomon_temple',
    'ark_covenant_poles_visible_holy_place_solomon_temple',
    'ark_covenant_tablets_only_content_solomon_temple'
)
ORDER BY ev.event_key, en.entity_key, c.claim_key;

\echo 'Phase 24 derivation and derivation_input dependency listing'
SELECT dc.claim_key AS derived_claim_key,
       d.method,
       d.assumptions,
       di.derivation_input_id,
       ic.claim_key AS input_claim_key,
       s.source_key AS input_source_key,
       sr.source_location AS input_locator
FROM claim dc
JOIN derivation d ON d.derivation_id = dc.derivation_id
JOIN derivation_input di ON di.derivation_id = d.derivation_id
JOIN claim ic ON ic.claim_id = di.input_claim_id
JOIN claim_evidence ce ON ce.claim_id = ic.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset ds ON ds.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = ds.source_id
WHERE dc.claim_key = 'CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED'
ORDER BY di.derivation_input_id;

\echo 'Phase 24 reconciliation: both source identities mapped ACTIVE to the same canonical entities with distinct supporting evidence'
SELECT s.source_key,
       si.source_identity_key,
       si.display_name,
       en.entity_key,
       esm.mapping_status_code,
       esm.confidence,
       ev.evidence_key AS supporting_evidence_key
FROM entity_source_mapping esm
JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
JOIN source s ON s.source_id = si.source_id
JOIN entity en ON en.entity_id = esm.entity_id
LEFT JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
WHERE s.source_key IN ('1KI_MT', '2CH_MT')
ORDER BY en.entity_key, s.source_key;
