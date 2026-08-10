-- Phase 16 rich persistent-artifact construction fixture: Noah's Ark and the Ark of the
-- Covenant.
--
-- This fixture extends the Genesis 1-11 fixture (020) and the validation-only Ark of the
-- Covenant entity (050) in place; it does not truncate prior phases. No upstream/external text
-- is imported here. Source records follow the repository's established "manually entered
-- reference point" convention already used for Genesis 1-11 and Genesis 5/8: the locator is
-- recorded, but no verbatim source text, hash, or quotation is stored. The recorded claims
-- reflect the well-known published content of these public-domain scriptural locators, exactly
-- as prior phases already did for Genesis 1 and the Genesis 5 genealogy.
--
-- Population scope:
--   Noah's Ark:        Genesis 6:14 (material/covering/rooms), Genesis 6:15 (dimensions),
--                       Genesis 6:16 (door/window components), Genesis 6:22 (construction
--                       completed), Genesis 7:7 (entering event). Genesis 8:4 (resting) is
--                       already populated and is reused unchanged.
--   Ark of the Covenant: Exodus 25:10 (dimensions/material), Exodus 25:11 (gold overlay),
--                       Exodus 25:12 (rings), Exodus 25:13 (poles, material/overlay),
--                       Exodus 25:17 (mercy seat dimensions/material), Exodus 25:18 (cherubim),
--                       Exodus 37:1 (Bezalel's completed construction), Exodus 40:20 (placing
--                       the tablets of the testimony inside, and setting the poles/mercy seat),
--                       Deuteronomy 10:3 (Moses' first-person account of making the ark).
--
-- Instruction vs completed construction: Genesis 6:14-16 and Exodus 25:10-22 record commanded
-- specifications (event_type INSTRUCTION); they are never treated as evidence of completed
-- construction. Genesis 6:22 and Exodus 37:1 record the distinct, later, completed-construction
-- act (event_type CONSTRUCTION) with its own builder. Recipient of instruction (Noah; Moses) and
-- builder/craftsman (Noah; Bezalel) are kept as separate roles using the existing `subjectOf`
-- predicate for recipients/primary subjects and the new `builderIn` predicate for the builder
-- role, never conflating the two.
--
-- Source difference preserved, not resolved: Exodus 37:1 names Bezalel as builder of the Ark of
-- the Covenant; Deuteronomy 10:3 has Moses speak in the first person of personally making an ark.
-- Both are recorded as independent, source-backed, non-merged claims about the same
-- `ark_covenant_construction` event, joined by an explicit claim_relation rather than silently
-- reconciled.
--
-- Materials distinguish primary material (`madeOfMaterial`) from covering/overlay
-- (`overlaidWithMaterial`); dimensions preserve the source unit via unit-suffixed predicates
-- (`lengthCubits`/`widthCubits`/`heightCubits`), consistent with the existing
-- `ageAtDeathYears`/`yearsFromCreation` unit-in-predicate-name convention. No modern-unit
-- conversion or derivation is added.
--
-- Handling/transport: Exodus 25:15's requirement that the poles remain in the rings and not be
-- withdrawn is a source-recorded restriction on future handling, not an ordinary event
-- participation fact. Forcing it into `participatesIn` would misrepresent a standing requirement
-- as a single occurrence. This fixture therefore does not encode that restriction as a claim; it
-- is recorded only as a documented semantic precision gap in the Phase 16 report.
BEGIN;

-- 1. New sources and datasets for Exodus and Deuteronomy, following the existing
--    "reference point" pattern used by GEN_MT/GEN_MT_REF.
INSERT INTO source (source_key, name, source_type_code, description) VALUES
    ('EXO_MT', 'Exodus, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of Exodus. No text is stored in this repository.'),
    ('DEU_MT', 'Deuteronomy, Masoretic textual tradition', 'SCRIPTURE',
     'Reference to the Masoretic tradition of Deuteronomy. No text is stored in this repository.');

INSERT INTO dataset (source_id, dataset_key, name, edition_label, version,
                     license_status, acquisition_method, transformation_notes)
SELECT source_id, 'EXO_MT_REF', 'Exodus reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and published construction/dimension content are recorded.',
       'Manually entered reference points',
       'Ark of the Covenant construction/dimension/material data recorded as typed values; no text imported.'
FROM source WHERE source_key = 'EXO_MT'
UNION ALL
SELECT source_id, 'DEU_MT_REF', 'Deuteronomy reference points, Masoretic tradition',
       'Masoretic tradition', 'ref-1',
       'No source text reproduced; only locators and published content are recorded.',
       'Manually entered reference points',
       'Deuteronomy''s first-person builder account recorded as a distinct competing claim; no text imported.'
FROM source WHERE source_key = 'DEU_MT';

-- 2. New source records: additional Genesis locators in the existing GEN_MT_REF dataset, plus
--    the new Exodus/Deuteronomy datasets.
INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
        ('GEN_MT_REF', 'MT_GEN_6_14', 'Genesis 6:14'),
        ('GEN_MT_REF', 'MT_GEN_6_15', 'Genesis 6:15'),
        ('GEN_MT_REF', 'MT_GEN_6_16', 'Genesis 6:16'),
        ('GEN_MT_REF', 'MT_GEN_6_22', 'Genesis 6:22'),
        ('GEN_MT_REF', 'MT_GEN_7_7', 'Genesis 7:7'),
        ('EXO_MT_REF', 'MT_EXO_25_10', 'Exodus 25:10'),
        ('EXO_MT_REF', 'MT_EXO_25_11', 'Exodus 25:11'),
        ('EXO_MT_REF', 'MT_EXO_25_12', 'Exodus 25:12'),
        ('EXO_MT_REF', 'MT_EXO_25_13', 'Exodus 25:13'),
        ('EXO_MT_REF', 'MT_EXO_25_17', 'Exodus 25:17'),
        ('EXO_MT_REF', 'MT_EXO_25_18', 'Exodus 25:18'),
        ('EXO_MT_REF', 'MT_EXO_37_1', 'Exodus 37:1'),
        ('EXO_MT_REF', 'MT_EXO_40_20', 'Exodus 40:20'),
        ('DEU_MT_REF', 'MT_DEU_10_3', 'Deuteronomy 10:3')
     ) AS r(dataset_key, source_record_key, source_location)
  ON r.dataset_key = d.dataset_key;

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr
WHERE sr.source_record_key IN (
    'MT_GEN_6_14', 'MT_GEN_6_15', 'MT_GEN_6_16', 'MT_GEN_6_22', 'MT_GEN_7_7',
    'MT_EXO_25_10', 'MT_EXO_25_11', 'MT_EXO_25_12', 'MT_EXO_25_13', 'MT_EXO_25_17',
    'MT_EXO_25_18', 'MT_EXO_37_1', 'MT_EXO_40_20', 'MT_DEU_10_3');

