\set ON_ERROR_STOP on

\echo 'Phase 17 generic extension (event_type + predicate; no table, no participation role)'
SELECT event_type_code, description FROM event_type WHERE event_type_code = 'STANDING_REQUIREMENT';
SELECT predicate_code, subject_kind_code, object_kind_code, event_participation_role_code
FROM predicate WHERE predicate_code = 'standingRequirementIn';

\echo 'Phase 17 standing requirement entity/event/claim coverage'
SELECT en.entity_key,
       en.entity_type_code,
       count(DISTINCT c.claim_id) FILTER (WHERE p.predicate = 'standingRequirementIn') AS standing_requirement_claims,
       count(DISTINCT ep.event_id) AS projected_event_participations
FROM entity en
LEFT JOIN proposition p ON p.subject_entity_id = en.entity_id
LEFT JOIN claim c ON c.proposition_id = p.proposition_id
LEFT JOIN event_participation ep ON ep.entity_id = en.entity_id
WHERE en.entity_key IN ('poles_ark_covenant', 'rings_ark_covenant', 'ark_of_covenant')
GROUP BY en.entity_key, en.entity_type_code
ORDER BY en.entity_key;

\echo 'Phase 17 source availability and semantic classification'
SELECT item, classification, finding
FROM (VALUES
    ('Exodus 25:15 standing pole-handling requirement (poles remain in the rings, not withdrawn)',
     'SOURCE-BACKED', 'Populated as one DIRECT_SOURCE_CLAIM on the new standingRequirementIn predicate, with complete Source->Dataset->SourceRecord->Citation->Evidence->ClaimEvidence->Claim->Proposition provenance.'),
    ('Distinction: instruction vs standing requirement vs completed/historical event',
     'STRUCTURALLY REPRESENTED', 'INSTRUCTION (ark_covenant_instruction), STANDING_REQUIREMENT (ark_covenant_pole_standing_requirement), and CONSTRUCTION (ark_covenant_construction) are three distinct, non-conflated event types; standingRequirementIn carries no participation role and never projects into event_participation.'),
    ('Observed state that the poles were physically in the rings at any point',
     'NOT DERIVED', 'No source observation of this state is recorded or acquired in this phase; none is asserted.'),
    ('Derived state (e.g. that the poles remained in the rings after some later point)',
     'NOT DERIVED', 'No Derivation was created; no derived claim exists for the standing requirement.'),
    ('Inferred compliance claim (that the instruction/requirement was obeyed, that removal did or did not occur, or that transport occurred)',
     'INTENTIONALLY EXCLUDED', 'Only source-backed assertions may establish compliance/non-compliance/transport; none is available, so none is inferred or fabricated.'),
    ('poles_ark_covenant / rings_ark_covenant / ark_of_covenant canonical identity and Phase 16 semantics',
     'SUPPORTED', 'Reused unchanged from Phase 16; no duplicate entity, no re-mapping, no merge.'),
    ('New source identity or reconciliation for poles_ark_covenant / rings_ark_covenant',
     'INTENTIONALLY EXCLUDED', 'Not warranted: the standing requirement is a direct claim about the already-canonical entity, not a new source identity to reconcile.'),
    ('Numbers 4/7/10 transport-by-Kohathites, 1-2 Samuel narrative, and other later Ark-of-the-Covenant lifecycle material',
     'SOURCE AVAILABILITY GAP', 'Not inspected as available/acquired in this phase; remains ACQUISITION PENDING; none is fabricated.'),
    ('Artifact-specific requirement/provenance/reconciliation/inference/participant table, JSON payload, or direct participant store',
     'INTENTIONALLY EXCLUDED', 'The existing Entity/SourceIdentity/Proposition/Claim/Evidence/Event architecture, plus one event_type and one predicate, proved sufficient; no new table was added.'),
    ('Noah''s Ark and all prior Phase 6-16 semantics',
     'SUPPORTED', 'Unaffected by this phase; no proposition, claim, entity, or mapping touching noahs_ark was added, changed, or removed.')
) AS coverage(item, classification, finding);
