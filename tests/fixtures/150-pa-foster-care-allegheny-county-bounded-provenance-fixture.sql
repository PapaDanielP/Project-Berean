-- PA foster-care corpus: Allegheny County-only bounded provenance population.
--
-- Scope: this fixture populates exactly two Allegheny County, Pennsylvania source-reported
-- re-entry observations from docs/08-corpus/pa-foster-care-placement-reunification/
-- COUNTY_BOUNDED_PROVENANCE_POPULATION.md:
--   (A) the Allegheny County NBPB source-reported 8.1% re-entry-within-12-months observation;
--   (B) the Allegheny County dashboard source-described approximately 9% re-entry trend.
--
-- It deliberately does NOT:
--   - populate a Pennsylvania statewide comparison observation, claim, or ranking;
--   - assert or persist that 8.1% equals approximately 9%;
--   - invent a numerator, denominator, cohort, profile period, filter state, export, snapshot,
--     or calculation for either observation;
--   - add a new predicate, entity_type, value_type, or any other registry row. The percentage
--     metric itself has no registered ENTITY/EVENT -> VALUE predicate that fits without semantic
--     distortion (see COUNTY_BOUNDED_PROVENANCE_POPULATION_REPORT.md, "Architecture findings").
--     That representation gap is classified NOT_YET_MODELED and is intentionally left unclaimed
--     as a structured proposition; the reported percentage text is preserved only in
--     evidence.observation and claim.notes, per the existing generic model's own conventions.
--
-- Each observation keeps an independent source -> dataset -> source_record -> citation ->
-- evidence -> claim_evidence -> claim -> proposition chain. The proposition asserts only that
-- Allegheny County is the explicit subject ("subjectOf", already registered for ENTITY -> EVENT)
-- of its own source-reporting event; it does not encode the percentage value as a structured
-- fact, so no denominator, numerator, or comparison can be silently manufactured downstream.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27', 'Allegheny County Fiscal Year 2026-27 Needs-Based Plan & Budget', 'REFERENCE',
     'Allegheny County DHS/OCYF planning and budget narrative; locator-only reference, page 69, section 2-3f.'),
    ('PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY', 'Allegheny County Child Welfare Out-of-Home Placements Interactive Dashboard', 'DATASET',
     'Allegheny County DHS / Allegheny Analytics public dashboard; locator-only reference to the Re-entry view as described in county material.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, v.dataset_key, v.name, v.edition_label, 'pa-foster-allegheny-1',
       'Locator-only reference; source text is NOT_STORED_BY_POLICY.',
       'Manual county-only bounded provenance population pass (Allegheny County material only).', v.notes
FROM source s
JOIN (VALUES
    ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27', 'PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'Allegheny County NBPB re-entry section reference point', 'FY 2026-27 NBPB, page 69',
     'County re-entry-within-12-months indicator; no numerator, denominator, or full cohort construction is stored.'),
    ('PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS', 'Allegheny County dashboard Re-entry view reference point', 'Re-entry view, as referenced by county material',
     'Approximate trend description; no filter state, export, or snapshot is stored.')
) AS v(source_key, dataset_key, name, edition_label, notes) ON s.source_key = v.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, v.source_record_key, v.source_location, 'pa-foster-allegheny-1'
FROM dataset d
JOIN (VALUES
    ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'FY 2026-27 Needs-Based Plan & Budget, PDF page 69, section 2-3f Re-entry (in 12 Months)'),
    ('PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9', 'Child Welfare Out-of-Home Placements: Interactive Dashboard, Re-entry view, publication page')
) AS v(dataset_key, source_record_key, source_location) ON d.dataset_key = v.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

