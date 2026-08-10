-- Phase 27 Genesis 1-50 source-backed corpus expansion.
--
-- This fixture extends the accepted Phase 26 state. It reuses GEN_MT / GEN_MT_REF and every
-- existing Genesis record and entity. Source text is not stored: raw_content, content_hash, and
-- quoted_text remain NULL. Only explicit assertions representable by the existing registries are
-- modeled; no identity, route, chronology, geography, causation, motive, or theology is inferred.
BEGIN;

INSERT INTO source_record (dataset_id, source_record_key, source_location, revision_label)
SELECT d.dataset_id, r.source_record_key, r.source_location, 'ref-1'
FROM dataset d
JOIN (VALUES
    ('MT_GEN_2_8', 'Genesis 2:8'), ('MT_GEN_2_22', 'Genesis 2:22'),
    ('MT_GEN_4_1', 'Genesis 4:1'), ('MT_GEN_4_2', 'Genesis 4:2'),
    ('MT_GEN_4_8', 'Genesis 4:8'), ('MT_GEN_4_16', 'Genesis 4:16'),
    ('MT_GEN_6_10', 'Genesis 6:10'), ('MT_GEN_11_2', 'Genesis 11:2'),
    ('MT_GEN_11_9', 'Genesis 11:9'), ('MT_GEN_11_26', 'Genesis 11:26'),
    ('MT_GEN_11_31', 'Genesis 11:31'), ('MT_GEN_12_5', 'Genesis 12:5'),
    ('MT_GEN_12_8', 'Genesis 12:8'), ('MT_GEN_13_12', 'Genesis 13:12'),
    ('MT_GEN_14_18', 'Genesis 14:18'), ('MT_GEN_15_18', 'Genesis 15:18'),
    ('MT_GEN_16_15', 'Genesis 16:15'), ('MT_GEN_18_1', 'Genesis 18:1'),
    ('MT_GEN_19_24', 'Genesis 19:24'), ('MT_GEN_20_1', 'Genesis 20:1'),
    ('MT_GEN_21_2', 'Genesis 21:2'), ('MT_GEN_21_31', 'Genesis 21:31'),
    ('MT_GEN_22_2', 'Genesis 22:2'), ('MT_GEN_23_1', 'Genesis 23:1'),
    ('MT_GEN_23_2', 'Genesis 23:2'), ('MT_GEN_24_67', 'Genesis 24:67'),
    ('MT_GEN_25_7', 'Genesis 25:7'), ('MT_GEN_25_25', 'Genesis 25:25'),
    ('MT_GEN_25_26', 'Genesis 25:26'), ('MT_GEN_26_6', 'Genesis 26:6'),
    ('MT_GEN_28_19', 'Genesis 28:19'), ('MT_GEN_29_32', 'Genesis 29:32'),
    ('MT_GEN_29_35', 'Genesis 29:35'), ('MT_GEN_30_24', 'Genesis 30:24'),
    ('MT_GEN_32_28', 'Genesis 32:28'), ('MT_GEN_33_18', 'Genesis 33:18'),
    ('MT_GEN_35_18', 'Genesis 35:18'), ('MT_GEN_35_28', 'Genesis 35:28'),
    ('MT_GEN_35_29', 'Genesis 35:29'), ('MT_GEN_37_17', 'Genesis 37:17'),
    ('MT_GEN_37_28', 'Genesis 37:28'), ('MT_GEN_39_20', 'Genesis 39:20'),
    ('MT_GEN_40_5', 'Genesis 40:5'), ('MT_GEN_40_12', 'Genesis 40:12'),
    ('MT_GEN_41_1', 'Genesis 41:1'), ('MT_GEN_41_50', 'Genesis 41:50'),
    ('MT_GEN_42_6', 'Genesis 42:6'), ('MT_GEN_43_15', 'Genesis 43:15'),
    ('MT_GEN_44_18', 'Genesis 44:18'), ('MT_GEN_45_1', 'Genesis 45:1'),
    ('MT_GEN_46_6', 'Genesis 46:6'), ('MT_GEN_47_28', 'Genesis 47:28'),
    ('MT_GEN_48_14', 'Genesis 48:14'), ('MT_GEN_49_33', 'Genesis 49:33'),
    ('MT_GEN_50_26', 'Genesis 50:26')
) AS r(source_record_key, source_location) ON d.dataset_key = 'GEN_MT_REF';

INSERT INTO citation (citation_key, source_record_id, locator)
SELECT 'CITE_' || sr.source_record_key, sr.source_record_id, sr.source_location
FROM source_record sr WHERE sr.source_record_key LIKE 'MT_GEN_%'
  AND NOT EXISTS (SELECT 1 FROM citation c WHERE c.source_record_id = sr.source_record_id);

INSERT INTO evidence (evidence_key, source_record_id, observation, evidence_type_code, notes)
SELECT 'EV_' || sr.source_record_key, sr.source_record_id,
       sr.source_location || ' is retained as an explicit Genesis source observation.',
       'SOURCE_OBSERVATION',
       CASE WHEN sr.source_record_key IN ('MT_GEN_32_28', 'MT_GEN_40_5', 'MT_GEN_41_1')
            THEN 'Details not expressible without adding semantics are retained as evidence only.'
            ELSE NULL END
