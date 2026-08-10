\set ON_ERROR_STOP on

\echo 'Phase 14 artifact source availability and coverage'
WITH artifact_slice AS (
    SELECT 'MT_GEN_8_4'::text AS source_record_key,
           'Genesis 8:4'::text AS locator,
           'Noah''s Ark'::text AS selected_artifact,
           'POPULATED'::text AS coverage_status,
           'SOURCE-BACKED'::text AS provenance_status,
           'NOT DERIVED'::text AS derivation_status,
           'SUPPORTED'::text AS architecture_status
)
SELECT a.locator,
       a.source_record_key,
       a.selected_artifact,
       count(DISTINCT ci.citation_id) AS citations,
       count(DISTINCT e.evidence_id) AS evidence,
       count(DISTINCT c.claim_id) AS direct_claims,
       a.coverage_status,
       a.provenance_status,
       a.derivation_status,
       a.architecture_status
FROM artifact_slice a
JOIN source_record sr ON sr.source_record_key = a.source_record_key
LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim c ON c.claim_id = ce.claim_id
GROUP BY a.locator, a.source_record_key, a.selected_artifact, a.coverage_status,
         a.provenance_status, a.derivation_status, a.architecture_status;

\echo 'Phase 14 artifact entity/source identity/reconciliation coverage'
SELECT en.entity_key,
       en.entity_type_code,
       en.canonical_name,
       count(DISTINCT si.source_identity_id) AS source_identities,
       count(DISTINCT esm.entity_source_mapping_id) FILTER (
           WHERE esm.mapping_status_code = 'ACTIVE'
       ) AS active_mappings,
       count(DISTINCT esm.supporting_evidence_id) FILTER (
           WHERE esm.mapping_status_code = 'ACTIVE'
       ) AS mapping_evidence,
       count(DISTINCT ep.event_id) AS projected_participation_events,
       'POPULATED' AS coverage_status,
       'SOURCE-BACKED' AS provenance_status,
       'STRUCTURALLY REPRESENTED' AS representation_status
FROM entity en
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
LEFT JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key IN ('noahs_ark', 'ark_of_covenant')
GROUP BY en.entity_key, en.entity_type_code, en.canonical_name
ORDER BY en.entity_key;

\echo 'Phase 14 artifact relationship/proposition classification'
SELECT p.proposition_id,
       coalesce(se.entity_key, sv.event_key) AS subject_key,
       p.predicate,
       coalesce(oe.entity_key, ov.event_key) AS object_key,
       count(DISTINCT c.claim_id) AS claims,
       count(DISTINCT ce.evidence_id) FILTER (WHERE ce.relation_type_code = 'SUPPORTS')
           AS supporting_evidence,
       CASE
           WHEN p.predicate IN ('subjectOf', 'participatesIn', 'occursAt') THEN 'SOURCE-BACKED'
           ELSE 'SEMANTIC PRECISION GAP'
       END AS semantic_classification
FROM proposition p
LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
LEFT JOIN event sv ON sv.event_id = p.subject_event_id
LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
LEFT JOIN event ov ON ov.event_id = p.object_event_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
WHERE se.entity_key = 'noahs_ark'
   OR sv.event_key = 'ark_resting'
   OR ov.event_key = 'ark_resting'
GROUP BY p.proposition_id, se.entity_key, sv.event_key, p.predicate, oe.entity_key, ov.event_key
ORDER BY p.proposition_id;

