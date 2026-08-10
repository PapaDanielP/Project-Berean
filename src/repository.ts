import type { Pool } from 'pg';
import type { ExplainProvenanceInput, ExploreTimelineInput, GraphEdge, GraphNode, SearchResult } from './types.js';

const boundedLimit = (value: number | undefined, fallback: number, max: number): number => {
  if (!value || Number.isNaN(value)) return fallback;
  return Math.max(1, Math.min(max, value));
};

export class BereanRepository {
  constructor(private readonly pool: Pool) {}

  async search(q: string, limit?: number): Promise<SearchResult[]> {
    const safeLimit = boundedLimit(limit, 20, 50);
    const term = `%${q}%`;
    const { rows } = await this.pool.query(
      `
      WITH search_results AS (
        SELECT 'entity'::text AS type, entity_id AS id, entity_key AS key,
               canonical_name AS label, entity_type_code AS detail
        FROM entity
        WHERE entity_key ILIKE $1 OR canonical_name ILIKE $1
        UNION ALL
        SELECT 'event', event_id, event_key, event_key, event_type_code
        FROM event
        WHERE event_key ILIKE $1 OR COALESCE(description, '') ILIKE $1
        UNION ALL
        SELECT 'claim', claim_id, claim_key, claim_key, claim_type_code
        FROM claim
        WHERE claim_key ILIKE $1 OR COALESCE(statement, '') ILIKE $1
        UNION ALL
        SELECT 'proposition', proposition_id, proposition_id::text,
               predicate || ' proposition', predicate
        FROM proposition
        WHERE predicate ILIKE $1
        UNION ALL
        SELECT 'evidence', evidence_id, evidence_key, evidence_key, evidence_type_code
        FROM evidence
        WHERE evidence_key ILIKE $1 OR COALESCE(observation, '') ILIKE $1
        UNION ALL
        SELECT 'source', source_id, source_key, name, source_type_code
        FROM source
        WHERE source_key ILIKE $1 OR name ILIKE $1
        UNION ALL
        SELECT 'dataset', dataset_id, dataset_key, name, edition_label
        FROM dataset
        WHERE dataset_key ILIKE $1 OR name ILIKE $1 OR COALESCE(version, '') ILIKE $1
        UNION ALL
        SELECT 'source_record', source_record_id, source_record_key, source_location, source_location
        FROM source_record
        WHERE source_record_key ILIKE $1 OR COALESCE(source_location, '') ILIKE $1
        UNION ALL
        SELECT 'citation', citation_id, citation_key, locator, locator
        FROM citation
        WHERE citation_key ILIKE $1 OR locator ILIKE $1
        UNION ALL
        SELECT 'source_identity', source_identity_id, source_identity_key, display_name, display_name
        FROM source_identity
        WHERE source_identity_key ILIKE $1 OR display_name ILIKE $1
      )
      SELECT type, id, key, label, detail
      FROM search_results
      ORDER BY type, key
      LIMIT $2
      `,
      [term, safeLimit]
    );

    return rows;
  }

  async getEntity(entityId: number): Promise<Record<string, unknown> | null> {
    const entityResult = await this.pool.query(
      `SELECT entity_id, entity_key, entity_type_code, canonical_name, description
       FROM entity WHERE entity_id = $1`,
      [entityId]
    );
    if (!entityResult.rowCount) return null;

    const [mappings, claims, events, relatedEntities] = await Promise.all([
      this.pool.query(
        `SELECT esm.entity_source_mapping_id, esm.mapping_status_code, esm.confidence, esm.justification,
                esm.notes, si.source_identity_id, si.source_identity_key, si.display_name,
                s.source_id, s.source_key, s.name AS source_name
         FROM entity_source_mapping esm
         JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
         JOIN source s ON s.source_id = si.source_id
         WHERE esm.entity_id = $1
         ORDER BY esm.entity_source_mapping_id`,
        [entityId]
      ),
      this.pool.query(
        `SELECT DISTINCT c.claim_id, c.claim_key, c.claim_type_code, c.claim_status_code,
                c.statement, c.proposition_id
         FROM claim c
         JOIN proposition p ON p.proposition_id = c.proposition_id
         WHERE p.subject_entity_id = $1 OR p.object_entity_id = $1
         ORDER BY c.claim_id`,
        [entityId]
      ),
      this.pool.query(
        `SELECT ep.event_id, ev.event_key, ev.event_type_code, ep.role_code, ep.asserting_claim_id
         FROM event_participation ep
         JOIN event ev ON ev.event_id = ep.event_id
         WHERE ep.entity_id = $1
         ORDER BY ep.event_id, ep.role_code`,
        [entityId]
      ),
      this.pool.query(
        `SELECT DISTINCT other.entity_id, other.entity_key, other.canonical_name,
                p.predicate, c.claim_id, c.claim_key
         FROM proposition p
         JOIN claim c ON c.proposition_id = p.proposition_id
         JOIN entity other ON other.entity_id =
              CASE WHEN p.subject_entity_id = $1 THEN p.object_entity_id
                   WHEN p.object_entity_id = $1 THEN p.subject_entity_id END
         WHERE p.subject_entity_id = $1 OR p.object_entity_id = $1
         ORDER BY other.entity_id`,
        [entityId]
      )
    ]);

    return {
      entity: entityResult.rows[0],
      sourceMappings: mappings.rows,
      claims: claims.rows,
      events: events.rows,
      relatedEntities: relatedEntities.rows
    };
  }

  async getClaim(claimId: number): Promise<Record<string, unknown> | null> {
    const claimResult = await this.pool.query(
      `SELECT c.claim_id, c.claim_key, c.claim_type_code, c.claim_status_code, c.statement,
              c.notes, c.derivation_id, c.proposition_id, cr.rendered_proposition
       FROM claim c
       LEFT JOIN claim_rendering cr ON cr.claim_id = c.claim_id
       WHERE c.claim_id = $1`,
      [claimId]
    );
    if (!claimResult.rowCount) return null;

    const claim = claimResult.rows[0];
    const propositionId = claim.proposition_id as number;

    const [proposition, evidence, relations, derivation, derivationInputs] = await Promise.all([
      this.pool.query(
        `SELECT p.proposition_id, p.predicate,
                p.subject_entity_id, se.canonical_name AS subject_entity_name,
                p.subject_event_id, sv.event_key AS subject_event_key,
                p.object_entity_id, oe.canonical_name AS object_entity_name,
                p.object_event_id, ov.event_key AS object_event_key,
                p.object_typed_value_id, tv.value_type_code, tv.text_value, tv.numeric_value,
                tv.date_value, tv.duration_value
         FROM proposition p
         LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
         LEFT JOIN event sv ON sv.event_id = p.subject_event_id
         LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
         LEFT JOIN event ov ON ov.event_id = p.object_event_id
         LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
         WHERE p.proposition_id = $1`,
        [propositionId]
      ),
      this.pool.query(
        `SELECT ce.relation_type_code, ce.notes AS relation_notes,
                e.evidence_id, e.evidence_key, e.evidence_type_code, e.observation,
                sr.source_record_id, sr.source_record_key, sr.source_location,
                d.dataset_id, d.dataset_key, d.name AS dataset_name,
                s.source_id, s.source_key, s.name AS source_name,
                c.citation_id, c.citation_key, c.locator, c.quoted_text
         FROM claim_evidence ce
         JOIN evidence e ON e.evidence_id = ce.evidence_id
         JOIN source_record sr ON sr.source_record_id = e.source_record_id
         JOIN dataset d ON d.dataset_id = sr.dataset_id
         JOIN source s ON s.source_id = d.source_id
         LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
         LEFT JOIN citation c ON c.citation_id = ec.citation_id
         WHERE ce.claim_id = $1
         ORDER BY e.evidence_id, c.citation_id`,
        [claimId]
      ),
      this.pool.query(
        `SELECT cr.claim_relation_id, cr.relation_type_code, cr.notes,
                cr.related_claim_id, rc.claim_key AS related_claim_key,
                cr.claim_id, c.claim_key
         FROM claim_relation cr
         JOIN claim c ON c.claim_id = cr.claim_id
         JOIN claim rc ON rc.claim_id = cr.related_claim_id
         WHERE cr.claim_id = $1 OR cr.related_claim_id = $1
         ORDER BY cr.claim_relation_id`,
        [claimId]
      ),
      this.pool.query(
        `SELECT derivation_id, method, assumptions, created_at
         FROM derivation WHERE derivation_id = $1`,
        [claim.derivation_id]
      ),
      this.pool.query(
        `SELECT di.derivation_input_id, di.notes,
                di.input_claim_id, ic.claim_key AS input_claim_key,
                di.input_evidence_id, ie.evidence_key AS input_evidence_key
         FROM derivation_input di
         LEFT JOIN claim ic ON ic.claim_id = di.input_claim_id
         LEFT JOIN evidence ie ON ie.evidence_id = di.input_evidence_id
         WHERE di.derivation_id = $1
         ORDER BY di.derivation_input_id`,
        [claim.derivation_id]
      )
    ]);

    return {
      claim,
      proposition: proposition.rows[0] ?? null,
      evidence: evidence.rows,
      claimRelations: relations.rows,
      derivation: derivation.rows[0] ?? null,
      derivationInputs: derivationInputs.rows
    };
  }