FROM source_record sr
WHERE sr.source_record_key IN (
    'MT_GEN_2_8','MT_GEN_2_22','MT_GEN_4_1','MT_GEN_4_2','MT_GEN_4_8','MT_GEN_4_16',
    'MT_GEN_6_10','MT_GEN_11_2','MT_GEN_11_9','MT_GEN_11_26','MT_GEN_11_31',
    'MT_GEN_12_5','MT_GEN_12_8','MT_GEN_13_12','MT_GEN_14_18','MT_GEN_15_18',
    'MT_GEN_16_15','MT_GEN_18_1','MT_GEN_19_24','MT_GEN_20_1','MT_GEN_21_2',
    'MT_GEN_21_31','MT_GEN_22_2','MT_GEN_23_1','MT_GEN_23_2','MT_GEN_24_67',
    'MT_GEN_25_7','MT_GEN_25_25','MT_GEN_25_26','MT_GEN_26_6','MT_GEN_28_19',
    'MT_GEN_29_32','MT_GEN_29_35','MT_GEN_30_24','MT_GEN_32_28','MT_GEN_33_18',
    'MT_GEN_35_18','MT_GEN_35_28','MT_GEN_35_29','MT_GEN_37_17','MT_GEN_37_28',
    'MT_GEN_39_20','MT_GEN_40_5','MT_GEN_40_12','MT_GEN_41_1','MT_GEN_41_50',
    'MT_GEN_42_6','MT_GEN_43_15','MT_GEN_44_18','MT_GEN_45_1','MT_GEN_46_6',
    'MT_GEN_47_28','MT_GEN_48_14','MT_GEN_49_33','MT_GEN_50_26'
);

INSERT INTO evidence_citation (evidence_id, citation_id)
SELECT e.evidence_id, c.citation_id
FROM evidence e JOIN citation c ON c.source_record_id = e.source_record_id
WHERE e.evidence_key LIKE 'EV_MT_GEN_%'
ON CONFLICT DO NOTHING;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('eden', 'PLACE', 'Eden', 'The named Genesis location; no modern identification is asserted.'),
    ('eve', 'PERSON', 'Eve', 'The woman named in the Genesis narrative.'),
    ('cain', 'PERSON', 'Cain', 'The person named in Genesis 4.'),
    ('abel', 'PERSON', 'Abel', 'The person named in Genesis 4.'),
    ('nod', 'PLACE', 'Nod', 'The named Genesis location; no modern identification is asserted.'),
    ('shem', 'PERSON', 'Shem', 'A son of Noah named in Genesis 6:10.'),
    ('ham', 'PERSON', 'Ham', 'A son of Noah named in Genesis 6:10.'),
    ('japheth', 'PERSON', 'Japheth', 'A son of Noah named in Genesis 6:10.'),
    ('shinar', 'PLACE', 'Shinar', 'The named Genesis location; no modern identification is asserted.'),
    ('babel', 'PLACE', 'Babel', 'The named Genesis city; no modern identification is asserted.'),
    ('terah', 'PERSON', 'Terah', 'The person named in Genesis 11:26.'),
    ('abraham', 'PERSON', 'Abraham', 'The Genesis person called Abram before Genesis 17:5.'),
    ('sarah', 'PERSON', 'Sarah', 'The Genesis person called Sarai before Genesis 17:15.'),
    ('lot', 'PERSON', 'Lot', 'The person named in the Abraham narratives.'),
    ('nahor_son_of_terah', 'PERSON', 'Nahor son of Terah', 'Kept distinct from any other Nahor.'),
    ('haran_son_of_terah', 'PERSON', 'Haran son of Terah', 'Kept distinct from the place Haran.'),
    ('ur', 'PLACE', 'Ur', 'The named Genesis location; no modern identification is asserted.'),
    ('haran_place', 'PLACE', 'Haran', 'The named Genesis location, distinct from Haran son of Terah.'),
    ('canaan', 'PLACE', 'Canaan', 'The named Genesis location; no modern boundary is asserted.'),
    ('bethel', 'PLACE', 'Bethel', 'The named Genesis location; no modern identification is asserted.'),
    ('sodom', 'PLACE', 'Sodom', 'The named Genesis location; no modern identification is asserted.'),
    ('melchizedek', 'PERSON', 'Melchizedek', 'The person named in Genesis 14:18.'),
    ('salem', 'PLACE', 'Salem', 'The named Genesis location; no modern identification is asserted.'),
    ('hagar', 'PERSON', 'Hagar', 'The person named in Genesis 16.'),
    ('ishmael', 'PERSON', 'Ishmael', 'The person named in Genesis 16:15.'),
    ('hebron', 'PLACE', 'Hebron', 'The named Genesis location; no modern identification is asserted.'),
    ('gerar', 'PLACE', 'Gerar', 'The named Genesis location; no modern identification is asserted.'),
    ('isaac', 'PERSON', 'Isaac', 'The person named in Genesis 21:2.'),
    ('abimelech_gerar', 'PERSON', 'Abimelech of Gerar', 'The Abimelech associated with Gerar in this corpus.'),
    ('beersheba', 'PLACE', 'Beersheba', 'The named Genesis location; no modern identification is asserted.'),
    ('rebekah', 'PERSON', 'Rebekah', 'The person named in Genesis 24.'),
    ('esau', 'PERSON', 'Esau', 'The person named in Genesis 25:25.'),
    ('jacob', 'PERSON', 'Jacob', 'The person named in Genesis 25:26.'),
    ('leah', 'PERSON', 'Leah', 'The person named in Genesis 29.'),
    ('rachel', 'PERSON', 'Rachel', 'The person named in Genesis 29.'),
    ('reuben', 'PERSON', 'Reuben', 'The person named in Genesis 29:32.'),
    ('judah', 'PERSON', 'Judah', 'The person named in Genesis 29:35.'),
    ('joseph', 'PERSON', 'Joseph', 'The son of Jacob named in Genesis.'),
    ('shechem', 'PLACE', 'Shechem', 'The named Genesis location; no modern identification is asserted.'),
    ('benjamin', 'PERSON', 'Benjamin', 'The person named in Genesis 35:18.'),
    ('dothan', 'PLACE', 'Dothan', 'The named Genesis location; no modern identification is asserted.'),
    ('midianite_traders', 'ORGANIZATION', 'Midianite traders', 'The collective referent in Genesis 37:28.'),
    ('egypt', 'PLACE', 'Egypt', 'The named Genesis location; no modern boundary is asserted.'),
    ('pharaoh_gen41', 'PERSON', 'Pharaoh in Genesis 41', 'The title-bearing person in Genesis 41; no external identity is asserted.'),
    ('pharaoh_cupbearer', 'PERSON', 'Pharaoh''s chief cupbearer', 'The office-holder in Genesis 40; no name is inferred.'),
    ('pharaoh_baker', 'PERSON', 'Pharaoh''s chief baker', 'The office-holder in Genesis 40; no name is inferred.'),
    ('ephraim', 'PERSON', 'Ephraim', 'The person named in Genesis 41:52.'),
    ('manasseh', 'PERSON', 'Manasseh', 'The person named in Genesis 41:51.');

