\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Multiple independent source claims share one normalized proposition.
    IF (
        SELECT count(DISTINCT c.claim_id)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE s.entity_key = 'adam'
          AND o.entity_key = 'seth'
          AND p.predicate = 'fatherOf'
          AND c.claim_key IN ('CLAIM_MT_ADAM_FATHER_SETH', 'CLAIM_LXX_ADAM_FATHER_SETH')
          AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase6: independent claims do not share the Adam fatherOf Seth proposition';
    END IF;

    -- Reverse provenance traversal from proposition back to source.
    IF (
        SELECT count(DISTINCT s.source_key)
        FROM proposition p
        JOIN claim c ON c.proposition_id = p.proposition_id
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        JOIN citation ci ON ci.citation_id = ec.citation_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key IN ('CLAIM_MT_ADAM_FATHER_SETH', 'CLAIM_LXX_ADAM_FATHER_SETH')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase6: reverse proposition-to-source provenance traversal is incomplete';
    END IF;

    -- Multi-source derivation remains distinguishable from direct source claims.
    IF NOT EXISTS (
        SELECT 1
        FROM claim dc
        JOIN derivation d ON d.derivation_id = dc.derivation_id
        WHERE dc.claim_key = 'CLAIM_XSRC_ADAM_FATHER_SETH_SHARED_DERIVED'
          AND dc.claim_type_code = 'DERIVED_CLAIM'
          AND (
              SELECT count(DISTINCT src.source_key)
              FROM derivation_input di
              JOIN claim ic ON ic.claim_id = di.input_claim_id
              JOIN claim_evidence ce ON ce.claim_id = ic.claim_id AND ce.relation_type_code = 'SUPPORTS'
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN source_record sr ON sr.source_record_id = e.source_record_id
              JOIN dataset ds ON ds.dataset_id = sr.dataset_id
              JOIN source src ON src.source_id = ds.source_id
              WHERE di.derivation_id = d.derivation_id
                AND src.source_key IN ('GEN_MT', 'GEN_LXX')
          ) = 2
    ) THEN
        RAISE EXCEPTION 'phase6: multi-source derivation is missing or lacks both source inputs';
    END IF;

    -- Contradictory claims are preserved as competing active claims with independent provenance.
    IF (
        SELECT count(*)
        FROM claim_relation cr
        JOIN claim a ON a.claim_id = cr.claim_id
        JOIN claim b ON b.claim_id = cr.related_claim_id
        WHERE cr.relation_type_code = 'CONTRADICTS'
          AND a.claim_key = 'CLAIM_LXX_ADAM_AGE_AT_SETH'
          AND b.claim_key = 'CLAIM_MT_ADAM_AGE_AT_SETH'
          AND a.claim_status_code = 'ACTIVE'
          AND b.claim_status_code = 'ACTIVE'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase6: contradictory Adam age claims are not preserved';
    END IF;

    -- EntitySourceMapping active rows require status, confidence, justification, and same-source evidence.
    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN evidence e ON e.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE esm.mapping_status_code = 'ACTIVE'
          AND (esm.confidence IS NULL OR esm.justification IS NULL OR btrim(esm.justification) = ''
               OR esm.supporting_evidence_id IS NULL OR d.source_id <> si.source_id)
    ) THEN
        RAISE EXCEPTION 'phase6: active entity-source mapping audit fields are incomplete';
    END IF;

    -- Claim SUPERSEDES preserves the superseded claim and its evidence rather than deleting it.
    IF NOT EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim active_claim ON active_claim.claim_id = cr.claim_id
        JOIN claim old_claim ON old_claim.claim_id = cr.related_claim_id
        JOIN claim_evidence ce ON ce.claim_id = old_claim.claim_id AND ce.relation_type_code = 'SUPPORTS'
        WHERE cr.relation_type_code = 'SUPERSEDES'
          AND active_claim.claim_key = 'CLAIM_MT_ADAM_AGE_AT_SETH'
          AND old_claim.claim_key = 'CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT'
          AND old_claim.claim_status_code = 'SUPERSEDED'
    ) THEN
        RAISE EXCEPTION 'phase6: Claim SUPERSEDES lifecycle is not preserved';
    END IF;

    -- Event participation is projected from claim-asserted propositions.
    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        JOIN claim c ON c.claim_id = ep.asserting_claim_id
        WHERE ev.event_key = 'seth_begetting'
          AND en.entity_key = 'adam'
          AND ep.role_code = 'PARENT'
          AND c.claim_key = 'CLAIM_ADAM_PARENT_SETH_BEGETTING'
    ) THEN
        RAISE EXCEPTION 'phase6: event participation projection is missing expected parent role';
    END IF;
END $$;
