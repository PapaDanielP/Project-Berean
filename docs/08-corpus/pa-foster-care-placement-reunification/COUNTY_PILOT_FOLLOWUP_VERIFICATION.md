# Allegheny County Pilot Follow-Up Verification

**Review date:** August 21, 2026  
**Corpus:** `pa-foster-care-placement-reunification`  
**Candidate county:** Allegheny County, Pennsylvania  
**Prior determination:** `PILOT_REVIEW_REQUIRED`  
**Follow-up determination:** `PILOT_REVIEW_REQUIRED`

## 1. Purpose and scope

This follow-up addresses the two unresolved items from `COUNTY_PILOT_SOURCE_RECORD_VERIFICATION.md`:

1. Verify the complete county citation and denominator/definition for the re-entry measure.
2. Reproduce a dashboard-level observation sufficiently to identify the view, period, and displayed population.

The follow-up used public official Allegheny County/Allegheny Analytics and Pennsylvania DHS/OCYF sources. It did not download source artifacts into `data/corpora/`, create source records, ingest evidence, modify the charter, or change application/schema/ingestion/test code.

## 2. Corrected county source finding

The prior verification document described a county 9% re-entry value from the FY 2026–2027 NBPB narrative. The complete public PDF provides a more precise current county value:

> Allegheny County's re-entry rate after reunification is **8.1%**.

The document defines the indicator at the county section as the percentage of children and youth who re-enter care within 12 months of discharge to reunification, living with a relative, or guardianship. It states that the national performance standard is 5.6%, and identifies the county value as 8.1%.

The same document reports that, among the county's re-entry population, children not involved in JPO had a 4.5% re-entry rate and JPO-involved youth had a 35.6% rate. These are subgroup observations and must not be substituted for the overall county measure.

### County source metadata

- **Title:** `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- **Issuing organization:** Allegheny County Department of Human Services, Office of Children, Youth and Families.
- **Source type:** Public county needs-based plan and budget narrative.
- **Source URL:** `https://analytics.alleghenycounty.us/wp-content/uploads/2025/09/NBB02_26-27_Narrative.pdf`.
- **Version dates:** Original submission August 15, 2025; Version 2 submission August 18, 2025.
- **Document period:** FYs 2024–25, 2025–26, and 2026–27 are named in the document header; the document reports historical and current measures from other periods.
- **Geographic scope:** Allegheny County.
- **Exact locator for indicator definition/value:** PDF page 69, section `2-3f Re-entry (in 12 Months)`; PDF pages 69–70 for the national standard and county 8.1% value.
- **Additional analysis locator:** PDF pages 70–71 for JPO/CYF, sex, and race subgroup analysis.
- **Unit:** Percentage.
- **Population/cohort:** Children and youth discharged to reunification, living with a relative, or guardianship, as stated by the county indicator definition.
- **Denominator:** The document describes the denominator population conceptually but does not provide a numeric denominator in the cited section.
- **Definition:** Re-entry into care within 12 months after discharge to the listed permanent or family-based exit destinations.
- **Qualification:** The county compares its result with the 5.6% national performance standard and separately reports data by JPO involvement, race, and sex.
- **Limitation:** The cited section does not expose the numerator, denominator, extraction file, confidence interval, or exact data-profile period underlying 8.1%. The value is source-backed as a county-reported measure, not independently recalculated here.

## 3. Dashboard observation and reproducibility

The FY 2026–2027 NBPB narrative identifies the public dashboard view used for the county's placement analysis:

- **Dashboard publication page:** `https://alleghenycountyanalytics.us/2021/01/07/child-welfare-out-of-home-placements-interactive-dashboard/`.
- **Dashboard description:** The dashboard provides filterable Allegheny County out-of-home-placement data from 2010 through 2021 and is updated annually.
- **Re-entry view URL cited by the county document:** `https://tableau.alleghenycounty.us/t/PublicSite/views/AlleghenyCountyChildWelfarePlacementInformation/Re-entry` with the share-link parameters shown in the PDF footnote.
- **Dashboard view:** `Re-entry`.
- **County document's displayed period:** The NBPB states that the dashboard indicates re-entries within one year have remained steady at about 9% over time. It also states that among children who exited in CY 2023, 56% returned to family, 19% were adopted, and 17% had a permanent legal custodian; children who returned to family had a 15% re-entry rate within one year, compared with 1% for PLC and 0% for adoption.
- **Dashboard filters:** The public share URL identifies the `Re-entry` view but does not encode a full visible filter state in the retrieved source text. The NBPB narrative identifies CY 2023 for the exit-destination analysis, but the underlying dashboard filter selections were not independently reproduced in this follow-up.
- **Dashboard denominator:** Not independently exposed by the retrieved dashboard publication page or share URL.
- **Dashboard conclusion:** A dashboard view and a county-reported CY 2023 observation are identifiable, but a fully reproducible dashboard-state record with visible filters, denominator, and export checksum was not established.

The dashboard therefore supplies stronger source and view identity than the previous review, but it does not yet satisfy full metric-level reproducibility for ingestion.

## 4. Statewide comparison measure

The selected statewide comparator remains the Pennsylvania statewide re-entry indicator:

