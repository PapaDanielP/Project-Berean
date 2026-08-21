# Allegheny County Source-Record Verification and First County-versus-State Comparability Test

**Review status:** Complete — source-record verification performed without corpus ingestion  
**Review date:** August 21, 2026  
**Candidate county:** Allegheny County, Pennsylvania  
**Corpus:** `pa-foster-care-placement-reunification`  
**Corpus period:** January 1, 2018 through December 31, 2025  
**Formal determination:** `PILOT_REVIEW_REQUIRED`

## 1. Scope

This phase verified the two county-level candidates identified in `COUNTY_PILOT_SOURCE_REVIEW_ALLEGHENY.md`:

1. Allegheny County FY 2026–2027 Needs-Based Plan and Budget.
2. Allegheny County Child Welfare Out-of-Home Placements: Interactive Dashboard.

It also tested one county measure against one Pennsylvania statewide measure. The review establishes source metadata and comparability conditions only. It does not establish that any county or statewide claim is true, does not rank Allegheny County, and does not authorize the county pilot.

No source documents were downloaded into `data/corpora/`, no source records were ingested, and no application, schema, ingestion, fixture, validation, or test code was modified.

## 2. Sources reviewed

### 2.1 Allegheny County FY 2026–2027 Needs-Based Plan and Budget

