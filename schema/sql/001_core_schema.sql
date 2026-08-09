-- Project Berean core relational baseline.
-- PostgreSQL 16 reference DDL. Apply to an empty schema.

CREATE TABLE source_type (
    source_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE entity_type (
    entity_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE claim_type (
    claim_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE claim_status (
    claim_status_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE evidence_type (
    evidence_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE claim_evidence_relation_type (
    relation_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE mapping_status (
    mapping_status_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE event_type (
    event_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE event_participation_role (
    role_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE claim_relation_type (
    relation_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);
CREATE TABLE value_type (
    value_type_code TEXT PRIMARY KEY,
    description TEXT NOT NULL
);

INSERT INTO source_type VALUES
    ('SCRIPTURE', 'A scriptural source or edition'), ('HISTORICAL_WORK', 'A historical work'),
    ('DATASET', 'An external structured dataset'), ('REFERENCE', 'A reference work');
INSERT INTO entity_type VALUES
    ('PERSON', 'A person'), ('PLACE', 'A place'), ('ORGANIZATION', 'An organization'),
    ('OBJECT', 'A physical object'), ('CONCEPT', 'A concept');
INSERT INTO claim_type VALUES
    ('DIRECT_SOURCE_CLAIM', 'A claim directly grounded in a source'),
    ('INTERPRETIVE_CLAIM', 'An interpretive claim'), ('DERIVED_CLAIM', 'A derived claim');
INSERT INTO claim_status VALUES
    ('ACTIVE', 'Currently asserted'), ('SUPERSEDED', 'Replaced by a later claim'),
    ('RETRACTED', 'Withdrawn'), ('UNDER_REVIEW', 'Not yet resolved');
INSERT INTO evidence_type VALUES
    ('SOURCE_OBSERVATION', 'An observation from a source record'),
    ('ANALYTICAL_OBSERVATION', 'An observation made during analysis');
INSERT INTO claim_evidence_relation_type VALUES
    ('SUPPORTS', 'Supports the claim'), ('CONTRADICTS', 'Contradicts the claim'),
    ('QUALIFIES', 'Qualifies the claim');
INSERT INTO mapping_status VALUES
    ('PROPOSED', 'Proposed reconciliation'), ('ACTIVE', 'Active reconciliation'),
    ('REJECTED', 'Rejected reconciliation'), ('SUPERSEDED', 'Superseded reconciliation');
INSERT INTO event_type VALUES
    ('BIRTH', 'Birth'), ('DEATH', 'Death'), ('GENEALOGICAL', 'Genealogical event'),
    ('CHRONOLOGICAL', 'Chronological event'), ('OTHER', 'Other event');
INSERT INTO event_participation_role VALUES
    ('PARTICIPANT', 'General participant'), ('SUBJECT', 'Primary subject'),
    ('PARENT', 'Parent'), ('CHILD', 'Child');
INSERT INTO claim_relation_type VALUES
    ('CONTRADICTS', 'Contradicts another claim'), ('QUALIFIES', 'Qualifies another claim'),
    ('REFINES', 'Refines another claim'), ('DUPLICATES', 'Duplicates another claim'),
    ('SUPERSEDES', 'Supersedes another claim');
INSERT INTO value_type VALUES
    ('TEXT', 'Textual value'), ('INTEGER', 'Integer value'), ('DECIMAL', 'Decimal value'),
    ('YEAR', 'Year value'), ('DATE', 'Calendar date'), ('DURATION', 'PostgreSQL interval');

CREATE TABLE source (
    source_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    source_type_code TEXT NOT NULL REFERENCES source_type(source_type_code),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dataset (
    dataset_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES source(source_id),
    dataset_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    edition_label TEXT,
    version TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE source_record (
    source_record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dataset_id BIGINT NOT NULL REFERENCES dataset(dataset_id),
    source_record_key TEXT NOT NULL,
    source_location TEXT,
    raw_content TEXT,
    content_hash CHAR(64) NOT NULL CHECK (content_hash ~ '^[0-9a-f]{64}$'),
    imported_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revision_label TEXT,
    supersedes_source_record_id BIGINT REFERENCES source_record(source_record_id),
    UNIQUE(dataset_id, source_record_key)
);

CREATE TABLE citation (
    citation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    citation_key TEXT NOT NULL UNIQUE,
    source_record_id BIGINT NOT NULL REFERENCES source_record(source_record_id),
    locator TEXT NOT NULL,
    quoted_text TEXT,
    UNIQUE(source_record_id, locator)
);

CREATE TABLE entity (
    entity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_key TEXT NOT NULL UNIQUE,
    entity_type_code TEXT NOT NULL REFERENCES entity_type(entity_type_code),
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
    mapping_status_code TEXT NOT NULL DEFAULT 'PROPOSED'
        REFERENCES mapping_status(mapping_status_code),
    confidence NUMERIC(5,4) CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
    notes TEXT
);
CREATE UNIQUE INDEX uq_active_entity_source_mapping
    ON entity_source_mapping(source_identity_id, entity_id)
    WHERE mapping_status_code = 'ACTIVE';

CREATE TABLE event (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_key TEXT NOT NULL UNIQUE,
    event_type_code TEXT NOT NULL REFERENCES event_type(event_type_code),
    description TEXT
);

CREATE TABLE typed_value (
    typed_value_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    value_type_code TEXT NOT NULL REFERENCES value_type(value_type_code),
    text_value TEXT,
    numeric_value NUMERIC,
    date_value DATE,
    duration_value INTERVAL,
    uncertainty_lower NUMERIC,
    uncertainty_upper NUMERIC,
    CHECK (uncertainty_lower IS NULL OR uncertainty_upper IS NOT NULL),
    CHECK (uncertainty_upper IS NULL OR uncertainty_lower IS NOT NULL),
    CHECK (uncertainty_lower IS NULL OR uncertainty_lower <= uncertainty_upper),
    CHECK (
        (value_type_code = 'TEXT' AND text_value IS NOT NULL AND numeric_value IS NULL AND date_value IS NULL AND duration_value IS NULL)
        OR (value_type_code IN ('INTEGER', 'DECIMAL', 'YEAR') AND numeric_value IS NOT NULL AND text_value IS NULL AND date_value IS NULL AND duration_value IS NULL)
        OR (value_type_code = 'DATE' AND date_value IS NOT NULL AND text_value IS NULL AND numeric_value IS NULL AND duration_value IS NULL)
        OR (value_type_code = 'DURATION' AND duration_value IS NOT NULL AND text_value IS NULL AND numeric_value IS NULL AND date_value IS NULL)
    )
);

CREATE TABLE proposition (
    proposition_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject_entity_id BIGINT REFERENCES entity(entity_id),
    subject_event_id BIGINT REFERENCES event(event_id),
    predicate TEXT NOT NULL,
    object_entity_id BIGINT REFERENCES entity(entity_id),
    object_event_id BIGINT REFERENCES event(event_id),
    object_typed_value_id BIGINT REFERENCES typed_value(typed_value_id),
    CHECK ((subject_entity_id IS NOT NULL)::int + (subject_event_id IS NOT NULL)::int = 1),
    CHECK ((object_entity_id IS NOT NULL)::int + (object_event_id IS NOT NULL)::int
           + (object_typed_value_id IS NOT NULL)::int = 1)
);

CREATE TABLE claim (
    claim_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_key TEXT NOT NULL UNIQUE,
    proposition_id BIGINT NOT NULL REFERENCES proposition(proposition_id),
    claim_type_code TEXT NOT NULL REFERENCES claim_type(claim_type_code),
    claim_status_code TEXT NOT NULL DEFAULT 'ACTIVE' REFERENCES claim_status(claim_status_code),
    statement TEXT NOT NULL,
    notes TEXT
);

CREATE TABLE event_participation (
    event_participation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES event(event_id),
    entity_id BIGINT NOT NULL REFERENCES entity(entity_id),
    role_code TEXT NOT NULL REFERENCES event_participation_role(role_code),
    asserting_claim_id BIGINT NOT NULL REFERENCES claim(claim_id),
    UNIQUE(event_id, entity_id, role_code, asserting_claim_id)
);

CREATE TABLE derivation (
    derivation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    method TEXT NOT NULL,
    assumptions TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE claim ADD COLUMN derivation_id BIGINT UNIQUE REFERENCES derivation(derivation_id);

CREATE TABLE evidence (
    evidence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evidence_key TEXT NOT NULL UNIQUE,
    source_record_id BIGINT NOT NULL REFERENCES source_record(source_record_id),
    observation TEXT NOT NULL,
    evidence_type_code TEXT NOT NULL DEFAULT 'SOURCE_OBSERVATION'
        REFERENCES evidence_type(evidence_type_code),
    notes TEXT
);

CREATE TABLE derivation_input (
    derivation_input_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    derivation_id BIGINT NOT NULL REFERENCES derivation(derivation_id),
    input_claim_id BIGINT REFERENCES claim(claim_id),
    input_evidence_id BIGINT REFERENCES evidence(evidence_id),
    notes TEXT,
    CHECK ((input_claim_id IS NOT NULL)::int + (input_evidence_id IS NOT NULL)::int = 1)
);

CREATE TABLE evidence_citation (
    evidence_id BIGINT NOT NULL REFERENCES evidence(evidence_id),
    citation_id BIGINT NOT NULL REFERENCES citation(citation_id),
    PRIMARY KEY (evidence_id, citation_id)
);

CREATE TABLE claim_evidence (
    claim_evidence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_id BIGINT NOT NULL REFERENCES claim(claim_id),
    evidence_id BIGINT NOT NULL REFERENCES evidence(evidence_id),
    relation_type_code TEXT NOT NULL REFERENCES claim_evidence_relation_type(relation_type_code),
    notes TEXT,
    UNIQUE(claim_id, evidence_id, relation_type_code)
);

CREATE TABLE claim_relation (
    claim_relation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_id BIGINT NOT NULL REFERENCES claim(claim_id),
    related_claim_id BIGINT NOT NULL REFERENCES claim(claim_id),
    relation_type_code TEXT NOT NULL REFERENCES claim_relation_type(relation_type_code),
    notes TEXT,
    CHECK (claim_id <> related_claim_id),
    UNIQUE(claim_id, related_claim_id, relation_type_code)
);

CREATE INDEX ix_source_record_dataset ON source_record(dataset_id);
CREATE INDEX ix_citation_source_record ON citation(source_record_id);
CREATE INDEX ix_evidence_source_record ON evidence(source_record_id);
CREATE INDEX ix_claim_evidence_claim ON claim_evidence(claim_id);
CREATE INDEX ix_claim_evidence_evidence ON claim_evidence(evidence_id);
CREATE INDEX ix_claim_relation_claim ON claim_relation(claim_id);
CREATE INDEX ix_event_participation_event ON event_participation(event_id);
CREATE INDEX ix_derivation_input_derivation ON derivation_input(derivation_id);
CREATE INDEX ix_proposition_subject_entity ON proposition(subject_entity_id);
CREATE INDEX ix_proposition_object_entity ON proposition(object_entity_id);
