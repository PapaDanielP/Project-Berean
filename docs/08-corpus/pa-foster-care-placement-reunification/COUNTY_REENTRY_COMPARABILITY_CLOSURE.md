# Allegheny County Re-entry Observation Reproducibility and Comparability Closure

**Review date:** August 21, 2026  
**Corpus:** `pa-foster-care-placement-reunification`  
**Candidate county:** Allegheny County, Pennsylvania  
**Prior pilot status:** `PILOT_REVIEW_REQUIRED`  
**County measure status:** `PARTIALLY_REPRODUCIBLE`  
**County/state comparison status:** `INSUFFICIENT_INFORMATION`  
**Pilot disposition:** `PILOT_REVIEW_REQUIRED`

## 1. Purpose

This phase evaluates two independent questions:

**A.** Can the Allegheny County re-entry observation be represented as a reproducible, source-scoped observation with its uncertainties preserved?

**B.** Can that county observation be compared defensibly with the Pennsylvania statewide re-entry observation already identified in prior work?

A positive answer to A does not imply a positive answer to B. This phase does not select Allegheny County as the county pilot, does not create source records or claims, and does not modify the corpus charter.

## 2. Baseline and prior determination

Prior documentation identified:

- A dashboard trend described as approximately 9% re-entry over time.
- A more precise county NBPB indicator of 8.1% re-entry after reunification.
- A Pennsylvania statewide re-entry value of 7.8% for the 21B–22A data-profile period.
- Missing county numerator, numeric denominator, complete cohort construction, underlying profile period, and reproducible dashboard state.

The prior formal status was `PILOT_REVIEW_REQUIRED`; this phase does not change it.

## 3. Sources reviewed

### 3.1 Allegheny County Needs-Based Plan and Budget

- **Title:** `Fiscal Year 2026-27 Needs-Based Plan & Budget`.
- **Issuer:** Allegheny County Department of Human Services, Office of Children, Youth and Families.
- **URL:** `https://analytics.alleghenycounty.us/wp-content/uploads/2025/09/NBB02_26-27_Narrative.pdf`.
- **Access date:** August 21, 2026.
- **Document period:** FY 2024–25, FY 2025–26, and FY 2026–27 planning document with historical measures.
- **Geographic scope:** Allegheny County.
- **Locator:** PDF page 69, section `2-3f Re-entry (in 12 Months)`; related subgroup discussion on pages 70–71.
- **Published observation:** Allegheny County's re-entry rate after reunification is 8.1%.
- **Stated population/cohort:** Children and youth who re-enter care within 12 months after discharge to reunification, living with a relative, or guardianship.
- **Unit:** Percentage.
- **Numerator:** `NOT_VERIFIED`.
- **Numeric denominator:** `NOT_VERIFIED`.
- **Complete inclusion/exclusion rules:** `NOT_VERIFIED`.
- **Underlying data-profile period:** `NOT_VERIFIED` in the cited section.
- **Qualifications:** The document compares the county value with a 5.6% national performance standard and separately reports subgroup results by JPO involvement, sex, and race.
- **Limitation:** The public section provides the reported indicator and functional definition but not enough arithmetic detail to reconstruct 8.1%.

### 3.2 Allegheny Analytics dashboard publication and dashboard reference

- **Title:** `Child Welfare Out-of-Home Placements: Interactive Dashboard`.
- **Issuer:** Allegheny County Department of Human Services / Allegheny Analytics.
- **Publication page:** `https://analytics.alleghenycounty.us/2021/01/07/child-welfare-out-of-home-placements-interactive-dashboard/`.
- **Archive/tag locator:** `https://analytics.alleghenycounty.us/tag/foster-care/`.
- **Access date:** August 21, 2026.
- **Published scope:** Filterable Allegheny County out-of-home-placement data; the archive describes coverage from 2010 through 2021 and annual updates.
- **Subject areas:** Children in placement, placement types, length of stay, exits, and re-entry after returning home.
- **Dashboard view referenced in prior county material:** `Re-entry`.
- **Exact dashboard filter state:** `NOT_VERIFIED`.
- **Selected date range:** `NOT_VERIFIED`.
- **Displayed numerator:** `NOT_VERIFIED`.
- **Displayed denominator:** `NOT_VERIFIED`.
- **Export/download:** `NOT_VERIFIED`.
- **Stable version or snapshot:** `NOT_VERIFIED`.
- **Limitation:** The publication page establishes source availability and subject coverage, but it does not independently reproduce the approximately 9% value.

