# Berean Domain Model

## Entity

A canonical representation of a person, place, organization, object, concept, or other identifiable knowledge object.

## Source Identity

A source-specific representation or name for an entity.

## Source Entity Mapping

A reconciliation assertion connecting a source identity to a canonical entity.

## Event

An occurrence or process involving entities and/or other events.

## Relationship

A semantic relation such as `fatherOf`, `motherOf`, `locatedAt`, `participatesIn`, or `precedes`.

A relationship is not automatically true merely because it exists in the model.

## Proposition

A structured semantic statement, commonly represented as:

```text
subject + predicate + object/value
```

## Claim

An assertion that a proposition is valid, applicable, or supported.

Claims may be:

- direct/source-grounded
- derived
- interpretive
- competing
- uncertain

## Evidence

A source-grounded observation that can be associated with one or more claims.

## Source

The originating work, publication, text, database, dataset, or other information source.

## Source Record

An identifiable record, row, passage, document location, or extracted source unit.

## Dataset

A structured representation of source material used for ingestion or analysis.

## Citation / Source Location

A locator identifying the relevant position within a source, such as a book/chapter/verse, page, section, record ID, URL, or document offset.

## Key semantic rule

The following are intentionally different:

- Evidence ≠ Claim
- Claim ≠ Truth
- Relationship ≠ Truth
- Source ≠ Evidence
- Source Record ≠ Claim
- Canonical Entity ≠ Source Identity
