\set ON_ERROR_STOP on

-- Phase 26 validates the bounded biblical entity coverage and provenance-aware ingestion slice.
--
-- It asserts that the ingested material is explicit, fully source-backed, bounded, and free of
-- identity/chronology/geography/theology inference, and that deliberately unmodeled observations
-- remain visible as cited evidence rather than disappearing.
DO $$
DECLARE
    phase26_new_entity_keys text[] := ARRAY[
        'mahalalel', 'jared', 'enoch', 'methuselah',
        'eli', 'hophni', 'phinehas_son_of_eli', 'philistines',
        'ebenezer', 'ashdod', 'house_of_dagon_ashdod', 'kiriath_jearim',
        'abinadab', 'eleazar_son_of_abinadab'
    ];
    phase26_locators text[] := ARRAY[
        'MT_GEN_5_12', 'MT_GEN_5_15', 'MT_GEN_5_18', 'MT_GEN_5_21',
        'MT_GEN_5_22', 'MT_GEN_5_23', 'MT_GEN_5_24',
        'MT_1SA_4_4', 'MT_1SA_4_11', 'MT_1SA_5_1', 'MT_1SA_5_2', 'MT_1SA_7_1', 'MT_1SA_7_2'
    ];
    enoch_claim_keys text[] := ARRAY[
        'CLAIM_MT_JARED_FATHER_ENOCH',
        'CLAIM_MT_ENOCH_FATHER_METHUSELAH',
        'CLAIM_ENOCH_CHILD_ENOCH_BEGETTING',
        'CLAIM_ENOCH_PARENT_METHUSELAH_BEGETTING',
        'CLAIM_MT_ENOCH_AGE_AT_METHUSELAH_65'
    ];
