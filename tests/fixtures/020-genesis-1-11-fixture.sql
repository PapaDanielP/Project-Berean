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
        ('GEN_MT_REF', 'MT_GEN_1_1', 'Genesis 1:1'),
        ('GEN_MT_REF', 'MT_GEN_1_2', 'Genesis 1:2'),
        ('GEN_MT_REF', 'MT_GEN_1_3', 'Genesis 1:3'),
        ('GEN_MT_REF', 'MT_GEN_1_4', 'Genesis 1:4'),
        ('GEN_MT_REF', 'MT_GEN_1_5', 'Genesis 1:5'),
        ('GEN_MT_REF', 'MT_GEN_1_6', 'Genesis 1:6'),
        ('GEN_MT_REF', 'MT_GEN_1_7', 'Genesis 1:7'),
        ('GEN_MT_REF', 'MT_GEN_1_8', 'Genesis 1:8'),
        ('GEN_MT_REF', 'MT_GEN_1_9', 'Genesis 1:9'),
        ('GEN_MT_REF', 'MT_GEN_1_10', 'Genesis 1:10'),
        ('GEN_MT_REF', 'MT_GEN_1_11', 'Genesis 1:11'),
        ('GEN_MT_REF', 'MT_GEN_1_12', 'Genesis 1:12'),
        ('GEN_MT_REF', 'MT_GEN_1_13', 'Genesis 1:13'),
        ('GEN_MT_REF', 'MT_GEN_1_14', 'Genesis 1:14'),
        ('GEN_MT_REF', 'MT_GEN_1_15', 'Genesis 1:15'),
        ('GEN_MT_REF', 'MT_GEN_1_16', 'Genesis 1:16'),
        ('GEN_MT_REF', 'MT_GEN_1_17', 'Genesis 1:17'),
        ('GEN_MT_REF', 'MT_GEN_1_18', 'Genesis 1:18'),
        ('GEN_MT_REF', 'MT_GEN_1_19', 'Genesis 1:19'),
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
    ('noah', 'PERSON', 'Noah'), ('ararat', 'PLACE', 'Ararat'),
    ('gen1_god', 'CONCEPT', 'God'),
    ('gen1_heavens', 'CONCEPT', 'heavens'),
    ('gen1_earth', 'CONCEPT', 'earth'),
    ('gen1_darkness', 'CONCEPT', 'darkness'),
    ('gen1_deep', 'CONCEPT', 'deep'),
    ('gen1_light', 'CONCEPT', 'light'),
    ('gen1_day', 'CONCEPT', 'day'),
    ('gen1_night', 'CONCEPT', 'night'),
    ('gen1_waters', 'CONCEPT', 'waters'),
    ('gen1_expanse', 'CONCEPT', 'expanse'),
    ('gen1_sky', 'CONCEPT', 'sky'),
    ('gen1_dry_land', 'CONCEPT', 'dry land'),
    ('gen1_seas', 'CONCEPT', 'seas'),
    ('gen1_vegetation', 'CONCEPT', 'vegetation'),
    ('gen1_lights', 'CONCEPT', 'lights'),
    ('gen1_greater_light', 'CONCEPT', 'greater light'),
    ('gen1_lesser_light', 'CONCEPT', 'lesser light'),
    ('gen1_stars', 'CONCEPT', 'stars');

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
    ('ark_resting', 'OTHER', 'The resting of the ark as located in the Genesis flood narrative.'),
    ('gen1_1_creation_statement', 'OTHER', 'Genesis 1:1 creation statement; modeled only as a source-record event placeholder.'),
    ('gen1_2_earth_condition', 'OTHER', 'Genesis 1:2 earth-condition statement; ambiguous details are intentionally unresolved.'),
    ('gen1_3_light_command', 'OTHER', 'Genesis 1:3 light-command statement.'),
    ('gen1_4_light_distinction', 'OTHER', 'Genesis 1:4 light/distinction statement.'),
    ('gen1_5_naming_statement', 'OTHER', 'Genesis 1:5 naming statement for day and night.'),
    ('gen1_6_expanse_statement', 'OTHER', 'Genesis 1:6 expanse statement.'),
    ('gen1_7_waters_statement', 'OTHER', 'Genesis 1:7 waters statement.'),
    ('gen1_8_sky_naming_statement', 'OTHER', 'Genesis 1:8 sky-naming statement.'),
    ('gen1_9_dry_land_statement', 'OTHER', 'Genesis 1:9 dry-land statement.'),
    ('gen1_10_naming_statement', 'OTHER', 'Genesis 1:10 naming statement for dry land and seas.'),
    ('gen1_11_vegetation_command_statement', 'OTHER', 'Genesis 1:11 vegetation-command statement.'),
    ('gen1_12_vegetation_statement', 'OTHER', 'Genesis 1:12 vegetation statement.'),
    ('gen1_13_day_boundary_statement', 'OTHER', 'Genesis 1:13 day-boundary statement; ordinal day count is intentionally unresolved.'),
    ('gen1_14_lights_command_statement', 'OTHER', 'Genesis 1:14 lights-command statement; sign/season/day/year function language is intentionally excluded.'),
    ('gen1_15_lights_giving_light_statement', 'OTHER', 'Genesis 1:15 lights-giving-light statement.'),
    ('gen1_16_two_great_lights_statement', 'OTHER', 'Genesis 1:16 two-great-lights-and-stars statement; day/night rule language is intentionally excluded.'),
    ('gen1_17_lights_placement_statement', 'OTHER', 'Genesis 1:17 lights-placement statement.'),
    ('gen1_18_light_darkness_distinction_statement', 'OTHER', 'Genesis 1:18 light/darkness distinction statement; day/night rule language and the evaluative statement are intentionally excluded.'),
    ('gen1_19_day_boundary_statement', 'OTHER', 'Genesis 1:19 day-boundary statement; ordinal day count is intentionally unresolved.');

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
             ('noah', 'subjectOf', 'ark_resting'),
             ('gen1_god', 'subjectOf', 'gen1_1_creation_statement'),
             ('gen1_heavens', 'participatesIn', 'gen1_1_creation_statement'),
             ('gen1_earth', 'participatesIn', 'gen1_1_creation_statement'),
             ('gen1_earth', 'subjectOf', 'gen1_2_earth_condition'),
             ('gen1_darkness', 'participatesIn', 'gen1_2_earth_condition'),
             ('gen1_deep', 'participatesIn', 'gen1_2_earth_condition'),
             ('gen1_god', 'subjectOf', 'gen1_3_light_command'),
             ('gen1_light', 'participatesIn', 'gen1_3_light_command'),
             ('gen1_god', 'subjectOf', 'gen1_4_light_distinction'),
             ('gen1_light', 'participatesIn', 'gen1_4_light_distinction'),
             ('gen1_darkness', 'participatesIn', 'gen1_4_light_distinction'),
             ('gen1_god', 'subjectOf', 'gen1_5_naming_statement'),
             ('gen1_light', 'participatesIn', 'gen1_5_naming_statement'),
             ('gen1_darkness', 'participatesIn', 'gen1_5_naming_statement'),
             ('gen1_day', 'participatesIn', 'gen1_5_naming_statement'),
             ('gen1_night', 'participatesIn', 'gen1_5_naming_statement'),
             ('gen1_god', 'subjectOf', 'gen1_6_expanse_statement'),
             ('gen1_expanse', 'participatesIn', 'gen1_6_expanse_statement'),
             ('gen1_god', 'subjectOf', 'gen1_7_waters_statement'),
             ('gen1_waters', 'participatesIn', 'gen1_7_waters_statement'),
             ('gen1_god', 'subjectOf', 'gen1_8_sky_naming_statement'),
             ('gen1_sky', 'participatesIn', 'gen1_8_sky_naming_statement'),
             ('gen1_god', 'subjectOf', 'gen1_9_dry_land_statement'),
             ('gen1_dry_land', 'participatesIn', 'gen1_9_dry_land_statement'),
             ('gen1_god', 'subjectOf', 'gen1_10_naming_statement'),
             ('gen1_dry_land', 'participatesIn', 'gen1_10_naming_statement'),
             ('gen1_seas', 'participatesIn', 'gen1_10_naming_statement'),
             ('gen1_god', 'subjectOf', 'gen1_11_vegetation_command_statement'),
             ('gen1_vegetation', 'participatesIn', 'gen1_11_vegetation_command_statement'),
             ('gen1_earth', 'subjectOf', 'gen1_12_vegetation_statement'),
             ('gen1_vegetation', 'participatesIn', 'gen1_12_vegetation_statement'),
             ('gen1_day', 'subjectOf', 'gen1_13_day_boundary_statement'),
             ('gen1_god', 'subjectOf', 'gen1_14_lights_command_statement'),
             ('gen1_lights', 'participatesIn', 'gen1_14_lights_command_statement'),
             ('gen1_god', 'subjectOf', 'gen1_15_lights_giving_light_statement'),
             ('gen1_lights', 'participatesIn', 'gen1_15_lights_giving_light_statement'),
             ('gen1_earth', 'participatesIn', 'gen1_15_lights_giving_light_statement'),
             ('gen1_god', 'subjectOf', 'gen1_16_two_great_lights_statement'),
             ('gen1_greater_light', 'participatesIn', 'gen1_16_two_great_lights_statement'),
             ('gen1_lesser_light', 'participatesIn', 'gen1_16_two_great_lights_statement'),
             ('gen1_stars', 'participatesIn', 'gen1_16_two_great_lights_statement'),
             ('gen1_god', 'subjectOf', 'gen1_17_lights_placement_statement'),
             ('gen1_greater_light', 'participatesIn', 'gen1_17_lights_placement_statement'),
             ('gen1_lesser_light', 'participatesIn', 'gen1_17_lights_placement_statement'),
             ('gen1_stars', 'participatesIn', 'gen1_17_lights_placement_statement'),
             ('gen1_earth', 'participatesIn', 'gen1_17_lights_placement_statement'),
             ('gen1_god', 'subjectOf', 'gen1_18_light_darkness_distinction_statement'),
             ('gen1_light', 'participatesIn', 'gen1_18_light_darkness_distinction_statement'),
             ('gen1_darkness', 'participatesIn', 'gen1_18_light_darkness_distinction_statement'),
             ('gen1_day', 'subjectOf', 'gen1_19_day_boundary_statement')) AS m(subject_key, predicate, event_key)
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

