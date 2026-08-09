-- Constraint cases that must fail; each failure is caught so this file is runnable.
DO $$
BEGIN
    BEGIN
        INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence)
        SELECT source_identity_id, entity_id, 'PROPOSED', 1.1
        FROM source_identity CROSS JOIN entity LIMIT 1;
        RAISE EXCEPTION 'invalid confidence was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO proposition (subject_entity_id, predicate)
        SELECT entity_id, 'invalidCardinality' FROM entity LIMIT 1;
        RAISE EXCEPTION 'invalid proposition cardinality was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code)
        SELECT claim_id, evidence_id, 'UNCONTROLLED'
        FROM claim CROSS JOIN evidence LIMIT 1;
        RAISE EXCEPTION 'uncontrolled relation was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
        VALUES ('INVALID_PROVENANCE', -1, 'This must not be stored.', 'SOURCE_OBSERVATION');
        RAISE EXCEPTION 'invalid evidence provenance was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
END $$;
