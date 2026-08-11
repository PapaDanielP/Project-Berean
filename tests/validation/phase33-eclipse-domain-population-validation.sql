\set ON_ERROR_STOP on

-- Phase 33 Stage A validation.
--
-- This file validates the population pass only: source registration, source-storage policy,
-- corpus inventory, provenance completeness, source-identity discipline, idempotence, and the
-- negative promotion boundaries. It deliberately contains no research question and no expected
-- research answer; Stage B questions live in
-- tests/validation/phase33-eclipse-independent-query-validation.sql and are not known here.
DO $$
DECLARE
    actual integer;
BEGIN
    -- 1. Required minimum sources are independently registered.
    SELECT count(*) INTO actual
    FROM source
    WHERE source_key IN (
        'ECLIPSE_1919_REPORT', 'OBSERVATORY_1919_ECLIPSE',
        'EARMAN_GLYMOUR_1980', 'KENNEFICK_2007'
    );
    IF actual <> 4 THEN
        RAISE EXCEPTION 'phase33 stage A: expected the four required sources, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM dataset
    WHERE dataset_key IN (
        'ECLIPSE_1919_REPORT_P33', 'OBSERVATORY_1919_P33',
        'EARMAN_GLYMOUR_1980_P33', 'KENNEFICK_2007_P33'
    )
      AND license_status = 'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.';
    IF actual <> 4 THEN
        RAISE EXCEPTION 'phase33 stage A: expected four NOT_STORED_BY_POLICY datasets, found %', actual;
    END IF;

    -- 2. Source-storage policy: locators only, never stored or quoted source text.
    IF EXISTS (
        SELECT 1
        FROM source_record sr
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key LIKE '%\_P33' ESCAPE '\'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR sr.source_location IS NULL)
    ) OR EXISTS (
        SELECT 1
        FROM citation ci
        JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key LIKE '%\_P33' ESCAPE '\'
          AND ci.quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: locator-only source-storage policy violated';
    END IF;

    -- 3. Deterministic corpus inventory. These counts must be identical on every replay.
    SELECT count(*) INTO actual
    FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
    WHERE d.dataset_key LIKE '%\_P33' ESCAPE '\';
    IF actual <> 11 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 11 source records, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM citation ci
    JOIN source_record sr ON sr.source_record_id = ci.source_record_id
    JOIN dataset d ON d.dataset_id = sr.dataset_id
    WHERE d.dataset_key LIKE '%\_P33' ESCAPE '\';
    IF actual <> 11 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 11 citations, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM evidence
    WHERE evidence_key LIKE 'EV\_P33\_%' ESCAPE '\' AND evidence_type_code = 'SOURCE_OBSERVATION';
    IF actual <> 9 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 9 source observations, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM evidence
    WHERE evidence_key LIKE 'EV\_P33\_%' ESCAPE '\' AND evidence_type_code = 'ANALYTICAL_OBSERVATION';
    IF actual <> 2 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 2 analytical observations, found %', actual;
    END IF;

    SELECT count(*) INTO actual FROM entity WHERE entity_key LIKE 'phase33\_%' ESCAPE '\';
    IF actual <> 15 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 15 entities, found %', actual;
    END IF;

    SELECT count(*) INTO actual FROM event WHERE event_key LIKE 'phase33\_%' ESCAPE '\';
    IF actual <> 3 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 3 events, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM claim WHERE claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\' AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF actual <> 14 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 14 direct source claims, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM claim WHERE claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\' AND claim_type_code <> 'DIRECT_SOURCE_CLAIM';
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase33 stage A: population created % non-direct claims', actual;
    END IF;

    -- 4. Every Phase 33 evidence row is citation-linked, and every claim is evidence-linked.
    IF EXISTS (
        SELECT 1 FROM evidence e
        LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\' AND ec.evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: a Phase 33 evidence row lacks citation linkage';
    END IF;

    -- 5. Provenance completeness for every Phase 33 claim:
    -- Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source.
    IF EXISTS (
        SELECT 1
        FROM claim c
        WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
          AND NOT EXISTS (
            SELECT 1
            FROM claim_evidence ce
            JOIN evidence e ON e.evidence_id = ce.evidence_id
            JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
            JOIN citation ci ON ci.citation_id = ec.citation_id
            JOIN source_record sr ON sr.source_record_id = ci.source_record_id
            JOIN dataset d ON d.dataset_id = sr.dataset_id
            JOIN source s ON s.source_id = d.source_id
            WHERE ce.claim_id = c.claim_id
              AND ce.relation_type_code = 'SUPPORTS'
              AND e.evidence_type_code = 'SOURCE_OBSERVATION'
          )
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: a Phase 33 claim lacks a complete source-observation provenance chain';
    END IF;

    -- 6. Negative promotion boundaries.
    IF EXISTS (
        SELECT 1
        FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
          AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: an analytical observation was promoted into a claim';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key IN ('EV_P33_SOBRAL_ASTROGRAPHIC_CONCERN', 'EV_P33_RESULTS_DISCUSSION',
                                 'EV_P33_OBSERVATORY_MEETING_DISCUSSION')
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: unresolved or unmodellable source material was promoted into a claim';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
        LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
        WHERE se.entity_key IN ('phase33_predicted_deflection_value', 'phase33_smaller_comparison_deflection_value')
           OR oe.entity_key IN ('phase33_predicted_deflection_value', 'phase33_smaller_comparison_deflection_value')
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: a theory-comparison concept was promoted into a proposition';
    END IF;

    IF EXISTS (
        SELECT 1 FROM proposition
        WHERE predicate IN ('confirmsTheory', 'supportsTheory', 'refutesTheory', 'preferredOver',
                            'strongerThan', 'sameAs', 'excludedBecause', 'biasedBy', 'weightedOver',
                            'occursOnDate')
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: an unregistered interpretive predicate was introduced';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim
        WHERE claim_key IN (
            'CLAIM_P33_ECLIPSE_CONFIRMS_GENERAL_RELATIVITY',
            'CLAIM_P33_SOBRAL_ASTROGRAPHIC_DATA_INVALID',
            'CLAIM_P33_EXPEDITION_THEORY_BIAS',
            'CLAIM_P33_EARMAN_GLYMOUR_CORRECT',
            'CLAIM_P33_KENNEFICK_CORRECT',
            'CLAIM_P33_ASTRONOMER_ROYAL_IS_DYSON'
        )
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: an interpretive, ranking, or identity-resolution claim was persisted';
    END IF;

    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim a ON a.claim_id = cr.claim_id
        JOIN claim b ON b.claim_id = cr.related_claim_id
        WHERE a.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
           OR b.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: a source difference was persisted as an automatic claim relation';
    END IF;

    -- 7. Source-identity discipline: source identities are distinct from canonical entities,
    -- reconciliations carry justification and evidence, and the title-only identity stays unresolved.
    SELECT count(*) INTO actual
    FROM entity_source_mapping esm
    JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
    WHERE si.source_identity_key LIKE 'phase33-%'
      AND esm.mapping_status_code = 'ACTIVE'
      AND esm.supporting_evidence_id IS NOT NULL
      AND COALESCE(esm.justification, '') <> '';
    IF actual <> 8 THEN
        RAISE EXCEPTION 'phase33 stage A: expected 8 justified active source-identity mappings, found %', actual;
    END IF;

    SELECT count(*) INTO actual
    FROM entity_source_mapping esm
    JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
    WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'
      AND esm.mapping_status_code = 'PROPOSED'
      AND esm.confidence IS NULL
      AND COALESCE(esm.justification, '') <> '';
    IF actual <> 1 THEN
        RAISE EXCEPTION 'phase33 stage A: the unresolved title-only identity is not preserved as a single justified PROPOSED mapping';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key = 'phase33-observatory-astronomer-royal'
          AND esm.mapping_status_code = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: an ambiguous source identity was silently reconciled';
    END IF;

    -- 8. Idempotence: no Phase 33 proposition or claim is duplicated by replay.
    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
        GROUP BY p.proposition_id
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'phase33 stage A: replay produced duplicate claims over one proposition';
    END IF;

    SELECT count(*) INTO actual FROM (
        SELECT p.subject_entity_id, p.subject_event_id, p.predicate,
               p.object_entity_id, p.object_event_id, count(*) AS n
        FROM proposition p
        JOIN claim c ON c.proposition_id = p.proposition_id
        WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
        GROUP BY 1, 2, 3, 4, 5
        HAVING count(*) > 1
    ) AS duplicated;
    IF actual <> 0 THEN
        RAISE EXCEPTION 'phase33 stage A: replay produced % duplicated propositions', actual;
    END IF;

    RAISE NOTICE 'ok: Phase 33 Stage A population is source-scoped, locator-only, fully provenanced, idempotent, and free of promoted interpretation';
    RAISE NOTICE 'ok: SOURCE-BACKED IS NOT TRUE; PROPOSED IS NOT FALSE; DIFFERENCE IS NOT CONTRADICTION; UNMODELED IS NOT FALSE';
END $$;

-- Deterministic Stage A inventory. This reports what was populated; it answers no question.
SELECT 'source' AS layer, s.source_key AS key, s.source_type_code AS detail
FROM source s
WHERE s.source_key IN ('ECLIPSE_1919_REPORT', 'OBSERVATORY_1919_ECLIPSE', 'EARMAN_GLYMOUR_1980', 'KENNEFICK_2007')
UNION ALL
SELECT 'evidence', e.evidence_key, e.evidence_type_code
FROM evidence e WHERE e.evidence_key LIKE 'EV\_P33\_%' ESCAPE '\'
UNION ALL
SELECT 'entity', en.entity_key, en.entity_type_code
FROM entity en WHERE en.entity_key LIKE 'phase33\_%' ESCAPE '\'
UNION ALL
SELECT 'event', ev.event_key, ev.event_type_code
FROM event ev WHERE ev.event_key LIKE 'phase33\_%' ESCAPE '\'
UNION ALL
SELECT 'claim', c.claim_key, c.claim_type_code
FROM claim c WHERE c.claim_key LIKE 'CLAIM\_P33\_%' ESCAPE '\'
UNION ALL
SELECT 'source_identity_mapping', si.source_identity_key, esm.mapping_status_code
FROM entity_source_mapping esm
JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
WHERE si.source_identity_key LIKE 'phase33-%'
ORDER BY 1, 2;
