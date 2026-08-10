# Phase 13 Persistent Entity and Relationship Population Report

## Scope

Phase 13 advances the Genesis genealogical line by exactly one locator, to **Genesis 5:9**, in
both already-registered textual traditions (`GEN_MT_REF` and `GEN_LXX_REF`). It extends the
existing `tests/fixtures/020-genesis-1-11-fixture.sql` in place; it does not add a competing
fixture, schema table, provenance layer, predicate, event type, claim relation type, or
reconciliation infrastructure.

The slice was selected because it is the smallest material beyond the current boundary that
genuinely exercises **persistent entities and their relationships** with complete provenance:

- Genesis 1 is already at its representable limit. Genesis 1:22–23 and 1:28–31 remain
  intentionally excluded (Phase 12) because blessing/multiplication, food-provision, evaluative,
  and ordinal-day semantics cannot be expressed by the registered predicates without false
  precision. Advancing there would require speculative predicates, which is out of scope.
- Genesis chapters 2–4, 6–7, and 9–11 remain **SOURCE UNAVAILABLE / ACQUISITION PENDING**; no
  source material for them has been acquired in this repository, and fabricating any is forbidden.
- Genesis 5 is already a populated chapter with the same structural convention (5:3, 5:6). Its
  next genealogical locator, 5:9, is source-supported in both traditions under the fixture's
  existing convention of recording published genealogical numerals without reproducing text, and
  it is precisely about a persistent person who recurs across locators.

Genesis is **not** semantically complete, and Genesis 5:12 onward remains deferred.

## Baseline and final validation

Baseline command, run against a newly created PostgreSQL 16 database before any change:

```sh
DATABASE_URL='postgresql:///berean_phase13_baseline?host=/var/run/postgresql&user=runner' \
  scripts/validation/run-postgres-validation.sh
```

Baseline result: **PASS**. All blocking/schema checks, the negative fixture, both
`blocking-cases.sh` runs, Phases 6–12, and the STEP Bible manifest/source checks completed with
**no blocking failure and no data-quality warning**. No pre-existing regression had to be repaired
in this phase.

Baseline coverage counts, measured after loading `020-genesis-1-11-fixture.sql` and
`050-phase11-object-entity-fixture.sql`: entities 31, source identities 5, entity source mappings
5, propositions 82, claims 88, ClaimEvidence links 92, events 28, projected event-participation
rows 72, evidence 37, source records 36, citations 36, derivations 3, derivation inputs 6, claim
relations 4.

Final command, run against a newly created PostgreSQL 16 database after the change:

```sh
DATABASE_URL='postgresql:///berean_phase13_final?host=/var/run/postgresql&user=runner' \
  scripts/validation/run-postgres-validation.sh
```

Final result: **PASS**. The complete run passed the blocking/schema checks, the negative fixture,
both `blocking-cases.sh` runs, Phases 6–12, the new Phase 13 slice and coverage report, and the
STEP Bible manifest/source checks. The runner emitted **no data-quality warning**, and every
expected negative case remained blocked: claim without evidence, source observation without
citation, unjustified active reconciliation, cross-source reconciliation evidence, derivation
without inputs, and a derived claim used as its own derivation input. `npm test` (the web
application suite, which loads the same Genesis fixture) also passed.

## Population and provenance

No source text, quotation, hash, external evidence, or source identity was fabricated. Both new
source records keep `raw_content` and `content_hash` NULL and their citations carry locators with
no quoted text, exactly as the surrounding Genesis 5 records do.

Every direct semantic assertion added in this phase has the complete provenance path:

```text
Source → Dataset → SourceRecord → Citation → Evidence → ClaimEvidence → Claim → Proposition
```

Added objects:

