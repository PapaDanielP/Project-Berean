# Project Berean Explorer

The Explorer is a read-only Express application over the reference PostgreSQL model. It is not a
second knowledge store: all inventory, scope, search, claims, graph edges, and provenance are read
from the existing Berean tables and projections.

## Query flow

`POST /api/research` accepts a natural-language question and optional persisted dataset identifiers.
The server creates a transient, inspectable plan, checks the registered predicate vocabulary, executes
a bounded Berean-only retrieval, and returns a capability status and source/dataset context. Query
plans and results are never persisted. User input is length-checked and all database values are bound
parameters.

`GET /api/research/scope` dynamically lists sources and datasets with counts. Berean has no Domain
table, so the UI deliberately calls these persisted scope units rather than manufacturing domains.
Selecting a scope only constrains the returned claim evidence; it neither reconciles identities nor
changes authoritative records.

The current web adapter exposes generic registered participation predicates and predicate-name/
description matches. Requests to establish truth or proof return `NOT_REPRESENTED`, rather than an
answer. Direct claims are marked `DIRECTLY_SUPPORTED`; derived claims are marked
`DERIVED_FROM_PERSISTED_GRAPH`. Existing claim and provenance endpoints remain the authoritative path
for complete Claim → ClaimEvidence → Evidence → Citation → SourceRecord → Dataset → Source inspection.

## Client

The vanilla client provides an accessible scope selector, keyword search, research question form,
expandable query plan, capability/limitation display, details, and bounded graph exploration. Local
browser history and saved research are intentionally not implemented: they would be UI-only and have
no authoritative status.

## Extension points and limits

Phase 35's interpreter exists as PostgreSQL validation logic rather than a deployed application
service. The Explorer therefore adds only a small reusable read-only adapter; it does not duplicate
the SQL validation interpreter, introduce domain-specific question dispatch, or create an answer
store. A future reusable Phase 35 runtime service can replace this adapter while preserving the
`/api/research` response boundary. The UI must continue to distinguish scholarly/evidence-only and
unresolved material rather than promote it to a claim.

## Verification

Focused API tests cover dynamic scope discovery, bounded read-only research, inspectable plans, and
unsupported proof requests. Run `npm run typecheck`, `npm run lint`, `npm test`, and the repository's
PostgreSQL validation script when a database is available.
