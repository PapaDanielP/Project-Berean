\set ON_ERROR_STOP on

-- Phase 14 persistent object/artifact validation, bounded to the already-supported
-- Genesis 8:4 Noah's Ark slice. This phase does not add source material; it verifies that the
-- existing source-backed artifact population remains provenance-complete and architecture-neutral.
DO $$
BEGIN
    -- 1. Source availability is exactly the existing Masoretic Genesis 8:4 reference point.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE sr.source_record_key = 'MT_GEN_8_4'
          AND sr.source_location = 'Genesis 8:4'
          AND d.dataset_key = 'GEN_MT_REF'
          AND s.source_key = 'GEN_MT'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires exactly the existing Masoretic Genesis 8:4 source record';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_location = 'Genesis 8:4'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 must not fabricate additional Genesis 8:4 source records';
    END IF;

    -- 2. No source text, hash, or quotation is introduced; observation and citation stay locator-only.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key = 'MT_GEN_8_4'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL
               OR ci.citation_key <> 'CITE_MT_GEN_8_4'
               OR ci.locator <> 'Genesis 8:4'
               OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Phase 14 Genesis 8:4 source record must remain locator-only with no fabricated text, hash, or quote';
    END IF;

    IF (
        SELECT count(*)
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        JOIN citation ci ON ci.citation_id = ec.citation_id
                         AND ci.source_record_id = sr.source_record_id
        WHERE e.evidence_key = 'EV_MT_GEN_8_4'
          AND sr.source_record_key = 'MT_GEN_8_4'
          AND e.evidence_type_code = 'SOURCE_OBSERVATION'
          AND ci.locator = 'Genesis 8:4'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires one cited Genesis 8:4 source observation';
    END IF;

    -- 3. Exactly one source-backed canonical artifact entity is populated for the selected slice.
    IF (
        SELECT count(*)
        FROM entity
        WHERE entity_key = 'noahs_ark'
          AND entity_type_code = 'OBJECT'
          AND canonical_name = 'Noah''s Ark'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires exactly one canonical OBJECT entity for Noah''s Ark';
    END IF;

    IF (
        SELECT count(DISTINCT en.entity_id)
        FROM entity en
        JOIN proposition p ON p.subject_entity_id = en.entity_id
        JOIN claim c ON c.proposition_id = p.proposition_id
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE en.entity_type_code = 'OBJECT'
          AND sr.source_record_key = 'MT_GEN_8_4'
          AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires exactly one source-backed canonical artifact entity';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity en
        WHERE en.entity_type_code = 'OBJECT'
          AND en.entity_key <> 'noahs_ark'
          AND EXISTS (
              SELECT 1
              FROM proposition p
              JOIN claim c ON c.proposition_id = p.proposition_id
              JOIN claim_evidence ce ON ce.claim_id = c.claim_id
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN source_record sr ON sr.source_record_id = e.source_record_id
              WHERE sr.source_record_key = 'MT_GEN_8_4'
                AND en.entity_id IN (p.subject_entity_id, p.object_entity_id)
          )
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not attach Genesis 8:4 evidence to a duplicate or wrong artifact entity';
    END IF;

    -- 4. Source identity and mapping are distinct from the canonical entity and auditable.
    IF (
        SELECT count(*)
        FROM source_identity si
        JOIN source s ON s.source_id = si.source_id
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE si.source_identity_key = 'mt-ark'
          AND si.display_name = 'the ark'
          AND s.source_key = 'GEN_MT'
          AND en.entity_key = 'noahs_ark'
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.confidence IS NOT NULL
          AND btrim(coalesce(esm.justification, '')) <> ''
          AND sr.source_record_key = 'MT_GEN_8_4'
          AND d.source_id = si.source_id
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires one active, evidence-backed mt-ark mapping to noahs_ark';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_identity si
        JOIN entity_source_mapping esm ON esm.source_identity_id = si.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        WHERE si.source_identity_key = 'mt-ark'
          AND en.entity_key <> 'noahs_ark'
    ) THEN
        RAISE EXCEPTION 'Phase 14 must reject a wrong canonical mapping for mt-ark';
    END IF;

    -- 5. Every direct claim in the artifact event has complete
    --    Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence -> Claim -> Proposition provenance.
    IF (
        SELECT count(DISTINCT c.claim_key)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (se.entity_key = 'noahs_ark' OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND c.claim_key IN ('CLAIM_NOAH_ARK_RESTING',
                              'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT',
                              'CLAIM_ARK_RESTING_ARARAT')
    ) <> 3 THEN
        RAISE EXCEPTION 'Phase 14 requires the three bounded Genesis 8:4 direct artifact-event claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND (se.entity_key = 'noahs_ark' OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
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
              WHERE ce.claim_id = c.claim_id
                AND ce.relation_type_code = 'SUPPORTS'
                AND sr.source_record_key = 'MT_GEN_8_4'
                AND ci.locator = 'Genesis 8:4'
          )
    ) THEN
        RAISE EXCEPTION 'Phase 14 artifact claim lacks complete source-to-proposition provenance';
    END IF;

    -- 6. Registered, already-existing predicates only; no unsupported dimensions, materials,
    --    ownership, chronology, causality, taxonomy, or modern interpretation.
    IF EXISTS (
        SELECT 1
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE (se.entity_key = 'noahs_ark'
               OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND p.predicate NOT IN ('subjectOf', 'participatesIn', 'occursAt')
    ) THEN
        RAISE EXCEPTION 'Phase 14 artifact slice must use only registered predicates already justified by the source';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE (se.entity_key = 'noahs_ark' OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
          AND p.predicate IN ('precedes', 'yearsFromCreation', 'fatherOf', 'motherOf',
                              'siblingOf', 'ageAtDeathYears', 'ageAtFatherhoodYears')
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not infer chronology, genealogy, taxonomy, or modern artifact semantics';
    END IF;

    -- 7. Participation is projection-only and comes from asserted propositions.
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name IN ('event_participant', 'event_participation_store',
                             'artifact', 'object', 'thing', 'object_source_mapping',
                             'artifact_source_mapping', 'entity_relationship',
                             'relationship')
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not introduce object-specific or participant truth tables';
    END IF;

    IF (
        SELECT table_type
        FROM information_schema.tables
        WHERE table_name = 'event_participation'
    ) <> 'VIEW' THEN
        RAISE EXCEPTION 'Phase 14 requires event_participation to remain a projection view';
    END IF;

    IF (
        SELECT count(*)
        FROM event_participation ep
        JOIN entity en ON en.entity_id = ep.entity_id
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN claim c ON c.claim_id = ep.asserting_claim_id
        WHERE en.entity_key = 'noahs_ark'
          AND ev.event_key = 'ark_resting'
          AND ep.role_code = 'PARTICIPANT'
          AND c.claim_key = 'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires Noah''s Ark participation to be projected from its asserted claim';
    END IF;

    -- 8. Equivalent semantics are not duplicated as new propositions; different semantics remain distinct.
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity en ON en.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE en.entity_key = 'noahs_ark'
          AND ev.event_key = 'ark_resting'
          AND p.predicate = 'participatesIn'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 14 requires exactly one normalized noahs_ark participatesIn ark_resting proposition';
    END IF;

    IF (
        SELECT count(DISTINCT p.proposition_id)
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE se.entity_key = 'noahs_ark'
           OR sv.event_key = 'ark_resting'
           OR ov.event_key = 'ark_resting'
    ) <> 3 THEN
        RAISE EXCEPTION 'Phase 14 requires exactly three distinct Genesis 8:4 artifact-event propositions';
    END IF;

    -- 9. Existing genuine contradictions remain preserved; the artifact slice adds none.
    IF (
        SELECT count(*)
        FROM claim_relation
        WHERE relation_type_code = 'CONTRADICTS'
    ) <> 4 THEN
        RAISE EXCEPTION 'Phase 14 must preserve all existing genuine contradiction relations';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id OR c.claim_id = cr.related_claim_id
        WHERE cr.relation_type_code = 'CONTRADICTS'
          AND c.claim_key IN ('CLAIM_NOAH_ARK_RESTING',
                              'CLAIM_MT_GEN_8_4_ARK_PARTICIPANT',
                              'CLAIM_ARK_RESTING_ARARAT')
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not invent artifact contradictions for Genesis 8:4';
    END IF;

    -- 10. No derivation, unrelated Genesis chapter, or later flood narrative material is added.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN event sv ON sv.event_id = p.subject_event_id
        LEFT JOIN event ov ON ov.event_id = p.object_event_id
        WHERE c.derivation_id IS NOT NULL
          AND (se.entity_key = 'noahs_ark' OR sv.event_key = 'ark_resting'
               OR ov.event_key = 'ark_resting')
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not derive artifact claims from Genesis 8:4';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF')
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'Phase 14 must not populate unrelated Genesis flood or later chapters';
    END IF;
END $$;
