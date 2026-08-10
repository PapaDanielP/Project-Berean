\set ON_ERROR_STOP on

\echo 'Phase 24 registry sufficiency check (no schema, event_type, predicate, role, or ClaimRelation extension added)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'DEATH', 'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT')
ORDER BY event_type_code;
SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
FROM predicate WHERE predicate_code IN ('subjectOf', 'participatesIn', 'standingRequirementIn')
ORDER BY predicate_code;

\echo 'Phase 24 bounded source/citation/evidence summary'
SELECT s.source_key,
       d.dataset_key,
       sr.source_record_key,
       sr.source_location,
       sr.raw_content IS NULL AS raw_content_null,
       sr.content_hash IS NULL AS content_hash_null,
       ci.quoted_text IS NULL AS quoted_text_null,
       ev.evidence_key,
       EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = ev.evidence_id) AS supports_phase_claim
FROM source s
JOIN dataset d ON d.source_id = s.source_id
JOIN source_record sr ON sr.dataset_id = d.dataset_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
JOIN evidence ev ON ev.source_record_id = sr.source_record_id
WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
ORDER BY d.dataset_key, sr.source_record_key;

\echo 'Phase 24 bounded entities, mappings, events, propositions, claims, derivations, and inputs summary'
SELECT count(*)::int AS phase24_sources
FROM source WHERE source_key IN ('1KI_MT', '2CH_MT');

SELECT count(*)::int AS phase24_datasets
FROM dataset WHERE dataset_key IN ('1KI_MT_REF', '2CH_MT_REF');

SELECT count(*)::int AS phase24_source_records
FROM source_record WHERE source_record_key IN (
    'MT_1KI_8_3', 'MT_1KI_8_4', 'MT_1KI_8_6', 'MT_1KI_8_7', 'MT_1KI_8_8', 'MT_1KI_8_9',
    'MT_2CH_5_4', 'MT_2CH_5_5', 'MT_2CH_5_7', 'MT_2CH_5_8', 'MT_2CH_5_9', 'MT_2CH_5_10'
);

SELECT count(*)::int AS phase24_citations
FROM citation WHERE citation_key IN (
    'CITE_MT_1KI_8_3', 'CITE_MT_1KI_8_4', 'CITE_MT_1KI_8_6', 'CITE_MT_1KI_8_7', 'CITE_MT_1KI_8_8', 'CITE_MT_1KI_8_9',
    'CITE_MT_2CH_5_4', 'CITE_MT_2CH_5_5', 'CITE_MT_2CH_5_7', 'CITE_MT_2CH_5_8', 'CITE_MT_2CH_5_9', 'CITE_MT_2CH_5_10'
);

SELECT count(*)::int AS phase24_evidence
FROM evidence WHERE evidence_key IN (
    'EV_MT_1KI_8_3', 'EV_MT_1KI_8_4', 'EV_MT_1KI_8_6', 'EV_MT_1KI_8_7', 'EV_MT_1KI_8_8', 'EV_MT_1KI_8_9',
    'EV_MT_2CH_5_4', 'EV_MT_2CH_5_5', 'EV_MT_2CH_5_7', 'EV_MT_2CH_5_8', 'EV_MT_2CH_5_9', 'EV_MT_2CH_5_10'
);

SELECT count(*)::int AS phase24_events
FROM event WHERE event_key IN (
    'ark_covenant_taken_up_temple_placement',
    'ark_covenant_brought_up_temple_placement',
    'ark_covenant_placed_inner_sanctuary_solomon_temple',
    'ark_covenant_covered_under_cherubim_solomon_temple',
    'ark_covenant_poles_visible_holy_place_solomon_temple',
    'ark_covenant_tablets_only_content_solomon_temple'
);

SELECT count(*)::int AS phase24_propositions
FROM proposition p
JOIN event ev ON ev.event_id = p.object_event_id
WHERE ev.event_key IN (
    'ark_covenant_taken_up_temple_placement',
    'ark_covenant_brought_up_temple_placement',
    'ark_covenant_placed_inner_sanctuary_solomon_temple',
    'ark_covenant_covered_under_cherubim_solomon_temple',
    'ark_covenant_poles_visible_holy_place_solomon_temple',
    'ark_covenant_tablets_only_content_solomon_temple'
);

SELECT c.claim_type_code, count(*)::int AS count
FROM claim c
WHERE c.claim_key LIKE 'CLAIM\_1KI\_%' ESCAPE '\'
   OR c.claim_key LIKE 'CLAIM\_2CH\_%' ESCAPE '\'
   OR c.claim_key = 'CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED'
GROUP BY c.claim_type_code
ORDER BY c.claim_type_code;

