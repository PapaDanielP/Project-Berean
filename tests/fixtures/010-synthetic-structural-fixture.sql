-- SYNTHETIC structural fixture.
--
-- Every source, record, name, and quotation below is invented for testing. Nothing here
-- transcribes or paraphrases a real work. The fixture exercises the structural invariants
-- of the model: typed claim/evidence, shared evidence, competing claims, reconciliation,
-- claim-asserted event participation, and a derived claim with explicit inputs.
--
-- The fixture is transactional and resets only reference-model data, so it is rerunnable.
BEGIN;
TRUNCATE source, entity, event, typed_value, derivation RESTART IDENTITY CASCADE;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('SYNTHETIC_REGISTER_A', 'Synthetic Register A (invented test source)', 'REFERENCE',
     'Invented source used only for structural testing.'),
    ('SYNTHETIC_REGISTER_B', 'Synthetic Register B (invented test source)', 'REFERENCE',
     'Second invented source that disagrees with Register A.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, 'SYNTH_A_ED1', 'Synthetic Register A, edition 1', 'Edition 1', '1.0',
       'Synthetic content authored for this repository', 'Authored in-repository',
       'None; records are stored as authored.'
FROM source WHERE source_key = 'SYNTHETIC_REGISTER_A'
UNION ALL
SELECT source_id, 'SYNTH_B_ED1', 'Synthetic Register B, edition 1', 'Edition 1', '1.0',
       'Synthetic content authored for this repository', 'Authored in-repository',
       'None; records are stored as authored.'
FROM source WHERE source_key = 'SYNTHETIC_REGISTER_B';

INSERT INTO source_record (dataset_id, source_record_key, source_location, raw_content,
                           content_hash, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, r.raw_content,
       encode(sha256(convert_to(r.raw_content, 'UTF8')), 'hex'), 'rev-1'
FROM dataset d
JOIN (VALUES
        ('SYNTH_A_ED1', 'A:1', 'Register A, entry 1', 'Entry 1: Gamma is recorded as the child of Alpha.'),
        ('SYNTH_A_ED1', 'A:2', 'Register A, entry 2', 'Entry 2: Alpha is recorded as living 80 years in total.'),
        ('SYNTH_B_ED1', 'B:7', 'Register B, entry 7', 'Entry 7: Gamma is recorded as the child of Beta.')
     ) AS r(dataset_key, source_record_key, source_location, raw_content)
  ON r.dataset_key = d.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator, quoted_text)
SELECT 'CITE_A_1', source_record_id, 'Register A, entry 1', raw_content
FROM source_record WHERE source_record_key = 'A:1'
UNION ALL
SELECT 'CITE_A_2', source_record_id, 'Register A, entry 2', raw_content
FROM source_record WHERE source_record_key = 'A:2'
UNION ALL
SELECT 'CITE_B_7', source_record_id, 'Register B, entry 7', raw_content
FROM source_record WHERE source_record_key = 'B:7';

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('synthetic_alpha', 'PERSON', 'Alpha', 'Invented person used for structural testing.'),
    ('synthetic_beta', 'PERSON', 'Beta', 'Invented person used for structural testing.'),
    ('synthetic_gamma', 'PERSON', 'Gamma', 'Invented person used for structural testing.');

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT source_id, 'register-a-alpha', 'Alpha'
FROM source WHERE source_key = 'SYNTHETIC_REGISTER_A'
UNION ALL
SELECT source_id, 'register-b-alpha', 'Alpha the elder'
FROM source WHERE source_key = 'SYNTHETIC_REGISTER_B';
INSERT INTO source_identity_alternate_name (source_identity_id, alternate_name)
SELECT source_identity_id, 'Alpha the elder'
FROM source_identity WHERE source_identity_key = 'register-a-alpha';

INSERT INTO event (event_key, event_type_code, description)
VALUES ('synthetic_gamma_birth', 'BIRTH', 'Invented birth event for Gamma.');

INSERT INTO typed_value (value_type_code, numeric_value, uncertainty_lower, uncertainty_upper)
VALUES ('YEAR', 80, 79, 81);

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT s.entity_id, v.predicate, o.entity_id
FROM (VALUES ('synthetic_alpha', 'fatherOf', 'synthetic_gamma'),
             ('synthetic_beta', 'fatherOf', 'synthetic_gamma')) AS v(subject_key, predicate, object_key)
JOIN entity s ON s.entity_key = v.subject_key
JOIN entity o ON o.entity_key = v.object_key;
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, v.predicate, e.event_id
FROM (VALUES ('synthetic_gamma', 'subjectOf'), ('synthetic_alpha', 'parentIn')) AS v(subject_key, predicate)
JOIN entity s ON s.entity_key = v.subject_key
CROSS JOIN event e WHERE e.event_key = 'synthetic_gamma_birth';
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT s.entity_id, 'ageAtDeathYears', t.typed_value_id
FROM entity s CROSS JOIN typed_value t
WHERE s.entity_key = 'synthetic_alpha' AND t.value_type_code = 'YEAR';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_ALPHA_FATHER_GAMMA', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Register A asserts that Alpha is the father of Gamma.'
FROM proposition p JOIN entity s ON s.entity_id = p.subject_entity_id
WHERE p.predicate = 'fatherOf' AND s.entity_key = 'synthetic_alpha'
UNION ALL
SELECT 'CLAIM_BETA_FATHER_GAMMA', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Register B asserts that Beta is the father of Gamma.'
FROM proposition p JOIN entity s ON s.entity_id = p.subject_entity_id
WHERE p.predicate = 'fatherOf' AND s.entity_key = 'synthetic_beta'
UNION ALL
SELECT 'CLAIM_GAMMA_BIRTH_SUBJECT', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Gamma is the subject of the recorded birth event.'
FROM proposition p WHERE p.predicate = 'subjectOf'
UNION ALL
SELECT 'CLAIM_ALPHA_BIRTH_PARENT', p.proposition_id, 'INTERPRETIVE_CLAIM',
       'Alpha is the parent participant in the recorded birth event.'
FROM proposition p WHERE p.predicate = 'parentIn';

INSERT INTO derivation (method, assumptions)
VALUES ('Arithmetic reading of a recorded total lifespan',
        'The recorded total is interpreted as elapsed years at death, with one year of rounding tolerance.');
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_ALPHA_AGE_DERIVED', p.proposition_id, 'DERIVED_CLAIM',
       'Alpha''s modeled age at death is 80 years, with an explicit uncertainty range.', d.derivation_id
FROM proposition p CROSS JOIN derivation d
WHERE p.predicate = 'ageAtDeathYears';

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT 'EV_A_1_PARENTAGE', source_record_id,
       'Register A entry 1 names Alpha as the parent of Gamma.', 'SOURCE_OBSERVATION'
FROM source_record WHERE source_record_key = 'A:1'
UNION ALL
SELECT 'EV_A_2_LIFESPAN', source_record_id,
       'Register A entry 2 records a total lifespan of 80 years for Alpha.', 'SOURCE_OBSERVATION'
FROM source_record WHERE source_record_key = 'A:2'
UNION ALL
SELECT 'EV_B_7_PARENTAGE', source_record_id,
       'Register B entry 7 names Beta, not Alpha, as the parent of Gamma.', 'SOURCE_OBSERVATION'
FROM source_record WHERE source_record_key = 'B:7';

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN (VALUES ('EV_A_1_PARENTAGE', 'CITE_A_1'), ('EV_A_2_LIFESPAN', 'CITE_A_2'),
             ('EV_B_7_PARENTAGE', 'CITE_B_7')) AS m(evidence_key, citation_key)
  ON m.evidence_key = e.evidence_key
JOIN citation c ON c.citation_key = m.citation_key;

-- Typed claim/evidence: shared evidence, multiple evidence per claim, and coexisting
-- supporting and contradicting evidence for the same claim.
INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, m.relation_type_code, m.notes
FROM (VALUES
        ('CLAIM_ALPHA_FATHER_GAMMA', 'EV_A_1_PARENTAGE', 'SUPPORTS', 'Register A states the parentage directly.'),
        ('CLAIM_ALPHA_FATHER_GAMMA', 'EV_B_7_PARENTAGE', 'CONTRADICTS', 'Register B names a different parent.'),
        ('CLAIM_BETA_FATHER_GAMMA', 'EV_B_7_PARENTAGE', 'SUPPORTS', 'Register B states the parentage directly.'),
        ('CLAIM_BETA_FATHER_GAMMA', 'EV_A_1_PARENTAGE', 'CONTRADICTS', 'Register A names a different parent.'),
        ('CLAIM_GAMMA_BIRTH_SUBJECT', 'EV_A_1_PARENTAGE', 'SUPPORTS', 'The same entry records the birth of Gamma.'),
        ('CLAIM_ALPHA_BIRTH_PARENT', 'EV_A_1_PARENTAGE', 'SUPPORTS', 'Participation is inferred from the parentage entry.'),
        ('CLAIM_ALPHA_BIRTH_PARENT', 'EV_B_7_PARENTAGE', 'QUALIFIES', 'Register B qualifies the parental participation.')
     ) AS m(claim_key, evidence_key, relation_type_code, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key;

INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'CONTRADICTS', 'The two registers assert different fathers for Gamma.'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_BETA_FATHER_GAMMA' AND b.claim_key = 'CLAIM_ALPHA_FATHER_GAMMA';
INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'QUALIFIES', 'The participation claim qualifies the parentage claim.'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_ALPHA_BIRTH_PARENT' AND b.claim_key = 'CLAIM_ALPHA_FATHER_GAMMA';

INSERT INTO derivation_input (derivation_id, input_evidence_id, notes)
SELECT d.derivation_id, e.evidence_id, 'Recorded lifespan value.'
FROM derivation d CROSS JOIN evidence e
WHERE e.evidence_key = 'EV_A_2_LIFESPAN';
INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, c.claim_id, 'The subject of the lifespan is the Alpha of Register A.'
FROM derivation d CROSS JOIN claim c
WHERE c.claim_key = 'CLAIM_ALPHA_FATHER_GAMMA';

-- Reconciliation: one active, auditable mapping and one unresolved proposal.
INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9900,
       'Register A entry 1 identifies this source identity with the canonical Alpha.', ev.evidence_id
FROM source_identity si CROSS JOIN entity en CROSS JOIN evidence ev
WHERE si.source_identity_key = 'register-a-alpha' AND en.entity_key = 'synthetic_alpha'
  AND ev.evidence_key = 'EV_A_1_PARENTAGE';
INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification)
SELECT si.source_identity_id, en.entity_id, 'PROPOSED', 0.5000,
       'Register B may use a different Alpha; the identification is unresolved.'
FROM source_identity si CROSS JOIN entity en
WHERE si.source_identity_key = 'register-b-alpha' AND en.entity_key = 'synthetic_alpha';
COMMIT;