INSERT INTO event (event_key, event_type_code, description) VALUES
    ('eden_garden_planting', 'OTHER', 'The planting in Eden described at Genesis 2:8.'),
    ('eve_formation', 'OTHER', 'The formation of the woman described at Genesis 2:22.'),
    ('abel_death', 'DEATH', 'The death of Abel described at Genesis 4:8; motive is not asserted.'),
    ('noah_sons_genealogy', 'GENEALOGICAL', 'Noah fathering Shem, Ham, and Japheth at Genesis 6:10.'),
    ('babel_construction', 'CONSTRUCTION', 'The city construction described at Genesis 11:4-9.'),
    ('terah_household_journey', 'OTHER', 'The household journey associated with Ur and Haran at Genesis 11:31.'),
    ('abraham_canaan_journey', 'OTHER', 'The journey into Canaan described at Genesis 12:5.'),
    ('abraham_bethel_encampment', 'OTHER', 'Abram camping near Bethel at Genesis 12:8.'),
    ('lot_sodom_settlement', 'OTHER', 'Lot dwelling among the cities near Sodom at Genesis 13:12.'),
    ('melchizedek_abraham_encounter', 'OTHER', 'The encounter recorded at Genesis 14:18.'),
    ('abraham_covenant_gen15', 'OTHER', 'The covenant occurrence recorded at Genesis 15:18.'),
    ('ishmael_birth', 'BIRTH', 'The birth of Ishmael recorded at Genesis 16:15.'),
    ('abraham_hebron_encounter', 'OTHER', 'The encounter by the oaks of Mamre recorded at Genesis 18:1.'),
    ('sodom_destruction', 'OTHER', 'The destruction occurrence described at Genesis 19:24; cause is not modeled.'),
    ('abraham_gerar_sojourn', 'OTHER', 'Abraham dwelling at Gerar at Genesis 20:1.'),
    ('isaac_birth', 'BIRTH', 'The birth of Isaac recorded at Genesis 21:2.'),
    ('beersheba_covenant', 'OTHER', 'The covenant occurrence at Genesis 21:31.'),
    ('isaac_offering', 'OTHER', 'The offering occurrence described at Genesis 22:2; completion is not asserted.'),
    ('sarah_death', 'DEATH', 'The death of Sarah recorded at Genesis 23:2.'),
    ('isaac_rebekah_encounter', 'OTHER', 'Isaac receiving Rebekah at Genesis 24:67.'),
    ('abraham_death', 'DEATH', 'The death of Abraham recorded at Genesis 25:7-8.'),
    ('esau_birth', 'BIRTH', 'The birth of Esau recorded at Genesis 25:25.'),
    ('jacob_birth', 'BIRTH', 'The birth of Jacob recorded at Genesis 25:26.'),
    ('isaac_gerar_sojourn', 'OTHER', 'Isaac dwelling at Gerar at Genesis 26:6.'),
    ('jacob_bethel_dream', 'OTHER', 'Jacob naming Bethel after the dream narrative at Genesis 28:19; dream content is not modeled.'),
    ('reuben_birth', 'BIRTH', 'The birth of Reuben recorded at Genesis 29:32.'),
    ('judah_birth', 'BIRTH', 'The birth of Judah recorded at Genesis 29:35.'),
    ('joseph_birth', 'BIRTH', 'The birth of Joseph recorded at Genesis 30:24.'),
    ('jacob_shechem_arrival', 'OTHER', 'Jacob arriving at Shechem at Genesis 33:18.'),
    ('benjamin_birth', 'BIRTH', 'The birth and naming of Benjamin recorded at Genesis 35:18.'),
    ('rachel_death', 'DEATH', 'The death of Rachel recorded at Genesis 35:18-19.'),
    ('isaac_death', 'DEATH', 'The death of Isaac recorded at Genesis 35:29.'),
    ('joseph_dothan_encounter', 'OTHER', 'Joseph finding his brothers near Dothan at Genesis 37:17.'),
    ('joseph_sale', 'OTHER', 'The sale occurrence recorded at Genesis 37:28; motive and later causation are not asserted.'),
    ('joseph_imprisonment', 'OTHER', 'Joseph being put in prison at Genesis 39:20.'),
    ('prison_dreams', 'OTHER', 'The two dreams recorded at Genesis 40:5; their content is not modeled.'),
    ('joseph_interpretation', 'OTHER', 'Joseph giving an interpretation at Genesis 40:12.'),
    ('pharaoh_dream', 'OTHER', 'Pharaoh dreaming at Genesis 41:1; dream content is not modeled.'),
    ('ephraim_birth', 'BIRTH', 'The birth of Ephraim before the famine, recorded at Genesis 41:50-52.'),
    ('manasseh_birth', 'BIRTH', 'The birth of Manasseh before the famine, recorded at Genesis 41:50-52.'),
    ('brothers_egypt_encounter', 'OTHER', 'Joseph meeting his brothers in Egypt at Genesis 42:6.'),
    ('benjamin_egypt_journey', 'OTHER', 'Benjamin traveling to Egypt at Genesis 43:15.'),
    ('judah_appeal', 'OTHER', 'Judah approaching Joseph at Genesis 44:18.'),
    ('joseph_revelation', 'OTHER', 'Joseph making himself known to his brothers at Genesis 45:1.'),
    ('jacob_household_migration', 'OTHER', 'Jacob and his household coming to Egypt at Genesis 46:6.'),
    ('jacob_death', 'DEATH', 'The death of Jacob recorded at Genesis 49:33.'),
    ('jacob_blessing_grandsons', 'OTHER', 'Jacob blessing Ephraim and Manasseh at Genesis 48:14-20.'),
    ('joseph_death', 'DEATH', 'The death of Joseph recorded at Genesis 50:26.');

