\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Twelve new Masoretic structural source records for Genesis 1:20-31.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN (
              'MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
              'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
              'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31'
          )
    ) <> 12 THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must have twelve Masoretic source records';
    END IF;

    -- Each new source record uses the existing GEN_MT_REF dataset under the existing GEN_MT source.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key IN (
              'MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
              'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
              'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31'
          )
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
    ) <> 12 THEN
        RAISE EXCEPTION 'Genesis 1:20-31 source records must reference the existing GEN_MT source and GEN_MT_REF dataset';
    END IF;

    -- Structural provenance is complete, no text/hash is introduced, and citations point at the
    -- correct source records.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN (
              'MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
              'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
              'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31'
          )
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL
               OR ci.citation_id IS NULL OR ci.locator <> sr.source_location OR e.evidence_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch has incomplete structural provenance, undistributed text, or a mismatched citation locator';
    END IF;

    -- Every new evidence item traces to a citation and, through it, to the correct source record.
    IF EXISTS (
        SELECT 1
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN (
              'MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
              'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
              'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31'
          )
          AND NOT EXISTS (
              SELECT 1
              FROM evidence_citation ec
              JOIN citation ci ON ci.citation_id = ec.citation_id
              WHERE ec.evidence_id = e.evidence_id
                AND ci.source_record_id = sr.source_record_id
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 evidence lacks a citation to its own source record';
    END IF;

    -- Every new direct claim has ClaimEvidence support and an underlying proposition.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN (
              'MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
              'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
              'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31'
          )
          AND NOT EXISTS (
              SELECT 1
              FROM evidence e
              JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
              JOIN claim c ON c.claim_id = ce.claim_id
              JOIN proposition p ON p.proposition_id = c.proposition_id
              WHERE e.source_record_id = sr.source_record_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 source record lacks a direct supported claim with a proposition';
    END IF;

    -- Only existing controlled predicates are used for the new Genesis 1:20-31 propositions.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key IN (
              'gen1_20_waters_birds_statement', 'gen1_21_creatures_birds_statement',
              'gen1_22_waters_birds_statement', 'gen1_23_day_boundary_statement',
              'gen1_24_land_creatures_statement', 'gen1_25_land_creatures_statement',
              'gen1_26_humankind_statement', 'gen1_27_humankind_statement',
              'gen1_28_humankind_statement', 'gen1_29_food_provision_statement',
              'gen1_30_creature_food_statement', 'gen1_31_completion_statement'
          )
          AND p.predicate NOT IN ('subjectOf', 'participatesIn')
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch introduces an unsupported predicate';
    END IF;

    -- No claim_relation rows (uncontrolled claim relations) are introduced for the new claims.
    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id OR c.claim_id = cr.related_claim_id
        WHERE c.claim_key LIKE 'CLAIM_MT_GEN_1_2%'
           OR c.claim_key LIKE 'CLAIM_MT_GEN_1_30%'
           OR c.claim_key LIKE 'CLAIM_MT_GEN_1_31%'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch introduces an uncontrolled claim relation';
    END IF;

    -- No derivations are introduced for this batch.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE (c.claim_key LIKE 'CLAIM_MT_GEN_1_2%' OR c.claim_key LIKE 'CLAIM_MT_GEN_1_30%' OR c.claim_key LIKE 'CLAIM_MT_GEN_1_31%')
          AND c.derivation_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not introduce derivations/chronology';
    END IF;

    -- Event participation remains projection-based.
    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'gen1_30_creature_food_statement'
          AND en.entity_key = 'gen1_green_plants'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch: event participation projection is missing the green-plants participant';
    END IF;

    -- Genesis 1:1-19 remains intact after this extension.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN (
              'MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5',
              'MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9', 'MT_GEN_1_10',
              'MT_GEN_1_11', 'MT_GEN_1_12', 'MT_GEN_1_13', 'MT_GEN_1_14', 'MT_GEN_1_15',
              'MT_GEN_1_16', 'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19'
          )
    ) <> 19 THEN
        RAISE EXCEPTION 'Genesis 1:1-19 content was altered by the Phase 10 extension';
    END IF;

    -- This phase remains bounded to Genesis 1 and must not populate Genesis 2-4, 6-7, or 9-11.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key LIKE 'MT_GEN_2\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_3\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_4\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_6\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_7\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_9\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_10\_%' ESCAPE '\'
           OR sr.source_record_key LIKE 'MT_GEN_11\_%' ESCAPE '\'
    ) THEN
        RAISE EXCEPTION 'Phase 10 must not populate Genesis 2-4, 6-7, or 9-11 source records';
    END IF;

    -- Genesis 1 is structurally bounded to 1:1-31.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key LIKE 'MT_GEN_1\_%' ESCAPE '\'
          AND substring(sr.source_location FROM ':([0-9]+)$')::int > 31
    ) THEN
        RAISE EXCEPTION 'Genesis 1 structural records must remain bounded to verses 1-31';
    END IF;
END $$;
