\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Blocking: structural and provenance integrity.
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.claim_type_code <> 'DERIVED_CLAIM'
        AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id)
    ) THEN RAISE EXCEPTION 'blocking: non-derived claim lacks evidence'; END IF;
    IF EXISTS (
        SELECT 1 FROM evidence e LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_id IS NULL
    ) THEN RAISE EXCEPTION 'blocking: evidence has broken provenance'; END IF;
    IF EXISTS (
        SELECT 1 FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
        LEFT JOIN source s ON s.source_id = d.source_id WHERE s.source_id IS NULL
    ) THEN RAISE EXCEPTION 'blocking: source record has broken provenance chain'; END IF;
    IF EXISTS (
        SELECT 1 FROM source_record WHERE raw_content IS NOT NULL AND content_hash IS NULL
    ) THEN RAISE EXCEPTION 'blocking: imported content has no content hash'; END IF;
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping WHERE confidence IS NOT NULL AND confidence NOT BETWEEN 0 AND 1
    ) THEN RAISE EXCEPTION 'blocking: mapping confidence is invalid'; END IF;
    IF EXISTS (
        SELECT source_identity_id, entity_id FROM entity_source_mapping WHERE mapping_status_code = 'ACTIVE'
        GROUP BY source_identity_id, entity_id HAVING count(*) > 1
    ) THEN RAISE EXCEPTION 'blocking: duplicate active entity mapping'; END IF;
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping
        WHERE mapping_status_code = 'ACTIVE' AND (justification IS NULL OR btrim(justification) = '')
    ) THEN RAISE EXCEPTION 'blocking: active reconciliation has no justification'; END IF;
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN evidence e ON e.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.source_id <> si.source_id
    ) THEN RAISE EXCEPTION 'blocking: reconciliation evidence comes from a different source'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim_evidence ce LEFT JOIN claim_evidence_relation_type rt
        ON rt.relation_type_code = ce.relation_type_code WHERE rt.relation_type_code IS NULL
    ) THEN RAISE EXCEPTION 'blocking: uncontrolled claim-evidence relation'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim_relation cr LEFT JOIN claim_relation_type rt
        ON rt.relation_type_code = cr.relation_type_code WHERE rt.relation_type_code IS NULL
    ) THEN RAISE EXCEPTION 'blocking: uncontrolled claim relation'; END IF;
    IF EXISTS (
        SELECT 1 FROM evidence e WHERE e.evidence_type_code = 'SOURCE_OBSERVATION'
        AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN RAISE EXCEPTION 'blocking: source observation lacks citation'; END IF;
    IF EXISTS (
        SELECT 1 FROM proposition p
        WHERE ((p.subject_entity_id IS NOT NULL)::int + (p.subject_event_id IS NOT NULL)::int) <> 1
           OR ((p.object_entity_id IS NOT NULL)::int + (p.object_event_id IS NOT NULL)::int
               + (p.object_typed_value_id IS NOT NULL)::int) <> 1
    ) THEN RAISE EXCEPTION 'blocking: proposition cardinality is invalid'; END IF;
    IF EXISTS (
        SELECT 1 FROM proposition p LEFT JOIN predicate pr
        ON pr.predicate_code = p.predicate
        AND pr.subject_kind_code = p.subject_kind_code
        AND pr.object_kind_code = p.object_kind_code
        WHERE pr.predicate_code IS NULL
    ) THEN RAISE EXCEPTION 'blocking: proposition uses an unregistered predicate or term kind'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.claim_type_code = 'DERIVED_CLAIM' AND c.derivation_id IS NULL
    ) THEN RAISE EXCEPTION 'blocking: derived claim lacks derivation'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.derivation_id IS NOT NULL AND c.claim_type_code <> 'DERIVED_CLAIM'
    ) THEN RAISE EXCEPTION 'blocking: non-derived claim has derivation'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.claim_type_code = 'DERIVED_CLAIM'
        AND NOT EXISTS (SELECT 1 FROM derivation_input di WHERE di.derivation_id = c.derivation_id)
    ) THEN RAISE EXCEPTION 'blocking: derivation has no inputs'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c JOIN derivation_input di ON di.derivation_id = c.derivation_id
        WHERE di.input_claim_id = c.claim_id
    ) THEN RAISE EXCEPTION 'blocking: derived claim is an input to its own derivation'; END IF;
    IF EXISTS (
        SELECT 1 FROM event_participation ep
        LEFT JOIN claim c ON c.claim_id = ep.asserting_claim_id
        WHERE c.claim_id IS NULL OR ep.event_id IS NULL OR ep.entity_id IS NULL
    ) THEN RAISE EXCEPTION 'blocking: event participation is not fully asserted'; END IF;

    -- Warnings: reviewable quality conditions that do not block.
    IF EXISTS (
        SELECT 1 FROM claim c WHERE c.claim_type_code <> 'DERIVED_CLAIM'
        AND NOT EXISTS (
            SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id
            AND ce.relation_type_code = 'SUPPORTS'
        )
    ) THEN RAISE WARNING 'warning: a non-derived claim has no supporting evidence'; END IF;
    IF EXISTS (
        SELECT 1 FROM source_record WHERE supersedes_source_record_id IS NOT NULL AND revision_label IS NULL
    ) THEN RAISE WARNING 'warning: superseding source record has no revision label'; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'CONTRADICTS'
        WHERE c.claim_status_code = 'ACTIVE'
        AND NOT EXISTS (
            SELECT 1 FROM claim_relation cr
            WHERE cr.relation_type_code = 'CONTRADICTS'
              AND (cr.related_claim_id = c.claim_id OR cr.claim_id = c.claim_id)
        )
    ) THEN RAISE WARNING 'warning: a claim has contradicting evidence but no recorded competing claim'; END IF;
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping
        WHERE mapping_status_code = 'ACTIVE' AND supporting_evidence_id IS NULL
    ) THEN RAISE WARNING 'warning: active reconciliation has no supporting evidence'; END IF;
END $$;
