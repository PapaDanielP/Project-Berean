# API Security Model

This document describes the **implemented** security behavior of the Project Berean API, traced to
`src/auth.ts`, `src/app.ts`, `src/administration/routes.ts`, `src/administration/repository.ts`, and the tests in
`tests/app/app.test.ts`.

## 1. Authentication

- Administrative routes use opaque bearer credentials configured out of band in `BEREAN_API_CREDENTIALS`
  (a JSON array of `{ key, displayName, role, tokenHash }`).
- `tokenHash` is a lowercase SHA-256 hex digest. Plaintext tokens are never stored in the repository or in the database.
- Presented tokens are compared with `timingSafeEqual` against pre-computed digests.
- Malformed credential configuration throws at construction time, so a misconfigured deployment cannot start with a weak credential.
- **Fail closed:** when no credential is configured, every administrative route returns `503 AUTH_NOT_CONFIGURED` and writes nothing.
- `401` responses always set `WWW-Authenticate: Bearer` and never distinguish "unknown token" from "no token" in a way that reveals valid keys.

## 2. Authorization

Roles are hierarchical; a route requiring role *R* also accepts every higher role.

| Rank | Role | Intent |
|---|---|---|
| 0 | `READER` | Read workflow administration rows |
| 1 | `RESEARCHER` | Scope inquiry, queue discovery, record candidates and derivation metadata |
| 2 | `CONTENT_EDITOR` | Register sources, source records, evidence, propose identity mappings, queue ingestion, control jobs |
| 3 | `REVIEWER` | Review candidates and identity mappings, author claims, queue validation |
| 4 | `ADMINISTRATOR` | Create and update corpora, queue exports |
| 5 | `SYSTEM` | Reserved for worker ownership checks; it is not a route minimum |

Minimum role per route:

| Route | Minimum role |
|---|---|
| `GET /api/v1/admin/:resource` | `READER` |
| `POST /api/v1/research-topics`, `/discovery-requests`, `/discovery-requests/:id/candidates`, `/derivations` | `RESEARCHER` |
| `POST /api/v1/source-registrations`, `/source-records`, `/evidence`, `/identity-mappings`, `/ingestion-jobs`, `/jobs/:id/cancel`, `/jobs/:id/retry` | `CONTENT_EDITOR` |
| `POST /api/v1/candidates/:id/review`, `/claims`, `/identity-mappings/:id/review`, `/validation-runs` | `REVIEWER` |
| `POST /api/v1/corpora`, `PATCH /api/v1/corpora/:id`, `POST /api/v1/export-jobs`, `GET /api/v1/export-artifacts/:artifactKey[/download]` | `ADMINISTRATOR` |

Beyond the role gate, `POST /api/v1/jobs/:id/cancel` and `/retry` apply an ownership and job-type check in the repository
and return `403 FORBIDDEN` (`JOB_ACTION_FORBIDDEN`) when the actor may not change that job.

Authentication is evaluated **before** resource validation, so probing `GET /api/v1/admin/not-real` without a credential
returns `401` and discloses nothing about which administrative resources exist.

## 3. Read surface

Read routes are unauthenticated by design: this deployment exposes a public, read-only scholarly explorer over persisted
material. That design decision has two hard requirements, both verified by tests:

1. **No read route mutates state.** `tests/app/app.test.ts` snapshots the row count of every base table before and after
   read traffic and asserts equality.
2. **No read route discloses withheld content.** Raw content and quoted text that are withheld by licence or policy are
   reported as `NOT_STORED_BY_POLICY`, never reconstructed.

If a deployment requires non-public reads, the gate belongs in front of the read router; the API does not silently
downgrade content based on the caller.

## 4. Input handling

- JSON bodies are limited to 16 KiB.
- Every identifier is validated as a positive safe integer before it reaches SQL.
- Every string field has an explicit maximum length; keys must match `^[A-Za-z0-9][A-Za-z0-9_.:-]*$`.
- Every enumerated field is validated against a closed list in `src/administration/service.ts`.
- All SQL is parameterized. Resource and registry names are resolved through fixed lookup maps, never interpolated.
- Unsupported resources, registries, and search filters return `404`; unsupported methods and paths under `/api/v1`
  return `501 NOT_REPRESENTED`.

## 5. Transport and response hardening

- `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: no-referrer`
- `X-Powered-By` disabled.
- The generic error handler returns `{"error":"internal_error"}` with no stack trace, driver code, SQL, or table name.
  Internal markers such as `UNSUPPORTED_ADMIN_RESOURCE` are mapped to contract errors before they can reach the client.

## 6. Transactionality, audit, and correlation

- Every mutation runs inside a single transaction in `AdministrationRepository.transaction`; any failure issues `ROLLBACK`.
- Every successful mutation appends an `audit_event` row **inside the same transaction**, so an unaudited mutation cannot exist.
- `audit_event` and `validation_result` are protected by database triggers that reject `UPDATE` and `DELETE`
  (`tests/app/app.test.ts` asserts the append-only failure).
- Administrative requests accept an optional `X-Correlation-Id` UUID, generate one when absent, echo it on the response,
  and persist it with the audit event.
- Optimistic concurrency for corpora is enforced in the `UPDATE ... WHERE version = $2` predicate, so a stale write commits
  nothing at all — neither the row change nor an audit event.

## 7. Deliberately absent capabilities

The API exposes no route for arbitrary URL fetch, file upload, arbitrary filesystem download, SQL execution, registry or predicate mutation,
truth adjudication, conflict resolution, or canonicalisation. These are not backlog items; adding them would move
authority out of reviewed, provenance-bearing structures. See [`API_EPISTEMIC_BOUNDARIES.md`](./API_EPISTEMIC_BOUNDARIES.md).

The single export download route accepts only an opaque artifact UUID, resolves a persisted safe
relative locator beneath the configured server-only root, rejects symlink/path escape, and verifies
the persisted byte length and SHA-256. API clients never control a filesystem path.

## 8. Operational responsibilities not implemented here

Classification: **DEVELOPER/OPERATIONS ONLY**.

- Credential issuance, rotation, and revocation are out-of-band operations against `BEREAN_API_CREDENTIALS`.
- Rate limiting, TLS termination, and network access control are deployment concerns and are not implemented in the process.
- Worker credentials and artifact retention/backup remain deployment responsibilities.