  async getProposition(propositionId: number): Promise<Record<string, unknown> | null> {
    const proposition = await this.pool.query(
      `SELECT p.proposition_id, p.predicate,
              p.subject_entity_id, se.entity_key AS subject_entity_key, se.canonical_name AS subject_entity_name,
              p.subject_event_id, sv.event_key AS subject_event_key,
              p.object_entity_id, oe.entity_key AS object_entity_key, oe.canonical_name AS object_entity_name,
              p.object_event_id, ov.event_key AS object_event_key,
              p.object_typed_value_id, tv.value_type_code, tv.text_value, tv.numeric_value, tv.date_value
       FROM proposition p
       LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
       LEFT JOIN event sv ON sv.event_id = p.subject_event_id
       LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
       LEFT JOIN event ov ON ov.event_id = p.object_event_id
       LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
       WHERE p.proposition_id = $1`,
      [propositionId]
    );
    if (!proposition.rowCount) return null;

    const claims = await this.pool.query(
      `SELECT claim_id, claim_key, claim_type_code, claim_status_code, statement
       FROM claim
       WHERE proposition_id = $1
       ORDER BY claim_id`,
      [propositionId]
    );

    return { proposition: proposition.rows[0], claims: claims.rows };
  }

  async getEvent(eventId: number): Promise<Record<string, unknown> | null> {
    const event = await this.pool.query(
      `SELECT event_id, event_key, event_type_code, description FROM event WHERE event_id = $1`,
      [eventId]
    );
    if (!event.rowCount) return null;

    const [participation, claims] = await Promise.all([
      this.pool.query(
        `SELECT ep.role_code, ep.asserting_claim_id, en.entity_id, en.entity_key, en.canonical_name,
                c.claim_key, c.claim_type_code
         FROM event_participation ep
         JOIN entity en ON en.entity_id = ep.entity_id
         JOIN claim c ON c.claim_id = ep.asserting_claim_id
         WHERE ep.event_id = $1
         ORDER BY ep.role_code, en.canonical_name`,
        [eventId]
      ),
      this.pool.query(
        `SELECT DISTINCT c.claim_id, c.claim_key, c.claim_type_code, c.claim_status_code, c.statement
         FROM claim c
         JOIN proposition p ON p.proposition_id = c.proposition_id
         WHERE p.subject_event_id = $1 OR p.object_event_id = $1
         ORDER BY c.claim_id`,
        [eventId]
      )
    ]);

    return {
      event: event.rows[0],
      participation: participation.rows,
      claims: claims.rows
    };
  }

  async listSources(): Promise<Record<string, unknown>[]> {
    const result = await this.pool.query(
      `SELECT s.source_id, s.source_key, s.name, s.source_type_code,
              count(DISTINCT d.dataset_id)::int AS dataset_count,
              count(DISTINCT sr.source_record_id)::int AS source_record_count
       FROM source s
       LEFT JOIN dataset d ON d.source_id = s.source_id
       LEFT JOIN source_record sr ON sr.dataset_id = d.dataset_id
       GROUP BY s.source_id
       ORDER BY s.source_key`
    );
    return result.rows;
  }

  async getSource(sourceId: number): Promise<Record<string, unknown> | null> {
    const source = await this.pool.query(
      `SELECT source_id, source_key, name, source_type_code, description
       FROM source WHERE source_id = $1`,
      [sourceId]
    );
    if (!source.rowCount) return null;

    const datasets = await this.pool.query(
      `SELECT d.dataset_id, d.dataset_key, d.name, d.edition_label, d.version,
              d.license_status, d.acquisition_method, d.transformation_notes,
              count(sr.source_record_id)::int AS source_record_count
       FROM dataset d
       LEFT JOIN source_record sr ON sr.dataset_id = d.dataset_id
       WHERE d.source_id = $1
       GROUP BY d.dataset_id
       ORDER BY d.dataset_key`,
      [sourceId]
    );

    const records = await this.pool.query(
      `SELECT sr.source_record_id, sr.source_record_key, sr.source_location, sr.raw_content,
              sr.content_hash, sr.revision_label, d.dataset_key
       FROM source_record sr
       JOIN dataset d ON d.dataset_id = sr.dataset_id
       WHERE d.source_id = $1
       ORDER BY d.dataset_key, sr.source_record_key
       LIMIT 200`,
      [sourceId]
    );

    return { source: source.rows[0], datasets: datasets.rows, sourceRecords: records.rows };
  }

  async getClaimProvenance(claimId: number): Promise<Record<string, unknown>> {
    const result = await this.pool.query(
      `SELECT c.claim_id, c.claim_key, c.claim_type_code,
              e.evidence_id, e.evidence_key, e.evidence_type_code,
              sr.source_record_id, sr.source_record_key, sr.source_location, sr.raw_content,
              d.dataset_id, d.dataset_key, d.name AS dataset_name,
              s.source_id, s.source_key, s.name AS source_name,
              ci.citation_id, ci.citation_key, ci.locator, ci.quoted_text,
              ce.relation_type_code
       FROM claim c
       LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
       LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
       LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
       LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
       LEFT JOIN source s ON s.source_id = d.source_id
       LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
       LEFT JOIN citation ci ON ci.citation_id = ec.citation_id
       WHERE c.claim_id = $1
       ORDER BY e.evidence_id, ci.citation_id`,
      [claimId]
    );

    return { claimId, traversal: result.rows };
  }

