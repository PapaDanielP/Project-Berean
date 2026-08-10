\set ON_ERROR_STOP on

\echo 'Phase 19 registry sufficiency check (no schema, event_type, predicate, role, or ClaimRelation added)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'DEATH', 'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT')
ORDER BY event_type_code;
SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
FROM predicate WHERE predicate_code IN ('subjectOf', 'participatesIn', 'standingRequirementIn')
ORDER BY predicate_code;

\echo 'Phase 19 bounded source/citation/evidence summary'
SELECT s.source_key, d.dataset_key, sr.source_record_key, sr.source_location,
       sr.raw_content IS NULL AS raw_content_null,
       sr.content_hash IS NULL AS content_hash_null,
       ci.quoted_text IS NULL AS quoted_text_null,
       ev.evidence_key,
       EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = ev.evidence_id) AS supports_phase_claim
FROM source s
JOIN dataset d ON d.source_id = s.source_id
JOIN source_record sr ON sr.dataset_id = d.dataset_id
JOIN citation ci ON ci.source_record_id = sr.source_record_id
JOIN evidence ev ON ev.source_record_id = sr.source_record_id
WHERE d.dataset_key = '2SA_MT_REF'
ORDER BY sr.source_record_key;

\echo 'Phase 19 entities, mappings, events, claims, and projected participation'
SELECT en.entity_key, en.entity_type_code, en.canonical_name
FROM entity en
WHERE en.entity_key IN ('ark_of_covenant', 'poles_ark_covenant', 'rings_ark_covenant',
                        'uzzah', 'new_cart_2sam6', 'priests_levites_ark_bearers')
ORDER BY en.entity_key;

SELECT si.source_identity_key, en.entity_key, esm.mapping_status_code,
       esm.confidence, ev.evidence_key AS supporting_evidence_key
FROM entity_source_mapping esm
JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
JOIN source s ON s.source_id = si.source_id
JOIN entity en ON en.entity_id = esm.entity_id
LEFT JOIN evidence ev ON ev.evidence_id = esm.supporting_evidence_id
WHERE s.source_key = '2SA_MT'
ORDER BY si.source_identity_key;

SELECT ev.event_key, ev.event_type_code, en.entity_key, ep.role_code, c.claim_key
FROM event ev
LEFT JOIN event_participation ep ON ep.event_id = ev.event_id
LEFT JOIN entity en ON en.entity_id = ep.entity_id
LEFT JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key IN ('ark_covenant_transport_new_cart_2sam6',
                       'ark_covenant_physical_interaction_uzzah_2sam6',
                       'uzzah_death_2sam6',
                       'ark_covenant_transport_jordan',
                       'ark_covenant_pole_standing_requirement')
ORDER BY ev.event_key, en.entity_key;

