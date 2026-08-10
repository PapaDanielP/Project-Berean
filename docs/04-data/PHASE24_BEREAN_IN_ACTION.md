# Phase 24 — Berean in Action

**PHASE 24 STATUS: IMPLEMENTED**<br>
**ARCHITECTURAL STATUS: NO SCHEMA CHANGE JUSTIFIED**<br>
**OPERATION: SOURCE-BACKED DATA CONSTRUCTION + READ-ONLY DEMONSTRATION**<br>
**MODE: FIXTURE / VALIDATION SLICE / EXISTING API ROUTES ONLY**<br>
**SEMANTIC INFERENCE: ONE DOCUMENTED CROSS-SOURCE DERIVATION ONLY**<br>
**PERSISTENCE: EXPLICIT FIXTURE INSERTS ONLY**<br>
**SOURCE DIFFERENCE PRESERVATION: EXPLICIT**<br>
**PHASE 19/21/23 REGRESSION: PASSING**

## What was built

Phase 24 extends the existing Ark-of-the-Covenant material forward to the Ark's placement in Solomon's temple, using two parallel source traditions:

- `1KI_MT` / `1KI_MT_REF` for **1 Kings 8:3-4, 8:6-9**
- `2CH_MT` / `2CH_MT_REF` for **2 Chronicles 5:4-5, 5:7-10**

The phase adds:

- 2 new `source` rows
- 2 new `dataset` rows
- 12 new `source_record` rows
- 12 new `citation` rows
- 12 new `evidence` rows
- 6 new `event` rows (`OTHER` only)
- 11 new `proposition` rows
- 22 new `DIRECT_SOURCE_CLAIM` rows
- 1 new `DERIVED_CLAIM`
- 1 new `derivation`
- 2 new `derivation_input` rows
- 6 new `source_identity` rows
- 2 new `source_identity_alternate_name` rows
- 6 new evidence-backed `entity_source_mapping` rows

No schema, registry, route, repository, table, column, predicate, event type, relationship type, JSON payload, or inference subsystem was added.

## Data scope

Exact bounded locators populated in this phase:

### 1 Kings

- `MT_1KI_8_3` — `1 Kings 8:3`
- `MT_1KI_8_4` — `1 Kings 8:4`
- `MT_1KI_8_6` — `1 Kings 8:6`
- `MT_1KI_8_7` — `1 Kings 8:7`
- `MT_1KI_8_8` — `1 Kings 8:8`
- `MT_1KI_8_9` — `1 Kings 8:9`

### 2 Chronicles

- `MT_2CH_5_4` — `2 Chronicles 5:4`
- `MT_2CH_5_5` — `2 Chronicles 5:5`
- `MT_2CH_5_7` — `2 Chronicles 5:7`
- `MT_2CH_5_8` — `2 Chronicles 5:8`
- `MT_2CH_5_9` — `2 Chronicles 5:9`
- `MT_2CH_5_10` — `2 Chronicles 5:10`

Sources/datasets used:

- `1KI_MT` / `1KI_MT_REF`
- `2CH_MT` / `2CH_MT_REF`

Reused canonical entities:

- `ark_of_covenant`
- `poles_ark_covenant`
- `priests_levites_ark_bearers`
- `tablets_of_testimony`

No second Ark, poles, or bearer canonical entity was introduced.

## Provenance examples

The new slice was built so each direct claim has the full deterministic chain:

`Claim -> ClaimEvidence -> Evidence -> EvidenceCitation -> Citation -> SourceRecord -> Dataset -> Source`

Example SQL used in `tests/validation/phase24-berean-in-action-slice.sql`:

```sql
SELECT c.claim_key,
       ce.relation_type_code,
       ev.evidence_key,
       ci.citation_key,
       ci.locator,
       sr.source_record_key,
       d.dataset_key,
       s.source_key
FROM claim c
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence ev ON ev.evidence_id = ce.evidence_id
JOIN evidence_citation ec ON ec.evidence_id = ev.evidence_id
JOIN citation ci ON ci.citation_id = ec.citation_id
JOIN source_record sr ON sr.source_record_id = ev.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
WHERE c.claim_key IN ('CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE',
                      'CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE')
ORDER BY c.claim_key;
```

