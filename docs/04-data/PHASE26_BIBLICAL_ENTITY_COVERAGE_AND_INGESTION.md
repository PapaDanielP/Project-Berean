# Phase 26 — Biblical Entity Coverage and Provenance-Aware Ingestion

Phase 26 populates a bounded, source-backed biblical corpus using the architecture accepted in
Phases 19–25. It adds no schema change, no registry change, and no new persistence mechanism.

Two boundaries govern the whole phase:

```text
SOURCE-BACKED IS NOT TRUE
ABSENCE IS NOT SOURCE SILENCE
```

---

## 1. Source boundary

The authoritative source boundary is the biblical text itself, represented through the existing
`source` → `dataset` → `source_record` → `citation` chain.

Phase 26 works inside the corpus already used by accepted fixtures:

| Passage range | Status in Phase 26 |
| --- | --- |
| Genesis 1–11 | already present (Phases 6–19); extended with Genesis 5:12–24 |
| Exodus 25 / 37 / 40, Deuteronomy 10, Joshua 3, 1 Kings 8, Hebrews 9 | already present (Ark lifecycle) |
| 2 Samuel 6 | already present (Phase 18/19) |
| 1 Samuel 4:4, 4:11, 5:1, 5:2, 7:1, 7:2 | ingested by Phase 26 |

External datasets (encyclopedias, external identifier registries, traditional literature) were used
only as discovery aids. No external identifier and no externally asserted fact entered the
authoritative graph. External material is recorded in the candidate worksheet only.

---

## 2. Candidate / reconciliation layer

The smallest repository-native staging artifact that supports the workflow is a CSV worksheet. No
staging table was added, because a file artifact is sufficient: candidate rows are reviewed once and
either ingested as ordinary Berean structures or retained as candidates.

```text
data/candidates/README.md
data/candidates/phase26-entity-candidates.csv
```

Columns preserved:

```text
candidate_key, entity_type, candidate_name, biblical_references,
explicit_textual_description, proposed_proposition, source_status,
external_source, external_identifier, review_status, exclusion_reason,
review_notes, proposed_mapping_decision
```

**Candidate data is not authoritative Berean knowledge.** It is never loaded into the database. The
coverage report reconciles the worksheet against the actual database state and reports
`worksheet_status` beside `actual_status`, so a divergence is visible rather than silent.

---

## 3. Tier policy

| Tier | Content | Treatment in Phase 26 |
| --- | --- | --- |
| Tier 1 | Explicit statements of the source text | Accepted as ordinary Entity/Proposition/Claim/Evidence/Citation structures |
| Tier 2 | Deterministic structural derivation from accepted stored assertions | Allowed via existing `derivation` / `derivation_input`; **no new derivation was required or created in Phase 26** |
| Tier 3 | Interpretive, traditional, harmonized, or externally sourced material | Candidate-only, `CANDIDATE_REQUIRES_REVIEW` or `EXCLUDED` |

No identity, chronology, geography, harmonization, causation, theology, contradiction, compliance,
violation, or source-intent inference was performed.

---

## 4. Ingestion artifact

```text
tests/fixtures/110-phase26-biblical-entity-coverage-fixture.sql
```

The fixture extends the accepted baseline in place. It is loaded last in the fixture chain, after
`100-phase24-berean-in-action-fixture.sql`, because `020-genesis-1-11-fixture.sql` truncates and
re-seeds the core tables.

Repository-native conventions reused without modification:

- source records are locators only: `raw_content`, `content_hash`, and `quoted_text` remain `NULL`
  and are reported as `NOT_STORED_BY_POLICY`;
- citation keys are `CITE_<source_record_key>`;
- evidence keys are `EV_<source_record_key>`;
- every non-derived claim resolves through
  `Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord → Dataset → Source`;
- every `ACTIVE` `entity_source_mapping` carries a justification and supporting evidence from the
  same source;
