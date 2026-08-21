# API Epistemic Boundaries

This document states the epistemic distinctions the API must preserve, and — for each one — **where the boundary is
enforced in code** and **which test proves it**. It complements [`API_LIMITATIONS.md`](./API_LIMITATIONS.md), which
catalogues limitations; this document is about enforcement.

## 1. The distinctions

| Distinction | What the API does | Enforcement | Evidence |
|---|---|---|---|
| Source ≠ Evidence | `POST /api/v1/source-registrations` registers availability only; evidence requires a separate cited call | Separate routes; `evidence.source_record_id` is required | `tests/app/app.test.ts` |
| Evidence ≠ Claim | `POST /api/v1/evidence` never creates a claim | `createEvidence` writes only `evidence` and `evidence_citation` | `tests/app/app.test.ts` |
| Claim ≠ Truth | Claim status is `UNDER_REVIEW` or `ACTIVE`; there is no truth field, route, or flag | `createClaim` accepts no truth value; research returns `NOT_REPRESENTED` for proof questions | `tests/app/app.test.ts` |
| Analytical observation ≠ Source observation | A direct or interpretive claim cannot be supported by `ANALYTICAL_OBSERVATION` evidence | `DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION` (`src/administration/repository.ts:318`) → `422` | `tests/app/app.test.ts` |
| Derived ≠ Direct | A `DERIVED_CLAIM` requires a derivation with explicit inputs; a non-derived claim may not reference one | `DERIVATION_REQUIRED`, `DERIVATION_NOT_ALLOWED`, `DERIVATION_INPUT_REQUIRED` (`repository.ts:307`) | `tests/app/app.test.ts` |
| Derivation ≠ Claim | `POST /api/v1/derivations` records metadata and never creates a claim | The route writes only `derivation` and `derivation_input` | `tests/app/app.test.ts` |
| Source identity ≠ Canonical entity | Mappings are inserted as `PROPOSED` (`repository.ts:373`) | Only `POST /api/v1/identity-mappings/:id/review` may transition, and only `WHERE mapping_status_code = 'PROPOSED'` (`repository.ts:408`) | `tests/app/app.test.ts` |
| `PROPOSED` ≠ `ACTIVE` | Activation requires a reviewer, a rationale, and evidence from the supplying source | `IDENTITY_EVIDENCE_SOURCE_MISMATCH` (`repository.ts:368`, `:404`) → `422`; wrong state → `409 INVALID_MAPPING_STATE` | `tests/app/app.test.ts` |
| Candidate ≠ Evidence | Discovery candidates carry a `discoveryLocator`, never an observation | Candidates are written to `discovery_candidate` only; review records a decision | `tests/app/app.test.ts` |
| Relationship ≠ Truth | Only registered predicates may be asserted; the API cannot register a predicate | Unregistered predicates fail the foreign key → `422 INTEGRITY_VIOLATION` | `tests/app/app.test.ts`, `tests/validation/*` |
| Projection ≠ Second authority | `event_participation` and the graph routes are projections of claim-asserted propositions | Views only; no participant write route exists | `schema/sql/001_core_schema.sql`, `tests/app/app.test.ts` |
| Competing claims ≠ Contradiction resolved | Multiple claims over one proposition are preserved | No merge, overwrite, or winner route exists | `tests/app/app.test.ts` |
| Result classification ≠ Adjudication | One bounded research response can return `DIRECTLY_SUPPORTED`, `DERIVED_FROM_PERSISTED_GRAPH`, `SCHOLARLY_CANDIDATE`, `EVIDENCE_CONTRADICTS`, and `EVIDENCE_QUALIFIES` rows simultaneously; each classification reports the represented data state, not a verdict, and contradicting/qualifying rows are never shown as direct support | `classifyResearchRow()` and `researchCapability()` (`src/repository.ts`) | `tests/app/app.test.ts` (R2-11 mixed research result classifications), `tests/fixtures/146-r2-11-mixed-research-evidence-fixture.sql` |
| Competing interpretations ≠ Selected interpretation | Several `INTERPRETIVE_CLAIM` rows about one topic are returned together as `SCHOLARLY_CANDIDATE`; none is selected, preferred, ranked, or promoted | No selection or promotion path exists in `research()` | `tests/app/app.test.ts` (R2-11 mixed research result classifications) |
| `NOT_REPRESENTED` ≠ `FALSE` | Unrepresentable requests return `501 NOT_REPRESENTED` or `capability:"NOT_REPRESENTED"` with an explicit "absence is not denial" statement | `src/api/v1.ts`, `src/repository.ts` | `tests/app/app.test.ts` |
| `NO_MATCH` ≠ `FALSE` | Empty search results are classified `NO_MATCH` with an explicit non-denial statement | `src/api/v1.ts` search handler | `tests/app/app.test.ts` |
| Dataset scope ≠ truth adjudication | Dataset filters bound visible provenance only; derived rows can remain partial/mixed and are never promoted to direct support by filtering | `research()` dataset-scoped derived traversal (`src/repository.ts`) | `tests/app/app.test.ts` |
| Predicate match ≠ Subject relevance | Research resolves one represented subject first, then filters claims by proposition subject; cross-subject predicate matches are excluded | `src/repository.ts` `resolveResearchSubject()` + subject-bound `research()` query | `tests/app/app.test.ts` |
| Locator-only ≠ Source silence | Withheld raw content and quoted text are reported as `NOT_STORED_BY_POLICY` | `src/repository.ts` provenance explanation | `tests/app/app.test.ts` |
| Workflow state ≠ Knowledge | Corpus, topic, discovery, job, validation, and audit rows never become propositions | Separate tables; no promotion path exists | `docs/api/API_CAPABILITY_MATRIX.md`, `tests/app/app.test.ts` |
| Queued ≠ Completed | Queueing routes return `202` and persist `QUEUED` state only | No in-process execution exists | `tests/app/app.test.ts` |
| Audit ≠ Evidence | `audit_event` records who changed workflow state, never what a source says | Append-only trigger; audit rows are not joinable into provenance | `tests/app/app.test.ts` |
| Validation result ≠ Claim | Validation runs are reproducibility records | Append-only `validation_result`; no claim is produced | `scripts/validation/run-postgres-validation.sh` |

