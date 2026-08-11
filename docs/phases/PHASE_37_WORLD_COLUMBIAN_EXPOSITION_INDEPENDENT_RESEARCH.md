# Phase 37 — 1893 World's Columbian Exposition Independent Graph-Derived Research

## 1. Executive Summary

Phase 37 repeats the Phase 33/36 independent two-stage domain lifecycle for a new, deliberately
bounded historical corpus: the 1893 World's Columbian Exposition in Chicago. Stage A populates a
locator-only, provenance-complete substrate using only registered predicates, entity/event types,
and claim/evidence machinery already present in the schema. Stage B then asks ten withheld
conceptual research questions — plus two deliberately unsupported probes — purely by read-only SQL
traversal of the persisted graph, with no answer table, no new predicate, and no schema, registry,
or Explorer change. The central capability under test — deriving previously unstored multi-hop
relationships (shared venues, person pairs, person→event→place chains, multi-source participation,
and same-venue cross-event pairs) from a newly populated domain while preserving provenance and
identity boundaries — is demonstrated with reproducible, before/after-identical, twice-replayed
evidence.

**Verdict: PASS WITH INTENTIONAL LIMITATION.**

## 2. Domain Scope and Source Corpus

The bounded corpus covers two represented occurrences of the fair — Dedication Day (October 21,
1892) and Opening Day (May 1, 1893) — both located at Jackson Park, with four source traditions:

| Source | Role |
| --- | --- |
| `WORLD_COLUMBIAN_EXPOSITION_OFFICIAL_CATALOGUE_1893` | contemporary exposition source |
| `CHICAGO_TRIBUNE_1893_EXPOSITION_OPENING` | independent contemporary newspaper account |
| `BADGER_1979_GREAT_AMERICAN_FAIR` | later historical analysis |
| `RYDELL_1984_ALL_THE_WORLDS_A_FAIR` | later historiographical/critical analysis |

No calendar-date predicate, ranking predicate, or second relationship store was introduced;
inspection of the schema, predicate registry, Explorer, and validation runner found no genuine
architectural deficiency requiring such an addition.

## 3. Candidate Review

`data/candidates/phase37-worlds-columbian-exposition-candidates.csv` records five candidates: the
two ordered events (`P37_DEDICATION_DAY`, `P37_OPENING_DAY`, both `INGESTED_DIRECT_SOURCE_CLAIM`),
the honorific identity ambiguity (`P37_MRS_POTTER_PALMER_IDENTITY`, `UNRESOLVED_SOURCE_IDENTITY`),
the scholarly interpretive difference (`P37_HISTORIOGRAPHY`, `SCHOLARLY_POSITION_CANDIDATE`), and an
explicitly excluded out-of-corpus attendance figure (`P37_EXACT_ATTENDANCE_FIGURE`,
`EXCLUDED_OUTSIDE_CORPUS`). The worksheet contains candidate key, entity/event type, candidate name,
source reference, explicit source description, proposed proposition, source status, review status,
coverage classification, obstacle classification, exclusion reason, proposed mapping decision, and
disposition — and no Stage B question, expected answer, query mapping, result row, ranking,
consensus, or verdict.

## 4. Stage A Population Inventory

`tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql` populates, using
`phase37_*` / `*_P37` / `CLAIM_P37_*` / `EV_P37_*` / `CITE_P37_*` keys distinct from every prior
phase:

- 4 sources, 4 locator-only datasets, 6 source records, 6 citations, 6 evidence rows (4
  `SOURCE_OBSERVATION`, 2 `ANALYTICAL_OBSERVATION`);
- 6 entities (4 `PERSON`, 1 `PLACE`, 1 `ORGANIZATION`) and 2 `OTHER` events;
- 9 `occursAt`/`participatesIn`/`precedes` propositions and 9 `DIRECT_SOURCE_CLAIM` claims, each with
  at least one cited `SUPPORTS` evidence link (one claim — Palmer's Opening Day participation — has
  two, from two independent sources);
- 5 source identities and 5 entity_source_mappings (4 `ACTIVE`, 1 `PROPOSED`).

The fixture uses `ON CONFLICT DO NOTHING` / `NOT EXISTS` guards throughout and contains no research
question, expected Stage B answer, answer table, ranking, consensus, or interpretation verdict.

## 5. Provenance Validation