- typed values are inserted through the existing `typed_value` table with a unit code.

### Part A — Genesis 5:12–24 (the Enoch slice)

New source records on the existing `GEN_MT` / `GEN_MT_REF`: Genesis 5:12, 5:15, 5:18, 5:21, 5:22,
5:23, 5:24.

New entities: `mahalalel`, `jared`, `enoch`, `methuselah` (all `PERSON`).

New events: `mahalalel_begetting`, `jared_begetting`, `enoch_begetting`, `methuselah_begetting`
(all `GENEALOGICAL`).

### Part B — 1 Samuel 4:4–7:2 (Ark material)

New source `1SA_MT` and dataset `1SA_MT_REF` with six locators.

New entities: `eli`, `hophni`, `phinehas_son_of_eli`, `philistines` (`ORGANIZATION`), `ebenezer`,
`ashdod`, `house_of_dagon_ashdod`, `kiriath_jearim`, `abinadab`, `eleazar_son_of_abinadab`.

The Ark itself remains one canonical entity described by multiple sources. No second Ark entity was
created, and no reconciliation across sources was invented.

---

## 5. Enoch end-to-end workflow

Enoch was the reported gap: the entity did not exist in Berean before this phase.

1. **Locate.** Enoch is explicitly named in the selected corpus at Genesis 5:18, 5:21, 5:22, 5:23,
   and 5:24.
2. **Restrict to explicit statements.** Only what the text states directly was modeled.
3. **Represent.** Entity `enoch`; propositions `jared fatherOf enoch`, `enoch fatherOf methuselah`,
   `enoch ageAtFatherhoodYears 65 (YEAR)`, `enoch childIn enoch_begetting`,
   `enoch parentIn methuselah_begetting`.
4. **Support.** Five direct source claims, each backed by evidence, citation, source record,
   dataset, and source.
5. **Project.** `event_participation` rows are projected from the claim-asserted propositions; no
   participant was authored directly.

Complete chain, as emitted by the coverage report:

| claim_key | subject | predicate | object | citation | source_record | dataset | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `CLAIM_MT_JARED_FATHER_ENOCH` | jared | fatherOf | enoch | Genesis 5:18 | `MT_GEN_5_18` | `GEN_MT_REF` | `GEN_MT` |
| `CLAIM_ENOCH_CHILD_ENOCH_BEGETTING` | enoch | childIn | enoch_begetting | Genesis 5:18 | `MT_GEN_5_18` | `GEN_MT_REF` | `GEN_MT` |
| `CLAIM_MT_ENOCH_FATHER_METHUSELAH` | enoch | fatherOf | methuselah | Genesis 5:21 | `MT_GEN_5_21` | `GEN_MT_REF` | `GEN_MT` |
| `CLAIM_MT_ENOCH_AGE_AT_METHUSELAH_65` | enoch | ageAtFatherhoodYears | 65 | Genesis 5:21 | `MT_GEN_5_21` | `GEN_MT_REF` | `GEN_MT` |
| `CLAIM_ENOCH_PARENT_METHUSELAH_BEGETTING` | enoch | parentIn | methuselah_begetting | Genesis 5:21 | `MT_GEN_5_21` | `GEN_MT_REF` | `GEN_MT` |

All five report `raw_content_status = NOT_STORED_BY_POLICY` and
`quoted_text_status = NOT_STORED_BY_POLICY`.

### Deliberately not modeled for Enoch

| Item | Reason |
| --- | --- |
| Genesis 5:22 "walked with God" and unnamed other sons and daughters | No non-interpretive predicate; unnamed persons are not entities |
| Genesis 5:23 "365 years" | `ageAtDeathYears` would assert a death the text does not state |
| Genesis 5:24 "was not, for God took him" | Reading it as death, translation, or ascension is interpretation |
| Enoch son of Cain (Genesis 4:17) | Identity inference; the two names are not asserted to be one person or two |
| Enoch as author of *1 Enoch* | Outside the source boundary |
| External chronological dating | Outside the source boundary |

