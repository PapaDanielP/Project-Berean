\set ON_ERROR_STOP on

\echo 'Phase 24 coverage summary'
SELECT item, count
FROM (
    SELECT 'sources' AS item, count(*)::int AS count FROM source WHERE source_key = '1SA_MT'
    UNION ALL
    SELECT 'datasets', count(*)::int FROM dataset WHERE dataset_key = '1SA_MT_REF'
    UNION ALL
    SELECT 'source_records', count(*)::int
    FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
    WHERE d.dataset_key = '1SA_MT_REF'
    UNION ALL
    SELECT 'citations', count(*)::int
    FROM citation ci JOIN source_record sr ON sr.source_record_id = ci.source_record_id
    JOIN dataset d ON d.dataset_id = sr.dataset_id
    WHERE d.dataset_key = '1SA_MT_REF'
    UNION ALL
    SELECT 'evidence', count(*)::int FROM evidence WHERE evidence_key LIKE 'EV_MT_1SA_%'
    UNION ALL
    SELECT 'propositions', count(DISTINCT p.proposition_id)::int
    FROM proposition p
    JOIN claim c ON c.proposition_id = p.proposition_id
    WHERE c.claim_key LIKE '%_1SAM%'
    UNION ALL
    SELECT 'claims', count(*)::int FROM claim WHERE claim_key LIKE '%_1SAM%'
    UNION ALL
    SELECT 'events', count(*)::int FROM event WHERE event_key LIKE '%_1sam%'
    UNION ALL
    SELECT 'projected_event_participation_rows', count(*)::int
    FROM event_participation ep
    JOIN event ev ON ev.event_id = ep.event_id
    WHERE ev.event_key LIKE '%_1sam%'
    UNION ALL
    SELECT 'claim_relations_added', count(*)::int
    FROM claim_relation cr
    JOIN claim c1 ON c1.claim_id = cr.claim_id
    JOIN claim c2 ON c2.claim_id = cr.related_claim_id
    WHERE c1.claim_key LIKE '%_1SAM%' OR c2.claim_key LIKE '%_1SAM%'
    UNION ALL
    SELECT 'derivations_added', count(*)::int
    FROM claim WHERE claim_key LIKE '%_1SAM%' AND claim_type_code = 'DERIVED_CLAIM'
    UNION ALL
    SELECT 'existing_accepted_derivations_available', count(*)::int
    FROM claim WHERE claim_type_code = 'DERIVED_CLAIM'
    UNION ALL
    SELECT 'existing_derivation_inputs_available', count(*)::int FROM derivation_input
) coverage
ORDER BY item;

\echo 'Phase 24 classification summary'
SELECT classification_item, classification, finding
FROM (VALUES
    ('1 Samuel source availability',
     'SOURCE-BACKED',
     'Six manually-entered reference-point source records and unquoted citations cover 1 Samuel 4:4, 4:11, 5:1, 5:2, 7:1, and 7:2.'),
    ('Ark capture',
     'SOURCE-BACKED',
     'The Ark capture is represented as ark_covenant_captured_1sam4 (OTHER), with Ark subject and Philistine participation claims supported by EV_MT_1SA_4_11.'),
    ('Philistine movement to Ashdod',
     'SOURCE-BACKED',
     'The movement from Ebenezer to Ashdod is represented as a distinct OTHER event with occursAt Ashdod, supported by EV_MT_1SA_5_1.'),
    ('Placement in house of Dagon',
     'SOURCE-BACKED',
     'The house-of-Dagon placement is represented as a distinct OTHER event with occursAt house_dagon_ashdod, supported by EV_MT_1SA_5_2.'),
    ('Kiriath-jearim / Abinadab custody context',
     'SOURCE-BACKED',
     '1 Samuel 7:1-2 events preserve the house of Abinadab, Eleazar, and Kiriath-jearim claims with full provenance.'),
    ('Duration of twenty years',
     'DOCUMENTED BUT NOT STRUCTURED',
     'The source observation records that 1 Samuel 7:2 describes twenty years, but no duration proposition is created because the registry has no event-duration predicate.'),
    ('Joshua / 1 Samuel / 2 Samuel transport differences',
     'PRESERVED SOURCE DIFFERENCE',
     'Priestly carrying, Philistine movement/custody, and new-cart transport remain separate source-backed events with no automatic contradiction or violation classification.'),
    ('Phase 24 derivation use',
     'EXISTING GENUINE DERIVATIONS REUSED',
     'Phase 24 does not add artificial 1 Samuel derivations. The accepted Genesis chronology and cross-source derivations remain available for CHECK_DERIVATION_ELIGIBILITY demonstrations.'),
    ('Evaluation boundary',
     'NOT_STORED_BY_POLICY / NO INFERENCE',
     'No source text or quotations are stored; no truth, causation, compliance, punishment, theology, or evidence-sufficiency evaluation is persisted.')
) AS summary(classification_item, classification, finding)
ORDER BY classification_item;

\echo 'Phase 24 source-chain examples'
SELECT c.claim_key,
       p.predicate,
       coalesce(subject_entity.entity_key, subject_event.event_key) AS subject_key,
       coalesce(object_entity.entity_key, object_event.event_key, tv.text_value, tv.numeric_value::text) AS object_key,
       ev.evidence_key,
       ci.locator,
       sr.raw_content IS NULL AS raw_content_not_stored_by_policy,
       ci.quoted_text IS NULL AS quoted_text_not_stored_by_policy,
       d.dataset_key,
       s.source_key
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
LEFT JOIN entity subject_entity ON subject_entity.entity_id = p.subject_entity_id
LEFT JOIN event subject_event ON subject_event.event_id = p.subject_event_id
LEFT JOIN entity object_entity ON object_entity.entity_id = p.object_entity_id
LEFT JOIN event object_event ON object_event.event_id = p.object_event_id
LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN (
    'CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4',
    'CLAIM_ARK_MOVEMENT_ASHDOD_PLACE_1SAM5',
    'CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7'
)
ORDER BY c.claim_key;
