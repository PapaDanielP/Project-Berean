# Read-only web MVP assessment and plan

## Repository/application assessment

- This repository is a PostgreSQL 16 reference schema with executable fixtures and validation scripts.
- There was no existing web application stack, API layer, or frontend package manager setup.
- The authoritative objects and provenance chain are already modeled in SQL and must be consumed as-is.
- Existing `event_participation` and `claim_rendering` are projections and remain authoritative for those views.

## Minimal implementation plan for first MVP slice

1. Add a small typed Node/TypeScript read-only web stack (Express + pg).
2. Implement parameterized read-only API endpoints for:
   - global search,
   - entity/claim/proposition/event detail,
   - provenance traversal,
   - source/dataset/source-record browsing,
   - bounded graph neighborhood,
   - Genesis locator coverage,
   - quality dashboard metrics.
3. Add a simple responsive accessible UI shell that consumes API endpoints and provides textual graph relationships.
4. Add focused API integration tests using the authoritative schema and fixtures.
5. Document local setup and verification commands while keeping PostgreSQL validation as a separate authoritative check.
