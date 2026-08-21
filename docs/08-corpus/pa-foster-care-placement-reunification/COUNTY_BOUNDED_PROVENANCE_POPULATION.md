# Allegheny County Bounded Provenance Population

**Review date:** August 21, 2026  
**Corpus:** `pa-foster-care-placement-reunification`  
**Candidate county:** Allegheny County, Pennsylvania  
**Determination:** `BOUNDED_PROVENANCE_POPULATION_PARTIAL`  
**Pilot status:** `PILOT_REVIEW_REQUIRED`

## 1. Purpose

This phase defines the smallest bounded provenance-population exercise for the Allegheny County re-entry material. Its purpose is to test whether Berean can preserve a source-backed county observation while retaining unresolved methodology instead of converting missing information into apparently precise facts.

The phase does not establish a county-versus-Pennsylvania performance comparison and does not select Allegheny County as the final pilot.

## 2. Governing review determinations

The preceding closure review established:

- County observation: `PARTIALLY_REPRODUCIBLE`.
- County/state comparison: `INSUFFICIENT_INFORMATION`.
- Pilot disposition: `PILOT_REVIEW_REQUIRED`.

The county NBPB reports an **8.1%** re-entry indicator. County dashboard material separately describes re-entry as approximately **9%** over time. The relationship between those observations is not established and must remain unresolved.

## 3. Sources used

### 3.1 Allegheny County NBPB

- **Title:** `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- **Issuer:** Allegheny County Department of Human Services, Office of Children, Youth and Families.
- **Source URL:** `https://analytics.alleghenycounty.us/wp-content/uploads/2025/09/NBB02_26-27_Narrative.pdf`.
- **Locator:** PDF page 69, section `2-3f Re-entry (in 12 Months)`; pages 70–71 contain related subgroup discussion.
- **Observation:** The county document reports an 8.1% re-entry rate after discharge to reunification, living with a relative, or guardianship.
- **Established:** Issuer, county scope, reported percentage, unit, functional 12-month exit/re-entry meaning, and listed exit destinations.
- **Unresolved:** Numerator, numeric denominator, complete cohort construction, complete inclusion/exclusion rules, exact underlying profile period, and calculation procedure.

### 3.2 Allegheny County dashboard publication

- **Title:** `Child Welfare Out-of-Home Placements: Interactive Dashboard`.
- **Issuer:** Allegheny County Department of Human Services / Allegheny Analytics.
- **Publication URL:** `https://analytics.alleghenycounty.us/2021/01/07/child-welfare-out-of-home-placements-interactive-dashboard/`.
- **Referenced view:** `Re-entry`.
- **Observation:** County material describes re-entry within one year as approximately 9% over time.
- **Established:** Dashboard identity, Allegheny County scope, broad placement/re-entry subject, and the separate approximate trend description.
- **Unresolved:** Exact dashboard filter state, selected dates, numerator, denominator, export/snapshot, version, refresh identifier, and whether the approximately 9% description is the same calculation as the NBPB's 8.1% indicator.

### 3.3 Pennsylvania statewide material

The Pennsylvania statewide 7.8% measure remains contextual and separate in this phase:

- **Title:** `Pennsylvania 2026 Annual Progress and Services Report`.
- **Issuer:** Pennsylvania Department of Human Services, Office of Children, Youth, and Families.
- **Locator:** PDF pages 29–30, Table 18, `SWDI on Reentry to Foster Care in 12 Months`.
- **Observation:** Pennsylvania reports an RSP value of 7.8% for the 21B–22A files.
- **Status in this phase:** Separate source-backed statewide context; no county/state comparison claim is created.

## 4. Observations populated

This repository-only phase creates a documentation record of the bounded population. It does not create database rows, source records, evidence, claims, propositions, or downloaded source artifacts.

### Observation A — County NBPB 8.1%

**Status:** `ESTABLISHED` as a source-reported observation; `QUALIFIED` for methodology.

```text
Scope: Allegheny County
Subject: county re-entry-within-12-months indicator
Value: 8.1 percent
Unit: percentage
Source: Allegheny County DHS / OCYF
Document: FY 2026-27 Needs-Based Plan & Budget
Locator: PDF page 69, section 2-3f
```

The observation must be represented as what the county source reports. It must not be represented as an independently reconstructed statistic.

### Observation B — Dashboard approximately 9%

**Status:** `ESTABLISHED` as a source-described trend; `QUALIFIED` and `UNRESOLVED` for exact metric reconstruction.

```text
Scope: Allegheny County
Subject: dashboard re-entry trend
Value: approximately 9 percent
Unit: percentage
Source: Allegheny County DHS / Allegheny Analytics
Dashboard view: Re-entry, as referenced by county material
Locator: dashboard publication page and county NBPB discussion
```

The observation remains separate from Observation A. No proposition is created stating that 8.1% equals approximately 9%.

### Observation C — Pennsylvania 7.8%

**Status:** `ESTABLISHED` as a separate statewide source-reported observation; `NOT_SUPPORTED` as a county comparison conclusion.

