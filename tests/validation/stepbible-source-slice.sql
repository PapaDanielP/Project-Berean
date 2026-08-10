\set ON_ERROR_STOP on

DO $$
DECLARE
    pinned_commit CONSTANT TEXT := 'b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39';
    record_hash CONSTANT TEXT := '28cdf66fc9d5c6e913595bbba12adc2a8059fb066cbcb0019d677ae883836e11';
BEGIN
    -- The STEP Bible source and dataset exist and are distinct from the Masoretic reference source.
    IF NOT EXISTS (
        SELECT 1 FROM dataset d
        JOIN source s ON s.source_id = d.source_id
        WHERE d.dataset_key = 'STEP_TAHOT_GEN' AND s.source_key = 'STEP_TAHOT'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: dataset STEP_TAHOT_GEN is missing or not under source STEP_TAHOT';
    END IF;
    IF EXISTS (
        SELECT 1 FROM dataset d
        JOIN source s ON s.source_id = d.source_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF') AND s.source_key = 'STEP_TAHOT'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: STEP Bible data was merged into the Masoretic reference source';
    END IF;

    -- The dataset records the pinned revision, the file-level license, and the attribution.
    IF NOT EXISTS (
        SELECT 1 FROM dataset
        WHERE dataset_key = 'STEP_TAHOT_GEN'
          AND version = pinned_commit
          AND edition_label LIKE '%' || pinned_commit || '%'
          AND license_status LIKE '%CC BY 4.0%'
          AND license_status LIKE '%STEPBible.org%'
          AND license_status LIKE '%Tyndale House%'
          AND acquisition_method LIKE '%' || pinned_commit || '%'
          AND transformation_notes IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: dataset must record the pinned commit, the file-level license, the required attribution, and transformation notes';
    END IF;

    -- Exactly one acquired source record, carrying the inspected content hash and the pinned revision.
    IF (
        SELECT count(*) FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'STEP_TAHOT_GEN'
    ) <> 1 THEN
        RAISE EXCEPTION 'STEP Bible acquisition: expected exactly one acquired Genesis source record';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM source_record
        WHERE source_record_key = 'STEP_TAHOT_GEN_1_1'
          AND content_hash = record_hash
          AND revision_label = pinned_commit
          AND source_location LIKE '%' || pinned_commit || '%'
          AND source_location LIKE '%Gen.1.1'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: source record must record the inspected content hash, the pinned revision, and the upstream file locator';
    END IF;

    -- No upstream payload is stored: no raw content and no quoted text.
    IF EXISTS (
        SELECT 1 FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE d.dataset_key = 'STEP_TAHOT_GEN'
          AND (sr.raw_content IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: upstream payload must not be redistributed in raw_content or quoted_text';
    END IF;

    -- The citation preserves the upstream source-locator format.
    IF NOT EXISTS (
        SELECT 1 FROM citation ci
        JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        WHERE ci.citation_key = 'CITE_STEP_TAHOT_GEN_1_1'
          AND sr.source_record_key = 'STEP_TAHOT_GEN_1_1'
          AND ci.locator = 'Gen.1.1'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: citation must reference the acquired source record with the upstream locator Gen.1.1';
    END IF;

    -- Every acquired evidence record has complete Evidence -> SourceRecord -> Dataset -> Source
    -- provenance and a citation into its own source record.
    IF (
        SELECT count(*) FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE s.source_key = 'STEP_TAHOT'
    ) <> 2 THEN
        RAISE EXCEPTION 'STEP Bible acquisition: expected two source observations with complete provenance';
    END IF;
    IF EXISTS (
        SELECT 1 FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'STEP_TAHOT_GEN'
          AND NOT EXISTS (
              SELECT 1 FROM evidence_citation ec
              JOIN citation ci ON ci.citation_id = ec.citation_id
              WHERE ec.evidence_id = e.evidence_id AND ci.source_record_id = sr.source_record_id
          )
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: evidence lacks a citation to its own source record';
    END IF;

    -- Every imported claim is a supported direct source claim with a registered predicate.
    IF (
        SELECT count(*) FROM claim WHERE claim_key LIKE 'CLAIM_STEP_TAHOT_%'
    ) <> 3 THEN
        RAISE EXCEPTION 'STEP Bible acquisition: expected exactly three imported STEP Bible claims';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'CLAIM_STEP_TAHOT_%'
          AND (c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
               OR c.derivation_id IS NOT NULL
               OR NOT EXISTS (
                   SELECT 1 FROM claim_evidence ce
                   JOIN evidence e ON e.evidence_id = ce.evidence_id
                   JOIN source_record sr ON sr.source_record_id = e.source_record_id
                   JOIN dataset d ON d.dataset_id = sr.dataset_id
                   WHERE ce.claim_id = c.claim_id
                     AND ce.relation_type_code = 'SUPPORTS'
                     AND d.dataset_key = 'STEP_TAHOT_GEN'
               ))
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: every imported claim must be a direct, non-derived claim supported by STEP Bible evidence';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        WHERE c.claim_key LIKE 'CLAIM_STEP_TAHOT_%'
          AND p.predicate NOT IN ('subjectOf', 'participatesIn')
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: imported claims must not introduce a new predicate';
    END IF;

    -- Claims are source-specific but share the already-normalized Genesis 1:1 propositions, so
    -- no duplicate proposition or duplicate GEN_MT_REF source record was created.
    IF EXISTS (
        SELECT 1 FROM claim step
        JOIN proposition p ON p.proposition_id = step.proposition_id
        WHERE step.claim_key LIKE 'CLAIM_STEP_TAHOT_%'
          AND NOT EXISTS (
              SELECT 1 FROM claim mt
              WHERE mt.proposition_id = step.proposition_id
                AND mt.claim_key LIKE 'CLAIM_MT_GEN_1_1\_%' ESCAPE '\'
          )
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: imported claims must reuse the existing Genesis 1:1 propositions rather than duplicating them';
    END IF;
    IF (
        SELECT count(*) FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key = 'gen1_1_creation_statement'
    ) <> 3 THEN
        RAISE EXCEPTION 'STEP Bible acquisition: the Genesis 1:1 proposition set was duplicated or altered';
    END IF;

    -- The Masoretic structural dataset is untouched by the acquisition batch.
    IF (
        SELECT count(*) FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF' AND sr.source_record_key = 'MT_GEN_1_1'
          AND sr.raw_content IS NULL AND sr.content_hash IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'STEP Bible acquisition: the Masoretic Genesis 1:1 structural record was altered';
    END IF;

    -- The acquisition batch is bounded: no other Genesis locator was imported from STEP Bible.
    IF EXISTS (
        SELECT 1 FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'STEP_TAHOT_GEN' AND sr.source_record_key <> 'STEP_TAHOT_GEN_1_1'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: batch must remain limited to the Gen.1.1 locator';
    END IF;

    -- No reconciliation, derivation, or claim relation is introduced by the acquisition batch.
    IF EXISTS (
        SELECT 1 FROM source_identity si
        JOIN source s ON s.source_id = si.source_id
        WHERE s.source_key = 'STEP_TAHOT'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: batch must not introduce source-identity reconciliation';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c ON c.claim_id IN (cr.claim_id, cr.related_claim_id)
        WHERE c.claim_key LIKE 'CLAIM_STEP_TAHOT_%'
    ) THEN
        RAISE EXCEPTION 'STEP Bible acquisition: batch must not introduce claim relations';
    END IF;
END $$;

\echo 'STEP Bible acquisition status'
SELECT s.source_key,
       d.dataset_key,
       d.version AS pinned_commit,
       count(DISTINCT sr.source_record_id) AS source_records,
       count(DISTINCT ci.citation_id) AS citations,
       count(DISTINCT e.evidence_id) AS evidence,
       count(DISTINCT c.claim_id) AS claims,
       bool_and(sr.raw_content IS NULL AND ci.quoted_text IS NULL) AS upstream_payload_excluded,
       bool_and(sr.content_hash IS NOT NULL) AS acquired_content_hashed
FROM source s
JOIN dataset d ON d.source_id = s.source_id
JOIN source_record sr ON sr.dataset_id = d.dataset_id
LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim c ON c.claim_id = ce.claim_id
WHERE s.source_key = 'STEP_TAHOT'
GROUP BY s.source_key, d.dataset_key, d.version;