`tests/validation/phase37-worlds-columbian-exposition-population-validation.sql` confirms: exactly
4 sources and 4 locator-only datasets; no `raw_content`/`content_hash` on Phase 37 source records and
no `quoted_text` on Phase 37 citations; every claim uses a registered predicate; exactly 9 direct
claims, each with complete `Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation →
SourceRecord → Dataset → Source` provenance; no analytical observation promoted to a claim; exactly
2 unpromoted scholarly observations; no persisted contradiction; no unsupported predicate
(`preferredOver`, `strongerThan`, `confirmsTheory`, `supportsTheory`, `refutesTheory`, `sameAs`)
registered; and no invented calendar-date proposition.

## 6. Identity Validation

The Official Catalogue's Board of Lady Managers biographical note uses the honorific "Mrs. Potter
Palmer" rather than a full personal name. This source identity (`phase37-catalogue-mrs-potter-palmer`)
carries exactly one `PROPOSED` — never `ACTIVE` — mapping to `phase37_bertha_palmer`, with an
evidence-backed justification. `PROPOSED` is not a denial of identity; it is a deliberately withheld
reconciliation, mirroring the Phase 36 Mrs. Mott boundary test.

## 7. Scholarly Isolation

Badger (1979) and Rydell (1984) are retained as two independently cited `ANALYTICAL_OBSERVATION`
rows (`EV_P37_BADGER_INTERPRETATION`, `EV_P37_RYDELL_INTERPRETATION`). Neither backs any
`claim_evidence` row; neither is merged, ranked, or persisted as a `claim_relation`. Their analytical
difference in interpretive focus is not modeled as a contradiction.

## 8. Withheld Research Questions

Ten conceptual questions (Q1–Q10) plus two unsupported probes were withheld from the Stage A
fixture, the Stage A validation, and the candidate worksheet. They appear for the first time in
`tests/validation/phase37-worlds-columbian-exposition-independent-query-validation.sql`, run inside
`BEGIN READ ONLY`.

## 9. Q1–Q10 Results

For each question: interpretation, capability, traversal, underlying persisted objects, derived
result, whether the result itself is persisted, provenance, and limitations.

- **Q1** — People participating in more than one represented event (`Person → participatesIn →
  Event`, aggregated). Persisted rows traversed: `event_participation` (view over
  `participatesIn` claims) joined to `entity`/`event`. Derived result: **Bertha Palmer**
  participates in both Dedication Day and Opening Day. Not itself persisted — no
  `multi_event_participant` table or claim exists. Provenance: each underlying `participatesIn`
  claim carries full provenance individually. Classification: `DERIVED_FROM_STORED_GRAPH`.
- **Q2** — Events sharing a venue (`Event → occursAt → Place`). Traversed: two `occursAt`
  propositions both resolving to `phase37_jackson_park`. Derived: Dedication Day and Opening Day
  share Jackson Park. Not persisted as an `event_pair` row. `DERIVED_FROM_STORED_GRAPH`.
- **Q3** — Pairs of people connected through a common event via a two-sided `event_participation`
  self-join, with no `knows`/`associatedWith` predicate stored. Derived: 4 pairs (Burnham–Palmer at
  Dedication Day; Palmer–Douglass, Palmer–Cleveland, Douglass–Cleveland at Opening Day). None of
  these pairs is a stored proposition. `DERIVED_FROM_STORED_GRAPH`.
- **Q4** — `Person → participatesIn → Event → occursAt → Place` three-hop chain. Derived: 5 rows,
  one per person/event pair, each resolving to Jackson Park. `DERIVED_FROM_STORED_GRAPH`.
- **Q5** — Established ordering (`precedes`) plus participants at each end, without inventing exact
  dates. Derived: Dedication Day precedes Opening Day; participants listed per side by traversal of
  `event_participation`, not by a stored calendar value. `DERIVED_FROM_STORED_GRAPH`.
- **Q6** — Claims supported by more than one independent source via full provenance joins. Derived:
  `CLAIM_P37_PALMER_PARTICIPATES_IN_OPENING_DAY` is backed by both the Official Catalogue and the
  Chicago Tribune. This *is* itself a stored claim (a `DIRECT_SOURCE_CLAIM`) with pre-existing
  `claim_evidence` rows; the query only counts and surfaces its distinct sources.
  `DIRECTLY_SUPPORTED`.
- **Q7** — Source observations with relevant information but no `claim_evidence` link. Derived: the
  two scholarly interpretations plus the honorific-only biographical note.
  `SCHOLARLY_CANDIDATE_NOT_PROMOTED`.
- **Q8** — Unresolved source identities and proposed canonical mappings. Derived: the
  `phase37-catalogue-mrs-potter-palmer` identity, `PROPOSED` toward `phase37_bertha_palmer`.
  `UNRESOLVED`.
