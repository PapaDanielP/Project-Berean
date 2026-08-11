\set ON_ERROR_STOP on
-- Phase 37 Stage A validates only population, provenance, and representation boundaries.
DO $$
DECLARE actual integer;
BEGIN
    SELECT count(*) INTO actual FROM source WHERE source_key IN ('WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893', 'CHICAGO_TRIBUNE_1893_EXPOSITION_OPENING', 'BADGER_1979_GREAT_AMERICAN_FAIR', 'RYDELL_1984_ALL_THE_WORLDS_A_FAIR');
    IF actual <> 4 THEN RAISE EXCEPTION 'phase37: expected 4 sources, found %', actual; END IF;

    SELECT count(*) INTO actual FROM dataset WHERE dataset_key LIKE '%\_P37' ESCAPE '\' AND license_status = 'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.';
    IF actual <> 4 THEN RAISE EXCEPTION 'phase37: expected 4 locator-only datasets, found %', actual; END IF;

    IF EXISTS (SELECT 1 FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key LIKE '%\_P37' ESCAPE '\' AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR sr.source_location IS NULL))
       OR EXISTS (SELECT 1 FROM citation c JOIN source_record sr ON sr.source_record_id = c.source_record_id JOIN dataset d ON d.dataset_id = sr.dataset_id WHERE d.dataset_key LIKE '%\_P37' ESCAPE '\' AND c.quoted_text IS NOT NULL)
    THEN RAISE EXCEPTION 'phase37: locator-only storage policy violated'; END IF;

    -- Every claim's predicate must be a registered predicate (no invented vocabulary).
    IF EXISTS (
        SELECT 1 FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id
        WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\'
          AND NOT EXISTS (SELECT 1 FROM predicate pr WHERE pr.predicate_code = p.predicate)
    ) THEN RAISE EXCEPTION 'phase37: claim uses an unregistered predicate'; END IF;

    SELECT count(*) INTO actual FROM claim WHERE claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\' AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF actual <> 9 THEN RAISE EXCEPTION 'phase37: expected 9 direct claims, found %', actual; END IF;

    -- Every direct claim has complete provenance: Claim -> ClaimEvidence -> Evidence -> EvidenceCitation
    -- -> Citation -> SourceRecord -> Dataset -> Source.
    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\'
          AND NOT EXISTS (
              SELECT 1 FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN RAISE EXCEPTION 'phase37: direct claim lacks complete cited supporting provenance'; END IF;

    -- Direct claims may only be backed by SOURCE_OBSERVATION evidence; analytical observations
    -- must never be promoted to a direct claim.
    IF EXISTS (SELECT 1 FROM claim c JOIN claim_evidence ce ON ce.claim_id = c.claim_id JOIN evidence e ON e.evidence_id = ce.evidence_id WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\' AND e.evidence_type_code <> 'SOURCE_OBSERVATION')
    THEN RAISE EXCEPTION 'phase37: analytical observation promoted to claim'; END IF;

    SELECT count(*) INTO actual FROM evidence e WHERE e.evidence_key LIKE 'EV\_P37\_%' ESCAPE '\' AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION' AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id);
    IF actual <> 2 THEN RAISE EXCEPTION 'phase37: expected 2 unpromoted scholarly observations, found %', actual; END IF;

    -- No source difference or scholarly disagreement is persisted as a claim_relation.
    IF EXISTS (SELECT 1 FROM claim_relation cr JOIN claim c ON c.claim_id = cr.claim_id WHERE c.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\')
    THEN RAISE EXCEPTION 'phase37: source difference was persisted as a claim relation'; END IF;

    -- The Mrs. Potter Palmer honorific-only identity must remain PROPOSED, not silently reconciled.
    IF EXISTS (SELECT 1 FROM entity_source_mapping esm JOIN source_identity si ON si.source_identity_id = esm.source_identity_id WHERE si.source_identity_key = 'phase37-catalogue-mrs-potter-palmer' AND esm.mapping_status_code = 'ACTIVE')
    THEN RAISE EXCEPTION 'phase37: ambiguous source identity was silently reconciled'; END IF;
    SELECT count(*) INTO actual FROM entity_source_mapping esm JOIN source_identity si ON si.source_identity_id = esm.source_identity_id WHERE si.source_identity_key = 'phase37-catalogue-mrs-potter-palmer' AND esm.mapping_status_code = 'PROPOSED';
    IF actual <> 1 THEN RAISE EXCEPTION 'phase37: expected the honorific identity to carry exactly one PROPOSED mapping, found %', actual; END IF;

    -- Negative checks: no unjustified/absent predicate semantics were introduced by this phase.
    IF EXISTS (SELECT 1 FROM predicate WHERE predicate_code IN ('preferredOver', 'strongerThan', 'confirmsTheory', 'supportsTheory', 'refutesTheory', 'sameAs'))
    THEN RAISE EXCEPTION 'phase37: an unsupported predicate was registered'; END IF;
    IF EXISTS (
            SELECT 1 FROM claim_relation cr
            JOIN claim a ON a.claim_id = cr.claim_id
            JOIN claim b ON b.claim_id = cr.related_claim_id
            WHERE (a.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\' OR b.claim_key LIKE 'CLAIM\_P37\_%' ESCAPE '\')
              AND cr.relation_type_code = 'CONTRADICTS'
       )
    THEN RAISE EXCEPTION 'phase37: a Phase 37 claim participates in a persisted contradiction'; END IF;

    -- No general calendar-date semantics were invented for this phase: no typed-value proposition
    -- attaches a DATE value_type to a Phase 37 event.
    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN event ev ON ev.event_id = p.subject_event_id
        JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
        WHERE ev.event_key LIKE 'phase37\_%' ESCAPE '\' AND tv.value_type_code = 'DATE'
    ) THEN RAISE EXCEPTION 'phase37: a general calendar-date proposition was invented'; END IF;

    RAISE NOTICE 'ok: Phase 37 population is source-scoped, provenance-backed, idempotent, and preserves scholarship and identity uncertainty.';
END $$;
