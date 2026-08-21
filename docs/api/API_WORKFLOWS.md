# API Workflows and Composition Recipes

This guide describes **actual implemented route sequences**. It does not introduce new endpoints, new predicates, or automatic promotions.

Related documents: [`API_DEVELOPER_GUIDE.md`](./API_DEVELOPER_GUIDE.md), [`API_CAPABILITY_MATRIX.md`](./API_CAPABILITY_MATRIX.md), [`API_SECURITY_MODEL.md`](./API_SECURITY_MODEL.md), [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md).

Cross-reference the architectural workflow decision in [`../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`](../01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md).

## Composition rules that always apply

1. **Search hit ≠ answer.** `MATCHED` search results are only lookup aids.
2. **Candidate ≠ evidence.** Discovery routes never create evidence automatically.
3. **Evidence ≠ claim.** Evidence creation never creates a claim automatically.
4. **Claim ≠ truth.** Claim persistence records an assertion with provenance, not truth.
5. **PROPOSED ≠ ACTIVE.** Identity mappings require an explicit review route.
6. **Queued job ≠ completed job.** Job routes persist queue state only; the SYSTEM worker is a separate process, and only validation jobs currently execute.
7. **Validation PASS ≠ truth.** A validation result is a structural reproducibility record, never historical truth or adjudication.

## Recipe 1: bounded research over what already exists

1. **Inspect available persisted scope**  
   `GET /api/research/scope`
2. **Optionally keyword-search a name or locator**  
   `GET /api/search?q=Nikola%20Tesla&limit=20`
3. **Run bounded research**  
   `POST /api/research`
4. **Explain a returned claim structurally**  
   `GET /api/provenance/explain?claim_id=<id>`
5. **Inspect entity context or graph neighborhood**  
   `GET /api/exploration/timeline?entity_key=phase37r_nikola_tesla`  
   `GET /api/graph?nodeType=entity&nodeId=<id>`

What must **not** be inferred:

- `ESTABLISHED` means structurally source-backed, not true.
- `NO_MATCH` means no persisted match in the selected scope, not falsehood.
- A graph neighborhood is query output, not a persisted new relationship.

## Recipe 2: corpus → topic → discovery request → candidate → review

1. **Create corpus**  
   `POST /api/v1/corpora`
2. **Create research topic**  
   `POST /api/v1/research-topics`
3. **Queue discovery request**  
   `POST /api/v1/discovery-requests` with `Idempotency-Key`
4. **Record a candidate**  
   `POST /api/v1/discovery-requests/:id/candidates`
5. **Review that candidate**  
   `POST /api/v1/candidates/:id/review`
6. **List workflow state**  
   `GET /api/v1/admin/discoveries`, `/candidates`, `/jobs`, `/audits`

Typical WCE example:

- corpus: `1893 World's Columbian Exposition`
- topic: `electrical-exhibits`
- discovery request: `CANDIDATE_DISCOVERY`
- candidate: unsupported relationship `wonTechnologyConflict`
- review: `NOT_REPRESENTED`

What to call next:

- If the candidate is only a workflow artifact, stop here.
- If a human reviewer decides source-backed representation is warranted, move manually into Recipe 3.

What must **not** be inferred:

- A queued discovery request is not discovery output.
- A reviewed candidate still does not create evidence or claims.
- `NOT_REPRESENTED` means the current schema/registry cannot express the requested semantics; it does not mean the proposition is false.

## Recipe 3: reviewed source registration → source record → citation → evidence

1. **Register source and dataset**  
   `POST /api/v1/source-registrations`
2. **Register source record and citation locator**  
   `POST /api/v1/source-records`
3. **Create evidence from that source record**  
   `POST /api/v1/evidence`
4. **Verify source detail if needed**  
   `GET /api/sources/:sourceId` or `GET /api/v1/sources/:id`

Example shape:

- source: reviewed historical work or official catalogue
- dataset: locator-only bounded dataset
- source record: one locator-bearing record
- citation: one locator
- evidence: `SOURCE_OBSERVATION` or `ANALYTICAL_OBSERVATION`