### 3.3 Pennsylvania statewide comparison source

- **Title:** `Pennsylvania 2026 Annual Progress and Services Report`.
- **Issuer:** Pennsylvania Department of Human Services, Office of Children, Youth, and Families.
- **URL:** `https://www.pa.gov/content/dam/copapwp-pagov/en/dhs/documents/docs/publications/documents/child-youth-and-family-service-plan/2026-annual-progress-services-report-apsr.pdf`.
- **Access date:** August 21, 2026.
- **Locator:** PDF pages 29–30, `SWDI on Reentry to Foster Care in 12 Months`, Table 18.
- **Definition:** Percentage of children who re-entered care within 12 months of discharge, among children who exit foster care in a 12-month period to reunification, living with a relative, or guardianship.
- **Reported value:** Pennsylvania RSP value 7.8% for the 21B–22A files.
- **Unit:** Percentage.
- **Data source:** AFCARS and NCANDS, February 2025 profile.
- **Qualification:** Later profile periods are marked DQ and the report states that data-quality issues are being addressed.

## 4. Allegheny County observation

The strongest county observation supported by an authoritative public source is:

> The Allegheny County FY 2026–2027 Needs-Based Plan and Budget reports an 8.1% re-entry rate after reunification for its stated 12-month re-entry indicator.

This is a **source-scoped observation**. It is not an independently recalculated statistic and is not a statewide claim.

The prior approximate 9% value is also retained as a separate source description:

> The county dashboard/NBPB narrative describes re-entry within one year as remaining approximately 9% over time.

These two values are not silently collapsed.

## 5. 8.1% versus approximately 9% reconciliation

| Question | Result | Reason |
|---|---|---|
| Same exact displayed value? | `NOT_VERIFIED` | The documents present 8.1% and approximately 9%, not the same displayed precision. |
| Same measure at different precision? | `NOT_VERIFIED` | No source statement confirms that approximately 9% is a rounded display of 8.1%. |
| Different reporting periods? | `NOT_VERIFIED` | The county material does not expose the complete underlying period for the 8.1% indicator, while the dashboard publication page describes a broader historical coverage. |
| Different calculation contexts? | `POSSIBLE_BUT_NOT_VERIFIED` | One value is a planning-document indicator and the other is a dashboard trend description. |
| Genuinely different measures? | `NOT_VERIFIED` | The public material does not establish whether the trend description and indicator use identical construction. |
| Arithmetic reconstruction possible? | `NOT_REPRODUCIBLE` | Numerator and numeric denominator are not supplied. |

The correct treatment is to preserve `8.1%` and `approximately 9%` as separate source observations until an authoritative source explicitly reconciles them.

## 6. Dashboard reproducibility findings

### 6.1 Observable

The public dashboard publication material establishes:

- Dashboard identity.
- Allegheny County geography.
- Out-of-home-placement subject matter.
- Coverage beginning in 2010 and described through 2021.
- Subject areas including placement types, length of stay, exits, and re-entry.
- Annual update behavior when a full year is available.

### 6.2 Not observable or not reproducibly captured

The following fields remain unresolved:

```text
Dashboard view: identified as Re-entry in prior county material
Visualization title: NOT_VERIFIED
Geography filter: NOT_VERIFIED beyond county-level publication scope
Cohort filter: NOT_VERIFIED
Date filter: NOT_VERIFIED
Measure filter: NOT_VERIFIED at metric-state level
Numerator: NOT_VERIFIED
Denominator: NOT_VERIFIED
Tooltip text: NOT_VERIFIED
Methodology text for exact view: NOT_VERIFIED
Export format: NOT_VERIFIED
Export filename: NOT_VERIFIED
Export timestamp: NOT_VERIFIED
Snapshot/version identifier: NOT_VERIFIED
Checksum: NOT_VERIFIED
```

The dashboard is therefore usable as a source-availability and view-description source, but the exact approximately 9% observation is not independently reproducible from the captured public material.

## 7. County metric qualification

# PARTIALLY_REPRODUCIBLE

The county measure is partially reproducible because:

- The issuer is identifiable.
- The county geography is identifiable.
- The 8.1% value is explicitly reported.
- The functional 12-month re-entry meaning and exit destinations are stated.
- The dashboard subject and broad coverage are identifiable.

