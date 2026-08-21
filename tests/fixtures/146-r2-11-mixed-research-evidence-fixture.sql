-- R2-11 mixed research-evidence fixture.
--
-- Bounded, neutral behaviour-testing data for one represented research topic:
-- "What madeOfMaterial claim is represented for R2-11 Reference Assembly?".
--
-- The topic deliberately carries, at the same time, a direct source-backed claim,
-- a derived claim with persisted derivation inputs, two competing interpretive
-- claims, a claim with contradicting evidence, and a claim with qualifying
-- evidence. Every row is represented data only: no row is selected, promoted,
-- reconciled, or characterised as resolved truth, and no historical assertion is
-- introduced. Labels are placeholder designations, not source text.
BEGIN;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('R211_PRIMARY_ALPHA', 'R2-11 represented primary reference alpha', 'REFERENCE',
     'Bounded placeholder reference used only to exercise represented direct-support behaviour. No source text is stored.'),
    ('R211_PRIMARY_BETA', 'R2-11 represented primary reference beta', 'REFERENCE',
     'Bounded placeholder reference used only to exercise represented contradicting and qualifying evidence. No source text is stored.'),
    ('R211_SCHOLARSHIP_ONE', 'R2-11 represented scholarly position one', 'REFERENCE',
     'Bounded placeholder reference used only to exercise a represented scholarly interpretation.'),
    ('R211_SCHOLARSHIP_TWO', 'R2-11 represented scholarly position two', 'REFERENCE',
     'Bounded placeholder reference used only to exercise a competing represented scholarly interpretation.')
ON CONFLICT (source_key) DO NOTHING;

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version, license_status, acquisition_method, transformation_notes)
SELECT s.source_id, d.dataset_key, d.name, d.edition_label, 'r2-11',
       'Locator-only placeholder bibliography; source text is NOT_STORED_BY_POLICY.',
       'Manually entered bounded regression fixture', d.notes
FROM source s
JOIN (VALUES
        ('R211_PRIMARY_ALPHA', 'R211_PRIMARY_ALPHA_REF', 'R2-11 primary alpha reference points',
         'R2-11 bounded fixture edition', 'Direct-support layer only; no historical assertion is made.'),
        ('R211_PRIMARY_BETA', 'R211_PRIMARY_BETA_REF', 'R2-11 primary beta reference points',
         'R2-11 bounded fixture edition', 'Contradicting and qualifying evidence layer only; disagreement is retained, not resolved.'),
        ('R211_SCHOLARSHIP_ONE', 'R211_SCHOLARSHIP_ONE_REF', 'R2-11 scholarly position one reference point',
         'R2-11 bounded fixture edition', 'Scholarly interpretation candidate only; never promoted to source fact.'),
        ('R211_SCHOLARSHIP_TWO', 'R211_SCHOLARSHIP_TWO_REF', 'R2-11 scholarly position two reference point',
         'R2-11 bounded fixture edition', 'Competing scholarly interpretation candidate only; no ranking is represented.')
     ) AS d(source_key, dataset_key, name, edition_label, notes) ON s.source_key = d.source_key
ON CONFLICT (dataset_key) DO NOTHING;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'r2-11'
FROM dataset d
JOIN (VALUES
        ('R211_PRIMARY_ALPHA_REF', 'R211_ALPHA_RECORD', 'R2-11 bounded fixture locator, alpha reference, section 1'),
        ('R211_PRIMARY_BETA_REF', 'R211_BETA_RECORD', 'R2-11 bounded fixture locator, beta reference, section 1'),
        ('R211_SCHOLARSHIP_ONE_REF', 'R211_SCHOLARSHIP_ONE_RECORD', 'R2-11 bounded fixture locator, scholarly position one'),
        ('R211_SCHOLARSHIP_TWO_REF', 'R211_SCHOLARSHIP_TWO_RECORD', 'R2-11 bounded fixture locator, scholarly position two')
     ) AS r(dataset_key, source_record_key, source_location) ON d.dataset_key = r.dataset_key