-- Independent source claims may share one normalized proposition when the
-- semantic assertion is the same and only source provenance differs.
INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT m.claim_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM', m.statement
FROM (VALUES
        ('adam', 'fatherOf', 'seth', 'CLAIM_MT_ADAM_FATHER_SETH',
         'The Masoretic tradition records Seth as begotten by Adam.'),
        ('adam', 'fatherOf', 'seth', 'CLAIM_LXX_ADAM_FATHER_SETH',
         'The Septuagint tradition records Seth as begotten by Adam.'),
        ('seth', 'fatherOf', 'enosh', 'CLAIM_MT_SETH_FATHER_ENOSH',
         'The Masoretic tradition records Enosh as begotten by Seth.'),
        ('seth', 'fatherOf', 'enosh', 'CLAIM_LXX_SETH_FATHER_ENOSH',
         'The Septuagint tradition records Enosh as begotten by Seth.')
     ) AS m(subject_key, predicate, object_key, claim_key, statement)
JOIN entity s ON s.entity_key = m.subject_key
JOIN entity o ON o.entity_key = m.object_key
JOIN proposition p ON p.subject_entity_id = s.entity_id
                  AND p.object_entity_id = o.entity_id
                  AND p.predicate = m.predicate;

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
         'Noah is the subject of the ark-resting event.'),
        ('gen1_god', 'subjectOf', 'gen1_1_creation_statement', 'CLAIM_MT_GEN_1_1_GOD_SUBJECT_CREATION',
         'Genesis 1:1 presents God as the subject of the creation statement.'),
        ('gen1_heavens', 'participatesIn', 'gen1_1_creation_statement', 'CLAIM_MT_GEN_1_1_HEAVENS_CREATION_PARTICIPANT',
         'Genesis 1:1 presents the heavens within the creation statement.'),
        ('gen1_earth', 'participatesIn', 'gen1_1_creation_statement', 'CLAIM_MT_GEN_1_1_EARTH_CREATION_PARTICIPANT',
         'Genesis 1:1 presents the earth within the creation statement.'),
        ('gen1_earth', 'subjectOf', 'gen1_2_earth_condition', 'CLAIM_MT_GEN_1_2_EARTH_CONDITION_SUBJECT',
         'Genesis 1:2 presents the earth as the subject of a condition statement.'),
        ('gen1_darkness', 'participatesIn', 'gen1_2_earth_condition', 'CLAIM_MT_GEN_1_2_DARKNESS_CONDITION_PARTICIPANT',
         'Genesis 1:2 presents darkness within the earth-condition statement.'),
        ('gen1_deep', 'participatesIn', 'gen1_2_earth_condition', 'CLAIM_MT_GEN_1_2_DEEP_CONDITION_PARTICIPANT',
         'Genesis 1:2 presents the deep within the earth-condition statement.'),
        ('gen1_god', 'subjectOf', 'gen1_3_light_command', 'CLAIM_MT_GEN_1_3_GOD_LIGHT_COMMAND_SUBJECT',
         'Genesis 1:3 presents God as the subject of the light-command statement.'),
        ('gen1_light', 'participatesIn', 'gen1_3_light_command', 'CLAIM_MT_GEN_1_3_LIGHT_COMMAND_PARTICIPANT',
         'Genesis 1:3 presents light within the light-command statement.'),
        ('gen1_god', 'subjectOf', 'gen1_4_light_distinction', 'CLAIM_MT_GEN_1_4_GOD_LIGHT_DISTINCTION_SUBJECT',
         'Genesis 1:4 presents God as the subject of the light/distinction statement.'),
        ('gen1_light', 'participatesIn', 'gen1_4_light_distinction', 'CLAIM_MT_GEN_1_4_LIGHT_DISTINCTION_PARTICIPANT',
         'Genesis 1:4 presents light within the light/distinction statement.'),
        ('gen1_darkness', 'participatesIn', 'gen1_4_light_distinction', 'CLAIM_MT_GEN_1_4_DARKNESS_DISTINCTION_PARTICIPANT',
         'Genesis 1:4 presents darkness within the light/distinction statement.'),
        ('gen1_god', 'subjectOf', 'gen1_5_naming_statement', 'CLAIM_MT_GEN_1_5_GOD_NAMING_SUBJECT',
         'Genesis 1:5 presents God as the subject of the naming statement.'),
        ('gen1_light', 'participatesIn', 'gen1_5_naming_statement', 'CLAIM_MT_GEN_1_5_LIGHT_NAMING_PARTICIPANT',
         'Genesis 1:5 presents light within the naming statement.'),
        ('gen1_darkness', 'participatesIn', 'gen1_5_naming_statement', 'CLAIM_MT_GEN_1_5_DARKNESS_NAMING_PARTICIPANT',
         'Genesis 1:5 presents darkness within the naming statement.'),
        ('gen1_day', 'participatesIn', 'gen1_5_naming_statement', 'CLAIM_MT_GEN_1_5_DAY_NAMING_PARTICIPANT',
         'Genesis 1:5 presents day within the naming statement.'),
        ('gen1_night', 'participatesIn', 'gen1_5_naming_statement', 'CLAIM_MT_GEN_1_5_NIGHT_NAMING_PARTICIPANT',
         'Genesis 1:5 presents night within the naming statement.'),
        ('gen1_god', 'subjectOf', 'gen1_6_expanse_statement', 'CLAIM_MT_GEN_1_6_GOD_EXPANSE_SUBJECT',
         'Genesis 1:6 presents God as the subject of an expanse statement.'),
        ('gen1_expanse', 'participatesIn', 'gen1_6_expanse_statement', 'CLAIM_MT_GEN_1_6_EXPANSE_PARTICIPANT',
         'Genesis 1:6 presents an expanse within the expanse statement.'),
        ('gen1_god', 'subjectOf', 'gen1_7_waters_statement', 'CLAIM_MT_GEN_1_7_GOD_WATERS_SUBJECT',
         'Genesis 1:7 presents God as the subject of a waters statement.'),
        ('gen1_waters', 'participatesIn', 'gen1_7_waters_statement', 'CLAIM_MT_GEN_1_7_WATERS_PARTICIPANT',
         'Genesis 1:7 presents waters within the waters statement.'),
        ('gen1_god', 'subjectOf', 'gen1_8_sky_naming_statement', 'CLAIM_MT_GEN_1_8_GOD_SKY_NAMING_SUBJECT',
         'Genesis 1:8 presents God as the subject of a sky-naming statement.'),
        ('gen1_sky', 'participatesIn', 'gen1_8_sky_naming_statement', 'CLAIM_MT_GEN_1_8_SKY_NAMING_PARTICIPANT',
         'Genesis 1:8 presents sky within the sky-naming statement.'),
        ('gen1_god', 'subjectOf', 'gen1_9_dry_land_statement', 'CLAIM_MT_GEN_1_9_GOD_DRY_LAND_SUBJECT',
         'Genesis 1:9 presents God as the subject of a dry-land statement.'),
        ('gen1_dry_land', 'participatesIn', 'gen1_9_dry_land_statement', 'CLAIM_MT_GEN_1_9_DRY_LAND_PARTICIPANT',
         'Genesis 1:9 presents dry land within the dry-land statement.'),
        ('gen1_god', 'subjectOf', 'gen1_10_naming_statement', 'CLAIM_MT_GEN_1_10_GOD_NAMING_SUBJECT',
         'Genesis 1:10 presents God as the subject of a naming statement.'),
        ('gen1_dry_land', 'participatesIn', 'gen1_10_naming_statement', 'CLAIM_MT_GEN_1_10_DRY_LAND_NAMING_PARTICIPANT',
         'Genesis 1:10 presents dry land within the naming statement. The specific name given is intentionally unresolved.'),
        ('gen1_seas', 'participatesIn', 'gen1_10_naming_statement', 'CLAIM_MT_GEN_1_10_SEAS_NAMING_PARTICIPANT',
         'Genesis 1:10 presents seas within the naming statement.'),
        ('gen1_god', 'subjectOf', 'gen1_11_vegetation_command_statement', 'CLAIM_MT_GEN_1_11_GOD_VEGETATION_COMMAND_SUBJECT',
         'Genesis 1:11 presents God as the subject of a vegetation-command statement.'),
        ('gen1_vegetation', 'participatesIn', 'gen1_11_vegetation_command_statement', 'CLAIM_MT_GEN_1_11_VEGETATION_COMMAND_PARTICIPANT',
         'Genesis 1:11 presents vegetation within the vegetation-command statement.'),
        ('gen1_earth', 'subjectOf', 'gen1_12_vegetation_statement', 'CLAIM_MT_GEN_1_12_EARTH_VEGETATION_SUBJECT',
         'Genesis 1:12 presents the earth as the subject of a vegetation statement.'),
        ('gen1_vegetation', 'participatesIn', 'gen1_12_vegetation_statement', 'CLAIM_MT_GEN_1_12_VEGETATION_PARTICIPANT',
         'Genesis 1:12 presents vegetation within the vegetation statement.'),
        ('gen1_day', 'subjectOf', 'gen1_13_day_boundary_statement', 'CLAIM_MT_GEN_1_13_DAY_BOUNDARY_SUBJECT',
         'Genesis 1:13 presents day as the subject of a day-boundary statement. The ordinal day count is intentionally unresolved.'),
        ('gen1_god', 'subjectOf', 'gen1_14_lights_command_statement', 'CLAIM_MT_GEN_1_14_GOD_LIGHTS_COMMAND_SUBJECT',
         'Genesis 1:14 presents God as the subject of a lights-command statement. Sign/season/day/year function language is intentionally excluded.'),
        ('gen1_lights', 'participatesIn', 'gen1_14_lights_command_statement', 'CLAIM_MT_GEN_1_14_LIGHTS_COMMAND_PARTICIPANT',
         'Genesis 1:14 presents lights within the lights-command statement.'),
        ('gen1_god', 'subjectOf', 'gen1_15_lights_giving_light_statement', 'CLAIM_MT_GEN_1_15_GOD_LIGHTS_GIVING_LIGHT_SUBJECT',
         'Genesis 1:15 presents God as the subject of a lights-giving-light statement.'),
        ('gen1_lights', 'participatesIn', 'gen1_15_lights_giving_light_statement', 'CLAIM_MT_GEN_1_15_LIGHTS_GIVING_LIGHT_PARTICIPANT',
         'Genesis 1:15 presents lights within the lights-giving-light statement.'),
        ('gen1_earth', 'participatesIn', 'gen1_15_lights_giving_light_statement', 'CLAIM_MT_GEN_1_15_EARTH_GIVING_LIGHT_PARTICIPANT',
         'Genesis 1:15 presents the earth within the lights-giving-light statement.'),
        ('gen1_god', 'subjectOf', 'gen1_16_two_great_lights_statement', 'CLAIM_MT_GEN_1_16_GOD_TWO_GREAT_LIGHTS_SUBJECT',
         'Genesis 1:16 presents God as the subject of a two-great-lights-and-stars statement. Day/night rule language is intentionally excluded.'),
        ('gen1_greater_light', 'participatesIn', 'gen1_16_two_great_lights_statement', 'CLAIM_MT_GEN_1_16_GREATER_LIGHT_PARTICIPANT',
         'Genesis 1:16 presents the greater light within the two-great-lights-and-stars statement.'),
        ('gen1_lesser_light', 'participatesIn', 'gen1_16_two_great_lights_statement', 'CLAIM_MT_GEN_1_16_LESSER_LIGHT_PARTICIPANT',
         'Genesis 1:16 presents the lesser light within the two-great-lights-and-stars statement.'),
        ('gen1_stars', 'participatesIn', 'gen1_16_two_great_lights_statement', 'CLAIM_MT_GEN_1_16_STARS_PARTICIPANT',
         'Genesis 1:16 presents the stars within the two-great-lights-and-stars statement.'),
        ('gen1_god', 'subjectOf', 'gen1_17_lights_placement_statement', 'CLAIM_MT_GEN_1_17_GOD_LIGHTS_PLACEMENT_SUBJECT',
         'Genesis 1:17 presents God as the subject of a lights-placement statement.'),
        ('gen1_greater_light', 'participatesIn', 'gen1_17_lights_placement_statement', 'CLAIM_MT_GEN_1_17_GREATER_LIGHT_PLACEMENT_PARTICIPANT',
         'Genesis 1:17 presents the greater light within the lights-placement statement.'),
        ('gen1_lesser_light', 'participatesIn', 'gen1_17_lights_placement_statement', 'CLAIM_MT_GEN_1_17_LESSER_LIGHT_PLACEMENT_PARTICIPANT',
         'Genesis 1:17 presents the lesser light within the lights-placement statement.'),
        ('gen1_stars', 'participatesIn', 'gen1_17_lights_placement_statement', 'CLAIM_MT_GEN_1_17_STARS_PLACEMENT_PARTICIPANT',
         'Genesis 1:17 presents the stars within the lights-placement statement.'),
        ('gen1_earth', 'participatesIn', 'gen1_17_lights_placement_statement', 'CLAIM_MT_GEN_1_17_EARTH_PLACEMENT_PARTICIPANT',
         'Genesis 1:17 presents the earth within the lights-placement statement.'),
        ('gen1_god', 'subjectOf', 'gen1_18_light_darkness_distinction_statement', 'CLAIM_MT_GEN_1_18_GOD_LIGHT_DARKNESS_DISTINCTION_SUBJECT',
         'Genesis 1:18 presents God as the subject of a light/darkness distinction statement. Day/night rule language and the evaluative statement are intentionally excluded.'),
        ('gen1_light', 'participatesIn', 'gen1_18_light_darkness_distinction_statement', 'CLAIM_MT_GEN_1_18_LIGHT_DISTINCTION_PARTICIPANT',
         'Genesis 1:18 presents light within the light/darkness distinction statement.'),
        ('gen1_darkness', 'participatesIn', 'gen1_18_light_darkness_distinction_statement', 'CLAIM_MT_GEN_1_18_DARKNESS_DISTINCTION_PARTICIPANT',
         'Genesis 1:18 presents darkness within the light/darkness distinction statement.'),
        ('gen1_day', 'subjectOf', 'gen1_19_day_boundary_statement', 'CLAIM_MT_GEN_1_19_DAY_BOUNDARY_SUBJECT',
         'Genesis 1:19 presents day as the subject of a day-boundary statement. The ordinal day count is intentionally unresolved.')
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

