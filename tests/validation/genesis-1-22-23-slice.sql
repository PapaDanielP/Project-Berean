\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Genesis 1:22-23 retain their already-declared structural boundaries. The existing
    -- predicates cannot express blessing/multiplication or ordinal-day semantics without
    -- adding false precision, so this phase adds no direct semantic claim.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE (sr.source_record_key, sr.source_location) IN (
                  ('MT_GEN_1_22', 'Genesis 1:22'),
                  ('MT_GEN_1_23', 'Genesis 1:23')
              )
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 12 requires exactly the Genesis 1:22-23 structural locators in GEN_MT_REF';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 12 has an unintended Genesis 1:22-23 source-record locator';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL
               OR ci.citation_key <> 'CITE_' || sr.source_record_key
               OR ci.locator <> sr.source_location OR ci.quoted_text IS NOT NULL
               OR e.evidence_key <> 'EV_' || sr.source_record_key || '_EXCLUDED'
               OR e.evidence_type_code <> 'SOURCE_OBSERVATION')
    ) THEN
        RAISE EXCEPTION 'Phase 12 source observations must retain exact locators without text, hashes, or quotations';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
          AND NOT EXISTS (
              SELECT 1
              FROM evidence_citation ec
              JOIN citation ci ON ci.citation_id = ec.citation_id
              WHERE ec.evidence_id = e.evidence_id
                AND ci.source_record_id = sr.source_record_id
                AND ci.locator = sr.source_location
          )
    ) THEN
        RAISE EXCEPTION 'Phase 12 source observations must cite their own structural source record';
    END IF;

    -- No direct assertion can faithfully be made with the available predicates. This also makes
    -- the complete-provenance requirement for direct claims explicit: none may be attached.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN evidence e ON e.source_record_id = sr.source_record_id
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        JOIN claim c ON c.claim_id = ce.claim_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
          AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'Phase 12 must not create direct claims for unrepresentable blessing or ordinal-day semantics';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN evidence e ON e.source_record_id = sr.source_record_id
        LEFT JOIN entity_source_mapping esm ON esm.supporting_evidence_id = e.evidence_id
        LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        LEFT JOIN claim c ON c.claim_id = ce.claim_id
        LEFT JOIN derivation d ON d.derivation_id = c.derivation_id
        LEFT JOIN event_participation ep ON ep.asserting_claim_id = c.claim_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23')
          AND (esm.entity_source_mapping_id IS NOT NULL OR d.derivation_id IS NOT NULL
               OR ep.asserting_claim_id IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Phase 12 must not introduce source identities, mappings, derivations, or authoritative event participation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event
        WHERE event_key ILIKE ANY (ARRAY['%blessing%', '%multipl%', '%ordinal%', '%fifth%', '%day_number%'])
    ) THEN
        RAISE EXCEPTION 'Phase 12 must not introduce blessing, multiplication, or ordinal-day events';
    END IF;

    -- The later Genesis 1 boundary remains exactly as classified in Phase 10.
    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_record_key IN ('MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27')
    ) <> 4
       OR EXISTS (
           SELECT 1
           FROM source_record sr
           WHERE sr.source_record_key IN ('MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27')
             AND NOT EXISTS (
                 SELECT 1
                 FROM evidence e
                 JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
                 JOIN claim c ON c.claim_id = ce.claim_id
                 WHERE e.source_record_id = sr.source_record_id
                   AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
                   AND ce.relation_type_code = 'SUPPORTS'
             )
       )
       OR EXISTS (
           SELECT 1
           FROM source_record sr
           JOIN evidence e ON e.source_record_id = sr.source_record_id
           JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
           WHERE sr.source_record_key IN ('MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31')
       ) THEN
        RAISE EXCEPTION 'Phase 12 must preserve Genesis 1:24-27 populated and Genesis 1:28-31 intentionally excluded';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (2, 3, 4, 6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'Phase 12 must leave Genesis chapters 2-4, 6-7, and 9-11 deferred';
    END IF;
END $$;
