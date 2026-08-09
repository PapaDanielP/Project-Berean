# ADR-0002: Separate Source, Evidence, Claim, and Truth

## Status

Accepted

## Decision

Berean will not collapse source material, evidence, claims, relationships, and truth into a single fact representation.

## Rationale

A knowledge system must preserve disagreement and uncertainty. A source can be wrong, an interpretation can be disputed, and a claim can be derived from evidence rather than directly stated.

## Consequence

Queries and downstream applications must distinguish:

- what a source says
- what evidence was extracted
- what claim is asserted
- what proposition the claim expresses
- what relationship is represented