CREATE TEMP TABLE phase27_assertion (
    assertion_key text PRIMARY KEY,
    source_record_key text NOT NULL,
    subject_entity_key text,
    subject_event_key text,
    predicate text NOT NULL,
    object_entity_key text,
    object_event_key text,
    numeric_value numeric
) ON COMMIT DROP;

INSERT INTO phase27_assertion VALUES
    ('001','MT_GEN_2_8','gen1_god',NULL,'subjectOf',NULL,'eden_garden_planting',NULL),
    ('002','MT_GEN_2_8',NULL,'eden_garden_planting','occursAt','eden',NULL,NULL),
    ('003','MT_GEN_2_22','eve',NULL,'subjectOf',NULL,'eve_formation',NULL),
    ('004','MT_GEN_4_1','eve',NULL,'motherOf','cain',NULL,NULL),
    ('005','MT_GEN_4_2','eve',NULL,'motherOf','abel',NULL,NULL),
    ('006','MT_GEN_4_8','cain',NULL,'siblingOf','abel',NULL,NULL),
    ('007','MT_GEN_4_8','abel',NULL,'subjectOf',NULL,'abel_death',NULL),
    ('008','MT_GEN_4_8','cain',NULL,'participatesIn',NULL,'abel_death',NULL),
    ('009','MT_GEN_4_16','cain',NULL,'locatedAt','nod',NULL,NULL),
    ('010','MT_GEN_6_10','noah',NULL,'fatherOf','shem',NULL,NULL),
    ('011','MT_GEN_6_10','noah',NULL,'fatherOf','ham',NULL,NULL),
    ('012','MT_GEN_6_10','noah',NULL,'fatherOf','japheth',NULL,NULL),
    ('013','MT_GEN_6_10','noah',NULL,'parentIn',NULL,'noah_sons_genealogy',NULL),
    ('014','MT_GEN_6_10','shem',NULL,'childIn',NULL,'noah_sons_genealogy',NULL),
    ('015','MT_GEN_6_10','ham',NULL,'childIn',NULL,'noah_sons_genealogy',NULL),
    ('016','MT_GEN_6_10','japheth',NULL,'childIn',NULL,'noah_sons_genealogy',NULL),
    ('017','MT_GEN_11_2',NULL,'babel_construction','occursAt','shinar',NULL,NULL),
    ('018','MT_GEN_11_9',NULL,'babel_construction','occursAt','babel',NULL,NULL),
    ('019','MT_GEN_11_26','terah',NULL,'fatherOf','abraham',NULL,NULL),
    ('020','MT_GEN_11_26','terah',NULL,'fatherOf','nahor_son_of_terah',NULL,NULL),
    ('021','MT_GEN_11_26','terah',NULL,'fatherOf','haran_son_of_terah',NULL,NULL),
    ('022','MT_GEN_11_31','terah',NULL,'subjectOf',NULL,'terah_household_journey',NULL),
    ('023','MT_GEN_11_31','abraham',NULL,'participatesIn',NULL,'terah_household_journey',NULL),
    ('024','MT_GEN_11_31','sarah',NULL,'participatesIn',NULL,'terah_household_journey',NULL),
    ('025','MT_GEN_11_31','lot',NULL,'participatesIn',NULL,'terah_household_journey',NULL),
    ('026','MT_GEN_11_31',NULL,'terah_household_journey','occursAt','ur',NULL,NULL),
    ('027','MT_GEN_11_31',NULL,'terah_household_journey','occursAt','haran_place',NULL,NULL),
    ('028','MT_GEN_12_5','abraham',NULL,'subjectOf',NULL,'abraham_canaan_journey',NULL),
    ('029','MT_GEN_12_5','sarah',NULL,'participatesIn',NULL,'abraham_canaan_journey',NULL),
    ('030','MT_GEN_12_5','lot',NULL,'participatesIn',NULL,'abraham_canaan_journey',NULL),
    ('031','MT_GEN_12_5',NULL,'abraham_canaan_journey','occursAt','canaan',NULL,NULL),
    ('032','MT_GEN_12_8','abraham',NULL,'subjectOf',NULL,'abraham_bethel_encampment',NULL),
    ('033','MT_GEN_12_8',NULL,'abraham_bethel_encampment','occursAt','bethel',NULL,NULL),
    ('034','MT_GEN_13_12','lot',NULL,'subjectOf',NULL,'lot_sodom_settlement',NULL),
    ('035','MT_GEN_13_12',NULL,'lot_sodom_settlement','occursAt','sodom',NULL,NULL),
    ('036','MT_GEN_14_18','melchizedek',NULL,'subjectOf',NULL,'melchizedek_abraham_encounter',NULL),
    ('037','MT_GEN_14_18','abraham',NULL,'participatesIn',NULL,'melchizedek_abraham_encounter',NULL),
    ('038','MT_GEN_14_18',NULL,'melchizedek_abraham_encounter','occursAt','salem',NULL,NULL),
    ('039','MT_GEN_15_18','abraham',NULL,'subjectOf',NULL,'abraham_covenant_gen15',NULL),
    ('040','MT_GEN_16_15','abraham',NULL,'fatherOf','ishmael',NULL,NULL),
    ('041','MT_GEN_16_15','hagar',NULL,'motherOf','ishmael',NULL,NULL),
    ('042','MT_GEN_16_15','abraham',NULL,'parentIn',NULL,'ishmael_birth',NULL),
    ('043','MT_GEN_16_15','hagar',NULL,'parentIn',NULL,'ishmael_birth',NULL),
    ('044','MT_GEN_16_15','ishmael',NULL,'childIn',NULL,'ishmael_birth',NULL),
    ('045','MT_GEN_18_1','abraham',NULL,'subjectOf',NULL,'abraham_hebron_encounter',NULL),
    ('047','MT_GEN_18_1',NULL,'abraham_hebron_encounter','occursAt','hebron',NULL,NULL),
    ('048','MT_GEN_19_24','sodom',NULL,'subjectOf',NULL,'sodom_destruction',NULL),
    ('049','MT_GEN_19_24',NULL,'sodom_destruction','occursAt','sodom',NULL,NULL),
    ('050','MT_GEN_20_1','abraham',NULL,'subjectOf',NULL,'abraham_gerar_sojourn',NULL),
    ('052','MT_GEN_20_1',NULL,'abraham_gerar_sojourn','occursAt','gerar',NULL,NULL),
    ('053','MT_GEN_21_2','abraham',NULL,'fatherOf','isaac',NULL,NULL),
    ('054','MT_GEN_21_2','sarah',NULL,'motherOf','isaac',NULL,NULL),
    ('055','MT_GEN_21_2','abraham',NULL,'parentIn',NULL,'isaac_birth',NULL),
    ('056','MT_GEN_21_2','sarah',NULL,'parentIn',NULL,'isaac_birth',NULL),
    ('057','MT_GEN_21_2','isaac',NULL,'childIn',NULL,'isaac_birth',NULL),
    ('058','MT_GEN_21_31','abraham',NULL,'participatesIn',NULL,'beersheba_covenant',NULL),
    ('059','MT_GEN_21_31','abimelech_gerar',NULL,'participatesIn',NULL,'beersheba_covenant',NULL),
    ('060','MT_GEN_21_31',NULL,'beersheba_covenant','occursAt','beersheba',NULL,NULL),
    ('061','MT_GEN_22_2','abraham',NULL,'subjectOf',NULL,'isaac_offering',NULL),
    ('062','MT_GEN_22_2','isaac',NULL,'participatesIn',NULL,'isaac_offering',NULL),
    ('063','MT_GEN_23_2','sarah',NULL,'subjectOf',NULL,'sarah_death',NULL),
    ('064','MT_GEN_23_2',NULL,'sarah_death','occursAt','hebron',NULL,NULL),
    ('065','MT_GEN_23_1','sarah',NULL,'ageAtDeathYears',NULL,NULL,127),
    ('066','MT_GEN_24_67','isaac',NULL,'subjectOf',NULL,'isaac_rebekah_encounter',NULL),
    ('067','MT_GEN_24_67','rebekah',NULL,'participatesIn',NULL,'isaac_rebekah_encounter',NULL),
    ('068','MT_GEN_25_7','abraham',NULL,'subjectOf',NULL,'abraham_death',NULL),
    ('069','MT_GEN_25_7','abraham',NULL,'ageAtDeathYears',NULL,NULL,175),
    ('070','MT_GEN_25_25','isaac',NULL,'fatherOf','esau',NULL,NULL),
    ('071','MT_GEN_25_25','rebekah',NULL,'motherOf','esau',NULL,NULL),
    ('072','MT_GEN_25_25','esau',NULL,'childIn',NULL,'esau_birth',NULL),
    ('073','MT_GEN_25_26','isaac',NULL,'fatherOf','jacob',NULL,NULL),
    ('074','MT_GEN_25_26','rebekah',NULL,'motherOf','jacob',NULL,NULL),
    ('075','MT_GEN_25_26','jacob',NULL,'childIn',NULL,'jacob_birth',NULL),
    ('076','MT_GEN_26_6','isaac',NULL,'subjectOf',NULL,'isaac_gerar_sojourn',NULL),
    ('078','MT_GEN_26_6',NULL,'isaac_gerar_sojourn','occursAt','gerar',NULL,NULL),
    ('079','MT_GEN_28_19','jacob',NULL,'subjectOf',NULL,'jacob_bethel_dream',NULL),
    ('080','MT_GEN_28_19',NULL,'jacob_bethel_dream','occursAt','bethel',NULL,NULL),
    ('081','MT_GEN_29_32','jacob',NULL,'fatherOf','reuben',NULL,NULL),
    ('082','MT_GEN_29_32','leah',NULL,'motherOf','reuben',NULL,NULL),
    ('083','MT_GEN_29_32','reuben',NULL,'childIn',NULL,'reuben_birth',NULL),
    ('084','MT_GEN_29_35','jacob',NULL,'fatherOf','judah',NULL,NULL),
    ('085','MT_GEN_29_35','leah',NULL,'motherOf','judah',NULL,NULL),
    ('086','MT_GEN_29_35','judah',NULL,'childIn',NULL,'judah_birth',NULL),
    ('087','MT_GEN_30_24','jacob',NULL,'fatherOf','joseph',NULL,NULL),
    ('088','MT_GEN_30_24','rachel',NULL,'motherOf','joseph',NULL,NULL),
    ('089','MT_GEN_30_24','joseph',NULL,'childIn',NULL,'joseph_birth',NULL),
    ('090','MT_GEN_33_18','jacob',NULL,'subjectOf',NULL,'jacob_shechem_arrival',NULL),
    ('091','MT_GEN_33_18',NULL,'jacob_shechem_arrival','occursAt','shechem',NULL,NULL),
    ('092','MT_GEN_35_18','jacob',NULL,'fatherOf','benjamin',NULL,NULL),
    ('093','MT_GEN_35_18','rachel',NULL,'motherOf','benjamin',NULL,NULL),
    ('094','MT_GEN_35_18','benjamin',NULL,'childIn',NULL,'benjamin_birth',NULL),
    ('095','MT_GEN_35_18','rachel',NULL,'subjectOf',NULL,'rachel_death',NULL),
    ('096','MT_GEN_35_29','isaac',NULL,'subjectOf',NULL,'isaac_death',NULL),
    ('097','MT_GEN_35_28','isaac',NULL,'ageAtDeathYears',NULL,NULL,180),
    ('098','MT_GEN_37_17','joseph',NULL,'subjectOf',NULL,'joseph_dothan_encounter',NULL),
    ('099','MT_GEN_37_17',NULL,'joseph_dothan_encounter','occursAt','dothan',NULL,NULL),
    ('100','MT_GEN_37_28','joseph',NULL,'subjectOf',NULL,'joseph_sale',NULL),
    ('101','MT_GEN_37_28','midianite_traders',NULL,'participatesIn',NULL,'joseph_sale',NULL),
    ('102','MT_GEN_39_20','joseph',NULL,'subjectOf',NULL,'joseph_imprisonment',NULL),
    ('103','MT_GEN_39_20',NULL,'joseph_imprisonment','occursAt','egypt',NULL,NULL),
    ('104','MT_GEN_40_5','pharaoh_cupbearer',NULL,'participatesIn',NULL,'prison_dreams',NULL),
    ('105','MT_GEN_40_5','pharaoh_baker',NULL,'participatesIn',NULL,'prison_dreams',NULL),
    ('106','MT_GEN_40_12','joseph',NULL,'subjectOf',NULL,'joseph_interpretation',NULL),
    ('107','MT_GEN_40_12','pharaoh_cupbearer',NULL,'participatesIn',NULL,'joseph_interpretation',NULL),
    ('108','MT_GEN_41_1','pharaoh_gen41',NULL,'subjectOf',NULL,'pharaoh_dream',NULL),
    ('109','MT_GEN_41_50','joseph',NULL,'fatherOf','ephraim',NULL,NULL),
    ('110','MT_GEN_41_50','joseph',NULL,'fatherOf','manasseh',NULL,NULL),
    ('111','MT_GEN_41_50','ephraim',NULL,'childIn',NULL,'ephraim_birth',NULL),
    ('112','MT_GEN_41_50','manasseh',NULL,'childIn',NULL,'manasseh_birth',NULL),
    ('113','MT_GEN_42_6','joseph',NULL,'subjectOf',NULL,'brothers_egypt_encounter',NULL),
    ('116','MT_GEN_42_6',NULL,'brothers_egypt_encounter','occursAt','egypt',NULL,NULL),
    ('117','MT_GEN_43_15','benjamin',NULL,'subjectOf',NULL,'benjamin_egypt_journey',NULL),
    ('119','MT_GEN_43_15',NULL,'benjamin_egypt_journey','occursAt','egypt',NULL,NULL),
    ('120','MT_GEN_44_18','judah',NULL,'subjectOf',NULL,'judah_appeal',NULL),
    ('121','MT_GEN_44_18','joseph',NULL,'participatesIn',NULL,'judah_appeal',NULL),
    ('122','MT_GEN_45_1','joseph',NULL,'subjectOf',NULL,'joseph_revelation',NULL),
    ('126','MT_GEN_46_6','jacob',NULL,'subjectOf',NULL,'jacob_household_migration',NULL),
    ('128','MT_GEN_46_6','benjamin',NULL,'participatesIn',NULL,'jacob_household_migration',NULL),
    ('129','MT_GEN_46_6',NULL,'jacob_household_migration','occursAt','egypt',NULL,NULL),
    ('130','MT_GEN_47_28','jacob',NULL,'ageAtDeathYears',NULL,NULL,147),
    ('131','MT_GEN_48_14','jacob',NULL,'subjectOf',NULL,'jacob_blessing_grandsons',NULL),
    ('132','MT_GEN_48_14','ephraim',NULL,'participatesIn',NULL,'jacob_blessing_grandsons',NULL),
    ('133','MT_GEN_48_14','manasseh',NULL,'participatesIn',NULL,'jacob_blessing_grandsons',NULL),
    ('134','MT_GEN_49_33','jacob',NULL,'subjectOf',NULL,'jacob_death',NULL),
    ('135','MT_GEN_50_26','joseph',NULL,'subjectOf',NULL,'joseph_death',NULL),
    ('136','MT_GEN_50_26','joseph',NULL,'ageAtDeathYears',NULL,NULL,110);

