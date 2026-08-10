\set ON_ERROR_STOP on

-- Phase 13 persistent entity and relationship population, bounded to Genesis 5:9.
--
-- The slice checks that the persistent PERSON entities of the genealogical line and the
-- relationship between them are populated from source records with complete provenance, that the
-- already-existing `enosh` entity is reused rather than duplicated, and that nothing beyond the
-- source-recorded parentage, participation, and numerals is asserted.
DO $$
BEGIN
    -- 1. Exactly the two intended Genesis 5:9 structural locators, one per textual tradition.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE (sr.source_record_key, sr.source_location, d.dataset_key, s.source_key) IN (
                  ('MT_GEN_5_9', 'Genesis 5:9', 'GEN_MT_REF', 'GEN_MT'),
                  ('LXX_GEN_5_9', 'Genesis 5:9', 'GEN_LXX_REF', 'GEN_LXX')
              )
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 requires exactly the Masoretic and Septuagint Genesis 5:9 structural locators';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_location = 'Genesis 5:9'
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 has an unintended Genesis 5:9 source-record locator';
    END IF;

    -- 2. No source text, hash, or quotation is introduced; each observation cites its own record.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL
               OR ci.citation_key <> 'CITE_' || sr.source_record_key
               OR ci.locator <> sr.source_location OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Phase 13 source records must retain exact locators without text, hashes, or quotations';
    END IF;

    IF (
        SELECT count(*)
        FROM evidence e
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
          AND e.evidence_type_code = 'SOURCE_OBSERVATION'
          AND EXISTS (
              SELECT 1
              FROM evidence_citation ec
              JOIN citation ci ON ci.citation_id = ec.citation_id
              WHERE ec.evidence_id = e.evidence_id
                AND ci.source_record_id = sr.source_record_id
                AND ci.locator = sr.source_location
          )
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 requires one cited Genesis 5:9 source observation per textual tradition';
    END IF;

    -- 3. Every Genesis 5:9 direct claim has the complete provenance path
    --    Source -> Dataset -> SourceRecord -> Citation -> Evidence -> ClaimEvidence -> Claim -> Proposition.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
          AND NOT EXISTS (
              SELECT 1
              FROM claim_evidence ce2
              JOIN evidence e2 ON e2.evidence_id = ce2.evidence_id AND ce2.relation_type_code = 'SUPPORTS'
              JOIN evidence_citation ec2 ON ec2.evidence_id = e2.evidence_id
              JOIN citation ci2 ON ci2.citation_id = ec2.citation_id
              JOIN source_record sr2 ON sr2.source_record_id = e2.source_record_id
              JOIN dataset d2 ON d2.dataset_id = sr2.dataset_id
              JOIN source s2 ON s2.source_id = d2.source_id
              JOIN proposition p2 ON p2.proposition_id = c.proposition_id
              WHERE ce2.claim_id = c.claim_id
                AND ci2.source_record_id = sr2.source_record_id
          )
    ) THEN
        RAISE EXCEPTION 'Phase 13 requires a complete source-to-proposition provenance path for every Genesis 5:9 claim';
    END IF;

    -- 4. Persistent entities: `kenan` is a new canonical PERSON, and the pre-existing `enosh`
    --    entity is reused across Genesis 5:6 and Genesis 5:9 rather than duplicated.
    IF (
        SELECT count(*) FROM entity WHERE entity_key = 'kenan' AND entity_type_code = 'PERSON'
    ) <> 1 OR (
        SELECT count(*) FROM entity WHERE canonical_name IN ('Enosh', 'Kenan')
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 requires exactly one canonical PERSON entity for each of Enosh and Kenan';
    END IF;

    IF (
        SELECT count(DISTINCT sr.source_record_key)
        FROM entity en
        JOIN proposition p ON p.subject_entity_id = en.entity_id
        JOIN claim c ON c.proposition_id = p.proposition_id
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE en.entity_key = 'enosh'
          AND sr.source_record_key IN ('MT_GEN_5_6', 'MT_GEN_5_9')
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 requires the persistent enosh entity to carry claims from both Genesis 5:6 and Genesis 5:9';
    END IF;

    -- 5. Relationship population: one normalized parentage proposition shared by the neutral,
    --    Masoretic, and Septuagint claims. Only source provenance differs.
    IF (
        SELECT count(*)
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE p.predicate = 'fatherOf' AND s.entity_key = 'enosh' AND o.entity_key = 'kenan'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 13 requires exactly one normalized enosh fatherOf kenan proposition';
    END IF;

    IF (
        SELECT count(DISTINCT c.claim_id)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE p.predicate = 'fatherOf' AND s.entity_key = 'enosh' AND o.entity_key = 'kenan'
          AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
          AND c.claim_key IN ('CLAIM_ENOSH_FATHER_KENAN', 'CLAIM_MT_ENOSH_FATHER_KENAN',
                              'CLAIM_LXX_ENOSH_FATHER_KENAN')
    ) <> 3 THEN
        RAISE EXCEPTION 'Phase 13 requires the shared and both source-specific parentage claims for Genesis 5:9';
    END IF;

    -- 6. Reconciliation: source-specific identities stay distinct from the canonical entities and
    --    every active mapping is auditable through same-source evidence.
    IF (
        SELECT count(*)
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        JOIN entity en ON en.entity_id = esm.entity_id
        JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
        JOIN source_record sr ON sr.source_record_id = ev.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE si.source_identity_key IN ('mt-enosh', 'mt-kenan', 'lxx-enosh', 'lxx-kenan')
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.confidence IS NOT NULL
          AND btrim(coalesce(esm.justification, '')) <> ''
          AND d.source_id = si.source_id
          AND sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
          AND en.entity_key IN ('enosh', 'kenan')
    ) <> 4 THEN
        RAISE EXCEPTION 'Phase 13 requires four auditable Genesis 5:9 reconciliation mappings backed by same-source evidence';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key IN ('mt-enosh', 'mt-kenan', 'lxx-enosh', 'lxx-kenan')
        GROUP BY si.source_identity_key
        HAVING count(DISTINCT esm.entity_id) > 1
    ) THEN
        RAISE EXCEPTION 'Phase 13 must not map one source identity to multiple canonical entities';
    END IF;

    -- 7. Participation stays a projection of claim-asserted propositions.
    IF (
        SELECT count(*)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        JOIN entity en ON en.entity_id = ep.entity_id
        JOIN claim c ON c.claim_id = ep.asserting_claim_id
        WHERE ev.event_key = 'kenan_begetting'
          AND ((en.entity_key = 'enosh' AND ep.role_code = 'PARENT'
                AND c.claim_key = 'CLAIM_ENOSH_PARENT_KENAN_BEGETTING')
            OR (en.entity_key = 'kenan' AND ep.role_code = 'CHILD'
                AND c.claim_key = 'CLAIM_KENAN_CHILD_KENAN_BEGETTING'))
    ) <> 2 OR (
        SELECT count(*)
        FROM event_participation ep
        JOIN event ev ON ev.event_id = ep.event_id
        WHERE ev.event_key = 'kenan_begetting'
    ) <> 2 THEN
        RAISE EXCEPTION 'Phase 13 requires exactly the projected parent and child participation for kenan_begetting';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name IN ('event_participant', 'event_participation_store', 'relationship',
                             'entity_relationship', 'person')
    ) THEN
        RAISE EXCEPTION 'Phase 13 must not introduce an authoritative participation or relationship table';
    END IF;

    -- 8. No inference: no derivation, chronology, ordering, or unsourced kinship is attached to
    --    the Genesis 5:9 material.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN source_record sr ON sr.source_record_id = e.source_record_id
        WHERE sr.source_record_key IN ('MT_GEN_5_9', 'LXX_GEN_5_9')
          AND (c.claim_type_code = 'DERIVED_CLAIM' OR c.derivation_id IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'Phase 13 must not derive claims from the Genesis 5:9 records';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN event e ON e.event_id = p.subject_event_id OR e.event_id = p.object_event_id
        WHERE e.event_key = 'kenan_begetting'
          AND p.predicate IN ('precedes', 'yearsFromCreation')
    ) THEN
        RAISE EXCEPTION 'Phase 13 must not add event ordering or chronology for the Genesis 5:9 begetting';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE 'kenan' IN (s.entity_key, o.entity_key)
          AND NOT (s.entity_key = 'enosh' AND o.entity_key = 'kenan' AND p.predicate = 'fatherOf')
    ) THEN
        RAISE EXCEPTION 'Phase 13 must not assert kinship for kenan beyond the source-recorded parentage';
    END IF;

    -- 9. Competing numerals are preserved rather than harmonized.
    IF (
        SELECT count(*)
        FROM claim_relation cr
        JOIN claim a ON a.claim_id = cr.claim_id
        JOIN claim b ON b.claim_id = cr.related_claim_id
        WHERE cr.relation_type_code = 'CONTRADICTS'
          AND a.claim_key = 'CLAIM_LXX_ENOSH_AGE_AT_KENAN'
          AND b.claim_key = 'CLAIM_MT_ENOSH_AGE_AT_KENAN'
          AND a.claim_status_code = 'ACTIVE' AND b.claim_status_code = 'ACTIVE'
    ) <> 1 THEN
        RAISE EXCEPTION 'Phase 13 must preserve the competing Genesis 5:9 age claims as active contradicting claims';
    END IF;

    -- 10. Prior phase boundaries are unaltered.
    IF (
        SELECT count(*)
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key = 'GEN_MT_REF'
          AND sr.source_record_key LIKE 'MT\_GEN\_1\_%' ESCAPE '\'
    ) <> 31 THEN
        RAISE EXCEPTION 'Phase 13 must preserve the 31 Genesis 1 structural locators';
    END IF;

    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_record_key IN ('MT_GEN_5_3', 'MT_GEN_5_6', 'MT_GEN_8_4',
                                    'LXX_GEN_5_3', 'LXX_GEN_5_6')
    ) <> 5 THEN
        RAISE EXCEPTION 'Phase 13 must preserve the prior Genesis 5 and Genesis 8 locators';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('GEN_MT_REF', 'GEN_LXX_REF')
          AND substring(sr.source_location FROM '^Genesis ([0-9]+):')::int IN (2, 3, 4, 6, 7, 9, 10, 11)
    ) THEN
        RAISE EXCEPTION 'Phase 13 must leave Genesis chapters 2-4, 6-7, and 9-11 deferred';
    END IF;
END $$;
