-- Genesis 1-11 stress-test fixture.
--
-- No source text is reproduced. Source records are structural references only:
-- `raw_content` and `content_hash` are NULL, and citations carry locators without quoted text.
-- The recorded values are the widely published genealogical numerals of the Masoretic and
-- Septuagint textual traditions, which differ from one another; the fixture uses that real
-- divergence as its competing-claim case rather than inventing a disagreement.
--
-- The fixture is transactional and resets only reference-model data, so it is rerunnable.
BEGIN;
TRUNCATE source, entity, event, typed_value, derivation RESTART IDENTITY CASCADE;

INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('GEN_MT', 'Genesis, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of Genesis. No text is stored in this repository.'),
    ('GEN_LXX', 'Genesis, Septuagint textual tradition', 'SCRIPTURE',
     'Reference to the Septuagint tradition of Genesis. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, 'GEN_MT_REF', 'Genesis 1-11 reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and published numerals are recorded.',
       'Manually entered reference points',
       'Genealogical numerals recorded as typed values; no text imported.'
FROM source WHERE source_key = 'GEN_MT'
UNION ALL
SELECT source_id, 'GEN_LXX_REF', 'Genesis 1-11 reference points, Septuagint tradition',
       'Septuagint tradition', 'ref-1',
       'No source text reproduced; only locators and published numerals are recorded.',
       'Manually entered reference points',
       'Genealogical numerals recorded as typed values; no text imported.'
FROM source WHERE source_key = 'GEN_LXX';

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('GEN_MT_REF', 'MT_GEN_5_3', 'Genesis 5:3'),
        ('GEN_MT_REF', 'MT_GEN_5_6', 'Genesis 5:6'),
        ('GEN_MT_REF', 'MT_GEN_8_4', 'Genesis 8:4'),
        ('GEN_LXX_REF', 'LXX_GEN_5_3', 'Genesis 5:3'),
        ('GEN_LXX_REF', 'LXX_GEN_5_6', 'Genesis 5:6')
     ) AS r(dataset_key, source_record_key, source_location)
  ON r.dataset_key = d.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr;

INSERT INTO entity (entity_key, entity_type_code, canonical_name) VALUES
    ('adam', 'PERSON', 'Adam'), ('seth', 'PERSON', 'Seth'), ('enosh', 'PERSON', 'Enosh'),
    ('noah', 'PERSON', 'Noah'), ('ararat', 'PLACE', 'Ararat');

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('GEN_MT', 'mt-adam', 'Adam'), ('GEN_MT', 'mt-seth', 'Seth'),
        ('GEN_LXX', 'lxx-adam', 'Adam'), ('GEN_LXX', 'lxx-seth', 'Seth')
     ) AS m(source_key, source_identity_key, display_name)
JOIN source s ON s.source_key = m.source_key;
INSERT INTO source_identity_alternate_name (source_identity_id, alternate_name)
SELECT si.source_identity_id, n.alternate_name
FROM (VALUES ('lxx-adam', 'Adam (Greek transliteration)'),
             ('lxx-seth', 'Seth (Greek transliteration)')) AS n(source_identity_key, alternate_name)
JOIN source_identity si ON si.source_identity_key = n.source_identity_key;

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('seth_begetting', 'GENEALOGICAL', 'The begetting of Seth as recorded in the Genesis genealogies.'),
    ('enosh_begetting', 'GENEALOGICAL', 'The begetting of Enosh as recorded in the Genesis genealogies.'),
    ('ark_resting', 'OTHER', 'The resting of the ark as located in the Genesis flood narrative.');

INSERT INTO typed_value (value_type_code, numeric_value) VALUES
    ('YEAR', 130), ('YEAR', 230), ('YEAR', 105), ('YEAR', 205), ('YEAR', 235), ('YEAR', 435);

INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT s.entity_id, m.predicate, o.entity_id
FROM (VALUES ('adam', 'fatherOf', 'seth'), ('seth', 'fatherOf', 'enosh')) AS m(subject_key, predicate, object_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key;
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES ('adam', 'parentIn', 'seth_begetting'), ('seth', 'childIn', 'seth_begetting'),
             ('seth', 'parentIn', 'enosh_begetting'), ('enosh', 'childIn', 'enosh_begetting'),
             ('noah', 'subjectOf', 'ark_resting')) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;
INSERT INTO proposition (subject_event_id, predicate, object_entity_id)
SELECT e.event_id, 'occursAt', o.entity_id
FROM event e CROSS JOIN entity o
WHERE e.event_key = 'ark_resting' AND o.entity_key = 'ararat';
INSERT INTO proposition (subject_event_id, predicate, object_event_id)
SELECT a.event_id, 'precedes', b.event_id
FROM event a CROSS JOIN event b
WHERE a.event_key = 'seth_begetting' AND b.event_key = 'enosh_begetting';
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT s.entity_id, 'ageAtFatherhoodYears', t.typed_value_id
FROM (VALUES ('adam', 130), ('adam', 230), ('seth', 105), ('seth', 205)) AS m(subject_key, years)
JOIN entity s ON s.entity_key = m.subject_key
JOIN typed_value t ON t.numeric_value = m.years;
INSERT INTO proposition (subject_event_id, predicate, object_typed_value_id)
SELECT e.event_id, 'yearsFromCreation', t.typed_value_id
FROM (VALUES ('enosh_begetting', 235), ('enosh_begetting', 435)) AS m(event_key, years)
JOIN event e ON e.event_key = m.event_key
JOIN typed_value t ON t.numeric_value = m.years;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_ADAM_FATHER_SETH', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Genesis 5:3 records Seth as begotten by Adam.'
FROM proposition p JOIN entity s ON s.entity_id = p.subject_entity_id
WHERE p.predicate = 'fatherOf' AND s.entity_key = 'adam'
UNION ALL
SELECT 'CLAIM_SETH_FATHER_ENOSH', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Genesis 5:6 records Enosh as begotten by Seth.'
FROM proposition p JOIN entity s ON s.entity_id = p.subject_entity_id
WHERE p.predicate = 'fatherOf' AND s.entity_key = 'seth';

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('adam', 'parentIn', 'seth_begetting', 'CLAIM_ADAM_PARENT_SETH_BEGETTING',
         'Adam is the parent participant in the begetting of Seth.'),
        ('seth', 'childIn', 'seth_begetting', 'CLAIM_SETH_CHILD_SETH_BEGETTING',
         'Seth is the child participant in the begetting of Seth.'),
        ('seth', 'parentIn', 'enosh_begetting', 'CLAIM_SETH_PARENT_ENOSH_BEGETTING',
         'Seth is the parent participant in the begetting of Enosh.'),
        ('enosh', 'childIn', 'enosh_begetting', 'CLAIM_ENOSH_CHILD_ENOSH_BEGETTING',
         'Enosh is the child participant in the begetting of Enosh.'),
        ('noah', 'subjectOf', 'ark_resting', 'CLAIM_NOAH_ARK_RESTING',
         'Noah is the subject of the ark-resting event.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_ARK_RESTING_ARARAT', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'Genesis 8:4 locates the resting of the ark on the mountains of Ararat.'
FROM proposition p WHERE p.predicate = 'occursAt'
UNION ALL
SELECT 'CLAIM_SETH_BEFORE_ENOSH', p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       'The begetting of Seth precedes the begetting of Enosh in the genealogy.'
FROM proposition p WHERE p.predicate = 'precedes';

-- Competing chronology claims: the two textual traditions record different numerals.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('adam', 130, 'CLAIM_MT_ADAM_AGE_AT_SETH',
         'The Masoretic tradition records Adam as 130 years old at the begetting of Seth.'),
        ('adam', 230, 'CLAIM_LXX_ADAM_AGE_AT_SETH',
         'The Septuagint tradition records Adam as 230 years old at the begetting of Seth.'),
        ('seth', 105, 'CLAIM_MT_SETH_AGE_AT_ENOSH',
         'The Masoretic tradition records Seth as 105 years old at the begetting of Enosh.'),
        ('seth', 205, 'CLAIM_LXX_SETH_AGE_AT_ENOSH',
         'The Septuagint tradition records Seth as 205 years old at the begetting of Enosh.')
     ) AS m(subject_key, years, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN typed_value t ON t.numeric_value = m.years
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_typed_value_id = t.typed_value_id;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT m.evidence_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION'
FROM (VALUES
        ('MT_GEN_5_3', 'EV_MT_GEN_5_3',
         'Genesis 5:3 in the Masoretic tradition records the begetting of Seth by Adam at 130 years.'),
        ('LXX_GEN_5_3', 'EV_LXX_GEN_5_3',
         'Genesis 5:3 in the Septuagint tradition records the begetting of Seth by Adam at 230 years.'),
        ('MT_GEN_5_6', 'EV_MT_GEN_5_6',
         'Genesis 5:6 in the Masoretic tradition records the begetting of Enosh by Seth at 105 years.'),
        ('LXX_GEN_5_6', 'EV_LXX_GEN_5_6',
         'Genesis 5:6 in the Septuagint tradition records the begetting of Enosh by Seth at 205 years.'),
        ('MT_GEN_8_4', 'EV_MT_GEN_8_4',
         'Genesis 8:4 records the ark as resting on the mountains of Ararat.')
     ) AS m(source_record_key, evidence_key, observation)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN citation c ON c.source_record_id = sr.source_record_id;

-- Evidence reuse, multi-evidence claims, and coexisting support and contradiction.
INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, m.relation_type_code, m.notes
FROM (VALUES
        ('CLAIM_ADAM_FATHER_SETH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Both traditions record the same parentage.'),
        ('CLAIM_ADAM_FATHER_SETH', 'EV_LXX_GEN_5_3', 'SUPPORTS', 'The traditions differ on the numeral, not the parentage.'),
        ('CLAIM_SETH_FATHER_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Both traditions record the same parentage.'),
        ('CLAIM_SETH_FATHER_ENOSH', 'EV_LXX_GEN_5_6', 'SUPPORTS', 'The traditions differ on the numeral, not the parentage.'),
        ('CLAIM_ADAM_PARENT_SETH_BEGETTING', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_SETH_CHILD_SETH_BEGETTING', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_SETH_PARENT_ENOSH_BEGETTING', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_ENOSH_CHILD_ENOSH_BEGETTING', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_NOAH_ARK_RESTING', 'EV_MT_GEN_8_4', 'SUPPORTS', 'The narrative names Noah as the subject.'),
        ('CLAIM_ARK_RESTING_ARARAT', 'EV_MT_GEN_8_4', 'SUPPORTS', 'The verse gives the location.'),
        ('CLAIM_SETH_BEFORE_ENOSH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The genealogy orders the two begettings.'),
        ('CLAIM_SETH_BEFORE_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'The genealogy orders the two begettings.'),
        ('CLAIM_MT_ADAM_AGE_AT_SETH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The Masoretic numeral is 130.'),
        ('CLAIM_MT_ADAM_AGE_AT_SETH', 'EV_LXX_GEN_5_3', 'CONTRADICTS', 'The Septuagint numeral is 230.'),
        ('CLAIM_LXX_ADAM_AGE_AT_SETH', 'EV_LXX_GEN_5_3', 'SUPPORTS', 'The Septuagint numeral is 230.'),
        ('CLAIM_LXX_ADAM_AGE_AT_SETH', 'EV_MT_GEN_5_3', 'CONTRADICTS', 'The Masoretic numeral is 130.'),
        ('CLAIM_MT_SETH_AGE_AT_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'The Masoretic numeral is 105.'),
        ('CLAIM_MT_SETH_AGE_AT_ENOSH', 'EV_LXX_GEN_5_6', 'CONTRADICTS', 'The Septuagint numeral is 205.'),
        ('CLAIM_LXX_SETH_AGE_AT_ENOSH', 'EV_LXX_GEN_5_6', 'SUPPORTS', 'The Septuagint numeral is 205.'),
        ('CLAIM_LXX_SETH_AGE_AT_ENOSH', 'EV_MT_GEN_5_6', 'CONTRADICTS', 'The Masoretic numeral is 105.')
     ) AS m(claim_key, evidence_key, relation_type_code, notes)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key;

INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'CONTRADICTS', m.notes
FROM (VALUES
        ('CLAIM_LXX_ADAM_AGE_AT_SETH', 'CLAIM_MT_ADAM_AGE_AT_SETH',
         'The traditions record different ages for Adam at the begetting of Seth.'),
        ('CLAIM_LXX_SETH_AGE_AT_ENOSH', 'CLAIM_MT_SETH_AGE_AT_ENOSH',
         'The traditions record different ages for Seth at the begetting of Enosh.')
     ) AS m(claim_key, related_claim_key, notes)
JOIN claim a ON a.claim_key = m.claim_key
JOIN claim b ON b.claim_key = m.related_claim_key;

-- Competing derived chronology: the same method over different source claims.
INSERT INTO derivation (method, assumptions) VALUES
    ('Cumulative addition of recorded begetting ages along the Adam-Seth-Enosh line',
     'Masoretic numerals only; ages are elapsed whole years; no gaps in the genealogy.'),
    ('Cumulative addition of recorded begetting ages along the Adam-Seth-Enosh line',
     'Septuagint numerals only; ages are elapsed whole years; no gaps in the genealogy.');

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_MT_ENOSH_YEAR_DERIVED', p.proposition_id, 'DERIVED_CLAIM',
       'On Masoretic numerals the begetting of Enosh falls 235 years from creation.', d.derivation_id
FROM proposition p JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
CROSS JOIN derivation d
WHERE p.predicate = 'yearsFromCreation' AND t.numeric_value = 235 AND d.assumptions LIKE 'Masoretic%'
UNION ALL
SELECT 'CLAIM_LXX_ENOSH_YEAR_DERIVED', p.proposition_id, 'DERIVED_CLAIM',
       'On Septuagint numerals the begetting of Enosh falls 435 years from creation.', d.derivation_id
FROM proposition p JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
CROSS JOIN derivation d
WHERE p.predicate = 'yearsFromCreation' AND t.numeric_value = 435 AND d.assumptions LIKE 'Septuagint%';

INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, c.claim_id, m.notes
FROM (VALUES
        ('Masoretic%', 'CLAIM_MT_ADAM_AGE_AT_SETH', 'First interval.'),
        ('Masoretic%', 'CLAIM_MT_SETH_AGE_AT_ENOSH', 'Second interval.'),
        ('Septuagint%', 'CLAIM_LXX_ADAM_AGE_AT_SETH', 'First interval.'),
        ('Septuagint%', 'CLAIM_LXX_SETH_AGE_AT_ENOSH', 'Second interval.')
     ) AS m(assumption_pattern, claim_key, notes)
JOIN derivation d ON d.assumptions LIKE m.assumption_pattern
JOIN claim c ON c.claim_key = m.claim_key;

INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'CONTRADICTS',
       'The derived chronologies disagree because their source numerals disagree.'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_LXX_ENOSH_YEAR_DERIVED' AND b.claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED';

-- Reconciliation: source-specific identities remain distinct from the canonical entity.
INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-adam', 'adam', 0.9900, 'The Masoretic genealogy identifies this figure at Genesis 5:3.', 'EV_MT_GEN_5_3'),
        ('mt-seth', 'seth', 0.9900, 'The Masoretic genealogy identifies this figure at Genesis 5:3.', 'EV_MT_GEN_5_3'),
        ('lxx-adam', 'adam', 0.9500, 'The Septuagint genealogy identifies the same genealogical position.', 'EV_LXX_GEN_5_3'),
        ('lxx-seth', 'seth', 0.9500, 'The Septuagint genealogy identifies the same genealogical position.', 'EV_LXX_GEN_5_3')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;
COMMIT;