Representative result shape:

```text
CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE | SUPPORTS | EV_MT_1KI_8_8 | CITE_MT_1KI_8_8 | 1 Kings 8:8        | MT_1KI_8_8  | 1KI_MT_REF | 1KI_MT
CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE | SUPPORTS | EV_MT_2CH_5_9 | CITE_MT_2CH_5_9 | 2 Chronicles 5:9   | MT_2CH_5_9  | 2CH_MT_REF | 2CH_MT
```

A second example resolves the bearer wording difference side-by-side without any `claim_relation`:

```sql
SELECT s.source_key,
       sr.source_location,
       c.claim_key,
       c.statement,
       en.entity_key,
       ev.event_key,
       cr.claim_relation_id,
       cr.relation_type_code
FROM claim c
JOIN proposition p ON p.proposition_id = c.proposition_id
JOIN entity en ON en.entity_id = p.subject_entity_id
JOIN event ev ON ev.event_id = p.object_event_id
JOIN claim_evidence ce ON ce.claim_id = c.claim_id
JOIN evidence e ON e.evidence_id = ce.evidence_id
JOIN source_record sr ON sr.source_record_id = e.source_record_id
JOIN dataset d ON d.dataset_id = sr.dataset_id
JOIN source s ON s.source_id = d.source_id
LEFT JOIN claim_relation cr ON cr.claim_id = c.claim_id OR cr.related_claim_id = c.claim_id
WHERE c.claim_key IN ('CLAIM_1KI_BEARERS_SUBJECT_TAKE_UP_TEMPLE',
                      'CLAIM_2CH_BEARERS_SUBJECT_TAKE_UP_TEMPLE')
ORDER BY s.source_key;
```

Expected result shape:

```text
1KI_MT | 1 Kings 8:3      | CLAIM_1KI_BEARERS_SUBJECT_TAKE_UP_TEMPLE | ...priests... | priests_levites_ark_bearers | ark_covenant_taken_up_temple_placement | NULL | NULL
2CH_MT | 2 Chronicles 5:4 | CLAIM_2CH_BEARERS_SUBJECT_TAKE_UP_TEMPLE | ...Levites... | priests_levites_ark_bearers | ark_covenant_taken_up_temple_placement | NULL | NULL
```

## API/query demonstrations

Phase 24 uses only existing read-only routes.

### `GET /api/provenance/explain`

Resolve a real claim id first:

```sql
SELECT claim_id
FROM claim
WHERE claim_key = 'CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE';
```

Then call:

```text
GET /api/provenance/explain?claim_id=<returned-claim-id>
```

Actual response (captured against a disposable local PostgreSQL 16 instance loaded with `schema/sql/001_core_schema.sql` and fixtures `020`, `050`, `040`, `060`, `070`, `080`, `090`, `100`, in that order; `claim_id=159` resolved `CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE` in that run — exact ids are run-dependent, resolve them by `claim_key` as shown above):

```json
{
  "operation": "EXPLAIN_PROVENANCE",
  "resolution_scope": "CLAIM",
  "read_only": true,
  "claims": [
    {
      "claim": {
        "claim_key": "CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE",
        "claim_type_code": "DIRECT_SOURCE_CLAIM"
      },
      "provenance_status": "SOURCE-BACKED",
      "structural_gaps": [],
      "supporting_evidence": [
        { "evidence_key": "EV_MT_1KI_8_8" }
      ],
      "citations": [
        { "citation_key": "CITE_MT_1KI_8_8", "locator": "1 Kings 8:8", "quoted_text_status": "NOT_STORED_BY_POLICY" }
      ],
      "source_records": [
        { "source_record_key": "MT_1KI_8_8", "raw_content_status": "NOT_STORED_BY_POLICY" }
      ],
      "datasets": [
        { "dataset_key": "1KI_MT_REF" }
      ],
      "source": [
        { "source_key": "1KI_MT", "source_type_code": "SCRIPTURE" }
      ],
      "derivation": null,
      "derivation_inputs": []
    }
  ],
  "provenance_status": "COMPLETE",
  "structural_gaps": []
}
```

