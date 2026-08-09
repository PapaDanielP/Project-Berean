-- Deterministic semantic fixture. It resets only reference-model data.
BEGIN;
TRUNCATE source, entity, event, typed_value, derivation RESTART IDENTITY CASCADE;

INSERT INTO source (source_key, name, source_type_code)
VALUES ('GENESIS_TEST', 'Genesis test source', 'SCRIPTURE');
INSERT INTO dataset (source_id, dataset_key, name, edition_label, version)
SELECT source_id, 'GENESIS_TEST_DATASET', 'Genesis test dataset', 'Test edition', '1'
FROM source WHERE source_key = 'GENESIS_TEST';
INSERT INTO source_record (dataset_id, source_record_key, source_location, raw_content, content_hash, revision_label)
SELECT dataset_id, 'GEN_4_1', 'Genesis 4:1', 'Test source observation for Cain and Eve.',
       repeat('a', 64), 'test-1'
FROM dataset WHERE dataset_key = 'GENESIS_TEST_DATASET'
UNION ALL
SELECT dataset_id, 'GEN_5_5', 'Genesis 5:5', 'Test source observation for Adam chronology.',
       repeat('b', 64), 'test-1'
FROM dataset WHERE dataset_key = 'GENESIS_TEST_DATASET';
INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITATION_GEN_4_1', source_record_id, 'Genesis 4:1'
FROM source_record WHERE source_record_key = 'GEN_4_1'
UNION ALL
SELECT 'CITATION_GEN_5_5', source_record_id, 'Genesis 5:5'
FROM source_record WHERE source_record_key = 'GEN_5_5';

INSERT INTO entity (entity_key, entity_type_code, canonical_name) VALUES
    ('adam_test', 'PERSON', 'Adam'), ('eve_test', 'PERSON', 'Eve'),
    ('cain_test', 'PERSON', 'Cain');
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT source_id, 'adam-in-test-source', 'Adam'
FROM source WHERE source_key = 'GENESIS_TEST';
INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence)
SELECT si.source_identity_id, e.entity_id, 'ACTIVE', 0.9900
FROM source_identity si CROSS JOIN entity e
WHERE si.source_identity_key = 'adam-in-test-source' AND e.entity_key = 'adam_test';

INSERT INTO event (event_key, event_type_code, description)
VALUES ('cain_birth_test', 'BIRTH', 'Cain birth event used for fixture participation.');
INSERT INTO typed_value (value_type_code, numeric_value, uncertainty_lower, uncertainty_upper)
VALUES ('YEAR', 930, 929, 931);
INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT a.entity_id, 'fatherOf', c.entity_id FROM entity a CROSS JOIN entity c
WHERE a.entity_key = 'adam_test' AND c.entity_key = 'cain_test';
INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT a.entity_id, 'notFatherOf', c.entity_id FROM entity a CROSS JOIN entity c
WHERE a.entity_key = 'adam_test' AND c.entity_key = 'cain_test';
INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT e.entity_id, 'motherOf', c.entity_id FROM entity e CROSS JOIN entity c
WHERE e.entity_key = 'eve_test' AND c.entity_key = 'cain_test';
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT e.entity_id, 'participatesIn', v.event_id FROM entity e CROSS JOIN event v
WHERE e.entity_key = 'cain_test' AND v.event_key = 'cain_birth_test';
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'ageAtDeathYears', v.typed_value_id FROM entity e CROSS JOIN typed_value v
WHERE e.entity_key = 'adam_test' AND v.value_type_code = 'YEAR';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_ADAM_FATHER_CAIN', proposition_id, 'DIRECT_SOURCE_CLAIM', 'Adam is Cain''s father.'
FROM proposition WHERE predicate = 'fatherOf'
UNION ALL
SELECT 'CLAIM_ADAM_NOT_FATHER_CAIN', proposition_id, 'INTERPRETIVE_CLAIM', 'Adam is not Cain''s father.'
FROM proposition WHERE predicate = 'notFatherOf'
UNION ALL
SELECT 'CLAIM_EVE_MOTHER_CAIN', proposition_id, 'DIRECT_SOURCE_CLAIM', 'Eve is Cain''s mother.'
FROM proposition WHERE predicate = 'motherOf'
UNION ALL
SELECT 'CLAIM_CAIN_BIRTH', proposition_id, 'DIRECT_SOURCE_CLAIM', 'Cain participates in the modeled birth event.'
FROM proposition WHERE predicate = 'participatesIn';
INSERT INTO derivation (method, assumptions)
VALUES ('Chronology arithmetic from recorded age values', 'The source age values are interpreted as elapsed years.');
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_ADAM_AGE_DERIVED', proposition_id, 'DERIVED_CLAIM',
       'Adam''s modeled age at death is 930 years, with an explicit uncertainty range.', derivation_id