Each retained observation is stored as cited `Evidence` with an explanatory `notes` value and backs
no claim. Evidence without a claim is availability of source material, never source silence.

---

## 6. Coverage inventory

```text
tests/validation/phase26-coverage-report.sql
```

The same report runs immediately before and immediately after ingestion in
`scripts/validation/run-postgres-validation.sh`, so the before/after comparison is reproducible on a
clean database.

Sections: summary counts; entities by type; claims by type and status; source/dataset/source-record
coverage; represented books and passages; entity reachability with `coverage_status`; entities with
no claims; claims with incomplete provenance; source records with no modeled claim; named-entity
corpus reconciliation; the Enoch end-to-end chain; unmodeled observations retained as evidence.

### Before / after

| Metric | Before | After | Δ |
| --- | ---: | ---: | ---: |
| sources | 9 | 10 | +1 |
| datasets | 9 | 10 | +1 |
| source records | 62 | 75 | +13 |
| citations | 62 | 75 | +13 |
| evidence | 64 | 77 | +13 |
| entities | 46 | 60 | +14 |
| propositions | 137 | 170 | +33 |
| claims | 150 | 183 | +33 |
| events | 41 | 52 | +11 |
| projected participations | 101 | 122 | +21 |
| derivations | 3 | 3 | 0 |
| derivation inputs | 6 | 6 | 0 |

Entities by type:

| Type | Before | After | Δ |
| --- | ---: | ---: | ---: |
| CONCEPT | 24 | 24 | 0 |
| OBJECT | 12 | 12 | 0 |
| ORGANIZATION | 1 | 2 | +1 |
| PERSON | 8 | 17 | +9 |
| PLACE | 1 | 5 | +4 |

Claims by type and status after ingestion: `DIRECT_SOURCE_CLAIM/ACTIVE` 179,
`DIRECT_SOURCE_CLAIM/SUPERSEDED` 1, `DERIVED_CLAIM/ACTIVE` 3. Claims with incomplete provenance: 0.

### Coverage classifications

| Classification | Meaning |
| --- | --- |
| `DIRECTLY_REPRESENTED` | Explicit source statement modeled as Entity/Proposition/Claim with full provenance |
| `DERIVED_STRUCTURALLY` | Produced by an existing `derivation` from accepted stored assertions |
| `CANDIDATE_REQUIRES_REVIEW` | Named or observed in the corpus but not safely representable yet |
| `EXCLUDED` | Outside the source boundary, or representable only through interpretation |
| `NOT_YET_MODELED` | Source material exists as evidence but backs no claim |

---

## 7. Explorer sparse-state semantics

`GET /api/exploration/timeline` remains the only exploration route. No new API was added. The
response now carries a `coverage` block assembled by read-only `SELECT` statements:

```json
{
  "coverage": {
    "coverage_status": "EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED",
    "entity_type": "PERSON",
    "claim_count": 5,
    "event_count": 2,
    "source_count": 1,
    "provenance_status": "COMPLETE_SOURCE_CHAIN",
    "modeled_reference_count": 2,
    "candidate_reference_count": 3,
    "related_source_material_status": "RELATED_SOURCE_MATERIAL_NOT_YET_MODELED",
    "labels": ["SOURCE-BACKED", "CANDIDATE-REQUIRES-REVIEW"]
  }
}
```

`coverage_status` values:

| Value | Condition |
| --- | --- |
| `NO_ENTITY_FOUND` | returned in the `404` body when the subject does not exist |
| `ENTITY_EXISTS_NO_CLAIMS` | entity exists, no claim references it |
| `CLAIMS_EXIST_NO_PROVENANCE` | claims exist, no source chain resolves |
| `ENTITY_EXISTS_NO_EVENTS` | claims and sources exist, no event is associated |
| `EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED` | full chain resolves and every source record is a locator |
| `EVIDENCE_EXISTS_SOURCE_TEXT_STORED` | full chain resolves and stored source text exists |