INSERT INTO claim (claim_key, proposition_id, claim_type_code, claim_status_code, statement, notes)
SELECT 'CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT', p.proposition_id, 'DIRECT_SOURCE_CLAIM', 'SUPERSEDED',
       'Draft curation claim for the Masoretic Adam-at-Seth numeral later superseded without deletion.',
       'Preserved to demonstrate Claim SUPERSEDES lifecycle without changing source evidence.'
FROM proposition p
JOIN entity s ON s.entity_id = p.subject_entity_id
JOIN typed_value t ON t.typed_value_id = p.object_typed_value_id
WHERE s.entity_key = 'adam' AND p.predicate = 'ageAtFatherhoodYears' AND t.numeric_value = 130;

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code)
SELECT m.evidence_key, sr.source_record_id, m.observation, 'SOURCE_OBSERVATION'
FROM (VALUES
        ('MT_GEN_1_1', 'EV_MT_GEN_1_1_CREATION_SUBJECT',
         'Genesis 1:1 is represented as a structural source-record boundary that identifies God as the subject of a creation statement.'),
        ('MT_GEN_1_1', 'EV_MT_GEN_1_1_CREATION_OBJECTS',
         'Genesis 1:1 is represented as a structural source-record boundary that identifies the heavens and the earth within the creation statement.'),
        ('MT_GEN_1_2', 'EV_MT_GEN_1_2_EARTH_CONDITION',
         'Genesis 1:2 is represented as a structural source-record boundary that describes earth, darkness, and the deep while leaving underdetermined details unresolved.'),
        ('MT_GEN_1_3', 'EV_MT_GEN_1_3_LIGHT_COMMAND',
         'Genesis 1:3 is represented as a structural source-record boundary that presents God and light within a light-command statement.'),
        ('MT_GEN_1_4', 'EV_MT_GEN_1_4_LIGHT_DISTINCTION',
         'Genesis 1:4 is represented as a structural source-record boundary that presents God, light, and darkness within a light/distinction statement.'),
        ('MT_GEN_1_5', 'EV_MT_GEN_1_5_NAMING',
         'Genesis 1:5 is represented as a structural source-record boundary that presents God, light, darkness, day, and night within a naming statement.'),
        ('MT_GEN_1_6', 'EV_MT_GEN_1_6_EXPANSE',
         'Genesis 1:6 is represented as a structural source-record boundary that presents God and an expanse within an expanse statement.'),
        ('MT_GEN_1_7', 'EV_MT_GEN_1_7_WATERS',
         'Genesis 1:7 is represented as a structural source-record boundary that presents God and waters within a waters statement.'),
        ('MT_GEN_1_8', 'EV_MT_GEN_1_8_SKY_NAMING',
         'Genesis 1:8 is represented as a structural source-record boundary that presents God and sky within a naming statement.'),
        ('MT_GEN_1_9', 'EV_MT_GEN_1_9_DRY_LAND',
         'Genesis 1:9 is represented as a structural source-record boundary that presents God and dry land within a dry-land statement.'),
        ('MT_GEN_1_10', 'EV_MT_GEN_1_10_NAMING',
         'Genesis 1:10 is represented as a structural source-record boundary that presents God, dry land, and seas within a naming statement. The specific names and the evaluative statement are intentionally excluded.'),
        ('MT_GEN_1_11', 'EV_MT_GEN_1_11_VEGETATION_COMMAND',
         'Genesis 1:11 is represented as a structural source-record boundary that presents God and vegetation within a vegetation-command statement.'),
        ('MT_GEN_1_12', 'EV_MT_GEN_1_12_VEGETATION',
         'Genesis 1:12 is represented as a structural source-record boundary that presents the earth and vegetation within a vegetation statement. The evaluative statement is intentionally excluded.'),
        ('MT_GEN_1_13', 'EV_MT_GEN_1_13_DAY_BOUNDARY',
         'Genesis 1:13 is represented as a structural source-record boundary that presents day within a day-boundary statement. The ordinal day count is intentionally excluded.'),
        ('MT_GEN_1_14', 'EV_MT_GEN_1_14_LIGHTS_COMMAND',
         'Genesis 1:14 is represented as a structural source-record boundary that presents God and lights within a lights-command statement. Sign/season/day/year function language is intentionally excluded.'),
        ('MT_GEN_1_15', 'EV_MT_GEN_1_15_LIGHTS_GIVING_LIGHT',
         'Genesis 1:15 is represented as a structural source-record boundary that presents God, lights, and the earth within a lights-giving-light statement.'),
        ('MT_GEN_1_16', 'EV_MT_GEN_1_16_TWO_GREAT_LIGHTS',
         'Genesis 1:16 is represented as a structural source-record boundary that presents God, the greater light, the lesser light, and the stars within a two-great-lights-and-stars statement. Day/night rule language is intentionally excluded.'),
        ('MT_GEN_1_17', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT',
         'Genesis 1:17 is represented as a structural source-record boundary that presents God, the greater light, the lesser light, the stars, and the earth within a lights-placement statement.'),
        ('MT_GEN_1_18', 'EV_MT_GEN_1_18_LIGHT_DARKNESS_DISTINCTION',
         'Genesis 1:18 is represented as a structural source-record boundary that presents God, light, and darkness within a light/darkness distinction statement. Day/night rule language and the evaluative statement are intentionally excluded.'),
        ('MT_GEN_1_19', 'EV_MT_GEN_1_19_DAY_BOUNDARY',
         'Genesis 1:19 is represented as a structural source-record boundary that presents day within a day-boundary statement. The ordinal day count is intentionally excluded.'),
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
        ('CLAIM_MT_GEN_1_1_GOD_SUBJECT_CREATION', 'EV_MT_GEN_1_1_CREATION_SUBJECT', 'SUPPORTS',
         'The verse boundary supports only the source-presented subject role, not a theological conclusion.'),
        ('CLAIM_MT_GEN_1_1_HEAVENS_CREATION_PARTICIPANT', 'EV_MT_GEN_1_1_CREATION_OBJECTS', 'SUPPORTS',
         'The same verse boundary supports multiple claim/proposition records.'),
        ('CLAIM_MT_GEN_1_1_EARTH_CREATION_PARTICIPANT', 'EV_MT_GEN_1_1_CREATION_OBJECTS', 'SUPPORTS',
         'The same verse boundary supports multiple claim/proposition records.'),
        ('CLAIM_MT_GEN_1_2_EARTH_CONDITION_SUBJECT', 'EV_MT_GEN_1_2_EARTH_CONDITION', 'SUPPORTS',
         'The claim preserves the condition statement without resolving ambiguous details.'),
        ('CLAIM_MT_GEN_1_2_DARKNESS_CONDITION_PARTICIPANT', 'EV_MT_GEN_1_2_EARTH_CONDITION', 'SUPPORTS',
         'The claim records only direct participation in the source-record statement.'),
        ('CLAIM_MT_GEN_1_2_DEEP_CONDITION_PARTICIPANT', 'EV_MT_GEN_1_2_EARTH_CONDITION', 'SUPPORTS',
         'The claim records only direct participation in the source-record statement.'),
        ('CLAIM_MT_GEN_1_3_GOD_LIGHT_COMMAND_SUBJECT', 'EV_MT_GEN_1_3_LIGHT_COMMAND', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_3_LIGHT_COMMAND_PARTICIPANT', 'EV_MT_GEN_1_3_LIGHT_COMMAND', 'SUPPORTS',
         'The claim records light as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_4_GOD_LIGHT_DISTINCTION_SUBJECT', 'EV_MT_GEN_1_4_LIGHT_DISTINCTION', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_4_LIGHT_DISTINCTION_PARTICIPANT', 'EV_MT_GEN_1_4_LIGHT_DISTINCTION', 'SUPPORTS',
         'The claim records light as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_4_DARKNESS_DISTINCTION_PARTICIPANT', 'EV_MT_GEN_1_4_LIGHT_DISTINCTION', 'SUPPORTS',
         'The claim records darkness as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_5_GOD_NAMING_SUBJECT', 'EV_MT_GEN_1_5_NAMING', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_5_LIGHT_NAMING_PARTICIPANT', 'EV_MT_GEN_1_5_NAMING', 'SUPPORTS',
         'The claim records light as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_5_DARKNESS_NAMING_PARTICIPANT', 'EV_MT_GEN_1_5_NAMING', 'SUPPORTS',
         'The claim records darkness as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_5_DAY_NAMING_PARTICIPANT', 'EV_MT_GEN_1_5_NAMING', 'SUPPORTS',
         'The claim records day as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_5_NIGHT_NAMING_PARTICIPANT', 'EV_MT_GEN_1_5_NAMING', 'SUPPORTS',
         'The claim records night as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_6_GOD_EXPANSE_SUBJECT', 'EV_MT_GEN_1_6_EXPANSE', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_6_EXPANSE_PARTICIPANT', 'EV_MT_GEN_1_6_EXPANSE', 'SUPPORTS',
         'The claim records the expanse as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_7_GOD_WATERS_SUBJECT', 'EV_MT_GEN_1_7_WATERS', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_7_WATERS_PARTICIPANT', 'EV_MT_GEN_1_7_WATERS', 'SUPPORTS',
         'The claim records waters as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_8_GOD_SKY_NAMING_SUBJECT', 'EV_MT_GEN_1_8_SKY_NAMING', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_8_SKY_NAMING_PARTICIPANT', 'EV_MT_GEN_1_8_SKY_NAMING', 'SUPPORTS',
         'The claim records sky as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_9_GOD_DRY_LAND_SUBJECT', 'EV_MT_GEN_1_9_DRY_LAND', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_9_DRY_LAND_PARTICIPANT', 'EV_MT_GEN_1_9_DRY_LAND', 'SUPPORTS',
         'The claim records dry land as directly present in the source-record statement.'),
        ('CLAIM_MT_GEN_1_10_GOD_NAMING_SUBJECT', 'EV_MT_GEN_1_10_NAMING', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_10_DRY_LAND_NAMING_PARTICIPANT', 'EV_MT_GEN_1_10_NAMING', 'SUPPORTS',
         'The claim records dry land as directly present in the naming statement without asserting the specific name given.'),
        ('CLAIM_MT_GEN_1_10_SEAS_NAMING_PARTICIPANT', 'EV_MT_GEN_1_10_NAMING', 'SUPPORTS',
         'The claim records seas as directly present in the naming statement.'),
        ('CLAIM_MT_GEN_1_11_GOD_VEGETATION_COMMAND_SUBJECT', 'EV_MT_GEN_1_11_VEGETATION_COMMAND', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_11_VEGETATION_COMMAND_PARTICIPANT', 'EV_MT_GEN_1_11_VEGETATION_COMMAND', 'SUPPORTS',
         'The claim records vegetation as directly present in the vegetation-command statement.'),
        ('CLAIM_MT_GEN_1_12_EARTH_VEGETATION_SUBJECT', 'EV_MT_GEN_1_12_VEGETATION', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_12_VEGETATION_PARTICIPANT', 'EV_MT_GEN_1_12_VEGETATION', 'SUPPORTS',
         'The claim records vegetation as directly present in the vegetation statement.'),
        ('CLAIM_MT_GEN_1_13_DAY_BOUNDARY_SUBJECT', 'EV_MT_GEN_1_13_DAY_BOUNDARY', 'SUPPORTS',
         'The claim records the source-presented subject role without asserting the ordinal day count.'),
        ('CLAIM_MT_GEN_1_14_GOD_LIGHTS_COMMAND_SUBJECT', 'EV_MT_GEN_1_14_LIGHTS_COMMAND', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_14_LIGHTS_COMMAND_PARTICIPANT', 'EV_MT_GEN_1_14_LIGHTS_COMMAND', 'SUPPORTS',
         'The claim records lights as directly present in the lights-command statement.'),
        ('CLAIM_MT_GEN_1_15_GOD_LIGHTS_GIVING_LIGHT_SUBJECT', 'EV_MT_GEN_1_15_LIGHTS_GIVING_LIGHT', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_15_LIGHTS_GIVING_LIGHT_PARTICIPANT', 'EV_MT_GEN_1_15_LIGHTS_GIVING_LIGHT', 'SUPPORTS',
         'The claim records lights as directly present in the lights-giving-light statement.'),
        ('CLAIM_MT_GEN_1_15_EARTH_GIVING_LIGHT_PARTICIPANT', 'EV_MT_GEN_1_15_LIGHTS_GIVING_LIGHT', 'SUPPORTS',
         'The claim records the earth as directly present in the lights-giving-light statement.'),
        ('CLAIM_MT_GEN_1_16_GOD_TWO_GREAT_LIGHTS_SUBJECT', 'EV_MT_GEN_1_16_TWO_GREAT_LIGHTS', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_16_GREATER_LIGHT_PARTICIPANT', 'EV_MT_GEN_1_16_TWO_GREAT_LIGHTS', 'SUPPORTS',
         'The claim records the greater light as directly present in the two-great-lights-and-stars statement.'),
        ('CLAIM_MT_GEN_1_16_LESSER_LIGHT_PARTICIPANT', 'EV_MT_GEN_1_16_TWO_GREAT_LIGHTS', 'SUPPORTS',
         'The claim records the lesser light as directly present in the two-great-lights-and-stars statement.'),
        ('CLAIM_MT_GEN_1_16_STARS_PARTICIPANT', 'EV_MT_GEN_1_16_TWO_GREAT_LIGHTS', 'SUPPORTS',
         'The claim records the stars as directly present in the two-great-lights-and-stars statement.'),
        ('CLAIM_MT_GEN_1_17_GOD_LIGHTS_PLACEMENT_SUBJECT', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_17_GREATER_LIGHT_PLACEMENT_PARTICIPANT', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT', 'SUPPORTS',
         'The claim records the greater light as directly present in the lights-placement statement.'),
        ('CLAIM_MT_GEN_1_17_LESSER_LIGHT_PLACEMENT_PARTICIPANT', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT', 'SUPPORTS',
         'The claim records the lesser light as directly present in the lights-placement statement.'),
        ('CLAIM_MT_GEN_1_17_STARS_PLACEMENT_PARTICIPANT', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT', 'SUPPORTS',
         'The claim records the stars as directly present in the lights-placement statement.'),
        ('CLAIM_MT_GEN_1_17_EARTH_PLACEMENT_PARTICIPANT', 'EV_MT_GEN_1_17_LIGHTS_PLACEMENT', 'SUPPORTS',
         'The claim records the earth as directly present in the lights-placement statement.'),
        ('CLAIM_MT_GEN_1_18_GOD_LIGHT_DARKNESS_DISTINCTION_SUBJECT', 'EV_MT_GEN_1_18_LIGHT_DARKNESS_DISTINCTION', 'SUPPORTS',
         'The claim records the source-presented subject role.'),
        ('CLAIM_MT_GEN_1_18_LIGHT_DISTINCTION_PARTICIPANT', 'EV_MT_GEN_1_18_LIGHT_DARKNESS_DISTINCTION', 'SUPPORTS',
         'The claim records light as directly present in the light/darkness distinction statement.'),
        ('CLAIM_MT_GEN_1_18_DARKNESS_DISTINCTION_PARTICIPANT', 'EV_MT_GEN_1_18_LIGHT_DARKNESS_DISTINCTION', 'SUPPORTS',
         'The claim records darkness as directly present in the light/darkness distinction statement.'),
        ('CLAIM_MT_GEN_1_19_DAY_BOUNDARY_SUBJECT', 'EV_MT_GEN_1_19_DAY_BOUNDARY', 'SUPPORTS',
         'The claim records the source-presented subject role without asserting the ordinal day count.'),
        ('CLAIM_ADAM_FATHER_SETH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Both traditions record the same parentage.'),
        ('CLAIM_ADAM_FATHER_SETH', 'EV_LXX_GEN_5_3', 'SUPPORTS', 'The traditions differ on the numeral, not the parentage.'),
        ('CLAIM_SETH_FATHER_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Both traditions record the same parentage.'),
        ('CLAIM_SETH_FATHER_ENOSH', 'EV_LXX_GEN_5_6', 'SUPPORTS', 'The traditions differ on the numeral, not the parentage.'),
        ('CLAIM_MT_ADAM_FATHER_SETH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The Masoretic record supports this source-specific parentage claim.'),
        ('CLAIM_LXX_ADAM_FATHER_SETH', 'EV_LXX_GEN_5_3', 'SUPPORTS', 'The Septuagint record supports this source-specific parentage claim.'),
        ('CLAIM_MT_SETH_FATHER_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'The Masoretic record supports this source-specific parentage claim.'),
        ('CLAIM_LXX_SETH_FATHER_ENOSH', 'EV_LXX_GEN_5_6', 'SUPPORTS', 'The Septuagint record supports this source-specific parentage claim.'),
        ('CLAIM_ADAM_PARENT_SETH_BEGETTING', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_SETH_CHILD_SETH_BEGETTING', 'EV_MT_GEN_5_3', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_SETH_PARENT_ENOSH_BEGETTING', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_ENOSH_CHILD_ENOSH_BEGETTING', 'EV_MT_GEN_5_6', 'SUPPORTS', 'Participation is recorded in the same verse.'),
        ('CLAIM_NOAH_ARK_RESTING', 'EV_MT_GEN_8_4', 'SUPPORTS', 'The narrative names Noah as the subject.'),
        ('CLAIM_ARK_RESTING_ARARAT', 'EV_MT_GEN_8_4', 'SUPPORTS', 'The verse gives the location.'),
        ('CLAIM_SETH_BEFORE_ENOSH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The genealogy orders the two begettings.'),
        ('CLAIM_SETH_BEFORE_ENOSH', 'EV_MT_GEN_5_6', 'SUPPORTS', 'The genealogy orders the two begettings.'),
        ('CLAIM_MT_ADAM_AGE_AT_SETH', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The Masoretic numeral is 130.'),
        ('CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT', 'EV_MT_GEN_5_3', 'SUPPORTS', 'The draft claim used the same source-backed Masoretic numeral.'),
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

INSERT INTO derivation (method, assumptions)
VALUES ('Cross-source comparison of normalized parentage propositions',
        'Masoretic and Septuagint claims are compared only for the shared Adam-fatherOf-Seth proposition; differing age numerals remain separate competing claims.');

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement, derivation_id)
SELECT 'CLAIM_XSRC_ADAM_FATHER_SETH_SHARED_DERIVED', p.proposition_id, 'DERIVED_CLAIM',
       'The selected Masoretic and Septuagint records share the normalized proposition that Adam is father of Seth.',
       d.derivation_id
FROM proposition p
JOIN entity s ON s.entity_id = p.subject_entity_id
JOIN entity o ON o.entity_id = p.object_entity_id
CROSS JOIN derivation d
WHERE p.predicate = 'fatherOf'
  AND s.entity_key = 'adam'
  AND o.entity_key = 'seth'
  AND d.method = 'Cross-source comparison of normalized parentage propositions';

INSERT INTO derivation_input (derivation_id, input_claim_id, notes)
SELECT d.derivation_id, c.claim_id, m.notes
FROM (VALUES
        ('CLAIM_MT_ADAM_FATHER_SETH', 'Masoretic direct source claim for the shared proposition.'),
        ('CLAIM_LXX_ADAM_FATHER_SETH', 'Septuagint direct source claim for the shared proposition.')
     ) AS m(claim_key, notes)
JOIN derivation d ON d.method = 'Cross-source comparison of normalized parentage propositions'
JOIN claim c ON c.claim_key = m.claim_key;

INSERT INTO claim_relation (claim_id, related_claim_id, relation_type_code, notes)
SELECT a.claim_id, b.claim_id, 'SUPERSEDES',
       'The active curated claim supersedes the preserved draft claim without deleting its provenance.'
FROM claim a CROSS JOIN claim b
WHERE a.claim_key = 'CLAIM_MT_ADAM_AGE_AT_SETH'
  AND b.claim_key = 'CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT';

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
