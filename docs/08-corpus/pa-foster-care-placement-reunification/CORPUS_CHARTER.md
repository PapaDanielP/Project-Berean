# Corpus Charter: Pennsylvania Foster-Care Placement Stability and Family Reunification

**Status:** MVP scope proposal for review  
**Corpus ID:** `pa-foster-care-placement-reunification`  
**Coverage period:** January 1, 2018 through December 31, 2025  
**Jurisdiction:** Commonwealth of Pennsylvania, with one county pilot to be selected after source-availability review  
**Owner:** Project Berean maintainers

## 1. Purpose

This corpus will test Project Berean's provenance-first model on a bounded public-records question:

> How do Pennsylvania's placement practices, case-planning processes, family connections, and service strategies relate to foster-care placement stability and family reunification outcomes?

The corpus is intended to preserve the relationship between source documents, evidence units, claims, propositions, identities, derivations, qualifications, and counterclaims. It is not intended to produce a universal ranking of counties, agencies, foster families, parents, or children.

## 2. MVP objectives

The MVP must allow a researcher to:

1. Locate authoritative Pennsylvania laws, regulations, policies, performance reports, oversight findings, and selected contextual research.
2. Identify the reporting period, population, jurisdiction, methodology, and definitions attached to each metric or finding.
3. Trace a represented claim to the exact source and evidence that supports, qualifies, or contradicts it.
4. Distinguish administrative indicators from qualitative case-review findings and from legal requirements.
5. Record uncertainty, data-quality limitations, publication dates, effective dates, and changes in terminology.
6. Compare compatible observations across years without implying causation where the evidence supports only description or association.

## 3. Scope

### Included

- Pennsylvania statewide public records published during or concerning 2018–2025.
- One county pilot selected from counties with sufficiently complete, public, and stable documentation.
- Placement stability, placement moves, placement disruptions, kinship placement, sibling connections, visitation, permanency planning, reunification, reunification timing, re-entry after reunification, and related service or policy interventions.
- Federal and state requirements that directly govern the selected outcomes.
- Official reports, public audits, court opinions, agency guidance, county plans, and carefully bounded contextual research.
- Source metadata, document versions, extraction notes, licensing/access notes, and provenance records.

### Excluded from the MVP

- Confidential case files, sealed court records, or personally identifying information.
- Individual child, parent, foster-family, or caseworker profiles.
- Predictive risk scoring, recommendations about individual families, or automated eligibility decisions.
- Claims that a policy caused an outcome unless an appropriate causal design and evidence are explicitly represented.
- A complete census of every Pennsylvania county or every available document.
- Live operational monitoring or production case-management functionality.
- Legal, medical, social-work, or child-safety advice.
- Ingestion code changes before the charter and inventory are reviewed.

## 4. Core concepts and definitions

Definitions must be stored with each relevant evidence or metric rather than assumed globally.

- **Placement stability:** A measure of placement continuity. The primary statewide administrative indicator is placement moves per 1,000 days of foster care, but qualitative review findings may use a different operational definition.
- **Placement move:** A change in the child's placement counted according to the source's stated methodology. Do not normalize across sources without recording the transformation.
- **Reunification:** A foster-care exit or permanency outcome identified by the source as return to a parent or primary caregiver. Record the source's exact definition and observation window.
- **Re-entry:** Entry into foster care after a prior exit, including the time interval and exit type specified by the source.
- **Kinship placement:** Placement with relatives or kin as defined by the source. Preserve distinctions between formal kinship care, fictive kin, and other caregiver categories.
- **Permanency:** A source-defined permanency goal or outcome. Do not treat permanency, reunification, adoption, guardianship, and placement stability as interchangeable.
- **Administrative indicator:** A calculated measure derived from administrative data, including its denominator, cohort, period, and data-quality status.
- **Qualitative finding:** A case-review, interview, audit, or narrative finding that is not necessarily generalizable to the statewide population.
- **Policy intervention:** A law, regulation, guidance, funding change, program, or implementation activity with a documented effective or implementation date.

## 5. Epistemic rules

1. Every substantive claim must identify its source and evidence span or structured data location.
2. A source's statement must not be rewritten as an independently verified fact without representing the source identity and claim type.
3. Reported allegation, substantiated finding, administrative observation, legal holding, recommendation, and causal conclusion are distinct claim types.
4. A metric is incomplete without its population, denominator, time period, jurisdiction, method, and data-quality qualification when available.
5. Comparisons require compatible definitions. If definitions differ, preserve separate propositions and record the incompatibility.
6. A lower or higher value is not inherently better unless the source explicitly establishes the desired direction.
7. Correlation, temporal sequence, program association, and causal effect must remain separate propositions.
8. Conflicting sources are retained and linked; they are not silently reconciled.
9. Source publication date, reporting period, effective date, and observation period are separate temporal fields.
10. Derived claims must identify all inputs and the transformation used.

## 6. Source-selection policy

Prioritize sources in this order:

1. Pennsylvania DHS/OCYF and other Commonwealth primary sources.
2. Pennsylvania statutes, regulations, official court opinions, and federal child-welfare materials governing Pennsylvania.
3. Official oversight, audit, review, and corrective-action materials.
4. County plans and public county child-welfare materials for the pilot county.
5. Peer-reviewed or research-institution publications used only when their methods and applicability can be represented clearly.

A source is eligible when it is publicly accessible, attributable, relevant to the defined outcomes, and sufficiently stable to archive or reference. Each source must receive a status of `candidate`, `selected`, `excluded`, or `superseded` with a reason.

## 7. Initial corpus composition target

The first review set should contain approximately:

- 3–5 laws or regulations.
- 3–5 statewide performance or planning reports.
- 2–4 oversight, review, audit, or corrective-action documents.
- 2–4 county-pilot documents.
- 2–4 contextual research sources.
- At least 10 manually reviewed evidence-to-claim derivations.

These are targets, not a requirement to ingest every listed source immediately.

## 8. Required source metadata

Each inventory row and later source manifest should capture, where applicable:

- Stable corpus source ID.
- Title and publisher.
- Source type and authority level.
- Jurisdiction and geographic granularity.
- Publication date, effective date, and reporting/observation period.
- Canonical URL and local artifact path when archived.
- Version, revision, supersession, and retrieval date.
- License, access restrictions, and permitted use.
- Relevant outcomes and populations.
- Methodology and data-quality notes.
- Review status and reviewer notes.

## 9. Data handling and privacy

Only public, lawfully usable material may be included. Do not copy names or details that identify children or families from public narrative documents when they are not necessary to represent the research claim. Redact or omit unnecessary personal information in extracted evidence. Preserve the source document's access and licensing conditions in the manifest.

## 10. MVP acceptance criteria

The corpus charter and inventory milestone is complete when:

- The folder structure is present and linked from the documentation index.
- The scope and exclusions have been reviewed and accepted.
- The inventory contains the initial authoritative source set and explicit selection statuses.
- Each selected source has a clear reason for inclusion and a defined research use.
- The county pilot is selected using documented availability and comparability criteria.
- At least 10 evidence-to-claim examples can be reviewed manually before automated ingestion expands.
- No ingestion implementation is expanded solely to accommodate unapproved scope.

## 11. Decisions still requiring review

- Select the county pilot.
- Confirm whether the coverage period remains 2018–2025 for the first public release.
- Approve the controlled vocabulary for placement and reunification metrics.
- Confirm the permitted-use treatment for contextual research and downloaded artifacts.
- Decide whether the first release should include education stability and sibling visitation as secondary dimensions or defer them.