`candidate_reference_count` counts source records whose stored observation mentions the entity's
canonical name but which back no claim about that entity. When it is non-zero the response reports
`RELATED_SOURCE_MATERIAL_NOT_YET_MODELED`. For Enoch this surfaces Genesis 5:22–5:24 as available
but unmodeled — the opposite of pretending the source is silent.

Labels applied: `SOURCE-BACKED`, `DERIVED-STRUCTURALLY`, `NOT-YET-MODELED`,
`CANDIDATE-REQUIRES-REVIEW`. No label asserts truth, falsity, or contradiction.

---

## 8. Validation

```text
tests/validation/phase26-biblical-entity-coverage-slice.sql
```

Executable assertions covering: baseline presence; registry immutability (22 predicates, 8 event
types, 5 entity types, 5 participation roles); single-instance entities with justified,
evidence-backed `ACTIVE` mappings; locator-only source records; the Enoch end-to-end chain and its
projected participation; the Enoch exclusions (no death event, no `ageAtDeathYears`, no
`yearsFromCreation`, no non-direct claim); unmodeled evidence retained, cited, and unattached;
identity boundaries (`enoch_son_of_cain` must not exist); a bounded 1 Samuel slice with no asserted
captor at 1 Samuel 4:11 and no claim relations; and the Ark remaining one canonical entity described
by at least five distinct sources.

Application tests in `tests/app/app.test.ts` cover the Enoch end-to-end response, the unmodeled
Genesis 5:22–24 observations surfacing as candidates, sparse-state coverage metadata,
`NO_ENTITY_FOUND`, 1 Samuel people and places explorable with `1SA_MT` provenance, Joshua 3 /
1 Samuel 5 / 2 Samuel 6 remaining distinct and unclassified, and a before/after row-count assertion
proving the exploration route mutates nothing.

Executed on clean disposable databases:

| Command | Result |
| --- | --- |
| `npm run lint` | PASS |
| `npm run typecheck` | PASS |
| `npm run build` | PASS |
| `npm test` | PASS (33/33) |
| `scripts/validation/run-postgres-validation.sh` | PASS (exit 0) |

---

## 9. Schema sufficiency

The existing schema was sufficient. No schema change, no registry change, and no persistence change
was made. Existing structures absorbed the entire corpus.

What the phase did discover are **registry expressiveness gaps**. Each was deliberately left
unresolved rather than papered over by adding predicates to increase coverage:

1. Genesis 5:23 "365 years" — only `ageAtDeathYears` exists, and using it would assert a death.
2. Genesis 5:22 / 5:24 — no non-interpretive predicate for "walked with God" or "God took him".
3. 1 Samuel 5:1 — `occursAt` records place association only, so origin and destination cannot be
   distinguished; both Ebenezer and Ashdod are recorded as `occursAt`.
4. 1 Samuel 7:1 — no custodial or consecration predicate.
5. 1 Samuel 7:2 — "twenty years" is a duration, while `yearsFromCreation` expresses a position.

Additionally, `Dagon` has no non-interpretive `entity_type_code` in the current controlled
vocabulary, so only `house_of_dagon_ashdod` (`PLACE`) was modeled; the referent remains a candidate.

---

## 10. Limitations

- Coverage is bounded to the passages listed in section 1. Absence of any other passage is
  unmodeled scope, not source silence.
- Twelve source records currently back no claim; they are reported as `NOT_YET_MODELED`.
- `candidate_reference_count` matches on canonical name within stored observations. It is a
  discovery hint for an analyst, not an assertion that the record is about the entity.
- No temporal position is stored for the new events, so the timeline reports them as
  `DATE_NOT_STORED`. No date was invented.
