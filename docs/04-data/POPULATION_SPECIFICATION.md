# Phase 6 Population Specification

This specification records the repeatable insertion and validation contract for controlled Berean population. It preserves the v0.6 architecture and does not add event reconciliation, claim relation types, provenance layers, or alternative persistence.

## Insertion contract

Populate each batch in one transaction and validate before accepting it:

```text
Source -> Dataset -> SourceRecord -> Citation -> Evidence -> Proposition -> Claim -> ClaimEvidence
                                      -> Entity -> SourceIdentity -> EntitySourceMapping
                                      -> Event -> claim-asserted Proposition -> event_participation view
                                      -> Derivation -> DerivationInput -> derived Claim
```

- **Source**: record source identity, name, type, and description only when known. Do not treat generated summaries or external structured data as Berean source evidence until imported through this chain.
- **Dataset**: attach to one Source and record dataset key, edition/version, license status, acquisition method, and transformation notes. Do not fabricate license or acquisition metadata.
- **SourceRecord**: preserve source boundaries with stable keys and locators. Store `raw_content` and `content_hash` only when the repository has distribution-compatible content; otherwise use structural records with both fields null.
- **Citation**: cite the SourceRecord and locator. Leave `quoted_text` null when source text is not redistributed.
- **Evidence**: use conservative observations tied to one SourceRecord and at least one Citation. `SOURCE_OBSERVATION` must not contain unsupported interpretation.
- **Proposition**: store the authoritative normalized semantic content with a registered predicate and valid subject/object kinds. Independent sources may share one Proposition only when the structured semantic assertion is the same.
- **Claim**: create source-specific assertions over Propositions. `claim.statement` is a display label, not a second semantic authority.
- **ClaimEvidence**: explicitly type each evidence relationship as `SUPPORTS`, `CONTRADICTS`, or `QUALIFIES`.
- **Entity**: create canonical entities only when needed by represented propositions.
- **SourceIdentity**: preserve source-specific names independently from canonical entities.
- **EntitySourceMapping**: record status, confidence where supportable, justification, and same-source supporting evidence for active mappings.
- **Event**: use the existing event table only as the modeled occurrence referenced by propositions. Event participation remains the `event_participation` projection from asserted propositions.
- **Derivation**: record method and assumptions before creating a derived Claim. Every derived Claim must have DerivationInput rows naming explicit claim/evidence inputs.

## Claim distinctions

- **Direct source claim**: a Claim of type `DIRECT_SOURCE_CLAIM` supported by source observation evidence.
- **Competing claim**: a coexisting Claim with different semantic content, preserved without overwriting the other claim.
- **Contradictory claim**: competing claim connected with `claim_relation.CONTRADICTS` and independent provenance.
- **Derived claim**: a Claim of type `DERIVED_CLAIM` with derivation metadata and inputs; it must never be indistinguishable from direct source evidence.

## Normalization and restraint

Use one Proposition for the same normalized semantic assertion, even when multiple Claims from different sources assert it. Use distinct Propositions for different numerals, subjects, objects, predicates, or term kinds. Do not infer chronology, event identity, theology, or reconciliation certainty from similarity or ordering. Preserve unresolved ambiguity in notes and reports instead of forcing precision.

## Source discipline

The Phase 6 Genesis slice uses repository-available structural locators and published genealogical numerals already represented in fixtures. It does not reproduce source text; `raw_content`, `content_hash`, and `quoted_text` remain null for structural Genesis records. External source declarations under `data/external/*` remain metadata-only until license and acquisition details are verified for a future import.

## Transactional validation

A batch is acceptable only after loading transactionally and passing:

1. schema constraints;
2. `scripts/validation/validate.sql`;
3. `tests/validation/blocking-cases.sh`;
4. Genesis slice validation;
5. Phase 6 regression checks;
6. Phase 6 coverage/data-quality reporting.

Absence of a record is reported as missing or intentionally excluded; it is not evidence that the underlying fact is false.
