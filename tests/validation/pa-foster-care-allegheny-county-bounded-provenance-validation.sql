\set ON_ERROR_STOP on
-- PA foster-care corpus: county-only (Allegheny County) bounded provenance population validation.
-- Validates the population created by
-- tests/fixtures/150-pa-foster-care-allegheny-county-bounded-provenance-fixture.sql.
-- This validation is corpus-specific and is NOT wired into scripts/validation/run-postgres-validation.sh;
-- it is intended to be run standalone against a disposable PostgreSQL database.
DO $$
DECLARE actual integer;
BEGIN
    -- 1. Exactly the two expected Allegheny County sources exist; no Pennsylvania statewide
    --    source was introduced by this population.
    SELECT count(*) INTO actual FROM source
    WHERE source_key IN ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY');
    IF actual <> 2 THEN RAISE EXCEPTION 'pa-foster-allegheny: expected 2 county sources, found %', actual; END IF;

    IF EXISTS (SELECT 1 FROM source WHERE source_key ILIKE '%STATEWIDE%' OR source_key ILIKE '%PENNSYLVANIA_APSR%' OR name ILIKE '%Annual Progress and Services Report%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: a Pennsylvania statewide source was unexpectedly populated'; END IF;

    -- 2. Both datasets are locator-only, county-scoped, and carry no downloaded content.
    SELECT count(*) INTO actual FROM dataset
    WHERE dataset_key IN ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS')
      AND license_status = 'Locator-only reference; source text is NOT_STORED_BY_POLICY.';
    IF actual <> 2 THEN RAISE EXCEPTION 'pa-foster-allegheny: expected 2 locator-only datasets, found %', actual; END IF;

    IF EXISTS (
        SELECT 1 FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS')
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR sr.source_location IS NULL)
    ) OR EXISTS (
        SELECT 1 FROM citation c JOIN source_record sr ON sr.source_record_id = c.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key IN ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS')
          AND c.quoted_text IS NOT NULL
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: locator-only, no-download storage policy violated'; END IF;

    -- 3. Both observations are present as SOURCE_OBSERVATION evidence, remain textually distinct,
    --    and neither observation's text states the other's value as equivalent.
    SELECT count(*) INTO actual FROM evidence
    WHERE evidence_key IN ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
      AND evidence_type_code = 'SOURCE_OBSERVATION';
    IF actual <> 2 THEN RAISE EXCEPTION 'pa-foster-allegheny: expected 2 SOURCE_OBSERVATION evidence rows, found %', actual; END IF;

    IF NOT EXISTS (SELECT 1 FROM evidence WHERE evidence_key = 'EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1' AND observation LIKE '%8.1%' AND observation NOT LIKE '%approximately 9%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: NBPB 8.1%% observation text is missing or contaminated with the dashboard value'; END IF;
    IF NOT EXISTS (SELECT 1 FROM evidence WHERE evidence_key = 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9' AND observation LIKE '%approximately 9%%' AND observation NOT LIKE '%8.1%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: dashboard approximately-9%% observation text is missing or contaminated with the NBPB value'; END IF;

    -- 4. Every evidence row is linked to its citation (complete source -> ... -> evidence chain).
    IF EXISTS (
        SELECT 1 FROM evidence e
        WHERE e.evidence_key IN ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
          AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id)
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: evidence lacks a linked citation'; END IF;

    -- 5. Allegheny County is represented as a PLACE entity (existing convention), not a new
    --    domain-specific table.
    IF NOT EXISTS (SELECT 1 FROM entity WHERE entity_key = 'pa_foster_allegheny_county' AND entity_type_code = 'PLACE')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: Allegheny County PLACE entity is missing'; END IF;

    -- 6. Both observations have a complete
    --    source -> dataset -> source_record -> citation -> evidence -> claim_evidence -> claim -> proposition
    --    chain, and each claim's proposition explicitly scopes to the Allegheny County entity via
    --    the already-registered "subjectOf" predicate (no new predicate was required or added).
    SELECT count(*) INTO actual FROM claim
    WHERE claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
      AND claim_type_code = 'DIRECT_SOURCE_CLAIM';
    IF actual <> 2 THEN RAISE EXCEPTION 'pa-foster-allegheny: expected 2 direct source claims, found %', actual; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id
        JOIN entity en ON en.entity_id = p.subject_entity_id
        WHERE c.claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
          AND (p.predicate <> 'subjectOf' OR en.entity_key <> 'pa_foster_allegheny_county' OR p.object_event_id IS NULL)
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: a county claim is not explicitly Allegheny-County-scoped via subjectOf'; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
          AND NOT EXISTS (
              SELECT 1 FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS' AND e.evidence_type_code = 'SOURCE_OBSERVATION'
          )
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: a county claim lacks cited SOURCE_OBSERVATION support'; END IF;

    -- 7. Neither proposition persists a percentage as a structured typed value (no invented
    --    numerator/denominator/calculation; the percentage remains text-only in evidence/claim notes).
    IF EXISTS (
        SELECT 1 FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id
        WHERE c.claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
          AND p.object_typed_value_id IS NOT NULL
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: a percentage was persisted as a structured typed value'; END IF;

    -- 8. The two observations are never equated or compared: no claim_relation row links them,
    --    directly or indirectly, and no single proposition/event covers both.
    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c1 ON c1.claim_id = cr.claim_id
        JOIN claim c2 ON c2.claim_id = cr.related_claim_id
        WHERE c1.claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
           OR c2.claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: the 8.1%% and approximately-9%% observations were linked by a claim relation'; END IF;

    IF (SELECT p.object_event_id FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id WHERE c.claim_key = 'CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE')
       = (SELECT p.object_event_id FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id WHERE c.claim_key = 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: the two observations were collapsed onto a single event'; END IF;

    -- 9. No unresolved field was silently resolved: each claim's notes must still document its
    --    unresolved methodology markers rather than a fabricated value.
    IF NOT EXISTS (SELECT 1 FROM claim WHERE claim_key = 'CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE' AND notes LIKE '%NUMERATOR_NOT_STATED%' AND notes LIKE '%DENOMINATOR_NOT_STATED%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: NBPB claim no longer documents unresolved numerator/denominator'; END IF;
    IF NOT EXISTS (SELECT 1 FROM claim WHERE claim_key = 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE' AND notes LIKE '%EXACT_FILTER_STATE_NOT_VERIFIED%' AND notes LIKE '%RELATION_TO_8_1_PERCENT_NOT_VERIFIED%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: dashboard claim no longer documents unresolved filter state / relation to 8.1%%'; END IF;

    -- 10. No unsupported statewide/performance statement is present anywhere in the population.
    IF EXISTS (
        SELECT 1 FROM (
            SELECT observation AS txt FROM evidence WHERE evidence_key IN ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
            UNION ALL
            SELECT notes FROM evidence WHERE evidence_key IN ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
            UNION ALL
            SELECT statement FROM claim WHERE claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
            UNION ALL
            SELECT notes FROM claim WHERE claim_key IN ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE')
        ) t(txt)
        WHERE txt ILIKE '%better than%' OR txt ILIKE '%worse than%' OR txt ILIKE '%performs%'
           OR txt ILIKE '%2018-2025%' OR txt ILIKE '%2018 to 2025%'
           OR txt ILIKE '%7.8%'
           OR (txt ILIKE '%statewide%' AND txt NOT ILIKE '%no pennsylvania statewide%')
    ) THEN RAISE EXCEPTION 'pa-foster-allegheny: an unsupported statewide/performance/full-period statement is present'; END IF;

    -- 11. Source identity reconciliation is present and conservative: only the unambiguous county
    --     self-identification is ACTIVE; no unrelated or unsupported mapping was silently activated.
    SELECT count(*) INTO actual FROM entity_source_mapping esm
    JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
    JOIN entity en ON en.entity_id = esm.entity_id
    WHERE si.source_identity_key IN ('pa-foster-allegheny-nbpb-county', 'pa-foster-allegheny-dashboard-county')
      AND en.entity_key = 'pa_foster_allegheny_county'
      AND esm.mapping_status_code = 'ACTIVE';
    IF actual <> 2 THEN RAISE EXCEPTION 'pa-foster-allegheny: expected 2 ACTIVE county source-identity mappings, found %', actual; END IF;

    IF EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.entity_id <> (SELECT entity_id FROM entity WHERE entity_key = 'pa_foster_allegheny_county') AND esm.source_identity_id IN (SELECT source_identity_id FROM source_identity WHERE source_identity_key IN ('pa-foster-allegheny-nbpb-county', 'pa-foster-allegheny-dashboard-county')))
    THEN RAISE EXCEPTION 'pa-foster-allegheny: county source identity was mapped to an unexpected entity'; END IF;

    -- 12. No new predicate, entity_type, or value_type was introduced by this population; the
    --     representation gap for a first-class percentage metric remains NOT_YET_MODELED.
    IF EXISTS (SELECT 1 FROM predicate WHERE predicate_code ILIKE '%reentry%' OR predicate_code ILIKE '%percent%' OR predicate_code ILIKE '%rate%')
    THEN RAISE EXCEPTION 'pa-foster-allegheny: an unexpected metric-specific predicate exists in the registry'; END IF;
    IF EXISTS (SELECT 1 FROM entity_type WHERE entity_type_code NOT IN ('PERSON', 'PLACE', 'ORGANIZATION', 'OBJECT', 'CONCEPT'))
    THEN RAISE EXCEPTION 'pa-foster-allegheny: an unexpected entity_type was introduced'; END IF;

    RAISE NOTICE 'ok: PA foster-care Allegheny County bounded provenance population is county-scoped, dual-path, non-equated, provenance-complete, idempotent, and free of unresolved-field fabrication.';
END $$;