The same pattern works for the 2 Chronicles parallel claim:

```sql
SELECT claim_id
FROM claim
WHERE claim_key = 'CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE';
```

```text
GET /api/provenance/explain?claim_id=<returned-claim-id>
```

### `GET /api/derivations/check-eligibility`

Resolve the stored derivation through its derived claim:

```sql
SELECT derivation_id
FROM claim
WHERE claim_key = 'CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED';
```

```text
GET /api/derivations/check-eligibility?derivation_id=<returned-derivation-id>
```

Actual response, captured the same way:

```json
{
  "operation": "CHECK_DERIVATION_ELIGIBILITY",
  "derivation": {
    "method": "Cross-source comparison of the shared pole-visibility observation at the Ark's placement in the temple"
  },
  "derived_claim": {
    "claim_key": "CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED",
    "claim_type_code": "DERIVED_CLAIM"
  },
  "input_status": [
    { "input_claim_key": "CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE", "kind_valid": true, "reference_valid": true, "provenance_structurally_complete": true, "self_input": false },
    { "input_claim_key": "CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE", "kind_valid": true, "reference_valid": true, "provenance_structurally_complete": true, "self_input": false }
  ],
  "checks": [
    { "id": "DERIVATION_EXISTS", "status": "PASS" },
    { "id": "DERIVED_CLAIM_EXISTS", "status": "PASS" },
    { "id": "DERIVED_CLAIM_TYPE_VALID", "status": "PASS" },
    { "id": "DERIVATION_LINK_VALID", "status": "PASS" },
    { "id": "METHOD_PRESENT", "status": "PASS" },
    { "id": "ASSUMPTIONS_PRESENT", "status": "PASS" },
    { "id": "DERIVATION_INPUT_EXISTS", "status": "PASS" },
    { "id": "DERIVATION_INPUT_KIND_VALID", "status": "PASS" },
    { "id": "DERIVATION_INPUT_REFERENCE_VALID", "status": "PASS" },
    { "id": "INPUT_PROVENANCE_STRUCTURALLY_COMPLETE", "status": "PASS" },
    { "id": "SELF_INPUT_ABSENT", "status": "PASS" },
    { "id": "TARGET_PROPOSITION_EXISTS", "status": "PASS" },
    { "id": "TARGET_PREDICATE_VALID", "status": "PASS" },
    { "id": "TARGET_TERM_KINDS_VALID", "status": "PASS" }
  ],
  "structurally_eligible": true,
  "license_status": "REQUIRES_HUMAN_METHOD_JUSTIFICATION",
  "read_only": true
}
```

### Additional read-only SQL demonstrations

`tests/validation/phase24-berean-in-action-slice.sql` also demonstrates:

1. event/participation exploration for all six new Phase 24 events;
2. derivation-input dependency listing for the one cross-source derivation;
3. reconciliation queries showing both source traditions mapped ACTIVE to the same canonical Ark, poles, and bearer entities with distinct supporting evidence.

## Coverage summary

Bounded Phase 24 counts:

| Object | Count |
| --- | ---: |
| Source | 2 |
| Dataset | 2 |
| SourceRecord | 12 |
| Citation | 12 |
| Evidence | 12 |
| Event | 6 |
| Proposition | 11 |
| Direct Claim | 22 |
| Derived Claim | 1 |
| Derivation | 1 |
| DerivationInput | 2 |
| SourceIdentity | 6 |
| SourceIdentityAlternateName | 2 |
| EntitySourceMapping | 6 |
| ClaimRelation | 0 |

## Source differences

The main cross-source difference in this phase is the wording of who took up the Ark:

- **1 Kings 8:3** names **priests** taking up the Ark.
- **2 Chronicles 5:4** names **Levites** taking up the Ark.

Phase 24 preserves that difference as source-backed difference only:

