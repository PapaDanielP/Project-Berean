# Phase 24 — Berean in Action

## Scope built

Phase 24 adds a reproducible, source-backed Ark of the Covenant lifecycle slice from 1 Samuel 4–7, extending the accepted Genesis / Ark material through Phase 19:

- 1 Samuel 4:4 — Ark brought from Shiloh into the battle-camp context.
- 1 Samuel 4:11 — Ark taken in the Philistine battle context.
- 1 Samuel 5:1 — Ark moved from Ebenezer to Ashdod by the Philistines.
- 1 Samuel 5:2 — Ark brought into the house of Dagon and set there.
- 1 Samuel 7:1 — Ark brought to the house of Abinadab; Eleazar set apart to keep it.
- 1 Samuel 7:2 — Ark remains at Kiriath-jearim for a long period.

The slice is intentionally small but coherent. It demonstrates source-backed Sources, Datasets, SourceRecords, Citations, Evidence, Propositions, Claims, Events, projected event relationships, source-identity mappings, provenance traversal, source comparison, event exploration, dependency exploration, and reuse of accepted genuine derivations.

## Files added or changed

- `tests/fixtures/100-phase24-berean-in-action-fixture.sql`
- `tests/validation/phase24-berean-in-action-slice.sql`
- `tests/validation/phase24-coverage-report.sql`
- `scripts/validation/run-postgres-validation.sh`
- `tests/app/app.test.ts`
- `docs/04-data/PHASE24_BEREAN_IN_ACTION.md`

No schema file or registry definition was changed.

## Coverage summary

Phase 24 itself adds:

| Category | Phase 24 count | Notes |
| --- | ---: | --- |
| Sources | 1 | `1SA_MT` |
| Datasets | 1 | `1SA_MT_REF` |
| SourceRecords | 6 | 1 Samuel 4:4, 4:11, 5:1, 5:2, 7:1, 7:2 |
| Citations | 6 | Locator-only, unquoted |
| Evidence | 6 | One source observation per locator |
| Propositions | 16 | Entity-event and event-place propositions |
| Claims | 16 | All `DIRECT_SOURCE_CLAIM` |
| Events | 7 | All existing `OTHER` event type |
| Relationships | 11 projected `event_participation` rows | Projection from claim-asserted propositions |
| ClaimRelations | 0 | No automatic source-difference classification |
| Derivations | 0 new | Existing accepted Genesis derivations remain available |
| DerivationInputs | 0 new | Existing accepted derivation inputs remain available |

Executable coverage query: `tests/validation/phase24-coverage-report.sql`.

## Provenance examples

Every Phase 24 claim is traceable through:

```text
Claim
→ ClaimEvidence
→ Evidence
→ EvidenceCitation
→ Citation
→ SourceRecord
→ Dataset
→ Source
```

Examples validated by `tests/validation/phase24-berean-in-action-slice.sql`:

| Claim | Evidence | Citation | SourceRecord | Dataset | Source |
| --- | --- | --- | --- | --- | --- |
| `CLAIM_ARK_COVENANT_SUBJECT_CAPTURE_1SAM4` | `EV_MT_1SA_4_11` | `1 Samuel 4:11` | `MT_1SA_4_11` | `1SA_MT_REF` | `1SA_MT` |
| `CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5` | `EV_MT_1SA_5_1` | `1 Samuel 5:1` | `MT_1SA_5_1` | `1SA_MT_REF` | `1SA_MT` |
| `CLAIM_ELEAZAR_PARTICIPANT_ARK_CARE_1SAM7` | `EV_MT_1SA_7_1` | `1 Samuel 7:1` | `MT_1SA_7_1` | `1SA_MT_REF` | `1SA_MT` |

Source text remains unstored by policy:

```text
source_record.raw_content = NULL
citation.quoted_text = NULL
```

The API reports those NULLs as `NOT_STORED_BY_POLICY`, not as source silence.

## Demonstration queries and API examples

### Provenance / evidence / source tracing

```sql
SELECT c.claim_key, ev.evidence_key, ci.locator, sr.source_record_key, d.dataset_key, s.source_key
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5';
```

API:

```text
GET /api/provenance/explain?claim_id=<id for CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5>
```

The Phase 24 app test verifies this operation is read-only and resolves the full `1SA_MT` source chain.

### Proposition exploration

```sql
SELECT c.claim_key, c.claim_type_code, c.statement
FROM claim c
WHERE c.proposition_id = (
    SELECT proposition_id
    FROM claim
    WHERE claim_key = 'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5'
);
```

This shows which claims assert the same authoritative structured proposition. The proposition remains authoritative; `claim.statement` is only a display label.

### Source comparison

```sql
SELECT s.source_key, c.claim_key, ev.event_key, c.statement
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN (
    'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_JORDAN',
    'CLAIM_ARK_COVENANT_SUBJECT_MOVED_ASHDOD_1SAM5',
    'CLAIM_ARK_COVENANT_SUBJECT_TRANSPORT_NEW_CART_2SAM6'
);
```

This compares:

- Joshua 3:6 — priestly carrying before the people.
- 1 Samuel 5:1 — Philistine movement from Ebenezer to Ashdod.
- 2 Samuel 6:3 — new-cart transport.

Berean preserves those differences as separate source-backed events. It does not automatically classify them as contradiction, violation, compliance, causation, or theological meaning.

