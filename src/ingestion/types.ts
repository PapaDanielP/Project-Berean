/**
 * Phase 28 Tier-1 ingestion types.
 *
 * The manifest is the only ingestion input. It carries the Phase 27 candidate worksheet columns
 * plus the machine-readable term/predicate/source columns needed to construct a claim graph with
 * complete provenance. Nothing in this module evaluates truth, reliability, entailment, or
 * identity beyond what a manifest row explicitly declares.
 */

export const MANIFEST_COLUMNS = [
  'candidate_key',
  'entity_type',
  'candidate_name',
  'biblical_references',
  'explicit_textual_description',
  'proposed_proposition',
  'source_status',
  'external_source',
  'external_identifier',
  'review_status',
  'exclusion_reason',
  'review_notes',
  'proposed_mapping_decision',
  'inference_flag',
  'source_key',
  'dataset_key',
  'source_record_key',
  'citation_key',
  'entity_key',
  'entity_type_code',
  'entity_name',
  'proposition_definition',
  'predicate_code',
  'subject_entity',
  'object_entity',
  'event_key',
  'event_type_code',
  'event_participation_role',
  'typed_value',
  'claim_key',
  'claim_type_code',
  'acceptance_tier',
  'acceptance_basis',
  'source_location',
  'subject_kind',
  'subject_key',
  'subject_type',
  'subject_name',
  'subject_description',
  'predicate',
  'object_kind',
  'object_key',
  'object_type',
  'object_name',
  'object_description',
  'object_value_type',
  'object_value',
  'mapping_source_identity_key',
  'mapping_display_name',
  'mapping_justification'
] as const;

export type ManifestColumn = (typeof MANIFEST_COLUMNS)[number];

export type ManifestRow = Record<ManifestColumn, string>;

export const SOURCE_STATUS_VALUES = [
  'EXPLICIT_IN_SELECTED_CORPUS',
  'OUTSIDE_SELECTED_CORPUS',
  'EXTERNAL_ONLY'
] as const;

export const REVIEW_STATUS_VALUES = [
  'PROPOSED_AUTO_ACCEPT',
  'REQUIRES_REVIEW',
  'EXCLUDED'
] as const;

export const ACCEPTANCE_TIER_VALUES = [
  'AUTO_ADMISSIBLE',
  'REQUIRES_HUMAN_REVIEW',
  'EXCLUDED',
  'NOT_YET_MODELED'
] as const;

/**
 * Prohibited-inference markers. Any value other than NONE keeps a candidate out of the
 * authoritative graph; the pipeline never decides for itself that an inference is safe.
 */
export const INFERENCE_FLAG_VALUES = [
  'NONE',
  'IDENTITY_INFERENCE',
  'DEATH_INFERENCE',
  'GEOGRAPHY_INFERENCE',
  'CHRONOLOGY_INFERENCE',
  'THEOLOGICAL_INFERENCE',
  'CAUSATION_INFERENCE',
  'HARMONIZATION_INFERENCE',
  'EXTERNAL_ATTRIBUTION'
] as const;

export const SUBJECT_KIND_VALUES = ['ENTITY', 'EVENT'] as const;
export const OBJECT_KIND_VALUES = ['ENTITY', 'EVENT', 'VALUE'] as const;

export type Classification =
  | 'AUTO_ACCEPT'
  | 'CANDIDATE_REQUIRES_REVIEW'
  | 'EXCLUDED'
  | 'INVALID';

export interface PredicateDefinition {
  predicate_code: string;
  subject_kind_code: string;
  object_kind_code: string;
  event_participation_role_code: string | null;
}

/** Controlled vocabulary and registry rows read from the database; never written by ingestion. */
export interface RegistrySnapshot {
  predicates: Map<string, PredicateDefinition>;
  entityTypes: Set<string>;
  eventTypes: Set<string>;
  valueTypes: Set<string>;
  claimTypes: Set<string>;
  sourceKeys: Set<string>;
  datasetSourceKeys: Map<string, string>;
}

/** Existing graph state used for duplicate detection and conflict detection. */
export interface GraphSnapshot {
  entityByKey: Map<string, { entity_type_code: string; canonical_name: string }>;
  entityKeyByTypeAndName: Map<string, string>;
  eventByKey: Map<string, { event_type_code: string }>;
  claimKeys: Set<string>;
}

export interface CandidateClassification {
  candidate_key: string;
  classification: Classification;
  reasons: string[];
}

export interface CandidateOutcome extends CandidateClassification {
  claim_key: string | null;
  persisted: boolean;
  already_present: boolean;
  duplicate_prevented: boolean;
  provenance_status: 'COMPLETE_PROVENANCE' | 'INCOMPLETE_PROVENANCE' | 'NOT_PERSISTED';
  source_backed_status: 'SOURCE_BACKED' | 'NOT_AUTOMATICALLY_IMPORTED';
  external_metadata_status: 'NONE' | 'DISCOVERY_METADATA_ONLY';
  acceptance_tier: string;
  acceptance_basis: string;
}

export const COUNTED_TABLES = [
  'entity',
  'event',
  'typed_value',
  'proposition',
  'claim',
  'claim_evidence',
  'evidence',
  'evidence_citation',
  'citation',
  'source_record',
  'source_identity',
  'entity_source_mapping',
  'source',
  'dataset',
  'source_type',
  'entity_type',
  'claim_type',
  'claim_status',
  'evidence_type',
  'claim_evidence_relation_type',
  'mapping_status',
  'event_type',
  'event_participation_role',
  'claim_relation_type',
  'value_type',
  'term_kind',
  'predicate',
  'derivation',
  'derivation_input'
] as const;

export type CountedTable = (typeof COUNTED_TABLES)[number];

export interface IngestionTotals {
  TOTAL_CANDIDATES: number;
  ASSERTIONS_CONSIDERED: number;
  SOURCE_RECORDS_CONSIDERED: number;
  AUTO_ACCEPTED: number;
  SOURCE_BACKED_AUTO_ACCEPTED: number;
  SOURCE_BACKED_MANUAL: number;
  DERIVED_STRUCTURALLY: number;
  CANDIDATE_REQUIRES_REVIEW: number;
  REQUIRES_HUMAN_REVIEW: number;
  EXCLUDED: number;
  NOT_YET_MODELED: number;
  INVALID: number;
  ALREADY_PRESENT: number;
  NEW_ENTITIES: number;
  NEW_PROPOSITIONS: number;
  NEW_CLAIMS: number;
  NEW_EVENTS: number;
  NEW_EVIDENCE: number;
  NEW_CITATIONS: number;
  NEW_SOURCE_RECORDS: number;
  NEW_TYPED_VALUES: number;
  NEW_MAPPINGS: number;
  COMPLETE_PROVENANCE: number;
  INCOMPLETE_PROVENANCE: number;
  DUPLICATES_PREVENTED: number;
  DUPLICATES_CREATED: number;
  NEW_RECORDS: number;
  PROJECTED_EVENT_PARTICIPATION: number;
}

export interface IngestionReport {
  manifest_source: string;
  committed: boolean;
  totals: IngestionTotals;
  candidates: CandidateOutcome[];
  not_accepted_reasons: { candidate_key: string; classification: Classification; reasons: string[] }[];
  before_counts: Record<CountedTable, number>;
  after_counts: Record<CountedTable, number>;
  delta_counts: Record<CountedTable, number>;
  boundary_notes: string[];
}
