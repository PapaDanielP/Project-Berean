\set ON_ERROR_STOP on

\echo 'Phase 15 rich persistent artifact coverage'
SELECT 'Noah''s Ark' AS artifact,
       'SUPPORTED' AS entity_status,
       'RUNTIME VERIFIED' AS provenance_status,
       count(DISTINCT si.source_identity_id) AS source_identities,
       count(DISTINCT esm.entity_source_mapping_id) FILTER (WHERE esm.mapping_status_code = 'ACTIVE') AS active_mappings,
       count(DISTINCT c.claim_id) AS direct_claims,
       count(DISTINCT ep.event_id) AS projected_events,
       count(DISTINCT c.derivation_id) AS derivations
FROM entity en
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
LEFT JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key = 'noahs_ark';

\echo 'Phase 15 source and semantic availability'
SELECT item, classification
FROM (VALUES
    ('Genesis 8:4 resting participation', 'SUPPORTED'),
    ('Construction, instructions, dimensions, materials, components, contents, transport, builders', 'SOURCE AVAILABILITY GAP'),
    ('Ark of the Covenant source-backed semantics', 'ACQUISITION PENDING'),
    ('Modern-unit conversion and derived dimensions', 'SEMANTIC PRECISION GAP'),
    ('Artifact-specific tables, JSON semantics, and participant store', 'INTENTIONALLY EXCLUDED')
) AS coverage(item, classification);