- **Title:** `Pennsylvania 2026 Annual Progress and Services Report`.
- **Issuing organization:** Pennsylvania Department of Human Services, Office of Children, Youth, and Families.
- **Source URL:** `https://www.pa.gov/content/dam/copapwp-pagov/en/dhs/documents/docs/publications/documents/child-youth-and-family-service-plan/2026-annual-progress-services-report-apsr.pdf`.
- **Exact locator:** PDF pages 29–30, Table 18, `SWDI on Reentry to Foster Care in 12 Months`.
- **Definition:** Percentage of children who re-entered care within 12 months of discharge, among children who exit foster care in a 12-month period to reunification, living with a relative, or guardianship.
- **Statewide value:** Pennsylvania RSP value 7.8% for the 21B–22A files, with RSP interval 7%–8.6%.
- **Unit:** Percentage.
- **Data source:** AFCARS and NCANDS, February 2025 profile.
- **Qualification:** Later profile periods are marked DQ in the table, and the report states that data-quality issues are being addressed.

## 5. First refined comparison

The two documents now have materially similar stated indicator language:

| Scope | Measure | Value | Stated definition | Period |
|---|---|---:|---|---|
| Allegheny County | Re-entry in 12 months | 8.1% | Children/youth re-entering within 12 months after discharge to reunification, living with a relative, or guardianship | County NBPB indicator; exact underlying profile period not stated in the cited section |
| Pennsylvania | SWDI re-entry in 12 months | 7.8% | Children re-entering within 12 months after exit to reunification, living with a relative, or guardianship | 21B–22A files |

This is an improvement over the prior 9%/7.8% comparison because the county definition is now explicitly aligned in wording with the statewide SWDI definition. It is still not a direct comparison because the county denominator and exact data-profile period remain unstated in the cited section, and the source methodologies/data systems have not been verified as identical.

## 6. Comparability matrix

| Dimension | County | Statewide | Result |
|---|---|---|---|
| Geographic scope | Allegheny County | Pennsylvania statewide | PARTIALLY_COMPARABLE; scopes remain distinct. |
| Population/cohort | Children/youth discharged to reunification, relative care, or guardianship | Children exiting foster care to reunification, relative care, or guardianship | PARTIALLY_COMPARABLE; wording aligns, but county cohort construction is not independently documented. |
| Denominator | Conceptually described; numeric denominator not stated | Conceptually defined by SWDI; numeric denominator not supplied in report table | PARTIALLY_COMPARABLE. |
| Metric definition | Re-entry within 12 months after listed exit destinations | Same stated SWDI definition | PARTIALLY_COMPARABLE; semantic wording aligns, methodology equivalence is not established. |
| Unit | Percentage | Percentage | COMPARABLE at unit level. |
| Reporting period | County NBPB indicator period not stated in the cited section; CY 2023 is separately identified for dashboard exit-destination analysis | 21B–22A files | NOT_ESTABLISHED. |
| Period type | County NBPB/county dashboard period conventions; fiscal and calendar references coexist | AFCARS/NCANDS data-profile period | NOT_ESTABLISHED. |
| Qualifications | County reports JPO, race, and sex subgroup differences and compares to national standard | State report records RSP interval and later DQ periods | PARTIALLY_COMPARABLE. |
| Limitations | No numeric denominator, numerator, interval, or underlying profile period in the cited county section | Statewide method is defined, but later periods have DQ | PARTIALLY_COMPARABLE. |

## 7. Berean representation assessment

No architecture change is justified.

The current model can preserve this test as separate source-backed assertions:

1. Allegheny County source record → citation → evidence → county claim → county proposition/value.
2. Pennsylvania APSR source record → citation → evidence → statewide claim → statewide proposition/value.
3. Distinct temporal qualifications and source identities.
4. Separate county and statewide geographic entities or scope anchors.
5. The county 8.1%, dashboard “about 9%,” subgroup rates, and statewide 7.8% as distinct observations rather than one normalized value.
6. A `QUALIFIES` or unresolved comparison relationship if a later reviewed claim explicitly compares them.

The unresolved denominator, profile-period, and dashboard-state information should remain explicit metadata/limitations. Berean must not derive a county-versus-state performance conclusion from the numerical difference alone.

## 8. Determination

# PILOT_REVIEW_REQUIRED

The follow-up establishes a more precise county measure and a substantially stronger semantic match to the statewide re-entry indicator. It does not establish a directly comparable county/state statistic because the county's numeric denominator, underlying data-profile period, and reproducible dashboard state remain unavailable in the reviewed public record.

The defensible conclusion is:

> Allegheny County and Pennsylvania publish re-entry-within-12-months indicators with materially aligned stated exit-destination language, but the current public records support only a partial comparability assessment, not a direct performance comparison.

## 9. Recommendation

Keep Allegheny County provisional.

The next source-verification action should be one of the following, in order:

1. Obtain or identify the county's underlying measure definition/data-profile documentation for the 8.1% indicator, including numerator, denominator, cohort dates, and source system.
2. Reproduce the Tableau `Re-entry` view with a documented CY 2023 filter state and capture the visible denominator or downloadable data, if publicly available.
3. If the county does not publish those details, register the NBPB and dashboard as source records with explicit limitations and use them for provenance/research tests without asserting direct county/state comparability.

Formal pilot authorization should wait until the charter's “sufficiently complete, public, and stable documentation” criterion is evaluated with these limitations recorded.

## 10. Change control

- **New document:** `COUNTY_PILOT_FOLLOWUP_VERIFICATION.md`.
- **`CORPUS_CHARTER.md`:** unchanged.
- **`SOURCE_INVENTORY.csv`:** unchanged.
- **Downloaded corpus documents:** none.
- **Application/schema/ingestion/fixture/test code:** none modified.