| Object | Added |
| --- | --- |
| SourceRecord | `MT_GEN_5_9` (Genesis 5:9, `GEN_MT_REF`), `LXX_GEN_5_9` (Genesis 5:9, `GEN_LXX_REF`) |
| Citation | `CITE_MT_GEN_5_9`, `CITE_LXX_GEN_5_9` (locators only) |
| Evidence | `EV_MT_GEN_5_9`, `EV_LXX_GEN_5_9` (`SOURCE_OBSERVATION`, each citing its own record) |
| Entity | `kenan` (`PERSON`) |
| SourceIdentity | `mt-enosh`, `mt-kenan` (under `GEN_MT`), `lxx-enosh`, `lxx-kenan` (under `GEN_LXX`) |
| EntitySourceMapping | 4 `ACTIVE` rows, each with confidence, justification, and same-source supporting evidence |
| Event | `kenan_begetting` (`GENEALOGICAL`) |
| Proposition | `enosh fatherOf kenan`, `enosh parentIn kenan_begetting`, `kenan childIn kenan_begetting`, `enosh ageAtFatherhoodYears 90`, `enosh ageAtFatherhoodYears 190` |
| Claim | `CLAIM_ENOSH_FATHER_KENAN`, `CLAIM_MT_ENOSH_FATHER_KENAN`, `CLAIM_LXX_ENOSH_FATHER_KENAN`, `CLAIM_ENOSH_PARENT_KENAN_BEGETTING`, `CLAIM_KENAN_CHILD_KENAN_BEGETTING`, `CLAIM_MT_ENOSH_AGE_AT_KENAN`, `CLAIM_LXX_ENOSH_AGE_AT_KENAN` |
| ClaimRelation | one `CONTRADICTS` between the competing age claims |
| TypedValue | `YEAR` 90, `YEAR` 190 |

Counts measured after loading `020-genesis-1-11-fixture.sql` and
`050-phase11-object-entity-fixture.sql`:

| Object | Before | After | Delta |
| --- | ---: | ---: | ---: |
| Entity | 31 | 32 | +1 |
| SourceIdentity | 5 | 9 | +4 |
| EntitySourceMapping | 5 | 9 | +4 |
| SourceRecord | 36 | 38 | +2 |
| Citation | 36 | 38 | +2 |
| Evidence | 37 | 39 | +2 |
| Proposition | 82 | 87 | +5 |
| Claim | 88 | 95 | +7 |
| ClaimEvidence | 92 | 102 | +10 |
| Event | 28 | 29 | +1 |
| Event participation (projection) | 72 | 74 | +2 |
| ClaimRelation | 4 | 5 | +1 |
| TypedValue | 6 | 8 | +2 |
| Source / Dataset / Derivation / DerivationInput | unchanged | unchanged | +0 |

Note that the `Entity` before/after figures include the validation-only `ark_of_covenant` entity
added by the Phase 11 fixture; the Genesis fixture alone moves from 30 to 31 entities.

### Persistent entities and reuse

`enosh` is **reused**, not duplicated. The same canonical entity is the child participant of
`enosh_begetting` (Genesis 5:6) and the parent participant and father in Genesis 5:9, so one
persistent entity now carries claims grounded in two different source records across two
traditions. Only `kenan` is new. The Phase 13 slice asserts this reuse explicitly, and asserts
that exactly one canonical entity exists for each of Enosh and Kenan.

### Reconciliation

Source-specific identities remain distinct from canonical entities. `mt-enosh`/`mt-kenan` map to
`enosh`/`kenan` justified by `EV_MT_GEN_5_9`; `lxx-enosh`/`lxx-kenan` map to the same canonical
entities justified by `EV_LXX_GEN_5_9`. Every mapping is `ACTIVE` with an explicit confidence
(0.99 Masoretic, 0.95 Septuagint, matching the existing convention for the same distinction),
a justification, and supporting evidence drawn from its own source. No mapping was created that
evidence does not support, and no claim was manufactured merely to attach evidence to an entity.

### Relationships

The relationship is a registered Proposition predicate, not a relationship truth table. One
normalized `enosh fatherOf kenan` proposition is shared by three distinct direct source claims —
the tradition-neutral claim and the two source-specific claims — so only provenance differs, not
semantics. Participation remains solely the `event_participation` projection over claim-asserted
propositions; the slice asserts `kenan_begetting` projects exactly `enosh`/`PARENT` and
`kenan`/`CHILD`, each traced to its asserting claim.

### Competing claims

The published Masoretic and Septuagint numerals for Enosh at the begetting of Kenan (90 and 190
years) disagree. Both are recorded as active `DIRECT_SOURCE_CLAIM` rows over separate typed
values, each `SUPPORTS`-linked to its own tradition's evidence and `CONTRADICTS`-linked to the
other's, plus one `CONTRADICTS` claim relation. The disagreement is preserved, not resolved.

## Derivations

**No derivation was added.** No derived claim, derivation, or derivation input was created for
Genesis 5:9, because none is genuinely required to represent the source-recorded parentage,
participation, or numerals. In particular, no `yearsFromCreation` chronology was computed for
`kenan_begetting`, and the existing Adam–Seth–Enosh chronology derivations were left untouched
rather than extended. The slice enforces this.