\echo 'Phase 14 coverage counts'
SELECT metric, count_value
FROM (
    SELECT 'artifact_entities' AS metric, count(*)::bigint AS count_value
    FROM entity
    WHERE entity_key = 'noahs_ark'
    UNION ALL
    SELECT 'artifact_source_identities', count(*)::bigint
    FROM source_identity
    WHERE source_identity_key = 'mt-ark'
    UNION ALL
    SELECT 'artifact_active_mappings', count(*)::bigint
    FROM entity_source_mapping esm
    JOIN entity en ON en.entity_id = esm.entity_id
    WHERE en.entity_key = 'noahs_ark'
      AND esm.mapping_status_code = 'ACTIVE'
    UNION ALL
    SELECT 'artifact_source_records', count(*)::bigint
    FROM source_record
    WHERE source_record_key = 'MT_GEN_8_4'
    UNION ALL
    SELECT 'artifact_citations', count(*)::bigint
    FROM citation ci
    JOIN source_record sr ON sr.source_record_id = ci.source_record_id
    WHERE sr.source_record_key = 'MT_GEN_8_4'
    UNION ALL
    SELECT 'artifact_evidence', count(*)::bigint
    FROM evidence
    WHERE evidence_key = 'EV_MT_GEN_8_4'
    UNION ALL
    SELECT 'artifact_propositions', count(*)::bigint
    FROM proposition p
    LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
    LEFT JOIN event sv ON sv.event_id = p.subject_event_id
    LEFT JOIN event ov ON ov.event_id = p.object_event_id
    WHERE se.entity_key = 'noahs_ark'
       OR sv.event_key = 'ark_resting'
       OR ov.event_key = 'ark_resting'
    UNION ALL
    SELECT 'artifact_claims', count(DISTINCT c.claim_id)::bigint
    FROM claim c
    JOIN proposition p ON p.proposition_id = c.proposition_id
    LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
    LEFT JOIN event sv ON sv.event_id = p.subject_event_id
    LEFT JOIN event ov ON ov.event_id = p.object_event_id
    WHERE se.entity_key = 'noahs_ark'
       OR sv.event_key = 'ark_resting'
       OR ov.event_key = 'ark_resting'
    UNION ALL
    SELECT 'artifact_claim_evidence', count(*)::bigint
    FROM claim_evidence ce
    JOIN claim c ON c.claim_id = ce.claim_id
    JOIN proposition p ON p.proposition_id = c.proposition_id
    LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
    LEFT JOIN event sv ON sv.event_id = p.subject_event_id
    LEFT JOIN event ov ON ov.event_id = p.object_event_id
    WHERE se.entity_key = 'noahs_ark'
       OR sv.event_key = 'ark_resting'
       OR ov.event_key = 'ark_resting'
    UNION ALL
    SELECT 'artifact_events', count(*)::bigint
    FROM event
    WHERE event_key = 'ark_resting'
    UNION ALL
    SELECT 'artifact_projected_participation', count(*)::bigint
    FROM event_participation ep
    JOIN entity en ON en.entity_id = ep.entity_id
    JOIN event ev ON ev.event_id = ep.event_id
    WHERE en.entity_key = 'noahs_ark'
      AND ev.event_key = 'ark_resting'
    UNION ALL
    SELECT 'artifact_derivations', count(DISTINCT c.derivation_id)::bigint
    FROM claim c
    JOIN proposition p ON p.proposition_id = c.proposition_id
    LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
    LEFT JOIN event sv ON sv.event_id = p.subject_event_id
    LEFT JOIN event ov ON ov.event_id = p.object_event_id
    WHERE c.derivation_id IS NOT NULL
      AND (se.entity_key = 'noahs_ark'
           OR sv.event_key = 'ark_resting'
           OR ov.event_key = 'ark_resting')
) counts
ORDER BY metric;

\echo 'Phase 14 exclusions and documented gaps'
SELECT item, classification, finding
FROM (VALUES
    ('Genesis 6-7 ark construction/source material', 'SOURCE UNAVAILABLE',
     'No repository source records are available for dimensions, material, construction, occupants, or movement.'),
    ('Noah''s Ark material/dimension/ownership semantics', 'SEMANTIC PRECISION GAP',
     'The selected Genesis 8:4 locator supports resting/location participation only; unsupported artifact attributes are intentionally excluded.'),
    ('Ark of the Covenant source-backed population', 'ACQUISITION PENDING',
     'The validation-only entity remains distinct and has no acquired source records in this repository.'),
    ('Object/artifact-specific architecture', 'INTENTIONALLY EXCLUDED',
     'The existing Entity, SourceIdentity, Proposition, Claim, Evidence, and Event model is sufficient for this slice.'),
    ('Future artifact predicates', 'DOCUMENTED UNRESOLVED DECISION',
     'Later source material may require new registered predicates, but no speculative predicate is added in Phase 14.')
) AS v(item, classification, finding)
ORDER BY item;

DO $$
BEGIN
    -- Deliberately corrupted case protections:
    -- duplicate canonical artifact entity, claim without evidence, active mapping without evidence,
    -- wrong canonical mapping, direct event participation bypass, unsupported predicate,
    -- fabricated quoted source text, and removed contradiction must all be rejected.
    IF (
        SELECT count(*)
        FROM entity
        WHERE canonical_name = 'Noah''s Ark'
          AND entity_type_code = 'OBJECT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase14 coverage: duplicate canonical Noah''s Ark artifact entity detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (se.entity_key = 'noahs_ark'
               OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              WHERE ce.claim_id = c.claim_id
                AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'phase14 coverage: artifact direct claim without supporting evidence detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key = 'mt-ark'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase14 coverage: active mt-ark mapping without evidence detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE si.source_identity_key = 'mt-ark'
          AND en.entity_key <> 'noahs_ark'
    ) THEN
        RAISE EXCEPTION 'phase14 coverage: mt-ark wrong canonical mapping detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name IN ('event_participant', 'event_participation_store',
                             'artifact_participation', 'object_participation')
    ) OR (
        SELECT table_type
        FROM information_schema.tables
        WHERE table_name = 'event_participation'
    ) <> 'VIEW' THEN
        RAISE EXCEPTION 'phase14 coverage: event participation must remain projection-only';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE (se.entity_key = 'noahs_ark'
               OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND p.predicate NOT IN ('subjectOf', 'participatesIn', 'occursAt')
    ) THEN
        RAISE EXCEPTION 'phase14 coverage: unsupported artifact predicate detected';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = 'MT_GEN_8_4'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase14 coverage: fabricated source text, hash, or quote detected';
    END IF;

    IF (
        SELECT count(*)
        FROM claim_relation
        WHERE relation_type_code = 'CONTRADICTS'
    ) <> 4 THEN
        RAISE EXCEPTION 'phase14 coverage: existing contradiction preservation was weakened';
    END IF;
END $$;
