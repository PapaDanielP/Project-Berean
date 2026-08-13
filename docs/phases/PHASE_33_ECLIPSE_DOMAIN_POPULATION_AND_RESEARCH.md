# Phase 33 — Eclipse Domain Population and Independent Scholarly Research

## 1. Scope and objective

Phase 33 tests one question that Phases 30–32 did not isolate:

> Can Berean populate a domain from sources, and then later answer scholarly questions it has never
> seen, without the answers having been encoded during ingestion?

The phase is executed in two strictly separated stages.

- **Stage A — population.** `tests/fixtures/142-phase33-eclipse-domain-population-fixture.sql`
  populates the bounded 1919 solar-eclipse domain from the represented sources only. It contains no
  research question, no expected answer, no answer table, no query result, no ranking, no
  consensus, and no interpretation verdict. `tests/validation/phase33-eclipse-domain-population-validation.sql`
  validates the population itself: source scope, storage policy, inventory, provenance, identity
  discipline, idempotence, and the negative promotion boundaries.
- **Stage B — interrogation.** `tests/validation/phase33-eclipse-independent-query-validation.sql`
  introduces ten previously withheld questions and answers each one by read-only traversal of the
  persisted substrate. It runs only after Stage A validation succeeds.

No schema, predicate, entity type, claim type, evidence type, event type, participation role,
interpretation table, answer table, truth/confidence/consensus field, convenience API, or second
knowledge store was added. Phase 33 uses the schema exactly as it stands after Phase 32.

Phase 32 also used the 1919 eclipse. Phase 33 does **not** reuse or delegate to the Phase 32
population: it performs its own independently keyed population pass (`phase33_*`, `*_P33`,
`CLAIM_P33_*`) which loads correctly both on an empty schema and alongside Phase 32. The four
bibliographic `source` rows are shared, because they are the same four works.

## 2. Corpus

The required minimum sources, all locator-only:

| `source_key` | Work | `source_type_code` | Role |
| --- | --- | --- | --- |
| `ECLIPSE_1919_REPORT` | Dyson, Eddington, and Davidson 1920, *Phil. Trans. R. Soc. A* 220 | `HISTORICAL_WORK` | Primary expedition report |
| `OBSERVATORY_1919_ECLIPSE` | *The Observatory* 42 (1919), Joint Eclipse Meeting report | `HISTORICAL_WORK` | Near-primary contemporary report |
| `EARMAN_GLYMOUR_1980` | *Historical Studies in the Physical Sciences* 11.1: 49–85 | `REFERENCE` | Later scholarship |
| `KENNEFICK_2007` | *Einstein Studies* 12 | `REFERENCE` | Later scholarship |

Source-storage policy: every Phase 33 dataset records
`license_status = 'Locator-only bibliography; source text is NOT_STORED_BY_POLICY.'`, every Phase 33
`source_record` has `raw_content IS NULL` and `content_hash IS NULL` but a non-null
`source_location`, and every Phase 33 `citation` has `quoted_text IS NULL`. Stage A validation
fails if any of these is violated. `NOT_STORED_BY_POLICY` means the repository does not redistribute
the text; it is not source silence and not a claim of nonexistence.

## 3. Stage A population inventory

Deterministic, verified by Stage A validation on every replay:

| Layer | Count | Notes |
| --- | --- | --- |
| Sources | 4 | Shared bibliographic rows |
| Datasets (`*_P33`) | 4 | All `NOT_STORED_BY_POLICY` |
| Source records | 11 | Locators only |
| Citations | 11 | One per source record, no quoted text |
| Evidence — `SOURCE_OBSERVATION` | 9 | |
| Evidence — `ANALYTICAL_OBSERVATION` | 2 | Earman/Glymour, Kennefick |
| Entities | 15 | 5 `PERSON`, 3 `PLACE`, 2 `ORGANIZATION`, 3 `OBJECT`, 2 `CONCEPT` |
| Events | 3 | All `OTHER` |
| Propositions | 14 | `occursAt` ×3, `participatesIn` ×6, `locatedAt` ×3, `precedes` ×2 |
| Claims | 14 | All `DIRECT_SOURCE_CLAIM`; zero interpretive or derived claims |
| Claim–evidence links | 16 | All `SUPPORTS`, all to `SOURCE_OBSERVATION` evidence |
| Source identities | 9 | 7 from the expedition report, 2 from the contemporary report |
| Entity–source mappings | 9 | 8 `ACTIVE` with justification and supporting evidence, 1 `PROPOSED` |

