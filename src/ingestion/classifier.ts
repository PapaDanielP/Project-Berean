import {
  INFERENCE_FLAG_VALUES,
  OBJECT_KIND_VALUES,
  REVIEW_STATUS_VALUES,
  SOURCE_STATUS_VALUES,
  SUBJECT_KIND_VALUES,
  type CandidateClassification,
  type GraphSnapshot,
  type ManifestRow,
  type RegistrySnapshot
} from './types.js';

/**
 * Deterministic Phase 28 classifier.
 *
 * The classifier decides only whether a manifest row may be persisted automatically. It never
 * decides whether an assertion is true, whether a source is reliable, or whether two referents
 * are the same. A biblical reference alone never authorises acceptance: the proposed assertion
 * itself must be structurally valid, explicitly source-backed, free of prohibited inference, and
 * free of duplicate canonical terms.
 */

const NUMERIC_VALUE_TYPES = new Set(['INTEGER', 'DECIMAL', 'YEAR']);

const isBlank = (value: string): boolean => value.trim() === '';

const entityNameKey = (entityType: string, canonicalName: string): string =>
  `${entityType}|${canonicalName.trim().toLowerCase()}`;

export const classifyCandidate = (
  row: ManifestRow,
  registry: RegistrySnapshot,
  graph: GraphSnapshot,
  seenCandidateKeys: Set<string>
): CandidateClassification => {
  const reasons: string[] = [];
  const invalid = (): CandidateClassification => ({
    candidate_key: row.candidate_key,
    classification: 'INVALID',
    reasons
  });

  if (isBlank(row.candidate_key)) {
    reasons.push('MISSING_REQUIRED_FIELD:candidate_key');
    return invalid();
  }
  if (seenCandidateKeys.has(row.candidate_key)) reasons.push('DUPLICATE_CANDIDATE_KEY');
  if (isBlank(row.candidate_name)) reasons.push('MISSING_REQUIRED_FIELD:candidate_name');
  if (isBlank(row.explicit_textual_description)) {
    reasons.push('MISSING_REQUIRED_FIELD:explicit_textual_description');
  }
  if (!(SOURCE_STATUS_VALUES as readonly string[]).includes(row.source_status)) {
    reasons.push('UNKNOWN_ENUM_VALUE:source_status');
  }
  if (!(REVIEW_STATUS_VALUES as readonly string[]).includes(row.review_status)) {
    reasons.push('UNKNOWN_ENUM_VALUE:review_status');
  }
  if (!(INFERENCE_FLAG_VALUES as readonly string[]).includes(row.inference_flag)) {
    reasons.push('UNKNOWN_ENUM_VALUE:inference_flag');
  }
  if (reasons.length > 0) return invalid();

  if (row.review_status === 'EXCLUDED') {
    if (isBlank(row.exclusion_reason)) {
      reasons.push('MISSING_REQUIRED_FIELD:exclusion_reason');
      return invalid();
    }
    reasons.push('EXCLUDED_BY_MANIFEST');
    if (row.inference_flag !== 'NONE') reasons.push(`PROHIBITED_INFERENCE_FLAG:${row.inference_flag}`);
    reasons.push(`EXCLUSION_REASON:${row.exclusion_reason}`);
    return { candidate_key: row.candidate_key, classification: 'EXCLUDED', reasons };
  }

  if (row.review_status === 'REQUIRES_REVIEW') {
    if (isBlank(row.review_notes)) {
      reasons.push('MISSING_REQUIRED_FIELD:review_notes');
      return invalid();
    }
    reasons.push('REVIEW_REQUESTED_BY_MANIFEST');
    if (row.inference_flag !== 'NONE') reasons.push(`PROHIBITED_INFERENCE_FLAG:${row.inference_flag}`);
    reasons.push(`REVIEW_NOTE:${row.review_notes}`);
    return { candidate_key: row.candidate_key, classification: 'CANDIDATE_REQUIRES_REVIEW', reasons };
  }

  // review_status === 'PROPOSED_AUTO_ACCEPT': the proposed assertion must be fully constructible.
  if (isBlank(row.source_key)) reasons.push('MISSING_REQUIRED_FIELD:source_key');
  if (isBlank(row.dataset_key)) reasons.push('MISSING_REQUIRED_FIELD:dataset_key');
  if (isBlank(row.source_record_key)) reasons.push('MISSING_REQUIRED_FIELD:source_record_key');
  if (isBlank(row.source_location)) reasons.push('MISSING_REQUIRED_FIELD:source_location');
  if (!isBlank(row.source_key) && !registry.sourceKeys.has(row.source_key)) {
    reasons.push('UNKNOWN_SOURCE_REFERENCE');
  }
  if (!isBlank(row.dataset_key)) {
    const datasetSource = registry.datasetSourceKeys.get(row.dataset_key);
    if (datasetSource === undefined) reasons.push('UNKNOWN_DATASET_REFERENCE');
    else if (datasetSource !== row.source_key) reasons.push('DATASET_SOURCE_MISMATCH');
  }

  const predicate = registry.predicates.get(row.predicate);
  if (isBlank(row.predicate)) reasons.push('MISSING_REQUIRED_FIELD:predicate');
  else if (!predicate) reasons.push('UNREGISTERED_PREDICATE');

  if (!(SUBJECT_KIND_VALUES as readonly string[]).includes(row.subject_kind)) {
    reasons.push('UNKNOWN_ENUM_VALUE:subject_kind');
  }
  if (!(OBJECT_KIND_VALUES as readonly string[]).includes(row.object_kind)) {
    reasons.push('UNKNOWN_ENUM_VALUE:object_kind');
  }
  if (predicate) {
    if (predicate.subject_kind_code !== row.subject_kind || predicate.object_kind_code !== row.object_kind) {
      reasons.push('PREDICATE_TERM_KIND_MISMATCH');
    }
  }

  if (isBlank(row.subject_key)) reasons.push('MISSING_REQUIRED_FIELD:subject_key');
  if (row.subject_kind === 'ENTITY') {
    reasons.push(...validateEntityTerm(row.subject_key, row.subject_type, row.subject_name, 'subject', registry, graph));
  } else if (row.subject_kind === 'EVENT') {
    reasons.push(...validateEventTerm(row.subject_key, row.subject_type, 'subject', registry, graph));
  }

  if (row.object_kind === 'ENTITY') {
    if (isBlank(row.object_key)) reasons.push('MISSING_REQUIRED_FIELD:object_key');
    reasons.push(...validateEntityTerm(row.object_key, row.object_type, row.object_name, 'object', registry, graph));
  } else if (row.object_kind === 'EVENT') {
    if (isBlank(row.object_key)) reasons.push('MISSING_REQUIRED_FIELD:object_key');
    reasons.push(...validateEventTerm(row.object_key, row.object_type, 'object', registry, graph));
  } else if (row.object_kind === 'VALUE') {
    if (!registry.valueTypes.has(row.object_value_type)) reasons.push('UNKNOWN_VALUE_TYPE');
    if (isBlank(row.object_value)) reasons.push('MISSING_REQUIRED_FIELD:object_value');
    else if (NUMERIC_VALUE_TYPES.has(row.object_value_type) && !/^-?\d+(\.\d+)?$/.test(row.object_value)) {
      reasons.push('INVALID_TYPED_VALUE');
    }
  }

  if (!isBlank(row.mapping_source_identity_key) || !isBlank(row.mapping_justification)) {
    if (isBlank(row.mapping_source_identity_key)) reasons.push('MISSING_REQUIRED_FIELD:mapping_source_identity_key');
    if (isBlank(row.mapping_justification)) reasons.push('MISSING_MAPPING_JUSTIFICATION');
    if (isBlank(row.mapping_display_name)) reasons.push('MISSING_REQUIRED_FIELD:mapping_display_name');
    if (row.subject_kind !== 'ENTITY' && row.object_kind !== 'ENTITY') reasons.push('MAPPING_REQUIRES_ENTITY_TERM');
  }

  const claimKey = `CLAIM_${row.candidate_key}`;
  if (graph.claimKeys.has(claimKey)) {
    // A pre-existing claim key is idempotent reuse, not a conflict; the pipeline verifies that it
    // still asserts the same proposition before reporting ALREADY_PRESENT.
    reasons.push('EXISTING_CLAIM_KEY');
  }

  if (reasons.some((reason) => reason !== 'EXISTING_CLAIM_KEY')) return invalid();

  if (row.inference_flag !== 'NONE') {
    return {
      candidate_key: row.candidate_key,
      classification: 'CANDIDATE_REQUIRES_REVIEW',
      reasons: [`PROHIBITED_INFERENCE_FLAG:${row.inference_flag}`]
    };
  }
  if (row.source_status !== 'EXPLICIT_IN_SELECTED_CORPUS') {
    return {
      candidate_key: row.candidate_key,
      classification: 'CANDIDATE_REQUIRES_REVIEW',
      reasons: [`NOT_EXPLICIT_IN_SELECTED_CORPUS:${row.source_status}`]
    };
  }

  return { candidate_key: row.candidate_key, classification: 'AUTO_ACCEPT', reasons };
};