INSERT INTO typed_value (value_type_code, numeric_value)
SELECT DISTINCT 'YEAR', numeric_value FROM phase27_assertion WHERE numeric_value IS NOT NULL;

INSERT INTO proposition
    (subject_entity_id, subject_event_id, predicate, object_entity_id, object_event_id, object_typed_value_id)
SELECT se.entity_id, sv.event_id, a.predicate, oe.entity_id, ov.event_id, tv.typed_value_id
FROM phase27_assertion a
LEFT JOIN entity se ON se.entity_key = a.subject_entity_key
LEFT JOIN event sv ON sv.event_key = a.subject_event_key
LEFT JOIN entity oe ON oe.entity_key = a.object_entity_key
LEFT JOIN event ov ON ov.event_key = a.object_event_key
LEFT JOIN typed_value tv ON tv.value_type_code = 'YEAR' AND tv.numeric_value = a.numeric_value;

INSERT INTO claim (claim_key, proposition_id, claim_type_code, statement)
SELECT 'CLAIM_P27_' || a.assertion_key, p.proposition_id, 'DIRECT_SOURCE_CLAIM',
       sr.source_location || ' records ' ||
       COALESCE(se.canonical_name, sv.event_key) || ' ' || a.predicate || ' ' ||
       COALESCE(oe.canonical_name, ov.event_key, a.numeric_value::text) || '.'
