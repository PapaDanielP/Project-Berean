# Project Berean API Developer Guide

## Status and contract

Berean is a provenance-first PostgreSQL reference model with a read-only Express
Explorer and an authenticated administration workflow. This guide documents the
API implemented in this repository, not a proposed service contract. Explorer
and research operations remain synchronous parameterized reads. Administrative
operations are controlled, transactional writes to the workflow layer or to the
existing authoritative objects; every implemented mutation is audited.

Two HTTP surfaces are currently exposed:

* **Explorer compatibility surface**: `/api/*`, used by the bundled Explorer.
* **Versioned surface**: `/api/v1/*`, a bounded read and administration
  interface. Its OpenAPI 3.1 discovery description is at `GET /openapi.json`.

Administrative routes require opaque bearer credentials whose SHA-256 hashes,
actor keys, names, and roles are supplied through `BEREAN_API_CREDENTIALS`.
Credentials are not stored in the database. If none are configured, mutations
fail closed with `503 AUTH_NOT_CONFIGURED`.

### Epistemic and persistence boundaries

`Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord
→ Dataset → Source` is the source-backed traversal. A claim is not truth, and
an `ESTABLISHED` research capability means only that the bounded retrieval
found represented, directly supported material. `claim.statement` is display
metadata; the structured Proposition is authoritative semantic content.

`event_participation` is a projection from claim-asserted propositions. It is
not an independently persisted event-participant assertion. Graph results are
stored claim/proposition edges, projection rows, or query-derived
neighborhoods—not a new claim or an inference result. A `NULL` source-record
body or citation quotation is reported as `NOT_STORED_BY_POLICY`, not source
silence. Source identities remain separate from canonical entities; a
`PROPOSED` mapping is not `ACTIVE`.

All research, search, graph, provenance explanation, and timeline output remains
transient. Database rows are never added or changed by those routes. The
application sends a 16 KiB JSON body limit and security headers
(`Content-Security-Policy`, `X-Content-Type-Options: nosniff`, and
`Referrer-Policy: no-referrer`), disables `X-Powered-By`, and uses
parameterized SQL.

## Shared behavior

Successful reads return `200` JSON unless stated otherwise. The compatibility
surface returns `{ "error": "..." }` for validation/not-found errors and
`{ "error": "internal_error", "message": "The request could not be completed." }`
for unhandled failures. V1 uses `{ "error": { "code", "message" } }`.
V1 unknown methods/routes return `501 NOT_REPRESENTED`; known nonexistent
resources return `404 NOT_FOUND`. Read failures can return `500`.

Examples use fixture values where named; numeric IDs are illustrative and must
be obtained by search or list first.

### Implementation locator

The server entrypoint is `src/server.ts`; application initialization, static
assets, security middleware, compatibility routes, and the final error handler
are in `src/app.ts:109-431`. The V1 router is
`src/api/v1.ts:44-179`. Database reads for all dynamic routes are in
`src/repository.ts`: resource/scope/research/search (`12-249`), entity through
source detail (`251-536`), provenance/derivation (`538-977`), timeline
(`1046-1403`), coverage/quality/graph (`1405-1592`). Tests covering the
surface are `tests/app/app.test.ts`; each route group below identifies its
relevant test coverage.

## Discovery and resource reads

| Method and route | Reads / response | Validation, bounds, and coverage |
|---|---|---|
| `GET /health` | Explorer `{status:"ok",mode:"read-only"}` | No database read. |
| `GET /api/v1/health` | Adds `api_version:"v1"` | No database read. |
| `GET /openapi.json` | OpenAPI 3.1 discovery object | Intentionally incomplete operation schemas. |
| `GET /api-docs` | Minimal HTML link to OpenAPI | Not Swagger UI. |
| `GET /api/v1/capabilities` | Implemented read capabilities and `NOT_REPRESENTED` limitations | Declares read-only boundary. |
| `GET /api/v1/schema` | Authoritative chain and projections | Reports that corpus/workflow tables do not exist. |
| `GET /api/v1/registry/{registry}` | `{results}` from a controlled registry | `predicates`, `entity-types`, `event-types`, `claim-types`, `evidence-types`, `mapping-statuses`; otherwise 404. `/registry/capabilities` 307-redirects to capabilities. |
| `GET /api/v1/{resource}?limit=1..100` | `{results}` compact rows | Resources: `entities`, `events`, `claims`, `evidence`, `sources`, `datasets`, `source-records`, `citations`, `identities`, `identity-mappings`. Default 50. |
| `GET /api/v1/{resource}/{id}` | Detail where implemented, otherwise a resource row | Positive safe integer only; 400 invalid, 404 absent. Entity/event/claim/source use richer reads. |
| `GET /api/entities/:entityId`, `/api/claims/:claimId`, `/api/propositions/:propositionId`, `/api/events/:eventId`, `/api/sources/:sourceId` | Explorer detail objects | Integer path parameter; 400 invalid and 404 absent. |
| `GET /api/sources` | `{sources}` with dataset and record counts | No pagination; returns every source. |