SELECT classification_item, classification, finding
FROM (VALUES
    ('2 Samuel 6:3-7 source availability',
     'SOURCE-BACKED',
     'Exactly five manually-entered reference-point source records and unquoted citations exist for 2 Samuel 6:3, 6:4, 6:5, 6:6, and 6:7; raw_content, content_hash, and quoted_text remain NULL.'),
    ('2 Samuel 6:3 Ark transport',
     'SOURCE-BACKED',
     'Represented as ark_covenant_transport_new_cart_2sam6 (OTHER) with ark_of_covenant subjectOf the event, supported by EV_MT_2SA_6_3.'),
    ('New cart / transport method',
     'SUPPORTED',
     'new_cart_2sam6 is a bounded OBJECT entity with evidence-backed 2 Samuel source identity/mapping and participatesIn the transport event; no CART predicate or transport table was added.'),
    ('Generic event/proposition representation',
     'STRUCTURALLY REPRESENTED',
     'The 2 Samuel 6 transport, interaction, and death occurrences are represented through existing Event, Proposition, Claim, ClaimEvidence, Evidence, Citation, SourceRecord, Dataset, and Source tables, with event_participation projected from claims.'),
    ('Uzzah',
     'SUPPORTED',
     'uzzah is a single named PERSON entity with evidence-backed 2 Samuel source identity/mapping; no duplicate Uzzah or unsupported named participants were added.'),
    ('Uzzah physical interaction with Ark',
     'SOURCE-BACKED',
     'Represented as ark_covenant_physical_interaction_uzzah_2sam6 (OTHER) with the Ark as SUBJECT and Uzzah as PARTICIPANT, supported by EV_MT_2SA_6_6; no TOUCHED/HANDLED_BY predicate was added.'),
    ('Source-recorded consequence',
     'SOURCE-BACKED',
     'Represented only as uzzah_death_2sam6 (DEATH) with Uzzah as SUBJECT, supported by EV_MT_2SA_6_7; no cause, punishment, violation, or theological interpretation is asserted.'),
    ('Exodus 25:15 standing requirement',
     'RUNTIME VERIFIED',
     'Phase 17 CLAIM_POLES_STANDING_REQUIREMENT remains unchanged as standingRequirementIn on a STANDING_REQUIREMENT event and continues to project zero event_participation rows.'),
    ('Joshua 3:6 transport',
     'RUNTIME VERIFIED',
     'Phase 18 ark_covenant_transport_jordan remains a distinct OTHER event using subjectOf/participatesIn; it is not merged with the 2 Samuel new-cart event.'),
    ('Relationship among Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7',
     'DOCUMENTED UNRESOLVED DECISION',
     'The source-backed claims coexist as independent propositions. Different transport descriptions do not by themselves create a logical contradiction, compliance finding, or violation claim.'),
    ('Contradiction between transport methods',
     'NOT DERIVED',
     'No ClaimRelation is added for Phase 19. Carrying in Joshua 3:6 and setting the Ark on a new cart in 2 Samuel 6:3 are different source assertions, not a supported logical contradiction.'),
    ('Compliance inference',
     'INTENTIONALLY EXCLUDED',
     'No claim derives obedience, non-obedience, violation of Exodus 25:15, or improper transport from either the standing requirement or the later events.'),
    ('Pole/ring physical state during 2 Samuel 6',
     'NOT DERIVED',
     'No proposition or event participation names poles_ark_covenant or rings_ark_covenant in the 2 Samuel 6 events; their physical state is not inferred.'),
    ('Causal interpretation of Uzzah death',
     'INTENTIONALLY EXCLUDED',
     'The death is represented as a source-recorded historical occurrence only; no causeOf, punishmentFor, violation, or causal ClaimRelation exists.'),
    ('Derived knowledge',
     'NOT DERIVED',
     'Phase 19 adds no DERIVED_CLAIM, no Derivation, and no DerivationInput; all new claims are direct source claims with citations.'),
    ('2 Samuel 6:4-5 detail',
     'SOURCE AVAILABILITY GAP',
     'The locators and evidence observations are present to cover the bounded source slice, but no distinct semantic claims are populated from 6:4-5 to avoid broadening participants, instruments, locations, or worship details.'),
    ('Ahio, oxen, locations, route, chronology, duration, ownership',
     'ACQUISITION PENDING',
     'Not populated in this minimal phase because they are not necessary to test the source-backed lifecycle conflict/handling/consequence question and would broaden the slice.'),
    ('Artifact-specific lifecycle infrastructure',
     'INTENTIONALLY EXCLUDED',
     'No artifact/lifecycle/participant/relationship table, JSON payload, artifact column, graph database, ontology engine, or inference subsystem was introduced.'),
    ('Generic precision for physical touch / causal consequence',
     'SEMANTIC PRECISION GAP',
     'The existing generic model can faithfully record that a source-backed interaction and death occurred, but not the fine-grained physical act or causal interpretation without adding unsupported false precision; no extension was justified for this slice.')
) AS coverage(classification_item, classification, finding)
ORDER BY classification_item;