  async explainProvenance(input: ExplainProvenanceInput): Promise<Record<string, unknown> | null> {
    const resolutionScope = input.claimId ? 'CLAIM' : 'PROPOSITION';
    const propositionLookupId = input.propositionId ?? null;
    const claimLookupId = input.claimId ?? null;
    const gapSet = new Set<string>();
    const dedupeRows = <T extends { [key: string]: unknown }>(rows: T[], key: keyof T): T[] => {
      const seen = new Set<string>();
      return rows.filter((row) => {
        const value = String(row[key] ?? '');
        if (seen.has(value)) return false;
        seen.add(value);
        return true;
      });
    };

    const propositionResult = await this.pool.query(
      `SELECT p.proposition_id, p.predicate,
              pr.description AS predicate_description,
              pr.subject_kind_code, pr.object_kind_code, pr.event_participation_role_code,
              p.subject_entity_id, se.entity_key AS subject_entity_key, se.canonical_name AS subject_entity_name,
              p.subject_event_id, sv.event_key AS subject_event_key, sv.event_type_code AS subject_event_type_code,
              p.object_entity_id, oe.entity_key AS object_entity_key, oe.canonical_name AS object_entity_name,
              p.object_event_id, ov.event_key AS object_event_key, ov.event_type_code AS object_event_type_code,
              p.object_typed_value_id, tv.value_type_code, tv.text_value, tv.numeric_value, tv.date_value, tv.duration_value
       FROM proposition p
       JOIN predicate pr ON pr.predicate_code = p.predicate
       LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
       LEFT JOIN event sv ON sv.event_id = p.subject_event_id
       LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
       LEFT JOIN event ov ON ov.event_id = p.object_event_id
       LEFT JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
       WHERE p.proposition_id = COALESCE($1, (SELECT proposition_id FROM claim WHERE claim_id = $2))`,
      [propositionLookupId, claimLookupId]
    );

    if (!propositionResult.rowCount) return null;

    const proposition = propositionResult.rows[0];
    const claimsResult = await this.pool.query(
      `SELECT c.claim_id, c.claim_key, c.claim_type_code, c.claim_status_code, c.statement, c.notes, c.derivation_id
       FROM claim c
       WHERE c.proposition_id = $1
         AND ($2::bigint IS NULL OR c.claim_id = $2)
       ORDER BY c.claim_id`,
      [proposition.proposition_id, claimLookupId]
    );

    if (resolutionScope === 'PROPOSITION' && !claimsResult.rowCount) {
      gapSet.add('MISSING_PROPOSITION_CLAIM');
    }

    const claims = [];

    for (const claim of claimsResult.rows) {
      const claimGaps = new Set<string>();
      const evidenceTraversal = await this.pool.query(
        `SELECT ce.claim_evidence_id, ce.relation_type_code, ce.notes AS claim_evidence_notes,
                e.evidence_id, e.evidence_key, e.evidence_type_code, e.observation, e.notes AS evidence_notes,
                ec.citation_id AS linked_citation_id,
                ci.citation_key, ci.locator, ci.quoted_text,
                sr.source_record_id, sr.source_record_key, sr.source_location, sr.raw_content, sr.content_hash,
                d.dataset_id, d.dataset_key, d.name AS dataset_name,
                s.source_id, s.source_key, s.name AS source_name, s.source_type_code
         FROM claim c
         LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
         LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
         LEFT JOIN evidence_citation ec ON ec.evidence_id = e.evidence_id
         LEFT JOIN citation ci ON ci.citation_id = ec.citation_id
         LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
         LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
         LEFT JOIN source s ON s.source_id = d.source_id
         WHERE c.claim_id = $1
         ORDER BY e.evidence_id, ci.citation_id`,
        [claim.claim_id]
      );

      if (!evidenceTraversal.rowCount || evidenceTraversal.rows.every((row) => row.claim_evidence_id === null)) {
        claimGaps.add('MISSING_CLAIM_EVIDENCE');
      }

      const sourceChain = evidenceTraversal.rows
        .filter((row) => row.evidence_id !== null)
        .map((row) => ({
          claim_id: claim.claim_id,
          evidence_id: row.evidence_id,
          citation_id: row.linked_citation_id,
          source_record_id: row.source_record_id,
          dataset_id: row.dataset_id,
          source_id: row.source_id
        }));

      const supportingEvidence = dedupeRows(
        evidenceTraversal.rows
          .filter((row) => row.evidence_id !== null)
          .map((row) => ({
            evidence_id: row.evidence_id,
            evidence_key: row.evidence_key,
            evidence_type_code: row.evidence_type_code,
            relation_type_code: row.relation_type_code,
            observation: row.observation,
            notes: row.evidence_notes
          })),
        'evidence_id'
      );

      const citations = dedupeRows(
        evidenceTraversal.rows
          .filter((row) => row.linked_citation_id !== null)
          .map((row) => ({
            citation_id: row.linked_citation_id,
            citation_key: row.citation_key,
            locator: row.locator,
            quoted_text: row.quoted_text,
            quoted_text_status: row.quoted_text === null ? 'NOT_STORED_BY_POLICY' : 'STORED'
          })),
        'citation_id'
      );

      const sourceRecords = dedupeRows(
        evidenceTraversal.rows
          .filter((row) => row.source_record_id !== null)
          .map((row) => ({
            source_record_id: row.source_record_id,
            source_record_key: row.source_record_key,
            source_location: row.source_location,
            raw_content: row.raw_content,
            content_hash: row.content_hash,
            raw_content_status: row.raw_content === null ? 'NOT_STORED_BY_POLICY' : 'STORED'
          })),
        'source_record_id'
      );

      const datasets = dedupeRows(
        evidenceTraversal.rows
          .filter((row) => row.dataset_id !== null)
          .map((row) => ({
            dataset_id: row.dataset_id,
            dataset_key: row.dataset_key,
            dataset_name: row.dataset_name
          })),
        'dataset_id'
      );

      const sources = dedupeRows(
        evidenceTraversal.rows
          .filter((row) => row.source_id !== null)
          .map((row) => ({
            source_id: row.source_id,
            source_key: row.source_key,
            source_name: row.source_name,
            source_type_code: row.source_type_code
          })),
        'source_id'
      );

      for (const row of evidenceTraversal.rows.filter((entry) => entry.evidence_id !== null)) {
        if (row.linked_citation_id === null) claimGaps.add('MISSING_CITATION');
        if (row.source_record_id === null) claimGaps.add('MISSING_SOURCE_RECORD');
        if (row.dataset_id === null) claimGaps.add('MISSING_DATASET');
        if (row.source_id === null) claimGaps.add('MISSING_SOURCE');
      }

      const projectedRelationshipsResult = await this.pool.query(
        `SELECT ep.asserting_claim_id, ep.role_code, ev.event_id, ev.event_key, ev.event_type_code,
                en.entity_id, en.entity_key, en.canonical_name
         FROM event_participation ep
         JOIN event ev ON ev.event_id = ep.event_id
         JOIN entity en ON en.entity_id = ep.entity_id
         WHERE ep.asserting_claim_id = $1
         ORDER BY ev.event_id, en.entity_id`,
        [claim.claim_id]
      );

      if (proposition.event_participation_role_code && !projectedRelationshipsResult.rowCount) {
        claimGaps.add('MISSING_PROJECTED_RELATIONSHIP');
      }

      let derivation: Record<string, unknown> | null = null;
      let derivationInputs: Record<string, unknown>[] = [];

      if (claim.claim_type_code === 'DERIVED_CLAIM') {
        if (!claim.derivation_id) {
          claimGaps.add('MISSING_DERIVATION');
        } else {
          const derivationResult = await this.pool.query(
            `SELECT derivation_id, method, assumptions, created_at
             FROM derivation
             WHERE derivation_id = $1`,
            [claim.derivation_id]
          );
          derivation = derivationResult.rows[0] ?? null;
          if (!derivation) {
            claimGaps.add('MISSING_DERIVATION');
          }

          const inputsResult = await this.pool.query(
            `SELECT di.derivation_input_id, di.notes,
                    di.input_claim_id, ic.claim_key AS input_claim_key,
                    di.input_evidence_id, ie.evidence_key AS input_evidence_key
             FROM derivation_input di
             LEFT JOIN claim ic ON ic.claim_id = di.input_claim_id
             LEFT JOIN evidence ie ON ie.evidence_id = di.input_evidence_id
             WHERE di.derivation_id = $1
             ORDER BY di.derivation_input_id`,
            [claim.derivation_id]
          );
          derivationInputs = inputsResult.rows;

          if (!inputsResult.rowCount) {
            claimGaps.add('MISSING_DERIVATION_INPUT');
          }

          for (const inputRow of inputsResult.rows) {
            const hasClaimInput = inputRow.input_claim_id !== null;
            const hasEvidenceInput = inputRow.input_evidence_id !== null;
            if (hasClaimInput === hasEvidenceInput) {
              claimGaps.add('INVALID_DERIVATION_INPUT');
            }
            if (inputRow.input_claim_id === claim.claim_id) {
              claimGaps.add('SELF_INPUT_DERIVATION');
            }
            if (hasClaimInput && inputRow.input_claim_key === null) {
              claimGaps.add('INVALID_DERIVATION_INPUT');
            }
            if (hasEvidenceInput && inputRow.input_evidence_key === null) {
              claimGaps.add('INVALID_DERIVATION_INPUT');
            }
          }
        }
      }

      const structuralGaps = Array.from(claimGaps);
      for (const gap of structuralGaps) gapSet.add(gap);

      const provenanceStatus =
        claim.claim_type_code === 'DIRECT_SOURCE_CLAIM'
          ? structuralGaps.length
            ? 'SOURCE-BACKED_WITH_GAPS'
            : 'SOURCE-BACKED'
          : claim.claim_type_code === 'DERIVED_CLAIM'
            ? structuralGaps.length
              ? 'DERIVED_WITH_GAPS'
              : 'DERIVED'
            : structuralGaps.length
              ? 'CLAIM_WITH_GAPS'
              : 'NOT DERIVED';

      claims.push({
        claim,
        proposition,
        claim_type: claim.claim_type_code,
        claim_status: claim.claim_status_code,
        provenance_status: provenanceStatus,
        source_chain: sourceChain,
        supporting_evidence: supportingEvidence,
        citations,
        source_records: sourceRecords,
        datasets,
        source: sources,
        derivation,
        derivation_inputs: derivationInputs,
        projected_relationships: projectedRelationshipsResult.rows,
        structural_gaps: structuralGaps,
        explanation:
          structuralGaps.length === 0
            ? 'Deterministic provenance traversal is structurally complete for this claim.'
            : `Deterministic traversal found structural gaps: ${structuralGaps.join(', ')}.`
      });
    }

    const structuralGaps = Array.from(gapSet);

    return {
      operation: 'EXPLAIN_PROVENANCE',
      input: { claim_id: claimLookupId, proposition_id: propositionLookupId },
      resolution_scope: resolutionScope,
      read_only: true,
      proposition,
      claims,
      provenance_status: structuralGaps.length ? 'INCOMPLETE' : 'COMPLETE',
      structural_gaps: structuralGaps,
      explanation:
        structuralGaps.length === 0
          ? 'Read-only deterministic traversal resolved the selected claim/proposition provenance chain.'
          : `Read-only deterministic traversal resolved the selected artifact and reported structural gaps: ${structuralGaps.join(', ')}.`,
      limitations: [
        'Evaluation is structural and deterministic only.',
        'No truth, contradiction, compliance, causation, theology, modal semantics, or generalized inference is assigned.',
        'NULL raw_content and NULL quoted_text are reported as not stored by policy.'
      ]
    };
  }

