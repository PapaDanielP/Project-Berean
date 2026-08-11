# PHASE 36 EVIDENCE AUDIT

## 1. Executive Summary

Classification: **PASS WITH INTENTIONAL LIMITATION**

What this audit verified from direct evidence:
- Phase 36 Stage A population is present, idempotent, and provenance-backed for direct claims.
- Candidate boundaries for Day One, Day Two ordering, unresolved Mrs. Mott identity, and isolated historiography are implemented as represented.
- Stage B is read-only and preserves persistent counts.
- Explorer/API endpoints are read-only and bounded on a Phase 36-only substrate.

What is not demonstrated:
- **NOVEL_RESEARCH_TEST: NOT DEMONSTRATED** (no withheld graph-derived probe analogous to Phase 33 Q8–Q10).

## 2. Candidate Boundary Audit

| Candidate | Intended boundary | Actual implementation evidence | Result |
| --- | --- | --- | --- |
| `P36_DAY_ONE` | Accepted/ingested; direct source-backed claim using registered `occursAt`; no historical-priority assertion | `CLAIM_P36_DAY_ONE_OCCURS_AT_WESLEYAN_CHAPEL` uses predicate `occursAt`, subject `phase36_seneca_falls_day_one_1848`, object `phase36_wesleyan_chapel`; claim type `DIRECT_SOURCE_CLAIM`; no Phase 36 proposition uses primacy/truth predicates | **PASS** |
| `P36_DAY_TWO` | Accepted/ingested; direct source-backed ordering-only claim using registered `precedes`; no general calendar-date predicate | `CLAIM_P36_DAY_ONE_PRECEDES_DAY_TWO` uses predicate `precedes` with required subject/object events; Phase 36 predicates observed: `occursAt`(2), `participatesIn`(4), `precedes`(1); `occursOnDate` occurrences = 0 | **PASS** |
| `P36_MRS_MOTT_IDENTITY` | Unresolved source identity; justified `PROPOSED` mapping; not ACTIVE; no `sameAs` proposition | `source_identity_key=phase36-proceedings-mrs-mott` mapped `PROPOSED` to `phase36_lucretia_mott` with justification + supporting evidence id; ACTIVE count for this identity = 0; `sameAs` proposition occurrences touching Phase 36 = 0 | **PASS** |
| `P36_HISTORIOGRAPHY` | Scholarly-position candidate, not-yet-modeled; two cited analytical observations; zero claim_evidence links; no contradiction/truth ranking/consensus claim | `EV_P36_WELLMAN_INTERPRETATION` and `EV_P36_TETRAULT_INTERPRETATION` are `ANALYTICAL_OBSERVATION` with claim links = 0; `claim_relation` touching Phase 36 = 0; `contradicts/preferredOver/strongerThan/supportsTheory/confirmsTheory/refutesTheory` occurrences = 0 | **PASS** |

## 3. Population Fidelity

Executed on empty schema with:
- `schema/sql/001_core_schema.sql`
- `tests/fixtures/143-phase36-seneca-falls-domain-population-fixture.sql`

Observed Phase 36 inventory counts:
- `source=4`, `dataset=4`, `source_record=5`, `citation=5`, `source_identity=3`, `entity_source_mapping=3`, `entity=6`, `event=2`, `proposition=7`, `claim=6`, `evidence=5`, `claim_evidence=7`, `claim_relation=0`.

All six Phase 36 claims are `DIRECT_SOURCE_CLAIM` and ACTIVE.

## 4. Provenance Verification

Query used (exact chain):
`claim -> proposition -> claim_evidence -> evidence -> evidence_citation -> citation -> source_record -> dataset -> source`

Observed direct Phase 36 provenance rows (7 rows total due dual-source support on Douglass claim):
- `CLAIM_P36_DAY_ONE_OCCURS_AT_WESLEYAN_CHAPEL -> EV_P36_DAY_ONE -> CITE_P36_PROCEEDINGS_DAY_ONE -> P36_PROCEEDINGS_DAY_ONE -> SENECA_FALLS_PROCEEDINGS_P36 -> SENECA_FALLS_PROCEEDINGS_1848`
- `CLAIM_P36_DAY_ONE_PRECEDES_DAY_TWO -> EV_P36_DAY_TWO -> CITE_P36_PROCEEDINGS_DAY_TWO -> ... -> SENECA_FALLS_PROCEEDINGS_1848`
- `CLAIM_P36_DAY_TWO_OCCURS_AT_WESLEYAN_CHAPEL -> EV_P36_DAY_TWO -> ...`
- `CLAIM_P36_DOUGLASS_PARTICIPATES_IN_DAY_TWO -> EV_P36_DAY_TWO -> ... -> SENECA_FALLS_PROCEEDINGS_1848`
- `CLAIM_P36_DOUGLASS_PARTICIPATES_IN_DAY_TWO -> EV_P36_NORTH_STAR_ACCOUNT -> CITE_P36_NORTH_STAR_CONVENTION_REPORT -> ... -> NORTH_STAR_1848_SENECA_FALLS`
- `CLAIM_P36_MOTT_PARTICIPATES_IN_DAY_ONE -> EV_P36_DAY_ONE -> ...`
- `CLAIM_P36_STANTON_PARTICIPATES_IN_DAY_ONE -> EV_P36_DAY_ONE -> ...`

