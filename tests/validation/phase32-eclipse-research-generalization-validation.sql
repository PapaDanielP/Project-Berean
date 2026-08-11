\set ON_ERROR_STOP on

-- Phase 32 validates cross-domain scholarly research generalization without schema changes.
DO $$
DECLARE
    p32_claim_count integer;
    p32_primary_evidence_count integer;
    p32_scholarly_evidence_count integer;
BEGIN
    IF (SELECT count(*) FROM source WHERE source_key IN (
            'ECLIPSE_1919_REPORT',
            'OBSERVATORY_1919_ECLIPSE'
        )) <> 2 THEN
        RAISE EXCEPTION 'phase32: expected two primary or near-primary eclipse source traditions';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM source_record sr
        WHERE sr.source_record_key IN (
            'ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
            'ECLIPSE_1919_SOBRAL_OBSERVATIONS',
            'ECLIPSE_1919_RESULTS_DISCUSSION',
            'OBSERVATORY_1919_JOINT_MEETING',
            'EARMAN_GLYMOUR_1980_49_85',
            'KENNEFICK_2007_EINSTEIN_STUDIES_12'
        )
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL)
    ) OR EXISTS (
        SELECT 1
        FROM citation
        WHERE citation_key IN (
            'CITE_ECLIPSE_1919_PRINCIPE_OBSERVATIONS',
            'CITE_ECLIPSE_1919_SOBRAL_OBSERVATIONS',
            'CITE_ECLIPSE_1919_RESULTS_DISCUSSION',
            'CITE_OBSERVATORY_1919_JOINT_MEETING',
            'CITE_EARMAN_GLYMOUR_1980_49_85',
            'CITE_KENNEFICK_2007_EINSTEIN_STUDIES_12'
        )
          AND quoted_text IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'phase32: locator-only storage policy violated';
    END IF;

    SELECT count(*)
    INTO p32_primary_evidence_count
    FROM evidence
    WHERE evidence_key IN (
        'EV_ECLIPSE_1919_PRINCIPE_OBS_P32',
        'EV_ECLIPSE_1919_SOBRAL_OBS_P32',
        'EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32',
        'EV_OBSERVATORY_1919_ANNOUNCEMENT_P32'
    )
      AND evidence_type_code = 'SOURCE_OBSERVATION';
    IF p32_primary_evidence_count <> 4 THEN
        RAISE EXCEPTION 'phase32: expected four source observations, found %', p32_primary_evidence_count;
    END IF;

    SELECT count(*)
    INTO p32_scholarly_evidence_count
    FROM evidence
    WHERE evidence_key IN (
        'EV_EARMAN_GLYMOUR_1980_INTERPRETATION_P32',
        'EV_KENNEFICK_2007_INTERPRETATION_P32'
    )
      AND evidence_type_code = 'ANALYTICAL_OBSERVATION';
    IF p32_scholarly_evidence_count <> 2 THEN
        RAISE EXCEPTION 'phase32: expected two competing scholarly observations, found %', p32_scholarly_evidence_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM evidence e
        LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        WHERE e.evidence_key LIKE 'EV\_%\_P32' ESCAPE '\'
          AND ec.evidence_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase32: a Phase 32 evidence row lacks citation linkage';
    END IF;

    SELECT count(*)
    INTO p32_claim_count
    FROM claim
    WHERE claim_key IN (
        'CLAIM_P32_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE',
        'CLAIM_P32_SOBRAL_OBSERVATION_OCCURS_AT_SOBRAL',
        'CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION',
        'CLAIM_P32_DAVIDSON_PARTICIPATES_IN_SOBRAL_OBSERVATION',
        'CLAIM_P32_CROMMELIN_PARTICIPATES_IN_SOBRAL_OBSERVATION',
        'CLAIM_P32_PRINCIPE_OBSERVATION_PRECEDES_ANNOUNCEMENT',
        'CLAIM_P32_SOBRAL_OBSERVATION_PRECEDES_ANNOUNCEMENT'
    )
      AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF p32_claim_count <> 7 THEN
        RAISE EXCEPTION 'phase32: expected seven direct source claims, found %', p32_claim_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN event ev ON ev.event_id = p.subject_event_id
        JOIN entity place ON place.entity_id = p.object_entity_id
        WHERE c.claim_key = 'CLAIM_P32_PRINCIPE_OBSERVATION_OCCURS_AT_PRINCIPE'
          AND ev.event_key = 'phase32_principe_eclipse_observation_1919'
          AND p.predicate = 'occursAt'
          AND place.entity_key = 'phase32_principe'
    ) OR NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity person ON person.entity_id = p.subject_entity_id
        JOIN event ev ON ev.event_id = p.object_event_id
        WHERE c.claim_key = 'CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION'
          AND person.entity_key = 'phase32_arthur_eddington'
          AND p.predicate = 'participatesIn'
          AND ev.event_key = 'phase32_principe_eclipse_observation_1919'
    ) OR NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN event observation ON observation.event_id = p.subject_event_id
        JOIN event announcement ON announcement.event_id = p.object_event_id
        WHERE c.claim_key = 'CLAIM_P32_PRINCIPE_OBSERVATION_PRECEDES_ANNOUNCEMENT'
          AND observation.event_key = 'phase32_principe_eclipse_observation_1919'
          AND p.predicate = 'precedes'
          AND announcement.event_key = 'phase32_joint_eclipse_announcement_1919'
    ) THEN
        RAISE EXCEPTION 'phase32: expected event, participation, or chronology propositions are missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
        JOIN citation ci ON ci.citation_id = ec.citation_id
        JOIN source_record sr ON sr.source_record_id = ci.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        JOIN source s ON s.source_id = d.source_id
        WHERE c.claim_key = 'CLAIM_P32_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION'
          AND ce.relation_type_code = 'SUPPORTS'
          AND e.evidence_key = 'EV_ECLIPSE_1919_PRINCIPE_OBS_P32'
          AND ci.citation_key = 'CITE_ECLIPSE_1919_PRINCIPE_OBSERVATIONS'
          AND s.source_key = 'ECLIPSE_1919_REPORT'
    ) THEN
        RAISE EXCEPTION 'phase32: direct claim provenance chain is incomplete';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim c
        JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE e.evidence_key IN (
            'EV_ECLIPSE_1919_SOBRAL_ASTROGRAPHIC_AMBIGUITY_P32',
            'EV_EARMAN_GLYMOUR_1980_INTERPRETATION_P32',
            'EV_KENNEFICK_2007_INTERPRETATION_P32'
        )
    ) THEN
        RAISE EXCEPTION 'phase32: ambiguous data handling or scholarly observations were promoted to claims';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM claim
        WHERE claim_key IN (
            'CLAIM_P32_ECLIPSE_CONFIRMS_GENERAL_RELATIVITY',
            'CLAIM_P32_EINSTEIN_SUPERSEDES_NEWTON',
            'CLAIM_P32_SOBRAL_ASTROGRAPHIC_DATA_INVALID',
            'CLAIM_P32_EXPEDITION_THEORY_BIAS',
            'CLAIM_P32_EARMAN_GLYMOUR_CORRECT',
            'CLAIM_P32_KENNEFICK_CORRECT'
        )
    ) THEN
        RAISE EXCEPTION 'phase32: interpretive, theory-confirmation, or scholarly ranking claims were persisted';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition p
        JOIN entity s ON s.entity_id = p.subject_entity_id
        LEFT JOIN entity o ON o.entity_id = p.object_entity_id
        WHERE s.entity_key IN (
            'phase32_general_relativity_deflection',
            'phase32_newtonian_deflection'
        )
          OR o.entity_key IN (
            'phase32_general_relativity_deflection',
            'phase32_newtonian_deflection'
        )
    ) THEN
        RAISE EXCEPTION 'phase32: theory comparison was promoted into a registered proposition';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM proposition
        WHERE predicate IN (
            'confirmsTheory',
            'supportsTheory',
            'refutesTheory',
            'preferredOver',
            'strongerThan',
            'sameAs',
            'excludedBecause',
            'biasedBy'
        )
    ) THEN
        RAISE EXCEPTION 'phase32: an unapproved interpretive predicate was introduced';
    END IF;

    IF (SELECT count(*) FROM entity_source_mapping esm
        JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
        WHERE si.source_identity_key IN (
            'phase32-report-eddington',
            'phase32-report-davidson',
            'phase32-report-crommelin',
            'phase32-report-principe-station',
            'phase32-report-sobral-station'
        )
          AND esm.mapping_status_code = 'ACTIVE'
          AND esm.supporting_evidence_id IS NOT NULL
          AND COALESCE(esm.justification, '') <> '') <> 5 THEN
        RAISE EXCEPTION 'phase32: expected active source-identity mappings with evidence and justification';
    END IF;

    RAISE NOTICE 'ok: Phase 32 generalizes to a non-Genesis 1919 eclipse research problem without schema or registry changes';
    RAISE NOTICE 'ok: SOURCE-BACKED IS NOT TRUE; DIRECT SOURCE CLAIM IS NOT SCHOLARLY INTERPRETATION; DIFFERENCE IS NOT CONTRADICTION; UNMODELED IS NOT FALSE';
END $$;

-- Deterministic synthesis output (stable order, no interpretation persistence).
SELECT *
FROM (
    VALUES
      ('Supported by represented source evidence', 'Principe and Sobral are represented as distinct 1919 eclipse observation events with source-backed participants and locations.', 'PASS'),
      ('Supported by represented source evidence', 'The represented observations precede the contemporary joint eclipse announcement.', 'PASS'),
      ('Ambiguity preserved', 'The Sobral astrographic-plate ambiguity is represented as source evidence only, not as a verdict about validity, bias, or contradiction.', 'PASS WITH INTENTIONAL LIMITATION'),
      ('Interpretive possibilities', 'Earman/Glymour and Kennefick reassess data handling and later interpretation as competing scholarly observations without ranking.', 'PASS'),
      ('Not established by represented corpus', 'The fixture does not assert that the expedition proved, disproved, confirmed, or refuted any theory.', 'PASS WITH INTENTIONAL LIMITATION'),
      ('Not established by represented corpus', 'No predicate is added for theory confirmation, data weighting, motive, or scholarly consensus.', 'PASS WITH INTENTIONAL LIMITATION')
) AS synthesis(section, assessment, classification)
ORDER BY section, assessment;
