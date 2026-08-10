\set ON_ERROR_STOP on

-- Phase 24 validates the real-knowledge demonstration slice while preserving the accepted
-- Phase 19-23 architectural boundary: no schema/registry drift, no fabricated text, no automatic
-- source resolution, and no mutation by read-only demonstrations.
DO $$
DECLARE
    phase24_claim_keys text[] := ARRAY[
        'CLAIM_1KI_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY',
        'CLAIM_1KI_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY',
        'CLAIM_2CH_SOLOMON_SUBJECT_TEMPLE_ASSEMBLY',
        'CLAIM_2CH_ELDERS_PARTICIPANT_TEMPLE_ASSEMBLY',
        'CLAIM_1KI_ARK_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_1KI_TENT_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_1KI_VESSELS_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_1KI_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_2CH_ARK_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_2CH_TENT_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_2CH_VESSELS_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_2CH_PRIESTS_LEVITES_PARTICIPANT_TEMPLE_TRANSFER',
        'CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT',
        'CLAIM_1KI_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT',
        'CLAIM_2CH_ARK_SUBJECT_TEMPLE_PLACEMENT',
        'CLAIM_2CH_PRIESTS_PARTICIPANT_TEMPLE_PLACEMENT',
        'CLAIM_1KI_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY',
        'CLAIM_2CH_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY',
        'CLAIM_1KI_ARK_LOCATED_INNER_SANCTUARY',
        'CLAIM_2CH_ARK_LOCATED_INNER_SANCTUARY',
        'CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
        'CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION'
    ];
BEGIN
    IF (SELECT count(*) FROM source WHERE source_key IN ('1KI_MT', '2CH_MT')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected 1 Kings and 2 Chronicles sources';
    END IF;

    IF (SELECT count(*) FROM dataset WHERE dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected two Phase 24 datasets';
    END IF;

    IF (SELECT count(*) FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')) <> 10 THEN
        RAISE EXCEPTION 'phase24: expected ten bounded source records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase24: forbids fabricated text, hash, or quotation';
    END IF;

    IF (SELECT count(*) FROM event_type) <> (SELECT count(*) FROM event_type WHERE event_type_code IN (
        'BIRTH', 'DEATH', 'GENEALOGICAL', 'CHRONOLOGICAL', 'OTHER',
        'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT'
    )) THEN
        RAISE EXCEPTION 'phase24: forbids event_type registry drift';
    END IF;

    IF (SELECT count(*) FROM predicate) <> (SELECT count(*) FROM predicate WHERE predicate_code IN (
        'fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt', 'precedes',
        'participatesIn', 'subjectOf', 'parentIn', 'childIn', 'builderIn',
        'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation',
        'lengthCubits', 'widthCubits', 'heightCubits', 'madeOfMaterial',
        'overlaidWithMaterial', 'hasComponent', 'containsContent', 'standingRequirementIn'
    )) THEN
        RAISE EXCEPTION 'phase24: forbids predicate registry drift';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('evaluation', 'knowledge_fact', 'factual_core', 'semantic_classifier',
                             'artifact_lifecycle', 'event_participant', 'inference', 'ontology')
    ) THEN
        RAISE EXCEPTION 'phase24: forbids new evaluation/semantic/ontology infrastructure tables';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key = 'ark_of_covenant') <> 1
       OR (SELECT count(*) FROM entity WHERE canonical_name = 'Ark of the Covenant') <> 1 THEN
        RAISE EXCEPTION 'phase24: expected the existing single canonical Ark of the Covenant entity';
    END IF;

    IF (SELECT count(*) FROM entity WHERE entity_key IN (
        'solomon', 'elders_of_israel_solomon_assembly', 'priests_levites_temple_ark_bearers',
        'solomon_temple_inner_sanctuary', 'tent_of_meeting', 'sanctuary_vessels_temporal_slice'
    )) <> 6 THEN
        RAISE EXCEPTION 'phase24: expected six new scoped referent entities';
    END IF;

    IF (SELECT count(*) FROM event WHERE event_key IN (
        'ark_covenant_temple_assembly', 'ark_covenant_temple_transfer', 'ark_covenant_temple_placement'
    ) AND event_type_code = 'OTHER') <> 3 THEN
        RAISE EXCEPTION 'phase24: expected three generic OTHER events';
    END IF;

    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(phase24_claim_keys) AND claim_type_code = 'DIRECT_SOURCE_CLAIM') <> 22 THEN
        RAISE EXCEPTION 'phase24: expected twenty-two direct source claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
          AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS')
    ) THEN
        RAISE EXCEPTION 'phase24: every Phase 24 direct claim needs supporting evidence';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM evidence ev
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('1KI_MT_REF', '2CH_MT_REF')
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = ev.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase24: every Phase 24 source observation needs a citation';
    END IF;

    IF (
        SELECT count(*)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity ark ON ark.entity_id = p.subject_entity_id
        JOIN entity tablets ON tablets.entity_id = p.object_entity_id
        WHERE ark.entity_key = 'ark_of_covenant'
          AND tablets.entity_key = 'tablets_of_testimony'
          AND p.predicate = 'containsContent'
          AND c.claim_key IN ('CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY',
                              'CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
                              'CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION',
                              'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED')
    ) <> 4 THEN
        RAISE EXCEPTION 'phase24: expected multiple claims, including derived comparison, on the same Ark/tablets proposition';
    END IF;

    IF (
        SELECT count(*)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE ev.event_key = 'ark_covenant_temple_placement'
          AND en.entity_key IN ('ark_of_covenant', 'priests_levites_temple_ark_bearers')
    ) <> 4 THEN
        RAISE EXCEPTION 'phase24: expected projected participation from 1 Kings and 2 Chronicles placement claims';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) THEN
        RAISE EXCEPTION 'phase24: standing requirement must not project event participation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim a ON a.claim_id = cr.claim_id
        JOIN claim b ON b.claim_id = cr.related_claim_id
        WHERE cr.relation_type_code = 'CONTRADICTS'
          AND ((a.claim_key LIKE 'CLAIM_1KI_%' AND b.claim_key LIKE 'CLAIM_2CH_%')
            OR (a.claim_key LIKE 'CLAIM_2CH_%' AND b.claim_key LIKE 'CLAIM_1KI_%'))
    ) THEN
        RAISE EXCEPTION 'phase24: 1 Kings / 2 Chronicles differences must not be auto-labeled contradiction';
    END IF;

    IF (SELECT count(*)
        FROM claim c
        JOIN derivation d ON d.derivation_id = c.derivation_id
        WHERE c.claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED'
          AND c.claim_type_code = 'DERIVED_CLAIM'
          AND d.method = 'Cross-source comparison of normalized Ark contents propositions in the temple-placement slice') <> 1 THEN
        RAISE EXCEPTION 'phase24: expected one genuine cross-source derived claim';
    END IF;

    IF (SELECT count(*)
        FROM claim c
        JOIN derivation_input di ON di.derivation_id = c.derivation_id
        WHERE c.claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED') <> 2 THEN
        RAISE EXCEPTION 'phase24: derived claim must have exactly two explicit inputs';
    END IF;
END $$;