```text
Scope: Pennsylvania statewide
Subject: SWDI re-entry to foster care within 12 months
Value: 7.8 percent RSP value
Period: 21B–22A files
Source: Pennsylvania DHS / OCYF
Locator: 2026 APSR pages 29–30, Table 18
```

This observation is not linked to either county observation by a direct comparative claim.

## 5. Exact provenance for each observation

The intended provenance chain for each future persisted observation is:

```text
Source
  → Dataset
    → SourceRecord
      → Citation
        → Evidence
          → ClaimEvidence
            → Claim
              → Proposition
```

### County NBPB provenance

```text
Allegheny County DHS / OCYF
  → FY 2026-27 Needs-Based Plan & Budget
    → public PDF source record
      → page 69, section 2-3f citation
        → SOURCE_OBSERVATION: source reports 8.1%
          → source-scoped DIRECT_SOURCE_CLAIM
            → county re-entry proposition with typed percentage value
```

Required qualification notes:

- `NUMERATOR_NOT_STATED`.
- `DENOMINATOR_NOT_STATED`.
- `COHORT_PARTIALLY_STATED`.
- `CALCULATION_NOT_RECONSTRUCTIBLE`.
- `UNDERLYING_PROFILE_PERIOD_NOT_VERIFIED`.

### Dashboard provenance

```text
Allegheny County DHS / Allegheny Analytics
  → Child Welfare Out-of-Home Placements dashboard
    → publication page or later versioned dashboard source record
      → dashboard Re-entry view citation
        → SOURCE_OBSERVATION: source describes approximately 9% trend
          → source-scoped DIRECT_SOURCE_CLAIM
            → dashboard trend proposition with qualified text/percentage value
```

Required qualification notes:

- `EXACT_FILTER_STATE_NOT_VERIFIED`.
- `NUMERATOR_NOT_STATED`.
- `DENOMINATOR_NOT_STATED`.
- `EXPORT_NOT_OBTAINED`.
- `SNAPSHOT_NOT_VERIFIED`.
- `RELATION_TO_8_1_PERCENT_NOT_VERIFIED`.

## 6. Geographic scope

All county observations are explicitly scoped to **Allegheny County**. The Pennsylvania observation is explicitly scoped to **Pennsylvania statewide**.

No statewide claim is created from county evidence. No county claim is created from statewide evidence. No county ranking, performance assessment, or county/state difference claim is created.

The geographic distinction is representable through existing Berean entities, source/dataset boundaries, corpus dataset membership, propositions, and source-scoped claims. No domain-specific geographic table is required by this exercise.

## 7. Temporal scope

The corpus-wide period of January 1, 2018 through December 31, 2025 is not assigned automatically to each observation.

The following temporal distinctions remain explicit:

- NBPB publication/version context: FY 2026–2027 document.
- NBPB re-entry indicator period: not fully verified in the cited section.
- Dashboard publication description: broad historical coverage described as 2010–2021.
- Dashboard trend period for approximately 9%: not fully verified.
- Pennsylvania 7.8% measure: 21B–22A files.
- Access/retrieval date: August 21, 2026.

No fiscal year, calendar year, dashboard period, or data-profile period is substituted for another.

## 8. Metric/value representation

The value itself may be preserved as a typed percentage/decimal value only when the source-backed value is recorded with its source context and qualification. The value does not carry an inferred denominator or cohort.

The following are prohibited:

```text
8.1% = approximately 9%
Allegheny County re-entry rate = 8.1–9%
implicit denominator derived from the percentage
implicit numerator derived from the percentage
Allegheny County performs better/worse than Pennsylvania
```

The two county observations should remain distinct propositions or source-scoped observations if populated later.

## 9. Known unresolved fields

| Field | Status |
|---|---|
| County NBPB numerator | `UNRESOLVED` / `NOT_STATED` |
| County NBPB numeric denominator | `UNRESOLVED` / `NOT_STATED` |
| County NBPB complete cohort construction | `UNRESOLVED` |
| County NBPB inclusion/exclusion rules | `UNRESOLVED` |
| County NBPB calculation method | `UNRESOLVED` |
| County NBPB underlying profile period | `UNRESOLVED` |
| Dashboard exact filter state | `UNRESOLVED` |
| Dashboard numerator | `UNRESOLVED` |
| Dashboard denominator | `UNRESOLVED` |
| Dashboard export/snapshot | `UNRESOLVED` |
| Relationship between 8.1% and approximately 9% | `UNRESOLVED` |
| County/state comparability | `INSUFFICIENT_INFORMATION` |

These unresolved statuses are not negative factual claims. They describe the current representation boundary.

## 10. Classification and acceptance treatment