  async checkDerivationEligibility(derivationId: number): Promise<Record<string, unknown> | null> {
    type Status = 'PASS' | 'FAIL' | 'NOT_APPLICABLE';
    const checks: { id: string; status: Status; detail: string }[] = [];
    const check = (id: string, status: Status, detail: string): void => {
      checks.push({ id, status, detail });
    };
    const derivationResult = await this.pool.query(
      'SELECT derivation_id, method, assumptions, created_at FROM derivation WHERE derivation_id = $1',
      [derivationId]
    );
    if (!derivationResult.rowCount) return null;
    const derivation = derivationResult.rows[0];

    const claimResult = await this.pool.query(
      `SELECT c.claim_id, c.claim_key, c.claim_type_code, c.claim_status_code, c.statement, c.notes,
              c.derivation_id, p.proposition_id AS target_proposition_id, p.predicate,
              p.subject_kind_code, p.object_kind_code, pr.predicate_code AS registered_predicate_code,
              pr.subject_kind_code AS registered_subject_kind_code,
              pr.object_kind_code AS registered_object_kind_code
       FROM claim c
       LEFT JOIN proposition p ON p.proposition_id = c.proposition_id
       LEFT JOIN predicate pr ON pr.predicate_code = p.predicate
       WHERE c.derivation_id = $1`,
      [derivationId]
    );
    const claim = claimResult.rows[0] ?? null;

    const inputsResult = await this.pool.query(
      `SELECT di.derivation_input_id, di.notes, di.input_claim_id, ic.claim_key AS input_claim_key,
              di.input_evidence_id, ie.evidence_key AS input_evidence_key
       FROM derivation_input di
       LEFT JOIN claim ic ON ic.claim_id = di.input_claim_id
       LEFT JOIN evidence ie ON ie.evidence_id = di.input_evidence_id
       WHERE di.derivation_id = $1 ORDER BY di.derivation_input_id`,
      [derivationId]
    );
    const inputStatus = [];

    for (const input of inputsResult.rows) {
      const hasClaim = input.input_claim_id !== null;
      const hasEvidence = input.input_evidence_id !== null;
      const kindValid = hasClaim !== hasEvidence;
      const referenceValid = kindValid && (hasClaim ? input.input_claim_key !== null : input.input_evidence_key !== null);
      const selfInput = Boolean(claim && hasClaim && Number(input.input_claim_id) === Number(claim.claim_id));
      let provenanceComplete = false;
      if (referenceValid) {
        const provenance = await this.pool.query(
          hasClaim
            ? `SELECT ce.claim_evidence_id, e.evidence_id, e.evidence_type_code, sr.source_record_id, d.dataset_id, s.source_id,
                      EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id) AS has_citation
               FROM claim c LEFT JOIN claim_evidence ce ON ce.claim_id = c.claim_id
               LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
               LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
               LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
               LEFT JOIN source s ON s.source_id = d.source_id WHERE c.claim_id = $1`
            : `SELECT e.evidence_id, e.evidence_type_code, sr.source_record_id, d.dataset_id, s.source_id,
                      EXISTS (SELECT 1 FROM evidence_citation ec WHERE ec.evidence_id = e.evidence_id) AS has_citation
               FROM evidence e LEFT JOIN source_record sr ON sr.source_record_id = e.source_record_id
               LEFT JOIN dataset d ON d.dataset_id = sr.dataset_id
               LEFT JOIN source s ON s.source_id = d.source_id WHERE e.evidence_id = $1`,
          [hasClaim ? input.input_claim_id : input.input_evidence_id]
        );
        provenanceComplete = provenance.rows.length > 0 && provenance.rows.every((row) =>
          row.evidence_id !== null && row.source_record_id !== null && row.dataset_id !== null && row.source_id !== null
          && (row.evidence_type_code !== 'SOURCE_OBSERVATION' || row.has_citation)
        );
      }
      inputStatus.push({
        derivation_input_id: input.derivation_input_id,
        input_kind: hasClaim ? 'CLAIM' : hasEvidence ? 'EVIDENCE' : null,
        input_claim_id: input.input_claim_id, input_claim_key: input.input_claim_key,
        input_evidence_id: input.input_evidence_id, input_evidence_key: input.input_evidence_key,
        kind_valid: kindValid, reference_valid: referenceValid,
        provenance_structurally_complete: provenanceComplete, self_input: selfInput, notes: input.notes
      });
    }

    const hasInputs = inputStatus.length > 0;
    const validReferences = inputStatus.filter((input) => input.reference_valid);
    const targetExists = Boolean(claim?.target_proposition_id);
    const predicateValid = Boolean(claim?.registered_predicate_code);
    const termKindsValid = predicateValid
      && claim.subject_kind_code === claim.registered_subject_kind_code
      && claim.object_kind_code === claim.registered_object_kind_code;

    check('DERIVATION_EXISTS', 'PASS', 'The requested Derivation row exists.');
    check('DERIVED_CLAIM_EXISTS', claim ? 'PASS' : 'FAIL',
      claim ? 'A Claim is linked to this Derivation.' : 'No Claim is linked to this Derivation.');
    check('DERIVED_CLAIM_TYPE_VALID', !claim ? 'NOT_APPLICABLE' : claim.claim_type_code === 'DERIVED_CLAIM' ? 'PASS' : 'FAIL',
      !claim ? 'No linked Claim is available to inspect.' : 'The linked Claim type was inspected.');
    check('DERIVATION_LINK_VALID', !claim ? 'NOT_APPLICABLE' : Number(claim.derivation_id) === derivationId ? 'PASS' : 'FAIL',
      !claim ? 'No linked Claim is available to inspect.' : 'The linked Claim derivation reference was inspected.');
    check('METHOD_PRESENT', String(derivation.method).trim() ? 'PASS' : 'FAIL',
      String(derivation.method).trim() ? 'Method metadata is present.' : 'Method metadata is blank.');
    check('ASSUMPTIONS_PRESENT', String(derivation.assumptions).trim() ? 'PASS' : 'FAIL',
      String(derivation.assumptions).trim() ? 'Assumptions metadata is present.' : 'Assumptions metadata is blank.');
    check('DERIVATION_INPUT_EXISTS', hasInputs ? 'PASS' : 'FAIL',
      hasInputs ? 'At least one DerivationInput row exists.' : 'No DerivationInput rows exist.');
    check('DERIVATION_INPUT_KIND_VALID', !hasInputs ? 'NOT_APPLICABLE'
      : inputStatus.every((input) => input.kind_valid) ? 'PASS' : 'FAIL',
    hasInputs ? 'All DerivationInput kinds were inspected.' : 'No DerivationInput row is available to inspect.');
    check('DERIVATION_INPUT_REFERENCE_VALID', !hasInputs ? 'NOT_APPLICABLE'
      : validReferences.length === inputStatus.length ? 'PASS' : 'FAIL',
    hasInputs ? 'All DerivationInput references were inspected.' : 'No DerivationInput row is available to inspect.');
    check('INPUT_PROVENANCE_STRUCTURALLY_COMPLETE', validReferences.length === 0 ? 'NOT_APPLICABLE'
      : validReferences.every((input) => input.provenance_structurally_complete) ? 'PASS' : 'FAIL',
    validReferences.length
      ? 'All valid DerivationInput references were inspected through their structural provenance chains.'
      : 'No valid DerivationInput reference is available to inspect.');
    check('SELF_INPUT_ABSENT', !hasInputs ? 'NOT_APPLICABLE'
      : inputStatus.every((input) => !input.self_input) ? 'PASS' : 'FAIL',
    hasInputs ? 'All DerivationInput rows were inspected for self-reference.' : 'No DerivationInput row is available to inspect.');
    check('TARGET_PROPOSITION_EXISTS', !claim ? 'NOT_APPLICABLE' : targetExists ? 'PASS' : 'FAIL',
      !claim ? 'No linked Claim is available to inspect.' : 'The linked Claim target Proposition was inspected.');
    check('TARGET_PREDICATE_VALID', !targetExists ? 'NOT_APPLICABLE' : predicateValid ? 'PASS' : 'FAIL',
      !targetExists ? 'No target Proposition is available to inspect.' : 'The target predicate registry entry was inspected.');
    check('TARGET_TERM_KINDS_VALID', !targetExists || !predicateValid ? 'NOT_APPLICABLE' : termKindsValid ? 'PASS' : 'FAIL',
      !targetExists || !predicateValid
        ? 'No registered target predicate is available for term-kind inspection.'
        : 'The target Proposition term kinds were checked against the registry.');

    return {
      operation: 'CHECK_DERIVATION_ELIGIBILITY',
      derivation,
      derived_claim: claim ? {
        claim_id: claim.claim_id, claim_key: claim.claim_key, claim_type_code: claim.claim_type_code,
        claim_status_code: claim.claim_status_code, statement: claim.statement, notes: claim.notes
      } : null,
      target_proposition: claim?.target_proposition_id ? {
        proposition_id: claim.target_proposition_id, predicate: claim.predicate,
        subject_kind_code: claim.subject_kind_code, object_kind_code: claim.object_kind_code
      } : null,
      input_status: inputStatus,
      checks,
      structurally_eligible: checks.every((entry) => entry.status !== 'FAIL'),
      license_status: 'REQUIRES_HUMAN_METHOD_JUSTIFICATION',
      read_only: true,
      explanation: checks.some((entry) => entry.status === 'FAIL')
        ? 'The stored derivation has one or more structural eligibility failures.'
        : 'The stored derivation satisfies every applicable structural eligibility check.',
      limitations: [
        'Structural eligibility is not logical entailment.',
        'Method and assumptions are returned as stored metadata without semantic interpretation.',
        'This read-only operation does not create, modify, or persist any artifact.'
      ]
    };
  }