- The candidate worksheet is reviewed manually; there is no automated ingestion path from CSV to
  database, by design.
- The browser explorer UI was not redesigned. The coverage metadata is exposed through the existing
  API response.

---

## 11. Phase 26 report

```text
PHASE 26 STATUS: COMPLETE

DATA COVERAGE
  before: 9 sources, 9 datasets, 62 source records, 62 citations, 64 evidence,
          46 entities, 137 propositions, 150 claims, 41 events,
          101 projected participations, 3 derivations, 6 derivation inputs
  after:  10 sources, 10 datasets, 75 source records, 75 citations, 77 evidence,
          60 entities, 170 propositions, 183 claims, 52 events,
          122 projected participations, 3 derivations, 6 derivation inputs

NEW ENTITIES: 14
  people: 9   (mahalalel, jared, enoch, methuselah, eli, hophni,
               phinehas_son_of_eli, abinadab, eleazar_son_of_abinadab)
  places: 4   (ebenezer, ashdod, house_of_dagon_ashdod, kiriath_jearim)
  organizations: 1 (philistines)
  objects: 0
  events: 11  (4 GENEALOGICAL, 5 OTHER, 2 DEATH)

NEW SOURCE RECORDS: 13
NEW EVIDENCE: 13
NEW PROPOSITIONS: 33
NEW CLAIMS: 33
NEW DERIVATIONS: 0
NEW DERIVATION INPUTS: 0

SOURCE-BACKED: 33 new claims, all with a complete chain
DERIVED-STRUCTURALLY: 0 added (3 pre-existing derived claims unchanged)
CANDIDATE-REQUIRES-REVIEW: 5 worksheet rows
NOT-YET-MODELED: 12 source records with evidence and no claim
EXCLUDED: 4 worksheet rows

PROVENANCE: complete 180 / incomplete 0
  (180 non-derived claims resolve a full source chain; the 3 pre-existing derived
   claims resolve through derivation inputs rather than direct evidence)

SCHEMA CHANGE: NONE
REGISTRY CHANGE: NONE
ARCHITECTURAL CHANGE: NONE
  (one additive read-only coverage block on the existing timeline response)

SCHEMA INSUFFICIENCIES DISCOVERED: NONE
  Five registry expressiveness gaps were recorded and deliberately left unresolved:
  Genesis 5:23 duration vs ageAtDeathYears; Genesis 5:22/5:24 non-interpretive
  representation; 1 Samuel 5:1 origin/destination direction; 1 Samuel 7:1 custody
  and consecration; 1 Samuel 7:2 duration vs chronological position.

DATA LIMITATIONS: bounded corpus; no stored source text by policy
INGESTION LIMITATIONS: manual candidate review; no automated CSV import path
USABILITY LIMITATIONS: browser UI unchanged; coverage exposed through the API

ENOCH END-TO-END STATUS: COMPLETE
  entity + 5 source-backed claims + 5 propositions + 2 events + full chain to GEN_MT,
  with 3 explicitly unmodeled observations retained as cited evidence.

REGRESSION
  Phase 19: PASS
  Phase 21: PASS
  Phase 23: PASS
  Phase 24: PASS
  Phase 25: PASS

SECURITY / STATIC ANALYSIS: secret scanning clean; CodeQL clean

FINAL ASSESSMENT
  The existing model represented the entire selected corpus without modification.
  Berean now holds a bounded, inspectable, fully source-backed slice in which the
  reported Enoch gap is closed end to end, and sparse coverage is reported honestly
  rather than hidden.
```

---

## 12. Closing statements

```text
This phase assembles and ingests explicit source statements.
It does not create, evaluate, harmonize, or promote knowledge.

DIFFERENCE IS NOT CONTRADICTION
SOURCE-BACKED IS NOT TRUE
ABSENCE IS NOT SOURCE SILENCE
NOT_STORED_BY_POLICY IS NOT UNSUPPORTED
```
