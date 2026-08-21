# Allegheny County Re-Entry Measure Reproducibility and Semantic Verification

**Review date:** August 21, 2026  
**Corpus:** `pa-foster-care-placement-reunification`  
**Candidate county:** Allegheny County, Pennsylvania  
**Prior pilot determination:** `PILOT_REVIEW_REQUIRED`  
**Measure determination:** `COUNTY_MEASURE_PARTIALLY_REPRODUCIBLE`

## 1. Research question

> Can the Allegheny County 9% re-entry observation be independently reconstructed, precisely defined, and provenance-preservingly represented?

The answer is **partially**.

The public county material supports a precise source-backed observation of **8.1%** in the FY 2026–2027 Needs-Based Plan and Budget and separately describes the dashboard trend as “about 9%.” The exact 9% observation cannot be independently reconstructed from the public material reviewed because no numerator, denominator, underlying cohort file, calculation table, or reproducible dashboard export was identified. The 8.1% indicator is semantically more precise than the earlier 9% description, but its underlying denominator and profile period remain unstated in the cited county section.

## 2. Materials inspected

The review used the following corpus documents and public source records:

- `CORPUS_CHARTER.md`.
- `SOURCE_INVENTORY.csv`.
- `COUNTY_PILOT_SOURCE_REVIEW_ALLEGHENY.md`.
- `COUNTY_PILOT_SOURCE_RECORD_VERIFICATION.md`.
- `COUNTY_PILOT_FOLLOWUP_VERIFICATION.md`.
- Allegheny County `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- Allegheny Analytics `Child Welfare Out-of-Home Placements: Interactive Dashboard` publication page.
- Pennsylvania `2026 Annual Progress and Services Report`.
- Berean domain and workflow documentation.

No source artifact was added to `data/corpora/`. No source record, evidence, claim, or proposition was persisted.

## 3. Original 9% observation

### 3.1 What the public record actually supports

The Allegheny Analytics dashboard publication page states that the dashboard covers Allegheny County out-of-home placements from 2010 through 2021 and includes exits and how many children returned to the child-welfare system after returning home, described as re-entries. It also states that the dashboard is updated annually when a full year of data becomes available. citeturn3view0

The FY 2026–2027 county NBPB narrative states that the dashboard indicates re-entries within one year have remained steady at approximately 9% over time. The same NBPB provides a more specific county indicator: **8.1%** of children and youth re-entered within 12 months of exit, against a 5.6% national performance standard. citeturn2view0turn3view1

Therefore, the materials contain two different representations:

1. **Dashboard trend description:** approximately 9% over time.
2. **County NBPB indicator:** 8.1% for the county's stated re-entry indicator.

They must not be silently normalized into one value.

### 3.2 Exact county NBPB indicator

- **Title:** `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- **Issuer:** Allegheny County Department of Human Services, Office of Children, Youth and Families.
- **Document type:** Public county needs-based plan and budget narrative.
- **Public source URL:** `https://analytics.alleghenycounty.us/wp-content/uploads/2025/09/NBB02_26-27_Narrative.pdf`.
- **Document period:** FYs 2024–25, 2025–26, and 2026–27; the narrative also reports historical measures.
- **Access/review date:** August 21, 2026.
- **Geographic scope:** Allegheny County.
- **Exact locator:** PDF page 69, section `2-3f Re-entry (in 12 Months)`; analysis continues on pages 70–71.
- **Metric wording:** The indicator measures the percentage of children and youth who re-enter care within 12 months of discharge to reunification, living with a relative, or guardianship.
- **Published value:** 8.1%.
- **Unit:** Percentage.
- **Numerator:** Not stated.
- **Denominator:** The eligible exit population is described conceptually, but a numeric denominator is not stated.
- **Cohort definition:** Children and youth discharged to reunification, living with a relative, or guardianship, followed for re-entry within 12 months, as stated by the indicator description.
- **Inclusion/exclusion criteria:** No complete operational inclusion or exclusion table was identified in the cited section.
- **Definition of re-entry:** Re-entry into care within 12 months after the listed discharge destinations, as stated by the county indicator description.
- **Qualifications:** The county separately analyzes JPO involvement, sex, and race. It reports 4.5% for children not involved in JPO and 35.6% for JPO-involved youth; these are subgroup measures, not substitutes for the overall 8.1% value. citeturn2view0
- **Methodological notes:** The cited section does not identify a numerator, denominator, extraction file, confidence interval, or underlying data-profile period.
- **Limitations:** The NBPB is a planning narrative. It provides a source-backed reported indicator but not enough information to reproduce the arithmetic independently.

### 3.3 Calculation reconstruction

The public material reviewed does not provide both numerator and denominator for the exact 8.1% county indicator, and it does not provide numerator and denominator for the dashboard's approximate 9% trend description.

Accordingly:

```text
9% = numerator / denominator

RECONSTRUCTION STATUS: NOT POSSIBLE FROM REVIEWED PUBLIC MATERIAL
```

