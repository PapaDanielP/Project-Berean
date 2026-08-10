\set ON_ERROR_STOP on

\echo 'Phase 18 registry sufficiency check (no new event_type, no new predicate added)'
SELECT event_type_code, description FROM event_type
WHERE event_type_code IN ('OTHER', 'INSTRUCTION', 'STANDING_REQUIREMENT', 'CONSTRUCTION')
ORDER BY event_type_code;
SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
FROM predicate WHERE predicate_code IN ('subjectOf', 'participatesIn', 'standingRequirementIn')
ORDER BY predicate_code;

\echo 'Phase 18 transport slice entity/event/claim coverage'
SELECT en.entity_key,
       en.entity_type_code,
       count(DISTINCT c.claim_id) FILTER (
           WHERE ev.event_key IN ('ark_covenant_transport_jordan', 'ark_covenant_transport_instruction_jordan')
       ) AS transport_slice_claims,
       count(DISTINCT ep.event_id) AS projected_event_participations
FROM entity en
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id
LEFT JOIN event ev ON ev.event_id = p.object_event_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key IN ('ark_of_covenant', 'poles_ark_covenant', 'rings_ark_covenant',
                        'priests_levites_ark_bearers')
GROUP BY en.entity_key, en.entity_type_code
ORDER BY en.entity_key;

\echo 'Phase 18 source availability and semantic classification'
SELECT item, classification, finding
FROM (VALUES
    ('Ark of the Covenant canonical identity',
     'SUPPORTED', 'Exactly one ark_of_covenant OBJECT entity, reused unchanged from Phase 16; no duplicate introduced.'),
    ('poles_ark_covenant / rings_ark_covenant canonical identity',
     'SUPPORTED', 'Reused unchanged from Phase 16; this phase asserts nothing new about either, and neither participates in the transport event.'),
    ('Exodus 25:15 STANDING_REQUIREMENT (poles remain in the rings)',
     'SOURCE-BACKED', 'The Phase 17 standingRequirementIn proposition and its STANDING_REQUIREMENT event are untouched and remain projection-free (zero event_participation rows).'),
    ('Joshua 3:6 transport instruction (Joshua commands the priests)',
     'SOURCE-BACKED', 'Populated as two DIRECT_SOURCE_CLAIMs on the pre-existing subjectOf/participatesIn predicates against a new INSTRUCTION event, with complete provenance.'),
    ('Joshua 3:6 historical transport occurrence (the priests took up the ark and went before the people)',
     'SOURCE-BACKED', 'Populated as two DIRECT_SOURCE_CLAIMs on the pre-existing subjectOf/participatesIn predicates against a new OTHER-typed event, with complete provenance.'),
    ('Identified transport carriers (the priests)',
     'SUPPORTED', 'Modeled as one new priests_levites_ark_bearers ORGANIZATION entity, explicitly named by Joshua 3:6; no individual priest is fabricated, and no Kohathite/other unlisted participant is asserted.'),
    ('Registry extension (event_type / predicate)',
     'INTENTIONALLY EXCLUDED', 'No event_type or predicate was added. The existing generic OTHER event_type and the existing subjectOf/participatesIn predicates were sufficient for this bounded transport slice; a TRANSPORT event_type or CARRIER role was considered but not needed, and was therefore not added speculatively.'),
    ('Observed physical state of the poles/rings during this transport (e.g. whether the poles were in the rings)',
     'SOURCE AVAILABILITY GAP', 'Joshua 3:6 makes no assertion about the poles or rings; no such state is recorded or acquired, so none is asserted.'),
    ('Compliance with, or violation of, the Exodus 25:15 standing requirement during this transport',
     'INTENTIONALLY EXCLUDED', 'Never inferred from the standing requirement''s existence, from the fact of a later transport event, or from their conjunction; only a future source-backed observation could establish this, and none is available.'),
    ('Numbers 4:15, Numbers 7:9, and Numbers 10:21 (Kohathite bearing of "the sanctuary"/"the holy things")',
     'SOURCE AVAILABILITY GAP', 'Considered but not selected: the plain text does not explicitly name "the ark of the covenant" as the object borne, so asserting the Ark as their object would require an inference beyond the locator; remains ACQUISITION PENDING.'),
    ('Joshua 6:6-13 (Ark carried around Jericho) and 2 Samuel 6:3-7 (Ark on a cart, Uzzah)',
     'SOURCE AVAILABILITY GAP', 'Not selected for this bounded phase; not the smallest coherent slice, and 2 Samuel 6 introduces a distinct cart-based transport method out of scope here; remains ACQUISITION PENDING.'),
    ('Deferred lifecycle material generally (later Ark narrative beyond Joshua 3:6)',
     'DOCUMENTED UNRESOLVED DECISION', 'Intentionally bounded to the smallest coherent slice for this phase; further Ark lifecycle events remain open for a future bounded phase.'),
    ('Artifact/transport/requirement/participant-specific table, JSON payload, or direct participant store',
     'INTENTIONALLY EXCLUDED', 'The existing Entity/SourceIdentity/Proposition/Claim/Evidence/Event architecture proved sufficient; no new table was added.'),
    ('Noah''s Ark and all prior Phase 6-17 semantics',
     'SUPPORTED', 'Unaffected by this phase; no proposition, claim, entity, or mapping touching noahs_ark, or the Phase 17 standing requirement, was added, changed, or removed.')
) AS coverage(item, classification, finding);
