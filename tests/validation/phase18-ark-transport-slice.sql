\set ON_ERROR_STOP on

-- Phase 18 validates that the existing generic Entity/SourceIdentity/EntitySourceMapping/
-- Proposition/Claim/Evidence/Event architecture -- unextended, with NO new event_type and NO
-- new predicate -- can faithfully represent the source-backed Joshua 3:6 Ark-of-the-Covenant
-- transport/handling occurrence, while preserving the distinction between an instruction, a
-- historical/completed transport event, the Exodus 25:15 STANDING_REQUIREMENT, and any
-- inferred compliance claim -- none of which, other than the transport occurrence itself, is
-- asserted in this phase.
DO $$
BEGIN
    -- 1. Locator integrity: exactly one new source record, in a new JOS_MT_REF dataset, with
    --    exactly one matching, unquoted citation and no fabricated text/hash. No unintended
    --    locator (e.g. Numbers 4:15/7:9/10:21, Joshua 3:3, Joshua 6:6-13, 2 Samuel 6:3-7) exists.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'JOS_MT_REF' AND sr.source_record_key = 'MT_JOS_3_6'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: expected exactly one Joshua 3:6 locator in JOS_MT_REF';
    END IF;

    IF (SELECT count(*) FROM source WHERE source_key = 'JOS_MT') <> 1 THEN
        RAISE EXCEPTION 'phase18: expected exactly one JOS_MT source';
    END IF;

    IF (SELECT count(*) FROM dataset WHERE dataset_key = 'JOS_MT_REF') <> 1 THEN
        RAISE EXCEPTION 'phase18: expected exactly one JOS_MT_REF dataset';
    END IF;

    IF (
        SELECT count(*) FROM source_record
        WHERE dataset_id = (SELECT dataset_id FROM dataset WHERE dataset_key = 'JOS_MT_REF')
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: forbids any unintended locator in JOS_MT_REF (only Joshua 3:6 is in scope)';
    END IF;

    IF EXISTS (
        SELECT 1 FROM source_record
        WHERE source_record_key = 'MT_JOS_3_6'
          AND (raw_content IS NOT NULL OR content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase18: forbids fabricated source text or hash for Joshua 3:6';
    END IF;

    IF (
        SELECT count(ci.citation_id)
        FROM source_record sr
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = 'MT_JOS_3_6'
          AND ci.locator = sr.source_location AND ci.quoted_text IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: Joshua 3:6 requires exactly one matching, unquoted citation';
    END IF;

    -- 2. Registry sufficiency: this phase adds NO event_type and NO predicate. The transport
    --    occurrence must use the pre-existing generic OTHER event_type, and only the
    --    pre-existing subjectOf/participatesIn predicates.
    IF (
        SELECT count(*) FROM event_type
    ) <> (SELECT count(*) FROM event_type WHERE event_type_code IN (
              'BIRTH', 'DEATH', 'GENEALOGICAL', 'CHRONOLOGICAL', 'OTHER',
              'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT'
          )) THEN
        RAISE EXCEPTION 'phase18: forbids any new event_type; only the pre-existing registry may be used';
    END IF;

    IF (
        SELECT count(*) FROM predicate
    ) <> (SELECT count(*) FROM predicate WHERE predicate_code IN (
              'fatherOf', 'motherOf', 'siblingOf', 'locatedAt', 'occursAt', 'precedes',
              'participatesIn', 'subjectOf', 'parentIn', 'childIn', 'builderIn',
              'ageAtDeathYears', 'ageAtFatherhoodYears', 'yearsFromCreation',
              'lengthCubits', 'widthCubits', 'heightCubits', 'madeOfMaterial',
              'overlaidWithMaterial', 'hasComponent', 'containsContent', 'standingRequirementIn'
          )) THEN
        RAISE EXCEPTION 'phase18: forbids any new predicate; only the pre-existing registry may be used';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('artifact_transport', 'transport', 'carrier', 'transport_event',
                             'artifact_participation', 'event_participant', 'artifact',
                             'object', 'thing', 'artifact_attribute', 'artifact_component',
                             'artifact_content', 'object_relationship', 'requirement')
    ) THEN
        RAISE EXCEPTION 'phase18: forbids any artifact/transport-specific table';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name IN ('entity', 'proposition', 'claim', 'event')
          AND data_type IN ('json', 'jsonb')
    ) THEN
        RAISE EXCEPTION 'phase18: forbids JSON semantic payloads';
    END IF;

    -- 3. Exactly one canonical Ark; poles/rings reused unchanged; no duplicate artifact entity.
    IF (
        SELECT count(*) FROM entity
        WHERE entity_key = 'ark_of_covenant' AND entity_type_code = 'OBJECT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: expected exactly one canonical ark_of_covenant OBJECT entity';
    END IF;

    IF (
        SELECT count(*) FROM entity
        WHERE entity_key IN ('poles_ark_covenant', 'rings_ark_covenant') AND entity_type_code = 'OBJECT'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase18: expected the pre-existing poles/rings OBJECT entities to remain, unduplicated';
    END IF;

    IF (
        SELECT count(*) FROM entity
        WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%ark of the covenant%'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: forbids any duplicate Ark-of-the-Covenant entity';
    END IF;

    IF (
        SELECT count(*) FROM entity
        WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%poles of the ark%'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: forbids any duplicate poles-of-the-ark entity';
    END IF;

    IF (
        SELECT count(*) FROM entity
        WHERE entity_type_code = 'OBJECT' AND canonical_name ILIKE '%rings of the ark%'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: forbids any duplicate rings-of-the-ark entity';
    END IF;

    -- 4. The new priests entity is exactly one, previously nonexistent, ORGANIZATION entity.
    IF (
        SELECT count(*) FROM entity
        WHERE entity_key = 'priests_levites_ark_bearers' AND entity_type_code = 'ORGANIZATION'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: expected exactly one priests_levites_ark_bearers ORGANIZATION entity';
    END IF;

    -- 5. Historical transport distinct from STANDING_REQUIREMENT, INSTRUCTION, and CONSTRUCTION.
    IF (
        SELECT count(*) FROM event
        WHERE event_key = 'ark_covenant_transport_jordan' AND event_type_code = 'OTHER'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: expected ark_covenant_transport_jordan typed OTHER (historical transport)';
    END IF;

    IF (
        SELECT count(*) FROM event
        WHERE event_key = 'ark_covenant_transport_instruction_jordan' AND event_type_code = 'INSTRUCTION'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: expected ark_covenant_transport_instruction_jordan typed INSTRUCTION';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event
        WHERE event_key IN ('ark_covenant_transport_jordan', 'ark_covenant_transport_instruction_jordan')
          AND event_type_code IN ('STANDING_REQUIREMENT', 'CONSTRUCTION')
    ) THEN
        RAISE EXCEPTION 'phase18: transport/instruction events must never be typed STANDING_REQUIREMENT or CONSTRUCTION';
    END IF;

    -- 6. Only explicitly source-supported transport participants: exactly the ark (subjectOf)
    --    and the priests (participatesIn) on the transport event; no fabricated participant.
    IF (
        SELECT count(DISTINCT ep.entity_id)
        FROM event_participation ep
        JOIN event e ON e.event_id = ep.event_id
        WHERE e.event_key = 'ark_covenant_transport_jordan'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase18: expected exactly two projected participants (ark, priests) on the transport event';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event e ON e.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE e.event_key = 'ark_covenant_transport_jordan'
          AND en.entity_key NOT IN ('ark_of_covenant', 'priests_levites_ark_bearers')
    ) THEN
        RAISE EXCEPTION 'phase18: forbids any transport participant other than the ark and the priests';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event e ON e.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE e.event_key = 'ark_covenant_transport_jordan'
          AND en.entity_key = 'ark_of_covenant' AND ep.role_code <> 'SUBJECT'
    ) THEN
        RAISE EXCEPTION 'phase18: the ark must be the SUBJECT (thing carried), not a generic participant, of the transport event';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event e ON e.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE e.event_key = 'ark_covenant_transport_jordan'
          AND en.entity_key = 'priests_levites_ark_bearers' AND ep.role_code = 'PARTICIPANT'
    ) THEN
        RAISE EXCEPTION 'phase18: expected the priests as a PARTICIPANT on the transport event';
    END IF;

    -- No poles/rings/noahs_ark participation was fabricated for this transport event.
    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN event e ON e.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE e.event_key = 'ark_covenant_transport_jordan'
          AND en.entity_key IN ('poles_ark_covenant', 'rings_ark_covenant', 'noahs_ark')
    ) THEN
        RAISE EXCEPTION 'phase18: forbids fabricating poles/rings/noahs_ark participation in the transport event';
    END IF;

    -- 7. No direct event_participation inserts; the projection remains authoritative (a view).
    IF (
        SELECT count(*) FROM information_schema.views
        WHERE table_name = 'event_participation'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: event_participation must remain a view, not a directly-writable table';
    END IF;

    -- 8. Exodus 25:15 STANDING_REQUIREMENT remains intact and generates no transport
    --    participation or compliance claim.
    IF (
        SELECT count(*) FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'standingRequirementIn'
          AND en.entity_key = 'poles_ark_covenant'
          AND ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: the Phase 17 standing-requirement proposition must remain intact';
    END IF;

    IF EXISTS (
        SELECT 1 FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'ark_covenant_pole_standing_requirement'
    ) THEN
        RAISE EXCEPTION 'phase18: the standing-requirement event must never appear in event_participation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE ev.event_key = 'ark_covenant_transport_jordan' AND p.predicate = 'standingRequirementIn'
    ) THEN
        RAISE EXCEPTION 'phase18: forbids standingRequirementIn asserted against the transport event';
    END IF;

    -- The standing-requirement event itself must remain typed STANDING_REQUIREMENT; it must
    -- never be retyped as OTHER/INSTRUCTION/CONSTRUCTION to represent it as a transport
    -- occurrence, a command, or a completed build.
    IF (
        SELECT count(*) FROM event
        WHERE event_key = 'ark_covenant_pole_standing_requirement' AND event_type_code = 'STANDING_REQUIREMENT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: the standing-requirement event must remain typed STANDING_REQUIREMENT, never represented as a transport/instruction/construction event';
    END IF;

    -- 9. No compliance claim exists anywhere: nothing asserts obedience, non-removal, or that
    --    the poles remained in the rings during or because of this transport.
    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key ~* 'complian|obey|obeyed|remained|non_removal'
    ) THEN
        RAISE EXCEPTION 'phase18: forbids any fabricated compliance/obedience claim key';
    END IF;

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
              coalesce(se.entity_key, oe.entity_key) IN ('poles_ark_covenant', 'rings_ark_covenant',
                                                          'priests_levites_ark_bearers')
              OR coalesce(sv.event_key, ov.event_key) IN
                 ('ark_covenant_pole_standing_requirement', 'ark_covenant_transport_jordan',
                  'ark_covenant_transport_instruction_jordan')
          )
    ) THEN
        RAISE EXCEPTION 'phase18: forbids any derived claim about the poles/rings/priests/transport slice';
    END IF;

    -- 10. Complete provenance for every new direct claim in this phase.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (se.entity_key = 'priests_levites_ark_bearers'
               OR coalesce(sv.event_key, ov.event_key) IN
                  ('ark_covenant_transport_jordan', 'ark_covenant_transport_instruction_jordan'))
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
                AND sr.source_record_key = 'MT_JOS_3_6' AND d.dataset_key = 'JOS_MT_REF'
                AND s.source_key = 'JOS_MT'
          )
    ) THEN
        RAISE EXCEPTION 'phase18: a transport-slice direct claim lacks complete source-to-proposition provenance';
    END IF;

    -- Every SUPPORTS evidence link for each transport-slice claim must itself have a citation;
    -- an evidence row with no citation must never silently count as valid provenance merely
    -- because the claim also has a separate, correctly-cited link.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE c.claim_key IN (
            'CLAIM_PRIESTS_RECIPIENT_ARK_TRANSPORT_INSTRUCTION',
            'CLAIM_ARK_COVENANT_PARTICIPANT_TRANSPORT_INSTRUCTION',
            'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
            'CLAIM_PRIESTS_PARTICIPANT_TRANSPORT_JORDAN'
          )
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN
        RAISE EXCEPTION 'phase18: every evidence row supporting a transport-slice claim requires a citation';
    END IF;

    IF (
        SELECT count(*) FROM claim
        WHERE claim_key IN (
            'CLAIM_PRIESTS_RECIPIENT_ARK_TRANSPORT_INSTRUCTION',
            'CLAIM_ARK_COVENANT_PARTICIPANT_TRANSPORT_INSTRUCTION',
            'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
            'CLAIM_PRIESTS_PARTICIPANT_TRANSPORT_JORDAN'
        ) AND claim_type_code = 'DIRECT_SOURCE_CLAIM'
    ) <> 4 THEN
        RAISE EXCEPTION 'phase18: expected all four transport-slice claims as direct source claims';
    END IF;

    -- 11. Source identities/mappings unchanged unless a genuinely distinct supported identity
    --     is introduced. This phase introduces none for the ark, poles, rings, or priests.
    IF EXISTS (
        SELECT 1 FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key IN ('ark_of_covenant', 'poles_ark_covenant', 'rings_ark_covenant',
                                'priests_levites_ark_bearers')
          AND esm.source_identity_id NOT IN (
              SELECT source_identity_id FROM source_identity WHERE source_identity_key = 'mt-ark-covenant'
          )
    ) THEN
        RAISE EXCEPTION 'phase18: forbids any unwarranted new source-identity mapping introduced by this phase';
    END IF;

    IF (
        SELECT count(*) FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE en.entity_key = 'ark_of_covenant' AND si.source_identity_key = 'mt-ark-covenant'
          AND esm.mapping_status_code = 'ACTIVE' AND esm.supporting_evidence_id IS NOT NULL
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: the Phase 16 ark_of_covenant/mt-ark-covenant active mapping must remain intact';
    END IF;

    -- 12. Noah's Ark and all prior Phase 6-17 semantics are unaffected by this phase.
    IF (
        SELECT count(*) FROM entity WHERE entity_key = 'noahs_ark' AND entity_type_code = 'OBJECT'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase18: noahs_ark must remain the sole, unduplicated canonical OBJECT entity';
    END IF;

    IF (
        SELECT count(DISTINCT ep.event_id)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'noahs_ark'
    ) <> 4 THEN
        RAISE EXCEPTION 'phase18: noahs_ark projected event participation must remain exactly as Phase 16 established';
    END IF;

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
        RAISE EXCEPTION 'phase18: Phase 16 hasComponent propositions for rings/poles must remain unchanged';
    END IF;
END $$;
