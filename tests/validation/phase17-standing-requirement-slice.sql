\set ON_ERROR_STOP on

-- Phase 17 validates that the existing generic Entity/SourceIdentity/EntitySourceMapping/
-- Proposition/Claim/Evidence/Event architecture, extended with the smallest possible
-- generic addition (one event_type, one predicate; no participation role, no table), can
-- faithfully represent the source-backed Exodus 25:15 standing requirement that the poles
-- remain in the rings of the Ark of the Covenant and are not withdrawn, while preserving the
-- distinction between an instruction, a standing requirement, a historical/completed event,
-- an observed state, a derived state, and an inferred compliance claim -- none of which,
-- other than the standing requirement itself, is asserted in this phase.
DO $$
BEGIN
    -- 1. Locator integrity: exactly one new source record, in the existing EXO_MT_REF
    --    dataset, with exactly one matching, unquoted citation and no fabricated text/hash.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'EXO_MT_REF' AND sr.source_record_key = 'MT_EXO_25_15'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: expected exactly one Exodus 25:15 locator in EXO_MT_REF';
    END IF;

    IF EXISTS (
        SELECT 1 FROM source_record
        WHERE source_record_key = 'MT_EXO_25_15'
          AND (raw_content IS NOT NULL OR content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase17: forbids fabricated source text or hash for Exodus 25:15';
    END IF;

    IF (
        SELECT count(ci.citation_id)
        FROM source_record sr
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = 'MT_EXO_25_15'
          AND ci.locator = sr.source_location AND ci.quoted_text IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: Exodus 25:15 requires exactly one matching, unquoted citation';
    END IF;

    -- 2. Generic extension: exactly the two smallest new registry rows exist, and no other
    --    schema/table change was made to represent the standing requirement.
    IF (
        SELECT count(*) FROM event_type WHERE event_type_code = 'STANDING_REQUIREMENT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: expected the registered STANDING_REQUIREMENT event_type';
    END IF;

    IF (
        SELECT count(*) FROM predicate
        WHERE predicate_code = 'standingRequirementIn'
          AND subject_kind_code = 'ENTITY' AND object_kind_code = 'EVENT'
          AND event_participation_role_code IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: expected standingRequirementIn (ENTITY->EVENT, no participation role)';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('artifact_requirement', 'standing_requirement', 'requirement',
                             'pole_requirement', 'artifact_participation', 'artifact', 'object',
                             'thing', 'event_participant', 'artifact_attribute',
                             'artifact_component', 'artifact_content', 'object_relationship')
    ) THEN
        RAISE EXCEPTION 'phase17: forbids any artifact/requirement-specific table';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name IN ('entity', 'proposition', 'claim', 'event')
          AND data_type IN ('json', 'jsonb')
    ) THEN
        RAISE EXCEPTION 'phase17: forbids JSON semantic payloads';
    END IF;

    -- 3. Reused entities: poles_ark_covenant, rings_ark_covenant, and ark_of_covenant are the
    --    same, single, pre-existing OBJECT entities established in Phase 16; no duplicate and
    --    no new entity was introduced for the standing requirement.
    IF (
        SELECT count(*) FROM entity
        WHERE entity_key IN ('poles_ark_covenant', 'rings_ark_covenant', 'ark_of_covenant')
          AND entity_type_code = 'OBJECT'
    ) <> 3 THEN
        RAISE EXCEPTION 'phase17: expected the three pre-existing OBJECT entities to remain, unduplicated';
    END IF;

    -- 4. The event is typed STANDING_REQUIREMENT, distinct from every INSTRUCTION and
    --    CONSTRUCTION event, and it is the sole object of the new proposition.
    IF (
        SELECT count(*) FROM event
        WHERE event_key = 'ark_covenant_pole_standing_requirement'
          AND event_type_code = 'STANDING_REQUIREMENT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: expected ark_covenant_pole_standing_requirement typed STANDING_REQUIREMENT';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'standingRequirementIn'
          AND en.entity_key = 'poles_ark_covenant'
          AND ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: expected exactly one poles_ark_covenant standingRequirementIn proposition';
    END IF;

    -- 5. No completed/historical event, participation, construction, or compliance claim was
    --    fabricated from the standing requirement. The STANDING_REQUIREMENT event carries no
    --    participatesIn, subjectOf, builderIn, parentIn, or childIn proposition of any kind,
    --    and no proposition anywhere asserts standingRequirementIn against an
    --    INSTRUCTION/CONSTRUCTION/OTHER event.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key = 'ark_covenant_pole_standing_requirement'
          AND p.predicate <> 'standingRequirementIn'
    ) THEN
        RAISE EXCEPTION 'phase17: the standing-requirement event must carry no participation/construction/other predicate';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'standingRequirementIn' AND ev.event_type_code <> 'STANDING_REQUIREMENT'
    ) THEN
        RAISE EXCEPTION 'phase17: standingRequirementIn must only target a STANDING_REQUIREMENT event';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) THEN
        RAISE EXCEPTION 'phase17: the standing-requirement event must never appear in the event_participation projection';
    END IF;

    -- 6. No claim anywhere asserts an observed state, a derived state, or an inferred
    --    compliance/transport/non-removal fact about the poles/rings/ark beyond the
    --    requirement's existence: no DERIVED_CLAIM touches these entities/event, and no claim
    --    key or statement suggests compliance, transport, removal, or presence.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DERIVED_CLAIM'
          AND (
              coalesce(se.entity_key, oe.entity_key) IN ('poles_ark_covenant', 'rings_ark_covenant')
              OR coalesce(sv.event_key, ov.event_key) = 'ark_covenant_pole_standing_requirement'
          )
    ) THEN
        RAISE EXCEPTION 'phase17: forbids any derived/inferred claim about the standing requirement';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key ~* 'complian|transport|removed|remained|present'
    ) THEN
        RAISE EXCEPTION 'phase17: forbids a fabricated compliance/transport/presence claim key';
    END IF;

    -- 7. Provenance: every direct claim touching the standing-requirement event or predicate
    --    has the complete Source -> Dataset -> SourceRecord -> Citation -> Evidence ->
    --    ClaimEvidence -> Claim -> Proposition chain. Scoped by event/predicate, not
    --    claim-key naming, so any injected claim is caught regardless of its key.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (p.predicate = 'standingRequirementIn'
               OR ov.event_key = 'ark_covenant_pole_standing_requirement')
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = e.source_record_id
                                    AND sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'phase17: a standing-requirement direct claim lacks complete source-to-proposition provenance';
    END IF;

    -- Every SUPPORTS evidence link for the standing-requirement claim must itself have a
    -- citation; an evidence row with no citation at all must never silently count as valid
    -- provenance merely because the claim also has a separate, correctly-cited link.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE c.claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT'
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase17: every evidence row supporting the standing-requirement claim requires a citation';
    END IF;

    IF (
        SELECT count(*)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        JOIN citation ci ON ci.citation_id = ec.citation_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
                              AND sr.source_record_id = ci.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT'
          AND sr.source_record_key = 'MT_EXO_25_15'
          AND d.dataset_key = 'EXO_MT_REF'
          AND s.source_key = 'EXO_MT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: CLAIM_POLES_STANDING_REQUIREMENT lacks complete source-to-proposition provenance';
    END IF;

    IF (SELECT claim_type_code FROM claim WHERE claim_key = 'CLAIM_POLES_STANDING_REQUIREMENT') <> 'DIRECT_SOURCE_CLAIM' THEN
        RAISE EXCEPTION 'phase17: CLAIM_POLES_STANDING_REQUIREMENT must remain a direct, non-derived source claim';
    END IF;

    -- 8. Preserved Phase 16 semantics: hasComponent, materials, dimensions, builder, and
    --    instruction/construction propositions for the Ark of the Covenant, its rings, and
    --    its poles remain exactly as Phase 16 established -- unmodified and unmerged.
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE p.predicate = 'hasComponent'
          AND (s.entity_key, o.entity_key) IN (
              ('ark_of_covenant', 'rings_ark_covenant'), ('ark_of_covenant', 'poles_ark_covenant')
          )
    ) <> 2 THEN
        RAISE EXCEPTION 'phase17: Phase 16 hasComponent propositions for rings/poles must remain unchanged';
    END IF;

    IF (
        SELECT count(*) FROM proposition p
        JOIN entity e ON e.entity_id = p.subject_entity_id
        WHERE e.entity_key = 'poles_ark_covenant'
          AND p.predicate IN ('madeOfMaterial', 'overlaidWithMaterial')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase17: Phase 16 poles_ark_covenant material propositions must remain unchanged';
    END IF;

    IF (
        SELECT count(*) FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE en.entity_key = 'ark_of_covenant' AND si.source_identity_key = 'mt-ark-covenant'
          AND esm.mapping_status_code = 'ACTIVE' AND esm.supporting_evidence_id IS NOT NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: the Phase 16 ark_of_covenant/mt-ark-covenant active mapping must remain intact';
    END IF;

    -- 9. No new source identity or reconciliation was introduced for poles_ark_covenant or
    --    rings_ark_covenant in this phase (none is warranted; the standing requirement is a
    --    direct claim about the already-canonical entity, not a new identity to reconcile).
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key IN ('poles_ark_covenant', 'rings_ark_covenant')
    ) THEN
        RAISE EXCEPTION 'phase17: forbids any unwarranted new source-identity mapping for poles/rings';
    END IF;

    -- 10. Noah's Ark remains entirely unaffected: its entity, its Phase 16 propositions, and
    --     its event participations are unchanged.
    IF (
        SELECT count(*) FROM entity WHERE entity_key = 'noahs_ark' AND entity_type_code = 'OBJECT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase17: noahs_ark must remain the sole, unduplicated canonical OBJECT entity';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity e ON e.entity_id = p.subject_entity_id OR e.entity_id = p.object_entity_id
        WHERE e.entity_key = 'noahs_ark' AND p.predicate = 'standingRequirementIn'
    ) THEN
        RAISE EXCEPTION 'phase17: noahs_ark must not receive any standing-requirement proposition';
    END IF;

    IF (
        SELECT count(DISTINCT ep.event_id)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'noahs_ark'
    ) <> 4 THEN
        RAISE EXCEPTION 'phase17: noahs_ark projected event participation must remain exactly as Phase 16 established';
    END IF;
END $$;