- **Q9** — People with source-backed participation established through more than one source
  tradition, using only established (`ACTIVE`/`SUPPORTS`) mappings. Derived: Bertha Palmer, via the
  Official Catalogue and the Chicago Tribune. `DERIVED_FROM_STORED_GRAPH`.
- **Q10** — People participating in different events (Event A ≠ Event B) sharing a place. Derived:
  12 ordered person/event pairs across the shared Jackson Park venue. Not persisted.
  `DERIVED_FROM_STORED_GRAPH`.

Two unsupported probes (numbered informally Q11/Q12 in the SQL) ask which scholar is "correct" and
what the exact calendar date/theory-confirmation status is; both return `NOT_REPRESENTED` with a
stated reason, inventing no predicate, date, ranking, or truth judgment.

## 10. Graph Traversal Demonstration

Every Q1–Q10 query is expressed as ordinary SQL joins over `proposition`, `claim`, `evidence`,
`claim_evidence`, `event_participation`, `entity`, and `event` — no procedural loop, no materialized
answer table, no external retrieval. `event_participation` is itself a view projected from
claim-asserted propositions (schema/sql/001_core_schema.sql), not a second authoritative store.

## 11. Natural-Language Explorer Demonstration

The existing generic Explorer (`src/app.ts`, unmodified) was exercised manually against the
Phase 37-populated database:

- `GET /api/research/scope` dynamically discovered all 4 Phase 37 datasets with correct source
  record/evidence/claim counts, alongside every pre-existing phase's datasets.
- `POST /api/research` with `{"question":"Who participates in the Opening Day event and where does
  it occur?","datasetIds":[20,21,22,23]}` returned `capability: ESTABLISHED`, an inspectable plan
  (candidate predicates, traversal shape, full-chain provenance requirement), and 7 bounded results,
  including the two provenance rows for Bertha Palmer's dually-sourced Opening Day participation.
- `POST /api/research` with `{"question":"Which scholar is correct about the exposition, Badger or
  Rydell?"}` returned `capability: NOT_REPRESENTED` with `limitation: "Absence of representation is
  not a denial. Try keyword search to find persisted records."` — no fabricated verdict.
- `GET /api/search?q=Bertha+Palmer` returned claim, entity, evidence, and source_identity rows
  labeled `MATCHED`/by type, distinct from established-claim results.

No domain-specific handler, route, or predicate was added to the Explorer for this phase.

## 12. Unsupported Query Demonstration

The two unsupported Stage B probes and the Explorer's scholarly-correctness probe above both return
`NOT_REPRESENTED` rather than an invented ranking, date, or truth judgment, using only the existing
capability classification.

## 13. Read-Only Verification

Before/after counts for `source`, `dataset`, `source_record`, `citation`, `source_identity`,
`entity_source_mapping`, `entity`, `event`, `proposition`, `claim`, `evidence`, `claim_evidence`, and
`claim_relation` were captured into a temp table before `BEGIN READ ONLY` and compared after
`COMMIT`; the Stage B script raises an exception if `BEFORE <> AFTER`. Both validation-script runs
completed with `RAISE NOTICE 'ok: ... identical before/after persistent counts'` and no exception.
Manual Explorer interrogation (Section 11) was independently confirmed read-only by comparing
`SELECT count(*) FROM claim` / `proposition` before and after the HTTP requests (326/313 both
times, matching the state left by the twice-replayed validation script plus the once-more-applied
fixture used for the manual demo).

## 14. Replay and Idempotence

