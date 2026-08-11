\set ON_ERROR_STOP on
-- Phase 36 Stage A validates only population, provenance, and representation boundaries.
DO $$
DECLARE actual integer;
BEGIN
    SELECT count(*) INTO actual FROM source WHERE source_key IN ('SENECA_FALLS_PROCEEDINGS_1848', 'NORTH_STAR_1848_SENECA_FALLS', 'WELLMAN_2004_SENECA_FALLS', 'TETRAULT_2014_SENECA_FALLS');
    IF actual <> 4 THEN RAISE EXCEPTION 'phase36: expected 4 sources, found %', actual; END IF;
    SELECT count(*) INTO actual FROM dataset WHERE dataset_key LIKE '%\_P36' ESCAPE '\' AND license_status = 'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.';
    IF actual <> 4 THEN RAISE EXCEPTION 'phase36: expected 4 locator-only datasets, found %', actual; END IF;
    IF EXISTS (SELECT 1 FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key LIKE '%\_P36' ESCAPE '\' AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR sr.source_location IS NULL))
       OR EXISTS (SELECT 1 FROM citation c JOIN source_record sr ON sr.source_record_id = c.source_record_id JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key LIKE '%\_P36' ESCAPE '\' AND c.quoted_text IS NOT NULL)
    THEN RAISE EXCEPTION 'phase36: locator-only storage policy violated'; END IF;
    SELECT count(*) INTO actual FROM claim WHERE claim_key LIKE 'CLAIM\_P36\_%' ESCAPE '\' AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF actual <> 6 THEN RAISE EXCEPTION 'phase36: expected 6 direct claims, found %', actual; END IF;
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'CLAIM\_P36\_%' ESCAPE '\'
          AND NOT EXISTS (
              SELECT 1 FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN RAISE EXCEPTION 'phase36: direct claim lacks cited supporting evidence'; END IF;
    IF EXISTS (SELECT 1 FROM claim c JOIN claim_evidence ce ON ce.claim_id = c.claim_id JOIN evidence e ON e.evidence_id = ce.evidence_id WHERE c.claim_key LIKE 'CLAIM\_P36\_%' ESCAPE '\' AND e.evidence_type_code <> 'SOURCE_OBSERVATION')
    THEN RAISE EXCEPTION 'phase36: analytical observation promoted to claim'; END IF;
    SELECT count(*) INTO actual FROM evidence e WHERE e.evidence_key LIKE 'EV\_P36\_%' ESCAPE '\' AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION' AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id);
    IF actual <> 2 THEN RAISE EXCEPTION 'phase36: expected 2 unpromoted scholarly observations, found %', actual; END IF;
    IF EXISTS (SELECT 1 FROM claim_relation cr JOIN claim c ON c.claim_id = cr.claim_id WHERE c.claim_key LIKE 'CLAIM\_P36\_%' ESCAPE '\')
    THEN RAISE EXCEPTION 'phase36: source difference was persisted as a claim relation'; END IF;
    IF EXISTS (SELECT 1 FROM entity_source_mapping esm JOIN source_identity si ON si.source_identity_id = esm.source_identity_id WHERE si.source_identity_key = 'phase36-proceedings-mrs-mott' AND esm.mapping_status_code = 'ACTIVE')
    THEN RAISE EXCEPTION 'phase36: ambiguous source identity was silently reconciled'; END IF;
    RAISE NOTICE 'ok: Phase 36 population is source-scoped, provenance-backed, idempotent, and preserves scholarship and identity uncertainty.';
END $$;