Result: **PASS**

## 5. Identity Boundary Verification

Observed Phase 36 source-identity mappings:
- `phase36-proceedings-stanton` -> ACTIVE -> `phase36_elizabeth_cady_stanton`.
- `phase36-north-star-douglass` -> ACTIVE -> `phase36_frederick_douglass`.
- `phase36-proceedings-mrs-mott` -> **PROPOSED** -> `phase36_lucretia_mott` with explicit justification.

No ACTIVE mapping for `phase36-proceedings-mrs-mott`. No `sameAs` proposition persisted for Phase 36.

Result: **PASS**

## 6. Scholarly Isolation Verification

Observed evidence rows:
- `EV_P36_WELLMAN_INTERPRETATION` (`ANALYTICAL_OBSERVATION`) claim links = 0.
- `EV_P36_TETRAULT_INTERPRETATION` (`ANALYTICAL_OBSERVATION`) claim links = 0.

Observed Phase 36 claim_relation count: 0.

Result: **PASS**

## 7. Independent Stage B Research

Inspected:
- `tests/validation/phase36-seneca-falls-independent-query-validation.sql`

Findings:
- Uses `CREATE TEMP TABLE phase36_counts_before` and `BEGIN READ ONLY`.
- Contains only retrieval queries over persisted claims/evidence/mapping.
- No inserts into answer/result persistence tables.
- No question IDs, expected-result constants, or query-to-answer storage.

Returned Stage B rows:
- 6 direct claims (rendered propositions + sources)
- 2 scholarly analytical observations (`SCHOLARLY_CANDIDATE_NOT_PROMOTED`)
- 1 unresolved identity row (`Mrs. Mott` PROPOSED)

Classification: **PASS WITH INTENTIONAL LIMITATION** (bounded read-only retrieval demonstrated).

## 8. Novel Query Assessment

Required novel withheld/graph-derived probe analogous to Phase 33 Q8–Q10:
- Not found in Phase 36 Stage B SQL.
- No evidence of hidden answer tables, expected-answer constants, or post-population stored answer mappings for Phase 36.
- Stage B outputs are direct listings of already-modeled structures, not novel derivations beyond Stage A-stated material.

**NOVEL_RESEARCH_TEST: NOT DEMONSTRATED**

## 9. Explorer Integration

Executed read-only API interrogation on Phase 36-only loaded database via `src/app.ts` routes.

Observed HTTP status = 200 for:
- `GET /api/research/scope`
- `POST /api/research` (all/single/multiple/excluded dataset scope)
- `GET /api/search?q=Mott&limit=20`
- supported question and unsupported question flows

Key observations:
- Scope discovery returned four P36 datasets (`SENECA_FALLS_PROCEEDINGS_P36`, `NORTH_STAR_SENECA_FALLS_P36`, `WELLMAN_2004_P36`, `TETRAULT_2014_P36`).
- `POST /api/research` includes inspectable plan fields (`classification`, `scope`, `candidate_predicates`, `traversal`, `provenance_requirement`).
- Supported question returned bounded, provenance-bearing results with capability `ESTABLISHED`.
- Unsupported truth/proof question returned capability `NOT_REPRESENTED` and empty results.
- `GET /api/search` returned keyword matches across types (`claim`, `entity`, `evidence`, `source_identity`) with no claim-establishment classification field (`hasClassificationField=false`).

Result: **PASS**

## 10. Read-Only Verification

Persistent-count snapshots across required tables:

### Stage B SQL interrogation
Before and after Stage B:
- `source=4, dataset=4, source_record=5, citation=5, source_identity=3, entity_source_mapping=3, entity=6, event=2, proposition=7, claim=6, evidence=5, claim_evidence=7, claim_relation=0`
- BEFORE = AFTER

### Explorer/API interrogation
Before and after endpoint calls:
- Same count vector as above
- `countsEqual=true`

Exact count query used:

```sql
SELECT (SELECT count(*) FROM source) AS source,
       (SELECT count(*) FROM dataset) AS dataset,
       (SELECT count(*) FROM source_record) AS source_record,
       (SELECT count(*) FROM citation) AS citation,
       (SELECT count(*) FROM source_identity) AS source_identity,
       (SELECT count(*) FROM entity_source_mapping) AS entity_source_mapping,
       (SELECT count(*) FROM entity) AS entity,
       (SELECT count(*) FROM event) AS event,
       (SELECT count(*) FROM proposition) AS proposition,
       (SELECT count(*) FROM claim) AS claim,
       (SELECT count(*) FROM evidence) AS evidence,
       (SELECT count(*) FROM claim_evidence) AS claim_evidence,
       (SELECT count(*) FROM claim_relation) AS claim_relation;
```

