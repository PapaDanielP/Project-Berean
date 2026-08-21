# Berean Validation

## Core invariants

### Claim/Evidence

Every source-backed claim must have at least one ClaimEvidence association.

### Evidence provenance

Every evidence record must have identifiable provenance to a SourceRecord or an explicitly documented exception.

### Source provenance

Every SourceRecord must resolve to a Dataset and Source.

### Entity reconciliation

Source identities must not be silently substituted for canonical entities.

### No implicit truth

A relationship or claim record must not be interpreted as universally true merely because it exists.

## Validation categories

- Structural integrity
- Referential integrity
- Provenance integrity
- Semantic integrity
- Reconciliation integrity
- Duplicate detection
- Conflict detection
- Regression testing

## Executable reference validation

With PostgreSQL 16 and an empty disposable database, set `DATABASE_URL` and run:

```sh
scripts/validation/run-postgres-validation.sh
```

The script loads the schema and deterministic fixture, executes negative constraint cases, and then runs `scripts/validation/validate.sql`. The validation emits **blocking** exceptions for unsupported non-derived claims, broken provenance, duplicate active mappings, invalid confidence, uncontrolled relations, missing required citations, invalid proposition cardinality, and incomplete derivations. It emits **warnings** for reviewable quality conditions and exits nonzero only for SQL/blocking failures.

The fixture demonstrates shared evidence, multiple evidence for a claim, contrary evidence, competing claims, source-identity reconciliation, asserted event participation, and a derived chronology claim. It is transactional and resets reference-model data; use an isolated test database.

`tests/validation/genesis-1-1-5-slice.sql` runs after the Genesis fixture and checks the conservative Genesis 1:1–5 slice specifically. It verifies five verse source-record boundaries, citation-compatible structural records with no stored source text, evidence-to-source provenance, claim-to-evidence provenance, multiple records attached to Genesis 1:1, and direct source claims only.

`tests/validation/phase28-ingestion-validation.sql` runs after the Phase 28 automated Tier-1 ingestion step and checks that every ingested claim is a direct source claim with a complete provenance chain, that deferred and excluded candidates stayed outside the graph, that locator-only source storage held, that ingested source-identity mappings are `ACTIVE`, justified, and evidence-backed, and that ingestion produced no duplicate assertion. The ingestion step itself requires the Node toolchain and is skipped when dependencies are absent.

## Worker-executed validation runs

`POST /api/v1/validation-runs` queues a `VALIDATION` job. The separate SYSTEM worker process
(`npm run worker`) claims the job under a lease token and executes the read-only structural
validation executor in `src/worker/validation-executor.ts`. The executor issues parameterized
PostgreSQL queries only: it never shells out to a script, never runs SQL taken from stored request
data, and never writes to authoritative knowledge tables. Results are appended to the immutable
`validation_result` table and are readable at `GET /api/v1/admin/validation-results`.

A `PASS` is an operational reproducibility record about structure. It is never historical truth,
scholarly adjudication, contradiction resolution, or claim validation in the epistemic sense.

| Requested type | Behavior |
|---|---|
| `SCHEMA` | Confirms the baseline core/administration tables and the `claim_rendering` and `event_participation` views resolve in the current search path. |
| `PROVENANCE` | Finds direct/interpretive claims with no cited `SOURCE_OBSERVATION` chain, and derived claims with no derivation or derivation input. Nothing is created or repaired. |
| `READ_ONLY` | Compares a before/after content snapshot of the authoritative knowledge and registry tables across the execution window. Workflow, result, and audit tables are excluded because the worker appends to them. |
| `NEGATIVE_SEMANTIC` | Structural boundary check that no forbidden predicate, undeclared job type, or unjustified active reconciliation is persisted. |
| `REGISTRY`, `IDENTITY`, `CLAIM`, `EVIDENCE`, `DERIVATION`, `CORPUS`, `REPLAY` | Accepted by the API but not implemented by this executor; each records one `NOT_APPLICABLE` result, which is neither a pass nor a failure. |

Stable result codes:

