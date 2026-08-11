\set ON_ERROR_STOP on

-- Phase 28 verifies the invariants the automated Tier-1 ingestion pipeline must hold after it has
-- run against whatever state the validation runner has already loaded. The assertions are
-- state-agnostic: when every manifest candidate is already represented, ingestion legitimately
-- creates no new CLAIM_P28_% row, and that is idempotency rather than failure.
DO $$
BEGIN
    -- Every claim written by ingestion carries the full provenance path
    -- Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE 'CLAIM_P28_%'
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
        RAISE EXCEPTION 'phase28: a Phase 28 claim lacks a complete provenance chain';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key LIKE 'CLAIM_P28_%' AND claim_type_code <> 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase28: ingestion may only write direct source claims';
    END IF;

    IF EXISTS (SELECT 1 FROM claim WHERE claim_key LIKE 'CLAIM_P28_%' AND derivation_id IS NOT NULL) THEN
        RAISE EXCEPTION 'phase28: ingestion must not write derived claims';
    END IF;

    -- Candidates that ingestion deliberately did not import must stay outside the graph.
    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key IN (
            'CLAIM_P28_GEN_5_23_ENOCH_AGE_AT_DEATH_365',
            'CLAIM_P28_GEN_5_24_ENOCH_ASCENSION',
            'CLAIM_P28_GEN_4_17_ENOCH_SON_OF_CAIN',
            'CLAIM_P28_EXT_ENOCH_AUTHORED_1_ENOCH',
            'CLAIM_P28_JOSEPH_SALE_CAUSATION',
            'CLAIM_P28_MODERN_LOCATIONS',
            'CLAIM_P28_GENESIS_CHRONOLOGY',
            'CLAIM_P28_GEN_1_2_CREATION_HARMONIZATION',
            'CLAIM_P28_EXT_THEOGRAPHIC_PERSON_IDS'
        )
    ) THEN
        RAISE EXCEPTION 'phase28: a candidate held back for review or exclusion entered the graph';
    END IF;

    -- Locator-only source storage policy for anything ingestion created.
    IF EXISTS (
        SELECT 1 FROM source_record
        WHERE source_record_key LIKE 'MT_GEN_%'
          AND (raw_content IS NOT NULL OR content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase28: locator-only source storage policy violated';
    END IF;
    IF EXISTS (
        SELECT 1 FROM citation WHERE citation_key LIKE 'CITE_MT_GEN_%' AND quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase28: locator-only citation storage policy violated';
    END IF;

    -- Source identity mappings written by ingestion are ACTIVE, justified, and evidence-backed.
    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key LIKE 'mt-p28-%'
          AND (esm.mapping_status_code <> 'ACTIVE'
               OR esm.justification IS NULL
               OR esm.supporting_evidence_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'phase28: a Phase 28 source identity mapping is incomplete';
    END IF;

    -- Ingestion never reconciles a canonical entity to two active identities of the same source.
    IF EXISTS (
        SELECT esm.entity_id
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE esm.mapping_status_code = 'ACTIVE'
        GROUP BY esm.entity_id, si.source_id
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'phase28: duplicate active source identity mapping for one entity and source';
    END IF;

    -- Idempotency: an ingested claim never duplicates an existing assertion of the same
    -- proposition from the same evidence.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
        JOIN claim other ON other.claim_id <> c.claim_id
             AND other.proposition_id = c.proposition_id
             AND other.claim_type_code = 'DIRECT_SOURCE_CLAIM'
        JOIN claim_evidence other_ce ON other_ce.claim_id = other.claim_id
             AND other_ce.evidence_id = ce.evidence_id
             AND other_ce.relation_type_code = 'SUPPORTS'
        WHERE c.claim_key LIKE 'CLAIM_P28_%' AND c.claim_type_code = 'DIRECT_SOURCE_CLAIM'
    ) THEN
        RAISE EXCEPTION 'phase28: an ingested claim duplicates an existing source-backed assertion';
    END IF;

    RAISE NOTICE 'ok: Phase 28 automated Tier-1 ingestion passes provenance, boundary, and idempotency validation';
END $$;
