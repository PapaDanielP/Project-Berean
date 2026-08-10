\set ON_ERROR_STOP on

\echo 'Phase 16 artifact entity coverage (structural/source-backed; not semantic completeness)'
SELECT en.entity_key,
       en.entity_type_code,
       en.canonical_name,
       count(DISTINCT esm.entity_source_mapping_id) FILTER (WHERE esm.mapping_status_code = 'ACTIVE') AS active_mappings,
       count(DISTINCT c.claim_id) AS claims,
       count(DISTINCT p.proposition_id) AS propositions,
       count(DISTINCT ep.event_id) AS projected_event_participations
FROM entity en
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key IN ('noahs_ark', 'ark_of_covenant', 'moses', 'bezalel', 'door_noahs_ark',
                        'window_noahs_ark', 'mercy_seat', 'cherubim_kapporet',
                        'rings_ark_covenant', 'poles_ark_covenant', 'tablets_of_testimony')
GROUP BY en.entity_key, en.entity_type_code, en.canonical_name
ORDER BY en.entity_key;

\echo 'Phase 16 predicate registry additions'
SELECT predicate_code, subject_kind_code, object_kind_code
FROM predicate
WHERE predicate_code IN ('builderIn', 'lengthCubits', 'widthCubits', 'heightCubits',
                          'madeOfMaterial', 'overlaidWithMaterial', 'hasComponent', 'containsContent')
ORDER BY predicate_code;

\echo 'Phase 16 preserved source-specific disagreement'
SELECT a.claim_key AS claim, b.claim_key AS related_claim, cr.relation_type_code
FROM claim_relation cr
JOIN claim a ON a.claim_id = cr.claim_id
JOIN claim b ON b.claim_id = cr.related_claim_id
WHERE a.claim_key IN ('CLAIM_BEZALEL_BUILDER_ARK_COVENANT', 'CLAIM_MOSES_BUILDER_ARK_COVENANT');

\echo 'Phase 16 source availability and semantic classification'
SELECT item, classification, finding
FROM (VALUES
    ('Noah''s Ark construction/instruction/dimensions/materials/components (Genesis 6:14-16,6:22)',
     'SUPPORTED', 'RUNTIME VERIFIED as source-backed, direct, fully provenanced claims.'),
    ('Noah''s Ark entering event (Genesis 7:7)',
     'SUPPORTED', 'RUNTIME VERIFIED; reuses the existing noahs_ark/noah entities.'),
    ('Ark of the Covenant construction/instruction/dimensions/materials/components/contents (Exodus 25,37,40)',
     'SUPPORTED', 'RUNTIME VERIFIED; ark_of_covenant now has an active, evidence-backed source-identity mapping.'),
    ('Bezalel vs Moses builder attribution (Exodus 37:1 vs Deuteronomy 10:3)',
     'DOCUMENTED UNRESOLVED DECISION', 'A genuine source disagreement, preserved via claim_relation CONTRADICTS rather than resolved.'),
    ('Exodus 25:15 pole-handling/transport restriction', 'SEMANTIC PRECISION GAP',
     'A standing requirement, not a single event; forcing it into participatesIn would misrepresent its meaning, so it is intentionally left unpopulated.'),
    ('Modern-unit dimension conversion', 'INTENTIONALLY EXCLUDED',
     'No derivation was created; original cubit units are preserved via unit-suffixed predicates.'),
    ('Numbers/later transport-by-Kohathites and other lifecycle events', 'SOURCE AVAILABILITY GAP',
     'Not populated in this phase; would require its own bounded slice and source records.'),
    ('Artifact-specific tables, JSON semantic payloads, or a participant store', 'INTENTIONALLY EXCLUDED',
     'The existing Entity/SourceIdentity/Proposition/Claim/Evidence/Event architecture proved sufficient; no new table was added.')
) AS coverage(item, classification, finding);
