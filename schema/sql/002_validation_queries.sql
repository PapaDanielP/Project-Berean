-- Read-only diagnostic queries. scripts/validation/validate.sql makes failures blocking.

-- Non-derived claims without evidence.
SELECT c.claim_key
FROM claim c
WHERE c.claim_type_code <> 'DERIVED_CLAIM'
  AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.claim_id = c.claim_id);

-- Source-observation evidence without a citation.
SELECT e.evidence_key
FROM evidence e
WHERE e.evidence_type_code = 'SOURCE_OBSERVATION'
  AND NOT EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id);

-- Defensive checks for data loaded with constraints disabled.
SELECT esm.entity_source_mapping_id
FROM entity_source_mapping esm
WHERE esm.confidence IS NOT NULL AND esm.confidence NOT BETWEEN 0 AND 1;

SELECT source_identity_id, entity_id
FROM entity_source_mapping
WHERE mapping_status_code = 'ACTIVE'
GROUP BY source_identity_id, entity_id
HAVING count(*) > 1;

SELECT p.proposition_id
FROM proposition p
WHERE ((p.subject_entity_id IS NOT NULL)::int + (p.subject_event_id IS NOT NULL)::int) <> 1
   OR ((p.object_entity_id IS NOT NULL)::int + (p.object_event_id IS NOT NULL)::int
       + (p.object_typed_value_id IS NOT NULL)::int) <> 1;
