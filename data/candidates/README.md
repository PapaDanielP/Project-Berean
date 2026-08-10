# Phase 26 candidate and reconciliation staging area

`phase26-entity-candidates.csv` is the smallest repository-native staging artifact for the
Phase 26 Biblical Entity Coverage and Reconciliation workflow. It is a review worksheet, not a
Berean persistence structure.

## Candidate data is not authoritative Berean knowledge

Nothing in this directory is a Source, Evidence, Claim, Proposition, or Entity. A candidate row
becomes Berean knowledge only when a reviewer accepts it and it is ingested through the normal
Source → Dataset → SourceRecord → Citation → Evidence → Claim path, with the proposition asserted
through an already registered predicate.

External identifiers (for example Theographic or STEP Bible identifiers) are recorded here as
discovery aids only. They are never imported as authoritative facts, and an external inference is
never promoted merely because an external dataset asserts it.

## Columns

| Column | Meaning |
| --- | --- |
| `candidate_key` | Stable worksheet key for the candidate row. |
| `entity_type` | Proposed `entity_type_code` (`PERSON`, `PLACE`, `ORGANIZATION`, `OBJECT`, `CONCEPT`). |
| `candidate_name` | Proposed display name as the candidate is named by the discovery aid. |
| `biblical_references` | Locators inside the Phase 26 source boundary where the candidate is explicitly named. Empty when the candidate is not explicitly named in the boundary. |
| `explicit_textual_description` | What the biblical text explicitly states about the candidate at those locators. |
| `proposed_proposition` | The structured proposition a reviewer proposes, expressed with an existing registered predicate. |
| `source_status` | `EXPLICIT_IN_SELECTED_CORPUS`, `NOT_EXPLICIT_IN_SELECTED_CORPUS`, or `OUTSIDE_SELECTED_CORPUS`. |
| `external_source` | Discovery aid that surfaced the candidate. |
| `external_identifier` | Identifier used by that discovery aid. Never authoritative. |
| `review_status` | `ACCEPTED_AND_INGESTED`, `CANDIDATE_REQUIRES_REVIEW`, or `EXCLUDED`. |
| `exclusion_reason` | Why an excluded candidate was excluded. |
| `review_notes` | Reviewer notes, including deliberately unmodeled material. |
| `proposed_mapping_decision` | Proposed Entity/EntitySourceMapping/import decision. |

## Tier policy

- Tier 1 — explicit source-backed statements may be ingested as ordinary Berean structures.
- Tier 2 — deterministic structural derivations only, using Derivation/DerivationInput.
- Tier 3 — interpretive or external-only material stays here as `CANDIDATE_REQUIRES_REVIEW`.

Absence from this worksheet is not source silence, and `EXCLUDED` is not a claim of nonexistence.
