export type SearchType =
  | 'entity'
  | 'event'
  | 'claim'
  | 'proposition'
  | 'evidence'
  | 'source'
  | 'dataset'
  | 'source_record'
  | 'citation'
  | 'source_identity';

export interface SearchResult {
  type: SearchType;
  id: number;
  key: string;
  label: string;
  detail?: string | null;
}

export interface GraphNode {
  id: string;
  type: string;
  label: string;
}

export interface GraphEdge {
  source: string;
  target: string;
  relation: string;
  claimId?: number;
}
