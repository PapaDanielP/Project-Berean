# Project Berean Explorer

The Explorer is a read-only Express application over the reference PostgreSQL model. It is not a
second knowledge store: all inventory, scope, search, claims, graph edges, and provenance are read
from the existing Berean tables and projections.

## Query flow

`POST /api/research` accepts a natural-language question (1–1000 characters) and up to 100 optional,
positive persisted dataset identifiers in `datasetIds`. Omitting `datasetIds`, or sending an empty
array, means all persisted datasets; a non-empty array means exactly those datasets. The client does
not submit a request when its selection is empty. Duplicate identifiers are removed by the adapter.
The server creates a transient, inspectable plan, checks the registered predicate vocabulary, executes
a bounded Berean-only retrieval, and returns a capability status and source/dataset context. Query
plans and results are never persisted. User input is length-checked and all database values are bound
parameters.

`GET /api/research/scope` dynamically lists sources and datasets with counts. Berean has no Domain
table, so the UI deliberately calls these persisted scope units rather than manufacturing domains.
Selecting a scope only constrains the returned claim evidence; it neither reconciles identities nor
changes authoritative records.

The response contains `question`, `interpretation`, `capability`, `plan`, bounded `results`, and an
optional `limitation`. The plan exposes selected dataset identifiers, registered candidate predicates,
the traversal shape, output constraints, and the full-provenance requirement. The adapter uses these
capability values:

- `ESTABLISHED`: represented direct claims (not declarations of truth);
- `DERIVED`: derived claims backed by persisted graph/derivation structure;
- `SCHOLARLY_CANDIDATE`: represented interpretive claims without candidate promotion;
- `UNRESOLVED`: represented claims whose stored status remains under review;
- `NOT_REPRESENTED`: no registered predicate/capability can answer the request; and
- `NO_MATCH`: a supported retrieval found no claims in the selected scope.

Result classifications remain more specific: `DIRECTLY_SUPPORTED`,
`DERIVED_FROM_PERSISTED_GRAPH`, `SCHOLARLY_CANDIDATE`, and `UNRESOLVED`. Requests to establish truth
or proof, and questions with no matching registered predicate, return `NOT_REPRESENTED` rather than an
invented answer. Existing claim and provenance endpoints remain the authoritative path for complete
Claim → ClaimEvidence → Evidence → Citation → SourceRecord → Dataset → Source inspection.

`GET /api/search` is the separate keyword operation. It accepts `q` (1–200 characters) and a positive
`limit`, bounded by the repository to 50. Its results are labeled `MATCHED` in the UI so a text match
cannot be mistaken for an established claim.

## Client

The dependency-free client provides:

- a dynamically discovered, filterable dataset selector with select-all, clear-all, counts, and
  current-tab session persistence;
- visibly separate keyword and natural-language workflows;
- capability text/badges and non-color patterns;
- relevant-only Answer, What Berean Establishes, Derived Relationships, Scholarly Interpretations,
  Unresolved, Sources, Evidence, and Provenance sections;
- structured entity, event, claim, source, and provenance details loaded only when requested;
- an inspectable query-plan disclosure; and
- a bounded graph neighborhood that initially shows 25 relationships and reveals further bounded
  results with **Load more**.

The active scope remains visible with selected dataset and linked-claim counts. An empty selection is
an explicit client state, not an alias for all datasets. Research questions, plans, and results are not
saved. Only the current tab's selected dataset identifiers may be retained in `sessionStorage`; they
are intersected with freshly discovered identifiers whenever scope is loaded.

All dynamic values are rendered with DOM `textContent`. Requests are abortable, normal UI errors do
not expose database messages, JSON bodies are limited to 16 KiB, security headers are applied, and no
application write routes exist.

## Extension points and limits

Phase 35's interpreter exists as PostgreSQL validation logic rather than a deployed application
service. The Explorer therefore adds only a small reusable read-only adapter; it does not duplicate
the SQL validation interpreter, introduce domain-specific question dispatch, or create an answer
store. A future reusable Phase 35 runtime service can replace this adapter while preserving the
`/api/research` response boundary. The UI must continue to distinguish scholarly/evidence-only and
unresolved material rather than promote it to a claim.

## Verification

Focused API tests cover the Explorer shell, dynamic/all/single/multiple scope behavior, bounded
read-only research, inspectable plans, unsupported proof requests, and invalid/bounded inputs. Run
`npm run typecheck`, `npm run lint`, `npm test`, and the repository's PostgreSQL validation script
when a database is available.
