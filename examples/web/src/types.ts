// .silo format types — matches spec v0.1.0

export interface SiloManifest {
  spec: string;
  min_reader: string;
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
  mode: "container" | "augmented" | "open";
  description?: string;
  icon?: string;
  creator?: { name: string; uri?: string };
  subject_entity_id?: string | null;
  sharing?: { access_mode?: string; allow_reshare?: boolean };
  tags?: string[];
  stats?: {
    memory_count?: number;
    entity_count?: number;
    ref_count?: number;
    ref_size_bytes?: number;
  };
  extensions?: Record<string, unknown>;
}

export type MemoryType =
  | "fact"
  | "decision"
  | "narrative"
  | "insight"
  | "open_item"
  | "custom";

export interface SiloMemory {
  id: string;
  type: MemoryType;
  content: string;
  created_at: string;
  updated_at: string;
  metadata?: Record<string, unknown>;
  updated_by?: string;
}

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

export interface SiloTopic {
  id: string;
  name: string;
  parent_id?: string;
  sort_order?: number;
}

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

export interface SiloRef {
  id: string;
  filename: string;
  path: string;
  mime_type: string;
  created_at: string;
  description?: string;
  size_bytes?: number;
  data_summary?: {
    row_count?: number;
    date_range?: { start: string; end: string };
    columns?: string[];
    source?: string;
  };
}

export interface SiloConfig {
  system_instructions?: string;
  mode_instructions?: string;
  welcome_summary?: string;
  welcome_message?: string;
  suggested_prompts?: string[];
  citation_required?: boolean;
}

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