Exact Phase 36 interpretation-predicate scan:

```sql
WITH p36_props AS (
  SELECT p.proposition_id, p.predicate
  FROM proposition p
  LEFT JOIN entity se ON se.entity_id=p.subject_entity_id
  LEFT JOIN event sv ON sv.event_id=p.subject_event_id
  LEFT JOIN entity oe ON oe.entity_id=p.object_entity_id
  LEFT JOIN event ov ON ov.event_id=p.object_event_id
  WHERE coalesce(se.entity_key,sv.event_key,'') LIKE 'phase36_%'
     OR coalesce(oe.entity_key,ov.event_key,'') LIKE 'phase36_%'
),
scan(predicate_name) AS (
  VALUES ('sameAs'),('contradicts'),('preferredOver'),('strongerThan'),
         ('supportsTheory'),('confirmsTheory'),('refutesTheory'),
         ('occursOnDate'),('yearsFromCreation')
)
SELECT s.predicate_name, count(p.proposition_id) AS proposition_occurrences
FROM scan s
LEFT JOIN p36_props p ON p.predicate = s.predicate_name
GROUP BY s.predicate_name
ORDER BY s.predicate_name;
```

Result: **PASS**

## 11. Replay and Idempotence

Evidence:
- Empty-schema replay: second run of `143-phase36` fixture produced only `INSERT 0 0` for all Phase 36 insert blocks.
- Full validation pipeline (`scripts/validation/run-postgres-validation.sh`) executed with exit 0 and Phase 36 first+second-run notices present.
- In full pipeline second run, Phase 36 fixture block showed 16 consecutive `INSERT 0 0` lines.

Result: **PASS**

## 12. Negative Semantic Tests

Checked Phase 36 occurrences:
- `sameAs=0`, `contradicts=0`, `preferredOver=0`, `strongerThan=0`, `supportsTheory=0`, `confirmsTheory=0`, `refutesTheory=0`, `occursOnDate=0`, `claim_relation touching P36=0`.
- All Phase 36 claims are direct source-backed and use only registered predicates (`occursAt`, `participatesIn`, `precedes`).
- Analytical observations remain evidence-only (0 claim links).

Epistemic rule verification (Phase 36 evidence):
- source-backed is not true: no truth predicate/field asserted; unsupported proof questions return `NOT_REPRESENTED`.
- direct source claim is not scholarly interpretation: direct claims bind SOURCE_OBSERVATION evidence only.
- scholarly interpretation is not Berean fact: analytical observations back zero claims.
- proposed identity is not active identity: `Mrs. Mott` remains PROPOSED.
- difference is not contradiction: no Phase 36 claim_relation contradictions.
- absence is not false: unsupported API path returns bounded `NOT_REPRESENTED`, not falsehood.
- `NOT_STORED_BY_POLICY` is not source silence: Phase 36 fixture/license and prior conventions preserve locator-only policy semantics.
- `NOT_ESTABLISHED` is not false: represented throughout prior validation conventions; unsupported relation handling preserves this boundary.

Result: **PASS**

## 13. Limitations Classification

| Limitation | Classification | Status |
| --- | --- | --- |
| No novel withheld graph-derivation probe in Phase 36 Stage B analogous to Q8–Q10 | `QUERY` | **NOT DEMONSTRATED** |
| Bounded corpus does not include broader historiography resolution or consensus claims | `INTENTIONAL_BOUNDARY` | **PASS WITH INTENTIONAL LIMITATION** |
| Historiography difference relations (contradiction/ranking/theory confirmation) intentionally not represented in this phase | `REGISTRY_EXPRESSIVENESS` | **PASS WITH INTENTIONAL LIMITATION** |

## 14. Architectural Assessment

Phase 36 demonstrates repeatable Stage A population + read-only Stage B retrieval + Explorer bounded interrogation on existing architecture, with provenance and identity boundaries preserved.

No evidence in this audit required schema, predicate-registry, or Explorer architecture change.

Result: **PASS WITH INTENTIONAL LIMITATION** (because novel independent research derivation test was not demonstrated).

## 15. Evidence-Based Verdict

- **WHAT THE CANDIDATE REVIEW PROVED:** Candidate boundary intent is coherent and mostly implemented exactly (Day One/Day Two directness and ordering boundary, unresolved Mrs. Mott identity, isolated historiography).
- **WHAT THE IMPLEMENTATION ACTUALLY DEMONSTRATED:** Idempotent Phase 36 population, complete provenance for direct claims, read-only Stage B, read-only Explorer/API behavior with bounded capability handling.
- **WHAT REMAINS UNPROVEN:** A genuine withheld novel graph-derived Stage B query outcome for Phase 36 comparable to Phase 33 anti-contamination probes.

Final classification: **PASS WITH INTENTIONAL LIMITATION**.
