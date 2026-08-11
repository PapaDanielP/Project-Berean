\set ON_ERROR_STOP on

-- Stage A validation: only source scope, provenance, storage policy, and classification
-- boundaries are checked here.  Stage B questions deliberately appear in a separate file.
DO $$
DECLARE
    source_count integer;
    inventory_count integer;
BEGIN
    SELECT count(*) INTO source_count
    FROM source
    WHERE source_key IN (
        'ECLIPSE_1919_REPORT', 'OBSERVATORY_1919_ECLIPSE',
        'EARMAN_GLYMOUR_1980', 'KENNEFICK_2007'
    );
    IF source_count <> 4 THEN
        RAISE EXCEPTION 'phase33 population: expected four independently registered sources, found %', source_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE s.source_key IN (
            'ECLIPSE_1919_REPORT', 'OBSERVATORY_1919_ECLIPSE',
            'EARMAN_GLYMOUR_1980', 'KENNEFICK_2007'
        )
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) THEN
        RAISE EXCEPTION 'phase33 population: locator-only source storage policy violated';
    END IF;

    SELECT count(*) INTO inventory_count
    FROM claim
    WHERE claim_key LIKE 'CLAIM_P32\_%' ESCAPE '\'
      AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF inventory_count <> 7 THEN
        RAISE EXCEPTION 'phase33 population: expected seven source-backed direct claims, found %', inventory_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM evidence e
        JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
        WHERE e.evidence_key IN (
            'EV_EARMAN_GLYMOUR_1980_INTERPRETATION_P32',
            'EV_KENNEFICK_2007_INTERPRETATION_P32',
            'EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32'
        )
    ) THEN
        RAISE EXCEPTION 'phase33 population: analytical or unresolved material was promoted to a claim';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
        LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        LEFT JOIN citation ci ON ci.citation_id = ec.citation_id
        LEFT JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
        LEFT JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key LIKE 'CLAIM_P32\_%' ESCAPE '\'
        GROUP BY c.claim_id
        HAVING count(s.source_id) = 0
    ) THEN
        RAISE EXCEPTION 'phase33 population: direct claim lacks complete provenance traversal';
    END IF;

    RAISE NOTICE 'ok: Phase 33 Stage A population is source-scoped, locator-only, and preserves scholarship/unresolved material outside claims';
END $$;