The population fixture was run twice directly against a local PostgreSQL 16 database: the first run
inserted all rows (4/4/6/6/6/6/6/2/2/6/1/9/10/5/4/1 across the fixture's statements); the second run
inserted **zero** additional rows in every statement. `scripts/validation/run-postgres-validation.sh`
now runs the full Phase 37 fixture → Stage A validation → Stage B validation sequence twice
consecutively (mirroring the Phase 33/36 convention), and the entire script — schema load through
every prior phase's replay, Phase 37 (twice), and the closing negative-integrity/blocking-cases
checks — passed end-to-end with exit code 0.

## 15. Negative Semantic Tests

Stage A validation explicitly checks for and rejects: an unregistered predicate on any Phase 37
claim; an analytical observation promoted to a claim; a persisted `claim_relation` involving a
Phase 37 claim; an `ACTIVE` mapping for the honorific-only Mrs. Potter Palmer identity; registration
of `preferredOver`, `strongerThan`, `confirmsTheory`, `supportsTheory`, `refutesTheory`, or `sameAs`
as predicates; and any Phase 37 event carrying a `DATE`-typed proposition value.

## 16. Limitations Classification

| Limitation | Classification |
| --- | --- |
| No scholarly-correctness adjudication between Badger and Rydell | `INTENTIONAL_BOUNDARY` |
| No exact calendar date or theory-confirmation semantics | `REGISTRY_EXPRESSIVENESS` |
| Mrs. Potter Palmer honorific left `PROPOSED`, not `ACTIVE` | `DATA_ENTRY` (corpus does not itself supply the reconciliation) |
| Attendance-figure candidate excluded | `DOMAIN_SCOPING_LIMITATION` |
| No architectural change to schema/registry/Explorer was required | not a limitation — inspection found no genuine deficiency |

## 17. Architectural Assessment

Inspection of the schema, predicate registry, provenance model, Explorer, and validation runner
found no genuine charter-consistent architectural deficiency requiring a schema change, a new
predicate, or a second knowledge store. The existing `occursAt`, `participatesIn`, and `precedes`
predicates, the `event_participation` projection view, and the generic natural-language adapter were
sufficient to populate this new domain and derive all ten withheld multi-hop relationships.

## 18. Evidence-Based Verdict

**PASS WITH INTENTIONAL LIMITATION.** The central acceptance test — populating a new historical
domain and deriving previously unstored multi-hop relationships (Q3 person pairs, Q4
person/event/place chains, Q9 multi-source participation, Q10 same-venue cross-event pairs) purely
by traversal, with unchanged before/after counts, deterministic repeated output, twice-replayed
idempotent population, and refusal to invent ranking/date/truth-judgment semantics for the two
unsupported probes — is demonstrated with complete, reproducible evidence.

## 19. What Was Stored

4 sources, 4 locator-only datasets, 6 source records, 6 citations, 6 evidence rows, 6 entities, 2
events, 9 propositions, 9 direct claims, 10 claim_evidence links, 5 source identities, and 5
entity_source_mappings — all under independent `phase37_*` / `*_P37` keys.

## 20. What Was Derived

Cross-event participation (Q1), shared venue (Q2), person pairs (Q3), the person/event/place chain
(Q4), ordering-with-participants (Q5), multi-source participation (Q9), and same-venue different-
event pairs (Q10) — none of which is itself a stored proposition, claim, or answer row.

## 21. What Remained Unresolved

The Mrs. Potter Palmer honorific-only identity remains `PROPOSED`, never `ACTIVE`.

## 22. What Current Architecture Cannot Represent

Scholarly correctness between Badger and Rydell; exact calendar dates for Dedication Day/Opening
Day; theory confirmation/refutation semantics; and an out-of-corpus attendance figure. All are
returned as `NOT_REPRESENTED`/excluded rather than fabricated.

## 23. Corpus and Representation Summary

See Sections 2 and 4 above for the full source table and population inventory.

## 24. Predicate and Registry Usage

Only pre-existing, already-registered predicates (`occursAt`, `participatesIn`, `precedes`) were
used; no row was added to the `predicate`, `entity_type`, `event_type`, `claim_type`,
`evidence_type`, or `mapping_status` tables.

## 25. Explorer and API Wiring

No Explorer/API source file was modified. The only repository wiring required by existing
convention was adding the Phase 37 fixture/Stage A/Stage B invocation (twice) to
`scripts/validation/run-postgres-validation.sh`, following the identical Phase 33/36 pattern.

## 26. Reproducibility Instructions

1. `psql "$DATABASE_URL" -f schema/sql/001_core_schema.sql`
2. `psql "$DATABASE_URL" -f tests/fixtures/144-phase37-worlds-columbian-exposition-population-fixture.sql`
3. `psql "$DATABASE_URL" -f tests/validation/phase37-worlds-columbian-exposition-population-validation.sql`
4. `psql "$DATABASE_URL" -f tests/validation/phase37-worlds-columbian-exposition-independent-query-validation.sql`
5. Repeat steps 2–4 to confirm idempotence, or run `scripts/validation/run-postgres-validation.sh`
   for the full repository replay (all phases, twice, plus negative-integrity/blocking-case checks).

## 27. Verification Commands Run

- `scripts/validation/run-postgres-validation.sh` — PASS (exit 0), full repository replay including
  Phase 37 twice.
- `npm run typecheck` — PASS, no errors.
- `npm run lint` — PASS, no errors.
- `npm test` — PASS, 83/83 tests (Explorer/API test suites, unrelated to this phase's SQL-only
  artifacts).
- `npm run build` — PASS, no errors.
- Manual Explorer HTTP verification (`GET /api/research/scope`, `POST /api/research`,
  `GET /api/search`) against a Phase 37-populated database — see Section 11.