Six of the eleven source observations back claims. Five evidence rows deliberately back no claim:
the Sobral astrographic focus concern, the deflection-results discussion, the contemporary meeting
reservations, and the two scholarly reassessments.

## 4. Research-question isolation

The Stage A fixture, the Stage A validation, and `data/candidates/phase33-eclipse-domain-candidates.csv`
contain source scope and classification decisions only. They do not contain the Stage B questions,
any expected answer, or any question→answer mapping, and no such mapping exists anywhere in the
repository. Stage B derives every result from ordinary SQL traversal of
`source → dataset → source_record → citation → evidence → claim_evidence → claim → proposition →
entity/event` and the existing `claim_rendering` and `event_participation` projections.

Questions 8, 9, and 10 are explicit anti-contamination probes. They ask for **graph properties that
no populated row states**, so they cannot be satisfied by string lookup:

- Q8: does any represented person take part in observing at more than one station?
- Q9: which stations hold more than one attested instrument, and is any preference established?
- Q10: which source identities remain unreconciled with a canonical entity?

## 5. Stage B questions and retrieved results

All queries executed inside `BEGIN READ ONLY;` with `retrieval_scope = BEREAN_ONLY` (no external
lookup). Exact results, as produced by `scripts/validation/run-postgres-validation.sh`:

**Q1 — What can Berean establish about what happened during the 1919 eclipse observations?**
14 rows, each a `DIRECT_SOURCE_CLAIM` with its rendered proposition and supporting source(s), for
example `Arthur Stanley Eddington participatesIn phase33_principe_observation_1919`
(`ECLIPSE_1919_REPORT`) and `phase33_joint_eclipse_meeting_1919 occursAt Burlington House`
(`OBSERVATORY_1919_ECLIPSE`). The two organizational participation claims retrieve **two**
independent supporting sources (`ECLIPSE_1919_REPORT, OBSERVATORY_1919_ECLIPSE`) without either
source being merged into or overwritten by the other.

**Q2 — What do the sources independently report, and where do their accounts differ?**
11 evidence rows grouped by source, each labelled `SUPPORTS_A_CLAIM` or
`EVIDENCE_ONLY_NOT_CLAIM_BACKING`. The expedition report's Sobral astrographic focus concern and the
contemporary report's record of reservations after the announcement are both retrieved, each under
its own source, neither resolved into the other.

**Q2b — Are those differences persisted as contradictions?**
`persisted_contradictions_among_phase33_claims = 0`, boundary `DIFFERENCE_IS_NOT_CONTRADICTION`.

**Q3 — Which competing scholarly interpretations are represented?**
2 rows: `EV_P33_EARMAN_GLYMOUR_INTERPRETATION` (`CITE_P33_EARMAN_GLYMOUR_49_85`) and
`EV_P33_KENNEFICK_INTERPRETATION` (`CITE_P33_KENNEFICK_EINSTEIN_STUDIES_12`), each with
`claims_backed = 0` and class `SCHOLARLY_CANDIDATE_NOT_PROMOTED`. Neither is ranked or preferred.

**Q4 — What is directly supported and what would require interpretation?**
19 rows: 14 `DIRECTLY_SUPPORTED` claims and 5 `REQUIRES_INTERPRETATION_NOT_CLAIMED` evidence rows
(`EV_P33_EARMAN_GLYMOUR_INTERPRETATION`, `EV_P33_KENNEFICK_INTERPRETATION`,
`EV_P33_OBSERVATORY_MEETING_DISCUSSION`, `EV_P33_RESULTS_DISCUSSION`,
`EV_P33_SOBRAL_ASTROGRAPHIC_CONCERN`).

**Q5 — Show the complete provenance of one direct claim.**
One row for `CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION`:

```text
Claim CLAIM_P33_EDDINGTON_PARTICIPATES_IN_PRINCIPE_OBSERVATION
  Proposition  Arthur Stanley Eddington --participatesIn--> phase33_principe_observation_1919
  ClaimEvidence  SUPPORTS
  Evidence       EV_P33_PRINCIPE_OBSERVATIONS (SOURCE_OBSERVATION)
  Citation       CITE_P33_REPORT_PRINCIPE_OBSERVATIONS
  SourceRecord   P33_REPORT_PRINCIPE_OBSERVATIONS  [source_text_status = NOT_STORED_BY_POLICY]
  Dataset        ECLIPSE_1919_REPORT_P33
  Source         ECLIPSE_1919_REPORT
```

**Q6 — What does the domain establish about the Sobral data-handling issue?**
1 row: the source observation is retrieved with `claims_backed = 0`,
`non_location_instrument_propositions = 0`, class `UNRESOLVED_NOT_ESTABLISHED`. Berean retrieves
what the source reports and establishes neither data invalidity, nor exclusion rationale, nor
motive, nor bias, nor contradiction.