V1 compact resource fields map directly to schema tables: entity identity and
type; event type; claim/proposition/type/status; evidence/source-record/type;
source metadata; dataset license/version; record location/hash/revision;
citation locator; source identity; and mapping status/confidence/justification/
supporting evidence. Detail reads additionally assemble real adjacent rows:
entity mappings/claims/events/related entities; event participation and claims;
claim proposition/evidence/claim relations/derivation; source datasets and up
to 200 source records; and a proposition's claims.

## Search is not research

`GET /api/search?q=<text>&limit=1..50` returns
`{query,results:[{type,id,key,label,detail}]}`. `q` is required and at most
200 characters; default limit is 20 (maximum 50). It performs case-insensitive
substring matching against represented entity names/keys, events, claim keys
and statements, proposition predicates, evidence, sources, datasets, source
records/locations, citations/locators, and source identities. It does not
search authoritative source text unless that text happens to be stored in one
of those fields.

`GET /api/v1/search[/{resource}]?q=<text>&limit=1..100` invokes the same
search with V1 bounds/default 50 and adds `"classification":"MATCHED"`.
The optional suffix filters by the singularized result type (for example,
`/api/v1/search/entities`). `MATCHED` means only a keyword hit: it is not
evidence, support, establishment, or a provenance result.

Example: `GET /api/search?q=Gen.1.1&limit=20` can return a citation locator.
Use the returned claim ID with provenance, or entity ID with graph/timeline,
rather than treating the hit as an answer.

## Natural-language research and scope

| Route | Request / response | Actual behavior |
|---|---|---|
| `GET /api/research/scope` | `{sources,datasets,inventory}` | Lists persisted sources/datasets and counts records, evidence, claims; it neither creates a scope nor reconciles identity. |
| `POST /api/research` | JSON `{question, datasetIds?: number[]}` | Returns question, interpretation, capability, plan, results, limitation. |
| `POST /api/v1/research` | Same body/result | Same implementation, V1 validation envelope. |
| `GET /api/v1/research/capabilities` | Mode and classifications | Documents supported classifications only. |

Question is required, trimmed, and at most 1,000 characters. `datasetIds`
contains at most 100 positive safe integers; duplicates are removed. Omit or
pass `[]` for **all** represented datasets. One ID restricts results to that
dataset; multiple IDs restrict to their union. An empty/stale/nonmatching scope
is valid: it can return `NO_MATCH`, never an invented answer. The API does not
validate that an ID exists before querying, and it does not persist scope
selection.

Research is a bounded rule-based retrieval, not general natural-language
reasoning. Questions mentioning participation select predicates registered with
an event participation role; other questions match registered predicate code or
description. It returns at most 50 matching persisted claims with their
proposition, evidence relation, and source/dataset labels. The plan reports
`BEREAN_ONLY`, selected IDs, candidate predicates, traversal shape, output
constraints, and full-chain requirement. It does not fetch external sources,
expand arbitrary hops, invent predicates, evaluate truth, or persist a plan.

Capability/result meanings are exact implementation labels:

* `ESTABLISHED`: non-derived results directly linked by `SUPPORTS`; not truth.
* `DERIVED` / `DERIVED_FROM_PERSISTED_GRAPH`: a stored `DERIVED_CLAIM`, with
  derivation metadata/inputs available through claim or provenance reads.
* `SCHOLARLY_CANDIDATE`: an `INTERPRETIVE_CLAIM`, not automatically fact.
* `UNRESOLVED`: an inactive (`UNDER_REVIEW`, `SUPERSEDED`, `RETRACTED`) claim,
  or evidence relation that is not direct support.
* `NOT_REPRESENTED`: a truth/proof request or no registered predicate match;
  it is not falsehood or a denial.
* `NO_MATCH`: registered retrieval found no selected-scope persisted claim.

