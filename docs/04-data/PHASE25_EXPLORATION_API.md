# Phase 25 — Berean Exploration API: Source Comparison and Event Timeline

**PHASE 25 STATUS: IMPLEMENTED**<br>
**ARCHITECTURAL STATUS: NO SCHEMA CHANGE**<br>
**REGISTRY STATUS: NO REGISTRY CHANGE**<br>
**OPERATION: GET /api/exploration/timeline**<br>
**MODE: READ-ONLY**<br>
**SEMANTIC INFERENCE: NONE**<br>
**PERSISTENCE: NONE**<br>
**PHASE 19 / 21 / 23 / 24 REGRESSION: PASSING**

## Purpose

Phase 25 makes already-persisted Berean knowledge inspectable through a single read-only
operation. It assembles the entity, its associated events, the claims that assert those
events, the authoritative propositions behind those claims, and the full provenance chain
down to Source identity.

> This operation assembles existing Berean knowledge. It does not create, evaluate, or promote knowledge.

Two architectural boundaries are preserved verbatim:

> DIFFERENCE ≠ CONTRADICTION

> SOURCE-BACKED ≠ TRUE

## Route

`GET /api/exploration/timeline`

Accepts exactly one of:

- `entity_id` — a positive integer;
- `entity_key` — an existing non-empty entity key.

### Request validation

| Condition | Status |
| --- | --- |
| Neither identifier supplied | `400` |
| Both identifiers supplied | `400` |
| Malformed `entity_id` (for example `abc`, `1.5`) | `400` |
| Zero or negative `entity_id` | `400` |
| Empty `entity_key` | `400` |
| Duplicated `entity_id` or `entity_key` query parameters | `400` |
| Entity does not exist | `404` |
| Entity exists, even with no associated events or claims | `200` |

An invalid identifier is never silently reinterpreted as a different entity.

## Response structure

```text
operation                     EXPLORE_TIMELINE
input                         echoed entity_id / entity_key
read_only                     true
entity                        entity_id, entity_key, entity_type_code, canonical_name, description
entity_source_mappings        source identities mapped to the canonical entity, with status,
                              confidence, justification, and supporting evidence id
timeline[]                    record_type = RELATED_EVENT
  event                       event_id, event_key, event_type_code, description
  temporal                    temporal_status plus stored typed values only
  claims[]                    record_type = STORED_CLAIM
    claim                     claim_id, claim_key, claim_type_code, claim_status_code, notes,
                              statement, statement_role = DISPLAY_METADATA_ONLY
    proposition               authoritative structured fields, authority =
                              AUTHORITATIVE_STRUCTURED_CONTENT
    predicate                 registered predicate metadata, including any
                              event_participation_role_code
    provenance                provenance_status, source_chain, supporting_evidence (with the
                              ClaimEvidence relation_type_code), citations, source_records,
                              datasets, sources, structural_gaps
    derivation                stored derivation metadata, when the claim is derived
    derivation_inputs         stored derivation inputs, when the claim is derived
    projected_relationships   event_participation rows asserted by this claim
  projected_event_participation
                              every event_participation row for the event, with event, entity,
                              role_code, and asserting claim
entity_claims_without_event   claims about the entity whose proposition references no event
source_comparison             distinct_source_count, comparison_status, per-source descriptions
stored_claim_relations        human-authored ClaimRelation rows among the returned claims
ordering                      the applied deterministic ordering rule
limitations                   explicit non-capabilities of the operation
```

`claim.statement` is returned as display metadata only. The `proposition` remains the
authoritative structured semantic content.

## Deterministic ordering

Timeline entries are ordered by:

1. stored event date/time typed values (`DATE` typed values asserted about the event);
2. existing stored chronological metadata (`YEAR` typed values asserted about the event);
3. the stable `event_id` as the final tie-breaker.

`temporal.temporal_status` reports exactly one of:

- `DATE_KNOWN` — a stored `DATE` typed value is asserted about the event;
- `CHRONOLOGICAL_METADATA_STORED` — a stored `YEAR` typed value is asserted about the event;
- `DATE_NOT_STORED` — no temporal value is stored.