**Q7 — What ordering is established, and what is not?**
2 rows (`phase33_principe_observation_1919 → phase33_joint_eclipse_meeting_1919` and the Sobral
equivalent), with `represented_event_dates = 0` and class `ORDERING_ONLY_NO_CALENDAR_DATES`.

**Q8 (novel probe) — Cross-station participation?**
0 rows. No represented person is associated with more than one station. This was computed by
joining `event_participation` to the stations reached through each event's `occursAt` proposition;
nothing in Stage A states it.

**Q9 (novel probe) — Multi-instrument stations and preference?**
1 row: `Sobral eclipse station | 2 | Sobral astrographic telescope, Sobral four-inch lens`, with
`instrument_to_instrument_relations = 0` and class `PREFERENCE_NOT_ESTABLISHED`. Berean can report
that one station has two attested instruments and that it establishes no preference between them.

**Q10 (novel probe) — Unreconciled source identities?**
1 row: `OBSERVATORY_1919_ECLIPSE | phase33-observatory-astronomer-royal | The Astronomer Royal |
PROPOSED | Frank Watson Dyson`, with the recorded justification that the contemporary report names
an office rather than a person.

## 6. Bounded synthesis

1. **Supported by represented source evidence** — station locations, station participants,
   instrument locations, meeting venue, organizational meeting participation, and
   observation-before-meeting ordering, each with a complete provenance chain to a registered
   source.
2. **Source differences and unresolved conflicts** — the expedition report's Sobral astrographic
   focus concern and the contemporary report's post-announcement reservations are preserved
   independently, back no claim, and are not persisted as contradiction.
3. **Scholarly interpretations** — Earman and Glymour 1980 and Kennefick 2007 are retained as
   citation-bearing analytical observations backing zero claims. Neither is ranked or resolved.
4. **Not established by the represented corpus** — theory confirmation or refutation, deflection
   magnitudes, data-weighting or exclusion rationale, motive, scholarly correctness, consensus,
   calendar dates, cross-station participation, instrument preference, and the identity of the
   title-only "Astronomer Royal" source identity.

## 7. Negative tests

Validated, not merely asserted:

| Boundary | Check | Result |
| --- | --- | --- |
| Scholarship is not a source claim | No Phase 33 `claim_evidence` row references `ANALYTICAL_OBSERVATION` evidence | 0 |
| Unresolved material is not a claim | Sobral concern, results discussion, and meeting reservations back no claim | 0 |
| No interpretive claim types | Phase 33 claims of type ≠ `DIRECT_SOURCE_CLAIM` | 0 |
| No interpretive predicates | Propositions using `confirmsTheory`, `supportsTheory`, `refutesTheory`, `preferredOver`, `strongerThan`, `sameAs`, `excludedBecause`, `biasedBy`, `weightedOver`, `occursOnDate` | 0 |
| No theory ranking | Propositions referencing either deflection-comparison `CONCEPT` entity | 0 |
| No automatic contradiction | `claim_relation` rows touching Phase 33 claims | 0 |
| No silent reconciliation | `ACTIVE` mapping for `phase33-observatory-astronomer-royal` | 0 |
| Reconciliation provenance | `ACTIVE` Phase 33 mappings with supporting evidence and justification | 8 of 8 |
| Read-only interrogation | Persistent counts across 13 tables before vs. after Stage B | identical |

The predicate registry does not structurally prevent a reviewer from attaching analytical evidence
to a claim; that boundary is enforced by validation, as in Phases 30–32. This is stated here rather
than "fixed" by adding schema. The enforcement was exercised, not merely asserted: deliberately
linking `EV_P33_KENNEFICK_INTERPRETATION` to a claim aborts Stage A with
`phase33 stage A: an analytical observation was promoted into a claim` and Stage B with
`phase33 stage B: 1 scholarly observations back a claim`, and activating the title-only Astronomer
Royal mapping aborts Stage A with
`phase33 stage A: expected 8 justified active source-identity mappings, found 9`.

## 8. Determinism, replay, and idempotence

`scripts/validation/run-postgres-validation.sh` runs Stage A fixture → Stage A validation → Stage B
queries → global `validate.sql` twice. Measured on PostgreSQL 16.14:

- Full suite exit status `0`, with all Phase 33 assertions raising their `ok:` notices in both runs.
- Second population run reported `INSERT 0 0` for every statement in the fixture: no duplicate
  source, dataset, source record, citation, evidence, entity, event, proposition, claim,
  claim-evidence link, source identity, or mapping.