  private async exploreClaim(claimId: number): Promise<Record<string, unknown>> {
    const explanation = await this.explainProvenance({ claimId });
    const entry = ((explanation?.claims as Record<string, unknown>[] | undefined) ?? [])[0] ?? {};
    const claim = (entry.claim as Record<string, unknown>) ?? {};
    const proposition = (entry.proposition as Record<string, unknown>) ?? {};
    const projected = (entry.projected_relationships as Record<string, unknown>[]) ?? [];

    return {
      record_type: 'STORED_CLAIM',
      claim: {
        claim_id: claim.claim_id,
        claim_key: claim.claim_key,
        claim_type_code: claim.claim_type_code,
        claim_status_code: claim.claim_status_code,
        notes: claim.notes,
        statement: claim.statement,
        statement_role: 'DISPLAY_METADATA_ONLY'
      },
      proposition: {
        proposition_id: proposition.proposition_id,
        predicate: proposition.predicate,
        subject_entity_id: proposition.subject_entity_id,
        subject_entity_key: proposition.subject_entity_key,
        subject_entity_name: proposition.subject_entity_name,
        subject_event_id: proposition.subject_event_id,
        subject_event_key: proposition.subject_event_key,
        subject_event_type_code: proposition.subject_event_type_code,
        object_entity_id: proposition.object_entity_id,
        object_entity_key: proposition.object_entity_key,
        object_entity_name: proposition.object_entity_name,
        object_event_id: proposition.object_event_id,
        object_event_key: proposition.object_event_key,
        object_event_type_code: proposition.object_event_type_code,
        object_typed_value_id: proposition.object_typed_value_id,
        value_type_code: proposition.value_type_code,
        text_value: proposition.text_value,
        numeric_value: proposition.numeric_value,
        date_value: proposition.date_value,
        duration_value: proposition.duration_value,
        authority: 'AUTHORITATIVE_STRUCTURED_CONTENT'
      },
      predicate: {
        predicate_code: proposition.predicate,
        description: proposition.predicate_description,
        subject_kind_code: proposition.subject_kind_code,
        object_kind_code: proposition.object_kind_code,
        event_participation_role_code: proposition.event_participation_role_code
      },
      provenance: {
        provenance_status: entry.provenance_status ?? null,
        source_chain: entry.source_chain ?? [],
        supporting_evidence: entry.supporting_evidence ?? [],
        citations: entry.citations ?? [],
        source_records: entry.source_records ?? [],
        datasets: entry.datasets ?? [],
        sources: entry.source ?? [],
        structural_gaps: entry.structural_gaps ?? []
      },
      derivation: entry.derivation ?? null,
      derivation_inputs: entry.derivation_inputs ?? [],
      projected_relationships: projected.map((row) => ({
        ...row,
        projection: 'PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION'
      }))
    };
  }

  private async exploreEventTemporalMetadata(eventId: number): Promise<Record<string, unknown>> {
    const stored = await this.pool.query(
      `SELECT p.proposition_id, p.predicate, c.claim_id, c.claim_key,
              tv.typed_value_id, tv.value_type_code, tv.text_value, tv.numeric_value,
              tv.date_value, tv.duration_value, tv.uncertainty_lower, tv.uncertainty_upper
       FROM proposition p
       JOIN typed_value tv ON tv.typed_value_id = p.object_typed_value_id
       JOIN claim c ON c.proposition_id = p.proposition_id
       WHERE p.subject_event_id = $1
       ORDER BY tv.typed_value_id, c.claim_id`,
      [eventId]
    );

    const storedDates = stored.rows.filter((row) => row.date_value !== null);
    const chronological = stored.rows.filter(
      (row) => row.date_value === null && row.numeric_value !== null && row.value_type_code === 'YEAR'
    );

    return {
      temporal_status: storedDates.length
        ? 'DATE_KNOWN'
        : chronological.length
          ? 'CHRONOLOGICAL_METADATA_STORED'
          : 'DATE_NOT_STORED',
      stored_dates: storedDates,
      chronological_metadata: chronological,
      note: 'No date is inferred, calculated, or narrated. Only stored typed values are reported.'
    };
  }

