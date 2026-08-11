\set ON_ERROR_STOP on
CREATE TEMP TABLE phase36_counts_before AS
SELECT (SELECT count(*) FROM source) AS sources, (SELECT count(*) FROM claim) AS claims,
       (SELECT count(*) FROM evidence) AS evidence, (SELECT count(*) FROM proposition) AS propositions;
BEGIN READ ONLY;
-- Withheld interrogation: no answer table is used; all results traverse persisted claims.
SELECT c.claim_key, r.rendered_proposition, string_agg(DISTINCT s.source_key, ', ' ORDER BY s.source_key) AS sources
FROM claim c JOIN claim_rendering r ON r.claim_id = c.claim_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id JOIN dataset d ON d.dataset_id = sr.dataset_id JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key LIKE 'CLAIM\_P36\_%' ESCAPE '\' GROUP BY c.claim_key, r.rendered_proposition ORDER BY c.claim_key;
SELECT e.evidence_key, e.observation, 'SCHOLARLY_CANDIDATE_NOT_PROMOTED' AS classification
FROM evidence e WHERE e.evidence_key IN ('EV_P36_WELLMAN_INTERPRETATION', 'EV_P36_TETRAULT_INTERPRETATION') ORDER BY e.evidence_key;
SELECT si.display_name, esm.mapping_status_code, en.canonical_name, esm.justification
FROM entity_source_mapping esm JOIN source_identity si ON si.source_identity_id = esm.source_identity_id JOIN entity en ON en.entity_id = esm.entity_id
WHERE si.source_identity_key = 'phase36-proceedings-mrs-mott';
COMMIT;
DO $$
BEGIN
    IF (SELECT claims FROM phase36_counts_before) <> (SELECT count(*) FROM claim)
       OR (SELECT evidence FROM phase36_counts_before) <> (SELECT count(*) FROM evidence)
       OR (SELECT propositions FROM phase36_counts_before) <> (SELECT count(*) FROM proposition) THEN
        RAISE EXCEPTION 'phase36: read-only interrogation changed persistent state';
    END IF;
    RAISE NOTICE 'ok: Phase 36 withheld interrogation is read-only and returns direct claims, scholarly candidates, and unresolved identity separately.';
END $$;
