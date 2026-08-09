# Architecture Alignment and Remediation Report

Reviewed baseline: merged `main` at commit `8ee59e44424997398ffed1c8994549eca2f7a73f`.

## A. Summary of changes

- Confirmed the PostgreSQL 16 reference schema, typed Claim–Evidence many-to-many model, citations, claim relations, derivation lineage, typed values, predicate registry, and event-participation projection.
- Added this report to document the merged remediation and its remaining limitations.
- Corrected the repository documentation so `event_participation` and `claim_rendering` are identified as views/projections rather than physical tables.
- Expanded Copilot guidance with the authoritative proposition, provenance, derivation, reconciliation, and event-participation rules.

## B. Changes intentionally not made

- No separate `relationship` table was added. Relationships remain proposition predicates and graph projections, avoiding duplicate semantic truth.
- No graph database, ontology engine, inference engine, microservices, distributed database, or unrelated sovereign architecture was introduced.
- No copyrighted or fabricated source text was added to the Genesis fixtures.
- No application, API, or ingestion pipeline was added; the repository remains a pre-beta reference data-model baseline.
- No broad redesign or rewrite was performed.

## C. Unresolved architectural decisions

1. The claim-status lifecycle is not yet fully tied to `SUPERSEDES` claim relations.
2. Confidence is currently defined for reconciliation mappings only.
3. Predicate governance, including ownership and possible inverse/symmetry metadata, remains open.
4. Event temporal bounds are currently represented through propositions and typed values rather than dedicated event columns.
5. Canonical entity merge/split history is not yet modeled.

## D. Known limitations

- Genesis 1–11 coverage is partial and deliberately contains no reproduced source text.
- The canonical CSV is not loaded by an importer; executable fixtures insert their own test data.
- Source-record revision metadata exists, but append-only behavior is not enforced against direct SQL updates.
- Validation is PostgreSQL-specific and currently fails fast on the first blocking error.
- No application, API, ingestion, or graph-export runtime exists yet.

## E. Recommended next steps

1. Decide and validate claim-status lifecycle transitions.
2. Add a small loader or explicit validation path for `canonical/entities.csv`.
3. Record bibliographic/source metadata for Genesis reference points without adding restricted source text.
4. Consider an append-only enforcement policy or trigger for source records.
5. Add aggregate validation reporting while retaining nonzero CI failure behavior.

## F. Does the repository faithfully represent the Berean architecture and vision?

**YES WITH SPECIFIC LIMITATIONS.**

The merged repository faithfully implements the core Berean distinctions: Source, Dataset, Source Record, Citation, Evidence, Claim, Proposition, Entity, Event, Source Identity, reconciliation mappings, derivations, and typed Claim–Evidence relations. Provenance is traceable, competing claims can coexist, event participation is derived from claim-asserted propositions, and no unrelated sovereign architecture has been introduced.

The limitations are explicit scope boundaries rather than architectural contradictions: the Genesis dataset is partial and metadata-oriented, the canonical CSV is not yet loaded, append-only source records are not enforced, validation is PostgreSQL-specific, and no application or ingestion runtime exists.
