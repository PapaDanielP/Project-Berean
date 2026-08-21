# Final Platform Architecture Audit

**Classification:** REVIEW / AUDIT record. This document records findings and evidence. It does **not**
define runtime behavior, schema semantics, or API contracts. Implementation (`src/`), schema
(`schema/sql/`), executable tests (`tests/`), and validation scripts (`scripts/validation/`) remain the
behavioral authority; the authoritative current documentation listed in [`../README.md`](../README.md)
remains the current specification.

**Audit date:** 2026-08-14 · **Base branch:** `main` · **Repository:** `PapaDanielP/Project-Berean`
**Scope:** repository-wide platform, API, administration, ingestion, provenance, Explorer,
documentation governance, and executable coverage.

---

## 1. Executive summary

Project Berean is a provenance-aware PostgreSQL reference model with a TypeScript/Express read-only
Explorer, a versioned read API, an authenticated administration API, and an ingestion pipeline. This
audit inventoried the whole repository, compared implemented routes against OpenAPI, API
documentation, and tests, traced every administrative and knowledge lifecycle, audited the Explorer
web application end to end (including real headless-browser testing against a fully populated
database), and executed every available verification command.

The platform is architecturally sound. Its epistemic boundaries survive the API **and** the Explorer
user interface: discovery is not converted to evidence, candidates are not converted to claims, claims
are not presented as truth, projections are not presented as new assertions, `NO_MATCH` and
`NOT_REPRESENTED` are not presented as falsity, `PROPOSED` mappings are not presented as active
identity, and derived claims are not presented as source-backed observations. Route-surface OpenAPI
coverage is complete and enforced in both directions by an executable test.

Two implementation defects were found by behavioral testing, both in read projections, both of which
are visible in the Explorer, and both of which are recorded here rather than fixed, because this task
is an audit and change discipline forbids unjustified implementation changes:

- **F-01 (SIGNIFICANT GAP / IMPLEMENTATION BUG)** — `GET /api/v1/search/{resource}` applies `limit`
  *before* the resource filter, so a small `limit` returns `classification: "NO_MATCH"` while matching
  persisted records exist. `NO_MATCH` is epistemically load-bearing, so an incorrect `NO_MATCH` is more
  than a paging inconvenience.
- **F-02 (IMPLEMENTATION BUG)** — the entity graph neighborhood emits self-referential edges
  (`Adam —fatherOf→ Adam`) because the self-exclusion guard compares a PostgreSQL `bigint` returned as
  a JavaScript string with a number. The Explorer renders those edges verbatim.

Neither defect mutates persisted state, weakens authorization, or changes stored semantics. Both are
read-path projection defects with a recommended next-phase remediation described in §21.

**Final classification: PLATFORM ARCHITECTURALLY SOUND — MINOR GAPS** (see §25 for the justification
and for why the passing test suite alone was not treated as sufficient evidence).

---

## 2. Repository state and inventory

Inventory performed before any change, over `README.md`, `docs/**`, `src/**`, `schema/**`, `tests/**`,
`scripts/**`, `data/**`, `.github/**`, `package.json`, `tsconfig.json`, `vitest.config.ts`,
`eslint.config.js`.

| Area | Contents | Notes |
|---|---|---|
| Application | `src/app.ts` (443 lines), `src/api/v1.ts`, `src/api/openapi.ts`, `src/administration/{routes,service,repository}.ts`, `src/auth.ts`, `src/repository.ts` (1600 lines), `src/types.ts`, `src/server.ts` | Single Express app; one PostgreSQL pool; no second data store |
| Explorer | `src/app.ts` HTML shell + `src/public/app.js` (630 lines) + `src/public/styles.css` | Dependency-free ES module client; no framework, no build step, no router |
| Ingestion | `src/ingestion/{pipeline,classifier,manifest,types,run-ingestion}.ts` | Executed by `npm run ingest`; the HTTP API only queues ingestion jobs |
| Schema | `schema/sql/001_core_schema.sql`, `002_validation_queries.sql`, `003_administration_workflow.sql` | Authoritative physical model plus the workflow/administration boundary |
| Tests | `tests/app/{app,phase28-ingestion,openapi-coverage,documentation-links}.test.ts`; `tests/fixtures/**` (22 fixtures); `tests/validation/**` (60+ SQL/bash suites) | 112 Vitest tests |
| Scripts | `scripts/validation/run-postgres-validation.sh`, `scripts/validation/validate.sql`, `scripts/acquisition/fetch-stepbible.sh` | Replays fixtures and phase validations |
| Data | `data/candidates/`, `data/external/`, `data/genesis-1-11/`, `data/ingestion/` | Candidate CSVs and source metadata; no source text committed |
| CI | `.github/workflows/postgres-validation.yml` | PostgreSQL 16 service; runs the validation script on push and pull request |
| Documentation | `docs/00-project` … `docs/07-review`, `docs/api`, `docs/phases`, `docs/README.md`, root `README.md` | Structure matches `docs/01-architecture/REPOSITORY_STRUCTURE.md` |

No duplicate API documentation set exists outside `docs/api/`. No competing documentation hierarchy,
misplaced fixtures, stray generated artifacts, committed credentials, `.env` files, database dumps, or
log files were found. Nothing was modified during the inventory pass.

## 3. Authority verification

The authority hierarchy declared in [`../README.md`](../README.md) was verified against reality rather
than assumed:

1. **Implementation / schema / executable tests** — confirmed as the only place where behavior is
   decided. Every finding in this report was derived from executed code, executed SQL, executed HTTP
   requests, or a browser session, not from documentation.
2. **Authoritative current documentation** — `CHARTER.md`, `ARCHITECTURE.md`,
   `KNOWLEDGE_ADMINISTRATION_WORKFLOW.md`, `REPOSITORY_STRUCTURE.md`, `DOMAIN_MODEL.md`,
   `INFORMATION_SCHEMA.md`, and `docs/api/**` were checked against the implementation; one drift was
   found (F-04) and corrected in this pass.
3. **Reference documentation** — `EXPLORER_READ_ONLY_ADAPTER.md` was verified statement by statement
   against `src/public/app.js` and observed HTTP traffic; it is accurate.
4. **Phase records**, 5. **validation records**, 6. **review/audit material** — preserved unchanged.
   No historical conclusion was rewritten, renumbered, or upgraded into a current specification.

## 4. Architecture

- One Express application composes: security headers → JSON body limit (16 KiB) → static
  `/public` → health/OpenAPI → administration router (`/api/v1`) → read router (`/api/v1`) →
  compatibility read routes (`/api/...`) → Explorer HTML fallback (`GET *`) → administration error
  handler → generic 500 handler.
- Data access is confined to `BereanRepository` and `AdministrationRepository`. All SQL uses bound
  parameters. The Explorer performs no database access and contains no SQL.
- Administration writes run inside `BEGIN`/`COMMIT`/`ROLLBACK` in `AdministrationRepository.transaction`,
  resolve the actor into `workflow_actor`, and write an `audit_event` row inside the same transaction.
- Workflow structures (`corpus`, `research_topic`, `discovery_request`, `discovery_candidate`,
  `candidate_review`, `asynchronous_job`, `validation_run`, `export_job`, `audit_event`) are separate
  from the authoritative chain (`source → dataset → source_record → citation → evidence →
  claim_evidence → claim → proposition`) and never substitute for it.
- `event_participation` and `claim_rendering` remain views projected from claim-asserted propositions.

**Verified, not assumed:** `GET /api/v1/schema` returns exactly that separation at runtime, and the
audit's own administrative probe created workflow rows without creating a single claim, evidence,
proposition, or identity mapping.

## 5. Schema / API alignment