  // Sparse-state coverage metadata for an already-selected entity. It reports only what the
  // database currently represents, so an explorer can distinguish an unpopulated subject from a
  // populated one. Absence is never reported as source silence, falsity, or nonexistence.
  private async exploreEntityCoverage(
    entityId: number,
    entityTypeCode: string,
    canonicalName: string
  ): Promise<Record<string, unknown>> {
    const modelled = await this.pool.query(
      `WITH entity_claim AS (
         SELECT DISTINCT c.claim_id, c.claim_type_code
         FROM proposition p
         JOIN claim c ON c.proposition_id = p.proposition_id
         WHERE p.subject_entity_id = $1 OR p.object_entity_id = $1
       ),
       entity_event AS (
         SELECT DISTINCT ev.event_id
         FROM event ev
         JOIN proposition p ON (p.object_event_id = ev.event_id AND p.subject_entity_id = $1)
                            OR (p.subject_event_id = ev.event_id AND p.object_entity_id = $1)
         JOIN claim c ON c.proposition_id = p.proposition_id
       ),
       chain AS (
         SELECT ec.claim_id, s.source_id, ci.citation_id, sr.source_record_id
         FROM entity_claim ec
         JOIN claim_evidence ce ON ce.claim_id = ec.claim_id
         JOIN evidence e ON e.evidence_id = ce.evidence_id
         JOIN evidence_citation ecit ON ecit.evidence_id = e.evidence_id
         JOIN citation ci ON ci.citation_id = ecit.citation_id
         JOIN source_record sr ON sr.source_record_id = ci.source_record_id
         JOIN dataset d ON d.dataset_id = sr.dataset_id
         JOIN source s ON s.source_id = d.source_id
       )
       SELECT
         (SELECT count(*)::int FROM entity_claim) AS claim_count,
         (SELECT count(*)::int FROM entity_claim WHERE claim_type_code = 'DERIVED_CLAIM') AS derived_claim_count,
         (SELECT count(*)::int FROM entity_claim WHERE claim_type_code <> 'DERIVED_CLAIM') AS non_derived_claim_count,
         (SELECT count(*)::int FROM entity_event) AS event_count,
         (SELECT count(DISTINCT source_id)::int FROM chain) AS source_count,
         (SELECT count(DISTINCT citation_id)::int FROM chain) AS modeled_reference_count,
         (SELECT count(DISTINCT claim_id)::int FROM chain) AS claims_with_source_chain,
         (SELECT count(DISTINCT ch.source_record_id)::int
            FROM chain ch
            JOIN source_record sr ON sr.source_record_id = ch.source_record_id
           WHERE sr.raw_content IS NOT NULL) AS stored_source_text_count`,
      [entityId]
    );

    // Source records that mention this entity by canonical name in a stored observation but do not
    // yet back any claim about it. This is unmodeled related material, not evidence of absence.
    const candidates = await this.pool.query(
      `SELECT count(DISTINCT sr.source_record_id)::int AS candidate_reference_count
       FROM evidence e
       JOIN source_record sr ON sr.source_record_id = e.source_record_id
       WHERE position(lower($2) in lower(e.observation)) > 0
         AND NOT EXISTS (
           SELECT 1
           FROM claim_evidence ce
           JOIN claim c ON c.claim_id = ce.claim_id
           JOIN proposition p ON p.proposition_id = c.proposition_id
           WHERE ce.evidence_id = e.evidence_id
             AND (p.subject_entity_id = $1 OR p.object_entity_id = $1)
         )`,
      [entityId, canonicalName]
    );

    const row = modelled.rows[0];
    const claimCount = Number(row.claim_count);
    const eventCount = Number(row.event_count);
    const sourceCount = Number(row.source_count);
    const derivedClaimCount = Number(row.derived_claim_count);
    const nonDerivedClaimCount = Number(row.non_derived_claim_count);
    const claimsWithSourceChain = Number(row.claims_with_source_chain);
    const storedSourceTextCount = Number(row.stored_source_text_count);
    const modeledReferenceCount = Number(row.modeled_reference_count);
    const candidateReferenceCount = Number(candidates.rows[0].candidate_reference_count);

    const provenanceStatus =
      nonDerivedClaimCount === 0
        ? 'NO_SOURCE_BACKED_CLAIM'
        : claimsWithSourceChain >= nonDerivedClaimCount
          ? 'COMPLETE_SOURCE_CHAIN'
          : 'INCOMPLETE_SOURCE_CHAIN';

    const coverageStatus =
      claimCount === 0
        ? 'ENTITY_EXISTS_NO_CLAIMS'
        : sourceCount === 0
          ? 'CLAIMS_EXIST_NO_PROVENANCE'
          : eventCount === 0
            ? 'ENTITY_EXISTS_NO_EVENTS'
            : storedSourceTextCount === 0
              ? 'EVIDENCE_EXISTS_SOURCE_TEXT_NOT_STORED'
              : 'EVIDENCE_EXISTS_SOURCE_TEXT_STORED';

    const labels: string[] = [];
    if (claimsWithSourceChain > 0) labels.push('SOURCE-BACKED');
    if (derivedClaimCount > 0) labels.push('DERIVED-STRUCTURALLY');
    if (claimCount === 0) labels.push('NOT-YET-MODELED');
    if (candidateReferenceCount > 0) labels.push('CANDIDATE-REQUIRES-REVIEW');

    return {
      coverage_status: coverageStatus,
      entity_type: entityTypeCode,
      claim_count: claimCount,
      event_count: eventCount,
      source_count: sourceCount,
      provenance_status: provenanceStatus,
      modeled_reference_count: modeledReferenceCount,
      candidate_reference_count: candidateReferenceCount,
      related_source_material_status:
        candidateReferenceCount > 0 ? 'RELATED_SOURCE_MATERIAL_NOT_YET_MODELED' : 'NO_UNMODELED_RELATED_SOURCE_MATERIAL',
      labels,
      note: 'Coverage describes what Berean currently represents. Absence of a claim, event, or source is never source silence, falsity, or nonexistence.'
    };
  }

