\set ON_ERROR_STOP on

\echo 'Phase 19 registry sufficiency check (no new event_type, predicate, role, table, or JSON payload)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'DEATH', 'INSTRUCTION', 'STANDING_REQUIREMENT', 'CONSTRUCTION')
ORDER BY event_type_code;
SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
FROM predicate WHERE predicate_code IN ('subjectOf', 'participatesIn', 'standingRequirementIn')
ORDER BY predicate_code;

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