It is not fully reproducible because:

- No numerator is stated.
- No numeric denominator is stated.
- Complete inclusion/exclusion rules are not stated.
- The exact underlying profile period is not recoverable from the cited section.
- The dashboard filter state is not captured.
- No export or snapshot was verified.
- The relation between 8.1% and approximately 9% is not explicitly documented.

It is not classified `NOT_REPRODUCIBLE` overall because the published county observation is attributable and semantically qualified enough for a limited source-backed representation. The exact arithmetic and dashboard reproduction, however, are `NOT_REPRODUCIBLE` in this phase.

## 8. Pennsylvania statewide comparison

The statewide measure is the Pennsylvania SWDI re-entry indicator reported as 7.8% for the 21B–22A files. Its definition uses the same broad exit destinations as the county NBPB indicator, but the statewide report provides a specific federal/state data-profile context that the county report does not provide.

### 8.1 Full comparability matrix

| Dimension | Allegheny County | Pennsylvania statewide | Compatible? | Evidence / reason |
|---|---|---|---|---|
| Measure meaning | Re-entry within 12 months after discharge to reunification, relative care, or guardianship | Re-entry within 12 months after exit to reunification, relative care, or guardianship | `PARTIALLY_COMPARABLE` | Stated meanings align materially, but full county method is not documented. |
| Numerator | `NOT_VERIFIED` | `NOT_VERIFIED` in the report table | `INSUFFICIENT_INFORMATION` | Neither public passage supplies a count. |
| Denominator | Numeric denominator `NOT_VERIFIED`; eligible population described conceptually | Eligible exit cohort described conceptually; numeric denominator not supplied | `PARTIALLY_COMPARABLE` | Cohort wording aligns, but numeric denominators and construction are unavailable. |
| Population | Children and youth in the county indicator | Children exiting foster care in the statewide SWDI cohort | `PARTIALLY_COMPARABLE` | Similar stated population, but exact county cohort construction is unresolved. |
| Cohort | Exit destinations and 12-month follow-up stated | Exit destinations and 12-month follow-up stated | `PARTIALLY_COMPARABLE` | Similar wording; no verified method equivalence. |
| Inclusion criteria | Exit destinations stated; complete rules `NOT_VERIFIED` | Exit destinations stated; full table methodology not reproduced in report excerpt | `PARTIALLY_COMPARABLE` | Broad criteria align, detailed rules do not. |
| Exclusion criteria | `NOT_VERIFIED` | `NOT_VERIFIED` in the cited table text | `INSUFFICIENT_INFORMATION` | No complete exclusion rules available for either source in this review. |
| Reporting period | County indicator period `NOT_VERIFIED` in cited section | 21B–22A files | `NOT_ESTABLISHED` | Periods cannot be aligned. |
| Period type | County planning/dashboard context; fiscal and calendar references coexist | AFCARS/NCANDS data-profile period | `NOT_ESTABLISHED` | Different period conventions and missing county profile period. |
| Calculation method | `NOT_VERIFIED` | Statewide indicator methodology named, but arithmetic inputs are not supplied | `INSUFFICIENT_INFORMATION` | Methodological equivalence cannot be established. |
| Geography | Allegheny County | Pennsylvania statewide | `PARTIALLY_COMPARABLE` | Geographic scopes are explicit and distinct. |
| Publication/source version | FY 2026–27 NBPB, Version 2 dates recorded in prior review; dashboard version not captured | Pennsylvania 2026 APSR, February 2025 data profile | `PARTIALLY_COMPARABLE` | Documents are attributable, but underlying data snapshots differ. |
| Qualifications | National standard comparison; JPO, sex, and race subgroup reporting | RSP interval and DQ flags for later periods | `PARTIALLY_COMPARABLE` | Both qualify the measure, but qualifications are not equivalent. |
| Limitations | Missing county arithmetic and dashboard state | Missing statewide arithmetic inputs; later data-quality issues | `PARTIALLY_COMPARABLE` | Both have limitations, but they constrain different parts of comparison. |

### 8.2 Comparison classification

# INSUFFICIENT_INFORMATION

The county and statewide measures have materially aligned stated meanings and units, but the missing county numerator, denominator, complete cohort construction, underlying profile period, and dashboard state prevent a defensible direct comparison.