  async exploreEntityTimeline(input: ExploreTimelineInput): Promise<Record<string, unknown> | null> {
    const entityResult = await this.pool.query(
      `SELECT entity_id, entity_key, entity_type_code, canonical_name, description
       FROM entity
       WHERE ($1::bigint IS NOT NULL AND entity_id = $1)
          OR ($2::text IS NOT NULL AND entity_key = $2)`,
      [input.entityId ?? null, input.entityKey ?? null]
    );
    if (!entityResult.rowCount) return null;

    const entity = entityResult.rows[0];
    const entityId = Number(entity.entity_id);

    const eventsResult = await this.pool.query(
      `SELECT DISTINCT ev.event_id, ev.event_key, ev.event_type_code, ev.description
       FROM event ev
       JOIN proposition p ON (p.object_event_id = ev.event_id AND p.subject_entity_id = $1)
                          OR (p.subject_event_id = ev.event_id AND p.object_entity_id = $1)
       JOIN claim c ON c.proposition_id = p.proposition_id
       ORDER BY ev.event_id`,
      [entityId]
    );

    const timeline = [];
    const claimIds = new Set<number>();

    for (const event of eventsResult.rows) {
      const eventClaims = await this.pool.query(
        `SELECT DISTINCT c.claim_id
         FROM claim c
         JOIN proposition p ON p.proposition_id = c.proposition_id
         WHERE p.subject_event_id = $1 OR p.object_event_id = $1
         ORDER BY c.claim_id`,
        [event.event_id]
      );

      const claims = [];
      for (const row of eventClaims.rows) {
        claimIds.add(Number(row.claim_id));
        claims.push(await this.exploreClaim(Number(row.claim_id)));
      }

      const participation = await this.pool.query(
        `SELECT ep.event_id, ev.event_key, ev.event_type_code,
                ep.entity_id, en.entity_key, en.canonical_name, en.entity_type_code,
                ep.role_code, ep.asserting_claim_id, c.claim_key AS asserting_claim_key
         FROM event_participation ep
         JOIN event ev ON ev.event_id = ep.event_id
         JOIN entity en ON en.entity_id = ep.entity_id
         JOIN claim c ON c.claim_id = ep.asserting_claim_id
         WHERE ep.event_id = $1
         ORDER BY ep.entity_id, ep.role_code, ep.asserting_claim_id`,
        [event.event_id]
      );

      timeline.push({
        record_type: 'RELATED_EVENT',
        event: {
          event_id: event.event_id,
          event_key: event.event_key,
          event_type_code: event.event_type_code,
          description: event.description
        },
        temporal: await this.exploreEventTemporalMetadata(Number(event.event_id)),
        claims,
        projected_event_participation: participation.rows.map((row) => ({
          ...row,
          projection: 'PROJECTED_FROM_CLAIM_ASSERTED_PROPOSITION'
        }))
      });
    }

    const temporalRank = (entry: { temporal: Record<string, unknown> }): number =>
      entry.temporal.temporal_status === 'DATE_KNOWN' ? 0 : entry.temporal.temporal_status === 'CHRONOLOGICAL_METADATA_STORED' ? 1 : 2;
    const firstDate = (entry: { temporal: Record<string, unknown> }): string =>
      String(((entry.temporal.stored_dates as { date_value: unknown }[])[0]?.date_value) ?? '');
    const firstChronological = (entry: { temporal: Record<string, unknown> }): number =>
      Number(((entry.temporal.chronological_metadata as { numeric_value: unknown }[])[0]?.numeric_value) ?? 0);

    timeline.sort((left, right) => {
      const rankDelta = temporalRank(left) - temporalRank(right);
      if (rankDelta !== 0) return rankDelta;
      const dateDelta = firstDate(left).localeCompare(firstDate(right));
      if (dateDelta !== 0) return dateDelta;
      const chronologicalDelta = firstChronological(left) - firstChronological(right);
      if (chronologicalDelta !== 0) return chronologicalDelta;
      return Number(left.event.event_id) - Number(right.event.event_id);
    });

    const entityOnlyClaims = await this.pool.query(
      `SELECT DISTINCT c.claim_id
       FROM claim c
       JOIN proposition p ON p.proposition_id = c.proposition_id
       WHERE (p.subject_entity_id = $1 OR p.object_entity_id = $1)
         AND p.subject_event_id IS NULL
         AND p.object_event_id IS NULL
       ORDER BY c.claim_id`,
      [entityId]
    );

    const entityClaims = [];
    for (const row of entityOnlyClaims.rows) {
      claimIds.add(Number(row.claim_id));
      entityClaims.push(await this.exploreClaim(Number(row.claim_id)));
    }

    const sourceMappings = await this.pool.query(
      `SELECT esm.entity_source_mapping_id, esm.mapping_status_code, esm.confidence, esm.justification,
              esm.notes, esm.supporting_evidence_id,
              si.source_identity_id, si.source_identity_key, si.display_name,
              s.source_id, s.source_key, s.name AS source_name
       FROM entity_source_mapping esm
       JOIN source_identity si ON si.source_identity_id = esm.source_identity_id
       JOIN source s ON s.source_id = si.source_id
       WHERE esm.entity_id = $1
       ORDER BY esm.entity_source_mapping_id`,
      [entityId]
    );

    const orderedClaimIds = Array.from(claimIds).sort((left, right) => left - right);
    const storedClaimRelations = orderedClaimIds.length
      ? await this.pool.query(
          `SELECT cr.claim_relation_id, cr.relation_type_code, cr.notes,
                  cr.claim_id, c.claim_key,
                  cr.related_claim_id, rc.claim_key AS related_claim_key
           FROM claim_relation cr
           JOIN claim c ON c.claim_id = cr.claim_id
           JOIN claim rc ON rc.claim_id = cr.related_claim_id
           WHERE cr.claim_id = ANY($1::bigint[]) OR cr.related_claim_id = ANY($1::bigint[])
           ORDER BY cr.claim_relation_id`,
          [orderedClaimIds]
        )
      : { rows: [] };

    const allClaims = [...timeline.flatMap((entry) => entry.claims), ...entityClaims];
    const sourceGroups = new Map<string, Record<string, unknown>>();

    for (const claimEntry of allClaims) {
      const claim = claimEntry.claim as Record<string, unknown>;
      const provenance = claimEntry.provenance as Record<string, unknown>;
      const sources = (provenance.sources as Record<string, unknown>[]) ?? [];
      const citations = (provenance.citations as Record<string, unknown>[]) ?? [];
      for (const source of sources) {
        const key = String(source.source_key ?? '');
        if (!sourceGroups.has(key)) {
          sourceGroups.set(key, {
            source_id: source.source_id,
            source_key: source.source_key,
            source_name: source.source_name,
            source_type_code: source.source_type_code,
            descriptions: [] as Record<string, unknown>[]
          });
        }
        (sourceGroups.get(key)!.descriptions as Record<string, unknown>[]).push({
          record_type: 'SOURCE_DESCRIPTION',
          claim_id: claim.claim_id,
          claim_key: claim.claim_key,
          claim_type_code: claim.claim_type_code,
          statement: claim.statement,
          statement_role: 'DISPLAY_METADATA_ONLY',
          locators: citations.map((citation) => citation.locator)
        });
      }
    }

    const sourceComparison = Array.from(sourceGroups.values()).sort((left, right) =>
      String(left.source_key).localeCompare(String(right.source_key))
    );

    const coverage = await this.exploreEntityCoverage(
      entityId,
      String(entity.entity_type_code),
      String(entity.canonical_name)
    );

    return {
      operation: 'EXPLORE_TIMELINE',
      input: { entity_id: input.entityId ?? null, entity_key: input.entityKey ?? null },
      read_only: true,
      entity: {
        entity_id: entity.entity_id,
        entity_key: entity.entity_key,
        entity_type_code: entity.entity_type_code,
        canonical_name: entity.canonical_name,
        description: entity.description
      },
      coverage,
      entity_source_mappings: sourceMappings.rows,
      timeline,
      entity_claims_without_event: entityClaims,
      source_comparison: {
        distinct_source_count: sourceComparison.length,
        comparison_status: sourceComparison.length > 1 ? 'DIFFERING_SOURCE_DESCRIPTION' : 'SINGLE_SOURCE_DESCRIPTION',
        sources: sourceComparison,
        note: 'DIFFERENCE IS NOT CONTRADICTION. SOURCE-BACKED IS NOT TRUE. Differences between stored source descriptions are reported without classification.'
      },
      stored_claim_relations: storedClaimRelations.rows,
      ordering: [
        'stored event date/time typed values',
        'existing stored chronological metadata',
        'stable event_id'
      ],
      limitations: [
        'This operation assembles existing Berean knowledge. It does not create, evaluate, or promote knowledge.',
        'No truth, falsity, contradiction, compliance, violation, causation, entailment, or theological meaning is assigned.',
        'Event participation rows are projections of claim-asserted propositions, not independently authored authoritative facts.',
        'NULL raw_content and NULL quoted_text are reported as NOT_STORED_BY_POLICY, never as source silence.',
        'No date is invented; events without stored temporal values are reported as DATE_NOT_STORED.'
      ]
    };
  }