-- Locator-only citations: no quoted text is captured, consistent with the "do not invent quoted
-- text" and "do not download source documents" constraints for this corpus.
INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_key IN ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27_DS', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_DS')
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT v.evidence_key, sr.source_record_id, v.observation, v.evidence_type_code, v.notes
FROM (VALUES
    ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1',
     'The Allegheny County FY 2026-27 Needs-Based Plan & Budget reports an 8.1% re-entry-within-12-months indicator for children discharged to reunification, living with a relative, or guardianship, at PDF page 69, section 2-3f.',
     'SOURCE_OBSERVATION',
     'County-scoped source-reported value only. Unresolved and NOT persisted as structured facts: NUMERATOR_NOT_STATED, DENOMINATOR_NOT_STATED, COHORT_PARTIALLY_STATED, CALCULATION_NOT_RECONSTRUCTIBLE, UNDERLYING_PROFILE_PERIOD_NOT_VERIFIED. This observation is independent of and not equated with the approximately 9% dashboard observation.'),
    ('EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9', 'PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9',
     'Allegheny County material describes the dashboard''s Re-entry view as showing children re-entering out-of-home placement within one year at approximately 9% over time.',
     'SOURCE_OBSERVATION',
     'County-scoped source-described trend only. Unresolved and NOT persisted as structured facts: EXACT_FILTER_STATE_NOT_VERIFIED, NUMERATOR_NOT_STATED, DENOMINATOR_NOT_STATED, EXPORT_NOT_OBTAINED, SNAPSHOT_NOT_VERIFIED, RELATION_TO_8_1_PERCENT_NOT_VERIFIED. This observation is independent of and not equated with the 8.1% NBPB observation.')
) AS v(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = v.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key IN ('EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
ON CONFLICT DO NOTHING;

-- Allegheny County, Pennsylvania is represented as a PLACE entity, consistent with existing
-- corpus convention. No new entity_type is introduced.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('pa_foster_allegheny_county', 'PLACE', 'Allegheny County, Pennsylvania',
     'Canonical place entity for the county named as the issuing/reporting scope of both represented Allegheny County source materials.')
ON CONFLICT (entity_key) DO NOTHING;

-- Each observation is modeled as its own reporting/description event rather than as a structured
-- percentage predicate, because no registered ENTITY/EVENT -> VALUE predicate exists for a
-- generic reported-metric percentage without reusing a domain-specific predicate (e.g.
-- ageAtDeathYears, lengthCubits) out of its intended semantic context. Using "subjectOf" only
-- asserts county scope of the reporting event; the percentage itself remains text-only.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('pa_foster_allegheny_nbpb_reentry_report_fy2026_27', 'OTHER',
     'The Allegheny County FY 2026-27 Needs-Based Plan & Budget reporting of the 8.1% re-entry-within-12-months indicator, section 2-3f.'),
    ('pa_foster_allegheny_dashboard_reentry_trend_description', 'OTHER',
     'The Allegheny County dashboard material''s description of the Re-entry view trend of approximately 9%.')
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT en.entity_id, 'subjectOf', ev.event_id
FROM (VALUES
    ('pa_foster_allegheny_county', 'pa_foster_allegheny_nbpb_reentry_report_fy2026_27'),
    ('pa_foster_allegheny_county', 'pa_foster_allegheny_dashboard_reentry_trend_description')
) AS v(entity_key, event_key)
JOIN entity en ON en.entity_key = v.entity_key JOIN event ev ON ev.event_key = v.event_key
WHERE NOT EXISTS (SELECT 1 FROM proposition p WHERE p.subject_entity_id = en.entity_id AND p.predicate = 'subjectOf' AND p.object_event_id = ev.event_id);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT v.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', v.statement, v.notes
FROM (VALUES
    ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'pa_foster_allegheny_county', 'subjectOf', 'pa_foster_allegheny_nbpb_reentry_report_fy2026_27',
     'Allegheny County is the explicit subject of its own NBPB re-entry-within-12-months report (8.1%, as source-reported).',
     'County-scoped only. NUMERATOR_NOT_STATED, DENOMINATOR_NOT_STATED, COHORT_PARTIALLY_STATED, CALCULATION_NOT_RECONSTRUCTIBLE, UNDERLYING_PROFILE_PERIOD_NOT_VERIFIED. No Pennsylvania statewide comparison is asserted. Not equated with the dashboard approximately-9% observation.'),
    ('CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE', 'pa_foster_allegheny_county', 'subjectOf', 'pa_foster_allegheny_dashboard_reentry_trend_description',
     'Allegheny County is the explicit subject of its own dashboard re-entry trend description (approximately 9%, as source-described).',
     'County-scoped only. EXACT_FILTER_STATE_NOT_VERIFIED, NUMERATOR_NOT_STATED, DENOMINATOR_NOT_STATED, EXPORT_NOT_OBTAINED, SNAPSHOT_NOT_VERIFIED, RELATION_TO_8_1_PERCENT_NOT_VERIFIED. No Pennsylvania statewide comparison is asserted. Not equated with the NBPB 8.1% observation.')
) AS v(claim_key, subject_key, predicate, object_key, statement, notes)
JOIN proposition p ON p.predicate = v.predicate
JOIN entity se ON se.entity_key = v.subject_key
JOIN event ov ON ov.event_key = v.object_key
WHERE p.subject_entity_id = se.entity_id AND p.object_event_id = ov.event_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'County-only bounded provenance population: direct source-reported support, no cross-observation equivalence asserted.'
FROM (VALUES
    ('CLAIM_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1_SCOPE', 'EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1'),
    ('CLAIM_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9_SCOPE', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9')
) AS v(claim_key, evidence_key)
JOIN claim c ON c.claim_key = v.claim_key JOIN evidence e ON e.evidence_key = v.evidence_key
ON CONFLICT DO NOTHING;

-- Source identity reconciliation stays conservative: both sources unambiguously name Allegheny
-- County as the issuing/reporting county in their own titles, so an ACTIVE mapping is justified
-- without inferring anything beyond that unambiguous self-identification.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, v.source_identity_key, v.display_name
FROM source s JOIN (VALUES
    ('PA_FOSTER_ALLEGHENY_NBPB_FY2026_27', 'pa-foster-allegheny-nbpb-county', 'Allegheny County'),
    ('PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY', 'pa-foster-allegheny-dashboard-county', 'Allegheny County')
) AS v(source_key, source_identity_key, display_name) ON v.source_key = s.source_key
ON CONFLICT (source_id, source_identity_key) DO NOTHING;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9700, v.justification, e.evidence_id
FROM (VALUES
    ('pa-foster-allegheny-nbpb-county', 'pa_foster_allegheny_county', 'EV_PA_FOSTER_ALLEGHENY_NBPB_REENTRY_8_1',
     'The FY 2026-27 Needs-Based Plan & Budget is unambiguously an Allegheny County DHS/OCYF document; no reconciliation ambiguity is present.'),
    ('pa-foster-allegheny-dashboard-county', 'pa_foster_allegheny_county', 'EV_PA_FOSTER_ALLEGHENY_DASHBOARD_REENTRY_9',
     'The dashboard is unambiguously an Allegheny County DHS / Allegheny Analytics publication; no reconciliation ambiguity is present.')
) AS v(source_identity_key, entity_key, evidence_key, justification)
JOIN source_identity si ON si.source_identity_key = v.source_identity_key
JOIN entity en ON en.entity_key = v.entity_key JOIN evidence e ON e.evidence_key = v.evidence_key
WHERE NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id AND esm.entity_id = en.entity_id AND esm.mapping_status_code = 'ACTIVE');

COMMIT;
