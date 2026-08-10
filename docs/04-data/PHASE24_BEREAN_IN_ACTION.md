# Phase 24 — Berean in Action: Real Knowledge Construction Demonstration

**PHASE 24 STATUS:** implemented as fixture data, read-only demonstrations, validation, and documentation  
**ARCHITECTURAL STATUS:** existing model remained sufficient  
**SCHEMA CHANGE:** none  
**REGISTRY CHANGE:** none  
**READ-ONLY API CHANGE:** no new endpoint; existing Phase 21 and Phase 23 endpoints are demonstrated  
**EVALUATION-IS-NOT-KNOWLEDGE:** preserved

Phase 24 transitions from architecture validation to an inspectable knowledge-construction demonstration using the existing Berean relational substrate. It extends the accepted Ark-of-the-Covenant material with a bounded temple-placement slice from **1 Kings 8:1, 8:3, 8:4, 8:6, 8:9** and **2 Chronicles 5:2, 5:4, 5:5, 5:7, 5:10**.

The slice is deliberately modest but coherent: Solomon assembles Israelite leaders; priestly/Levitical participants bring up the Ark, tent of meeting, and holy vessels; the Ark is placed in the inner sanctuary; the temple-placement contents statements from 1 Kings and 2 Chronicles are compared with explicit provenance.

## Files added or extended

- `tests/fixtures/100-phase24-berean-in-action-fixture.sql`
- `tests/validation/phase24-berean-in-action-slice.sql`
- `tests/validation/phase24-coverage-report.sql`
- `tests/app/app.test.ts`
- `scripts/validation/run-postgres-validation.sh`
- `docs/04-data/PHASE24_BEREAN_IN_ACTION.md`

## Data scope

### New sources and datasets

| Source | Dataset | Scope |
| --- | --- | --- |
| `1KI_MT` — 1 Kings, Masoretic textual tradition | `1KI_MT_REF` | Manually entered reference points for selected 1 Kings 8 Ark temple-placement locators |
| `2CH_MT` — 2 Chronicles, Masoretic textual tradition | `2CH_MT_REF` | Manually entered reference points for selected 2 Chronicles 5 Ark temple-placement locators |

As in earlier phases, no source text is stored. `source_record.raw_content`, `source_record.content_hash`, and `citation.quoted_text` remain `NULL` for this manually entered reference-point slice. Phase 21 reports those nulls as `NOT_STORED_BY_POLICY`, not as source silence.

### New referents

Phase 24 adds only the persistent referents needed for the bounded slice:

- `solomon` (`PERSON`)
- `elders_of_israel_solomon_assembly` (`ORGANIZATION`)
- `priests_levites_temple_ark_bearers` (`ORGANIZATION`)
- `solomon_temple_inner_sanctuary` (`PLACE`)
- `tent_of_meeting` (`OBJECT`)
- `sanctuary_vessels_temporal_slice` (`OBJECT`)

The existing `ark_of_covenant` entity is reused. No duplicate Ark entity is created.

### New events

All new events use the existing generic `OTHER` event type:

- `ark_covenant_temple_assembly`
- `ark_covenant_temple_transfer`
- `ark_covenant_temple_placement`

These are descriptive historical occurrences only. They do not encode compliance, violation, causation, theology, pole/ring physical state, route, duration, or inference from source difference.

## Coverage summary

The Phase 24 validation report demonstrates the following scoped additions:

| Structure | Phase 24 count |
| --- | ---: |
| Sources | 2 |
| Datasets | 2 |
| Source records | 10 |
| Citations | 10 |
| Evidence observations | 10 |
| Direct source claims | 22 |
| Derived claims | 1 |
| Derivation inputs | 2 |

The count is not the main success criterion. The important property is that every direct source claim has a full source-backed path and that the one derived claim has explicit claim inputs.

## Complete provenance examples

The fixture and validation demonstrate complete paths of the form:

`Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`

Examples:

| Claim | Evidence | Citation | Source record | Dataset | Source |
| --- | --- | --- | --- | --- | --- |
| `CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT` | `EV_MT_1KI_8_6` | `CITE_MT_1KI_8_6` | `MT_1KI_8_6` | `1KI_MT_REF` | `1KI_MT` |
| `CLAIM_2CH_ARK_SUBJECT_TEMPLE_PLACEMENT` | `EV_MT_2CH_5_7` | `CITE_MT_2CH_5_7` | `MT_2CH_5_7` | `2CH_MT_REF` | `2CH_MT` |
| `CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION` | `EV_MT_1KI_8_9` | `CITE_MT_1KI_8_9` | `MT_1KI_8_9` | `1KI_MT_REF` | `1KI_MT` |
| `CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION` | `EV_MT_2CH_5_10` | `CITE_MT_2CH_5_10` | `MT_2CH_5_10` | `2CH_MT_REF` | `2CH_MT` |

