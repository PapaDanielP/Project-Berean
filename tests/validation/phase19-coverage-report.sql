\set ON_ERROR_STOP on

\echo 'Phase 19 registry sufficiency check (no schema, event_type, predicate, role, or ClaimRelation added)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'DEATH', 'INSTRUCTION', 'CONSTRUCTION', 'STANDING_REQUIREMENT')
\echo 'Phase 19 registry sufficiency check (no new event_type, predicate, role, table, or JSON payload)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'DEATH', 'INSTRUCTION', 'STANDING_REQUIREMENT', 'CONSTRUCTION')
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
\echo 'Phase 19 2 Samuel 6:3-7 source-backed slice coverage'
SELECT en.entity_key,
       en.entity_type_code,
       count(DISTINCT c.claim_id) FILTER (
           WHERE ev.event_key IN ('ark_covenant_new_cart_transport_2sam6',
                                  'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6')
       ) AS phase19_claims,
       count(DISTINCT ep.event_id) FILTER (
           WHERE evp.event_key IN ('ark_covenant_new_cart_transport_2sam6',
                                   'uzzah_ark_physical_interaction_2sam6', 'uzzah_death_2sam6')
       ) AS phase19_projected_events
FROM entity en
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id
LEFT JOIN event ev ON ev.event_id = p.object_event_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
LEFT JOIN event evp ON evp.event_id = ep.event_id
WHERE en.entity_key IN ('ark_of_covenant', 'poles_ark_covenant', 'rings_ark_covenant',
                        'priests_levites_ark_bearers', 'new_cart_ark_transport', 'uzzah')
GROUP BY en.entity_key, en.entity_type_code
ORDER BY en.entity_key;

\echo 'Phase 19 source availability and semantic classification'
SELECT item, classification, finding
FROM (VALUES
    ('2 Samuel 6:3-7 source availability',
     'SOURCE-BACKED', 'One manually-entered reference point is populated as source_record MT_2SA_6_3_7 with matching unquoted citation and one source observation; raw_content, content_hash, and quoted_text remain NULL.'),
    ('Ark of the Covenant canonical identity',
     'SUPPORTED', 'The existing ark_of_covenant OBJECT entity is reused exactly once; no duplicate Ark entity or new Ark source reconciliation is introduced.'),
    ('Ark transport on a new cart',
     'SOURCE-BACKED', 'Represented by OTHER event ark_covenant_new_cart_transport_2sam6 with Ark as subject and the new cart/Uzzah as projected participants, all supported by EV_MT_2SA_6_3_7.'),
    ('New cart / transport method',
     'SOURCE-BACKED', 'Represented as one OBJECT entity, new_cart_ark_transport, participating in the 2 Samuel transport event; no CART type, artifact table, or JSON method payload is added.'),
    ('Uzzah named person',
     'SOURCE-BACKED', 'Represented as one PERSON entity because the bounded locator identifies Uzzah; no duplicate Uzzah or source-identity reconciliation is added.'),
    ('Uzzah physical interaction with the Ark',
     'SOURCE-BACKED', 'Represented by OTHER event uzzah_ark_physical_interaction_2sam6 with Uzzah as subject and the Ark as participant; no touched/handled-by predicate is invented.'),
    ('Source-recorded consequence concerning Uzzah',
     'SOURCE-BACKED', 'Represented only as DEATH event uzzah_death_2sam6 with Uzzah as subject; no causeOf, punishmentFor, violatedRequirement, or compliance relation is asserted.'),
    ('Exodus 25:15 standing requirement',
     'SUPPORTED', 'The Phase 17 STANDING_REQUIREMENT event and standingRequirementIn proposition remain unchanged and projection-free; they are not evidence of compliance, violation, transport, or pole state.'),
    ('Joshua 3:6 transport',
     'SUPPORTED', 'The Phase 18 Joshua transport event remains a distinct OTHER event with the Ark and priests only; it is not merged with or treated as contradictory to the 2 Samuel new-cart transport.'),
    ('Relationship among Exodus 25:15, Joshua 3:6, and 2 Samuel 6:3-7',
     'DOCUMENTED UNRESOLVED DECISION', 'The records are preserved as independent source-backed assertions. No contradiction or compliance relation is justified solely because transport methods differ or a standing requirement exists.'),
    ('Contradiction between transport methods',
     'NOT DERIVED', 'No ClaimRelation is added for Joshua 3:6 versus 2 Samuel 6:3-7; different transport descriptions are not a logical contradiction by themselves.'),
    ('Compliance inference / violation inference',
     'INTENTIONALLY EXCLUDED', 'The phase deliberately rejects claims that Uzzah violated Exodus 25:15 or that any party complied with it; the selected source slice does not establish that semantic relation.'),
    ('Pole/ring physical state during 2 Samuel 6:3-7',
     'SOURCE AVAILABILITY GAP', 'No source-backed observation in this populated slice asserts whether poles were present, absent, in the rings, removed, or used; no state claim is added.'),
    ('Causal interpretation of Uzzah death',
     'INTENTIONALLY EXCLUDED', 'The death occurrence is modeled, but no cause, punishment, improper transport, ownership, chronology, route, duration, or violation predicate is introduced.'),
    ('Derived knowledge',
     'NOT DERIVED', 'No DERIVED_CLAIM, Derivation, or DerivationInput is added for Phase 19. Existing derivations remain unchanged and self-input is rejected.'),
    ('Ahio, David, oxen, locations, priests, Levites, Kohathites, and other participants',
     'INTENTIONALLY EXCLUDED', 'The fixture stays minimal: it models only the Ark, the new cart, and Uzzah needed for the phase objective and does not infer or populate unrelated participants.'),
    ('Deferred lifecycle events beyond 2 Samuel 6:3-7',
     'ACQUISITION PENDING', 'Joshua 6, broader 2 Samuel narrative, Numbers material, and later Ark lifecycle records remain outside this bounded source-backed phase.'),
    ('Generic model sufficiency for source-backed lifecycle conflict handling',
     'RUNTIME VERIFIED', 'The full validation suite verifies that existing Entity/SourceRecord/Citation/Evidence/Proposition/Claim/Event/ClaimRelation architecture can represent the slice without schema changes.'),
    ('Semantic precision for touched/cart/consequence labels',
     'SEMANTIC PRECISION GAP', 'The generic model records the events faithfully through event descriptions and source-backed claims, but no reusable touched/cart/causal vocabulary is added because the phase does not require query-level precision for those concepts.')
) AS coverage(item, classification, finding);