FROM phase27_assertion a
JOIN source_record sr ON sr.source_record_key = a.source_record_key
LEFT JOIN entity se ON se.entity_key = a.subject_entity_key
LEFT JOIN event sv ON sv.event_key = a.subject_event_key
LEFT JOIN entity oe ON oe.entity_key = a.object_entity_key
LEFT JOIN event ov ON ov.event_key = a.object_event_key
JOIN proposition p
  ON p.predicate = a.predicate
 AND p.subject_entity_id IS NOT DISTINCT FROM se.entity_id
 AND p.subject_event_id IS NOT DISTINCT FROM sv.event_id
 AND p.object_entity_id IS NOT DISTINCT FROM oe.entity_id
 AND p.object_event_id IS NOT DISTINCT FROM ov.event_id
LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
WHERE tv.numeric_value IS NOT DISTINCT FROM a.numeric_value;

INSERT INTO claim_evidence (claim_id, evidence_id, relation_type_code, notes)
SELECT c.claim_id, e.evidence_id, 'SUPPORTS', 'Direct source observation for this Phase 27 assertion.'
FROM phase27_assertion a
JOIN claim c ON c.claim_key = 'CLAIM_P27_' || a.assertion_key
JOIN evidence e ON e.evidence_key = 'EV_' || a.source_record_key;