- **Exact title:** `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- **Issuing organization:** Allegheny County Department of Human Services.
- **Source type:** County needs-based plan and budget / public planning document.
- **Stable source page:** Allegheny County Needs-Based Plan and Budget archive.
- **Document locator:** The county archive identifies the `2026 to 2027 Plan (PDF, 2MB)` under the SFY 2026–2027 archive.
- **Publication/reporting period:** The document is a state-fiscal-year planning document for SFY 2026–2027 and contains retrospective measures from earlier fiscal and calendar periods.
- **Geographic scope:** Allegheny County.
- **Relevant topics:** Placement stability, family-like placement settings, kinship placement, permanency, family preservation, removals, duration, and re-entry.
- **Verified metric:** The county document states that, from FY 2018–2019 through FY 2022–2023, 33% of home removals (4,658 removals) were associated with adult drug or alcohol use; for children under five, 43% (1,909 removals) were associated with adult drug or alcohol use. It further states that removals associated with adult drug or alcohol use lasted an average of 117 days longer than other removals and that the children re-entered care at a rate of 30%, compared with an overall Allegheny County re-entry rate of 9%.
- **Denominator:** The document provides denominators for the removal percentages through counts and percentages. The denominator for the 30% and 9% re-entry rates is not stated in the quoted passage; the document footnote states that the duration and re-entry statistics are for FY 2018–2019 through FY 2020–2021.
- **Metric definition:** The document does not, in the reviewed passage, reproduce the full operational definition of “re-entered care” or define the complete eligible exit cohort. The source terminology must be preserved.
- **Unit:** Percent for removal association and re-entry rates; days for the duration difference; count for removals.
- **Qualifications:** The re-entry and duration statistics are limited to FY 2018–2019 through FY 2020–2021, even though the surrounding narrative discusses a broader FY 2018–2019 through FY 2022–2023 period for removal association.
- **Limitations:** This is a planning narrative, not a dedicated county performance dataset. It mixes fiscal periods and contextual program discussion. The quoted county re-entry values cannot be treated as directly comparable to a statewide value without aligning cohort, denominator, period, and definition.
- **Source-backed claim suitability:** Yes, for a narrowly scoped claim such as “the Allegheny County NBPB reports an overall re-entry rate of 9% for the specified source period.” No, for an unqualified claim that Allegheny County’s re-entry rate was 9% during the entire 2018–2025 corpus period.

### 2.2 Allegheny County Child Welfare Out-of-Home Placements: Interactive Dashboard

- **Exact title:** `Child Welfare Out-of-Home Placements: Interactive Dashboard`.
- **Issuing organization:** Allegheny County Department of Human Services / Allegheny Analytics.
- **Source type:** Public interactive dashboard.
- **Stable source page:** Allegheny Analytics dashboard publication page.
- **Publication date:** January 7, 2021.
- **Reporting/observation period:** The publication page states that the dashboard provides an overview of Allegheny County child-welfare out-of-home placements from 2010 through 2021.
- **Geographic scope:** Allegheny County.
- **Relevant topics:** Yearly point-in-time counts, characteristics of children in placement, placement types, length of stay, exits, and re-entries after returning home.
- **Population/cohort:** The publication page identifies children in child-welfare out-of-home placements for the point-in-time and placement analyses. The exact denominator and cohort for each dashboard view are view-specific and are not exposed by the publication page alone.
- **Dashboard state/filter:** The public publication page links to the dashboard and identifies the scope, but the reviewed HTML does not expose a reproducible filter state, downloadable table, dashboard version identifier, or exact view-level locator for a particular metric value.
- **Denominator:** Not stated at the publication-page level. Any future observation must record the dashboard tab, filters, date accessed, displayed population, denominator, and export/snapshot metadata if available.
- **Metric definition:** The publication page describes the dashboard categories but does not provide the full operational definitions for every view.
- **Unit:** Likely counts, placement categories, durations, and re-entry measures depending on the selected dashboard view; the exact unit must be recorded per view and is not assumed here.
- **Qualifications:** The page states that the dashboard is updated annually when a full year of data becomes available.
- **Limitations:** It is a dynamic dashboard rather than a static versioned report. The current verification phase did not establish a reproducible observation of a specific county value from a specified dashboard state.
- **Source-backed claim suitability:** Yes, for a source-availability claim that the dashboard covers the stated county subject and period. Not yet for a specific metric-value claim without view-level reproduction metadata.

### 2.3 Pennsylvania statewide comparison source

- **Exact title:** `Pennsylvania 2026 Annual Progress and Services Report`.
- **Issuing organization:** Pennsylvania Department of Human Services, Office of Children, Youth, and Families.
- **Source type:** State Annual Progress and Services Report / official statewide performance report.
- **Publication/reporting period:** The report contains statewide data profiles and reporting-cycle values, including periods expressed as A/B data-profile periods rather than a single calendar year.
- **Geographic scope:** Pennsylvania statewide.
- **Selected statewide measure:** `SWDI on Reentry to Foster Care in 12 Months`.
- **Definition:** The report defines this as the percentage of children who re-entered care within 12 months of discharge, among children who exit foster care in a 12-month period to reunification, living with a relative, or guardianship.
- **Statewide value used for test:** The report gives a Pennsylvania RSP value of 7.8% for the 21B–22A files, with an RSP interval of 7%–8.6%. It also states that the more recent 22A–23B and later data had data-quality issues and were not calculated in the relevant profile sequence.
- **Denominator:** The report defines the denominator conceptually as children exiting foster care in the 12-month period to reunification, living with a relative, or guardianship. The report's statewide measure is therefore not an unrestricted percentage of all children in placement.
- **Unit:** Percentage.
- **Exact locator:** Pennsylvania 2026 APSR, pages 29–30, Table 18 and the accompanying SWDI definition.
- **Qualifications:** The report identifies data-quality issues in later data and distinguishes the 21B–22A period from later DQ periods.
- **Limitations:** The statewide value is not from the same period as the county NBPB re-entry values and the county source's complete denominator/cohort definition has not been verified in this phase.

## 3. Measure under comparison

The first test compares re-entry within 12 months:

| Scope | Source measure | Value | Period |
|---|---|---:|---|
| Allegheny County | County-reported overall re-entry rate | 9% | FY 2018–2019 through FY 2020–2021, according to the county document footnote |
| Pennsylvania statewide | SWDI on Reentry to Foster Care in 12 Months, RSP value | 7.8% | 21B–22A files, according to Pennsylvania Table 18 |

The county source also reports a 30% re-entry rate for children whose removals were associated with adult drug or alcohol use. That subgroup value is **not** used as the primary county-versus-state comparison because it is not the same population as the statewide SWDI denominator.

## 4. Comparability matrix

| Dimension | County | Statewide | Comparable? |
|---|---|---|---|
| Geographic scope | Allegheny County | Pennsylvania statewide | PARTIALLY_COMPARABLE — geographic scopes are explicit but different. |
| Population/cohort | County document reports an overall county re-entry rate and a subgroup rate for removals associated with adult drug/alcohol use; exact eligible exit cohort is not fully reproduced in the reviewed passage. | Children exiting foster care in a 12-month period to reunification, living with a relative, or guardianship. | NOT_ESTABLISHED — the county overall rate may be conceptually related, but cohort equivalence is not verified. |
| Denominator | The quoted county passage does not state the denominator for the 9% overall rate or 30% subgroup rate. | Defined by the SWDI measure as the specified exit cohort. | NOT_ESTABLISHED. |
| Metric definition | “Reentered care” as reported in the county NBPB; full operational definition not verified in this phase. | Explicit SWDI definition for re-entry within 12 months. | NOT_ESTABLISHED. |
| Unit | Percentage. | Percentage. | COMPARABLE at unit level only. |
| Reporting period | FY 2018–2019 through FY 2020–2021 for the county re-entry statistics. | 21B–22A files for the reported 7.8% RSP value. | PARTIALLY_COMPARABLE — both are multi-period measures, but the periods are not the same and are not mapped here. |
| Period type | County: state fiscal years. | State: AFCARS/NCANDS data-profile period notation. | NOT_ESTABLISHED. |
| Qualifications | County footnote limits duration/re-entry statistics to FY 2018–2019 through FY 2020–2021. | State report notes DQ issues in later periods and reports an RSP interval. | PARTIALLY_COMPARABLE — both have qualifications, but they are not equivalent. |
| Limitations | County source is a planning narrative and does not expose the full denominator/methodology in the reviewed passage. | State measure has a defined cohort but later data-quality limitations. | NOT_ESTABLISHED. |

## 5. Provenance observations

### County NBPB

- **Source:** Allegheny County Department of Human Services.
- **Dataset/document:** FY 2026–2027 Needs-Based Plan and Budget.
- **Source record:** The complete PDF should be registered later as a single source record only after its stable locator, revision, access date, and permitted storage treatment are recorded.
- **Citation locator:** Page 6 of the public PDF for the quoted removal, duration, and re-entry passage; footnote 5 on page 6 identifies the FY 2018–2019 through FY 2020–2021 period for the duration and re-entry statistics.
- **Evidence distinction:** The observation should be stored as what the county document reports, not as an independently verified statewide fact.

### County dashboard

- **Source:** Allegheny County DHS / Allegheny Analytics.
- **Dataset/document:** Child Welfare Out-of-Home Placements: Interactive Dashboard.
- **Source record:** The publication page and the linked dashboard should be represented separately if the dashboard is later populated: the page is explanatory metadata; a dashboard observation would require its own view/filter/access metadata.
- **Citation locator:** Publication page, dashboard description, and direct dashboard link. No specific metric observation was persisted in this phase.

### Pennsylvania APSR

- **Source:** Pennsylvania DHS / OCYF.
- **Dataset/document:** Pennsylvania 2026 Annual Progress and Services Report.
- **Citation locator:** Pages 29–30, Table 18, `SWDI on Reentry to Foster Care in 12 Months`.
- **Evidence distinction:** The statewide 7.8% value is a source-reported RSP value for the stated data-profile period, not a general Pennsylvania re-entry fact for all years.

## 6. Semantic risks

1. **Denominator mismatch:** The county document does not expose the complete denominator in the reviewed passage, while the statewide report defines its denominator explicitly.
2. **Cohort mismatch:** The county document includes an overall rate and a subgroup rate associated with adult drug/alcohol use; the statewide measure uses a specified exit-to-reunification/relative/guardianship cohort.
3. **Definition mismatch:** “Re-entry” is not assumed to have identical operational definitions across the documents.
4. **Period mismatch:** County statistics cover FY 2018–2019 through FY 2020–2021; the statewide 7.8% value is for 21B–22A files.
5. **Period-type mismatch:** County values use state fiscal years; statewide values use data-profile periods based on AFCARS/NCANDS files.
6. **Scope leakage:** A county value must not be attached to Pennsylvania statewide claims, and a statewide value must not be attached to Allegheny County.
7. **Unsupported inference:** The difference between 9% and 7.8% must not be described as a performance difference without verified cohort and method equivalence.
8. **Dashboard-state ambiguity:** The dashboard publication page exposes the broad period and topic coverage but not a reproducible metric-level filter state or denominator.
9. **Planning-document limitation:** The NBPB is a planning and funding document, not necessarily a canonical statistical release for every measure it mentions.

## 7. Berean representation assessment

The existing Berean architecture can represent this verification result without schema changes:

- County and Pennsylvania can be distinct entities or scoped source/dataset contexts.
- The county NBPB and Pennsylvania APSR can be distinct sources, datasets, source records, and citations.
- The two reported percentages can be represented as separate typed values attached to separate propositions.
- Reporting periods can remain distinct through source records, citations, typed temporal values, and source-backed claim metadata/conventions.
- The 30% subgroup and 9% overall county values can remain separate propositions rather than being collapsed.
- Evidence can support, qualify, or contradict claims without creating a truth value.
- The dashboard can remain a source-availability record until a reproducible view-level observation is verified.

The current architecture does not automatically supply a native denominator, cohort, or dashboard-filter field on every typed value. Those are controlled modeling and ingestion requirements for the next phase, not demonstrated reasons to redesign the schema. The comparison should therefore remain `PARTIALLY_COMPARABLE`/`NOT_ESTABLISHED`, rather than being promoted to a direct comparative claim.

## 8. Determination

# PILOT_REVIEW_REQUIRED

The review identified a legitimate county measure and a legitimate statewide measure concerning re-entry within 12 months, but the evidence does not establish sufficient equivalence of denominator, cohort, metric definition, and period for a defensible county-versus-state comparison. The county dashboard also lacks a reproducible metric-level observation in this phase.

The strongest conclusion supported now is:

> Allegheny County and Pennsylvania both publish public child-welfare re-entry measures, but the current source records do not establish that the reported percentages are directly comparable.

That is a source-availability and comparability finding, not a performance conclusion.

## 9. Recommendation

Do not formally select Allegheny County yet.

Proceed with a narrow source-record verification follow-up:

1. Register the county NBPB and Pennsylvania APSR as candidate source records without ingesting claims.
2. Capture the complete county citation and any county methodology/footnote defining the 9% rate.
3. Reproduce one dashboard view, recording its filters, access date, displayed cohort, denominator, and export/snapshot metadata.
4. Match one county measure to one statewide measure only if all comparison dimensions can be documented.
5. Reassess the pilot determination after that evidence is available.

## 10. Change control

- **`SOURCE_INVENTORY.csv`:** Not changed. The two candidates were reviewed, but the inventory does not yet contain complete verified county source-record metadata and no source was marked selected.
- **`CORPUS_CHARTER.md`:** Unchanged. The county pilot remains provisional.
- **Downloaded corpus documents:** None added.
- **Application/schema/ingestion/fixture/test code:** None modified.
- **Review document created:** `COUNTY_PILOT_SOURCE_RECORD_VERIFICATION.md`.
