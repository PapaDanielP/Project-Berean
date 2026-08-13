# Phase History Index

**Status:** ACTIVE — canonical phase-history index
**Scope:** Historical phase and research record navigation only
**Authority:** PHASE RECORD index (historical evidence; does not supersede current authoritative architecture, data model, or API documentation)
**Last verified:** 2026-08-13

This file is the canonical index into Project Berean's phase history. Phase records are
**historical evidence** of what was implemented, tested, and validated at a point in time.
They do not override current authoritative documentation — see
[`../README.md`](../README.md) for the authority map and
[`../01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md),
[`../02-domain/DOMAIN_MODEL.md`](../02-domain/DOMAIN_MODEL.md), and
[`../api/API_DEVELOPER_GUIDE.md`](../api/API_DEVELOPER_GUIDE.md) for current architecture,
data model, and API behavior respectively.

Phase history is split across two directories for historical reasons:

- [`../04-data/`](../04-data/) — legacy Phase 6–32 data-population, capability, and
  provenance-engine records (see [`../04-data/README.md`](../04-data/README.md) for that
  index).
- [`phases/`](.) (this directory) — later Phase 33–37R/37B independent-research and
  domain-lifecycle validation records.

## Phase 33–37R/37B index (this directory)

| Phase | Title | Status |
|---|---|---|
| 33 | [Eclipse Domain Population and Independent Scholarly Research](./PHASE_33_ECLIPSE_DOMAIN_POPULATION_AND_RESEARCH.md) | Historical record |
| 34 | [Natural-Language Scholarly Query Interpretation over the Phase 33 Eclipse Substrate](./PHASE_34_NATURAL_LANGUAGE_RESEARCH_QUERY.md) | Historical record |
| 35 | [Cross-Domain Natural-Language Scholarly Research](./PHASE_35_CROSS_DOMAIN_NATURAL_LANGUAGE_RESEARCH.md) | Historical record |
| 36 | [Evidence Audit](./PHASE_36_EVIDENCE_AUDIT.md) | Historical record |
| 36 | [Repeatable Domain Lifecycle and Independent Research Platform Validation](./PHASE_36_REPEATABLE_DOMAIN_LIFECYCLE.md) | Historical record |
| 37 | [1893 World's Columbian Exposition Independent Graph-Derived Research](./PHASE_37_WORLD_COLUMBIAN_EXPOSITION_INDEPENDENT_RESEARCH.md) | Historical record |
| 37R/37B | [World's Columbian Exposition Discovery-Driven Expansion](./PHASE_37R_37B_WORLD_COLUMBIAN_EXPOSITION_EXPANSION.md) | Historical record |

Phase 28 (automated ingestion pipeline), Phase 36 (evidence audit and repeatable domain
lifecycle), and Phase 37/37R/37B (independent research and discovery-driven expansion)
conclusions are preserved verbatim above and in `docs/04-data/`; this index does not alter
or reinterpret their findings.

## Legacy Phase 6–32 index

See [`../04-data/README.md`](../04-data/README.md) for the full legacy index. Summary:

- Phases 6–19: Genesis 1–11 controlled population, object/artifact entity modeling, and
  source-backed lifecycle/conflict validation.
- Phase 20: Provenance engine capability specification (design contract, non-implementing).
- Phase 21–23: Read-only provenance/derivation-eligibility operation records.
- Phase 24–27: Berean-in-action demonstration, exploration API, and Genesis 1–50 corpus
  expansion.
- Phase 28: Automated Tier-1 ingestion pipeline.
- Phase 30–32: Scholarly research validation and cross-domain generalization.

## Reading a phase record

Each phase record should be read as a historical snapshot. When a phase record states an
architectural conclusion that is still true today, the current authoritative document is
the source of truth; the phase record is retained as the original evidence and rationale.
Where a phase record's original conclusions differ from later phases or current behavior,
that difference is preserved as historical record, not silently corrected.
