# Phase 37R/37B — World's Columbian Exposition Discovery-Driven Expansion

## Result

**PASS WITH DOCUMENTED SOURCE-ACCESS AND REGISTRY LIMITATIONS.** Phase 37 remains unchanged.
Phase 37R adds an independently keyed, locator-only electrical-exhibition corpus; Phase 37B
interrogates it with a withheld synthesis prompt. No schema, registry, or Explorer code changed.

## Reproducible source review

`data/candidates/phase37r-worlds-columbian-exposition-source-review.csv` is the bounded source
manifest. It records eight reviewed works, stable locators, roles, access date (`2026-08-11`),
access status, and permitted use:

- primary/official: the 1893 *Official Directory* and post-fair official report;
- contemporary technical/trade/guidebook: Barrett, *Electrical Industries*, and Bancroft;
- discovery only: the Chicago's 1893 World's Fair people index;
- scholarly interpretation: Badger and Rydell.

The LOC and Internet Archive scans could not be fetched from this sandbox. Catalog/index records
and indexed descriptions were available. Consistent with the existing Phase 37 policy, Phase 37R
stores no source text, hash, or quotation. It uses explicit work/section locators and records the
access limitation rather than fabricating quotations or page numbers. The official report and
guidebook remain review-only because the inaccessible scans did not establish an additional
represented proposition.

## Selection method

1. Review every source category before choosing entities.
2. Generate candidates from the official directory, contemporary accounts, electrical-industry
   material, and the discovery-only people index.
3. Verify candidate propositions against primary or contemporary technical sources; discovery
   sources never support claims.
4. Map only verified propositions to existing registered predicates and entity/event types.
5. Retain every exclusion, unresolved identity, and registry mismatch in the candidate audit.
6. Populate Stage A without embedding the withheld question or expected answers.

The resulting candidate audit contains **33 discovered candidates: 20 selected and 13 excluded**.

| Category | Discovered | Selected | Excluded |
|---|---:|---:|---:|
| People | 5 | 1 | 4 |
| Organizations | 4 | 3 | 1 |
| Events | 3 | 1 | 2 |
| Exhibits | 5 | 4 | 1 |
| Electrical technologies | 7 | 5 | 2 |
| Relationships | 9 | 6 | 3 |

Exclusions include prior Phase 37 coverage, out-of-scope candidates, unverified exhibit identities,
ambiguous corporate/person identities, absent predicates, and unsupported winner, superiority, and
causal narratives.

## Tesla and Westinghouse non-special-casing

Neither name occurs in accepted Phase 37. Both emerged when the review reached the Electricity
Building sources and the discovery people index. They use the same candidate fields, verification
rules, and disposition process as every other person:

- Nikola Tesla was selected after contemporary technical and electrical-industry verification.
- George Westinghouse was excluded from population because the accessible locator did not
  page-confirm his personal participation separately from the company exhibit. His source identity
  remains unresolved.
- Westinghouse Electric and Manufacturing Company was independently selected as an organization.

The deterministic candidate audit rejects person-specific `IF`/`CASE` selection branches. There is
no Tesla- or Westinghouse-specific application logic.

## Population and provenance

`tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql` adds:

- 5 locator-only datasets, 14 source records, 14 citations, and 14 evidence rows;
- 10 entities: 1 person, 3 organizations, 1 place, and 5 technologies/apparatus;
- 5 exhibit/events;
- 15 direct claims and 22 `SUPPORTS` links;
- 6 source identities, 4 active mappings, and 2 deliberately unresolved identities;
- 2 cited scholarly analytical observations supporting no claim.

All direct claims traverse
`Claim → ClaimEvidence → Evidence → EvidenceCitation → Citation → SourceRecord → Dataset → Source`.
The discovery-only people index enters neither the source graph nor claim provenance.

## Withheld Phase 37B suite

The prompt first appears in
`tests/validation/phase37b-worlds-columbian-exposition-withheld-query-validation.sql`:

> Tell me about the people and electrical technologies represented at the 1893 World's Columbian
> Exposition, and explain the relationships Berean can establish between them.

The read-only suite distinguishes:

- **Established:** people, organizations, exhibits, technologies, participation, locations, and
  their complete source chains.
- **Derived:** three person→exhibit→technology paths; one
  person→organization→exhibit co-participation path; person→event→location paths; shared exhibit
  participation; and seven claims supported by multiple source traditions.
- **Scholarly:** two independently cited interpretations, neither promoted, ranked, or resolved.
- **Unresolved:** the George Westinghouse personal identity and the ambiguous Edison index identity.
- **Not represented:** an AC/DC winner, technological superiority, historical causation, or
  person-to-organization employment/membership.

The person→organization→exhibit result means only that a person and organization share a
claim-asserted exhibit. It must not be read as employment or membership.

## Architectural assessment

No architecture or schema modification was necessary for entities, exhibit/events, locations,
technologies, source-backed participation, multi-source support, uncertainty, or scholarship.
Existing `occursAt` and `participatesIn` propositions and the claim-derived
`event_participation` view were sufficient.

One precise registry limitation remains: Berean has no general person-to-organization predicate.
The corpus therefore cannot assert `memberOf` or `employedBy`. Phase 37R does not misuse
`locatedAt`, add a predicate, or convert co-participation into membership. This is a result of the
architectural test, not a silent redesign.

## Known gaps

- Precise scan page numbers remain unavailable for some directory/trade locators in this sandbox.
- George Westinghouse's personal participation and the Edison index identity need additional
  page-level evidence.
- Thomson-Houston/General Electric reconciliation remains excluded pending identity evidence.
- Contract awards, bid amounts, scheduled demonstrations, technological rank, and causal historical
  conclusions are not represented.
- Scholarship is intentionally retained as interpretation rather than source fact.

## Validation

Run independently against the reference schema:

```sh
tests/validation/phase37r-candidate-audit-validation.sh
psql "$DATABASE_URL" -f tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql
psql "$DATABASE_URL" -f tests/validation/phase37r-worlds-columbian-exposition-population-validation.sql
psql "$DATABASE_URL" -f tests/validation/phase37b-worlds-columbian-exposition-withheld-query-validation.sql
```

The full repository runner executes the Phase 37R/37B lifecycle twice after unchanged Phase 37.
Targeted PostgreSQL validation passed on `2026-08-11`: the first fixture run inserted the inventory
above, the second inserted zero rows, both population validations passed, and Phase 37B preserved
identical before/after persistent counts. The full PostgreSQL reference validation also passed
end-to-end. `npm run typecheck`, `npm run lint`, and `npm run build` passed; `npm test` passed all
83 tests against an isolated PostgreSQL database.
