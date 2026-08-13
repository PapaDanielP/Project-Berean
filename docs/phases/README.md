# Historical Phase Records

This index is the canonical entry point for Project Berean phase history. Phase records are retained as historical evidence of objectives, scope, implementation, validation, limitations, architectural conclusions, and verdicts at the time they were written. They do **not** supersede the current architecture, schema, API, validation, or repository-structure documents linked from [`../README.md`](../README.md).

## Authority boundary

Use this order when a phase record appears to conflict with current materials:

1. implementation/schema/tests/validation scripts;
2. authoritative current documentation;
3. reference documentation;
4. phase records;
5. validation records;
6. archive/review material.

Do not rewrite historical phase evidence into a current specification. Instead, update the authoritative document and leave a cross-reference from the historical record when necessary.

## Canonical locations

- Legacy Phase 6–32 records remain in [`../04-data/`](../04-data/) because existing data, ingestion, and Genesis documentation link to those paths and because those phases primarily document population/data-model growth.
- Phase 33 and later independent domain/research/validation records live in this directory.
- New phase reports belong in this directory unless they are direct continuations of a legacy `docs/04-data/` record.

## Legacy Phase 6–32 records

| Phase / record | Path | Historical purpose |
|---|---|---|
| Genesis/data population setup | [`../04-data/GENESIS_1_1-5_SLICE.md`](../04-data/GENESIS_1_1-5_SLICE.md), [`../04-data/POPULATION_SPECIFICATION.md`](../04-data/POPULATION_SPECIFICATION.md), [`../04-data/DATA_POLICY.md`](../04-data/DATA_POLICY.md), [`../04-data/STEPBIBLE_ACQUISITION_REPORT.md`](../04-data/STEPBIBLE_ACQUISITION_REPORT.md) | Early source/data scope, policy, and acquisition evidence. |
| Phase 6–19 reports | [`../04-data/PHASE6_REPORT.md`](../04-data/PHASE6_REPORT.md) through [`../04-data/PHASE19_REPORT.md`](../04-data/PHASE19_REPORT.md) | Incremental Genesis/entity/artifact/event/provenance population and validation records. |
| Phase 20–25 reports | [`../04-data/PHASE20_REPORT.md`](../04-data/PHASE20_REPORT.md), [`../04-data/PHASE20_CAPABILITY_SPECIFICATION.md`](../04-data/PHASE20_CAPABILITY_SPECIFICATION.md), [`../04-data/PHASE21_EXPLAIN_PROVENANCE.md`](../04-data/PHASE21_EXPLAIN_PROVENANCE.md), [`../04-data/PHASE22_CAPABILITY_ASSESSMENT.md`](../04-data/PHASE22_CAPABILITY_ASSESSMENT.md), [`../04-data/PHASE23_CHECK_DERIVATION_ELIGIBILITY.md`](../04-data/PHASE23_CHECK_DERIVATION_ELIGIBILITY.md), [`../04-data/PHASE24_BEREAN_IN_ACTION.md`](../04-data/PHASE24_BEREAN_IN_ACTION.md), [`../04-data/PHASE25_EXPLORATION_API.md`](../04-data/PHASE25_EXPLORATION_API.md) | Capability, provenance explanation, derivation eligibility, demonstration, and Explorer/API-era records. Current API authority is under [`../api/`](../api/). |
| Phase 26–32 reports | [`../04-data/PHASE26_BIBLICAL_ENTITY_COVERAGE_AND_INGESTION.md`](../04-data/PHASE26_BIBLICAL_ENTITY_COVERAGE_AND_INGESTION.md), [`../04-data/PHASE27_GENESIS_1_50.md`](../04-data/PHASE27_GENESIS_1_50.md), [`../04-data/PHASE28_INGESTION_PIPELINE.md`](../04-data/PHASE28_INGESTION_PIPELINE.md), [`../04-data/PHASE30_SCHOLARLY_RESEARCH_VALIDATION.md`](../04-data/PHASE30_SCHOLARLY_RESEARCH_VALIDATION.md), [`../04-data/PHASE31_END_TO_END_SCHOLARLY_RESEARCH_DEMONSTRATION.md`](../04-data/PHASE31_END_TO_END_SCHOLARLY_RESEARCH_DEMONSTRATION.md), [`../04-data/PHASE32_CROSS_DOMAIN_SCHOLARLY_RESEARCH_GENERALIZATION.md`](../04-data/PHASE32_CROSS_DOMAIN_SCHOLARLY_RESEARCH_GENERALIZATION.md) | Biblical entity coverage, ingestion, and research validation history. Current ingestion commands are in [`../../data/ingestion/README.md`](../../data/ingestion/README.md) and [`../00-project/DEVELOPER_GUIDE.md`](../00-project/DEVELOPER_GUIDE.md). |

## Later phase records

| Phase | Path | Historical purpose |
|---|---|---|
| Phase 33 | [`PHASE_33_ECLIPSE_DOMAIN_POPULATION_AND_RESEARCH.md`](./PHASE_33_ECLIPSE_DOMAIN_POPULATION_AND_RESEARCH.md) | Eclipse domain population and independent research validation. |
| Phase 34 | [`PHASE_34_NATURAL_LANGUAGE_RESEARCH_QUERY.md`](./PHASE_34_NATURAL_LANGUAGE_RESEARCH_QUERY.md) | Natural-language research query validation. |
| Phase 35 | [`PHASE_35_CROSS_DOMAIN_NATURAL_LANGUAGE_RESEARCH.md`](./PHASE_35_CROSS_DOMAIN_NATURAL_LANGUAGE_RESEARCH.md) | Cross-domain natural-language query validation. |
| Phase 36 | [`PHASE_36_EVIDENCE_AUDIT.md`](./PHASE_36_EVIDENCE_AUDIT.md), [`PHASE_36_REPEATABLE_DOMAIN_LIFECYCLE.md`](./PHASE_36_REPEATABLE_DOMAIN_LIFECYCLE.md) | Evidence audit and Seneca Falls repeatable lifecycle validation. |
| Phase 37 / 37R | [`PHASE_37_WORLD_COLUMBIAN_EXPOSITION_INDEPENDENT_RESEARCH.md`](./PHASE_37_WORLD_COLUMBIAN_EXPOSITION_INDEPENDENT_RESEARCH.md), [`PHASE_37R_37B_WORLD_COLUMBIAN_EXPOSITION_EXPANSION.md`](./PHASE_37R_37B_WORLD_COLUMBIAN_EXPOSITION_EXPANSION.md) | World's Columbian Exposition independent research, withheld-query, and candidate-audit validation. |

## Current references

- Architecture: [`../01-architecture/ARCHITECTURE.md`](../01-architecture/ARCHITECTURE.md)
- Schema: [`../03-schema/INFORMATION_SCHEMA.md`](../03-schema/INFORMATION_SCHEMA.md)
- API: [`../api/API_DEVELOPER_GUIDE.md`](../api/API_DEVELOPER_GUIDE.md)
- Validation: [`../05-validation/VALIDATION.md`](../05-validation/VALIDATION.md)
