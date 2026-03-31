// .silo format types — matches spec v0.1.0

// ---------------------------------------------------------------------------
// Manifest
// ---------------------------------------------------------------------------

export type SiloMode = "container" | "augmented" | "open";

export interface SiloManifest {
  spec: string;
  min_reader: string;
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
  mode: SiloMode;
  description?: string;
  icon?: string;
  creator?: SiloCreator;
  subject_entity_id?: string | null;
  sharing?: SiloSharing;
  tags?: string[];
  stats?: SiloStats;
  extensions?: Record<string, unknown>;
}

export interface SiloCreator {
  name: string;
  uri?: string;
}

export interface SiloSharing {
  access_mode?: "read" | "read_write";
  allow_reshare?: boolean;
}

export interface SiloStats {
  memory_count?: number;
  entity_count?: number;
  ref_count?: number;
  ref_size_bytes?: number;
}

// ---------------------------------------------------------------------------
// Memory types & metadata
// ---------------------------------------------------------------------------

export type MemoryType =
  | "fact"
  | "decision"
  | "narrative"
  | "insight"
  | "open_item"
  | "custom";

export interface FactMetadata {
  key?: string;
  confidence?: number;
  category?: string;
}

export interface DecisionMetadata {
  title?: string;
  alternatives_considered?: string[];
  decided_by?: string[];
  decided_at?: string;
  confidence?: number;
  status?: "final" | "tentative" | "revisited";
}

export interface NarrativeMetadata {
  title?: string;
  topic?: string;
  section_order?: number;
}

export interface InsightMetadata {
  title?: string;
  confidence?: number;
  supporting_memory_ids?: string[];
  category?: string;
}

export interface OpenItemMetadata {
  priority?: "high" | "medium" | "low";
  status?: "open" | "resolved" | "cancelled";
  due_date?: string;
  assigned_to?: string;
}

export interface CustomMetadata {
  custom_type?: string;
  schema?: string;
  data?: unknown;
}

export interface SiloMemory {
  id: string;
  type: MemoryType;
  content: string;
  created_at: string;
  updated_at: string;
  metadata?: Record<string, unknown>;
  updated_by?: string;
}

// ---------------------------------------------------------------------------
// Entities & relationships
// ---------------------------------------------------------------------------

export interface SiloEntity {
  id: string;
  name: string;
  type: string;
  created_at: string;
  updated_at: string;
  properties?: Record<string, unknown>;
  alternate_names?: string[];
}

export interface SiloRelationship {
  id: string;
  source_entity_id: string;
  target_entity_id: string;
  type: string;
  created_at: string;
  weight?: number;
  metadata?: Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Topics
// ---------------------------------------------------------------------------

export interface SiloTopic {
  id: string;
  name: string;
  parent_id?: string;
  sort_order?: number;
}

// ---------------------------------------------------------------------------
// Links
// ---------------------------------------------------------------------------

export interface MemoryEntityLink {
  memory_id: string;
  entity_id: string;
  role?: string;
}

export interface MemoryRefLink {
  memory_id: string;
  ref_id: string;
  relationship?: string;
}

// ---------------------------------------------------------------------------
// Refs
// ---------------------------------------------------------------------------

export interface SiloRef {
  id: string;
  filename: string;
  path: string;
  mime_type: string;
  created_at: string;
  description?: string;
  size_bytes?: number;
  data_summary?: RefDataSummary;
}

export interface RefDataSummary {
  row_count?: number;
  date_range?: { start: string; end: string };
  columns?: string[];
  source?: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

export interface SiloConfig {
  system_instructions?: string;
  mode_instructions?: string;
  welcome_summary?: string;
  welcome_message?: string;
  suggested_prompts?: string[];
  citation_required?: boolean;
}

// ---------------------------------------------------------------------------
// Content & Package
// ---------------------------------------------------------------------------

export interface SiloContent {
  memories: SiloMemory[];
  entities: SiloEntity[];
  relationships: SiloRelationship[];
  topics: SiloTopic[];
  memory_entity_links: MemoryEntityLink[];
  memory_ref_links: MemoryRefLink[];
  refs: SiloRef[];
  config: SiloConfig;
}

export interface SiloPackage {
  manifest: SiloManifest;
  content: SiloContent;
  refFiles: Map<string, Uint8Array>;
}
