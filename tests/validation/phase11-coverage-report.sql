\set ON_ERROR_STOP on

\echo 'Phase 11 object/artifact entity coverage (structural/source-backed; not semantic completeness)'
SELECT en.entity_key,
       en.entity_type_code,
       en.canonical_name,
       count(DISTINCT si.source_identity_id) AS source_identities,
       count(DISTINCT esm.entity_source_mapping_id) FILTER (WHERE esm.mapping_status_code = 'ACTIVE')
           AS active_entity_mappings,
       count(DISTINCT sr.source_record_id) AS source_records,
       count(DISTINCT ci.citation_id) AS citations,
       count(DISTINCT ev.evidence_id) AS evidence_items,
       count(DISTINCT c.claim_id) AS claims,
       count(DISTINCT p.proposition_id) AS propositions,
       count(DISTINCT ep.asserting_claim_id) AS event_participation_rows,
       CASE
           WHEN count(DISTINCT c.claim_id) > 0 THEN 'POPULATED'
           WHEN count(DISTINCT sr.source_record_id) > 0 THEN 'STRUCTURALLY REPRESENTED'
           ELSE 'VALIDATION-ONLY / SOURCE UNAVAILABLE'
       END AS import_status
FROM entity en
LEFT JOIN entity_source_mapping esm ON esm.entity_id = en.entity_id
LEFT JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id OR p.object_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
LEFT JOIN evidence ev ON ev.evidence_id = ce.evidence_id
LEFT JOIN evidence_citation ecit ON ecit.evidence_id = ev.evidence_id
LEFT JOIN citation ci ON ci.citation_id = ecit.citation_id
LEFT JOIN source_record sr ON sr.source_record_id = ev.source_record_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_type_code = 'OBJECT'
GROUP BY en.entity_key, en.entity_type_code, en.canonical_name
ORDER BY en.entity_key;

\echo 'Phase 11 competing/shared-evidence check (ClaimEvidence many-to-many remains intact)'
SELECT e.evidence_key,
       count(DISTINCT ce.claim_id) AS supported_claims
FROM evidence e
JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
WHERE e.evidence_key = 'EV_MT_GEN_8_4'
GROUP BY e.evidence_key;

DO $$
BEGIN
    IF (
        SELECT count(*) FROM entity WHERE entity_type_code = 'OBJECT'
    ) <> 2 THEN
        RAISE EXCEPTION 'phase11 coverage: expected exactly two OBJECT entities (noahs_ark, ark_of_covenant)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM entity WHERE entity_key = 'noahs_ark' AND entity_type_code = 'OBJECT'
    ) THEN
        RAISE EXCEPTION 'phase11 coverage: noahs_ark OBJECT entity is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM entity WHERE entity_key = 'ark_of_covenant' AND entity_type_code = 'OBJECT'
    ) THEN
        RAISE EXCEPTION 'phase11 coverage: ark_of_covenant OBJECT entity is missing';
    END IF;
END $$;