| Code | Status | Meaning |
|---|---|---|
| `SCHEMA_BASELINE_PRESENT` | `PASS` | Every required table and structural view is present. |
| `SCHEMA_MISSING_TABLE` / `SCHEMA_MISSING_VIEW` | `FAIL` | A required structure does not resolve. |
| `SCHEMA_UNEXPECTED_RELATION_KIND` | `FAIL` | A required structure exists with the wrong relation kind. |
| `PROVENANCE_CHAIN_STRUCTURALLY_COMPLETE` | `PASS` | No structural provenance violation was found. |
| `PROVENANCE_CLAIM_MISSING_CITED_SOURCE_OBSERVATION` | `FAIL` | A direct/interpretive claim cites no `SOURCE_OBSERVATION`. |
| `PROVENANCE_DERIVED_CLAIM_MISSING_DERIVATION` | `FAIL` | A derived claim records no derivation. |
| `PROVENANCE_DERIVED_CLAIM_MISSING_DERIVATION_INPUT` | `FAIL` | A derived claim's derivation declares no input. |
| `PROVENANCE_VIOLATIONS_TRUNCATED` / `PROVENANCE_DERIVED_VIOLATIONS_TRUNCATED` | `WARNING` | More violations exist than the bounded reporting limit reports. |
| `READ_ONLY_KNOWLEDGE_TABLES_UNCHANGED` | `PASS` | No authoritative knowledge or registry table changed during execution. |
| `READ_ONLY_KNOWLEDGE_TABLE_MUTATED` | `FAIL` | A knowledge table changed during execution and no other actor recorded audited activity. |
| `READ_ONLY_CONCURRENT_EXTERNAL_MUTATION` | `WARNING` | A knowledge table changed while another actor recorded audited activity, so the change is not attributable to this executor. |
| `READ_ONLY_SNAPSHOT_INCOMPLETE` | `FAIL` | A knowledge table could not be compared across the execution window. |
| `NEGATIVE_SEMANTIC_FORBIDDEN_CAPABILITIES_ABSENT` | `PASS` | No forbidden automatic capability is represented. |
| `NEGATIVE_SEMANTIC_FORBIDDEN_PREDICATE_REGISTERED` | `FAIL` | A registered predicate expresses automatic truth/proof/adjudication/inference semantics. |
| `NEGATIVE_SEMANTIC_UNDECLARED_JOB_TYPE` | `FAIL` | Workflow state persists a job type outside the declared closed set. |
| `NEGATIVE_SEMANTIC_UNJUSTIFIED_ACTIVE_IDENTITY_MAPPING` | `FAIL` | An active reconciliation records no justification. |
| `VALIDATION_TYPE_NOT_IMPLEMENTED` | `NOT_APPLICABLE` | The requested type is accepted but unimplemented. |

Job semantics:

- cancellation is observed before each validation type and before finalization; a cancelled run
  persists no further results, finalizes as `CANCELLED`, and leaves `validation_run.completed_at`
  `NULL` because the run did not complete;
- a completed run sets `validation_run.completed_at` in the same transaction that finalizes the job
  as `COMPLETED` and appends the worker audit event;
- an unexpected executor failure finalizes the job `FAILED` with a stable worker error code, and any
  already-persisted results remain immutable;
- because `validation_result` rows are immutable and a `validation_run` belongs to exactly one job,
  a retried or lease-recovered job whose run already holds results is refused with
  `VALIDATION_RUN_ALREADY_EXECUTED` rather than appending a second, ambiguous result set. Queue a new
  validation run instead;
- each `READ_ONLY` snapshot is taken inside a read-only repeatable-read transaction so it is
  internally consistent, and a detected change is only reported as `FAIL` when no other actor
  recorded audited activity during the execution window.

## Related validation records

- Current governance verification: [`../07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md`](../07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md)
- API verification evidence: [`../api/VERIFICATION_REPORT.md`](../api/VERIFICATION_REPORT.md)
- Legacy Phase 6–32 validation history: [`../04-data/README.md`](../04-data/README.md)
- Later phase validation records: [`../phases/README.md`](../phases/README.md)

## Genesis regression

Genesis 1–11 should include tests for:

- parent/child relationships
- births and deaths
- events
- places
- chronology
- multiple evidence records
- derived assertions
- conflicting assertions
- source identity reconciliation
