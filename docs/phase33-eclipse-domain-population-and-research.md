# Phase 33 — Eclipse Domain Population and Independent Research

## 1. Objective and distinction from Phases 30–32

Phase 33 tests the separation of acquisition from later interrogation.  Phases 30–31
demonstrated scholarly boundaries in a Genesis corpus; Phase 32 generalized those boundaries to
the 1919 eclipse.  This phase replays that bounded, source-driven population as **Stage A**, then
introduces seven previously withheld questions only in **Stage B** and reads the persisted corpus.
No schema, registry, predicate, convenience API, answer table, or second knowledge store is added.

## 2. Domain definition

The bounded domain is the 1919 solar-eclipse observation/reporting corpus: Dyson, Eddington, and
Davidson (1920); *The Observatory* contemporary 1919 joint report; Earman and Glymour (1980); and
Kennefick (2007).  Records are locator-only (`NOT_STORED_BY_POLICY`); no copyrighted source text is
redistributed.

## 3–5. Population process, validation, and inventory

`142-phase33-eclipse-domain-population-fixture.sql` replays the independently source-scoped Phase
32 population, whose stable keys and conflict guards make the process idempotent.  It covers source
registration/identity, entities (five people/places plus two comparison concepts), three events,
seven propositions/direct claims, six evidence records/citations, five identity mappings, two
scholarly candidates, and one unresolved Sobral data-handling observation.

Stage A validation verifies the four sources, locator-only policy, seven direct claims, full
Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord → Dataset → Source
provenance, and that analytical/unresolved evidence is never linked to a claim.  Replaying the
fixture and validation is deterministic and creates no duplicates.

## 6. Research-question isolation

The population fixture and candidate CSV contain only source scope and classification decisions;
they contain neither Stage B questions nor expected answers.  The questions exist solely in
`phase33-eclipse-independent-query-validation.sql`, which captures a session-local pre-query
counter and then begins `BEGIN READ ONLY`.  The seventh temporal/negative synthesis question is not a population
instruction, so it demonstrates a question unknown during population.

## 7–10. Independent queries, categories, and provenance

Stage B executes the seven required questions and returns, for every query, retrieved direct-claim
keys, source evidence, citations, scholarly candidates, unresolved material, bounded synthesis,
and `BEREAN_ONLY` scope.  It performs no external discovery; any external retrieval would require
an `EXTERNAL_RESEARCH` label and is excluded here.

* **DIRECTLY SUPPORTED:** distinct Principe/Sobral observation locations, reported participants,
  and observation-before-announcement chronology.
* **INTERPRETIVE:** Earman/Glymour and Kennefick are analytical observations/candidates only.
* **UNRESOLVED:** the source-reported Sobral astrographic focus concern does not establish data
  invalidity, selection motive, bias, or contradiction.
* **NOT REPRESENTED:** theory confirmation/refutation, motive, scholarly correctness/ranking, and
  consensus.

For example, the Eddington–Principe claim traverses
`Claim → ClaimEvidence → EV_ECLIPSE_1919_PRINCIPE_OBS_P32 → EvidenceCitation →
CITE_ECLIPSE_1919_PRINCIPE_OBSERVATIONS → SourceRecord → Dataset → ECLIPSE_1919_REPORT`.

## 11–12. Read-only behavior and determinism

The query validation captures counts for sources, identities, entities, events, propositions,
claims, evidence, and citations before querying and asserts identical counts afterwards.  It
contains only a read-only transaction and query result output.  The validation runner executes
Stage A and Stage B twice, proving replay/idempotence and deterministic result ordering.

## 13. Limitations

`REGISTRY_EXPRESSIVENESS`: no predicate faithfully expresses Sobral weighting rationale, motive,
theory confirmation, or scholarly ranking. `QUERY`: the existing read-only explorer exposes stored
objects/provenance rather than a natural-language interpretation engine. `DATA_ENTRY`: the bounded
locator-only corpus does not establish claims absent from its represented observations.
`DOMAIN_SCOPING_LIMITATION`: this is a deliberately small corpus, not all eclipse historiography.

## 14. Architectural assessment

Yes. Berean can populate a bounded domain and later interrogate persisted source-backed knowledge
with unseen questions without encoding answers during ingestion.  It does so by returning direct
support, interpretation candidates, unresolved material, and non-representation separately.

## 15. Final verdict

PASS WITH INTENTIONAL LIMITATION