## Proposition exploration and multiple claims

Phase 24 reuses the existing `ark_of_covenant containsContent tablets_of_testimony` proposition. It now has multiple coexisting claims:

- `CLAIM_ARK_COVENANT_CONTAINS_TESTIMONY` — Exodus 40:20 direct source claim from Phase 16.
- `CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION` — 1 Kings 8:9 direct source claim.
- `CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION` — 2 Chronicles 5:10 direct source claim.
- `CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED` — Phase 24 derived comparison claim.

The proposition remains the structured semantic authority. The claim statements are display/explanation text, not a second semantic authority.

## Source differences preserved

Phase 24 demonstrates source comparison without automatic resolution:

- 1 Kings records priestly/Levitical participation in the temple-transfer sequence with `EV_MT_1KI_8_3` and `EV_MT_1KI_8_4`.
- 2 Chronicles records related priestly/Levitical participation with `EV_MT_2CH_5_4` and `EV_MT_2CH_5_5`.
- Both source-backed descriptions coexist on normalized event-participation propositions.
- No `ClaimRelation` is created between 1 Kings and 2 Chronicles claims merely because details differ.
- The existing Exodus 37:1 / Deuteronomy 10:3 builder difference from Phase 16 remains a separate preserved source-difference example.

## Event exploration

The new events are explorable through the existing event APIs and the `event_participation` view. Participation is projected from asserted claims using existing predicates:

- `subjectOf` projects `SUBJECT`.
- `participatesIn` projects `PARTICIPANT`.
- `occursAt` records event location without creating event participation.

The placement event has source-backed projected participation from both 1 Kings and 2 Chronicles:

- `ark_of_covenant` as `SUBJECT`.
- `priests_levites_temple_ark_bearers` as `PARTICIPANT`.

The placement event also has explicit location claims:

- `CLAIM_1KI_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY`
- `CLAIM_2CH_TEMPLE_PLACEMENT_OCCURS_AT_INNER_SANCTUARY`

## Derivation example

Phase 24 includes one genuine derived-claim example:

- Derived claim: `CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED`
- Method: `Cross-source comparison of normalized Ark contents propositions in the temple-placement slice`
- Inputs:
  - `CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION`
  - `CLAIM_2CH_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION`

This derived claim records structural agreement between the selected 1 Kings and 2 Chronicles source-backed claims on the existing normalized proposition. It does **not** infer exhaustive inventory, truth, source silence, contradiction, sufficiency, theology, or a global factual core.

## Demonstration queries

The executable examples are in `tests/validation/phase24-coverage-report.sql`. They cover:

1. Coverage summary for sources, datasets, source records, citations, evidence, claims, derivations, and derivation inputs.
2. Full provenance examples from claim to source.
3. Proposition exploration with multiple source-backed and derived claims.
4. Source comparison preserving differences without automatic contradiction.
5. Event exploration through projected participation and explicit location propositions.
6. Derivation explanation through stored method, assumptions, and inputs.

Run them through the full validation script:

```sh
DATABASE_URL=<clean disposable PostgreSQL database> scripts/validation/run-postgres-validation.sh
```

## API demonstrations

Phase 24 does not add endpoints. It demonstrates the existing Phase 21 and Phase 23 read-only endpoints with new data.

### Provenance explanation

Example lookup after loading the fixture:

```sql
SELECT claim_id
FROM claim
WHERE claim_key = 'CLAIM_1KI_ARK_SUBJECT_TEMPLE_PLACEMENT';
```

Then call:

```http
GET /api/provenance/explain?claim_id=<claim_id>
```

Expected behavior:

- `operation = EXPLAIN_PROVENANCE`
- `read_only = true`
- complete source-backed traversal through `1KI_MT_REF` / `1KI_MT`
- `raw_content_status = NOT_STORED_BY_POLICY`
- `quoted_text_status = NOT_STORED_BY_POLICY`
- no mutation of persistent table counts