ON CONFLICT (dataset_id, source_record_key) DO NOTHING;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'R211_ALPHA_RECORD',
    'R211_BETA_RECORD',
    'R211_SCHOLARSHIP_ONE_RECORD',
    'R211_SCHOLARSHIP_TWO_RECORD'
)
ON CONFLICT (citation_key) DO NOTHING;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, m.evidence_type_code, m.notes
FROM (VALUES
        ('EV_R211_ALPHA_SUPPORT', 'R211_ALPHA_RECORD',
         'The alpha reference records material designation A for the R2-11 reference assembly.',
         'SOURCE_OBSERVATION',
         'Represented source observation used as direct support; support is not confirmation of truth.'),
        ('EV_R211_BETA_CONTRADICTION', 'R211_BETA_RECORD',
         'The beta reference records a material designation that is incompatible with designation B for the R2-11 reference assembly.',
         'SOURCE_OBSERVATION',
         'Represented contradicting observation; the contradicted claim is retained, not deleted or adjudicated.'),
        ('EV_R211_BETA_QUALIFICATION', 'R211_BETA_RECORD',
         'The beta reference records that material designation C applies only to a delimited portion of the R2-11 reference assembly.',
         'SOURCE_OBSERVATION',
         'Represented qualifying observation; qualification is never rendered as direct support.'),
        ('EV_R211_SCHOLARSHIP_ONE_STATEMENT', 'R211_SCHOLARSHIP_ONE_RECORD',
         'Scholarly position one records, at the cited locator, that it reads the assembly as material designation D.',
         'SOURCE_OBSERVATION',
         'Cited source observation anchoring the interpretive claim; recording a position is not endorsing it.'),
        ('EV_R211_SCHOLARSHIP_TWO_STATEMENT', 'R211_SCHOLARSHIP_TWO_RECORD',
         'Scholarly position two records, at the cited locator, that it reads the assembly as material designation E.',
         'SOURCE_OBSERVATION',
         'Cited source observation anchoring the competing interpretive claim; recording a position is not endorsing it.'),
        ('EV_R211_SCHOLARSHIP_ONE', 'R211_SCHOLARSHIP_ONE_RECORD',
         'Scholarly position one reads the represented alpha and beta observations as designation D.',
         'ANALYTICAL_OBSERVATION',
         'Represented scholarly interpretation retained as a candidate only; no promotion to source fact.'),
        ('EV_R211_SCHOLARSHIP_TWO', 'R211_SCHOLARSHIP_TWO_RECORD',
         'Scholarly position two reads the same represented observations as designation E.',
         'ANALYTICAL_OBSERVATION',
         'Competing represented scholarly interpretation; the disagreement is preserved without selection.')
     ) AS m(evidence_key, source_record_key, observation, evidence_type_code, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key
ON CONFLICT (evidence_key) DO NOTHING;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key IN (
    'EV_R211_ALPHA_SUPPORT',
    'EV_R211_BETA_CONTRADICTION',
    'EV_R211_BETA_QUALIFICATION',
    'EV_R211_SCHOLARSHIP_ONE_STATEMENT',
    'EV_R211_SCHOLARSHIP_TWO_STATEMENT',
    'EV_R211_SCHOLARSHIP_ONE',
    'EV_R211_SCHOLARSHIP_TWO'
)
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('r211_reference_assembly', 'OBJECT', 'R2-11 Reference Assembly',
     'Bounded placeholder object used only as a stable research subject for mixed result-set regression coverage.')
ON CONFLICT (entity_key) DO NOTHING;

INSERT INTO typed_value (value_type_code, text_value)
SELECT 'TEXT', v.text_value
FROM (VALUES
        ('R2-11 material designation A'),
        ('R2-11 material designation B'),
        ('R2-11 material designation C'),
        ('R2-11 material designation D'),
        ('R2-11 material designation E'),
        ('R2-11 material designation A with delimited C portion')
     ) AS v(text_value)
WHERE NOT EXISTS (
    SELECT 1 FROM typed_value tv
    WHERE tv.value_type_code = 'TEXT' AND tv.text_value = v.text_value
);

INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT subject.entity_id, 'madeOfMaterial', tv.typed_value_id
FROM entity subject
JOIN typed_value tv ON tv.value_type_code = 'TEXT'
JOIN (VALUES
        ('R2-11 material designation A'),
        ('R2-11 material designation B'),
        ('R2-11 material designation C'),
        ('R2-11 material designation D'),
        ('R2-11 material designation E'),
        ('R2-11 material designation A with delimited C portion')
     ) AS v(text_value) ON v.text_value = tv.text_value
WHERE subject.entity_key = 'r211_reference_assembly'
  AND NOT EXISTS (
    SELECT 1 FROM proposition p
    WHERE p.subject_entity_id = subject.entity_id
      AND p.predicate = 'madeOfMaterial'
      AND p.object_typed_value_id = tv.typed_value_id
);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, m.claim_type_code, m.statement, m.notes
FROM (VALUES
        ('CLAIM_R211_DIRECT_SUPPORT', 'R2-11 material designation A', 'DIRECT_SOURCE_CLAIM',
         'The R2-11 reference assembly is recorded with material designation A.',
         'Direct source claim; represented support is not a verdict of truth.'),
        ('CLAIM_R211_CONTRADICTED', 'R2-11 material designation B', 'DIRECT_SOURCE_CLAIM',
         'The R2-11 reference assembly is recorded with material designation B.',
         'Retained claim whose only represented evidence relation is CONTRADICTS; the disagreement is preserved, not resolved.'),
        ('CLAIM_R211_QUALIFIED', 'R2-11 material designation C', 'DIRECT_SOURCE_CLAIM',
         'The R2-11 reference assembly is recorded with material designation C.',
         'Retained claim whose only represented evidence relation is QUALIFIES; qualification is not direct support.'),
        ('CLAIM_R211_INTERPRETATION_ONE', 'R2-11 material designation D', 'INTERPRETIVE_CLAIM',
         'Scholarly position one reads the represented record as material designation D.',
         'Represented scholarly interpretation; competing interpretations coexist without selection.'),
        ('CLAIM_R211_INTERPRETATION_TWO', 'R2-11 material designation E', 'INTERPRETIVE_CLAIM',
         'Scholarly position two reads the represented record as material designation E.',
         'Competing represented scholarly interpretation; neither interpretation is preferred or promoted.')
     ) AS m(claim_key, object_text_value, claim_type_code, statement, notes)
JOIN typed_value tv ON tv.value_type_code = 'TEXT' AND tv.text_value = m.object_text_value
JOIN entity subject ON subject.entity_key = 'r211_reference_assembly'
JOIN proposition p ON p.subject_entity_id = subject.entity_id
    AND p.predicate = 'madeOfMaterial'
    AND p.object_typed_value_id = tv.typed_value_id
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, m.relation_type_code, m.notes
FROM (VALUES
        ('CLAIM_R211_DIRECT_SUPPORT', 'EV_R211_ALPHA_SUPPORT', 'SUPPORTS',
         'Represented direct support from the alpha reference observation.'),
        ('CLAIM_R211_CONTRADICTED', 'EV_R211_BETA_CONTRADICTION', 'CONTRADICTS',
         'Represented contradicting observation from the beta reference.'),
        ('CLAIM_R211_QUALIFIED', 'EV_R211_BETA_QUALIFICATION', 'QUALIFIES',
         'Represented qualifying observation from the beta reference.'),
        ('CLAIM_R211_INTERPRETATION_ONE', 'EV_R211_SCHOLARSHIP_ONE_STATEMENT', 'SUPPORTS',
         'Cited source observation that scholarly position one states this reading; the interpretation remains a candidate.'),
        ('CLAIM_R211_INTERPRETATION_TWO', 'EV_R211_SCHOLARSHIP_TWO_STATEMENT', 'SUPPORTS',
         'Cited source observation that scholarly position two states this reading; the interpretation remains a candidate.'),
        ('CLAIM_R211_INTERPRETATION_ONE', 'EV_R211_SCHOLARSHIP_ONE', 'SUPPORTS',
         'Represented analytical provenance for scholarly position one; the interpretation remains a candidate.'),
        ('CLAIM_R211_INTERPRETATION_TWO', 'EV_R211_SCHOLARSHIP_TWO', 'SUPPORTS',
         'Represented analytical provenance for scholarly position two; the interpretation remains a candidate.')
     ) AS m(claim_key, evidence_key, relation_type_code, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key
ON CONFLICT DO NOTHING;

-- The two interpretations disagree in represented data. The disagreement is recorded,
-- never adjudicated, and neither claim is superseded or retracted by this relation.
INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT one.claim_id, two.claim_id, 'CONTRADICTS',
       'Represented scholarly disagreement retained without selection, promotion, or resolution.'
FROM claim one
JOIN claim two ON two.claim_key = 'CLAIM_R211_INTERPRETATION_TWO'
WHERE one.claim_key = 'CLAIM_R211_INTERPRETATION_ONE'
ON CONFLICT DO NOTHING;

INSERT INTO derivation (method, assumptions)
SELECT 'R2-11 represented composition derivation',
       'Composes one represented direct-support claim with one represented qualifying observation; the output is derived, never direct source support.'
WHERE NOT EXISTS (
    SELECT 1 FROM derivation d WHERE d.method = 'R2-11 represented composition derivation'
);

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes, derivation_id)
SELECT 'CLAIM_R211_DERIVED_COMPOSITION', p.proposition_id, 'DERIVED_CLAIM',
       'Composed representation: material designation A with a delimited designation C portion.',
       'Derived from persisted claim and evidence inputs; source-backed inputs never make the derived claim direct support.',
       d.derivation_id
FROM entity subject
JOIN typed_value tv ON tv.value_type_code = 'TEXT'
    AND tv.text_value = 'R2-11 material designation A with delimited C portion'
JOIN proposition p ON p.subject_entity_id = subject.entity_id
    AND p.predicate = 'madeOfMaterial'
    AND p.object_typed_value_id = tv.typed_value_id
JOIN derivation d ON d.method = 'R2-11 represented composition derivation'
WHERE subject.entity_key = 'r211_reference_assembly'
ON CONFLICT (claim_key) DO NOTHING;

INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, input_claim.claim_id,
       'Represented direct-support claim input, provenanced through the alpha dataset.'
FROM derivation d
JOIN claim input_claim ON input_claim.claim_key = 'CLAIM_R211_DIRECT_SUPPORT'
WHERE d.method = 'R2-11 represented composition derivation'
  AND NOT EXISTS (
    SELECT 1 FROM derivation_input di
    WHERE di.derivation_id = d.derivation_id AND di.input_claim_id = input_claim.claim_id
);

INSERT INTO derivation_input (derivation_id, input_evidence_id, notes)
SELECT d.derivation_id, input_evidence.evidence_id,
       'Represented qualifying evidence input, provenanced through the beta dataset.'
FROM derivation d
JOIN evidence input_evidence ON input_evidence.evidence_key = 'EV_R211_BETA_QUALIFICATION'
WHERE d.method = 'R2-11 represented composition derivation'
  AND NOT EXISTS (
    SELECT 1 FROM derivation_input di
    WHERE di.derivation_id = d.derivation_id AND di.input_evidence_id = input_evidence.evidence_id
);

COMMIT;