-- 3. New entities. Each qualifies as a persistent, source-identified referent that recurs or is
--    individually addressed across more than one verse/assertion (rings, poles, mercy seat, and
--    cherubim are each addressed again in Exodus 37 and/or Exodus 40; Moses and Bezalel are named
--    persons; the door, window, and tablets are individually specified, distinct components).
INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('moses', 'PERSON', 'Moses', NULL),
    ('bezalel', 'PERSON', 'Bezalel', NULL),
    ('door_noahs_ark', 'OBJECT', 'door of the ark', 'The door specified for Noah''s Ark in Genesis 6:16.'),
    ('window_noahs_ark', 'OBJECT', 'window of the ark', 'The opening for light specified for Noah''s Ark in Genesis 6:16.'),
    ('mercy_seat', 'OBJECT', 'mercy seat', 'The cover of the Ark of the Covenant, specified in Exodus 25:17.'),
    ('cherubim_kapporet', 'OBJECT', 'cherubim of the mercy seat', 'The two gold cherubim of one piece with the mercy seat, specified in Exodus 25:18.'),
    ('rings_ark_covenant', 'OBJECT', 'gold rings of the ark', 'The four gold rings specified in Exodus 25:12.'),
    ('poles_ark_covenant', 'OBJECT', 'poles of the ark', 'The carrying poles specified in Exodus 25:13, later placed in Exodus 40:20.'),
    ('tablets_of_testimony', 'OBJECT', 'tablets of the testimony', 'The tablets placed inside the Ark of the Covenant, per Exodus 40:20.');