const validateEntityTerm = (
  entityKey: string,
  entityType: string,
  canonicalName: string,
  position: 'subject' | 'object',
  registry: RegistrySnapshot,
  graph: GraphSnapshot
): string[] => {
  const reasons: string[] = [];
  if (isBlank(entityKey)) return reasons;
  const existing = graph.entityByKey.get(entityKey);
  if (existing) {
    if (!isBlank(entityType) && entityType !== existing.entity_type_code) {
      reasons.push(`ENTITY_TYPE_CONFLICT:${position}`);
    }
    if (!isBlank(canonicalName) && canonicalName !== existing.canonical_name) {
      reasons.push(`ENTITY_NAME_CONFLICT:${position}`);
    }
    return reasons;
  }
  if (isBlank(entityType)) reasons.push(`MISSING_REQUIRED_FIELD:${position}_type`);
  else if (!registry.entityTypes.has(entityType)) reasons.push(`UNKNOWN_ENTITY_TYPE:${position}`);
  if (isBlank(canonicalName)) reasons.push(`MISSING_REQUIRED_FIELD:${position}_name`);
  if (!isBlank(entityType) && !isBlank(canonicalName)) {
    const duplicateKey = graph.entityKeyByTypeAndName.get(entityNameKey(entityType, canonicalName));
    if (duplicateKey !== undefined && duplicateKey !== entityKey) {
      reasons.push(`DUPLICATE_CANONICAL_ENTITY:${position}`);
    }
  }
  return reasons;
};

