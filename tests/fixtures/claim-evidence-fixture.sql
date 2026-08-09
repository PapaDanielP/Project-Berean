-- Minimal semantic fixture demonstrating the repaired Claim ↔ Evidence model.

INSERT INTO source (source_key, name, source_type)
VALUES ('GENESIS_TEST', 'Genesis test source', 'SCRIPTURE');

INSERT INTO dataset (source_id, dataset_key, name)
SELECT source_id, 'GENESIS_TEST_DATASET', 'Genesis test dataset'
FROM source
WHERE source_key = 'GENESIS_TEST';

INSERT INTO source_record (dataset_id, source_record_key, source_location, raw_content)
SELECT dataset_id, 'GEN_4_1', 'Genesis 4:1',
       'Test source observation for Cain and Eve.'
FROM dataset
WHERE dataset_key = 'GENESIS_TEST_DATASET';

INSERT INTO entity (entity_key, entity_type, canonical_name)
VALUES ('adam_test', 'PERSON', 'Adam'),
       ('cain_test', 'PERSON', 'Cain');

INSERT INTO proposition (
    subject_entity_id,
    predicate,
    object_entity_id
)
SELECT a.entity_id, 'fatherOf', c.entity_id
FROM entity a
CROSS JOIN entity c
WHERE a.entity_key = 'adam_test'
  AND c.entity_key = 'cain_test';

INSERT INTO claim (
    claim_key,
    proposition_id,
    claim_type,
    statement
)
SELECT 'CLAIM_ADAM_FATHER_CAIN',
       proposition_id,
       'DIRECT_SOURCE_CLAIM',
       'Adam is Cain''s father.'
FROM proposition
WHERE predicate = 'fatherOf';

INSERT INTO evidence (
    evidence_key,
    source_record_id,
    observation
)
SELECT 'EVIDENCE_GEN_4_1_CAIN',
       source_record_id,
       'The source record identifies Cain in relation to Adam and Eve.'
FROM source_record
WHERE source_record_key = 'GEN_4_1';

INSERT INTO claim_evidence (
    claim_id,
    evidence_id,
    relation_type
)
SELECT c.claim_id,
       e.evidence_id,
       'SUPPORTS'
FROM claim c
CROSS JOIN evidence e
WHERE c.claim_key = 'CLAIM_ADAM_FATHER_CAIN'
  AND e.evidence_key = 'EVIDENCE_GEN_4_1_CAIN';
