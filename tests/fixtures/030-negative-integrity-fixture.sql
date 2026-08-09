-- Constraint cases that must fail. Each expected failure is caught, so the file is runnable
-- and non-destructive; an unexpected success raises and stops the run.
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
        SELECT entity_id, 'fatherOf' FROM entity LIMIT 1;
        RAISE EXCEPTION 'invalid proposition cardinality was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
        SELECT a.entity_id, 'unregisteredPredicate', b.entity_id
        FROM entity a CROSS JOIN entity b WHERE a.entity_id <> b.entity_id LIMIT 1;
        RAISE EXCEPTION 'unregistered predicate was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        -- fatherOf is registered as ENTITY -> ENTITY, so an event object must be rejected.
        INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
        SELECT e.entity_id, 'fatherOf', v.event_id FROM entity e CROSS JOIN event v LIMIT 1;
        RAISE EXCEPTION 'predicate object-kind mismatch was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
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
    BEGIN
        INSERT INTO source_record (dataset_id, source_record_key, raw_content)
        SELECT dataset_id, 'UNHASHED_IMPORT', 'Imported content without a content hash.'
        FROM dataset LIMIT 1;
        RAISE EXCEPTION 'imported content without a content hash was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code)
        SELECT claim_id, claim_id, 'CONTRADICTS' FROM claim LIMIT 1;
        RAISE EXCEPTION 'self-referential claim relation was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO typed_value (value_type_code, text_value)
        VALUES ('YEAR', 'one hundred');
        RAISE EXCEPTION 'untyped value payload was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
END $$;
