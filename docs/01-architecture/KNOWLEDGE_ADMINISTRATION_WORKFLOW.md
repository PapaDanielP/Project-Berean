# Knowledge Administration and Research Workflow Architecture

## Decision

The administration workflow is a durable, audited coordination layer around the
existing Berean model. It is not another knowledge graph. `source`, `dataset`,
`source_record`, `citation`, `evidence`, `proposition`, `claim`,
`entity_source_mapping`, and `derivation` remain authoritative. Workflow rows
may reference their identifiers, but never copy their semantic content as a
second authority. `event_participation` remains a projection.

This decision follows the charter, information schema, ADR-0003, the Phase
33–37 independent population/query pattern, the Phase 37R candidate/source
review CSVs, and the existing Explorer and ingestion pipeline. The CSVs remain
reproducibility fixtures; new administrative decisions can now be represented
as normalized records.

## Persistence assessment

| Requested concept | Decision and reason |
|---|---|
| **Corpus** | First-class `corpus` plus `corpus_dataset`. A bounded, owned, archivable scope has identity and lifecycle independent of any one dataset. Archival never deletes knowledge. |
| **ResearchTopic** | First-class `research_topic`. A question and its declared boundary must survive discovery, gap analysis, validation, and revision. It is not a Claim. |
| **DiscoveryRequest** | First-class `discovery_request`, linked to an asynchronous job. Reproducibility requires the submitted query, request kind, requested candidate kinds, and bounded scope. |
| **DiscoveryCandidate** | First-class `discovery_candidate`. Candidates are neither Evidence nor Claims and need stable review/audit identity, representation status, locator, and obstacle classification. |
| **CandidateReview** | First-class, one-current-decision `candidate_review`, with reviewer and rationale. Review changes candidate workflow state but never promotes knowledge automatically. |
| **IngestionJob** | First-class specialization of `asynchronous_job`. Transaction and partial-failure policy, source/candidate context, idempotency, results, cancellation, and replay cannot be reconstructed safely from logs. |
| **ValidationRun** | First-class specialization with append-only `validation_result`. Validation type, subject, result, and execution identity are reproducibility records, not knowledge. |
| **AuditEvent** | First-class append-only table. Every implemented administrative mutation writes one event in the same transaction. Audit explains administration; it is not evidence or a claim store. |
| **User/Actor** | First-class `workflow_actor`, populated only after successful bearer authentication. Stable actor identity is required by ownership, review, jobs, and audit. Credentials remain outside PostgreSQL. |
| **WorkflowState** | **No separate table.** Controlled `CHECK`-constrained status columns on the owned aggregate are normalized and auditable. A generic state JSON/document would weaken integrity. |
| **ExportJob** | First-class specialization of `asynchronous_job`. Corpus, format, raw-content policy, reproducibility note, and manifest hash must survive execution and license review. |

No table stores arbitrary request JSON. `requested_types` and
`validation_types` are bounded controlled arrays because they are multi-valued
selections from closed vocabularies, not opaque payloads.

## Separation and lifecycle

```text
ResearchTopic → Corpus → DiscoveryRequest → DiscoveryCandidate → CandidateReview
                                                        │
                                                        └─ not Evidence

reviewed source locator → Source → Dataset → SourceRecord → Citation
                                                   │
                                                   └→ Evidence
                                                        │
registered Proposition ← Claim ← typed ClaimEvidence ───┘
```

The API does not fetch arbitrary URLs, execute SQL, read files, mutate
registries, confirm truth, or construct arbitrary graph edges. Discovery stores
locator metadata only. Unsupported proposed relationship semantics are recorded
as `NOT_REPRESENTED` with `REGISTRY_EXPRESSIVENESS`; they are not false.

`SOURCE_OBSERVATION` and `ANALYTICAL_OBSERVATION` remain controlled evidence
types. Claim authoring requires cited source observations for non-derived
claims. Creating analysis evidence creates no claim. Derivations require
explicit claim/evidence inputs and create no claim automatically. A derived
claim remains `DERIVED_FROM_PERSISTED_GRAPH`, never `DIRECTLY_SUPPORTED`.

Identity mappings start `PROPOSED` with evidence, confidence, and justification.
Only a reviewer may transition a proposal to `ACTIVE` or `REJECTED`; review is
audited. `PROPOSED` is never interpreted as `ACTIVE`.

## Authorization and integrity

Mutations use SHA-256-hashed opaque bearer credentials configured outside the
database. Roles are ordered `READER`, `RESEARCHER`, `CONTENT_EDITOR`,
`REVIEWER`, `ADMINISTRATOR`, `SYSTEM`; every route enforces a minimum role
server-side. When credentials are absent, administration returns
`AUTH_NOT_CONFIGURED`, rather than trusting identity headers.

PostgreSQL transactions couple each mutation with audit. Stable unique keys and
payload-bound job idempotency prevent duplicate or ambiguous replay. Reusing a
key with a different request returns `IDEMPOTENCY_CONFLICT`. Corpus updates
require `If-Match` and reject stale versions. SQL is parameterized; body,
string, array, identifier,
and result bounds are enforced. Errors do not disclose SQL. Validation and
audit rows reject update/delete at the database layer.

External acquisition is deliberately out of process. A future retriever must
implement DNS/IP revalidation, redirect limits, private/link-local address
denial, scheme and port allowlists, response/time limits, and license policy
before it may write a SourceRecord. Until then there is no SSRF surface.

## Limitation classification

| Limitation | Classification | Evidence / behavior |
|---|---|---|
| Natural-language matching is a bounded registered-predicate search, not general interpretation. | `QUERY` | `BereanRepository.research`; unmatched semantics return `NOT_REPRESENTED`. |
| Reviewed candidates and source locators still require an operator to enter canonical records/evidence. | `DATA_ENTRY` | Jobs are controlled plans; no candidate auto-promotion exists. |
| A requested relationship without a predicate cannot become a Proposition. | `REGISTRY_EXPRESSIVENESS` | Candidate insertion records `NOT_REPRESENTED`; registry has read-only APIs. |
| A corpus can include only explicitly attached persisted datasets. | `DOMAIN_SCOPING_LIMITATION` | `corpus_dataset` is the bounded membership relation. |
| The durable worker does not execute ingestion or discovery jobs, and export is limited to bounded local JSONL without raw content. | `ARCHITECTURAL_DEFICIENCY` | `npm run worker` provides SYSTEM actor leasing, heartbeat, recovery, cooperative cancellation, read-only structural validation, and configured-local-root deterministic export; ingestion/discovery and broader export shapes remain unavailable. |

These limitations are explicit API results or documented deployment boundaries;
none are silently converted to falsity, evidence, claims, or truth.