This is not `DIRECTLY_COMPARABLE`. It is also not classified `NOT_COMPARABLE`, because the available wording indicates a potentially compatible indicator family. The correct current result is `INSUFFICIENT_INFORMATION`.

## 9. Missing and unknown fields

| Field | Status |
|---|---|
| County numerator | `NOT_VERIFIED` |
| County numeric denominator | `NOT_VERIFIED` |
| County complete cohort construction | `NOT_VERIFIED` |
| County inclusion rules | `NOT_VERIFIED` |
| County exclusion rules | `NOT_VERIFIED` |
| County underlying profile period | `NOT_VERIFIED` |
| County calculation method | `NOT_VERIFIED` |
| Exact relationship between 8.1% and approximately 9% | `NOT_VERIFIED` |
| Dashboard exact filter state | `NOT_VERIFIED` |
| Dashboard export/snapshot | `NOT_VERIFIED` |
| Statewide numerator | `NOT_VERIFIED` |
| Statewide numeric denominator | `NOT_VERIFIED` in the report table |
| Statewide later-period data quality | `VERIFIED` as reported DQ |
| Source-scoped county observation | `VERIFIED` |
| Source-scoped statewide observation | `VERIFIED` |

## 10. Berean provenance implications

The existing Berean model can preserve this imperfect research situation without schema redesign.

The correct conceptual chain is:

```text
Allegheny County DHS / Allegheny Analytics
  → NBPB or dashboard dataset
    → source record
      → page/section/dashboard citation
        → SOURCE_OBSERVATION evidence
          → source-scoped claim
            → proposition with typed percentage value
```

The county 8.1% value, dashboard approximate 9% description, subgroup rates, and Pennsylvania 7.8% value must be separate observations. Their similar units do not authorize merging.

Missing denominator, profile period, and dashboard state should remain explicit limitations. They should not be replaced with fabricated values or hidden in prose. A later comparison claim, if ever authored, would require its own evidence and should remain unresolved or qualified unless the missing dimensions are supplied.

This is consistent with Berean's documented separation:

- Source is not evidence.
- Source record is not a claim.
- Evidence is not a claim.
- Claim is not truth.
- A relationship is not automatically true.
- A workflow or review status does not promote knowledge.

No new schema concept is justified by this phase. The missing information is a source-verification and population limitation, not a demonstrated failure of the generic provenance model.

## 11. Pilot-selection implications

The county source base remains useful for a controlled provenance and semantic-boundary pilot because:

- Official county sources are attributable.
- The county measure has a stated functional meaning.
- The measure can be preserved with explicit missing-field statuses.
- The dashboard supplies a meaningful test of dynamic-source uncertainty.
- The source set covers relevant child-welfare subject matter.

However, the source base does not yet establish a fully reproducible county statistic or a directly comparable county/state measure. The charter requires sufficiently complete, public, and stable county documentation; this criterion is therefore only partially satisfied.

## 12. Final determination

### County observation

# PARTIALLY_REPRODUCIBLE

### County/state comparison

# INSUFFICIENT_INFORMATION

### Pilot disposition

# PILOT_REVIEW_REQUIRED

The evidence supports a qualified, source-scoped Allegheny County observation but does not close the reproducibility or comparability gaps sufficiently to select Allegheny County formally.

## 13. Recommended next step

Choose one controlled next phase:

1. **Methodology acquisition:** locate a public county methodology appendix, aggregate extract, data dictionary, or dashboard export that supplies the numerator, denominator, cohort dates, source system, and exact dashboard state; or
2. **Bounded provenance population:** register the NBPB and dashboard as candidate source records with explicit limitations and use them as an intentional incomplete-metadata validation case, without authoring a county-versus-state performance comparison.

Do not change the charter or select Allegheny County until the county-selection evidence is reviewed against the charter's “sufficiently complete, public, and stable documentation” criterion.

## 14. Change-control statement

- **Created:** `COUNTY_REENTRY_COMPARABILITY_CLOSURE.md`.
- **Modified:** No existing corpus documents.
- **`CORPUS_CHARTER.md`:** unchanged.
- **`SOURCE_INVENTORY.csv`:** unchanged.
- **Downloaded source documents:** none.
- **Source records/evidence/claims/propositions:** none created.
- **Application code:** unchanged.
- **Schema/migrations:** unchanged.
- **Ingestion code/manifests:** unchanged.
- **Fixtures/tests/validation scripts:** unchanged.