SELECT en.entity_key,
       si.source_identity_key,
       esm.mapping_status_code,
       ev.evidence_key AS supporting_evidence_key
FROM entity_source_mapping esm
JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
JOIN entity en ON en.entity_id = esm.entity_id
LEFT JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
WHERE si.source_identity_key IN (
    'mt-ark-1ki8', 'mt-poles-1ki8', 'mt-ark-bearers-1ki8',
    'mt-ark-2ch5', 'mt-poles-2ch5', 'mt-ark-bearers-2ch5'
)
ORDER BY en.entity_key, si.source_identity_key;

SELECT dc.claim_key AS derived_claim_key,
       d.method,
       count(di.derivation_input_id)::int AS derivation_input_count
FROM claim dc
JOIN derivation d ON d.derivation_id = dc.derivation_id
LEFT JOIN derivation_input di ON di.derivation_id = d.derivation_id
WHERE dc.claim_key = 'CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED'
GROUP BY dc.claim_key, d.method;

SELECT classification_item, classification, finding
FROM (VALUES
    ('1 Kings and 2 Chronicles source availability',
     'SOURCE-BACKED',
     'Exactly two new sources, two new datasets, twelve manually-entered reference-point source records, twelve unquoted citations, and twelve cited source observations exist for the bounded temple-placement slice.'),
    ('Temple-placement event representation',
     'STRUCTURALLY REPRESENTED',
     'The bounded slice uses six OTHER events and eleven propositions with the existing subjectOf/participatesIn predicates; no new event type, predicate, role, or table was added.'),
    ('Ark and poles canonical reuse',
     'SUPPORTED',
     'The existing canonical ark_of_covenant and poles_ark_covenant entities are reused across both source traditions, with no duplicate Ark or poles entity introduced.'),
    ('Bearer organization reuse',
     'DOCUMENTED UNRESOLVED DECISION',
     'The existing priests_levites_ark_bearers organization is reused for both source traditions to avoid manufacturing a second canonical bearer entity from the wording difference alone.'),
    ('Priests versus Levites wording at ark take-up',
     'PRESERVED SOURCE DIFFERENCE',
     '1 Kings 8:3 names priests taking up the ark, while 2 Chronicles 5:4 names Levites taking up the ark. The difference remains visible in separate direct claims, evidence observations, and source identities, and is not harmonized here.'),
    ('Priests versus Levites ClaimRelation',
     'RUNTIME VERIFIED',
     'No ClaimRelation row is attached to the Phase 24 bearer claims. The wording difference is preserved without adding CONTRADICTS, QUALIFIES, REFINES, DUPLICATES, or SUPERSEDES.'),
    ('Inner sanctuary placement',
     'SOURCE-BACKED',
     'Both traditions have direct source claims for the Ark in the inner-sanctuary placement event and for the source-named bearers participating in that event.'),
    ('Cherubim covering observation',
     'SOURCE-BACKED',
     'Both traditions have direct source claims for the Ark and its poles in the cherubim-covering event, without introducing a new temple-cherubim canonical entity.'),
    ('Pole-visibility observation',
     'SOURCE-BACKED',
     'Both traditions have separate direct source claims for the shared observation that the poles were visible from the Holy Place but not from outside at the time of each source''s own writing.'),
    ('Tablets-only content observation',
     'SOURCE-BACKED',
     'Both traditions have direct source claims for the Ark as the subject of the tablets-only-content event and for the tablets as the only named contents in that locator.'),
    ('Cross-source pole-visibility derivation',
     'STRUCTURALLY REPRESENTED',
     'One DERIVED_CLAIM and one Derivation with two DerivationInput claim rows are present for the shared pole-visibility observation only, following the existing cross-source comparison pattern.'),
    ('Bearer-wording harmonization',
     'NOT DERIVED',
     'The derivation does not merge or resolve the priests-versus-Levites difference and does not derive a new bearer claim.'),
    ('Compliance, violation, causation, contradiction, and theology',
     'INTENTIONALLY EXCLUDED',
     'No claim concludes compliance with Exodus 25:15, violation, causal consequence, punishment, contradiction, or theological meaning from the temple-placement slice.'),
    ('Source-specific identity reconciliation',
     'RUNTIME VERIFIED',
     'Six source_identity rows and six ACTIVE entity_source_mapping rows reconcile 1 Kings and 2 Chronicles source identities for the ark, poles, and bearers to the same canonical entities with distinct supporting evidence.'),
    ('Additional Solomon-temple or later Ark narrative detail',
     'ACQUISITION PENDING',
     'No additional participants, place graph, broader inventory, chronology, or later references such as Jeremiah 3:16 are populated in this bounded phase.')
) AS coverage(classification_item, classification, finding)
ORDER BY classification_item;