For proposition-level exploration:

```sql
SELECT proposition_id
FROM claim
WHERE claim_key = 'CLAIM_1KI_ARK_CONTAINS_TABLETS_ONLY_SOURCE_DESCRIPTION';
```

Then call:

```http
GET /api/provenance/explain?proposition_id=<proposition_id>
```

Expected behavior: the response returns the Exodus, 1 Kings, 2 Chronicles, and derived comparison claims that assert the same normalized proposition.

### Derivation eligibility

Example lookup:

```sql
SELECT derivation_id
FROM claim
WHERE claim_key = 'CLAIM_XSRC_ARK_CONTAINS_TABLETS_TEMPLE_SHARED_DERIVED';
```

Then call:

```http
GET /api/derivations/check-eligibility?derivation_id=<derivation_id>
```

Expected behavior:

- `operation = CHECK_DERIVATION_ELIGIBILITY`
- `structurally_eligible = true`
- stored method and assumptions returned without semantic interpretation
- two input claims reported
- `license_status = REQUIRES_HUMAN_METHOD_JUSTIFICATION`
- limitation remains: structural eligibility is not logical entailment
- no mutation of persistent table counts

These API behaviors are covered by `tests/app/app.test.ts`.

## Deliberately unmade conclusions

Phase 24 intentionally does not assert:

- that the 1 Kings and 2 Chronicles accounts are identical in every detail;
- that any source is exhaustive because it mentions tablets;
- that missing stored source text means source silence;
- that the Ark was or was not compliant with Exodus 25:15 during the temple transfer;
- that Joshua 3, 2 Samuel 6, 1 Kings 8, and 2 Chronicles 5 contradict one another merely because they describe different Ark-handling contexts;
- theological meaning of the Ark, temple, cherubim, cloud, glory, or covenant;
- causation, violation, punishment, obedience, sufficiency, entailment, truth, or falsity;
- a canonical factual core promoted from multiple sources.

## Problems discovered and classification

No architectural deficiency requiring schema, registry, predicate, event-type, persistence, or API redesign was discovered.

Observed limitations are classified as expected model boundaries rather than defects:

| Limitation | Classification | Phase 24 handling |
| --- | --- | --- |
| Fine-grained distinctions among priests, Levites, and offices can vary by source wording | Data/usability precision limit | Scoped collective entity `priests_levites_temple_ark_bearers`; source identities remain distinct |
| The model can record placement and location but not infer compliance with a standing requirement | Deliberate semantic boundary | No compliance/violation claim or relation added |
| Source descriptions can be compared structurally, but semantic identity/exhaustiveness is not automatic | Deliberate evaluation boundary | One explicit derived comparison only for the selected normalized proposition |
| No source text is stored for these locators | Storage-policy limitation | Citations and source records remain locator-only; Phase 21 reports `NOT_STORED_BY_POLICY` |

## Existing model sufficiency

The existing Berean model remained sufficient for this phase. The demonstration used only:

- `Source`, `Dataset`, `SourceRecord`, `Citation`, `Evidence`, `EvidenceCitation`
- `Entity`, `SourceIdentity`, `EntitySourceMapping`
- `Event`
- `Proposition`
- `Claim`, `ClaimEvidence`
- `Derivation`, `DerivationInput`
- existing predicate and event-type registries
- existing `event_participation` projection
- existing Phase 21 and Phase 23 read-only APIs

No schema, registry, persistence, semantic-engine, evaluator, classifier, or mutation endpoint change was justified.

## Validation status

Validated on a clean disposable PostgreSQL database and app test database during implementation:

- `npm run lint` — passed
- `npm run typecheck` — passed
- `npm run build` — passed
- `npm test` — passed, 24 tests
- `scripts/validation/run-postgres-validation.sh` — passed, including Phase 19 positive/coverage/negative behavior and Phase 24 fixture/coverage validation

The app tests include read-only table-count checks for both:

- `GET /api/provenance/explain`
- `GET /api/derivations/check-eligibility`

## Highest-value next architectural question

The highest-value next question is not a new schema element by default. Based on actual usage, the next useful question is:

**Can Berean provide a read-only dependency-impact view over existing Claim, Evidence, DerivationInput, ClaimRelation, and projected event-participation edges while clearly reporting only structural dependencies, not truth consequences or semantic invalidation?**

That question should remain read-only and query-scoped unless a separate accepted phase justifies more.