- Stage A and Stage B output for the second run is byte-identical to the first run apart from those
  `INSERT` counts; all result sets are explicitly ordered.
- The Phase 33 fixture also loads cleanly against an empty schema, so Stage A does not depend on the
  Phase 32 population.
- Stage B asserts equality of counts for `source`, `dataset`, `source_record`, `citation`,
  `source_identity`, `entity_source_mapping`, `entity`, `event`, `proposition`, `claim`, `evidence`,
  `claim_evidence`, and `claim_relation` before and after all ten queries. They were identical.

## 9. Requirement classification

| Requirement | Classification |
| --- | --- |
| Independent source-driven Stage A population | PASS |
| Required minimum sources represented | PASS |
| Locator-only source-storage policy with `NOT_STORED_BY_POLICY` | PASS |
| Entities, events, propositions, direct claims, evidence, citations | PASS |
| Complete provenance for every Phase 33 claim | PASS |
| Independent source traditions preserved without merging | PASS |
| Source difference preserved without contradiction | PASS |
| Scholarly candidates preserved without promotion or ranking | PASS |
| Unresolved source identity preserved as `PROPOSED` | PASS |
| Withheld Stage B questions answered by traversal | PASS |
| Novel anti-contamination queries (Q8, Q9, Q10) | PASS |
| Read-only interrogation with unchanged persistent counts | PASS |
| Deterministic replay and idempotence | PASS |
| Calendar-date chronology for the observations | PASS WITH INTENTIONAL LIMITATION — `REGISTRY_EXPRESSIVENESS` |
| Measured deflection values and theoretical comparison | PASS WITH INTENTIONAL LIMITATION — `REGISTRY_EXPRESSIVENESS` |
| Sobral data-weighting/exclusion rationale and motive | PASS WITH INTENTIONAL LIMITATION — `REGISTRY_EXPRESSIVENESS` |
| Natural-language question interpretation | NOT IMPLEMENTED — `QUERY` |
| Breadth of eclipse historiography | PASS WITH INTENTIONAL LIMITATION — `DOMAIN_SCOPING_LIMITATION` |

Detail on the limitations:

- `REGISTRY_EXPRESSIVENESS` — the substrate can hold the material (all three appear as retrievable
  source observations with citations), but no registered predicate expresses an event's calendar
  date, a measured physical quantity, a theory relation, or a data-weighting rationale.
  `yearsFromCreation` is a Genesis-scoped chronology predicate and is not a general date predicate.
  No predicate was added, so these remain evidence-only and are reported by Stage B as
  `NOT_ESTABLISHED`.
- `QUERY` — Stage B questions are natural-language headers over hand-written SQL traversals. The
  existing read-only exploration layer returns stored objects and provenance; it does not parse
  questions. No convenience API was added for this phase.
- `DATA_ENTRY` — anything absent from the eleven represented locators is missing corpus material,
  not an architectural deficiency. `NOT_ESTABLISHED` is not `FALSE`.
- `DOMAIN_SCOPING_LIMITATION` — this is a deliberately small bounded corpus, not the full
  historiography of the 1919 expeditions.

No requirement was classified `ARCHITECTURAL_DEFICIENCY`.

## 10. Architectural assessment

> Can Berean populate a domain from sources and later answer unseen scholarly questions without the
> answers having been encoded during ingestion?

**Yes, within the represented corpus and the registered predicate vocabulary.** The evidence is
Q8, Q9, and Q10: their results (no cross-station participant; exactly one multi-instrument station
with no preference established; exactly one unreconciled source identity) are computed by traversing
the persisted graph, and no Stage A row states any of them. The provenance-bearing structure —
independent evidence per source, claims bound to propositions, citations bound to source records,
identity mappings with status and justification — is what makes those answers derivable.

Equally important is what the answers do **not** contain. The corpus can be asked the historically
loaded questions (Was relativity confirmed? Were the Sobral plates discarded for theoretical
reasons?) and Berean answers by retrieving the source observation and reporting
`UNRESOLVED_NOT_ESTABLISHED`, not by manufacturing a verdict. Faithful incompleteness was preserved
over fabricated completeness, and no architecture was changed to obtain a better verdict.

Phase 33 did not expose an architectural deficiency. It confirmed a known, intentional boundary: the
predicate registry does not express dates, measurements, weighting rationale, or theory relations,
so material of those kinds stays at the evidence layer and is reported as not established.

## 11. Final verdict

PASS WITH INTENTIONAL LIMITATION