  async getGenesisCoverage(): Promise<Record<string, unknown>> {
    const byLocator = await this.pool.query(
      `WITH locators AS (
         SELECT sr.source_record_id, sr.source_location, sr.raw_content,
                COALESCE(ci.locator, sr.source_location) AS locator
         FROM source_record sr
         LEFT JOIN citation ci ON ci.source_record_id = sr.source_record_id
         WHERE sr.source_location ILIKE 'Genesis %' OR ci.locator ILIKE 'Genesis %' OR ci.locator ILIKE 'Gen.%'
       ),
       metrics AS (
         SELECT l.locator,
                bool_or(l.source_record_id IS NOT NULL) AS structurally_represented,
                bool_or(l.raw_content IS NOT NULL) AS populated,
                bool_or(l.raw_content IS NULL) AS source_unavailable,
                count(DISTINCT CASE WHEN c.claim_type_code <> 'DERIVED_CLAIM' THEN c.claim_id END)::int AS source_backed_claims,
                count(DISTINCT CASE WHEN c.claim_type_code = 'DERIVED_CLAIM' THEN c.claim_id END)::int AS derived_claims,
                count(DISTINCT CASE WHEN c.claim_status_code = 'UNDER_REVIEW' THEN c.claim_id END)::int AS unresolved_claims,
                count(DISTINCT CASE WHEN COALESCE(c.statement, '') ILIKE '%intentionally excluded%'
                                      OR COALESCE(c.statement, '') ILIKE '%intentionally unresolved%'
                                      OR COALESCE(c.notes, '') ILIKE '%deferred%'
                                    THEN c.claim_id END)::int AS deferred_or_under_modeled_claims
         FROM locators l
         LEFT JOIN evidence e ON e.source_record_id = l.source_record_id
         LEFT JOIN claim_evidence ce ON ce.evidence_id = e.evidence_id
         LEFT JOIN claim c ON c.claim_id = ce.claim_id
         GROUP BY l.locator
       )
       SELECT * FROM metrics ORDER BY locator LIMIT 300`
    );

    return {
      locators: byLocator.rows,
      summary: {
        locatorCount: byLocator.rowCount,
        structurallyRepresentedCount: byLocator.rows.filter((r: { structurally_represented: boolean }) => r.structurally_represented).length,
        populatedCount: byLocator.rows.filter((r: { populated: boolean }) => r.populated).length,
        sourceUnavailableCount: byLocator.rows.filter((r: { source_unavailable: boolean }) => r.source_unavailable).length
      }
    };
  }

  async getQualityDashboard(): Promise<Record<string, unknown>> {
    const [counts, claimTypes, contradictory, mappings] = await Promise.all([
      this.pool.query(
        `SELECT
           (SELECT count(*) FROM source) AS source_count,
           (SELECT count(*) FROM dataset) AS dataset_count,
           (SELECT count(*) FROM source_record) AS source_record_count,
           (SELECT count(*) FROM evidence) AS evidence_count,
           (SELECT count(*) FROM claim) AS claim_count,
           (SELECT count(*) FROM proposition) AS proposition_count,
           (SELECT count(*) FROM event) AS event_count,
           (SELECT count(*) FROM entity) AS entity_count`
      ),
      this.pool.query(
        `SELECT claim_type_code, count(*)::int AS count
         FROM claim GROUP BY claim_type_code ORDER BY claim_type_code`
      ),
      this.pool.query(
        `SELECT count(*)::int AS contradictory_claim_relations
         FROM claim_relation WHERE relation_type_code = 'CONTRADICTS'`
      ),
      this.pool.query(
        `SELECT mapping_status_code, count(*)::int AS count
         FROM entity_source_mapping GROUP BY mapping_status_code ORDER BY mapping_status_code`
      )
    ]);

    return {
      totals: counts.rows[0],
      claimTypeDistribution: claimTypes.rows,
      contradictoryRelations: contradictory.rows[0]?.contradictory_claim_relations ?? 0,
      sourceIdentityMappingStatus: mappings.rows
    };
  }

  async getGraphNeighborhood(nodeType: string, nodeId: number): Promise<{ nodes: GraphNode[]; edges: GraphEdge[] }> {
    const nodes = new Map<string, GraphNode>();
    const edges: GraphEdge[] = [];

    const addNode = (type: string, id: number, label: string): string => {
      const key = `${type}:${id}`;
      if (!nodes.has(key)) nodes.set(key, { id: key, type, label });
      return key;
    };

    if (nodeType === 'entity') {
      const entity = await this.pool.query(
        `SELECT entity_id, canonical_name FROM entity WHERE entity_id = $1`,
        [nodeId]
      );
      if (!entity.rowCount) return { nodes: [], edges: [] };

      const center = addNode('entity', nodeId, entity.rows[0].canonical_name as string);

      const related = await this.pool.query(
        `SELECT p.predicate, p.proposition_id,
                p.object_entity_id, oe.canonical_name AS object_entity_name,
                p.subject_entity_id, se.canonical_name AS subject_entity_name,
                c.claim_id
         FROM proposition p
         JOIN claim c ON c.proposition_id = p.proposition_id
         LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
         LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
         WHERE p.subject_entity_id = $1 OR p.object_entity_id = $1
         LIMIT 150`,
        [nodeId]
      );

      for (const row of related.rows) {
        if (row.subject_entity_id && row.subject_entity_id !== nodeId) {
          const from = addNode('entity', row.subject_entity_id as number, row.subject_entity_name as string);
          edges.push({ source: from, target: center, relation: row.predicate as string, claimId: row.claim_id as number });
        }
        if (row.object_entity_id && row.object_entity_id !== nodeId) {
          const to = addNode('entity', row.object_entity_id as number, row.object_entity_name as string);
          edges.push({ source: center, target: to, relation: row.predicate as string, claimId: row.claim_id as number });
        }
      }

      const eventLinks = await this.pool.query(
        `SELECT ep.event_id, ev.event_key, ep.role_code, ep.asserting_claim_id
         FROM event_participation ep
         JOIN event ev ON ev.event_id = ep.event_id
         WHERE ep.entity_id = $1
         LIMIT 150`,
        [nodeId]
      );

      for (const row of eventLinks.rows) {
        const eventNode = addNode('event', row.event_id as number, row.event_key as string);
        edges.push({ source: center, target: eventNode, relation: row.role_code as string, claimId: row.asserting_claim_id as number });
      }
    } else if (nodeType === 'claim') {
      const claim = await this.pool.query(`SELECT claim_id, claim_key FROM claim WHERE claim_id = $1`, [nodeId]);
      if (!claim.rowCount) return { nodes: [], edges: [] };
      const center = addNode('claim', nodeId, claim.rows[0].claim_key as string);

      const linked = await this.pool.query(
        `SELECT p.proposition_id, p.predicate,
                se.entity_id AS subject_entity_id, se.canonical_name AS subject_entity_name,
                oe.entity_id AS object_entity_id, oe.canonical_name AS object_entity_name,
                ev.event_id AS object_event_id, ev.event_key AS object_event_key
         FROM claim c
         JOIN proposition p ON p.proposition_id = c.proposition_id
         LEFT JOIN entity se ON se.entity_id = p.subject_entity_id
         LEFT JOIN entity oe ON oe.entity_id = p.object_entity_id
         LEFT JOIN event ev ON ev.event_id = p.object_event_id
         WHERE c.claim_id = $1`,
        [nodeId]
      );

      for (const row of linked.rows) {
        const propositionNode = addNode('proposition', row.proposition_id as number, row.predicate as string);
        edges.push({ source: center, target: propositionNode, relation: 'asserts' });

        if (row.subject_entity_id) {
          const subj = addNode('entity', row.subject_entity_id as number, row.subject_entity_name as string);
          edges.push({ source: propositionNode, target: subj, relation: 'subject' });
        }
        if (row.object_entity_id) {
          const obj = addNode('entity', row.object_entity_id as number, row.object_entity_name as string);
          edges.push({ source: propositionNode, target: obj, relation: 'object' });
        }
        if (row.object_event_id) {
          const objEvent = addNode('event', row.object_event_id as number, row.object_event_key as string);
          edges.push({ source: propositionNode, target: objEvent, relation: 'object' });
        }
      }

      const evidence = await this.pool.query(
        `SELECT e.evidence_id, e.evidence_key, ce.relation_type_code
         FROM claim_evidence ce
         JOIN evidence e ON e.evidence_id = ce.evidence_id
         WHERE ce.claim_id = $1`,
        [nodeId]
      );

      for (const row of evidence.rows) {
        const evidenceNode = addNode('evidence', row.evidence_id as number, row.evidence_key as string);
        edges.push({ source: center, target: evidenceNode, relation: row.relation_type_code as string });
      }
    }

    return { nodes: Array.from(nodes.values()), edges };
  }
}