What to call next:

- To author a claim from direct source material, continue to Recipe 4.
- To retain analytical observations without promotion, stop after evidence creation.

What must **not** be inferred:

- registering a source does not create source text, evidence, or claims;
- evidence does not create a claim;
- analytical evidence is not direct-claim evidence.

## Recipe 4: evidence → proposition/claim → provenance check

1. **Create direct or interpretive claim**  
   `POST /api/v1/claims`
2. **Explain claim provenance**  
   `GET /api/provenance/explain?claim_id=<id>`
3. **Inspect proposition-wide siblings if needed**  
   `GET /api/propositions/:propositionId`
4. **Inspect entity or event context**  
   `GET /api/entities/:entityId` / `GET /api/events/:eventId`

Genesis example:

- direct claim like `Adam fatherOf Seth`
- provenance chain through `Claim -> ClaimEvidence -> Evidence -> Citation -> SourceRecord -> Dataset -> Source`

What to call next:

- If reconciliation is required, continue to Recipe 5.
- If derivation metadata is required for a future derived claim, continue to Recipe 6.

What must **not** be inferred:

- claim status is not truth;
- the optional `statement` is display metadata only;
- `QUALIFIES` / `CONTRADICTS` claim-evidence links report stored relation type only, not global truth resolution.

## Recipe 5: source identity → proposed mapping → explicit review

1. **Create proposed mapping**  
   `POST /api/v1/identity-mappings`
2. **Review mapping**  
   `POST /api/v1/identity-mappings/:id/review`
3. **Inspect entity-centered mapping state**  
   `GET /api/entities/:entityId` or `GET /api/v1/identity-mappings/:id`

Example boundaries from fixtures and manual verification:

- `phase37-catalogue-mrs-potter-palmer` remains `PROPOSED` until explicit review.
- A manually created mapping returned `PROPOSED`, then `REJECTED` only after the review route.

What must **not** be inferred:

- source identity is not canonical entity;
- `PROPOSED` is not `ACTIVE`;
- evidence from a different source cannot justify the mapping.

## Recipe 6: derivation metadata → structural eligibility → derived claim

1. **Create derivation metadata with explicit inputs**  
   `POST /api/v1/derivations`
2. **Check structural eligibility**  
   `GET /api/derivations/check-eligibility?derivation_id=<id>`
3. **If and only if a reviewer decides to persist a derived claim, create it**  
   `POST /api/v1/claims` with `claimType: "DERIVED_CLAIM"` and `derivationId`
4. **Explain the resulting claim**  
   `GET /api/provenance/explain?claim_id=<id>`

What must **not** be inferred:

- derivation metadata is not a derived claim;
- structural eligibility is not logical entailment;
- creating a derivation never creates a claim automatically.

## Recipe 7: queue validation / export / ingestion work

1. **Queue job**  
   `POST /api/v1/validation-runs`  
   `POST /api/v1/export-jobs`  
   `POST /api/v1/ingestion-jobs`
2. **Inspect queue state**  
   `GET /api/v1/admin/jobs`
3. **Cancel or retry if necessary**  
   `POST /api/v1/jobs/:id/cancel`  
   `POST /api/v1/jobs/:id/retry`
4. **Inspect specialized table rows**  
   `GET /api/v1/admin/validations` or `/exports`

What must **not** be inferred:

- `QUEUED` is not execution;
- queue requests do not themselves produce `validation_result`, `ingestion_result`, or export artifacts;
- retry/cancel only change persisted workflow state.

## Recipe 8: full administration lifecycle with explicit human gates

Implemented sequence:

