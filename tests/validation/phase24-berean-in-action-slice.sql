\set ON_ERROR_STOP on

-- Phase 24 validates a reproducible Ark/Genesis knowledge-construction demonstration built on
-- accepted Phase 19-23 architecture without schema/registry/persistence expansion.
DO $$
DECLARE
    phase24_claim_keys text[] := ARRAY[
        'CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS',
        'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS',
        'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA',
        'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD'
    ];
BEGIN
    -- 1) Baseline regression spot-checks (Phase 19-23 prerequisites present).
    IF (SELECT count(*) FROM claim WHERE claim_key = 'CLAIM_UZZAH_SUBJECT_DEATH_2SAM6') <> 1 THEN
        RAISE EXCEPTION 'phase24: missing accepted Phase 19 baseline claim';
    END IF;
    IF (SELECT count(*) FROM claim WHERE claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED' AND claim_type_code = 'DERIVED_CLAIM') <> 1 THEN
        RAISE EXCEPTION 'phase24: missing accepted derived-claim baseline used by Phase 23';
    END IF;
    IF (SELECT count(*) FROM predicate WHERE predicate_code = 'containsContent') <> 1 THEN
        RAISE EXCEPTION 'phase24: required existing containsContent predicate missing';
    END IF;

    -- 2) Source, dataset, source_record, citation integrity for new bounded locators.
    IF (SELECT count(*) FROM source WHERE source_key IN ('1KI_MT', 'HEB_GNT')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected exactly two new sources';
    END IF;
    IF (SELECT count(*) FROM dataset WHERE dataset_key IN ('1KI_MT_REF', 'HEB_GNT_REF')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected exactly two new datasets';
    END IF;
    IF (SELECT count(*) FROM source_record WHERE source_record_key IN ('MT_1KI_8_9', 'GNT_HEB_9_4')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected exactly two new source records';
    END IF;
    IF (SELECT count(*) FROM citation WHERE citation_key IN ('CITE_MT_1KI_8_9', 'CITE_GNT_HEB_9_4')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected exactly two new citations';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
        WHERE sr.source_record_key IN ('MT_1KI_8_9', 'GNT_HEB_9_4')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR ci.quoted_text IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase24: no raw source text/hash/quotation may be stored for this slice';
    END IF;

    -- 3) New entities and direct source-backed claims are present and bounded.
    IF (SELECT count(*) FROM entity WHERE entity_key IN ('golden_jar_manna', 'aarons_rod_budded')) <> 2 THEN
        RAISE EXCEPTION 'phase24: expected two new canonical object entities';
    END IF;
    IF (SELECT count(*) FROM claim WHERE claim_key = ANY(phase24_claim_keys) AND claim_type_code = 'DIRECT_SOURCE_CLAIM') <> 4 THEN
        RAISE EXCEPTION 'phase24: expected exactly four direct source claims in the Phase 24 slice';
    END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
          AND c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase24: phase24 claim types must remain DIRECT_SOURCE_CLAIM';
    END IF;

    -- 4) Provenance chain completeness Claim -> Evidence -> Citation -> SourceRecord -> Dataset -> Source.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key = ANY(phase24_claim_keys)
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
                AND s.source_key IN ('1KI_MT', 'HEB_GNT')
          )
    ) THEN
        RAISE EXCEPTION 'phase24: each phase24 claim requires complete source-backed provenance';
    END IF;

    -- 5) Source differences preserved without automatic contradiction classification.
    IF (
        SELECT count(*)
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity se ON se.entity_id = p.subject_entity_id
        JOIN entity oe ON oe.entity_id = p.object_entity_id
        WHERE se.entity_key = 'ark_of_covenant'
          AND p.predicate = 'containsContent'
          AND oe.entity_key = 'tablets_of_testimony'
          AND c.claim_key IN ('CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY', 'CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS', 'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS')
    ) <> 3 THEN
        RAISE EXCEPTION 'phase24: expected preserved multi-source tablet attestations';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key = ANY(phase24_claim_keys)
          AND c2.claim_key = ANY(phase24_claim_keys)
          AND cr.relation_type_code IN ('CONTRADICTS', 'SUPERSEDES')
    ) THEN
        RAISE EXCEPTION 'phase24: source differences must not be auto-classified as contradiction/supersession';
    END IF;

    -- 6) Existing structural derivation baseline remains available for eligibility demonstration.
    IF NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN derivation d ON d.derivation_id = c.derivation_id
        JOIN derivation_input di ON di.derivation_id = d.derivation_id
        WHERE c.claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED'
          AND c.claim_type_code = 'DERIVED_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase24: missing derivation baseline used by CHECK_DERIVATION_ELIGIBILITY demonstration';
    END IF;
END $$;
