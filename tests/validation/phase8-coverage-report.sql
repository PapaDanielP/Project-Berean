\set ON_ERROR_STOP on

\echo 'Phase 8 Genesis 1-11 chapter coverage'
WITH chapters AS (
    SELECT generate_series(1, 11) AS chapter
),
coverage AS (
    SELECT substring(sr.source_location FROM '^Genesis ([0-9]+):')::int AS chapter,
           count(DISTINCT sr.source_record_id) AS source_records,
           count(DISTINCT ci.citation_id) AS citations,
           count(DISTINCT e.evidence_id) AS evidence_items,
           count(DISTINCT cl.claim_id) AS claims,
           count(DISTINCT p.proposition_id) AS propositions,
           count(DISTINCT en.entity_id) FILTER (WHERE en.entity_id IS NOT NULL) AS entities,
           count(DISTINCT si.source_identity_id) AS source_identities,
           count(DISTINCT esm.entity_source_mapping_id) AS entity_mappings,
           count(DISTINCT ev.event_id) AS events,
           count(DISTINCT ep.asserting_claim_id) AS event_participation,
           count(DISTINCT d.derivation_id) AS derivations,
           count(DISTINCT di.input_claim_id) AS derivation_inputs,
           bool_or(sr.raw_content IS NULL) AS structurally_represented,
           bool_or(e.evidence_type_code = 'SOURCE_OBSERVATION') AS source_backed,
           bool_or(cl.claim_type_code = 'DERIVED_CLAIM') AS derived,
           bool_or(sr.raw_content IS NULL OR ci.quoted_text IS NULL) AS intentionally_excluded_text
    FROM source_record sr
    LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
    LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
    LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
    LEFT JOIN claim cl ON cl.claim_id = ce.claim_id
    LEFT JOIN proposition p ON p.proposition_id = cl.proposition_id
    LEFT JOIN entity en ON en.entity_id = p.subject_entity_id OR en.entity_id = p.object_entity_id
    LEFT JOIN entity_source_mapping esm ON esm.supporting_evidence_id = e.evidence_id
    LEFT JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
    LEFT JOIN event ev ON ev.event_id = p.subject_event_id OR ev.event_id = p.object_event_id
    LEFT JOIN event_participation ep ON ep.asserting_claim_id = cl.claim_id
    LEFT JOIN derivation d ON d.derivation_id = cl.derivation_id
    LEFT JOIN derivation_input di ON di.derivation_id = d.derivation_id
    WHERE sr.source_location ~ '^Genesis [0-9]+:[0-9]+$'
    GROUP BY substring(sr.source_location FROM '^Genesis ([0-9]+):')::int
)
SELECT ch.chapter,
       coalesce(c.source_records, 0) AS source_records,
       coalesce(c.citations, 0) AS citations,
       coalesce(c.evidence_items, 0) AS evidence,
       coalesce(c.claims, 0) AS claims,
       coalesce(c.propositions, 0) AS propositions,
       coalesce(c.entities, 0) AS entities,
       coalesce(c.source_identities, 0) AS source_identities,
       coalesce(c.entity_mappings, 0) AS entity_mappings,
       coalesce(c.events, 0) AS events,
       coalesce(c.event_participation, 0) AS event_participation,
       coalesce(c.derivations, 0) AS derivations,
       coalesce(c.derivation_inputs, 0) AS derivation_inputs,
       coalesce(c.structurally_represented, false) AS structurally_represented,
       coalesce(c.source_backed, false) AS source_backed,
       coalesce(c.derived, false) AS derived,
       coalesce(c.intentionally_excluded_text, false) AS intentionally_excluded_text,
       CASE
           WHEN coalesce(c.claims, 0) > 0 THEN 'POPULATED'
           WHEN coalesce(c.source_records, 0) > 0 THEN 'STRUCTURALLY REPRESENTED'
           ELSE 'SOURCE UNAVAILABLE'
       END AS import_status,
       CASE WHEN coalesce(c.source_records, 0) = 0 THEN 'UNRESOLVED' ELSE NULL END AS semantic_status
FROM chapters ch
LEFT JOIN coverage c ON c.chapter = ch.chapter
ORDER BY ch.chapter;

\echo 'Phase 8 Genesis 1 verse coverage (1:10-13 boundary detail)'
SELECT substring(sr.source_location FROM ':([0-9]+)$')::int AS verse,
       sr.source_record_key,
       count(DISTINCT cl.claim_id) AS claims,
       bool_and(sr.raw_content IS NULL AND sr.content_hash IS NULL) AS text_and_hash_excluded
FROM source_record sr
JOIN dataset d ON d.dataset_id = sr.dataset_id
LEFT JOIN evidence e ON e.source_record_id = sr.source_record_id
LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
LEFT JOIN claim cl ON cl.claim_id = ce.claim_id
WHERE d.dataset_key = 'GEN_MT_REF'
  AND sr.source_record_key IN ('MT_GEN_1_10', 'MT_GEN_1_11', 'MT_GEN_1_12', 'MT_GEN_1_13')
GROUP BY sr.source_record_key, sr.source_location
ORDER BY verse;

DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM source_record
        WHERE source_record_key IN ('MT_GEN_1_10', 'MT_GEN_1_11', 'MT_GEN_1_12', 'MT_GEN_1_13')
    ) <> 4 THEN
        RAISE EXCEPTION 'phase8 coverage: Genesis 1:10-13 batch is absent';
    END IF;

    -- Regression boundary check: chapter 1 remains structurally bounded to verses 1-31.
    IF EXISTS (
        SELECT 1
        FROM source_record
        WHERE source_record_key LIKE 'MT_GEN_1\_%' ESCAPE '\'
          AND substring(source_location FROM ':([0-9]+)$')::int > 31
    ) THEN
        RAISE EXCEPTION 'phase8 coverage: Genesis 1 structural range must remain bounded to verses 1-31';
    END IF;
END $$;