const validateEventTerm = (
  eventKey: string,
  eventType: string,
  position: 'subject' | 'object',
  registry: RegistrySnapshot,
  graph: GraphSnapshot
): string[] => {
  const reasons: string[] = [];
  if (isBlank(eventKey)) return reasons;
  const existing = graph.eventByKey.get(eventKey);
  if (existing) {
    if (!isBlank(eventType) && eventType !== existing.event_type_code) {
      reasons.push(`EVENT_TYPE_CONFLICT:${position}`);
    }
    return reasons;
  }
  if (isBlank(eventType)) reasons.push(`MISSING_REQUIRED_FIELD:${position}_type`);
  else if (!registry.eventTypes.has(eventType)) reasons.push(`UNKNOWN_EVENT_TYPE:${position}`);
  return reasons;
};

export const registerCandidateTerms = (row: ManifestRow, graph: GraphSnapshot): void => {
  if (row.subject_kind === 'ENTITY' && row.subject_key && !graph.entityByKey.has(row.subject_key)) {
    graph.entityByKey.set(row.subject_key, {
      entity_type_code: row.subject_type,
      canonical_name: row.subject_name
    });
    graph.entityKeyByTypeAndName.set(entityNameKey(row.subject_type, row.subject_name), row.subject_key);
  }
  if (row.subject_kind === 'EVENT' && row.subject_key && !graph.eventByKey.has(row.subject_key)) {
    graph.eventByKey.set(row.subject_key, { event_type_code: row.subject_type });
  }
  if (row.object_kind === 'ENTITY' && row.object_key && !graph.entityByKey.has(row.object_key)) {
    graph.entityByKey.set(row.object_key, {
      entity_type_code: row.object_type,
      canonical_name: row.object_name
    });
    graph.entityKeyByTypeAndName.set(entityNameKey(row.object_type, row.object_name), row.object_key);
  }
  if (row.object_kind === 'EVENT' && row.object_key && !graph.eventByKey.has(row.object_key)) {
    graph.eventByKey.set(row.object_key, { event_type_code: row.object_type });
  }
};