## Coverage and exclusions

- Genesis 5:9 (Masoretic and Septuagint) is **POPULATED**, **SOURCE-BACKED**, **NOT DERIVED**,
  and **TEXT INTENTIONALLY EXCLUDED**.
- Genesis 5:3, 5:6, and 8:4 remain **POPULATED** and unaltered.
- Genesis 1:1–21 and 1:24–27 remain **POPULATED**; Genesis 1:22–23 and 1:28–31 remain
  **STRUCTURALLY REPRESENTED**, **SOURCE-BACKED**, and **INTENTIONALLY EXCLUDED**.
- Genesis 5:10 onward, and Genesis chapters 2–4, 6–7, and 9–11, remain **SOURCE UNAVAILABLE**,
  **UNRESOLVED**, and **ACQUISITION PENDING**.

Deliberate omissions inside the selected slice:

- **Event ordering.** No `precedes` relation between `enosh_begetting` and `kenan_begetting` was
  added. Event-to-event relations are out of scope for this phase, and genealogical ordering is
  not asserted from these two records.
- **Chronology.** No years-from-creation position, elapsed interval, or lifespan is asserted for
  Kenan or the Genesis 5:9 begetting.
- **Remaining Genesis 5:9 content.** Any further material in the verse beyond the recorded
  begetting and numeral is not modeled; the source observation records only what the claims
  assert.
- **Lineage inference.** No proposition connects `kenan` to `adam` or `seth`. Kenan participates
  in exactly the one source-recorded parentage relationship and its begetting event.
- **Identity, taxonomy, geography, ownership, and interpretation.** None is asserted. The
  Septuagint identities carry the same display names as the canonical entities; no transliteration,
  variant spelling, or naming detail was invented for them.

## Validation and integrity

`tests/validation/genesis-5-9-slice.sql` checks the exact intended locators, the absence of any
unintended Genesis 5:9 locator, the absence of raw text/hashes/quotations, one cited source
observation per tradition, the complete source-to-proposition provenance path for every Genesis
5:9 claim, entity persistence and non-duplication, the single shared parentage proposition with
its three claims, the four auditable same-source reconciliations, one-identity-to-one-entity
mapping, projection-only participation with no authoritative participation/relationship table, the
absence of derivations/ordering/chronology/unsourced kinship, preservation of the competing
numerals, and the untouched Genesis 1, Genesis 5/8, and deferred-chapter boundaries.

`tests/validation/phase13-coverage-report.sql` emits the genealogical locator classification, a
persistent-entity coverage summary (active source identities, supporting source records, projected
participations per entity), and the deferred-chapter classification. It rejects a Genesis 5:9
record without a supported direct claim, a populated genealogical entity without an
evidence-backed active reconciliation, loss of Genesis 1's 31 structural locators, population of
the deferred chapters, and any Genesis 5 locator beyond 5:9.

The authoritative runner executes both after the Phase 12 checks and before the STEP Bible checks.
The Phase 13 checks were also exercised against deliberately corrupted copies of the loaded data
(deleted participation claim, deleted Septuagint parentage claim, duplicate Kenan entity, injected
`precedes` relation, remapped source identity, removed contradiction, injected quoted text) and
each corruption was rejected.

Repository integrity assessment: **SUPPORTED / RUNTIME VERIFIED**. Phase 13 uses only the existing
relational model and preserves the distinctions among Entity, SourceIdentity, EntitySourceMapping,
Proposition, Claim, Evidence, Event, the `event_participation` projection, and Derivation. No
architectural deficiency was found, no negative case was weakened, and no warning was introduced.

## Unresolved decisions

- Whether a later phase should populate Genesis 5:10 onward, and whether the existing
  Adam–Seth–Enosh chronology derivations should then be extended to Kenan, is a **DOCUMENTED
  UNRESOLVED DECISION**. It is not an authorization to compute chronology now.
- Whether source-specific naming variants (for example Septuagint transliterations) should be
  recorded as `source_identity_alternate_name` rows for the newly added identities remains open;
  none was invented in this phase.

## Files changed

- `tests/fixtures/020-genesis-1-11-fixture.sql`
- `tests/validation/genesis-5-9-slice.sql`
- `tests/validation/phase13-coverage-report.sql`
- `scripts/validation/run-postgres-validation.sh`
- `data/genesis-1-11/README.md`
- `docs/04-data/PHASE13_REPORT.md`