| Item | Classification | Treatment |
|---|---|---|
| County NBPB reports 8.1% | `ESTABLISHED` | Preserve as source-scoped direct observation with citation. |
| County NBPB functional definition | `QUALIFIED` | Preserve listed exit destinations and 12-month window; retain missing methodology fields. |
| Dashboard describes approximately 9% | `ESTABLISHED` | Preserve as separate source-scoped trend description. |
| Dashboard exact arithmetic | `UNRESOLVED` | Do not reconstruct or persist an inferred calculation. |
| 8.1% equals approximately 9% | `NOT SUPPORTED` | No source-backed equivalence claim. |
| County denominator | `UNRESOLVED` | Do not use a placeholder or inferred value. |
| Pennsylvania reports 7.8% | `ESTABLISHED` | Preserve separately as statewide source observation. |
| County/state comparison | `NOT SUPPORTED` / `INSUFFICIENT_INFORMATION` | No comparative claim is authored. |
| County pilot selection | `UNRESOLVED` | Charter remains provisional. |

## 11. Research queries and expected behavior

No database population or runtime query execution was performed in this documentation-only phase. The following are the required bounded research probes for a later isolated population test.

### Q1 — County measure

> What re-entry measure is reported for Allegheny County?

Expected:

- Return the 8.1% NBPB observation and, if the dashboard observation is populated, the separate approximately 9% trend observation.
- Preserve separate provenance paths.
- Do not merge values.

### Q2 — Denominator

> What is the denominator for the Allegheny County 8.1% re-entry measure?

Expected:

- Report that the numeric denominator is not established by the available source material.
- Do not fabricate a value.
- Do not return a predicate-only or unrelated denominator claim.

### Q3 — Cohort

> What cohort does the 8.1% measure represent?

Expected:

- Return only the source-supported exit-destination and 12-month information.
- Mark complete cohort construction as unresolved.

### Q4 — County/state comparison

> Is Allegheny County's 8.1% re-entry rate comparable to Pennsylvania's 7.8% rate?

Expected:

```text
capability: INSUFFICIENT_INFORMATION
```

Reason:

- Denominator, cohort construction, calculation method, and reporting period are not sufficiently aligned.

### Q5 — 8.1% versus approximately 9%

> Are Allegheny County's 8.1% and approximately 9% re-entry observations the same measure?

Expected:

```text
capability: INSUFFICIENT_INFORMATION
```

Reason:

- The source material does not establish equivalence.

### Q6 — Bounded knowledge

> What can Berean establish about Allegheny County re-entry?

Expected:

- Return source-backed county observations.
- Separate qualified definitions from unresolved methodology.
- Expose provenance and limitations.

## 12. Negative tests

The following negative assertions must remain absent from any future populated corpus:

```text
8.1% = approximately 9%
Allegheny County re-entry rate = 8.1–9%
8.1% denominator = [inferred number]
Allegheny County performs better than Pennsylvania
Allegheny County performs worse than Pennsylvania
The 8.1% value covers the entire 2018–2025 corpus period
The dashboard's exact filter state is known
The county numerator is known
```

A future corpus-specific validation should fail if any of these are persisted as unsupported claims or returned as established results.

## 13. Schema/architecture observations

The existing generic architecture is sufficient to represent the bounded observations without schema changes:

- `Source`, `Dataset`, `SourceRecord`, and `Citation` preserve source identity and locator context.
- `Evidence` can retain the source observation without promoting it to truth.
- `ClaimEvidence` can preserve support, qualification, or contradiction relationships.
- `Claim` and `Proposition` can retain separate county, dashboard, and statewide observations.
- `TypedValue` can retain the reported percentage without inventing numerator or denominator.
- `Corpus`/`corpus_dataset` can bound the research scope.
- Existing research classifications can distinguish direct, qualified, unresolved, and derived material.

The phase found no architectural reason to add a foster-care-specific table or a new methodology table. The missing fields are source-data limitations and population requirements. If later source records require richer structured metric metadata than the existing generic model can faithfully preserve, that deficiency must be demonstrated with a concrete failing case before any schema change is considered.

## 14. Limitations

1. This phase documents the bounded population design; it does not create database rows.
2. The exact dashboard state and arithmetic remain unavailable.
3. The county NBPB's functional definition does not expose all operational cohort rules.
4. The relationship between 8.1% and approximately 9% remains unresolved.
5. The Pennsylvania 7.8% value remains separate and is not compared to the county values.
6. No source content was downloaded or ingested.
7. Runtime research probes and repository validation commands were not executed in this documentation-only write operation because no database population or executable test changes were made.

## 15. Pilot-status determination

```text
PILOT_REVIEW_REQUIRED
```

The source material is suitable for a bounded provenance test, but the charter's county-selection decision remains provisional. This phase does not authorize `PILOT_SELECTED`.

## 16. Change-control statement

- **Created:** `COUNTY_BOUNDED_PROVENANCE_POPULATION.md`.
- **Modified:** No existing corpus documents.
- **`CORPUS_CHARTER.md`:** unchanged.
- **`SOURCE_INVENTORY.csv`:** unchanged.
- **Downloaded source documents:** none.
- **Source records/evidence/claims/propositions:** none created.
- **Application code:** unchanged.
- **Schema/migrations:** unchanged.
- **Ingestion code/manifests:** unchanged.
- **Fixtures/tests/validation scripts:** unchanged.