BEGIN
    -- 1) Accepted baseline must still be present and unmodified in kind.
    IF (SELECT count(*) FROM claim WHERE claim_key = 'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6') <> 1 THEN
        RAISE EXCEPTION 'phase26: missing accepted Phase 19 baseline claim';
    END IF;
    IF (SELECT count(*) FROM claim WHERE claim_key = 'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS') <> 1 THEN
        RAISE EXCEPTION 'phase26: missing accepted Phase 24 baseline claim';
    END IF;
    IF (SELECT count(*) FROM claim WHERE claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED' AND claim_type_code = 'DERIVED_CLAIM') <> 1 THEN
        RAISE EXCEPTION 'phase26: missing accepted derived-claim baseline used by Phase 23';
    END IF;

    -- 2) No registry or vocabulary expansion. Phase 26 uses only already registered structures.
    IF (SELECT count(*) FROM predicate) <> 22 THEN
        RAISE EXCEPTION 'phase26: predicate registry must remain unchanged (expected 22 predicates)';
    END IF;
    IF (SELECT count(*) FROM event_type) <> 8 THEN
        RAISE EXCEPTION 'phase26: event_type vocabulary must remain unchanged';
    END IF;
    IF (SELECT count(*) FROM entity_type) <> 5 THEN
        RAISE EXCEPTION 'phase26: entity_type vocabulary must remain unchanged';
    END IF;
    IF (SELECT count(*) FROM event_participation_role) <> 5 THEN
        RAISE EXCEPTION 'phase26: participation role vocabulary must remain unchanged';
    END IF;

    -- 3) Every Phase 26 entity exists exactly once and is reconciled with evidence-backed mappings.
    IF (SELECT count(*) FROM entity WHERE entity_key = ANY(phase26_new_entity_keys)) <> array_length(phase26_new_entity_keys, 1) THEN
        RAISE EXCEPTION 'phase26: expected every selected-corpus entity to exist exactly once';
    END IF;
    IF EXISTS (
        SELECT 1 FROM unnest(phase26_new_entity_keys) AS k(entity_key)
        WHERE NOT EXISTS (
            SELECT 1 FROM entity_source_mapping esm
            JOIN entity en ON en.entity_id = esm.entity_id
            WHERE en.entity_key = k.entity_key
              AND esm.mapping_status_code = 'ACTIVE'
              AND esm.supporting_evidence_id IS NOT NULL
              AND btrim(COALESCE(esm.justification, '')) <> ''
        )
    ) THEN
        RAISE EXCEPTION 'phase26: every ingested entity needs an evidence-backed justified reconciliation';
    END IF;

    -- 4) Every Phase 26 locator is a structural reference only; no source text/hash/quotation.
    IF (SELECT count(*) FROM source_record WHERE source_record_key = ANY(phase26_locators)) <> array_length(phase26_locators, 1) THEN
        RAISE EXCEPTION 'phase26: expected every selected locator to be present exactly once';
    END IF;
    IF EXISTS (
        SELECT 1 FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = ANY(phase26_locators)
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase26: no source text, hash, or quotation may be stored for this slice';
    END IF;
    IF EXISTS (
        SELECT 1 FROM source_record sr
        WHERE sr.source_record_key = ANY(phase26_locators)
          AND NOT EXISTS (SELECT 1 FROM citation ci WHERE ci.source_record_id = sr.source_record_id)
    ) THEN
        RAISE EXCEPTION 'phase26: every selected locator needs a citation';
    END IF;
    IF EXISTS (
        SELECT 1 FROM source_record sr
        WHERE sr.source_record_key = ANY(phase26_locators)
          AND NOT EXISTS (SELECT 1 FROM evidence e WHERE e.source_record_id = sr.source_record_id)
    ) THEN
        RAISE EXCEPTION 'phase26: every selected locator needs a cited source observation';
    END IF;

    -- 5) Enoch end-to-end: every Enoch claim resolves through the full Phase 21 provenance chain.
    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(enoch_claim_keys)) <> array_length(enoch_claim_keys, 1) THEN
        RAISE EXCEPTION 'phase26: expected the complete Enoch claim set';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(enoch_claim_keys)
          AND c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase26: Enoch claims must remain direct source claims';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(enoch_claim_keys)
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'phase26: every Enoch claim must resolve to Source through the existing chain';
    END IF;
    IF (SELECT count(*) FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'enoch') < 2 THEN
        RAISE EXCEPTION 'phase26: Enoch must be visible through projected event participation';
    END IF;

    -- 6) Enoch exclusions: no death/translation event, no chronology, no external material.
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE en.entity_key = 'enoch' AND ev.event_type_code = 'DEATH'
    ) THEN
        RAISE EXCEPTION 'phase26: Genesis 5:24 must not be represented as a death event';
    END IF;
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        WHERE en.entity_key = 'enoch' AND p.predicate = 'ageAtDeathYears'
    ) THEN
        RAISE EXCEPTION 'phase26: Genesis 5:23 must not be modeled as an age at death';
    END IF;
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN event ev ON ev.event_id = p.subject_event_id
        WHERE ev.event_key IN ('enoch_begetting', 'methuselah_begetting')
          AND p.predicate = 'yearsFromCreation'
    ) THEN
        RAISE EXCEPTION 'phase26: no chronology may be derived for the Enoch slice';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity en ON en.entity_id = p.subject_entity_id OR en.entity_id = p.object_entity_id
        WHERE en.entity_key = 'enoch' AND c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase26: no interpretive or derived Enoch claim may be created in this phase';
    END IF;

    -- 7) Deliberately unmodeled observations remain visible as cited evidence, never deleted.
    IF EXISTS (
        SELECT 1 FROM unnest(ARRAY['EV_MT_GEN_5_22', 'EV_MT_GEN_5_23', 'EV_MT_GEN_5_24', 'EV_MT_1SA_7_2']) AS k(evidence_key)
        WHERE NOT EXISTS (
            SELECT 1 FROM evidence e
            JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
            WHERE e.evidence_key = k.evidence_key
        )
    ) THEN
        RAISE EXCEPTION 'phase26: unmodeled observations must remain as cited evidence';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key IN ('EV_MT_GEN_5_22', 'EV_MT_GEN_5_23', 'EV_MT_GEN_5_24', 'EV_MT_1SA_7_2')
    ) THEN
        RAISE EXCEPTION 'phase26: deliberately unmodeled observations must not back a claim';
    END IF;

    -- 8) Identity reconciliation boundaries are preserved: similar naming is not identity.
    IF EXISTS (SELECT 1 FROM entity WHERE entity_key = 'enoch_son_of_cain') THEN
        RAISE EXCEPTION 'phase26: the Genesis 4:17 Enoch is outside this slice and must not be created';
    END IF;
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key = 'enoch' AND esm.mapping_status_code = 'ACTIVE'
        GROUP BY en.entity_id
        HAVING count(DISTINCT si.source_id) > 1
    ) THEN
        RAISE EXCEPTION 'phase26: the Enoch entity must not be reconciled across multiple sources in this phase';
    END IF;

    -- 9) 1 Samuel 4-7 material is source-backed and bounded.
    IF (SELECT count(*) FROM source WHERE source_key = '1SA_MT') <> 1 THEN
        RAISE EXCEPTION 'phase26: expected exactly one new 1 Samuel source';
    END IF;
    IF (SELECT count(*) FROM dataset WHERE dataset_key = '1SA_MT_REF') <> 1 THEN
        RAISE EXCEPTION 'phase26: expected exactly one new 1 Samuel dataset';
    END IF;
    IF (SELECT count(*) FROM event WHERE event_key IN (
            'ark_presence_1sam4', 'ark_capture_1sam4', 'hophni_death_1sam4',
            'phinehas_son_of_eli_death_1sam4', 'ark_transport_ashdod_1sam5',
            'ark_placement_house_dagon_1sam5', 'ark_relocation_kiriath_jearim_1sam7')) <> 7 THEN
        RAISE EXCEPTION 'phase26: expected exactly the seven bounded 1 Samuel events';
    END IF;
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key = 'ark_capture_1sam4' AND en.entity_key = 'philistines'
    ) THEN
        RAISE EXCEPTION 'phase26: 1 Samuel 4:11 does not name the captors; no captor may be asserted';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id
        JOIN claim rc ON rc.claim_id = cr.related_claim_id
        WHERE c.claim_key LIKE '%1SAM%' OR rc.claim_key LIKE '%1SAM%'
    ) THEN
        RAISE EXCEPTION 'phase26: no automatic claim relation may be created for the 1 Samuel slice';
    END IF;

    -- 10) The Ark remains one canonical entity across every source-backed description.
    IF (SELECT count(*) FROM entity WHERE entity_key = 'ark_of_covenant') <> 1 THEN
        RAISE EXCEPTION 'phase26: the Ark of the Covenant must remain a single canonical entity';
    END IF;
    IF (SELECT count(DISTINCT s.source_key)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE en.entity_key = 'ark_of_covenant') < 5 THEN
        RAISE EXCEPTION 'phase26: the Ark should now be described by at least five distinct sources';
    END IF;
END $$;

\echo 'ok: Phase 26 biblical entity coverage slice passes bounded ingestion validation'
