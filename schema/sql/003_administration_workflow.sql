-- Operational administration workflow. These tables coordinate reviewed work; they do not
-- replace or duplicate the authoritative source/evidence/claim/proposition model.

CREATE TABLE workflow_actor (
    actor_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_key TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    role_code TEXT NOT NULL CHECK (role_code IN
        ('READER', 'RESEARCHER', 'CONTENT_EDITOR', 'REVIEWER', 'ADMINISTRATOR', 'SYSTEM')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE corpus (
    corpus_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    corpus_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    scope_note TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    owner_actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE corpus_dataset (
    corpus_id BIGINT NOT NULL REFERENCES corpus(corpus_id),
    dataset_id BIGINT NOT NULL REFERENCES dataset(dataset_id),
    added_by_actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    added_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (corpus_id, dataset_id)
);

CREATE TABLE research_topic (
    research_topic_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    corpus_id BIGINT NOT NULL REFERENCES corpus(corpus_id),
    topic_key TEXT NOT NULL,
    question TEXT NOT NULL,
    scope_note TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'ACTIVE', 'COMPLETED', 'ARCHIVED')),
    owner_actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (corpus_id, topic_key)
);

CREATE TABLE asynchronous_job (
    job_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_type TEXT NOT NULL CHECK (job_type IN ('DISCOVERY', 'INGESTION', 'VALIDATION', 'EXPORT')),
    status TEXT NOT NULL DEFAULT 'QUEUED' CHECK (status IN
        ('QUEUED', 'RUNNING', 'WAITING_FOR_REVIEW', 'COMPLETED', 'FAILED', 'CANCELLED')),
    idempotency_key TEXT NOT NULL,
    request_fingerprint CHAR(64) NOT NULL CHECK (request_fingerprint ~ '^[0-9a-f]{64}$'),
    requested_by_actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    correlation_id UUID NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    progress_current INTEGER NOT NULL DEFAULT 0 CHECK (progress_current >= 0),
    progress_total INTEGER NOT NULL DEFAULT 0 CHECK (progress_total >= 0),
    error_code TEXT,
    error_message TEXT,
    cancel_requested_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (requested_by_actor_id, job_type, idempotency_key)
);

CREATE TABLE discovery_request (
    discovery_request_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    corpus_id BIGINT NOT NULL REFERENCES corpus(corpus_id),
    research_topic_id BIGINT REFERENCES research_topic(research_topic_id),
    job_id BIGINT NOT NULL UNIQUE REFERENCES asynchronous_job(job_id),
    request_kind TEXT NOT NULL CHECK (request_kind IN ('SOURCE_DISCOVERY', 'CANDIDATE_DISCOVERY', 'GAP_DISCOVERY')),
    query_text TEXT NOT NULL,
    bounded_scope TEXT NOT NULL,
    requested_types TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE discovery_candidate (
    discovery_candidate_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    discovery_request_id BIGINT NOT NULL REFERENCES discovery_request(discovery_request_id),
    candidate_key TEXT NOT NULL,
    candidate_type TEXT NOT NULL CHECK (candidate_type IN
        ('PERSON', 'ORGANIZATION', 'PLACE', 'EVENT', 'DOCUMENT', 'TECHNOLOGY',
         'CONCEPT', 'RELATIONSHIP', 'SOURCE_IDENTITY', 'SOURCE')),
    label TEXT NOT NULL,
    description TEXT,
    representation_status TEXT NOT NULL DEFAULT 'UNREVIEWED' CHECK (representation_status IN
        ('UNREVIEWED', 'REPRESENTABLE', 'NOT_REPRESENTED', 'DUPLICATE', 'EXCLUDED')),
    obstacle_classification TEXT CHECK (obstacle_classification IN
        ('QUERY', 'DATA_ENTRY', 'REGISTRY_EXPRESSIVENESS', 'DOMAIN_SCOPING_LIMITATION',
         'ARCHITECTURAL_DEFICIENCY')),
    proposed_predicate TEXT,
    discovery_locator TEXT NOT NULL,
    resulting_entity_id BIGINT REFERENCES entity(entity_id),
    resulting_event_id BIGINT REFERENCES event(event_id),
    resulting_source_identity_id BIGINT REFERENCES source_identity(source_identity_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (discovery_request_id, candidate_key),
    CHECK (candidate_type <> 'RELATIONSHIP' OR proposed_predicate IS NOT NULL),
    CHECK (representation_status <> 'NOT_REPRESENTED' OR obstacle_classification IS NOT NULL)
);

CREATE TABLE candidate_review (
    candidate_review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    discovery_candidate_id BIGINT NOT NULL REFERENCES discovery_candidate(discovery_candidate_id),
    decision TEXT NOT NULL CHECK (decision IN
        ('APPROVED', 'REJECTED', 'NEEDS_SOURCE_VERIFICATION', 'NOT_REPRESENTED')),
    rationale TEXT NOT NULL,
    reviewer_actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (discovery_candidate_id)
);

CREATE TABLE ingestion_job (
    ingestion_job_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT NOT NULL UNIQUE REFERENCES asynchronous_job(job_id),
    corpus_id BIGINT NOT NULL REFERENCES corpus(corpus_id),
    source_id BIGINT REFERENCES source(source_id),
    discovery_candidate_id BIGINT REFERENCES discovery_candidate(discovery_candidate_id),
    transaction_policy TEXT NOT NULL DEFAULT 'ATOMIC'
        CHECK (transaction_policy IN ('ATOMIC', 'SAVEPOINT_PER_ITEM')),
    partial_failure_policy TEXT NOT NULL DEFAULT 'ROLLBACK_ALL'
        CHECK (partial_failure_policy IN ('ROLLBACK_ALL', 'RETAIN_SUCCESSES')),
    committed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ
);

CREATE TABLE ingestion_result (
    ingestion_result_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingestion_job_id BIGINT NOT NULL REFERENCES ingestion_job(ingestion_job_id),
    item_key TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('VALIDATED', 'COMMITTED', 'FAILED', 'SKIPPED')),
    source_record_id BIGINT REFERENCES source_record(source_record_id),
    evidence_id BIGINT REFERENCES evidence(evidence_id),
    claim_id BIGINT REFERENCES claim(claim_id),
    error_code TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ingestion_job_id, item_key)
);

CREATE TABLE validation_run (
    validation_run_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT NOT NULL UNIQUE REFERENCES asynchronous_job(job_id),
    corpus_id BIGINT REFERENCES corpus(corpus_id),
    validation_types TEXT[] NOT NULL,
    completed_at TIMESTAMPTZ,
    CHECK (validation_types <@ ARRAY[
        'SCHEMA', 'PROVENANCE', 'REGISTRY', 'IDENTITY', 'CLAIM', 'EVIDENCE',
        'DERIVATION', 'CORPUS', 'REPLAY', 'READ_ONLY', 'NEGATIVE_SEMANTIC'
    ]::TEXT[])
);

CREATE TABLE validation_result (
    validation_result_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    validation_run_id BIGINT NOT NULL REFERENCES validation_run(validation_run_id),
    validation_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PASS', 'FAIL', 'WARNING', 'NOT_APPLICABLE')),
    code TEXT NOT NULL,
    message TEXT NOT NULL,
    subject_type TEXT,
    subject_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION reject_validation_result_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'validation results are immutable';
END
$$;
CREATE TRIGGER validation_result_immutable
    BEFORE UPDATE OR DELETE ON validation_result
    FOR EACH ROW EXECUTE FUNCTION reject_validation_result_change();

CREATE TABLE export_job (
    export_job_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT NOT NULL UNIQUE REFERENCES asynchronous_job(job_id),
    corpus_id BIGINT NOT NULL REFERENCES corpus(corpus_id),
    format TEXT NOT NULL CHECK (format IN ('JSONL', 'CSV')),
    include_raw_content BOOLEAN NOT NULL DEFAULT FALSE,
    reproducibility_note TEXT NOT NULL,
    manifest_hash CHAR(64),
    CHECK (manifest_hash IS NULL OR manifest_hash ~ '^[0-9a-f]{64}$')
);

CREATE TABLE audit_event (
    audit_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id BIGINT NOT NULL REFERENCES workflow_actor(actor_id),
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id BIGINT,
    correlation_id UUID NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    outcome TEXT NOT NULL CHECK (outcome IN ('SUCCEEDED', 'REJECTED', 'FAILED')),
    detail TEXT NOT NULL
);

CREATE OR REPLACE FUNCTION reject_audit_event_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'audit events are append-only';
END
$$;
CREATE TRIGGER audit_event_append_only
    BEFORE UPDATE OR DELETE ON audit_event
    FOR EACH ROW EXECUTE FUNCTION reject_audit_event_change();

CREATE INDEX ix_research_topic_corpus ON research_topic(corpus_id);
CREATE INDEX ix_discovery_request_corpus ON discovery_request(corpus_id);
CREATE INDEX ix_discovery_candidate_request ON discovery_candidate(discovery_request_id);
CREATE INDEX ix_async_job_status ON asynchronous_job(status, created_at);
CREATE INDEX ix_audit_resource ON audit_event(resource_type, resource_id, occurred_at);
