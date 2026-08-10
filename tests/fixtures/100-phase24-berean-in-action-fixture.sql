-- Phase 24 reproducible Ark/Genesis demonstration slice.
--
-- Extends the accepted Phase 19 baseline in place using existing architecture only.
-- Adds two source-backed Ark-content attestations (1 Kings 8:9 and Hebrews 9:4),
-- preserving source distinctions without contradiction/compliance/causation inference.
-- No source text/quotation/hash is stored; only locators and structured assertions.
BEGIN;

-- 1) Sources and datasets (reference-point convention only).
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('1KI_MT', '1 Kings, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic textual tradition of 1 Kings. No source text is stored in this repository.'),
    ('HEB_GNT', 'Hebrews, Greek textual tradition', 'SCRIPTURE',
     'Reference to the Greek textual tradition of Hebrews. No source text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT s.source_id, d.dataset_key, d.name, d.edition_label, 'ref-1',
       'No source text reproduced; only locators and selected source-backed content are recorded.',
       'Manually entered reference points',
       d.transformation_notes
FROM source s
JOIN (VALUES
        ('1KI_MT', '1KI_MT_REF', '1 Kings reference points, Masoretic tradition', 'Masoretic tradition',
         '1 Kings 8:9 Ark-content reference recorded using existing containsContent semantics only.'),
        ('HEB_GNT', 'HEB_GNT_REF', 'Hebrews reference points, Greek textual tradition', 'Greek textual tradition',
         'Hebrews 9:4 Ark-content references recorded using existing containsContent semantics only.')
     ) AS d(source_key, dataset_key, name, edition_label, transformation_notes)
  ON s.source_key = d.source_key;

-- 2) Exact locators and citations.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('1KI_MT_REF', 'MT_1KI_8_9', '1 Kings 8:9'),
        ('HEB_GNT_REF', 'GNT_HEB_9_4', 'Hebrews 9:4')
     ) AS r(dataset_key, source_record_key, source_location)
  ON d.dataset_key = r.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN ('MT_1KI_8_9', 'GNT_HEB_9_4');

-- 3) Additional canonical entities needed for Hebrews 9:4 source-backed content.
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('golden_jar_manna', 'OBJECT', 'golden jar holding manna',
     'The golden jar with manna referenced in Hebrews 9:4.'),
    ('aarons_rod_budded', 'OBJECT', 'Aaron''s rod that budded',
     'Aaron''s rod that budded, referenced in Hebrews 9:4.');

-- 4) Propositions: reuse existing Ark->tablets proposition; add two additional Ark content propositions.
INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT ark.entity_id, 'containsContent', obj.entity_id
FROM entity ark
JOIN entity obj ON obj.entity_key IN ('golden_jar_manna', 'aarons_rod_budded')
WHERE ark.entity_key = 'ark_of_covenant';

-- 5) Claims.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, notes)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement, m.notes
FROM (VALUES
        ('ark_of_covenant', 'containsContent', 'tablets_of_testimony',
         'CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS',
         '1 Kings 8:9 records the tablets in the ark at the selected locator.',
         'This direct claim records source-backed Ark/tablets attestation only; no exclusivity or contradiction judgment is inferred.'),
        ('ark_of_covenant', 'containsContent', 'tablets_of_testimony',
         'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS',
         'Hebrews 9:4 records tablets of the covenant in the ark.',
         'Coexists with other source-backed content claims without automatic harmonization or contradiction classification.'),
        ('ark_of_covenant', 'containsContent', 'golden_jar_manna',
         'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA',
         'Hebrews 9:4 records a golden jar holding manna in relation to the ark.',
         'Recorded as source-backed attestation only; no temporal or doctrinal reconciliation is inferred.'),
        ('ark_of_covenant', 'containsContent', 'aarons_rod_budded',
         'CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD',
         'Hebrews 9:4 records Aaron''s rod that budded in relation to the ark.',
         'Recorded as source-backed attestation only; no automatic contradiction or compliance finding is inferred.')
     ) AS m(subject_key, predicate, object_key, claim_key, statement, notes)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_entity_id = o.entity_id
                  AND p.predicate = m.predicate;

-- 6) Evidence and citation links.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT m.evidence_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', m.notes
FROM (VALUES
        ('EV_MT_1KI_8_9',
         'MT_1KI_8_9',
         '1 Kings 8:9 records the tablets in the ark at this locator.',
         'Bounded source observation; no source text is stored.'),
        ('EV_GNT_HEB_9_4',
         'GNT_HEB_9_4',
         'Hebrews 9:4 records the ark in relation to tablets, a golden jar holding manna, and Aaron''s rod that budded.',
         'Bounded source observation; no source text is stored.')
     ) AS m(evidence_key, source_record_key, observation, notes)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT ev.evidence_id, ci.citation_id
FROM evidence ev
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
WHERE ev.evidence_key IN ('EV_MT_1KI_8_9', 'EV_GNT_HEB_9_4');

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, ev.evidence_id, 'SUPPORTS', 'Direct source observation support.'
FROM (VALUES
        ('CLAIM_MT_1KI_8_9_ARK_CONTAINS_TABLETS', 'EV_MT_1KI_8_9'),
        ('CLAIM_GNT_HEB_9_4_ARK_CONTAINS_TABLETS', 'EV_GNT_HEB_9_4'),
        ('CLAIM_GNT_HEB_9_4_ARK_CONTAINS_GOLDEN_JAR_MANNA', 'EV_GNT_HEB_9_4'),
        ('CLAIM_GNT_HEB_9_4_ARK_CONTAINS_AARONS_ROD', 'EV_GNT_HEB_9_4')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

-- 7) Source identities and evidence-backed reconciliation mappings.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, m.source_identity_key, m.display_name
FROM (VALUES
        ('1KI_MT', 'mt-tablets-1ki-8-9', 'the two tablets'),
        ('HEB_GNT', 'gnt-tablets-heb-9-4', 'the tablets of the covenant'),
        ('HEB_GNT', 'gnt-golden-jar-manna-heb-9-4', 'golden jar holding manna'),
        ('HEB_GNT', 'gnt-aarons-rod-heb-9-4', 'Aaron''s rod that budded')
     ) AS m(source_key, source_identity_key, display_name)
JOIN source s ON s.source_key = m.source_key;

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', m.confidence, m.justification, ev.evidence_id
FROM (VALUES
        ('mt-tablets-1ki-8-9', 'tablets_of_testimony', 0.9800,
         '1 Kings 8:9 source identity refers to the tablets in the ark.', 'EV_MT_1KI_8_9'),
        ('gnt-tablets-heb-9-4', 'tablets_of_testimony', 0.9800,
         'Hebrews 9:4 source identity refers to the tablets in the ark.', 'EV_GNT_HEB_9_4'),
        ('gnt-golden-jar-manna-heb-9-4', 'golden_jar_manna', 0.9800,
         'Hebrews 9:4 source identity refers to the golden jar holding manna.', 'EV_GNT_HEB_9_4'),
        ('gnt-aarons-rod-heb-9-4', 'aarons_rod_budded', 0.9800,
         'Hebrews 9:4 source identity refers to Aaron''s rod that budded.', 'EV_GNT_HEB_9_4')
     ) AS m(source_identity_key, entity_key, confidence, justification, evidence_key)
JOIN source_identity si ON si.source_identity_key = m.source_identity_key
JOIN entity en ON en.entity_key = m.entity_key
JOIN evidence ev ON ev.evidence_key = m.evidence_key;

COMMIT;
