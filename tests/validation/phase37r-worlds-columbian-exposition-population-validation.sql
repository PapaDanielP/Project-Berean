\set ON_ERROR_STOP on
DO $$
DECLARE actual integer;
BEGIN
    SELECT count(*) INTO actual FROM dataset WHERE dataset_key LIKE '%\_P37R' ESCAPE '\';
    IF actual <> 5 THEN RAISE EXCEPTION 'phase37r: expected 5 datasets, found %', actual; END IF;

    SELECT count(*) INTO actual
    FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
    WHERE d.dataset_key LIKE '%\_P37R' ESCAPE '\';
    IF actual <> 14 THEN RAISE EXCEPTION 'phase37r: expected 14 source records, found %', actual; END IF;

    IF EXISTS (
        SELECT 1 FROM source_record sr JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key LIKE '%\_P37R' ESCAPE '\'
          AND (sr.raw_content IS NOT NULL OR sr.content_hash IS NOT NULL OR sr.source_location IS NULL)
    ) OR EXISTS (
        SELECT 1 FROM citation c JOIN source_record sr ON sr.source_record_id = c.source_record_id
        JOIN dataset d ON d.dataset_id = sr.dataset_id
        WHERE d.dataset_key LIKE '%\_P37R' ESCAPE '\' AND c.quoted_text IS NOT NULL
    ) THEN RAISE EXCEPTION 'phase37r: locator-only storage policy violated'; END IF;

    SELECT count(*) INTO actual FROM evidence WHERE evidence_key LIKE 'EV\_P37R\_%' ESCAPE '\';
    IF actual <> 14 THEN RAISE EXCEPTION 'phase37r: expected 14 evidence rows, found %', actual; END IF;
    SELECT count(*) INTO actual FROM entity WHERE entity_key LIKE 'phase37r\_%' ESCAPE '\';
    IF actual <> 10 THEN RAISE EXCEPTION 'phase37r: expected 10 entities, found %', actual; END IF;
    SELECT count(*) INTO actual FROM event WHERE event_key LIKE 'phase37r\_%' ESCAPE '\';
    IF actual <> 5 THEN RAISE EXCEPTION 'phase37r: expected 5 exhibit/events, found %', actual; END IF;
    SELECT count(*) INTO actual FROM claim WHERE claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\';
    IF actual <> 15 THEN RAISE EXCEPTION 'phase37r: expected 15 direct claims, found %', actual; END IF;
    SELECT count(*) INTO actual
    FROM claim_evidence ce JOIN claim c ON c.claim_id = ce.claim_id
    WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\';
    IF actual <> 22 THEN RAISE EXCEPTION 'phase37r: expected 22 claim-evidence links, found %', actual; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c JOIN proposition p ON p.proposition_id = c.proposition_id
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
          AND (c.claim_type_code <> 'DIRECT_SOURCE_CLAIM'
               OR p.predicate NOT IN ('occursAt', 'participatesIn'))
    ) THEN RAISE EXCEPTION 'phase37r: non-direct claim or unapproved predicate found'; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
          AND NOT EXISTS (
              SELECT 1 FROM claim_evidence ce
              JOIN evidence e ON e.evidence_id = ce.evidence_id
              JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
              JOIN citation ci ON ci.citation_id = ec.citation_id
              JOIN source_record sr ON sr.source_record_id = ci.source_record_id
              JOIN dataset d ON d.dataset_id = sr.dataset_id
              JOIN source s ON s.source_id = d.source_id
              WHERE ce.claim_id = c.claim_id AND ce.relation_type_code = 'SUPPORTS'
          )
    ) THEN RAISE EXCEPTION 'phase37r: direct claim lacks complete cited provenance'; END IF;

    IF EXISTS (
        SELECT 1 FROM claim c JOIN claim_evidence ce ON ce.claim_id = c.claim_id
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
          AND e.evidence_type_code <> 'SOURCE_OBSERVATION'
    ) THEN RAISE EXCEPTION 'phase37r: scholarship was promoted to a direct claim'; END IF;

    SELECT count(*) INTO actual
    FROM evidence e
    WHERE e.evidence_key IN ('EV_P37R_BADGER_INTERPRETATION', 'EV_P37R_RYDELL_INTERPRETATION')
      AND e.evidence_type_code = 'ANALYTICAL_OBSERVATION'
      AND NOT EXISTS (SELECT 1 FROM claim_evidence ce WHERE ce.evidence_id = e.evidence_id);
    IF actual <> 2 THEN RAISE EXCEPTION 'phase37r: expected two isolated scholarly observations, found %', actual; END IF;

    SELECT count(*) INTO actual
    FROM source_identity si
    WHERE si.source_identity_key IN ('phase37r-directory-edison-name', 'phase37r-barrett-george-westinghouse')
      AND NOT EXISTS (SELECT 1 FROM entity_source_mapping esm WHERE esm.source_identity_id = si.source_identity_id);
    IF actual <> 2 THEN RAISE EXCEPTION 'phase37r: unresolved person identities were silently reconciled'; END IF;

    IF EXISTS (
        SELECT 1 FROM proposition p
        JOIN entity subject ON subject.entity_id = p.subject_entity_id
        JOIN entity object ON object.entity_id = p.object_entity_id
        WHERE subject.entity_key LIKE 'phase37r\_%' ESCAPE '\'
          AND subject.entity_type_code = 'PERSON' AND object.entity_type_code = 'ORGANIZATION'
    ) THEN RAISE EXCEPTION 'phase37r: person-to-organization relation was invented'; END IF;

    IF EXISTS (
        SELECT 1 FROM predicate
        WHERE predicate_code IN ('memberOf', 'employedBy', 'exhibited', 'wonAgainst',
                                 'superiorTo', 'caused', 'sameAs')
    ) THEN RAISE EXCEPTION 'phase37r: unsupported predicate was registered'; END IF;

    IF EXISTS (
        SELECT 1 FROM claim_relation cr
        JOIN claim c ON c.claim_id = cr.claim_id
        WHERE c.claim_key LIKE 'CLAIM\_P37R\_%' ESCAPE '\'
    ) THEN RAISE EXCEPTION 'phase37r: interpretation or derived relation was persisted'; END IF;

    IF EXISTS (
        SELECT 1 FROM source s
        JOIN dataset d ON d.source_id = s.source_id
        WHERE s.source_key = 'WORLDS_FAIR_CHICAGO_1893_PEOPLE'
          AND d.dataset_key LIKE '%\_P37R' ESCAPE '\'
    ) THEN RAISE EXCEPTION 'phase37r: discovery-only people index entered the claim corpus'; END IF;

    RAISE NOTICE 'ok: Phase 37R expanded population is provenance-backed, locator-only, and preserves discovery, scholarship, identity, and registry boundaries.';
END $$;
