-- Berean integrity checks

-- Claims without evidence
SELECT c.claim_id, c.claim_key
FROM claim c
LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
WHERE ce.claim_id IS NULL;

-- Evidence without provenance (should return zero)
SELECT e.evidence_id, e.evidence_key
FROM evidence e
LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
WHERE sr.source_record_id IS NULL;

-- Broken source-record dataset references
SELECT sr.source_record_id, sr.source_record_key
FROM source_record sr
LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
WHERE d.dataset_id IS NULL;

-- Evidence provenance chain
SELECT
    e.evidence_key,
    sr.source_record_key,
    d.dataset_key,
    s.source_key
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id;

-- Claims with contradictory evidence
SELECT
    c.claim_key,
    ce.relation_type,
    e.evidence_key
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
WHERE ce.relation_type = 'CONTRADICTS';
