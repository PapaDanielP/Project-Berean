\set ON_ERROR_STOP on

-- Phase 15 re-exercises the existing source-backed Noah's Ark slice without adding
-- unavailable construction, dimensions, materials, components, or contents.
DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM entity
        WHERE canonical_name = 'Noah''s Ark'
          AND entity_type_code = 'OBJECT'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 15 requires exactly one canonical Noah''s Ark OBJECT entity';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key = 'MT_GEN_8_4'
          AND sr.source_location = 'Genesis 8:4'
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
          AND sr.raw_content IS NULL
          AND sr.content_hash IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 15 source record must remain the acquired locator-only Genesis 8:4 record';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM citation ci
        JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        WHERE sr.source_record_key = 'MT_GEN_8_4'
          AND (ci.citation_key <> 'CITE_MT_GEN_8_4'
               OR ci.locator <> 'Genesis 8:4'
               OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Phase 15 forbids fabricated Genesis 8:4 quotation or locator data';
    END IF;

    IF (
        SELECT count(*)
        FROM source_identity si
        JOIN source s ON s.source_id = si.source_id
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        WHERE si.source_identity_key = 'mt-ark'
          AND s.source_key = 'GEN_MT'
          AND en.entity_key = 'noahs_ark'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.confidence IS NOT NULL
          AND btrim(coalesce(esm.justification, '')) <> ''
          AND sr.source_record_key = 'MT_GEN_8_4'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 15 requires one auditable, evidence-backed mt-ark mapping';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE (se.entity_key = 'noahs_ark'
               OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND (
              p.predicate NOT IN ('participatesIn', 'subjectOf', 'occursAt')
              OR (c.claim_type_code = 'DIRECT_SOURCE_CLAIM' AND p.predicate = 'yearsFromCreation')
              OR (c.claim_type_code = 'DIRECT_SOURCE_CLAIM' AND NOT EXISTS (
                  SELECT 1
                  FROM claim_evidence ce
                  JOIN evidence e ON e.evidence_id = ce.evidence_id
                  JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
                  JOIN citation ci ON ci.citation_id = ec.citation_id
                  JOIN source_record sr ON sr.source_record_id = e.source_record_id
                  WHERE ce.claim_id = c.claim_id
                    AND ce.relation_type_code = 'SUPPORTS'
                    AND sr.source_record_key = 'MT_GEN_8_4'
                    AND ci.locator = 'Genesis 8:4'
              ))
          )
    ) THEN
        RAISE EXCEPTION 'Phase 15 artifact semantics are unsupported, non-provenanced, or improperly direct';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DERIVED_CLAIM'
          AND (se.entity_key = 'noahs_ark'
               OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND (c.derivation_id IS NULL OR NOT EXISTS (
              SELECT 1 FROM derivation_input di WHERE di.derivation_id = c.derivation_id
          ))
    ) THEN
        RAISE EXCEPTION 'Phase 15 derived artifact claim lacks complete derivation inputs';
    END IF;

    IF (
        SELECT count(*)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN claim c ON c.claim_id = ep.asserting_claim_id
        WHERE en.entity_key = 'noahs_ark'
          AND ev.event_key = 'ark_resting'
          AND ep.role_code = 'PARTICIPANT'
          AND c.claim_key = 'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT'
    ) <> 1
       OR (SELECT table_type FROM information_schema.tables
           WHERE table_name = 'event_participation') <> 'VIEW'
       OR EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_name IN ('event_participant', 'artifact', 'object', 'thing',
                                'artifact_attribute', 'artifact_component', 'object_relationship')
       ) THEN
        RAISE EXCEPTION 'Phase 15 requires proposition-projected participation and no artifact-specific store';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name IN ('entity', 'proposition', 'claim')
          AND data_type IN ('json', 'jsonb')
    ) THEN
        RAISE EXCEPTION 'Phase 15 forbids JSON semantic payloads';
    END IF;
END $$;