No numerator or denominator is inferred from the percentage. No rounding explanation can be established. No alternative calculation is substituted for the source's reported value.

## 4. Meaning of “re-entry”

The county NBPB explicitly defines the indicator as re-entry within 12 months after discharge to reunification, living with a relative, or guardianship. citeturn2view0

The public record reviewed establishes:

- A prior discharge/exit is required.
- The discharge destinations are limited to reunification, living with a relative, or guardianship.
- The follow-up window is 12 months.
- The unit is a percentage of the defined exit cohort.

The public record does **not** establish:

- The numerator count.
- The denominator count.
- Whether the cohort is based on discharge date, a data-profile period, or another extraction rule.
- Whether the measure counts every subsequent re-entry or only the first re-entry.
- Whether the same agency/system boundary is required.
- The exact source system or file used for the county calculation.
- The treatment of edge cases, missing records, transfers, or multiple exits.

The following statuses therefore apply:

- `PRIOR_EXIT_REQUIRED`: Established by the county indicator wording.
- `12_MONTH_FOLLOW_UP`: Established by the county indicator wording.
- `EXIT_DESTINATIONS_SPECIFIED`: Established by the county indicator wording.
- `NUMERATOR_NOT_STATED`: Applies.
- `DENOMINATOR_NOT_STATED`: Applies numerically.
- `COHORT_PARTIALLY_STATED`: Applies.
- `FULL_OPERATIONAL_DEFINITION_NOT_STATED`: Applies.

## 5. Dashboard reproduction

### 5.1 Dashboard source metadata

- **Exact dashboard title:** `Child Welfare Out-of-Home Placements: Interactive Dashboard`.
- **Publication issuer:** Allegheny County Department of Human Services / Allegheny Analytics.
- **Publication page:** `https://analytics.alleghenycounty.us/2021/01/07/child-welfare-placement-interactive-dashboard/`.
- **Publication date:** January 7, 2021.
- **Dashboard URL:** The publication page links to the Tableau dashboard at `https://tableau.alleghenycounty.us/` and identifies the direct dashboard access path.
- **Dashboard scope:** Allegheny County out-of-home placements.
- **Published period:** 2010 through 2021.
- **Available subject areas:** Point-in-time counts, placement characteristics, placement types, length of stay, exits, and re-entries after returning home. citeturn3view0

### 5.2 Re-entry dashboard state

The county NBPB references a Tableau `Re-entry` view and separately discusses CY 2023 exit destinations and one-year re-entry rates. The public publication page identifies the dashboard's broad subject and period, but the reviewed public HTML and source text do not expose a complete reproducible state containing all of the following:

```text
Geography: Allegheny County
Measure: Re-entry
Cohort: not fully exposed
Period: not fully exposed for the approximately 9% trend
Other filters: not fully exposed
Numerator: not displayed in the reviewed publication page
Denominator: not displayed in the reviewed publication page
Export filename/checksum: not available in the reviewed material
Refresh/version identifier: not available in the reviewed material
```

The NBPB does provide additional county observations for children exiting in CY 2023: 56% returned to family, 19% were adopted, and 17% had a permanent legal custodian; it reports one-year re-entry rates of 15% for children returning to family, 1% for permanent legal custody, and 0% for adoption. These are separate exit-destination observations and do not independently reconstruct the approximately 9% trend or the 8.1% overall indicator. citeturn3view1

### 5.3 Dashboard reproduction result

```text
DASHBOARD_VIEW_IDENTIFIED: YES
DASHBOARD_TOPIC_IDENTIFIED: YES
DASHBOARD_PERIOD_DESCRIPTION_IDENTIFIED: YES
EXACT_FILTER_STATE_REPRODUCED: NO
NUMERATOR_DISPLAYED: NO
DENOMINATOR_DISPLAYED: NO
EXPORT_OR_SNAPSHOT_VERIFIED: NO
EXACT_9_PERCENT_REPRODUCED: NO
```

The dashboard independently substantiates that Allegheny County publishes a re-entry view, but it does not independently reproduce the exact 9% value in this phase.

## 6. Reproducibility assessment

| Requirement | Result | Reason |
|---|---|---|
| Exact source identified | PASS | County NBPB and dashboard publication page are attributable and publicly located. |
| Exact 9% wording identified | PARTIAL | The NBPB describes the dashboard trend as approximately 9% over time. |
| Exact 8.1% county indicator identified | PASS | NBPB page 69 reports the indicator and value. |
| Numerator identified | FAIL | Not stated in reviewed public material. |
| Denominator identified | FAIL | Numeric denominator not stated. |
| Cohort identified | PARTIAL | Exit destinations and 12-month follow-up are stated; full construction is not. |
| Re-entry definition identified | PARTIAL | Functional definition is stated; full operational methodology is not. |
| Arithmetic reconstructed | FAIL | Numerator and denominator are unavailable. |
| Dashboard view identified | PASS | Public dashboard page and re-entry view are identified. |
| Dashboard filters reproduced | FAIL | Complete filter state not exposed or independently captured. |
| Dashboard export verified | FAIL | No export file, timestamp, checksum, or downloadable table was verified. |
| Provenance-preserving representation possible | PASS | Berean can preserve the reported values, source distinctions, citations, and limitations without asserting a comparative truth. |

