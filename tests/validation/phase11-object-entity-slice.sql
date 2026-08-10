\set ON_ERROR_STOP on

DO $$
BEGIN
    -- 1. Noah's Ark and Ark of the Covenant have distinct canonical Entity records, both using
    --    the existing OBJECT entity-type value.
    IF (
        SELECT count(*)
        FROM entity
        WHERE entity_key IN ('noahs_ark', 'ark_of_covenant')
          AND entity_type_code = 'OBJECT'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase11: noahs_ark and ark_of_covenant must both exist as distinct OBJECT entities';
    END IF;

    IF (
        SELECT count(DISTINCT entity_id)
        FROM entity
        WHERE entity_key IN ('noahs_ark', 'ark_of_covenant')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase11: noahs_ark and ark_of_covenant must have distinct entity_id values';
    END IF;

    -- 2. Their source identities remain distinct: noahs_ark has exactly one active mapping to a
    --    source identity of its own, and ark_of_covenant (validation-only) has none.
    IF (
        SELECT count(*)
        FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key = 'noahs_ark'
          AND esm.mapping_status_code = 'ACTIVE'
    ) <> 1 THEN
        RAISE EXCEPTION 'phase11: noahs_ark must have exactly one active entity_source_mapping';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE en.entity_key = 'ark_of_covenant'
    ) THEN
        RAISE EXCEPTION 'phase11: ark_of_covenant must remain a validation-only entity with no source identity mapping';
    END IF;

    -- 3. Claims/evidence for one cannot silently attach to the other: no proposition, claim, or
    --    evidence references ark_of_covenant, and every proposition referencing noahs_ark does not
    --    also reference ark_of_covenant.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity en ON en.entity_id IN (p.subject_entity_id, p.object_entity_id)
        WHERE en.entity_key = 'ark_of_covenant'
    ) THEN
        RAISE EXCEPTION 'phase11: ark_of_covenant must not participate in any proposition';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE si.source_identity_key = 'mt-ark' AND en.entity_key <> 'noahs_ark'
    ) THEN
        RAISE EXCEPTION 'phase11: the mt-ark source identity must map only to noahs_ark';
    END IF;

    -- 4. Every direct object claim for noahs_ark has complete
    --    Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence -> Claim ->
    --    Proposition provenance.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        WHERE en.entity_key = 'noahs_ark'
          AND NOT EXISTS (
              SELECT 1
              FROM claim c
              JOIN claim_evidence ce ON ce.claim_id = c.claim_id
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ci.source_record_id
                                    AND sr.source_record_id = e.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE c.proposition_id = p.proposition_id
                AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
                AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN
        RAISE EXCEPTION 'phase11: noahs_ark claim lacks complete Source->Dataset->SourceRecord->Citation->Evidence->ClaimEvidence->Claim->Proposition provenance';
    END IF;

    -- 5. SourceIdentity -> EntitySourceMapping -> Entity is valid for the ark object identity used.
    IF NOT EXISTS (
        SELECT 1
        FROM source_identity si
        JOIN source s ON s.source_id = si.source_id
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE si.source_identity_key = 'mt-ark'
          AND s.source_key = 'GEN_MT'
          AND en.entity_key = 'noahs_ark'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.justification IS NOT NULL
          AND esm.supporting_evidence_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase11: mt-ark SourceIdentity->EntitySourceMapping->Entity chain is incomplete';
    END IF;

    -- 6. Object event participation is projected from asserted propositions through
    --    event_participation, not a second authoritative store.
    IF NOT EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE en.entity_key = 'noahs_ark'
          AND ev.event_key = 'ark_resting'
          AND ep.role_code = 'PARTICIPANT'
    ) THEN
        RAISE EXCEPTION 'phase11: noahs_ark event participation is missing from the event_participation projection';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        WHERE en.entity_key = 'ark_of_covenant'
    ) THEN
        RAISE EXCEPTION 'phase11: ark_of_covenant must not appear in the event_participation projection';
    END IF;

    -- 7. Existing ClaimEvidence many-to-many and competing-claim behavior remain intact: the
    --    shared MT_GEN_8_4 evidence continues to support multiple distinct claims (Noah as
    --    subject, the ark as participant, and the location claim), and the pre-existing
    --    competing Masoretic/Septuagint claims remain untouched.
    IF (
        SELECT count(DISTINCT ce.claim_id)
        FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key = 'EV_MT_GEN_8_4'
    ) < 3 THEN
        RAISE EXCEPTION 'phase11: EV_MT_GEN_8_4 must continue to support multiple distinct claims (ClaimEvidence many-to-many)';
    END IF;

    IF (
        SELECT count(*)
        FROM claim
        WHERE claim_key IN ('CLAIM_MT_ADAM_AGE_AT_SETH', 'CLAIM_LXX_ADAM_AGE_AT_SETH')
    ) <> 2 THEN
        RAISE EXCEPTION 'phase11: pre-existing competing Masoretic/Septuagint claims must remain intact';
    END IF;

    -- 8. No unsupported canonical object attributes are introduced: the entity table has no
    --    columns beyond entity_key/entity_type_code/canonical_name/description, so dimensions,
    --    materials, or contents cannot be stored as attributes; assert that neither ark entity's
    --    description encodes a dimension/material claim disguised as a canonical attribute.
    IF EXISTS (
        SELECT 1
        FROM entity
        WHERE entity_key IN ('noahs_ark', 'ark_of_covenant')
          AND (description ~* 'cubit' OR description ~* 'gopher wood' OR description ~* 'acacia wood'
               OR description ~* 'gold-plated' OR description ~* 'contains ')
    ) THEN
        RAISE EXCEPTION 'phase11: no dimension/material/content attribute may be encoded on the canonical entity';
    END IF;

    -- 9a. No unsupported event type is introduced: ark_resting keeps its existing OTHER event type.
    IF (
        SELECT event_type_code FROM event WHERE event_key = 'ark_resting'
    ) <> 'OTHER' THEN
        RAISE EXCEPTION 'phase11: ark_resting must keep its existing OTHER event type';
    END IF;

    -- 9b. No uncontrolled claim relation: the new ark participant claim has no claim_relation row.
    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id OR c.claim_id = cr.related_claim_id
        WHERE c.claim_key = 'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT'
    ) THEN
        RAISE EXCEPTION 'phase11: the new ark participant claim must not introduce a claim_relation';
    END IF;

    -- 9c. No object-specific table was introduced: assert the schema still has no thing/artifact/
    --     object-specific table by confirming the object entities live in the shared entity table.
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_name = 'entity'
    ) OR EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('thing', 'artifact', 'object', 'physical_object')
    ) THEN
        RAISE EXCEPTION 'phase11: object entities must live in the existing entity table with no new object-specific table';
    END IF;

    -- 10. Genesis 1-11 content and prior phase batches remain unaltered.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key IN (
              'MT_GEN_1_1', 'MT_GEN_1_2', 'MT_GEN_1_3', 'MT_GEN_1_4', 'MT_GEN_1_5',
              'MT_GEN_1_6', 'MT_GEN_1_7', 'MT_GEN_1_8', 'MT_GEN_1_9', 'MT_GEN_1_10',
              'MT_GEN_1_11', 'MT_GEN_1_12', 'MT_GEN_1_13', 'MT_GEN_1_14', 'MT_GEN_1_15',
              'MT_GEN_1_16', 'MT_GEN_1_17', 'MT_GEN_1_18', 'MT_GEN_1_19', 'MT_GEN_1_20',
              'MT_GEN_1_21', 'MT_GEN_1_22', 'MT_GEN_1_23', 'MT_GEN_1_24', 'MT_GEN_1_25',
              'MT_GEN_1_26', 'MT_GEN_1_27', 'MT_GEN_1_28', 'MT_GEN_1_29', 'MT_GEN_1_30',
              'MT_GEN_1_31', 'MT_GEN_5_3', 'MT_GEN_5_6', 'MT_GEN_8_4'
          )
    ) <> 34 THEN
        RAISE EXCEPTION 'phase11: Genesis 1-11 prior batch source records were altered';
    END IF;
END $$;