No date is invented, narrated, calculated, or inferred from relationships between events.
Every current Ark event reports `DATE_NOT_STORED`, because no temporal value is stored for it.

## Provenance traversal

The operation reuses the Phase 21 `EXPLAIN_PROVENANCE` traversal helper for every claim
rather than reimplementing provenance semantics:

`Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`

A reader can therefore move from `Entity -> Event -> Claim -> Evidence -> Citation ->
SourceRecord -> Dataset -> Source` without losing source identity.

## Source-text storage policy

`source_record.raw_content = NULL` is reported as `raw_content_status = NOT_STORED_BY_POLICY`.
`citation.quoted_text = NULL` is reported as `quoted_text_status = NOT_STORED_BY_POLICY`.

Neither condition is treated as source silence, absence of source content, or evidence of
anything about the source.

## Source comparison behavior

`source_comparison` groups the returned source-backed claims by Source. Each entry records
the Source identity and a `SOURCE_DESCRIPTION` per claim, with claim identity, display
statement, and citation locators.

`comparison_status` is `DIFFERING_SOURCE_DESCRIPTION` when more than one distinct Source
describes the subject, and `SINGLE_SOURCE_DESCRIPTION` otherwise. Only the neutral labels
`RELATED_EVENT`, `STORED_CLAIM`, `SOURCE_DESCRIPTION`, `SINGLE_SOURCE_DESCRIPTION`, and
`DIFFERING_SOURCE_DESCRIPTION` are produced.

The operation never labels stored material `CONTRADICTION`, `COMPLIANCE`, `VIOLATION`,
`ERROR`, `TRUE`, or `FALSE`. Where a human author has already persisted a classification,
it is surfaced unchanged in `stored_claim_relations` (for example the accepted
Exodus 37:1 / Deuteronomy 10:3 builder `CONTRADICTS` relation), attributed to the stored
`claim_relation` row rather than produced by this operation.

## Projected relationship semantics

`event_participation` is a view projected from claim-asserted propositions. Every projected
row returned by this operation carries
`projection = PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION` and names its asserting claim.
Projected rows are not independently authored authoritative facts, and no second
event-participant store is created or implied.

Predicates deliberately registered without an `event_participation_role_code` — such as
`standingRequirementIn` — still never project participation.

## Read-only guarantee

The endpoint issues only parameterized `SELECT` statements and invokes no persistence
helper. `tests/app/app.test.ts` captures row counts across every public persistent and
registry table before and after an exploration request and asserts they are unchanged.

## Ark examples

`GET /api/exploration/timeline?entity_key=ark_of_covenant` returns, from the accepted
fixtures, the Ark events and their source-backed claims, including:

- Exodus instruction, construction, and contents-placement material;
- Joshua 3:6 transport instruction and priestly carrying;
- 2 Samuel 6:3 new-cart transport and the 2 Samuel 6:6 handling occurrence;
- 1 Samuel 4:4, 4:11, 5:1, 5:2, 7:1, and 7:2 capture, movement, and custody material.

Each claim exposes its evidence, citation locator, source record, dataset, and source, and
each event exposes its projected participation (for example `ark_of_covenant` as `SUBJECT`
and `philistines` as `PARTICIPANT` in `ark_covenant_moved_to_ashdod_1sam5`).

`GET /api/exploration/timeline?entity_id=<id>` behaves identically for the same entity.

## Limitations

- Timeline events are those connected to the entity through a claim-asserted proposition;
  material connected only through other entities is reached by exploring those entities.
- No temporal ordering is available for material whose source stores no date, so most Ark
  events are ordered by stable identifier.
- Durations recorded only in evidence text (for example the twenty years of 1 Samuel 7:2)
  remain evidence text, because no duration predicate is registered.
- No truth, falsity, contradiction, sufficiency, entailment, causation, compliance,
  violation, theological meaning, or source-silence conclusion is produced.
- The operation is query-scoped and ephemeral; nothing it assembles is persisted.