-- 4. New events. INSTRUCTION events record a commanded specification; CONSTRUCTION events record
--    the source's own assertion of completed building. They are never merged.
INSERT INTO event (event_key, event_type_code, description) VALUES
    ('ark_building_instruction', 'INSTRUCTION', 'Genesis 6:14-16 commanded specification for building the ark; not itself an assertion of completed construction.'),
    ('ark_construction_completed', 'CONSTRUCTION', 'Genesis 6:22 records that Noah did according to all that was commanded.'),
    ('ark_entering', 'OTHER', 'Genesis 7:7 records Noah and his household entering the ark.'),
    ('ark_covenant_instruction', 'INSTRUCTION', 'Exodus 25:10-22 commanded specification for building the Ark of the Covenant; not itself an assertion of completed construction.'),
    ('ark_covenant_construction', 'CONSTRUCTION', 'Completed construction of the Ark of the Covenant, as independently recorded by Exodus 37:1 (Bezalel) and Deuteronomy 10:3 (Moses'' first-person account).'),
    ('ark_covenant_contents_placement', 'OTHER', 'Exodus 40:20 records the testimony placed inside the ark and the poles and mercy seat set upon it.');

-- 5. Propositions: entity/event predicates.
INSERT INTO proposition (subject_entity_id, predicate, object_event_id)
SELECT s.entity_id, m.predicate, e.event_id
FROM (VALUES
        ('noah', 'subjectOf', 'ark_building_instruction'),
        ('noahs_ark', 'participatesIn', 'ark_building_instruction'),
        ('noah', 'builderIn', 'ark_construction_completed'),
        ('noahs_ark', 'subjectOf', 'ark_construction_completed'),
        ('noah', 'participatesIn', 'ark_entering'),
        ('noahs_ark', 'participatesIn', 'ark_entering'),
        ('moses', 'subjectOf', 'ark_covenant_instruction'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_instruction'),
        ('bezalel', 'builderIn', 'ark_covenant_construction'),
        ('moses', 'builderIn', 'ark_covenant_construction'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_construction'),
        ('moses', 'participatesIn', 'ark_covenant_contents_placement'),
        ('tablets_of_testimony', 'participatesIn', 'ark_covenant_contents_placement'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_contents_placement')
     ) AS m(subject_key, predicate, event_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key;

-- 6. Propositions: entity/entity component and content predicates.
INSERT INTO proposition (subject_entity_id, predicate, object_entity_id)
SELECT s.entity_id, m.predicate, o.entity_id
FROM (VALUES
        ('noahs_ark', 'hasComponent', 'door_noahs_ark'),
        ('noahs_ark', 'hasComponent', 'window_noahs_ark'),
        ('ark_of_covenant', 'hasComponent', 'rings_ark_covenant'),
        ('ark_of_covenant', 'hasComponent', 'poles_ark_covenant'),
        ('ark_of_covenant', 'hasComponent', 'mercy_seat'),
        ('mercy_seat', 'hasComponent', 'cherubim_kapporet'),
        ('ark_of_covenant', 'containsContent', 'tablets_of_testimony')
     ) AS m(subject_key, predicate, object_key)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key;

-- 7. Propositions: dimensions (unit-preserving, cubits) and materials (made-of vs overlay), each
--    given its own typed_value row so that repeated numeral/text values across different
--    subjects (e.g. two entities both "acacia wood") are never ambiguously joined.
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 300) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'lengthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 50) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'widthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 30) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'heightCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'gopher wood') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'pitch') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'overlaidWithMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'noahs_ark';

WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 2.5) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'lengthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'ark_of_covenant';
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 1.5) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'widthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'ark_of_covenant';
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 1.5) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'heightCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'ark_of_covenant';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'acacia wood') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'ark_of_covenant';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'pure gold') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'overlaidWithMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'ark_of_covenant';

WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'acacia wood') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'poles_ark_covenant';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'gold') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'overlaidWithMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'poles_ark_covenant';

WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 2.5) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'lengthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'mercy_seat';
WITH v AS (INSERT INTO typed_value (value_type_code, numeric_value) VALUES ('DECIMAL', 1.5) RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'widthCubits', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'mercy_seat';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'pure gold') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'mercy_seat';
WITH v AS (INSERT INTO typed_value (value_type_code, text_value) VALUES ('TEXT', 'hammered gold') RETURNING typed_value_id)
INSERT INTO proposition (subject_entity_id, predicate, object_typed_value_id)
SELECT e.entity_id, 'madeOfMaterial', v.typed_value_id FROM entity e, v WHERE e.entity_key = 'cherubim_kapporet';

