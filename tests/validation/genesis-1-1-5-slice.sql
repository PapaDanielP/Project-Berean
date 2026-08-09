\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Genesis 1:1-5 must be represented as five distinct Masoretic source-record boundaries.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
    ) <> 5 THEN
        RAISE EXCEPTION 'Genesis 1:1-5 slice must have five source records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 structural source records must not store source text';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM citation c
        JOIN source_record sr ON sr.source_record_id = c.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
          AND c.quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 citations must not quote undistributed source text';
    END IF;

    -- Every slice source record has at least one citation, evidence item, and supported claim.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
          AND NOT EXISTS (SELECT 1 FROM citation c WHERE c.source_record_id = sr.source_record_id)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 source record lacks citation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
          AND NOT EXISTS (SELECT 1 FROM evidence e WHERE e.source_record_id = sr.source_record_id)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 source record lacks evidence';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5')
          AND NOT EXISTS (
              SELECT 1
              FROM evidence e
              JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
              WHERE e.source_record_id = sr.source_record_id
                AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 source record lacks a supported claim';
    END IF;

    -- Every slice evidence item must trace to citation/source-record/dataset/source.
    IF EXISTS (
        SELECT 1
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        LEFT JOIN citation c ON c.citation_id = ec.citation_id
        LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
        LEFT JOIN source s ON s.source_id = d.source_id
        WHERE e.evidence_key LIKE 'EV_MT_GEN_1_%'
          AND (c.citation_id IS NULL OR d.dataset_id IS NULL OR s.source_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 evidence lacks citation/source provenance';
    END IF;

    -- Every slice claim must have a lossless path to evidence, citation, source record, dataset, and source.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE 'CLAIM_MT_GEN_1_%'
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = e.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND sr.source_record_key LIKE 'MT_GEN_1_%'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 claim lacks supported provenance path';
    END IF;

    -- Genesis 1:1 demonstrates multiple evidence and multiple claim/proposition records on one verse boundary.
    IF (
        SELECT count(*)
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key = 'MT_GEN_1_1'
    ) < 2 THEN
        RAISE EXCEPTION 'Genesis 1:1 must demonstrate multiple evidence records on one source record';
    END IF;

    IF (
        SELECT count(DISTINCT c.claim_id)
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key = 'MT_GEN_1_1'
    ) < 2 THEN
        RAISE EXCEPTION 'Genesis 1:1 must demonstrate multiple claims on one source record';
    END IF;

    -- The conservative slice should not introduce derived, contradicting, or speculative relation claims.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE 'CLAIM_MT_GEN_1_%'
          AND c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 slice claims must remain direct source claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        WHERE c.claim_key LIKE 'CLAIM_MT_GEN_1_%'
          AND ce.relation_type_code <> 'SUPPORTS'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:1-5 slice should not add unsupported contrary evidence';
    END IF;
END $$;
