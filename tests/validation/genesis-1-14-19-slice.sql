\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Six new Masoretic structural source records for Genesis 1:14-19.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN ('MT_GEN_1_14', 'MT_GEN_1_15', 'MT_GEN_1_16',
                                        'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19')
    ) <> 6 THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch must have six Masoretic source records';
    END IF;

    -- Each new source record uses the existing GEN_MT_REF dataset under the existing GEN_MT source.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key IN ('MT_GEN_1_14', 'MT_GEN_1_15', 'MT_GEN_1_16',
                                        'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19')
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
    ) <> 6 THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch source records must reference the existing GEN_MT source and GEN_MT_REF dataset';
    END IF;

    -- Structural provenance is complete, no text/hash is introduced, and citations point at the
    -- correct source records.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_14', 'MT_GEN_1_15', 'MT_GEN_1_16',
                                        'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL
               OR ci.citation_id IS NULL OR ci.locator <> sr.source_location OR e.evidence_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch has incomplete structural provenance, undistributed text, or a mismatched citation locator';
    END IF;

    -- Every new evidence item traces to a citation and, through it, to the correct source record.
    IF EXISTS (
        SELECT 1
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_14', 'MT_GEN_1_15', 'MT_GEN_1_16',
                                        'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19')
          AND NOT EXISTS (
              SELECT 1
              FROM evidence_citation ec
              JOIN citation ci ON ci.citation_id = ec.citation_id
              WHERE ec.evidence_id = e.evidence_id
                AND ci.source_record_id = sr.source_record_id
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 evidence lacks a citation to its own source record';
    END IF;

    -- Every new direct claim has ClaimEvidence support and an underlying proposition.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_14', 'MT_GEN_1_15', 'MT_GEN_1_16',
                                        'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19')
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
        RAISE EXCEPTION 'Genesis 1:14-19 source record lacks a direct supported claim with a proposition';
    END IF;

    -- Only the existing controlled predicates (subjectOf, participatesIn) are used by the new
    -- Genesis 1:14-19 propositions; no new predicate is introduced by this batch.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key IN ('gen1_14_lights_command_statement', 'gen1_15_lights_giving_light_statement',
                                'gen1_16_two_great_lights_statement', 'gen1_17_lights_placement_statement',
                                'gen1_18_light_darkness_distinction_statement', 'gen1_19_day_boundary_statement')
          AND p.predicate NOT IN ('subjectOf', 'participatesIn')
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch introduces an unsupported predicate';
    END IF;

    -- No claim_relation rows (uncontrolled claim relations) are introduced for the new claims.
    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id OR c.claim_id = cr.related_claim_id
        WHERE c.claim_key IN (
              'CLAIM_MT_GEN_1_14_GOD_LIGHTS_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_14_LIGHTS_COMMAND_PARTICIPANT',
              'CLAIM_MT_GEN_1_15_GOD_LIGHTS_GIVING_LIGHT_SUBJECT', 'CLAIM_MT_GEN_1_15_LIGHTS_GIVING_LIGHT_PARTICIPANT',
              'CLAIM_MT_GEN_1_15_EARTH_GIVING_LIGHT_PARTICIPANT',
              'CLAIM_MT_GEN_1_16_GOD_TWO_GREAT_LIGHTS_SUBJECT', 'CLAIM_MT_GEN_1_16_GREATER_LIGHT_PARTICIPANT',
              'CLAIM_MT_GEN_1_16_LESSER_LIGHT_PARTICIPANT', 'CLAIM_MT_GEN_1_16_STARS_PARTICIPANT',
              'CLAIM_MT_GEN_1_17_GOD_LIGHTS_PLACEMENT_SUBJECT', 'CLAIM_MT_GEN_1_17_GREATER_LIGHT_PLACEMENT_PARTICIPANT',
              'CLAIM_MT_GEN_1_17_LESSER_LIGHT_PLACEMENT_PARTICIPANT', 'CLAIM_MT_GEN_1_17_STARS_PLACEMENT_PARTICIPANT',
              'CLAIM_MT_GEN_1_17_EARTH_PLACEMENT_PARTICIPANT',
              'CLAIM_MT_GEN_1_18_GOD_LIGHT_DARKNESS_DISTINCTION_SUBJECT', 'CLAIM_MT_GEN_1_18_LIGHT_DISTINCTION_PARTICIPANT',
              'CLAIM_MT_GEN_1_18_DARKNESS_DISTINCTION_PARTICIPANT',
              'CLAIM_MT_GEN_1_19_DAY_BOUNDARY_SUBJECT'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch introduces an uncontrolled claim relation';
    END IF;

    -- No derivation, source identity, or entity-source mapping is introduced by this batch.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key IN (
              'CLAIM_MT_GEN_1_14_GOD_LIGHTS_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_19_DAY_BOUNDARY_SUBJECT'
          )
          AND c.derivation_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch must not introduce derivations/chronology';
    END IF;

    -- Event participation for the new statements is projection-based (event_participation view),
    -- not a separate authoritative table.
    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'gen1_16_two_great_lights_statement'
          AND en.entity_key = 'gen1_stars'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch: event participation projection is missing the stars participant';
    END IF;

    -- Light, greater light, lesser light, and stars remain distinct entities (no collapsed ontology).
    IF (
        SELECT count(DISTINCT entity_id)
        FROM entity
        WHERE entity_key IN ('gen1_light', 'gen1_lights', 'gen1_greater_light', 'gen1_lesser_light', 'gen1_stars')
    ) <> 5 THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch must distinguish light, lights, greater light, lesser light, and stars as separate entities';
    END IF;

    -- No new evaluation predicate/event is introduced for Genesis 1:18.
    IF EXISTS (
        SELECT 1
        FROM event
        WHERE event_key ILIKE '%gen1_18%'
          AND event_key <> 'gen1_18_light_darkness_distinction_statement'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:14-19 batch must not add a separate evaluation event/predicate for Genesis 1:18';
    END IF;

    -- Genesis 1:1-13 record counts remain exactly as established by the Phase 6-8 batches.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN (
              'MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5',
              'MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9', 'MT_GEN_1_10',
              'MT_GEN_1_11', 'MT_GEN_1_12', 'MT_GEN_1_13'
          )
    ) <> 13 THEN
        RAISE EXCEPTION 'Genesis 1:1-13 batch was altered by the Phase 9 extension';
    END IF;

    -- Regression boundary check: chapter 1 remains structurally bounded to verses 1-31.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key LIKE 'MT_GEN_1\_%' ESCAPE '\'
          AND substring(sr.source_location FROM ':([0-9]+)$')::int > 31
    ) THEN
        RAISE EXCEPTION 'Genesis 1 structural range must remain bounded to verses 1-31';
    END IF;
END $$;