| Authoritative structure | Read exposure | Write exposure | Verified |
|---|---|---|---|
| `source`, `dataset`, `source_record`, `citation` | `/api/sources`, `/api/sources/{id}`, `/api/v1/{sources,datasets,source-records,citations}` | `POST /api/v1/source-registrations`, `POST /api/v1/source-records` (CONTENT_EDITOR) | Yes |
| `evidence`, `claim_evidence` | claim detail, provenance routes, `/api/v1/evidence` | `POST /api/v1/evidence` (CONTENT_EDITOR) | Yes |
| `claim`, `proposition` | `/api/claims/{id}`, `/api/propositions/{id}`, `/api/v1/claims/{id}` | `POST /api/v1/claims` (REVIEWER) | Yes |
| `entity`, `event`, `event_participation` | `/api/entities/{id}`, `/api/events/{id}`, timeline, graph | none (entities/events are not HTTP-creatable) | Yes |
| `source_identity`, `entity_source_mapping` | `/api/v1/identities`, `/api/v1/identity-mappings` | `POST /api/v1/identity-mappings`, `POST /api/v1/identity-mappings/{id}/review` | Yes |
| `derivation`, `derivation_input` | `/api/derivations/check-eligibility` | `POST /api/v1/derivations` (RESEARCHER) | Yes |
| Registries (`predicate`, `*_type`, `mapping_status`) | `/api/v1/registry/{registry}` | **none by design** — registry change requires a reviewed migration | Yes |
| Workflow tables | `/api/v1/admin/{resource}` (READER) | corpora/topics/discovery/candidates/jobs routes | Yes |

`GET /api/v1/propositions/{id}` is **not** implemented although `propositions` is a supported search
filter (F-10). No other schema structure exposed for search lacks a documented read path.

## 6. API inventory and endpoint matrix