### Event exploration

```sql
SELECT ev.event_key, ev.event_type_code, en.entity_key, ep.role_code, c.claim_key
FROM event ev
JOIN event_participation ep ON ep.event_id = ev.event_id
JOIN entity en ON en.entity_id = ep.entity_id
JOIN claim c ON c.claim_id = ep.asserting_claim_id
WHERE ev.event_key = 'ark_covenant_moved_to_ashdod_1sam5'
ORDER BY en.entity_key;
```

API:

```text
GET /api/events/<id for ark_covenant_moved_to_ashdod_1sam5>
```

The result demonstrates that `event_participation` remains a projection from claim-asserted propositions, not a second authoritative event-participant table.

### Dependency exploration

```sql
SELECT ev.evidence_key, c.claim_key, ce.relation_type_code
FROM evidence ev
JOIN claim_evidence ce ON ce.evidence_id = ev.evidence_id
JOIN claim c ON c.claim_id = ce.claim_id
WHERE ev.evidence_key LIKE 'EV_MT_1SA_%'
ORDER BY ev.evidence_key, c.claim_key;
```

Existing derivation dependency exploration remains available through `derivation_input`:

```sql
SELECT dc.claim_key AS derived_claim_key, ic.claim_key AS input_claim_key, di.notes
FROM claim dc
JOIN derivation_input di ON di.derivation_id = dc.derivation_id
JOIN claim ic ON ic.claim_id = di.input_claim_id
WHERE dc.claim_key = 'CLAIM_MT_ENOSH_YEAR_DERIVED';
```

### Derivation explanation and structural eligibility

Phase 24 does not add artificial 1 Samuel derivations. It reuses accepted genuine Genesis derivations, including:

- `CLAIM_MT_ENOSH_YEAR_DERIVED`
- `CLAIM_LXX_ENOSH_YEAR_DERIVED`
- `CLAIM_XSRC_ADAM_FATHER_SETH_SHARED_DERIVED`

API:

```text
GET /api/derivations/check-eligibility?derivation_id=<id for CLAIM_MT_ENOSH_YEAR_DERIVED>
```

This preserves Phase 23: the endpoint checks only structural eligibility, returns method and assumptions as metadata, and does not license logical entailment.

## Source-difference examples

### Ark movement and custody differences

The accepted Ark material now includes:

- Exodus 25:15 — a standing requirement that the poles remain in the rings (`standingRequirementIn`, no projected participation).
- Joshua 3:6 — priests carry the Ark before the people.
- 1 Samuel 4–7 — the Ark is taken, moved by Philistines, set in the house of Dagon, brought to Abinadab's house, and remains at Kiriath-jearim.
- 2 Samuel 6:3 — the Ark is set on a new cart.

These are represented as distinct source-backed claims and events. Phase 24 deliberately does not infer:

- compliance or violation of Exodus 25:15;
- contradiction between priestly carrying and new-cart transport;
- causation for any consequence;
- theological explanation;
- global factual-core promotion.

### Names and identities

1 Samuel uses the source identity “Ark of God” in this slice. Phase 24 maps that source-specific identity to the existing canonical `ark_of_covenant` entity with evidence-backed justification, while preserving the source identity as distinct from the canonical entity.

## Limitations and deliberately unmade conclusions

The model remained sufficient for the Phase 24 slice, but the demonstration shows some boundaries:

- 1 Samuel 7:2's “twenty years” is preserved in the evidence observation but not promoted to a typed proposition because the current predicate registry has no event-duration predicate.
- Hophni, Phinehas, Dagon as a distinct entity, Ebenezer, Shiloh as a place entity, additional Philistine city movements, and later return details are not modeled. They are future data-entry scope, not schema failures.
- The fixture does not store source text or quotations. That is policy-preserving, not source silence.
- The fixture does not classify source differences as contradictions. Difference is not contradiction.

## Issue classification

No actual schema insufficiency was discovered.

Observed limits are classified as:

- `DATA ENTRY / FIXTURE PROBLEM` for unmodeled adjacent persons, places, and later events.
- `USABILITY PROBLEM` for needing multi-join SQL to answer common exploration questions.
- `DOCUMENTATION PROBLEM` addressed by this report and the Phase 24 validation/coverage scripts.

The “twenty years” duration is best classified as a bounded registry-usability question, not an immediate schema insufficiency: the evidence can preserve the source observation without forcing an unsupported proposition.

## Model sufficiency

The existing model remained sufficient for Phase 24:

- NO SCHEMA CHANGE.
- NO REGISTRY CHANGE.
- NO EVALUATION PERSISTENCE.
- NO AUTOMATIC Claim, Derivation, Evidence, ClaimRelation, or provenance creation.
- NO semantic inference.

Berean now demonstrates an inspectable knowledge substrate rather than only structural fixtures: a user can ask what claims exist, where they came from, which source supplied them, what events and projected relationships they assert, where sources differ, and which derivations remain structurally eligible.

## Highest-value next question

Based on actual usage, the highest-value next question is:

> Can Berean provide a read-only “source comparison / event timeline” API that assembles already-stored claims, evidence, events, and source chains for a selected entity without creating new knowledge or classifying the differences?

That would improve usability while preserving the current architecture and evaluation-is-not-knowledge boundary.
