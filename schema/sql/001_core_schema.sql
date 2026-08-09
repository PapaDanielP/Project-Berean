-- Project Berean core relational baseline
-- v0.6.1 conceptual remediation
-- PostgreSQL-oriented reference DDL; adapt types/syntax if another RDBMS is selected.

CREATE TABLE source (
    source_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    source_type TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dataset (
    dataset_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES source(source_id),
    dataset_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    version TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE source_record (
    source_record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dataset_id BIGINT NOT NULL REFERENCES dataset(dataset_id),
    source_record_key TEXT NOT NULL,
    source_location TEXT,
    raw_content TEXT,
    UNIQUE(dataset_id, source_record_key)
);

CREATE TABLE entity (
    entity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_key TEXT NOT NULL UNIQUE,
    entity_type TEXT NOT NULL,
    canonical_name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE source_identity (
    source_identity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES source(source_id),
    source_identity_key TEXT NOT NULL,
    display_name TEXT NOT NULL,
    UNIQUE(source_id, source_identity_key)
);

CREATE TABLE entity_source_mapping (
    entity_source_mapping_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_identity_id BIGINT NOT NULL REFERENCES source_identity(source_identity_id),
    entity_id BIGINT NOT NULL REFERENCES entity(entity_id),
    mapping_status TEXT NOT NULL DEFAULT 'PROPOSED',
    confidence NUMERIC(5,4),
    notes TEXT
);

CREATE TABLE event (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_key TEXT NOT NULL UNIQUE,
    event_type TEXT NOT NULL,
    description TEXT
);

CREATE TABLE proposition (
    proposition_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject_entity_id BIGINT REFERENCES entity(entity_id),
    subject_event_id BIGINT REFERENCES event(event_id),
    predicate TEXT NOT NULL,
    object_entity_id BIGINT REFERENCES entity(entity_id),
    object_event_id BIGINT REFERENCES event(event_id),
    object_value TEXT,
    CHECK (
        (subject_entity_id IS NOT NULL)::int +
        (subject_event_id IS NOT NULL)::int = 1
    ),
    CHECK (
        (object_entity_id IS NOT NULL)::int +
        (object_event_id IS NOT NULL)::int +
        (object_value IS NOT NULL)::int <= 1
    )
);

CREATE TABLE claim (
    claim_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_key TEXT NOT NULL UNIQUE,
    proposition_id BIGINT NOT NULL REFERENCES proposition(proposition_id),
    claim_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    statement TEXT NOT NULL,
    notes TEXT
);

CREATE TABLE evidence (
    evidence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evidence_key TEXT NOT NULL UNIQUE,
    source_record_id BIGINT NOT NULL REFERENCES source_record(source_record_id),
    observation TEXT NOT NULL,
    evidence_type TEXT NOT NULL DEFAULT 'SOURCE_OBSERVATION',
    notes TEXT
);

CREATE TABLE claim_evidence (
    claim_evidence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_id BIGINT NOT NULL REFERENCES claim(claim_id),
    evidence_id BIGINT NOT NULL REFERENCES evidence(evidence_id),
    relation_type TEXT NOT NULL,
    notes TEXT,
    UNIQUE(claim_id, evidence_id, relation_type)
);

CREATE INDEX ix_source_record_dataset
    ON source_record(dataset_id);

CREATE INDEX ix_evidence_source_record
    ON evidence(source_record_id);

CREATE INDEX ix_claim_evidence_claim
    ON claim_evidence(claim_id);

CREATE INDEX ix_claim_evidence_evidence
    ON claim_evidence(evidence_id);

CREATE INDEX ix_proposition_subject_entity
    ON proposition(subject_entity_id);

CREATE INDEX ix_proposition_object_entity
    ON proposition(object_entity_id);