Route surface introspected from the live Express stack of `createApp()`: **51 method/path layers** =
49 addressable routes + 2 wildcard fallbacks. This matches the count recorded in
[`../api/OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md) and is enforced by
`tests/app/openapi-coverage.test.ts`.

Legend — Auth: `—` none, role name = minimum role (hierarchical). Tested: `T` behavior-asserted in
`tests/app/**`, `M` manually exercised during this audit, `C` code-traced only. Explorer: `Y` used by
`src/public/app.js`, `N` unused.

### 6.1 Infrastructure and read routes

| Endpoint | Method | Impl | Auth | Tested | OpenAPI | Documented | Persistent effect | Audit | Idem. | Concurrency | Explorer |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `/health` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | N |
| `/openapi.json` | GET | yes | — | T | yes | yes | none | n/a | n/a | n/a | N |
| `/api-docs` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/health` | GET | yes | — | T | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/capabilities` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/schema` | GET | yes | — | M (C in suite) | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/registry/{registry}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/search`, `/api/v1/search/{resource}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/research` | POST | yes | — | T,M | yes | yes | **none** (transient) | n/a | n/a | n/a | N |
| `/api/v1/research/capabilities` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/provenance/claim/{id}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/graph/entity/{id}` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/{resource}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/v1/{resource}/{id}` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | N |
| `ALL /api/v1/*` (fallback) | ALL | yes | — | T,M | fallback entry | yes | none | n/a | n/a | n/a | N |
| `/api/research/scope` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/research` | POST | yes | — | T,M | yes | yes | **none** (transient) | n/a | n/a | n/a | **Y** |
| `/api/search` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/entities/{entityId}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/claims/{claimId}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/propositions/{propositionId}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/events/{eventId}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/sources` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/sources/{sourceId}` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/provenance/claims/{claimId}` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/provenance/explain` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/derivations/check-eligibility` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/exploration/timeline` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | N |
| `/api/genesis/coverage` | GET | yes | — | T,M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/dashboard/quality` | GET | yes | — | M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `/api/graph` | GET | yes | — | T (400 only), M | yes | yes | none | n/a | n/a | n/a | **Y** |
| `GET *` (Explorer shell) | GET | yes | — | T,M | fallback entry | yes | none | n/a | n/a | n/a | **Y** |

### 6.2 Administration routes

| Endpoint | Method | Impl | Min role | Tested | OpenAPI | Documented | Persistent effect | Audit | Idem. | Concurrency | Explorer |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `/api/v1/admin/{resource}` | GET | yes | READER | T,M | yes | yes | none | read | n/a | n/a | N |
| `/api/v1/corpora` | POST | yes | ADMINISTRATOR | T,M | yes | yes | `corpus` | yes | key uniqueness → 409 DUPLICATE | version 1 | N |
| `/api/v1/corpora/{id}` | PATCH | yes | ADMINISTRATOR | T,M | yes | yes | `corpus` | yes | n/a | **If-Match; 409 STALE_VERSION verified** | N |
| `/api/v1/research-topics` | POST | yes | RESEARCHER | T,M | yes | yes | `research_topic` | yes | key uniqueness | version | N |
| `/api/v1/discovery-requests` | POST | yes | RESEARCHER | T,M | yes | yes | `discovery_request` + queued job | yes | **Idempotency-Key verified (replay 202, conflict 409)** | n/a | N |
| `/api/v1/discovery-requests/{id}/candidates` | POST | yes | RESEARCHER | T,M | yes | yes | `discovery_candidate` (UNREVIEWED) | yes | key uniqueness | n/a | N |
| `/api/v1/candidates/{id}/review` | POST | yes | REVIEWER | T,M | yes | yes | `candidate_review` (+ status transition) | yes | upsert per candidate | n/a | N |
| `/api/v1/source-registrations` | POST | yes | CONTENT_EDITOR | T | yes | yes | `source` + `dataset` | yes | key uniqueness | n/a | N |
| `/api/v1/source-records` | POST | yes | CONTENT_EDITOR | T | yes | yes | `source_record` + `citation` | yes | key uniqueness | n/a | N |
| `/api/v1/evidence` | POST | yes | CONTENT_EDITOR | T | yes | yes | `evidence` + `evidence_citation` | yes | key uniqueness | n/a | N |
| `/api/v1/claims` | POST | yes | REVIEWER | T | yes | yes | `proposition` + `claim` + `claim_evidence` | yes | key uniqueness | n/a | N |
| `/api/v1/identity-mappings` | POST | yes | CONTENT_EDITOR | T | yes | yes | `entity_source_mapping` (PROPOSED) | yes | uniqueness | n/a | N |
| `/api/v1/identity-mappings/{id}/review` | POST | yes | REVIEWER | T | yes | yes | mapping status → ACTIVE/REJECTED | yes | n/a | 409 INVALID_MAPPING_STATE | N |
| `/api/v1/derivations` | POST | yes | RESEARCHER | T | yes | yes | `derivation` + `derivation_input` | yes | n/a | n/a | N |
| `/api/v1/ingestion-jobs` | POST | yes | CONTENT_EDITOR | C | yes | yes | queued `asynchronous_job` + `ingestion_job` | yes | Idempotency-Key | n/a | N |
| `/api/v1/validation-runs` | POST | yes | REVIEWER | T,M | yes | yes | queued job + `validation_run` | yes | **Idempotency-Key verified** | n/a | N |
| `/api/v1/export-jobs` | POST | yes | ADMINISTRATOR | C | yes | yes | queued job + `export_job` | yes | Idempotency-Key | n/a | N |
| `/api/v1/jobs/{id}/cancel` | POST | yes | CONTENT_EDITOR + ownership | T,M | yes | yes | job status → CANCELLED | yes | n/a | **409 INVALID_JOB_STATE verified** | N |
| `/api/v1/jobs/{id}/retry` | POST | yes | CONTENT_EDITOR + ownership | M | yes | yes | job requeue + attempt++ | yes | n/a | **409 INVALID_JOB_STATE verified** | N |

**Discrepancies identified:** F-01, F-05, F-10 (§21). No endpoint is implemented but undocumented; no
endpoint is documented but unimplemented; no Explorer call is absent from OpenAPI.

## 7. Administrative and knowledge lifecycles

Each stage below was exercised over HTTP during this audit against a fully populated database
(Phase 30–37R fixtures loaded by the validation script).

| Stage | API | Persistence | AuthZ | Idem. | Concurrency | Audit | Provenance | Human review | Tests | OpenAPI | Docs | Explorer |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Corpus | `POST/PATCH /corpora` | `corpus` | ADMINISTRATOR | key uniqueness | If-Match version | yes | n/a | owner | yes | yes | yes | none (intentional) |
| Source registration | `POST /source-registrations` | `source`+`dataset` | CONTENT_EDITOR | key | n/a | yes | starts chain | reviewed acquisition | yes | yes | yes | read-only view |
| Ingestion | `POST /ingestion-jobs` queue only; `npm run ingest` executes | `asynchronous_job`,`ingestion_job` | CONTENT_EDITOR | Idempotency-Key | n/a | yes | manifest-driven | yes | pipeline tested (35 tests) | yes | yes | none |
| Discovery | `POST /discovery-requests` | `discovery_request` + queued job | RESEARCHER | **verified** | n/a | yes | locator only | request-level | yes | yes | yes | none |
| Candidate | `POST /discovery-requests/{id}/candidates` | `discovery_candidate` (UNREVIEWED) | RESEARCHER | key | n/a | yes | `discovery_locator` | required | yes | yes | yes | none |
| Candidate review | `POST /candidates/{id}/review` | `candidate_review` | REVIEWER | upsert | n/a | yes | rationale | **explicit** | yes | yes | yes | none |
| Evidence / citation | `POST /source-records`, `POST /evidence` | `source_record`,`citation`,`evidence` | CONTENT_EDITOR | key | n/a | yes | citation required | yes | yes | yes | yes | read-only view |
| Claim / proposition | `POST /claims` | `proposition`,`claim`,`claim_evidence` | REVIEWER | key | n/a | yes | 422 without cited SOURCE_OBSERVATION | yes | yes | yes | yes | read-only view |
| Entity/event projection | none (read) | `event_participation` view | n/a | n/a | n/a | n/a | claim-asserted | n/a | yes | yes | yes | yes |
| Identity mapping | `POST /identity-mappings` (+ `/review`) | `entity_source_mapping` | CONTENT_EDITOR / REVIEWER | uniqueness | 409 on non-PROPOSED | yes | evidence must come from the same source | **required** | yes | yes | yes | mapping status shown |
| Derivation | `POST /derivations`, `GET /api/derivations/check-eligibility` | `derivation`,`derivation_input` | RESEARCHER | n/a | n/a | yes | explicit inputs | yes | yes | yes | yes | derivation shown |
| Validation run | `POST /validation-runs` | `validation_run` + job | REVIEWER | **verified** | n/a | yes | n/a | yes | yes | yes | yes | none |
| Export | `POST /export-jobs` | `export_job` + job | ADMINISTRATOR | Idempotency-Key | n/a | yes | reproducibility note required | yes | code-traced | yes | yes | none |
| Job control | `POST /jobs/{id}/{cancel,retry}` | job status | CONTENT_EDITOR + ownership | n/a | **409 verified** | yes | n/a | yes | partly | yes | yes | none |
| Audit | `GET /api/v1/admin/audits` | `audit_event` (append-only trigger) | READER | n/a | n/a | is the audit | correlation id | yes | yes | yes | yes | none |

Observed lifecycle evidence (this audit, HTTP): corpus `201` → `PATCH` with `If-Match: 1` → `200`
(`version` 1→2) → replayed `If-Match: 1` → `409 STALE_VERSION`; topic `201`; discovery `202` →
identical replay `202` returning the **same** `discovery_request_id` → different body with the same
`Idempotency-Key` → `409 IDEMPOTENCY_CONFLICT`; candidate `201` with `representation_status:
"UNREVIEWED"`; review decision `NEEDS_SOURCE_VERIFICATION` → `200` and the candidate deliberately
**stays** `UNREVIEWED` (only `APPROVED`/`REJECTED`/`NOT_REPRESENTED` transition it); validation run
`202 QUEUED`; `retry` on a queued job → `409`; `cancel` → `200 CANCELLED`; second `cancel` → `409`;
`audit_event` rows written for every one of those operations with a correlation id.

**No candidate, discovery record, or job produced evidence, a claim, a proposition, or an identity
mapping.** The workflow boundary held under live exercise.

## 8. Security

| Control | Implementation | Verified |
|---|---|---|
| Authentication | `BearerAuthenticator`; SHA-256 digest compared with `timingSafeEqual`; credentials from `BEREAN_API_CREDENTIALS` | Missing credential → `401 UNAUTHENTICATED` + `WWW-Authenticate: Bearer`; wrong token → `401`; valid token → `200` |
| Not configured | No credentials → `503 AUTH_NOT_CONFIGURED` for every administrative route | Asserted in `tests/app/app.test.ts` |
| Authorization | Hierarchical roles READER < RESEARCHER < CONTENT_EDITOR < REVIEWER < ADMINISTRATOR < SYSTEM, enforced server-side per route | Tested; `403 FORBIDDEN` on insufficient role |
| Enumeration resistance | Auth evaluated before resource existence; unknown admin resource → `404` only when authenticated; unknown job → `409` not `404` | Verified over HTTP |
| Transport of secrets | No token, credential, or session is ever handled by the Explorer client | Code-traced + observed network log (no `Authorization` header from the browser) |
| CSRF | No cookies, no session, no ambient credential; writes require an explicit bearer token | Code-traced |
| XSS | All dynamic values rendered with `textContent`; `innerHTML` used only to clear containers | Browser probe with `<img src=x onerror=alert(1)>` produced **0** injected nodes and no page error |
| CSP | `default-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'` | Observed on responses; the policy actively blocked `unsafe-eval` during browser automation |
| Other headers | `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `x-powered-by` disabled | Observed |
| Injection | Every query uses bound parameters; resources/registries are allow-listed maps, never interpolated | Code-traced across `src/repository.ts` and `src/administration/repository.ts` |
| Input bounds | JSON body ≤ 16 KiB; `q` ≤ 200; question ≤ 1000; `datasetIds` ≤ 100; limits bounded | Verified (400 responses) |
| Error disclosure | Generic handler returns `{"error":"internal_error","message":"The request could not be completed."}` | **Verified against an unavailable database**: `500` with no stack trace, driver code, SQL, or table name on both `/api/search` and `/api/v1/entities/1` |

## 9. Provenance

The full chain `claim → proposition → evidence → citation → source_record → dataset → source` was
traced end to end in the browser. For `CLAIM_P37R_ELECTRICAL_EXHIBITION_AT_ELECTRICITY_BUILDING` the
Explorer rendered:

```
Claim: CLAIM_P37R_ELECTRICAL_EXHIBITION_AT_ELECTRICITY_BUILDING
Evidence (SUPPORTS): EV_P37R_DIRECTORY_ELECTRICITY_BUILDING
Citation: Official Directory (1893), Electricity Building and classified exhibitor directory
Source record: P37R_DIRECTORY_ELECTRICITY_BUILDING
Dataset: Phase 37R official directory reference points
Source: Official Directory of the World's Columbian Exposition
```

`NOT_STORED_BY_POLICY` is emitted by `explainProvenance` and the timeline route for `NULL`
`quoted_text`/`raw_content` and is documented as locator-only storage rather than source silence. The
Explorer never renders quoted text or raw content at all, so it cannot misrepresent absent text as
source silence; it also does not surface the policy status (F-07 records the related presentation gap
for derived claims).

## 10. Epistemic boundaries (API)

| Boundary | Enforcement | Verified |
|---|---|---|
| Claim ≠ truth | Research capability values never assert truth; claim status is preserved | `SUPERSEDED` claim displayed as superseded |
| Evidence ≠ claim | `422 DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION`; analytical observation cannot back a direct claim | Tested |
| Discovery ≠ evidence | Candidates carry only a `discovery_locator`; no promotion route exists | Live probe |
| Candidate ≠ claim | Review records a decision; representation status is not a claim | Live probe |
| PROPOSED ≠ ACTIVE | Only `POST /identity-mappings/{id}/review` transitions; `409 INVALID_MAPPING_STATE` otherwise | Tested |
| Derived ≠ source-backed | `DERIVATION_REQUIRED` / `DERIVATION_INPUT_REQUIRED` (422); eligibility is structural only | Tested + live |
| Truth requests | `POST /api/research` with proof language → `capability: NOT_REPRESENTED`, `results: []` | Live + browser |
| `NO_MATCH` ≠ false | Explicit non-denial limitation text on every empty result | Live (see F-01 for the one incorrect trigger) |
| `NOT_REPRESENTED` ≠ false | `501` and research capability text both state absence ≠ denial | Live |
| Projection ≠ assertion | `event_participation` rows carry `asserting_claim_id` | Live |
| Registry immutability over HTTP | No predicate/registry write route exists; `501` on any attempt | Live (`PUT /api/v1/anything` → `501 NOT_REPRESENTED`) |

## 11. OpenAPI audit

Measured by introspecting the live route stack and `openApiDocument()`:

| Classification | Count | Detail |
|---|---|---|
| IMPLEMENTED_AND_DOCUMENTED | 49 addressable routes + 2 fallbacks | Enforced bidirectionally by `tests/app/openapi-coverage.test.ts` |
| IMPLEMENTED_BUT_UNDOCUMENTED | 0 | A new undocumented route fails the suite |
| DOCUMENTED_BUT_NOT_IMPLEMENTED | 0 | Phantom operations fail the suite |
| OPENAPI_ONLY | 0 | Same enforcement |
| DOCUMENTED_AND_TESTED | 37 addressable routes + 2 fallbacks | Per-route evidence in `API_CAPABILITY_MATRIX.md` |
| IMPLEMENTED_BUT_UNTESTED | 12 | Enumerated in `OPENAPI_GAP_REPORT.md` §IMPLEMENTED_BUT_UNTESTED |

This audit manually exercised 8 of those 12 untested routes (`/health`, `/api-docs`, `/api/sources`,
`/api/sources/{id}`, `/api/dashboard/quality`, `/api/v1/schema`, `/api/v1/research/capabilities`,
`/api/v1/graph/entity/{id}`, plus `/api/v1/{resource}/{id}` and `POST /api/v1/jobs/{id}/retry`); all
behaved as documented. Manual exercise is **not** a substitute for automated assertions, so the
recorded gap stands (F-11).

**Explorer calls absent from OpenAPI: none.** Every one of the ten endpoints the Explorer calls is
documented under the `compatibility` tag.

## 12. Documentation governance

- `docs/README.md` remains the authority map; the hierarchy is stated and matches observed reality.
- `docs/01-architecture/REPOSITORY_STRUCTURE.md` remains the placement authority; no file violates it.
- `docs/api/` is the single canonical API documentation location; no competing API guide exists
  elsewhere (also enforced by `tests/app/documentation-links.test.ts`).
- Historical material is preserved: legacy Phase 6–32 records under `docs/04-data/`, later phase
  studies under `docs/phases/`, prior audits under `docs/07-review/`. Nothing was renumbered, rewritten,
  or deleted in this pass.
- Review documents are classified in `docs/README.md`; this report is added under REVIEW / AUDIT and
  explicitly disclaims runtime authority in its header.
- Markdown link integrity: `tests/app/documentation-links.test.ts` resolves every local link across all
  tracked Markdown files and guards retired path fragments — 10 tests, all passing after this change.

One documentation drift was found and corrected (F-04); everything else in the authoritative and
reference sets matched the implementation.

## 13. Explorer architecture

- **Shape.** A server-rendered HTML shell (constant in `src/app.ts`) plus one dependency-free ES module
  (`src/public/app.js`, 630 lines). No framework, no bundler, no client router, no service worker, no
  hidden build step. Any unmatched `GET` returns the same shell, so the application has exactly one
  page and no stale routes.
- **Data access.** 100% HTTP. There is no database driver, SQL string, or connection configuration in
  client code, and no duplicated server business logic: classification, capability, plan, and
  provenance decisions all arrive from the server; the client only groups results by the server-supplied
  `classification` value.
- **API abstraction.** A single `fetchJson(url, options)` wrapper centralizes request execution, JSON
  parsing, and error normalization. All ten endpoints go through it.
- **State.** Module-level state only (`scopeState`, `selected`, `graphEdges`, abort controllers). The
  only persistence is `sessionStorage['berean-scope']`, holding dataset identifiers, which are
  re-intersected with freshly discovered identifiers on load. No knowledge is cached client-side.
- **Types.** The client is plain JavaScript with no type declarations, and it is outside the lint
  target (`npm run lint` covers `src/**/*.ts` and `tests/app/**/*.ts`). Recorded as F-12.
- **Loading / empty / error states.** Present and distinct for scope, search, research, detail, graph,
  and provenance (`Loading represented detail…`, `No represented records matched this keyword.`,
  `The bounded graph neighborhood could not be loaded.`, etc.).
- **Auth / capability detection.** The Explorer is read-only by construction: no login, no token, no
  administrative control, and no capability probing. It cannot expose an unsupported capability because
  it renders no write affordance at all.
- **Hard-coded knowledge.** None. The only literals are UI placeholder text (`Try: Adam, Gen.1.1,
  CLAIM_MT…`) and the client-side page size (25). Every identifier used in a request comes from a
  server response.
- **Static fallback.** There is no offline/static fallback data set; if an API call fails the UI says so
  rather than presenting substitute content — the correct behavior for a provenance-first application.

## 14. Explorer ↔ API contract

| Explorer call | Method | Request assumptions | Response assumptions | Server behavior | Status |
|---|---|---|---|---|---|
| `/api/research/scope` | GET | none | `payload.datasets[]` with `dataset_id`, `name`, `source_name`, counts | matches | **Correct & documented** |
| `/api/research` | POST | JSON `{question, datasetIds}`; empty array = all datasets | `capability`, `interpretation`, `plan`, `results[].classification`, `limitation` | matches | **Correct & documented** |
| `/api/search?q&limit=25` | GET | `q` ≤ 200, `limit` positive | `{query, results[]}` with `type,id,key,label` | matches; effective cap 50 | **Correct & documented** |
| `/api/entities/{id}` | GET | numeric id from a search hit | `entity`, `sourceMappings`, `events`, `claims` | matches | **Correct & documented** |
| `/api/claims/{id}` | GET | numeric id | `claim`, `proposition`, `evidence`, `derivation`, `claimRelations` | matches | **Correct & documented** |
| `/api/propositions/{id}` | GET | numeric id | rendered generically | matches | **Correct & documented** |
| `/api/events/{id}` | GET | numeric id | `event`, `participation`, `claims` | matches | **Correct & documented** |
| `/api/sources`, `/api/sources/{id}` | GET | none / numeric id | `sources[]` / `source`,`datasets`,`sourceRecords` | matches | **Correct & documented** |
| `/api/provenance/claims/{id}` | GET | numeric id | **200 with `traversal[]` even when the claim is absent** | matches, and the divergence from `/api/v1/provenance/claim/{id}` (404) is explicitly documented in OpenAPI | **Correct & documented** |
| `/api/genesis/coverage`, `/api/dashboard/quality` | GET | none | arbitrary JSON rendered as formatted text | matches | **Correct & documented** |
| `/api/graph?nodeType&nodeId` | GET | `nodeType ∈ {entity, claim}` | `edges[]` with `source,relation,target` | matches, but see **F-02** | **Correct contract, defective projection** |

- **Outdated assumptions:** none found.
- **Undocumented/private calls:** none — every call is an OpenAPI-documented compatibility route.
- **Bypassing:** none — no database access, no duplicated server logic, no hidden endpoint.
- **Error-envelope handling:** the Explorer reads the legacy `{ "error": "message" }` shape used by
  every route it calls, and otherwise falls back to a generic message. It never renders a raw server
  payload into an error message.
- **Unused server capabilities** (F-06): `/api/exploration/timeline`, `/api/provenance/explain`,
  `/api/derivations/check-eligibility`, and the entire `/api/v1` surface (including
  `/api/v1/identities/{id}`, which would give the Explorer a real detail view for `source_identity`
  search hits that currently fall back to the "no dedicated bounded detail endpoint" message).
- **Missing server capability needed by the UI:** none.

## 15. Explorer user-workflow testing

**Browser automation was available and was used.** The bundled Playwright MCP browser tool was not
reachable in this environment, so Playwright 1.49.1 with Chromium Headless Shell 131 was installed
under `/tmp` (outside the repository, not committed, `package.json` unchanged) and driven against
`http://localhost:3210`, an application instance started with `npx tsx src/server.ts` over the
PostgreSQL database populated by `scripts/validation/run-postgres-validation.sh` (Phase 6–37R
fixtures: 30 sources, 36 datasets, 179 source records, 191 evidence rows, 361 claims, 157 entities).

Session facts: page title `Project Berean Explorer`; scope panel discovered **36 of 36 datasets · 378
linked claims**; **0 console errors and 0 page errors** across both sessions; observed network calls
were exactly the ten documented compatibility endpoints and nothing else.

## 16. User-prompt matrix

Expectations were derived from the data actually represented and from the API's actual capabilities,
not from historical plausibility.

| # | Prompt / action | Expected API | Expected classification | Expected UI | Actual result | Verdict |
|---|---|---|---|---|---|---|
| 1 | Search `Nikola Tesla` | `GET /api/search` | MATCHED (lexical) | hits labelled `MATCHED`, "Matches are not established claims." | 9 hits incl. citation, claims, entity `phase37r_nikola_tesla`; status text as expected | **PASS** |
| 2 | Search `George Westinghouse` | `GET /api/search` | MATCHED | hits for the Westinghouse company/identity material | matched records returned and labelled | **PASS** |
| 3 | Search `World's Columbian Exposition` | `GET /api/search` | MATCHED | source/dataset/event hits | matched records returned | **PASS** |
| 4 | Search `AC` | `GET /api/search` | MATCHED (substring) | hits labelled as lexical matches | matched records returned, all labelled `MATCHED` | **PASS** |
| 5 | Search `DC` | `GET /api/search` | MATCHED (substring) | 2 lexical hits, no AC/DC narrative | dataset + source-record hits only; no comparison, ranking, or verdict | **PASS** |
| 6 | Search `1893` | `GET /api/search` | MATCHED | citations/source records/events | 25 hits (bounded), all labelled | **PASS** |
| 7 | Search `Genesis` | `GET /api/search` | MATCHED | Genesis citations | 25 hits (bounded) | **PASS** |
| 8 | Search a nonsense term | `GET /api/search` | no match | "No represented records matched this keyword." | exactly that text, no substitute content | **PASS** |
| 9 | Open entity `Nikola Tesla` | `GET /api/entities/196` | represented detail | identity/mapping, events, claims sections | "Source identities and reconciliation (1)", "Events (2)", "Claims (2)" | **PASS** |
| 10 | Expand graph for that entity | `GET /api/graph` | projected edges | edges from persisted rows | 4 edges rendered — **2 of them self-loops** (`entity:196 —participatesIn→ entity:196`) | **FAIL (F-02)** |
| 11 | Open a claim and trace provenance | `GET /api/claims/{id}` + `/api/provenance/claims/{id}` | full chain | claim → evidence → citation → source record → dataset → source | complete six-step chain rendered (§9) | **PASS** |
| 12 | Trace provenance of a **derived** claim (`CLAIM_MT_ENOSH_YEAR_DERIVED`) | same | no source-backed chain | derivation shown; no invented citation | Derivation method/assumptions shown; provenance section rendered only `Claim: …` with **no** evidence or citation invented — but also no explicit "no source-backed chain" statement | **PASS with note (F-07)** |
| 13 | Open a **superseded** claim (`CLAIM_MT_ADAM_AGE_AT_SETH_DRAFT`) | `GET /api/claims/92` | status preserved | `SUPERSEDED` badge, evidence retained | rendered `SUPERSEDED` with its supporting evidence, not promoted | **PASS** |
| 14 | Search `Edison` (unresolved identity) | `GET /api/search` | source identity, not a person record | identity shown as source-scoped | `Source identity · phase37r-directory-edison-name · Edison` plus a citation describing "identity context unresolved"; clicking yields "No dedicated bounded detail endpoint exists for this record type." | **PASS** |
| 15 | Research: "Who participated in represented events?" (established) | `POST /api/research` | `ESTABLISHED` | Answer + "What Berean Establishes" + Sources | `CAPABILITY: ESTABLISHED`, 50 bounded results, sections as expected | **PASS** |
| 16 | Research: "Prove that alternating current is true" (truth request) | `POST /api/research` | `NOT_REPRESENTED` | no results, non-denial limitation | `CAPABILITY: NOT REPRESENTED`, 0 results, "Absence of representation is not a denial…" | **PASS** |
| 17 | Research: "What did the exhibits confirm about AC?" (confirmation request) | `POST /api/research` | `NOT_REPRESENTED` | no invented conclusion | `NOT REPRESENTED`, 0 results | **PASS** |
| 18 | Research: `ageAtFatherhoodYears` (mixed/unresolved corpus) | `POST /api/research` | `UNRESOLVED` | separate Establishes / Unresolved / Evidence sections | `CAPABILITY: UNRESOLVED`; 7 established, 1 unresolved, 6 evidence-relation results kept in a separate "Evidence" section | **PASS** |
| 19 | Research: "Which unicorn attended the exposition?" (not represented) | `POST /api/research` | `NOT_REPRESENTED` | non-denial text | `NOT REPRESENTED` with "Absence of representation is not a denial. Try keyword search…" | **PASS** |
| 20 | Research with empty scope | none (client blocks) | n/a | explicit prompt, disabled button | "No scope selected…" and the Research button disabled | **PASS** |
| 21 | Coverage dashboard / Genesis coverage / sources navigation | `/api/dashboard/quality`, `/api/genesis/coverage`, `/api/sources` | representation counts | structured payload | rendered; Genesis locators reported `populated:false, source_unavailable:true` rather than as absence of the text | **PASS** |
| 22 | Administrative flow through the UI | n/a | not exposed | no admin affordance | none present — read-only by design | **N/A (intentionally unsupported)** |
| 23 | XSS probe `<img src=x onerror=alert(1)>` as a search term | `GET /api/search` | no match | escaped text only | 0 injected nodes, container HTML was the escaped empty-state paragraph | **PASS** |

**21 PASS, 1 PASS-with-note, 1 FAIL (F-02), 1 intentionally unsupported.**

## 17. Explorer epistemic-safety review

| Conversion the UI must **not** make | Result |
|---|---|
| discovery → fact | Not possible; no discovery surface in the Explorer |
| candidate → claim | Not possible; no candidate surface |
| claim → truth | **Safe.** Claims are labelled by status/type; the standing banner states results are not truth declarations |
| co-participation → employment/membership | **Safe.** Event participation is rendered as "Claim-asserted participation" with role codes and the asserting claim; no relationship is synthesized |
| differing source description → contradiction | **Safe.** `EVIDENCE_CONTRADICTS`/`EVIDENCE_QUALIFIES` reflect stored `claim_evidence` relations only; "Related or competing claims" preserves stored relation types |
| source-backed → proven | **Safe.** Capability text explicitly says a represented claim is not automatically truth |
| `NO_MATCH` → false | **Safe in the Explorer** ("No represented records matched this keyword."); see F-01 for the API-side false `NO_MATCH` |
| `NOT_REPRESENTED` → false | **Safe.** Limitation text is displayed verbatim |
| unresolved identity → identified person | **Safe.** `Edison` surfaced as a *source identity*, not as a canonical person |
| proposed mapping → active identity | **Safe.** `Mapping status` is displayed as a field with justification and confidence |
| derived → directly attested | **Safe.** Derived claims render a Derivation section; no citation is invented (F-07 is a clarity note, not a conversion) |
| projection → new assertion | **Mostly safe**, except that F-02 renders self-referential edges that correspond to no proposition |

Provenance chain and `NOT_STORED_BY_POLICY` handling: §9.

## 18. Error and failure handling

| Condition | Observed | Assessment |
|---|---|---|
| Missing auth | `401 UNAUTHENTICATED` + `WWW-Authenticate: Bearer` | Correct |
| Invalid token | `401` with a distinct message, no enumeration | Correct |
| Insufficient role | `403 FORBIDDEN` naming the required minimum role | Correct |
| `400` validation | e.g. `limit must be between 1 and 100.`, `question is required…` | Useful, specific, no internals |
| `404` | Structured `NOT_FOUND` (V1) / legacy `{error}` (compatibility) | Correct |
| `409` stale version | `STALE_VERSION` after `If-Match` replay | Correct, no partial write |
| `409` idempotency conflict | `IDEMPOTENCY_CONFLICT` on key reuse with a different body | Correct |
| `409` job state | `INVALID_JOB_STATE` on illegal transition **and on unknown job ids** (deliberate non-enumeration, asserted in `tests/app/app.test.ts`) | Correct; the unknown-id nuance is tested but not stated in `API_WORKFLOWS.md` (F-09) |
| `422` epistemic validation | `DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION`, `DERIVATION_INPUT_REQUIRED`, `IDENTITY_EVIDENCE_SOURCE_MISMATCH`, `INTEGRITY_VIOLATION` | Correct |
| `500` | Reproduced against an unavailable database: `{"error":"internal_error","message":"The request could not be completed."}` with no stack trace, driver code, SQL, or table name | Correct (envelope documented) |
| `501` | `NOT_REPRESENTED` for unmatched V1 methods/paths and for unindexed search resources | Correct |
| `NO_MATCH` / `NOT_REPRESENTED` | Explicit non-denial limitation text | Correct except F-01 |
| Empty search / graph / provenance | Distinct explicit empty states in the UI | Correct (F-07 note for derived claims) |
| Queued / cancelled / failed jobs | Status returned and listed; retry/cancel gated by state | Correct |
| Silent failure → "no data" | **Not observed.** Every failure path renders an error state, never an empty success | Correct |

## 19. Browser and application results

- Application under test: `npx tsx src/server.ts` on port 3210, `DATABASE_URL` pointing at the
  validated PostgreSQL 16 database; administrative credentials supplied through
  `BEREAN_API_CREDENTIALS` with an `ADMINISTRATOR` role for the lifecycle probe.
- Browser: Chromium Headless Shell 131.0.6778.33 (Playwright build v1148) via Playwright 1.49.1
  installed under `/tmp/browsertest` (not committed, no repository dependency added).
- Two scripted sessions were run (workflow/prompt coverage and epistemic-safety/security coverage);
  results are recorded in §15–§18. Zero console errors, zero page errors.
- Notable secondary evidence: Playwright's `waitForFunction` was **blocked by the application's own CSP**
  (`Refused to evaluate a string as JavaScript … script-src 'self'`), an independent confirmation that
  the deployed CSP is effective.

## 20. Contract-test assessment

There is currently **no automated Explorer↔API contract test**: `src/public/app.js` has no unit tests,
is not covered by `npm run lint`, and no browser or HTTP-level test asserts that the endpoints the
client calls still return the fields it reads.

Smallest useful strategy (recommended, **not** implemented here, and deliberately not a new framework):

1. Extract the ten Explorer endpoint paths from `src/public/app.js` with a regular expression in a
   Vitest test and assert each one resolves to an OpenAPI-documented path — this reuses
   `tests/app/openapi-coverage.test.ts` machinery and costs one small file.
2. Add supertest assertions for the *field names* the client depends on (`datasets[].dataset_id`,
   `results[].classification`, `traversal[].source_name`, `edges[].relation`, …) so a rename breaks a
   test rather than the UI.
3. Only if a UI regression is later observed, consider adding a browser runner. Adding Playwright to
   `package.json` today would cost a ~100 MB browser download in CI for coverage that steps 1–2 largely
   provide.

## 21. Findings

Each finding: ID · area · classification · evidence · current behavior · expected behavior · impact ·
risk · schema/API/Explorer/documentation/testing impact · recommended next phase.

### F-01 — Resource-filtered search applies `limit` before the filter
- **Area:** API read surface (`src/api/v1.ts` `router.get('/search/:resource?')`).
- **Classification:** SIGNIFICANT GAP / IMPLEMENTATION BUG.
- **Resolution note (2026-08-21 / R2-13):** superseded by a repository-level typed search path used
  by V1 resource-filtered keyword search. The resource filter is now applied before `limit`, with
  regression coverage for `GET /api/v1/search/entities?q=adam&limit=1` and deterministic key ordering.
- **Evidence:** `GET /api/v1/search/entities?q=Tesla&limit=5` → `classification: "NO_MATCH"`, 0
  results; the same query with `limit=25` or `limit=100` → `MATCHED`, entity `phase37r_nikola_tesla`.
  Root cause: `repository.search(query, requestedLimit)` returns the *unfiltered* top-N, and
  `results.filter(...)` runs afterwards.
- **Current behavior:** a low `limit` can report `NO_MATCH` although matching persisted records exist.
- **Expected behavior:** `NO_MATCH` reports that no persisted record matched the term; `limit` bounds
  the returned rows, not the search.
- **Impact / risk:** `NO_MATCH` is epistemically load-bearing (`NO_MATCH ≠ FALSE` is a documented
  boundary). A false `NO_MATCH` invites exactly the inference the model forbids. Risk grows as the
  corpus grows, because more unfiltered rows crowd out the filtered type.
- **Schema impact:** none. **API impact:** response classification only, no contract change needed.
  **Explorer impact:** none today (the Explorer uses the unfiltered compatibility route).
  **Documentation impact:** the developer-guide example was not reproducible (F-04, corrected).
  **Testing impact:** the existing filter test uses `limit=100` with exact keys, so it cannot catch this.
- **Recommended next phase:** apply the resource filter inside the search query (or over-fetch then
  filter then truncate), and add a regression test asserting that a filtered search with a small limit
  does not report `NO_MATCH` when a matching record exists. Not implemented here: it is a runtime
  change outside audit scope.

### F-02 — Entity graph neighborhood emits self-referential edges
- **Area:** `src/repository.ts` `getGraphNeighborhood`, entity branch (lines ~1523–1531).
- **Classification:** IMPLEMENTATION BUG (Explorer-visible).
- **Evidence:** `GET /api/graph?nodeType=entity&nodeId=1` returned 13 edges, **8** of them self-loops
  (`entity:1 —fatherOf→ entity:1`, `entity:1 —ageAtFatherhoodYears→ entity:1`); the browser session
  rendered `entity:196 —participatesIn→ entity:196` for Nikola Tesla. Root cause: `row.subject_entity_id
  !== nodeId` compares a PostgreSQL `bigint` (returned by `pg` as a **string**) with a number, so the
  self-exclusion guard never fires and the centre node is re-emitted as a neighbour.
- **Current behavior:** the projected neighborhood contains edges no proposition asserts, and the
  Explorer renders them verbatim as `X —fatherOf→ X`.
- **Expected behavior:** an edge exists only where a persisted proposition relates the centre entity to
  a *different* node; subject-only propositions contribute no entity-to-entity edge.
- **Impact / risk:** a graph projection displays a relationship that is not represented, which is a
  projection-versus-assertion boundary problem, not merely cosmetic. No persisted state is affected.
- **Schema impact:** none. **API impact:** `/api/graph` and `/api/v1/graph/entity/{id}` payloads.
  **Explorer impact:** misleading edges in the relationship list. **Documentation impact:** none (docs
  describe the intended behavior correctly). **Testing impact:** no test asserts edge content (F-03).
- **Recommended next phase:** compare numerically (`Number(row.subject_entity_id) !== nodeId`, likewise
  for the object branch) and add a graph-content regression test. Not implemented here: runtime change.

### F-03 — Graph edge content is untested
- **Area:** `tests/app/app.test.ts`. **Classification:** TEST COVERAGE GAP.
- **Evidence:** the only graph assertion is `GET /api/graph?nodeType=dataset` → `400`; no test inspects
  nodes or edges, which is why F-02 survived.
- **Impact:** graph projection defects are invisible to CI. **Recommended next phase:** assert node and
  edge shape for one fixture entity and one fixture claim, including the absence of self-loops.

### F-04 — Non-reproducible search example in the developer guide
- **Area:** `docs/api/API_DEVELOPER_GUIDE.md`. **Classification:** DOCUMENTATION DRIFT.
- **Resolution note (2026-08-21 / R2-13):** the developer guide now documents the corrected
  filter-before-limit behavior and uses a reproducible `limit=1` filtered-search example.
- **Evidence:** the documented example `GET /api/v1/search/entities?q=adam&limit=3` now returns
  `NO_MATCH` against the full corpus (consequence of F-01); the same call with `limit=100` returns the
  documented `adam` entity.
- **Action taken in this pass:** the example was corrected to a reproducible call and a note describing
  the actual filter-after-limit behavior was added, cross-referencing F-01. No claim about intended
  behavior was weakened, and the underlying defect was recorded rather than hidden.

### F-05 — V1 search `limit` documented as 1..100 but effectively capped at 50
- **Classification:** MINOR GAP (documentation precision).
- **Evidence:** `GET /api/v1/search?q=a&limit=100` returns 50 rows; `boundedLimit(limit, 20, 50)` in
  `src/repository.ts` caps the repository query at 50 while `src/api/v1.ts` accepts up to 100.
- **Impact:** a client requesting 100 silently receives at most 50. **Recommended next phase:** state
  the effective cap in `API_DEVELOPER_GUIDE.md` and the OpenAPI `limit` description, or align the cap.

### F-06 — Server read capabilities unused by the Explorer
- **Classification:** MINOR GAP (product surface, intentional adapter boundary).
- **Evidence:** the Explorer never calls `/api/exploration/timeline`, `/api/provenance/explain`,
  `/api/derivations/check-eligibility`, or any `/api/v1` route; `source_identity`, `dataset`,
  `citation`, `evidence`, and `source_record` search hits therefore fall back to
  "No dedicated bounded detail endpoint exists for this record type." even though
  `GET /api/v1/{resource}/{id}` can read most of them.
- **Impact:** a user cannot reach the entity timeline or proposition-level provenance explanation from
  the UI. Nothing is misrepresented. **Recommended next phase:** if a timeline/identity view is wanted,
  add it against the existing documented endpoints; no new API surface is required.

### F-07 — Derived-claim provenance renders a bare claim line
- **Classification:** MINOR GAP (Explorer presentation).
- **Evidence:** for `CLAIM_MT_ENOSH_YEAR_DERIVED` the provenance section rendered only
  `Claim: CLAIM_MT_ENOSH_YEAR_DERIVED`; the "no source-backed provenance chain is represented" message
  only appears when `traversal` is empty, and here the traversal has one row with null evidence fields.
- **Impact:** no false claim is made, but the absence of a chain is implicit rather than stated.
  **Recommended next phase:** treat a traversal row with no evidence as the explicit derived/no-chain
  state in `renderProvenance`.

### F-08 — Research result truncation is not surfaced
- **Classification:** MINOR GAP. `POST /api/research` bounds results at 50 rows; the Explorer reported
  "Established. 50 bounded results." without stating that more may exist. Documented server-side in
  `API_DEVELOPER_GUIDE.md` ("Results are limited to 50 rows"). **Recommended next phase:** state the
  bound in the UI.

### F-09 — Unknown job id returns `409`, documented only implicitly
- **Classification:** MINOR GAP (documentation). `POST /api/v1/jobs/2147483000/cancel` → `409
  INVALID_JOB_STATE`. This is deliberate non-enumeration and is asserted in `tests/app/app.test.ts`, but
  `API_WORKFLOWS.md` describes `409` only as an illegal transition. **Recommended next phase:** one
  clarifying sentence in the workflow error table.

### F-10 — `GET /api/v1/propositions/{id}` not implemented while `propositions` is a search filter
- **Classification:** MINOR GAP (API symmetry). `/api/v1/search/propositions` is supported, but the V1
  resource set excludes `propositions`, so `GET /api/v1/propositions/1` returns the generic
  `404 NOT_FOUND` ("Resource was not found.") rather than distinguishing "not part of the V1 read
  surface". The compatibility route `/api/propositions/{id}` is the documented reader.
  **Recommended next phase:** either add the V1 reader or make the 404 message distinguish the case, as
  `identity-mappings` already does with its `501` pointer.

### F-11 — 12 documented routes have no behavior-level test
- **Classification:** TEST COVERAGE GAP (previously reported and still accurate). Enumerated in
  `docs/api/OPENAPI_GAP_REPORT.md`. This audit manually exercised most of them successfully; manual
  exercise does not close the gap. **Recommended next phase:** add thin supertest assertions,
  prioritising `POST /api/v1/ingestion-jobs`, `POST /api/v1/export-jobs`, and
  `POST /api/v1/jobs/{id}/retry` because they write.

### F-12 — Explorer client is outside lint and type checking
- **Classification:** MINOR GAP. `npm run lint` covers `src/**/*.ts` and `tests/app/**/*.ts`; `npm run
  typecheck` covers TypeScript only. `src/public/app.js` (630 lines) is checked by neither.
  **Recommended next phase:** add `src/public/*.js` to the lint target if a JavaScript ESLint
  configuration can be applied without changing runtime behavior.

### F-13 — No Explorer↔API contract test
- **Classification:** EXPLORER/API CONTRACT GAP. See §20 for the smallest useful strategy.

### F-14 — Job execution is queue-only
- **Classification:** INTENTIONALLY UNSUPPORTED (documented). Ingestion, validation, and export jobs
  persist queue rows; execution happens through `npm run ingest` and the validation scripts. This is
  stated in `README.md`, `API_LIMITATIONS.md`, and `API_CAPABILITY_MATRIX.md`. No action.

### Items assessed as COMPLETE
Authentication and role enforcement; optimistic concurrency; idempotency; audit append-only behavior;
transaction/rollback boundaries; epistemic 422 validation; workflow/knowledge separation; provenance
traversal; `NOT_STORED_BY_POLICY` reporting; OpenAPI route-surface coverage and its enforcement;
documentation authority model, canonical API location, historical preservation, and link integrity;
Explorer read-only guarantee, XSS/CSP posture, and error states.

### Items assessed as SHOULD NOT EXIST
**None.** No route, table, document, or UI affordance was found that contradicts the charter. In
particular there is no truth-adjudication endpoint, no external-retrieval endpoint, no arbitrary SQL
execution, no automatic candidate/evidence/claim/identity promotion, and no second authoritative store.

## 22. Overall coverage assessment

| Area | Behavior-tested | Code-traced only | Manually exercised in this audit |
|---|---|---|---|
| Read API | yes (extensive) | `/api/v1/schema`, `/api/v1/research/capabilities` | yes |
| Auth / authz | yes | — | yes |
| Idempotency | yes | export/ingestion job keys | yes (discovery + validation) |
| Concurrency | yes | — | yes (If-Match, mapping state, job state) |
| Transactions / rollback | yes (count snapshots before/after failures) | — | indirectly |
| Audit | yes | — | yes |
| Jobs | partly (cancel tested, retry not) | retry | yes (both) |
| Discovery / candidate review | yes | — | yes |
| Identity | yes | — | listing only |
| Derivation | yes | — | yes (eligibility 404 path) |
| Ingestion | yes (35 tests on the pipeline) | HTTP queue route | queue route not exercised (writes) |
| Provenance | yes | — | yes |
| Epistemic boundaries | yes | — | yes |
| OpenAPI | yes (bidirectional) | — | yes |
| Documentation | yes (link integrity, canonical paths) | — | yes |
| **Explorer** | **no automated tests** | client fully code-traced | **yes — two headless-browser sessions** |
| Integration / user prompts | no automated tests | — | yes (23-row prompt matrix) |

## 23. Files changed in this audit

| File | Change | Classification |
|---|---|---|
| `docs/07-review/FINAL_PLATFORM_ARCHITECTURE_AUDIT.md` | created (this report) | documentation (review/audit record) |
| `docs/README.md` | added this report to the REVIEW / AUDIT section | documentation (index) |
| `README.md` | added a link to this report | documentation (navigation) |
| `docs/api/API_DEVELOPER_GUIDE.md` | corrected the non-reproducible V1 filtered-search example and documented the actual filter-after-limit behavior (F-04/F-01) | documentation (accuracy correction) |
| `tests/app/documentation-links.test.ts` | registered this report as a canonical entry point and asserted it is indexed from `docs/README.md` | test (documentation integrity) |

No implementation, schema, fixture, validation, runtime, or CI file was modified. No file was deleted,
moved, or renumbered. No historical record was rewritten.

## 24. Commands executed and results

All commands were run from the repository root on 2026-08-14 against a local PostgreSQL 16 instance
with `DATABASE_URL` set.

| # | Command | Exit code | Result | Observations |
|---|---|---|---|---|
| 1 | `npm ci` | 0 | PASS | 0 vulnerabilities reported |
| 2 | `npm run typecheck` | 0 | PASS | `tsc --noEmit`, no diagnostics |
| 3 | `npm run lint` | 0 | PASS | ESLint over `src/**/*.ts` and `tests/app/**/*.ts` (see F-12) |
| 4 | `npm run build` | 0 | PASS | `tsc -p tsconfig.json` |
| 5 | `npm test` | 0 | PASS | Vitest **112 tests / 4 files** (pre-change baseline) — `app.test.ts` 61, `phase28-ingestion.test.ts` 35, `openapi-coverage.test.ts` 6, `documentation-links.test.ts` 10 |
| 6 | `bash scripts/validation/run-postgres-validation.sh` | 0 | PASS | Full Phase 6–37R replay; all negative/blocking cases blocked as expected ("All validation self-test cases passed."). Run after dropping the `phase28_ingestion` and `public` schemas, which the suites require |
| 7 | `npx tsx src/server.ts` + ~45 `curl` probes (read, V1, administration lifecycle, error paths) | n/a | PASS with findings | Evidence for §6–§8, §18; F-01 discovered here |
| 8 | Headless Chromium sessions (Playwright 1.49.1, browsers under `/tmp`) | 0 | PASS with findings | Evidence for §15–§17; F-02 confirmed in the UI; 0 console/page errors |
| 9 | 500-path probe with an unavailable database | n/a | PASS | Generic `internal_error` envelope, no internals disclosed |
| 10 | `npm run typecheck && npm run lint && npm test` (re-run after documentation/test changes) | 0 | PASS | **113 tests / 4 files**; `documentation-links.test.ts` now 11 tests (one added for this report) |
| 11 | `bash scripts/validation/run-postgres-validation.sh` (re-run after changes) | 0 | PASS | Unchanged: "All validation self-test cases passed." |

Dedicated Explorer/frontend tests, Playwright/Cypress suites, and API contract tests **do not exist in
the repository** and therefore could not be run; the browser testing above was performed with tooling
installed outside the repository (§19) and added no repository dependency. No result in this report was
fabricated; every row above corresponds to a command that was actually executed.

CI status: the `PostgreSQL reference validation` workflow is green on `main` (run 337). The run for this
pull request is in the `action_required` state, which is the standard "workflow awaiting maintainer
approval" state for an agent-authored branch, not a failure. The same script was executed locally
(command 6) with exit code 0.

## 25. Final classification

**PLATFORM ARCHITECTURALLY SOUND — MINOR GAPS**

Justification, explicitly *not* based on the passing test suite alone:

- Every authoritative epistemic boundary was exercised over HTTP and through a real browser session and
  held (§10, §17). No workflow record, discovery result, candidate, projection, or derived claim was
  converted into evidence, a claim, an identity, or truth.
- The administrative lifecycle was executed end to end with authentication, authorization, idempotency,
  optimistic concurrency, transactional writes, and append-only audit all behaving as documented (§7).
- The Explorer uses only documented APIs, performs no database access, duplicates no server logic,
  exposes no unsupported capability, handles empty/error states honestly, and is free of XSS and
  credential handling (§13, §14, §16, §17).
- Two genuine read-projection defects exist (F-01, F-02). Both are visible to users, both touch the
  presentation of epistemic status, and neither is caught by the current suite — which is precisely why
  a passing suite is insufficient evidence. Neither is architectural: no schema, contract, authority
  model, or workflow boundary needs to change to fix them.
- The remaining findings are minor documentation, coverage, and product-surface gaps.

Nothing found justifies `ARCHITECTURAL DEFECTS FOUND`; the presence of F-01 and F-02 prevents
`PLATFORM ARCHITECTURALLY COMPLETE`; their limited blast radius and the absence of any boundary
violation keep this below `SIGNIFICANT GAPS`.

## 26. Next steps (recommended, not implemented here)

1. F-01 is superseded by R2-13 (filter before limit plus regression coverage); keep monitoring V1 search coverage as the corpus grows.
2. Fix F-02 (numeric comparison in the entity graph) and add the graph-content test (F-03).
3. Add the thin Explorer↔API contract assertions described in §20 (F-13).
4. Close the enumerated behavior-test gaps for the writing routes (F-11).
5. Documentation precision: effective search cap (F-05), unknown-job `409` (F-09), V1 proposition read
   asymmetry (F-10).
6. Optional Explorer improvements: explicit derived/no-chain provenance state (F-07), result-truncation
   notice (F-08), timeline/identity views over existing endpoints (F-06), lint coverage for the client
   (F-12).

## 27. Related records

- [`DOCUMENTATION_GOVERNANCE_AUDIT.md`](./DOCUMENTATION_GOVERNANCE_AUDIT.md) — documentation governance
  and authority audit (immediately preceding pass; preserved unchanged).
- [`REPOSITORY_CONSOLIDATION_REPORT.md`](./REPOSITORY_CONSOLIDATION_REPORT.md) — repository-wide
  structural consolidation audit (preserved unchanged).
- [`REMEDIATION-REPORT.md`](./REMEDIATION-REPORT.md), [`WEB_APP_MVP_REPORT.md`](./WEB_APP_MVP_REPORT.md),
  [`COPILOT_PEER_REVIEW_PROMPT.md`](./COPILOT_PEER_REVIEW_PROMPT.md) — earlier review records, preserved.
- [`../api/OPENAPI_GAP_REPORT.md`](../api/OPENAPI_GAP_REPORT.md) and
  [`../api/VERIFICATION_REPORT.md`](../api/VERIFICATION_REPORT.md) — API coverage and verification
  evidence relied upon and independently re-verified by this audit.

## 28. Subsequent verification (appended 2026-08-14; findings above unchanged)

This section is an append-only pointer; nothing above it was rewritten. The Explorer/API findings of
this audit were narrowed, re-verified, and (where fixed) marked in
[`EXPLORER_API_INTEGRATION_AUDIT.md`](./EXPLORER_API_INTEGRATION_AUDIT.md), with live evidence in
[`EXPLORER_TEST_REPORT.md`](./EXPLORER_TEST_REPORT.md) §9 and the canonical endpoint matrix in
[`../api/API_EXPLORER_INTEGRATION_MATRIX.md`](../api/API_EXPLORER_INTEGRATION_MATRIX.md).

- **F-02 / F-03** (self-referential entity graph edges, untested edge content) — fixed as F-EXP-01
  with a regression test; re-confirmed live (2 `PARTICIPANT` edges, 0 self-loops).
- **F-13** (no Explorer↔API contract test) — closed as F-EXP-02 by
  `tests/app/explorer-contract.test.ts`.
- **New, found after this audit:** unmatched `/api` paths returned `200 text/html` (the Explorer
  shell) instead of a JSON 404 — fixed as F-EXP-03 with a regression test and OpenAPI/guide updates.
- **F-01, F-04 through F-12, F-14** remain open exactly as recorded in §21; none was silently closed.
