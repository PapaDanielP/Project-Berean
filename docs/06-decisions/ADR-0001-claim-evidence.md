# ADR-0001: Explicit Claim ↔ Evidence Association

## Status

Accepted

## Context

The earlier model allowed Claims to reference source records while Evidence was modeled separately. This did not explicitly represent the semantic relationship between a Claim and the Evidence supporting or challenging it.

## Decision

Represent Claim ↔ Evidence as an explicit many-to-many association.

```text
Claim
  ↕
ClaimEvidence
  ↕
Evidence
```

## Rationale

One Claim may have multiple evidence records, and one Evidence record may support multiple Claims.

The association also needs a relationship type.

## Initial relation types

- `SUPPORTS`
- `CONTRADICTS`
- `QUALIFIES`
- `DERIVED_FROM`

## Consequences

The schema gains an additional association object but becomes semantically explicit and auditable.