-- 8. Claims: direct source claims for every proposition created above, plus the existing
--    predicate-driven claim keys.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('noah', 'subjectOf', 'ark_building_instruction', 'CLAIM_NOAH_RECIPIENT_ARK_INSTRUCTION',
         'Genesis 6:14 presents Noah as the recipient of the ark-building instruction.'),
        ('noahs_ark', 'participatesIn', 'ark_building_instruction', 'CLAIM_ARK_PARTICIPANT_INSTRUCTION',
         'Genesis 6:14 presents the ark as the object of the building instruction.'),
        ('noah', 'builderIn', 'ark_construction_completed', 'CLAIM_NOAH_BUILDER_ARK',
         'Genesis 6:22 presents Noah as having done all that was commanded, i.e. as builder.'),
        ('noahs_ark', 'subjectOf', 'ark_construction_completed', 'CLAIM_ARK_SUBJECT_CONSTRUCTION',
         'Genesis 6:22 presents the ark as the completed subject of the construction.'),
        ('noah', 'participatesIn', 'ark_entering', 'CLAIM_NOAH_ENTERING_ARK',
         'Genesis 7:7 presents Noah as entering the ark.'),
        ('noahs_ark', 'participatesIn', 'ark_entering', 'CLAIM_ARK_PARTICIPANT_ENTERING',
         'Genesis 7:7 presents the ark as the object entered.'),
        ('moses', 'subjectOf', 'ark_covenant_instruction', 'CLAIM_MOSES_RECIPIENT_ARK_COVENANT_INSTRUCTION',
         'Exodus 25:10 presents Moses as the recipient of the Ark of the Covenant building instruction.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_instruction', 'CLAIM_ARK_COVENANT_PARTICIPANT_INSTRUCTION',
         'Exodus 25:10 presents the ark as the object of the building instruction.'),
        ('bezalel', 'builderIn', 'ark_covenant_construction', 'CLAIM_BEZALEL_BUILDER_ARK_COVENANT',
         'Exodus 37:1 presents Bezalel as builder of the Ark of the Covenant.'),
        ('moses', 'builderIn', 'ark_covenant_construction', 'CLAIM_MOSES_BUILDER_ARK_COVENANT',
         'Deuteronomy 10:3 presents Moses, in the first person, as builder of an ark.'),
        ('ark_of_covenant', 'subjectOf', 'ark_covenant_construction', 'CLAIM_ARK_COVENANT_SUBJECT_CONSTRUCTION',
         'Exodus 37:1 presents the ark as the completed subject of the construction.'),
        ('moses', 'participatesIn', 'ark_covenant_contents_placement', 'CLAIM_MOSES_PLACES_TESTIMONY',
         'Exodus 40:20 presents Moses as the one who places the testimony in the ark.'),
        ('tablets_of_testimony', 'participatesIn', 'ark_covenant_contents_placement', 'CLAIM_TESTIMONY_PARTICIPANT_PLACEMENT',
         'Exodus 40:20 presents the testimony as the object placed.'),
        ('ark_of_covenant', 'participatesIn', 'ark_covenant_contents_placement', 'CLAIM_ARK_COVENANT_PARTICIPANT_PLACEMENT',
         'Exodus 40:20 presents the ark as the object receiving the testimony.')
     ) AS m(subject_key, predicate, event_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN event e ON e.event_key = m.event_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_event_id = e.event_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('noahs_ark', 'hasComponent', 'door_noahs_ark', 'CLAIM_ARK_HAS_DOOR',
         'Genesis 6:16 specifies a door for the ark.'),
        ('noahs_ark', 'hasComponent', 'window_noahs_ark', 'CLAIM_ARK_HAS_WINDOW',
         'Genesis 6:16 specifies a window/opening for the ark.'),
        ('ark_of_covenant', 'hasComponent', 'rings_ark_covenant', 'CLAIM_ARK_COVENANT_HAS_RINGS',
         'Exodus 25:12 specifies four gold rings for the ark.'),
        ('ark_of_covenant', 'hasComponent', 'poles_ark_covenant', 'CLAIM_ARK_COVENANT_HAS_POLES',
         'Exodus 25:13 specifies poles for carrying the ark.'),
        ('ark_of_covenant', 'hasComponent', 'mercy_seat', 'CLAIM_ARK_COVENANT_HAS_MERCY_SEAT',
         'Exodus 25:17 specifies a mercy seat as the cover of the ark.'),
        ('mercy_seat', 'hasComponent', 'cherubim_kapporet', 'CLAIM_MERCY_SEAT_HAS_CHERUBIM',
         'Exodus 25:18 specifies two cherubim of one piece with the mercy seat.'),
        ('ark_of_covenant', 'containsContent', 'tablets_of_testimony', 'CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY',
         'Exodus 40:20 records the testimony placed inside the ark.')
     ) AS m(subject_key, predicate, object_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.object_entity_id = o.entity_id
                  AND p.predicate = m.predicate;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('noahs_ark', 'lengthCubits', 300, 'CLAIM_ARK_LENGTH_CUBITS',
         'Genesis 6:15 records the ark''s length as 300 cubits.'),
        ('noahs_ark', 'widthCubits', 50, 'CLAIM_ARK_WIDTH_CUBITS',
         'Genesis 6:15 records the ark''s width as 50 cubits.'),
        ('noahs_ark', 'heightCubits', 30, 'CLAIM_ARK_HEIGHT_CUBITS',
         'Genesis 6:15 records the ark''s height as 30 cubits.'),
        ('ark_of_covenant', 'lengthCubits', 2.5, 'CLAIM_ARK_COVENANT_LENGTH_CUBITS',
         'Exodus 25:10 records the ark''s length as two and a half cubits.'),
        ('ark_of_covenant', 'widthCubits', 1.5, 'CLAIM_ARK_COVENANT_WIDTH_CUBITS',
         'Exodus 25:10 records the ark''s width as a cubit and a half.'),
        ('ark_of_covenant', 'heightCubits', 1.5, 'CLAIM_ARK_COVENANT_HEIGHT_CUBITS',
         'Exodus 25:10 records the ark''s height as a cubit and a half.'),
        ('mercy_seat', 'lengthCubits', 2.5, 'CLAIM_MERCY_SEAT_LENGTH_CUBITS',
         'Exodus 25:17 records the mercy seat''s length as two and a half cubits.'),
        ('mercy_seat', 'widthCubits', 1.5, 'CLAIM_MERCY_SEAT_WIDTH_CUBITS',
         'Exodus 25:17 records the mercy seat''s width as a cubit and a half.')
     ) AS m(subject_key, predicate, num, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.predicate = m.predicate
JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id AND t.numeric_value = m.num;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('noahs_ark', 'madeOfMaterial', 'gopher wood', 'CLAIM_ARK_MADE_OF_GOPHER_WOOD',
         'Genesis 6:14 records the ark as made of gopher wood.'),
        ('noahs_ark', 'overlaidWithMaterial', 'pitch', 'CLAIM_ARK_COVERED_WITH_PITCH',
         'Genesis 6:14 records the ark as covered, inside and out, with pitch.'),
        ('ark_of_covenant', 'madeOfMaterial', 'acacia wood', 'CLAIM_ARK_COVENANT_MADE_OF_ACACIA',
         'Exodus 25:10 records the ark as made of acacia wood.'),
        ('ark_of_covenant', 'overlaidWithMaterial', 'pure gold', 'CLAIM_ARK_COVENANT_OVERLAID_GOLD',
         'Exodus 25:11 records the ark as overlaid, inside and out, with pure gold.'),
        ('poles_ark_covenant', 'madeOfMaterial', 'acacia wood', 'CLAIM_POLES_MADE_OF_ACACIA',
         'Exodus 25:13 records the poles as made of acacia wood.'),
        ('poles_ark_covenant', 'overlaidWithMaterial', 'gold', 'CLAIM_POLES_OVERLAID_GOLD',
         'Exodus 25:13 records the poles as overlaid with gold.'),
        ('mercy_seat', 'madeOfMaterial', 'pure gold', 'CLAIM_MERCY_SEAT_MADE_OF_GOLD',
         'Exodus 25:17 records the mercy seat as made of pure gold.'),
        ('cherubim_kapporet', 'madeOfMaterial', 'hammered gold', 'CLAIM_CHERUBIM_MADE_OF_GOLD',
         'Exodus 25:18 records the cherubim as made of hammered gold, of one piece with the mercy seat.')
     ) AS m(subject_key, predicate, txt, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN proposition p ON p.subject_entity_id = s.entity_id AND p.predicate = m.predicate
JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id AND t.text_value = m.txt;

-- 9. Evidence: one source observation per new source record.
INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || m.source_record_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION', NULL
FROM (VALUES
        ('MT_GEN_6_14', 'Genesis 6:14 records God instructing Noah to make the ark of gopher wood, with rooms, covered inside and outside with pitch.'),
        ('MT_GEN_6_15', 'Genesis 6:15 records the instructed dimensions of the ark: 300 cubits long, 50 cubits wide, 30 cubits high.'),
        ('MT_GEN_6_16', 'Genesis 6:16 records the instructed roof/window, a door in the side, and lower, second, and third decks.'),
        ('MT_GEN_6_22', 'Genesis 6:22 records that Noah did all that God commanded him.'),
        ('MT_GEN_7_7', 'Genesis 7:7 records Noah, his sons, his wife, and his sons'' wives entering the ark because of the flood waters.'),
        ('MT_EXO_25_10', 'Exodus 25:10 records the instructed ark of acacia wood, two and a half cubits long, a cubit and a half wide, a cubit and a half high.'),
        ('MT_EXO_25_11', 'Exodus 25:11 records the instructed overlay of pure gold, inside and out.'),
        ('MT_EXO_25_12', 'Exodus 25:12 records four gold rings to be cast for the ark.'),
        ('MT_EXO_25_13', 'Exodus 25:13 records poles of acacia wood overlaid with gold, to be put through the rings.'),
        ('MT_EXO_25_17', 'Exodus 25:17 records the instructed mercy seat of pure gold, two and a half cubits long and a cubit and a half wide.'),
        ('MT_EXO_25_18', 'Exodus 25:18 records two cherubim of hammered gold, made of one piece with the mercy seat.'),
        ('MT_EXO_37_1', 'Exodus 37:1 records that Bezalel made the ark of acacia wood.'),
        ('MT_EXO_40_20', 'Exodus 40:20 records Moses placing the testimony inside the ark, setting the poles on the ark, and putting the mercy seat on top.'),
        ('MT_DEU_10_3', 'Deuteronomy 10:3 records Moses, in the first person, recounting that he made an ark of acacia wood.')
     ) AS m(source_record_key, observation)
JOIN source_record sr ON sr.source_record_key = m.source_record_key;

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN citation c ON c.source_record_id = sr.source_record_id
WHERE e.evidence_key IN (
    'EV_MT_GEN_6_14', 'EV_MT_GEN_6_15', 'EV_MT_GEN_6_16', 'EV_MT_GEN_6_22', 'EV_MT_GEN_7_7',
    'EV_MT_EXO_25_10', 'EV_MT_EXO_25_11', 'EV_MT_EXO_25_12', 'EV_MT_EXO_25_13', 'EV_MT_EXO_25_17',
    'EV_MT_EXO_25_18', 'EV_MT_EXO_37_1', 'EV_MT_EXO_40_20', 'EV_MT_DEU_10_3');

-- 10. Claim-evidence links: each new claim is supported by its corresponding source observation.
INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Direct source observation for this claim.'
FROM (VALUES
        ('CLAIM_NOAH_RECIPIENT_ARK_INSTRUCTION', 'EV_MT_GEN_6_14'),
        ('CLAIM_ARK_PARTICIPANT_INSTRUCTION', 'EV_MT_GEN_6_14'),
        ('CLAIM_ARK_MADE_OF_GOPHER_WOOD', 'EV_MT_GEN_6_14'),
        ('CLAIM_ARK_COVERED_WITH_PITCH', 'EV_MT_GEN_6_14'),
        ('CLAIM_ARK_LENGTH_CUBITS', 'EV_MT_GEN_6_15'),
        ('CLAIM_ARK_WIDTH_CUBITS', 'EV_MT_GEN_6_15'),
        ('CLAIM_ARK_HEIGHT_CUBITS', 'EV_MT_GEN_6_15'),
        ('CLAIM_ARK_HAS_DOOR', 'EV_MT_GEN_6_16'),
        ('CLAIM_ARK_HAS_WINDOW', 'EV_MT_GEN_6_16'),
        ('CLAIM_NOAH_BUILDER_ARK', 'EV_MT_GEN_6_22'),
        ('CLAIM_ARK_SUBJECT_CONSTRUCTION', 'EV_MT_GEN_6_22'),
        ('CLAIM_NOAH_ENTERING_ARK', 'EV_MT_GEN_7_7'),
        ('CLAIM_ARK_PARTICIPANT_ENTERING', 'EV_MT_GEN_7_7'),
        ('CLAIM_MOSES_RECIPIENT_ARK_COVENANT_INSTRUCTION', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_PARTICIPANT_INSTRUCTION', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_LENGTH_CUBITS', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_WIDTH_CUBITS', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_HEIGHT_CUBITS', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_MADE_OF_ACACIA', 'EV_MT_EXO_25_10'),
        ('CLAIM_ARK_COVENANT_OVERLAID_GOLD', 'EV_MT_EXO_25_11'),
        ('CLAIM_ARK_COVENANT_HAS_RINGS', 'EV_MT_EXO_25_12'),
        ('CLAIM_ARK_COVENANT_HAS_POLES', 'EV_MT_EXO_25_13'),
        ('CLAIM_POLES_MADE_OF_ACACIA', 'EV_MT_EXO_25_13'),
        ('CLAIM_POLES_OVERLAID_GOLD', 'EV_MT_EXO_25_13'),
        ('CLAIM_ARK_COVENANT_HAS_MERCY_SEAT', 'EV_MT_EXO_25_17'),
        ('CLAIM_MERCY_SEAT_LENGTH_CUBITS', 'EV_MT_EXO_25_17'),
        ('CLAIM_MERCY_SEAT_WIDTH_CUBITS', 'EV_MT_EXO_25_17'),
        ('CLAIM_MERCY_SEAT_MADE_OF_GOLD', 'EV_MT_EXO_25_17'),
        ('CLAIM_MERCY_SEAT_HAS_CHERUBIM', 'EV_MT_EXO_25_18'),
        ('CLAIM_CHERUBIM_MADE_OF_GOLD', 'EV_MT_EXO_25_18'),
        ('CLAIM_BEZALEL_BUILDER_ARK_COVENANT', 'EV_MT_EXO_37_1'),
        ('CLAIM_ARK_COVENANT_SUBJECT_CONSTRUCTION', 'EV_MT_EXO_37_1'),
        ('CLAIM_MOSES_PLACES_TESTIMONY', 'EV_MT_EXO_40_20'),
        ('CLAIM_TESTIMONY_PARTICIPANT_PLACEMENT', 'EV_MT_EXO_40_20'),
        ('CLAIM_ARK_COVENANT_PARTICIPANT_PLACEMENT', 'EV_MT_EXO_40_20'),
        ('CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY', 'EV_MT_EXO_40_20'),
        ('CLAIM_MOSES_BUILDER_ARK_COVENANT', 'EV_MT_DEU_10_3')
     ) AS m(claim_key, evidence_key)
JOIN claim c ON c.claim_key = m.claim_key
JOIN evidence e ON e.evidence_key = m.evidence_key;

-- 11. Genuine source difference, preserved rather than resolved: Exodus names Bezalel as builder;
--     Deuteronomy has Moses speak of personally making the ark. Both claims remain independently
--     asserted; the relation records the disagreement without merging or deleting either claim.
INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'CONTRADICTS',
       'Exodus 37:1 names Bezalel as builder; Deuteronomy 10:3 has Moses speak of personally making the ark. Both claims are preserved rather than reconciled.'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_BEZALEL_BUILDER_ARK_COVENANT' AND b.claim_key = 'CLAIM_MOSES_BUILDER_ARK_COVENANT';

-- 12. Reconciliation: the Ark of the Covenant now receives a source identity and an active,
--     evidence-backed mapping to its canonical Entity, resolving the "structurally represented,
--     unmapped" status recorded by Phases 11/14/15. It remains a distinct canonical Entity from
--     noahs_ark; no merge is performed.
INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, 'mt-ark-covenant', 'the ark'
FROM source s WHERE s.source_key = 'EXO_MT';

INSERT INTO entity_source_mapping (source_identity_id, entity_id, mapping_status_code, confidence,
                                   justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9900,
       'Exodus 25:10 names the ark as the direct object of the building instruction at this locator.',
       ev.evidence_id
FROM source_identity si
JOIN entity en ON en.entity_key = 'ark_of_covenant'
JOIN evidence ev ON ev.evidence_key = 'EV_MT_EXO_25_10'
WHERE si.source_identity_key = 'mt-ark-covenant';

COMMIT;
