\set ON_ERROR_STOP on

DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN ('MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9')
    ) <> 4 THEN
        RAISE EXCEPTION 'Genesis 1:6-9 batch must have four Masoretic source records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL
               OR ci.citation_id IS NULL OR e.evidence_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:6-9 batch has incomplete structural provenance or undistributed text';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9')
          AND NOT EXISTS (
              SELECT 1
              FROM evidence e
              JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
              JOIN claim c ON c.claim_id = ce.claim_id
              WHERE e.source_record_id = sr.source_record_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:6-9 source record lacks a direct supported claim';
    END IF;
END $$;
