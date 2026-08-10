\set ON_ERROR_STOP on

-- Phase 16 validates that the existing generic Entity/SourceIdentity/EntitySourceMapping/
-- Proposition/Claim/Evidence/Event architecture can faithfully represent rich, source-backed
-- persistent-artifact semantics for Noah's Ark (Genesis 6-7) and the Ark of the Covenant
-- (Exodus 25/37/40, Deuteronomy 10), without adding artifact-specific tables or fabricating
-- unsupported content.
DO $$
BEGIN
    -- 1. Locator integrity: exactly the intended Phase 16 source records exist, in the intended
    --    datasets, and no other Genesis 6-7 verse, Exodus, or Deuteronomy locator appears.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN ('MT_GEN_6_14', 'MT_GEN_6_15', 'MT_GEN_6_16',
                                        'MT_GEN_6_22', 'MT_GEN_7_7')
    ) <> 5 THEN
        RAISE EXCEPTION 'phase16: expected exactly five Genesis 6-7 artifact-construction locators';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (6, 7)
          AND sr.source_record_key NOT IN ('MT_GEN_6_14', 'MT_GEN_6_15', 'MT_GEN_6_16',
                                            'MT_GEN_6_22', 'MT_GEN_7_7')
    ) THEN
        RAISE EXCEPTION 'phase16: Genesis chapters 6-7 must remain bounded to exactly the five intended locators';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'EXO_MT_REF'
          AND sr.source_record_key IN ('MT_EXO_25_10', 'MT_EXO_25_11', 'MT_EXO_25_12',
                                        'MT_EXO_25_13', 'MT_EXO_25_17', 'MT_EXO_25_18',
                                        'MT_EXO_37_1', 'MT_EXO_40_20')
    ) <> 8 THEN
        RAISE EXCEPTION 'phase16: expected exactly eight Exodus Ark-of-the-Covenant locators';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'DEU_MT_REF'
          AND sr.source_record_key = 'MT_DEU_10_3'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected exactly one Deuteronomy 10:3 locator';
    END IF;

    -- 2. Source integrity: every new source record belongs to its intended dataset/source, has
    --    exactly one citation whose locator matches, and stores no raw text/hash/quotation
    --    (the established "manually entered reference point" convention).
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key IN ('MT_GEN_6_14', 'MT_GEN_6_15', 'MT_GEN_6_16',
                                        'MT_GEN_6_22', 'MT_GEN_7_7', 'MT_EXO_25_10',
                                        'MT_EXO_25_11', 'MT_EXO_25_12', 'MT_EXO_25_13',
                                        'MT_EXO_25_17', 'MT_EXO_25_18', 'MT_EXO_37_1',
                                        'MT_EXO_40_20', 'MT_DEU_10_3')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase16: forbids fabricated source text or hash for any new locator';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_6_14', 'MT_GEN_6_15', 'MT_GEN_6_16',
                                        'MT_GEN_6_22', 'MT_GEN_7_7', 'MT_EXO_25_10',
                                        'MT_EXO_25_11', 'MT_EXO_25_12', 'MT_EXO_25_13',
                                        'MT_EXO_25_17', 'MT_EXO_25_18', 'MT_EXO_37_1',
                                        'MT_EXO_40_20', 'MT_DEU_10_3')
        GROUP BY sr.source_record_id, sr.source_location
        HAVING count(ci.citation_id) <> 1
            OR bool_or(ci.locator <> sr.source_location)
            OR bool_or(ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase16: every new source record requires exactly one matching, unquoted citation';
    END IF;

    -- 3. Provenance: every direct claim touching a Phase 16 artifact entity/event has the
    --    complete Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence ->
    --    Claim -> Proposition chain. Scoped by entity/event, not claim-key naming, so any
    --    injected claim is caught regardless of its key.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND c.claim_key NOT IN ('CLAIM_NOAH_ARK_RESTING', 'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT',
                                   'CLAIM_ARK_RESTING_ARARAT')
          AND (
              coalesce(se.entity_key, oe.entity_key) IN (
                  'noahs_ark', 'ark_of_covenant', 'moses', 'bezalel', 'door_noahs_ark',
                  'window_noahs_ark', 'mercy_seat', 'cherubim_kapporet', 'rings_ark_covenant',
                  'poles_ark_covenant', 'tablets_of_testimony'
              )
              OR coalesce(sv.event_key, ov.event_key) IN (
                  'ark_building_instruction', 'ark_construction_completed', 'ark_entering',
                  'ark_covenant_instruction', 'ark_covenant_construction',
                  'ark_covenant_contents_placement'
              )
          )
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
        RAISE EXCEPTION 'phase16: a Phase 16 direct claim lacks complete source-to-proposition provenance';
    END IF;

    -- 4. Entity integrity: the nine new Phase 16 OBJECT/PERSON entities exist exactly once, with
    --    no accidental duplicates.
    IF (
        SELECT count(*)
        FROM entity
        WHERE entity_key IN ('moses', 'bezalel', 'door_noahs_ark', 'window_noahs_ark',
                              'mercy_seat', 'cherubim_kapporet', 'rings_ark_covenant',
                              'poles_ark_covenant', 'tablets_of_testimony')
    ) <> 9 THEN
        RAISE EXCEPTION 'phase16: expected exactly nine new Phase 16 entities';
    END IF;

    IF EXISTS (
        SELECT canonical_name FROM entity
        WHERE entity_key IN ('moses', 'bezalel', 'door_noahs_ark', 'window_noahs_ark',
                              'mercy_seat', 'cherubim_kapporet', 'rings_ark_covenant',
                              'poles_ark_covenant', 'tablets_of_testimony', 'noahs_ark',
                              'ark_of_covenant')
        GROUP BY canonical_name
        HAVING count(*) <> 1
    ) THEN
        RAISE EXCEPTION 'phase16: no accidental duplicate canonical artifact/person entities';
    END IF;

    -- 5. SourceIdentity/EntitySourceMapping: the Ark of the Covenant now has one auditable,
    --    evidence-backed, ACTIVE mapping (resolving the Phase 11/14/15 unmapped status), distinct
    --    from noahs_ark's existing mapping.
    IF (
        SELECT count(*)
        FROM source_identity si
        JOIN source s ON s.source_id = si.source_id
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
        WHERE si.source_identity_key = 'mt-ark-covenant'
          AND s.source_key = 'EXO_MT'
          AND en.entity_key = 'ark_of_covenant'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.confidence IS NOT NULL
          AND btrim(coalesce(esm.justification, '')) <> ''
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: requires one active, evidence-backed mt-ark-covenant mapping to ark_of_covenant';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key = 'mt-ark-covenant' AND en.entity_key <> 'ark_of_covenant'
    ) THEN
        RAISE EXCEPTION 'phase16: mt-ark-covenant must not be mapped to any entity other than ark_of_covenant';
    END IF;

    -- No ACTIVE mapping to any Phase 16 artifact entity may exist without supporting evidence.
    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key IN ('noahs_ark', 'ark_of_covenant')
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase16: an active mapping to a Phase 16 artifact entity requires supporting evidence';
    END IF;

    -- 6. Instruction vs completed construction: recipients of instruction are distinguished from
    --    builders; INSTRUCTION events are never conflated with CONSTRUCTION events.
    IF (
        SELECT count(*) FROM event
        WHERE event_key IN ('ark_building_instruction', 'ark_covenant_instruction')
          AND event_type_code = 'INSTRUCTION'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase16: instruction events must be typed INSTRUCTION, distinct from completed construction';
    END IF;

    IF (
        SELECT count(*) FROM event
        WHERE event_key IN ('ark_construction_completed', 'ark_covenant_construction')
          AND event_type_code = 'CONSTRUCTION'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase16: completed-construction events must be typed CONSTRUCTION, distinct from instruction';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'builderIn' AND ev.event_type_code <> 'CONSTRUCTION'
    ) THEN
        RAISE EXCEPTION 'phase16: builderIn must only target a CONSTRUCTION event, never an INSTRUCTION event';
    END IF;

    -- 7. Builder relationships: Noah is builder of the completed ark; Bezalel and Moses are each
    --    independently asserted as builder of the completed Ark of the Covenant (a genuine,
    --    preserved source disagreement, not a merge).
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'builderIn' AND en.entity_key = 'noah'
          AND ev.event_key = 'ark_construction_completed'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected exactly one Noah builderIn ark_construction_completed proposition';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE p.predicate = 'builderIn' AND en.entity_key IN ('bezalel', 'moses')
          AND ev.event_key = 'ark_covenant_construction'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase16: expected both Bezalel and Moses independently asserted as builderIn ark_covenant_construction';
    END IF;

    -- 8. The Bezalel/Moses builder disagreement is preserved via claim_relation, mirroring the
    --    existing MT/LXX contradiction convention, never silently merged or deleted.
    IF (
        SELECT count(*)
        FROM claim_relation cr
        JOIN claim a ON a.claim_id = cr.claim_id
        JOIN claim b ON b.claim_id = cr.related_claim_id
        WHERE cr.relation_type_code = 'CONTRADICTS'
          AND a.claim_key IN ('CLAIM_BEZALEL_BUILDER_ARK_COVENANT', 'CLAIM_MOSES_BUILDER_ARK_COVENANT')
          AND b.claim_key IN ('CLAIM_BEZALEL_BUILDER_ARK_COVENANT', 'CLAIM_MOSES_BUILDER_ARK_COVENANT')
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected exactly one preserved Bezalel/Moses builder contradiction relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM claim WHERE claim_key = 'CLAIM_BEZALEL_BUILDER_ARK_COVENANT')
       OR NOT EXISTS (SELECT 1 FROM claim WHERE claim_key = 'CLAIM_MOSES_BUILDER_ARK_COVENANT') THEN
        RAISE EXCEPTION 'phase16: both competing builder claims must remain independently present, never merged away';
    END IF;

    -- 9. Dimensions preserve original unit via unit-suffixed predicates; no bare/unitless
    --    dimension predicate and no modern-unit conversion or derivation exists.
    IF NOT EXISTS (
        SELECT 1 FROM predicate WHERE predicate_code IN ('lengthCubits', 'widthCubits', 'heightCubits')
    ) THEN
        RAISE EXCEPTION 'phase16: expected the registered cubit-unit dimension predicates';
    END IF;

    IF EXISTS (SELECT 1 FROM predicate WHERE predicate_code IN ('length', 'width', 'height', 'lengthMeters')) THEN
        RAISE EXCEPTION 'phase16: forbids a bare/unitless or modern-unit dimension predicate';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
        WHERE en.entity_key = 'noahs_ark' AND p.predicate = 'lengthCubits' AND t.numeric_value = 300
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected noahs_ark lengthCubits 300, preserving the source''s original unit';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim WHERE claim_type_code = 'DERIVED_CLAIM'
          AND (claim_key LIKE '%METER%' OR claim_key LIKE '%CONVERSION%')
    ) THEN
        RAISE EXCEPTION 'phase16: forbids a fabricated modern-unit conversion derivation';
    END IF;

    -- 10. Materials distinguish made-of (structural) from overlay/covering; no conflation.
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
        WHERE en.entity_key = 'ark_of_covenant' AND p.predicate = 'madeOfMaterial' AND t.text_value = 'acacia wood'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected ark_of_covenant madeOfMaterial acacia wood';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
        WHERE en.entity_key = 'ark_of_covenant' AND p.predicate = 'overlaidWithMaterial' AND t.text_value = 'pure gold'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected ark_of_covenant overlaidWithMaterial pure gold, distinct from madeOfMaterial';
    END IF;

    -- 11. Components/contents use entity-to-entity propositions only where the source itself
    --     individually specifies a persistent referent; no invented component/content.
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE p.predicate = 'hasComponent'
          AND (s.entity_key, o.entity_key) IN (
              ('noahs_ark', 'door_noahs_ark'), ('noahs_ark', 'window_noahs_ark'),
              ('ark_of_covenant', 'rings_ark_covenant'), ('ark_of_covenant', 'poles_ark_covenant'),
              ('ark_of_covenant', 'mercy_seat'), ('mercy_seat', 'cherubim_kapporet')
          )
    ) <> 6 THEN
        RAISE EXCEPTION 'phase16: expected exactly the six source-specified hasComponent propositions';
    END IF;

    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE p.predicate = 'containsContent'
          AND s.entity_key = 'ark_of_covenant' AND o.entity_key = 'tablets_of_testimony'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase16: expected exactly one ark_of_covenant containsContent tablets_of_testimony proposition';
    END IF;

    -- 12. Handling/transport restriction (Exodus 25:15) is intentionally NOT encoded as a claim,
    --     since it is a standing requirement rather than a single event occurrence; this
    --     documents the semantic precision gap rather than forcing false event-participation
    --     precision.
    IF EXISTS (
        SELECT 1 FROM source_record WHERE source_record_key = 'MT_EXO_25_15'
    ) THEN
        RAISE EXCEPTION 'phase16: Exodus 25:15 handling restriction must remain an unpopulated, documented semantic precision gap';
    END IF;

    -- 13. Event participation projection: noahs_ark and ark_of_covenant participation is
    --     correctly projected for every new event, with no authoritative participant store.
    IF (
        SELECT count(DISTINCT ep.event_id)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'noahs_ark'
          AND ep.event_id IN (
              SELECT event_id FROM event
              WHERE event_key IN ('ark_building_instruction', 'ark_entering')
          )
    ) <> 2 THEN
        RAISE EXCEPTION 'phase16: noahs_ark participation must be projected for ark_building_instruction and ark_entering';
    END IF;

    IF (
        SELECT count(DISTINCT ep.event_id)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'ark_of_covenant'
          AND ep.event_id IN (
              SELECT event_id FROM event
              WHERE event_key IN ('ark_covenant_instruction', 'ark_covenant_contents_placement')
          )
    ) <> 2 THEN
        RAISE EXCEPTION 'phase16: ark_of_covenant participation must be projected for its instruction and contents-placement events';
    END IF;

    IF (SELECT table_type FROM information_schema.tables WHERE table_name = 'event_participation') <> 'VIEW'
       OR EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_name IN ('event_participant', 'artifact', 'object', 'thing',
                                'artifact_attribute', 'artifact_component', 'artifact_content',
                                'artifact_participation', 'object_relationship')
       ) THEN
        RAISE EXCEPTION 'phase16: event participation must remain a projection with no artifact-specific store';
    END IF;

    -- 14. No JSON semantic payload has been introduced onto entity/proposition/claim.
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name IN ('entity', 'proposition', 'claim')
          AND data_type IN ('json', 'jsonb')
    ) THEN
        RAISE EXCEPTION 'phase16: forbids JSON semantic payloads';
    END IF;

    -- 15. Any derived claim touching a Phase 16 artifact entity/event must have a derivation and
    --     complete derivation_input rows, and may never be its own derivation input.
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
              coalesce(se.entity_key, oe.entity_key) IN (
                  'noahs_ark', 'ark_of_covenant', 'moses', 'bezalel', 'door_noahs_ark',
                  'window_noahs_ark', 'mercy_seat', 'cherubim_kapporet', 'rings_ark_covenant',
                  'poles_ark_covenant', 'tablets_of_testimony'
              )
              OR coalesce(sv.event_key, ov.event_key) IN (
                  'ark_building_instruction', 'ark_construction_completed', 'ark_entering',
                  'ark_covenant_instruction', 'ark_covenant_construction',
                  'ark_covenant_contents_placement'
              )
          )
          AND (c.derivation_id IS NULL OR NOT EXISTS (
              SELECT 1 FROM derivation_input di WHERE di.derivation_id = c.derivation_id
          ))
    ) THEN
        RAISE EXCEPTION 'phase16: a derived artifact claim lacks complete derivation inputs';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        JOIN derivation_input di ON di.derivation_id = c.derivation_id
        WHERE di.input_claim_id = c.claim_id
    ) THEN
        RAISE EXCEPTION 'phase16: a derived claim must never be its own derivation input';
    END IF;

    -- 16. No derivation was introduced; every Phase 16 claim remains a DIRECT_SOURCE_CLAIM.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE 'CLAIM_%'
          AND c.claim_key IN (
              'CLAIM_NOAH_RECIPIENT_ARK_INSTRUCTION', 'CLAIM_ARK_PARTICIPANT_INSTRUCTION',
              'CLAIM_NOAH_BUILDER_ARK', 'CLAIM_ARK_SUBJECT_CONSTRUCTION',
              'CLAIM_NOAH_ENTERING_ARK', 'CLAIM_ARK_PARTICIPANT_ENTERING',
              'CLAIM_MOSES_RECIPIENT_ARK_COVENANT_INSTRUCTION', 'CLAIM_ARK_COVENANT_PARTICIPANT_INSTRUCTION',
              'CLAIM_BEZALEL_BUILDER_ARK_COVENANT', 'CLAIM_MOSES_BUILDER_ARK_COVENANT',
              'CLAIM_ARK_COVENANT_SUBJECT_CONSTRUCTION', 'CLAIM_MOSES_PLACES_TESTIMONY',
              'CLAIM_TESTIMONY_PARTICIPANT_PLACEMENT', 'CLAIM_ARK_COVENANT_PARTICIPANT_PLACEMENT',
              'CLAIM_ARK_HAS_DOOR', 'CLAIM_ARK_HAS_WINDOW', 'CLAIM_ARK_COVENANT_HAS_RINGS',
              'CLAIM_ARK_COVENANT_HAS_POLES', 'CLAIM_ARK_COVENANT_HAS_MERCY_SEAT',
              'CLAIM_MERCY_SEAT_HAS_CHERUBIM', 'CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY',
              'CLAIM_ARK_LENGTH_CUBITS', 'CLAIM_ARK_WIDTH_CUBITS', 'CLAIM_ARK_HEIGHT_CUBITS',
              'CLAIM_ARK_COVENANT_LENGTH_CUBITS', 'CLAIM_ARK_COVENANT_WIDTH_CUBITS',
              'CLAIM_ARK_COVENANT_HEIGHT_CUBITS', 'CLAIM_MERCY_SEAT_LENGTH_CUBITS',
              'CLAIM_MERCY_SEAT_WIDTH_CUBITS', 'CLAIM_ARK_MADE_OF_GOPHER_WOOD',
              'CLAIM_ARK_COVERED_WITH_PITCH', 'CLAIM_ARK_COVENANT_MADE_OF_ACACIA',
              'CLAIM_ARK_COVENANT_OVERLAID_GOLD', 'CLAIM_POLES_MADE_OF_ACACIA',
              'CLAIM_POLES_OVERLAID_GOLD', 'CLAIM_MERCY_SEAT_MADE_OF_GOLD',
              'CLAIM_CHERUBIM_MADE_OF_GOLD'
          )
          AND (c.claim_type_code <> 'DIRECT_SOURCE_CLAIM' OR c.derivation_id IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase16: every Phase 16 claim must remain a direct, non-derived source claim';
    END IF;
END $$;