- separate direct claims;
- separate evidence observations;
- separate source identities (`mt-ark-bearers-1ki8` and `mt-ark-bearers-2ch5`);
- separate supporting evidence for the two ACTIVE mappings.

No contradiction was inferred, and no `claim_relation` row was added.

## Derivation example and why it is genuine

Phase 24 adds exactly one derivation:

- **Method:** `Cross-source comparison of the shared pole-visibility observation at the Ark's placement in the temple`
- **Derived claim:** `CLAIM_XSRC_POLES_VISIBLE_HOLY_PLACE_TEMPLE_SHARED_DERIVED`
- **Inputs:**
  - `CLAIM_1KI_POLES_VISIBLE_HOLY_PLACE_TEMPLE`
  - `CLAIM_2CH_POLES_VISIBLE_HOLY_PLACE_TEMPLE`

This derivation is justified because both sources make the same bounded observation about the poles being visible from the Holy Place before the inner sanctuary but not from outside, and each source presents that observation as true at the time of its own writing. The derivation does **not** merge or resolve the priests-versus-Levites wording difference, does **not** infer compliance with Exodus 25:15, and does **not** extend the observation beyond what both sources say.

## Limitations

- No place entity or richer temple-location graph was added for the inner sanctuary / Holy Place wording.
- No temple-cherubim canonical entity was added in this bounded phase.
- The tablets-only observation is represented through event semantics already available in the model, not through a new inventory or exclusivity subsystem.
- Numeric ids (`claim_id`, `derivation_id`, etc.) are run-dependent (Postgres `GENERATED ALWAYS AS IDENTITY`); resolve them by stable `claim_key`/`derivation` linkage as shown above, not by hard-coded id.

## Verification results

Run against a disposable local PostgreSQL 16 instance (schema + fixtures loaded fresh, then dropped):

- `npm run lint` — passed, no errors.
- `npm run typecheck` — passed, no errors.
- `npm run build` — passed, no errors.
- `npm test` (vitest, `DATABASE_URL` pointed at the disposable database) — **26/26 tests passed**, including the 4 new Phase 24 tests in `tests/app/app.test.ts` (1 Kings provenance, 2 Chronicles provenance, derivation eligibility, read-only guarantee) and all pre-existing Phase 19/21/23 tests.
- `scripts/validation/run-postgres-validation.sh` — completed with exit code `0`, including the new Phase 24 fixture/slice/coverage-report section, the unmodified Phase 19 negative-cases suite (18/18 blocked as expected), and the final generic negative-integrity/`blocking-cases.sh` re-run (all passed).
- `GET /api/provenance/explain` and `GET /api/derivations/check-eligibility` were exercised directly against the running app (via a temporary local HTTP listener) for the new Phase 24 claims/derivation; responses matched the shapes shown above, and `structurally_eligible: true` with all fourteen checks `PASS` was returned for the new derivation.

## Deliberately unmade conclusions

Phase 24 deliberately does **not** conclude any of the following:

- compliance with Exodus 25:15;
- non-compliance or violation;
- contradiction between 1 Kings and 2 Chronicles;
- causation, punishment, or theological meaning;
- a broader temple inventory beyond the selected locators;
- any new global factual core about bearers beyond the separate source-backed claims.

## Classification of issues discovered

- **Preserved source difference:** priests vs Levites in the take-up wording.
- **Documented unresolved decision:** reuse of one canonical bearer organization rather than introducing a second canonical organization from wording alone.
- **No new schema deficiency found:** the existing generic model remained sufficient for this bounded slice.

## Did the existing generic model remain sufficient?

**Yes.** The existing generic model remained sufficient because the bounded source material could be represented with existing `OTHER` events, existing `subjectOf` / `participatesIn` predicates, existing provenance tables, and existing source-identity reconciliation structures. No reproducible need for a new table, route, predicate, role, or event type appeared in this slice.

## Highest-value next question based on actual usage

A modest next question would be whether **Jeremiah 3:16** deserves its own bounded slice as a later Ark reference, tested with the same provenance-first discipline and without collapsing the earlier Ark lifecycle material into a single harmonized narrative.