## 2. Absence semantics

Berean distinguishes four different kinds of "nothing here", and the API must never collapse them:

| Situation | Response | Meaning |
|---|---|---|
| The record does not exist | `404 NOT_FOUND` | Berean holds no such row |
| The capability is not representable | `501 NOT_REPRESENTED` | The schema cannot express the request; this is not a denial of the subject |
| Nothing matched the search term | `200` with `classification:"NO_MATCH"` | No persisted record matched; the subject may still be real |
| Content is intentionally withheld | `NOT_STORED_BY_POLICY` | The source may well say something; Berean does not store the text |

## 3. Routes that must never exist

These are permanently excluded, not deferred:

- `/truth`, `/verify`, `/prove`, or any adjudication route
- `/infer` or generalized inference over the graph
- `/approve-anything`, `/resolve-conflict`, `/make-canonical`
- arbitrary relationship or predicate creation over HTTP
- arbitrary import, URL fetch, filesystem access, or SQL execution
- automatic candidate → evidence, evidence → claim, derivation → claim, or `PROPOSED` → `ACTIVE` promotion

Adding any of them would move epistemic authority out of reviewed, provenance-bearing structures and into an API call.

## 4. Human review gates

Classification: **REQUIRES_HUMAN_REVIEW**. These transitions are deliberately not automated:

- candidate review decisions;
- identity mapping activation or rejection;
- claim authoring and claim status;
- acceptance of derived claims.

## 5. External access gates

Classification: **REQUIRES_EXTERNAL_SOURCE_ACCESS**. Berean records locators and licence status but performs no retrieval.
Acquiring source text is an out-of-band, reviewed activity (for example `scripts/acquisition/fetch-stepbible.sh`).