1. `POST /api/v1/corpora`
2. `POST /api/v1/research-topics`
3. `POST /api/v1/discovery-requests`
4. `POST /api/v1/discovery-requests/:id/candidates`
5. `POST /api/v1/candidates/:id/review`
6. `POST /api/v1/source-registrations`
7. `POST /api/v1/source-records`
8. `POST /api/v1/evidence`
9. `POST /api/v1/claims`
10. `GET /api/provenance/explain?claim_id=<id>`
11. `POST /api/v1/identity-mappings`
12. `POST /api/v1/identity-mappings/:id/review`
13. `POST /api/v1/derivations`
14. `GET /api/derivations/check-eligibility?derivation_id=<id>`
15. `POST /api/v1/validation-runs`
16. `POST /api/v1/export-jobs`

What is **not** implemented as an automatic chain:

- corpus → topic → source registration is not auto-triggered;
- candidate review does not auto-create source records, evidence, claims, or mappings;
- derivation eligibility does not auto-create a derived claim;
- queued ingestion work does not auto-complete; queued validation and bounded export work complete only when the separate SYSTEM worker process is running.

## Asynchronous semantics

| Route | Status | What is persisted synchronously | What requires a SYSTEM worker |
|---|---|---|---|
| `POST /api/v1/discovery-requests` | `202` | `discovery_request` + `asynchronous_job` (`QUEUED`) | Candidate production |
| `POST /api/v1/ingestion-jobs` | `202` | `asynchronous_job` (`QUEUED`) | Ingestion execution and `ingestion_result` rows |
| `POST /api/v1/validation-runs` | `202` | `validation_run` + `asynchronous_job` (`QUEUED`) | Execution by the SYSTEM worker's read-only validation executor, append-only `validation_result` rows, and `validation_run.completed_at` |
| `POST /api/v1/export-jobs` | `202` | `export_job` + `asynchronous_job` (`QUEUED`) | Export artifact production |

Rules:

1. `202` means *the queue state is durably persisted*, never *the work is done*.
2. Poll `GET /api/v1/admin/jobs` for status, `GET /api/v1/admin/validation-results` for validation results, and resolve completed exports through `GET /api/v1/export-artifacts/:artifactKey`. `npm run worker` executes `SYSTEM_NOOP`, `VALIDATION`, and bounded `EXPORT` jobs. Ingestion and discovery jobs legitimately remain `QUEUED` until their bounded executors are implemented.
3. Every queueing route requires `Idempotency-Key`. Replaying the same key with the same request fingerprint returns the original job; replaying it with a different fingerprint returns `409 IDEMPOTENCY_CONFLICT` and writes nothing.
4. `POST /api/v1/jobs/:id/cancel` and `/retry` change workflow state only and return `409 INVALID_JOB_STATE` when the transition is not allowed.

## Conflict handling recipe

Berean reports every write conflict as `409`, so one branch handles them all:

| Code | Meaning | Correct client action |
|---|---|---|
| `STALE_VERSION` | The `If-Match` version is not current | Re-read the resource, re-apply the change, retry |
| `IDEMPOTENCY_CONFLICT` | The key was reused with a different body | Use a new `Idempotency-Key` |
| `INVALID_MAPPING_STATE` | The mapping is no longer `PROPOSED` | Re-read the mapping; do not force activation |
| `INVALID_JOB_STATE` | The job cannot make that transition | Re-read job status |
| `DUPLICATE` | The stable key already exists | Reuse the existing row |

No `409` ever commits a partial write: each mutation runs in a single transaction together with its audit row.

## Search and provenance composition

1. `GET /api/v1/search/{resource}?q=...` — normalized lookup that applies the resource filter before the result limit. `NO_MATCH` means nothing persisted matched; it is not falsity.
2. `GET /api/v1/{resource}/{id}` — expanded detail for the matched record.
3. `GET /api/v1/provenance/claim/{id}` — structured provenance with explicit gap reporting (`404` when the claim is not represented).
4. `GET /api/v1/graph/entity/{id}` — bounded neighborhood projected from claim-asserted propositions; a projected edge is never a new claim.

`GET /api/provenance/claims/{id}` remains available for the Explorer interface and intentionally returns `200` with an empty `traversal` and `classification:"CLAIM_NOT_REPRESENTED"` for an unrepresented claim. New integrations should use the versioned route.