Individual result classifications may instead expose `EVIDENCE_CONTRADICTS` or
`EVIDENCE_QUALIFIES`. Those report a stored ClaimEvidence relation, not a
global contradiction resolution.

## Provenance, claims, identities, and derivation

| Route | Inputs | Output / limits |
|---|---|---|
| `GET /api/provenance/claims/:claimId` | Integer | Raw joined traversal rows for a claim; it returns an empty traversal for an absent claim (unlike explain). |
| `GET /api/provenance/explain?claim_id=N` | Exactly one positive `claim_id` or `proposition_id` | Deterministic `EXPLAIN_PROVENANCE`; 400 invalid/both/neither, 404 absent. |
| `GET /api/v1/provenance/claim/:id` | Positive ID | Same deterministic claim explanation, V1 envelope. |
| `GET /api/derivations/check-eligibility?derivation_id=N` | Positive ID | Check list (`PASS`, `FAIL`, `NOT_APPLICABLE`); 404 absent. |

Explanation returns the selected authoritative proposition; claim(s); source
chain IDs; deduplicated supporting evidence, citations, records, datasets, and
sources; projected participation; derivation and inputs; per-claim and overall
structural gaps. Direct claims are `SOURCE-BACKED` or
`SOURCE-BACKED_WITH_GAPS`; derived claims are `DERIVED` or
`DERIVED_WITH_GAPS`. It checks missing ClaimEvidence/citation/record/dataset/
source, missing projected participation, and malformed/missing/self derivation
inputs. It does not assess truth, causation, theology, contradiction,
compliance, or generalized inference.

Entity detail, timeline, and V1 identity/mapping resources expose source
identities separately and mapping status, confidence, justification, notes,
and supporting evidence ID. Consumers must preserve that state: a proposed or
unresolved mapping is not active reconciliation.

## Entity, event, timeline, and graph exploration

`GET /api/exploration/timeline?entity_id=N` or
`?entity_key=ark_of_covenant` requires exactly one selector. It returns the
entity, coverage, mappings, related events, each event's claim/proposition/
provenance, projected participation, entity-only claims, source comparison,
stored claim relations, and ordering. It returns 400 invalid/both/neither and
404 with `coverage_status:"NO_ENTITY_FOUND"` absent. Dates are only stored
typed values; ordering is date, then stored year, then event ID. A comparison
label of `DIFFERING_SOURCE_DESCRIPTION` is explicitly not contradiction.

`GET /api/graph?nodeType=entity|claim&nodeId=N` and
`GET /api/v1/graph/entity/:id` return bounded neighborhoods from actual
claim/proposition, participation, and provenance edges. They are not graph
database queries, relationship truth, or persisted derived claims. In Phase
37R, for example, an available person→exhibit→technology path is query-derived;
shared exhibit participation does not assert employment or membership.

`GET /api/genesis/coverage` is a Genesis-location-specific dashboard (up to
300 locators), not general corpus coverage. `GET /api/dashboard/quality`
returns current structural counts/quality classifications. Both are read-only
and data-dependent.

## Supported composition workflows

1. **Research**: call scope, select IDs, post a question, inspect plan and
   classification, then explain a returned claim. Treat an empty result or
   `NOT_REPRESENTED` as a coverage/capability boundary.
2. **Search to research**: keyword-search `Nikola Tesla` or
   `CLAIM_MT_ADAM_FATHER_SETH`; use its source/dataset context to select scope;
   research registered predicates rather than promoting `MATCHED`.
3. **Claim to provenance**: search claim → get claim detail → explain by claim
   ID → follow locator, record, dataset, and source. Inspect gaps and storage
   policy flags before relying on the chain.
4. **Entity to graph**: search entity → entity detail/timeline → graph
   neighborhood → verify any edge's asserting claim via provenance.
5. **Scope comparison**: run the same bounded question with `[]`, one dataset,
   then multiple datasets. Compare represented descriptions; do not label
   disagreement as contradiction unless a stored ClaimRelation says so.

## Administration and workflow API

The persistence decision and semantic boundaries are documented in
`docs/01-architecture/KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`. Administrative
list reads are `GET /api/v1/admin/{corpora|topics|discoveries|candidates|jobs|
validations|audits|exports}?limit=1..100`. They require at least `READER`.