FROM proposition CROSS JOIN derivation WHERE predicate = 'ageAtDeathYears';

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT 'EVIDENCE_GEN_4_1_PARENTAGE', source_record_id,
       'The source record identifies Cain in relation to Adam and Eve.', 'SOURCE_OBSERVATION'
FROM source_record WHERE source_record_key = 'GEN_4_1'
UNION ALL
SELECT 'EVIDENCE_GEN_5_5_CHRONOLOGY', source_record_id,
       'The source record supplies chronology material for Adam.', 'SOURCE_OBSERVATION'
FROM source_record WHERE source_record_key = 'GEN_5_5';
INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.citation_key = 'CITATION_GEN_4_1'
WHERE e.evidence_key = 'EVIDENCE_GEN_4_1_PARENTAGE'
UNION ALL
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.citation_key = 'CITATION_GEN_5_5'
WHERE e.evidence_key = 'EVIDENCE_GEN_5_5_CHRONOLOGY';
INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS'
FROM claim c CROSS JOIN evidence e
WHERE c.claim_key IN ('CLAIM_ADAM_FATHER_CAIN', 'CLAIM_EVE_MOTHER_CAIN', 'CLAIM_CAIN_BIRTH')
  AND e.evidence_key = 'EVIDENCE_GEN_4_1_PARENTAGE'
UNION ALL
SELECT c.claim_id, e.evidence_id, 'SUPPORTS'
FROM claim c CROSS JOIN evidence e
WHERE c.claim_key = 'CLAIM_ADAM_NOT_FATHER_CAIN'
  AND e.evidence_key = 'EVIDENCE_GEN_5_5_CHRONOLOGY'
UNION ALL
SELECT c.claim_id, e.evidence_id, 'CONTRADICTS'
FROM claim c CROSS JOIN evidence e
WHERE c.claim_key = 'CLAIM_ADAM_FATHER_CAIN'
  AND e.evidence_key = 'EVIDENCE_GEN_5_5_CHRONOLOGY';
INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code)
SELECT a.claim_id, b.claim_id, 'QUALIFIES'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_EVE_MOTHER_CAIN' AND b.claim_key = 'CLAIM_ADAM_FATHER_CAIN';
INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code)
SELECT a.claim_id, b.claim_id, 'CONTRADICTS'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_ADAM_NOT_FATHER_CAIN' AND b.claim_key = 'CLAIM_ADAM_FATHER_CAIN';
INSERT INTO event_participation (event_id, entity_id, role_code, asserting_claim_id)
SELECT v.event_id, e.entity_id, 'SUBJECT', c.claim_id
FROM event v CROSS JOIN entity e CROSS JOIN claim c
WHERE v.event_key = 'cain_birth_test' AND e.entity_key = 'cain_test'
  AND c.claim_key = 'CLAIM_CAIN_BIRTH';
INSERT INTO derivation_input (derivation_id, input_evidence_id, notes)
SELECT d.derivation_id, e.evidence_id, 'Chronology source input.'
FROM derivation d CROSS JOIN evidence e
WHERE e.evidence_key = 'EVIDENCE_GEN_5_5_CHRONOLOGY';
COMMIT;
