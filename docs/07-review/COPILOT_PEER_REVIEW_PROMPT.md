# GitHub Copilot Peer Review Prompt

Perform an independent senior-level peer review of the entire Project Berean repository.

Review the project overview, purpose, charter, architecture, domain model, information schema, SQL/database implementation, source ingestion, evidence, claims, provenance, entity reconciliation, validation, tests, documentation, and sample data.

Do not assume the architecture is correct.

Specifically test:

- Whether Source, SourceRecord, Evidence, Claim, Proposition, Entity, Event, Relationship, and SourceIdentity are semantically distinct.
- Whether Claim ↔ Evidence is truly many-to-many.
- Whether Evidence has complete provenance.
- Whether competing Claims can coexist.
- Whether derived claims are distinguishable from direct source observations.
- Whether source-specific identities can be reconciled without losing provenance.
- Whether Genesis 1–11 exposes schema weaknesses.
- Whether the physical schema faithfully represents the conceptual model.
- Whether cardinalities and constraints prevent invalid states.
- Whether the architecture can scale without premature complexity.
- Whether the repository documentation matches implementation.
- Whether graph projection is natural without requiring Berean to become a graph database prematurely.

Explicitly keep sovereign geography, geographic residency, security classifications, and sovereign access-control concepts outside Berean unless the repository itself demonstrates a genuine requirement.

Report:

- Executive Summary
- Critical Findings
- Major Findings
- Moderate Findings
- Minor Findings
- Architectural Strengths
- Domain Model Assessment
- Claim/Evidence/Provenance Assessment
- Information Schema Assessment
- Data Quality Assessment
- Genesis 1–11 Stress Test
- Scalability Assessment
- Graph Readiness
- Documentation Assessment
- Do Now
- Do Soon
- Do Later
- Do Not Do Yet
- Overall Architecture Verdict

For every finding provide concrete repository evidence and distinguish actual defects from future possibilities.

Do not recommend a rewrite unless incremental remediation is demonstrably insufficient.
