# ADR-0003: Reference Schema Boundaries and Derived Assertions

## Status

Accepted

## Decision

The PostgreSQL reference schema implements controlled vocabulary tables, citations, typed values, event participation, claim relations, and a minimal derivation model. A source record is append-only at the operating-policy level and records a content hash, import timestamp, revision label, and optional superseded record.

`dataset` is the imported edition/version or structured import container of a `source`; it is not a separate claim or evidence layer. Claim/evidence relations express evidential bearing only. Claim/claim relations express comparison or succession between assertions.

Event participation is an asserted statement: every participation row names its asserting claim. Derived claims link to one derivation with an explicit method, assumptions, and one or more claim/evidence inputs.

## Consequences

The baseline does not implement a generalized rule engine, application/API, ingestion process, canonical CSV loader, separate relationship table, or graph database. Predicate-based propositions can be projected to a graph when a consumer needs that representation.
