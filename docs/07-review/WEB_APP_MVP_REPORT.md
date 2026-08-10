# Read-only web MVP implementation report

## Scope implemented in this PR

- Added a first read-only application layer over the existing PostgreSQL schema.
- No schema/model redesign and no duplicate authoritative knowledge store were introduced.
- Implemented API + UI vertical slice for search and provenance traversal using existing model semantics.

## Routes and API endpoints

- UI shell: `/`
- Health: `/health`
- Search: `/api/search`
- Entity detail: `/api/entities/:entityId`
- Claim detail: `/api/claims/:claimId`
- Proposition detail: `/api/propositions/:propositionId`
- Event detail (from `event_participation`): `/api/events/:eventId`
- Source browser: `/api/sources`, `/api/sources/:sourceId`
- Provenance explorer: `/api/provenance/claims/:claimId`
- Genesis coverage: `/api/genesis/coverage`
- Graph neighborhood (bounded): `/api/graph?nodeType=...&nodeId=...`
- Coverage/quality dashboard: `/api/dashboard/quality`

## Runtime setup

See `docs/00-project/DEVELOPER_GUIDE.md` for exact commands and environment variables.

## Notable constraints preserved

- Claims are displayed as assertions; no hidden truth model.
- Direct vs derived claims remain explicit.
- Competing claims remain coexisting via claim relations/evidence relations.
- Source text is not fabricated; source-unavailable conditions are shown from runtime fields.
- Event participation uses the existing authoritative projection view.

## Deferred for later increments

- Richer visual graph rendering beyond bounded textual neighborhood.
- More advanced provenance filtering and pagination controls.
- Additional UX polish for deeply nested detail navigation.