INSERT INTO source_identity (source_id, source_identity_key, display_name)
SELECT s.source_id, 'mt-p27-' || en.entity_key,
       CASE en.entity_key WHEN 'abraham' THEN 'Abram' WHEN 'sarah' THEN 'Sarai'
            ELSE en.canonical_name END
FROM source s CROSS JOIN entity en
WHERE s.source_key = 'GEN_MT'
  AND en.entity_key IN (
    'eden','eve','cain','abel','nod','shem','ham','japheth','shinar','babel','terah',
    'abraham','sarah','lot','nahor_son_of_terah','haran_son_of_terah','ur','haran_place',
    'canaan','bethel','sodom','melchizedek','salem','hagar','ishmael','hebron','gerar',
    'isaac','abimelech_gerar','beersheba','rebekah','esau','jacob','leah','rachel',
    'reuben','judah','joseph','shechem','benjamin','dothan','midianite_traders','egypt',
    'pharaoh_gen41','pharaoh_cupbearer','pharaoh_baker','ephraim','manasseh'
  );

CREATE TEMP TABLE phase27_mapping(entity_key text PRIMARY KEY, source_record_key text NOT NULL) ON COMMIT DROP;
INSERT INTO phase27_mapping VALUES
    ('eden','MT_GEN_2_8'),('eve','MT_GEN_2_22'),('cain','MT_GEN_4_1'),('abel','MT_GEN_4_2'),
    ('nod','MT_GEN_4_16'),('shem','MT_GEN_6_10'),('ham','MT_GEN_6_10'),('japheth','MT_GEN_6_10'),
    ('shinar','MT_GEN_11_2'),('babel','MT_GEN_11_9'),('terah','MT_GEN_11_26'),
    ('abraham','MT_GEN_11_26'),('sarah','MT_GEN_11_31'),('lot','MT_GEN_11_31'),
    ('nahor_son_of_terah','MT_GEN_11_26'),('haran_son_of_terah','MT_GEN_11_26'),
    ('ur','MT_GEN_11_31'),('haran_place','MT_GEN_11_31'),('canaan','MT_GEN_12_5'),
    ('bethel','MT_GEN_12_8'),('sodom','MT_GEN_13_12'),('melchizedek','MT_GEN_14_18'),
    ('salem','MT_GEN_14_18'),('hagar','MT_GEN_16_15'),('ishmael','MT_GEN_16_15'),
    ('hebron','MT_GEN_18_1'),('gerar','MT_GEN_20_1'),('isaac','MT_GEN_21_2'),
    ('abimelech_gerar','MT_GEN_21_31'),('beersheba','MT_GEN_21_31'),('rebekah','MT_GEN_24_67'),
    ('esau','MT_GEN_25_25'),('jacob','MT_GEN_25_26'),('leah','MT_GEN_29_32'),
    ('rachel','MT_GEN_30_24'),('reuben','MT_GEN_29_32'),('judah','MT_GEN_29_35'),
    ('joseph','MT_GEN_30_24'),('shechem','MT_GEN_33_18'),('benjamin','MT_GEN_35_18'),
    ('dothan','MT_GEN_37_17'),('midianite_traders','MT_GEN_37_28'),('egypt','MT_GEN_39_20'),
    ('pharaoh_gen41','MT_GEN_41_1'),('pharaoh_cupbearer','MT_GEN_40_5'),
    ('pharaoh_baker','MT_GEN_40_5'),('ephraim','MT_GEN_41_50'),('manasseh','MT_GEN_41_50');

INSERT INTO entity_source_mapping
    (source_identity_id, entity_id, mapping_status_code, confidence, justification, supporting_evidence_id)
SELECT si.source_identity_id, en.entity_id, 'ACTIVE', 0.9900,
       sr.source_location || ' explicitly identifies this source referent.', ev.evidence_id
FROM phase27_mapping m
JOIN entity en ON en.entity_key = m.entity_key
JOIN source_identity si ON si.source_identity_key = 'mt-p27-' || m.entity_key
JOIN source_record sr ON sr.source_record_key = m.source_record_key
JOIN evidence ev ON ev.evidence_key = 'EV_' || m.source_record_key;

COMMIT;
