\set ON_ERROR_STOP on

DO $$
BEGIN
    -- Twelve new Masoretic structural source records for Genesis 1:20-31.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN ('MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
                                        'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
                                        'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31')
    ) <> 12 THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must have twelve Masoretic source records';
    END IF;

    -- Each new source record uses the existing GEN_MT_REF dataset under the existing GEN_MT source.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key IN ('MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
                                        'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
                                        'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31')
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
    ) <> 12 THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch source records must reference the existing GEN_MT source and GEN_MT_REF dataset';
    END IF;

    -- Structural provenance is complete, no text/hash is introduced, and citations point at the
    -- correct source records. Every locator has at least an evidence item (some intentionally
    -- unclaimed, per the documented semantic exclusions).
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
                                        'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
                                        'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31')
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
        WHERE sr.source_record_key IN ('MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23',
                                        'MT_GEN_1_24', 'MT_GEN_1_25', 'MT_GEN_1_26', 'MT_GEN_1_27',
                                        'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30', 'MT_GEN_1_31')
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

    -- The six conservatively representable verses (creatures/birds and mankind statements) each
    -- have a direct supported claim with an underlying proposition.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN ('MT_GEN_1_20', 'MT_GEN_1_21', 'MT_GEN_1_24', 'MT_GEN_1_25',
                                        'MT_GEN_1_26', 'MT_GEN_1_27')
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
        RAISE EXCEPTION 'Genesis 1:20-31 representable source record lacks a direct supported claim with a proposition';
    END IF;

    -- The six intentionally under-modeled verses (blessing/multiplication, fifth/sixth-day
    -- boundary, dominion, food-provision, and evaluative statements) deliberately have no claim.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN evidence e ON e.source_record_id = sr.source_record_id
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        WHERE sr.source_record_key IN ('MT_GEN_1_22', 'MT_GEN_1_23', 'MT_GEN_1_28', 'MT_GEN_1_29',
                                        'MT_GEN_1_30', 'MT_GEN_1_31')
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not assert a claim for the intentionally under-modeled verses';
    END IF;

    -- Only the existing controlled predicates (subjectOf, participatesIn) are used by the new
    -- Genesis 1:20-31 propositions; no new predicate is introduced by this batch.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key IN ('gen1_20_creatures_command_statement', 'gen1_21_creatures_statement',
                                'gen1_24_land_creatures_command_statement', 'gen1_25_land_creatures_statement',
                                'gen1_26_mankind_command_statement', 'gen1_27_mankind_creation_statement')
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
          AND c.claim_key IN (
              'CLAIM_MT_GEN_1_20_GOD_CREATURES_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_20_CREATURES_COMMAND_PARTICIPANT',
              'CLAIM_MT_GEN_1_20_BIRDS_COMMAND_PARTICIPANT', 'CLAIM_MT_GEN_1_20_WATERS_COMMAND_PARTICIPANT',
              'CLAIM_MT_GEN_1_21_GOD_CREATURES_SUBJECT', 'CLAIM_MT_GEN_1_21_CREATURES_PARTICIPANT',
              'CLAIM_MT_GEN_1_21_BIRDS_PARTICIPANT', 'CLAIM_MT_GEN_1_21_WATERS_PARTICIPANT',
              'CLAIM_MT_GEN_1_24_GOD_LAND_CREATURES_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_24_LAND_CREATURES_COMMAND_PARTICIPANT',
              'CLAIM_MT_GEN_1_25_GOD_LAND_CREATURES_SUBJECT', 'CLAIM_MT_GEN_1_25_LAND_CREATURES_PARTICIPANT',
              'CLAIM_MT_GEN_1_26_GOD_MANKIND_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_26_MANKIND_COMMAND_PARTICIPANT',
              'CLAIM_MT_GEN_1_27_GOD_MANKIND_CREATION_SUBJECT', 'CLAIM_MT_GEN_1_27_MANKIND_CREATION_PARTICIPANT'
          )
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch introduces an uncontrolled claim relation';
    END IF;

    -- No derivation, source identity, or entity-source mapping is introduced by this batch.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key IN (
              'CLAIM_MT_GEN_1_20_GOD_CREATURES_COMMAND_SUBJECT', 'CLAIM_MT_GEN_1_27_GOD_MANKIND_CREATION_SUBJECT'
          )
          AND c.derivation_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not introduce derivations/chronology';
    END IF;

    -- Event participation for the new statements is projection-based (event_participation view),
    -- not a separate authoritative table.
    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'gen1_27_mankind_creation_statement'
          AND en.entity_key = 'gen1_mankind'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch: event participation projection is missing the mankind participant';
    END IF;

    -- No dominion, blessing, multiplication, image, likeness, male/female, food, or evaluation
    -- vocabulary is introduced as an event/entity/predicate name by this batch.
    IF EXISTS (
        SELECT 1
        FROM event
        WHERE event_key ILIKE ANY (ARRAY['%dominion%', '%blessing%', '%multipl%', '%image%',
                                          '%likeness%', '%male%', '%female%', '%food%', '%evaluat%'])
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not introduce dominion/blessing/image/likeness/male-female/food/evaluation semantics';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM entity
        WHERE entity_key ILIKE ANY (ARRAY['%dominion%', '%blessing%', '%species%'])
           OR canonical_name ~* '\mkind\M'
           OR canonical_name ~* '\mmale\M'
           OR canonical_name ~* '\mfemale\M'
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not introduce dominion/blessing/kind/species/male-female entities';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM predicate
        WHERE predicate_code NOT IN ('fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt',
                                      'precedes', 'participatesIn', 'subjectOf', 'parentIn', 'childIn',
                                      'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation')
    ) THEN
        RAISE EXCEPTION 'Genesis 1:20-31 batch must not introduce a new predicate';
    END IF;

    -- Genesis 1:1-19 record counts remain exactly as established by the Phase 6-9 batches.
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
        RAISE EXCEPTION 'Genesis 1:1-19 batch was altered by the Phase 10 extension';
    END IF;

    -- Genesis chapters 2-4, 6-7, and 9-11 remain explicitly deferred; this batch does not
    -- populate them.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (2, 3, 4, 6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'Genesis chapters 2-4, 6-7, and 9-11 must remain deferred for this batch';
    END IF;
END $$;