| Minimum role | Operations |
|---|---|
| `RESEARCHER` | create research topics and discovery requests/candidates; record derivations with explicit inputs |
| `CONTENT_EDITOR` | register source/dataset and source-record/citation locators; create evidence; propose evidence-backed identity mappings; queue/cancel/retry ingestion |
| `REVIEWER` | review candidates/mappings; author validated claims; queue validation |
| `ADMINISTRATOR` | create/archive/version corpora; queue controlled exports |

Jobs require `Idempotency-Key`; exact duplicate replay by actor and job type
returns the existing job, while a different payload returns
`IDEMPOTENCY_CONFLICT`. Corpus updates require numeric `If-Match` and return
`STALE_VERSION` on conflict. Mutations return an `X-Correlation-Id` and append
an audit event in the same transaction. Audit and validation results are
database-immutable.

Discovery requests and candidates never create Evidence or Claims. Source
registration keeps Source, Dataset, SourceRecord, and Citation distinct.
Evidence creation requires citation identifiers and creates no Claim. Direct
and interpretive claim authoring accepts only cited `SOURCE_OBSERVATION`
evidence. Derivation creation accepts explicit claim/evidence inputs and creates
no Claim automatically. Identity mappings begin `PROPOSED` and require a
reviewer to become `ACTIVE` or `REJECTED`.

Still unavailable: arbitrary URL retrieval, uploads, filesystem access, SQL,
registry mutation, generalized inference, truth/falsity/causation/superiority
decisions, automatic candidate/evidence/claim promotion, and an in-process
durable worker. Jobs persist controlled state for a separately deployed SYSTEM
worker. Locators are metadata only, so the API exposes no SSRF-capable fetch
operation.

## API-to-data-model mapping and capability matrix

| Capability | Primary objects | Read | Write | Persistent result | Human review/provenance | Current |
|---|---|---:|---:|---:|---|---|
| Resource/registry reads | listed tables and controlled vocabularies | Yes | No | No | Existing provenance only | Yes |
| Search | indexed columns of represented tables | Yes | No | No | `MATCHED` is not evidence | Yes |
| Research | claim, proposition, ClaimEvidence, source chain | Yes | No | No | Bounded classifications/full-chain plan | Yes |
| Provenance/derivation check | claim/evidence/citation/derivation inputs | Yes | No | No | Structural, deterministic only | Yes |
| Timeline/graph | proposition, `event_participation`, claim relations | Yes | No | No | Stored/projected/query-derived separated | Yes |
| Corpus/content management | workflow plus source through claim/identity/derivation | Yes | Controlled | Yes | Role, review, audit, provenance gates | Yes |
| Candidate/discovery workflow | request, candidate, review, job, audit | Yes | Controlled | Yes | Candidate never auto-promotes | Yes |
| Ingestion/validation/export plans | specialized asynchronous jobs | Yes | Queue/state | Yes | Idempotent; SYSTEM worker required | Partial |

## Remaining implementation priorities

P1: deploy a durable SYSTEM worker for queued ingestion, validation, and export
execution. It must preserve transaction/license policies and append immutable
results; it must never convert discovery into evidence automatically.

P2: expand the OpenAPI discovery document with complete request/response
component schemas and pagination contracts.

P3: if external acquisition is added, first provide a separately sandboxed
retriever with the URL/DNS/redirect/network/license controls listed in the
architecture assessment. Do not add truth, inference, registry-mutation, or
arbitrary relationship-authoring endpoints.

## Documentation verification report

**Endpoints inspected:** every Express route in `src/app.ts` and
`src/api/v1.ts` and `src/administration/routes.ts`, including wildcard fallback
and static/API documentation routes. **Source inspected:** `src/app.ts`,
`src/api/v1.ts`, `src/administration/*`, `src/repository.ts`, `src/types.ts`,
`src/server.ts`, schema SQL, application tests, package scripts, README,
Explorer/Phase 25 documentation, and Phase 37R/37B artifacts.

**Tests inspected:** `tests/app/app.test.ts` (including read-only count
snapshots, scope semantics, research classifications, validation, provenance,
timeline, and graph assertions) and Phase 37R validation references.
The OpenAPI document remains a discovery contract rather than a complete set of
response schemas. `/api/provenance/claims/:id` does not 404 for an absent claim,
while explain does. No generalized inference or external retrieval is claimed.

Verification commands for this documentation change are `npm run typecheck`,
`npm run lint`, `npm test` (requires `DATABASE_URL`), and
`scripts/validation/run-postgres-validation.sh` (PostgreSQL 16).