## 7. Berean representation assessment

The current Berean model can represent the result without schema redesign.

The recommended representation is:

```text
Source: Allegheny County DHS / Allegheny Analytics
Dataset: FY 2026-27 Needs-Based Plan & Budget
SourceRecord: public PDF
Citation: page 69, section 2-3f
Evidence: county document reports 8.1% re-entry within 12 months
Claim: DIRECT_SOURCE_CLAIM, source-scoped
Proposition: county re-entry indicator → typed DECIMAL value 8.1
Qualification: denominator/profile period/methodology not stated
```

The dashboard should be represented separately:

```text
Source: Allegheny County DHS / Allegheny Analytics
Dataset: Child Welfare Out-of-Home Placements dashboard
SourceRecord: dashboard publication page or versioned dashboard observation
Citation: dashboard page/view locator
Evidence: dashboard publishes county re-entry subject and period coverage
Claim: source-scoped dashboard availability or view-description claim
Limitation: exact metric state and denominator not reproduced
```

The value `8.1%`, the dashboard description “about 9%,” subgroup values, and any later dashboard observation must remain distinct evidence/claim objects. Berean's workflow architecture requires source records and citations to remain authoritative, while evidence, claims, and propositions preserve their separate epistemic roles. The model explicitly distinguishes source, source record, citation, evidence, claim, and truth; it also permits locator-only storage when raw content is not retained. citeturn1view0turn1view2turn1view3

No new schema concept is justified by this phase. The missing denominator, cohort metadata, and dashboard-state capture are source-verification and population requirements, not demonstrated architectural failures.

## 8. Semantic risks

1. **Approximation risk:** “About 9%” is not interchangeable with the NBPB's 8.1% indicator.
2. **Denominator risk:** No numeric denominator is available for independent reconstruction.
3. **Cohort risk:** The functional exit destinations are stated, but the complete cohort construction is not.
4. **Period risk:** The dashboard publication page covers 2010–2021, while the NBPB is a FY 2026–2027 document containing historical and CY 2023 observations.
5. **Dashboard-state risk:** A page describing a dashboard is not the same as a captured dashboard observation.
6. **Subgroup risk:** JPO, sex, race, and exit-destination subgroup rates must not be treated as the overall county rate.
7. **Rounding risk:** The public record does not establish whether 9% is a rounded display of 8.1%, a separate trend summary, or a value from another dashboard state.
8. **Scope risk:** County observations must not be promoted to Pennsylvania-wide observations.
9. **Causation risk:** The subgroup differences do not establish why the overall rate has the reported value.
10. **Privacy risk:** Future dashboard exports must be screened to ensure aggregate output does not expose individual-level information.

## 9. Determination

# COUNTY_MEASURE_PARTIALLY_REPRODUCIBLE

The public record is sufficient to identify and provenance-preservingly represent the county's 8.1% re-entry indicator and the dashboard's approximate 9% trend description. It is not sufficient to reconstruct the exact arithmetic or independently reproduce the dashboard value because the numerator, numeric denominator, full cohort construction, underlying profile period, and complete dashboard state are not available in the reviewed material.

The exact 9% observation is therefore **not independently reproducible** in this phase, but the broader county measure is not semantically unresolved: its functional definition and source context are sufficiently stated for a qualified source-backed representation.

## 10. Effect on pilot determination

The county pilot remains:

```text
PILOT_REVIEW_REQUIRED
```

This phase does not authorize formal selection of Allegheny County. The county has a usable public source for a provenance and semantic-boundary test, but the evidence does not satisfy a stronger claim of independently reproducible county performance measurement.

## 11. Recommended next step

Proceed in one of two controlled ways:

1. **Source-acquisition follow-up:** obtain a public county methodology appendix, underlying aggregate extract, or reproducible dashboard export that supplies the numerator, denominator, cohort dates, source system, and dashboard state; or
2. **Bounded provenance pilot:** register the NBPB and dashboard as source records with explicit limitations, create only source-scoped observations, and use the unresolved denominator/profile period as an intentional validation case.

Do not create a derived county-versus-state comparison from 8.1%, 9%, or 7.8% unless the missing dimensions are resolved.

## 12. Change control

- **New document:** `COUNTY_MEASURE_REPRODUCIBILITY.md`.
- **`CORPUS_CHARTER.md`:** unchanged.
- **`SOURCE_INVENTORY.csv`:** unchanged.
- **Downloaded corpus documents:** none added.
- **Source records/evidence/claims:** none persisted.
- **Application/schema/ingestion/fixture/test code:** none modified.
