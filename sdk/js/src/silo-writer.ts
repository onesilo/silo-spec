import type {
  SiloMode,
  SiloManifest,
  SiloContent,
  SiloConfig,
  SiloMemory,
  SiloEntity,
  SiloRelationship,
  MemoryEntityLink,
  FactMetadata,
  DecisionMetadata,
  NarrativeMetadata,
  InsightMetadata,
  OpenItemMetadata,
} from "./types.js";
import { createSiloPackage } from "./silo-package.js";

const SPEC_VERSION = "0.1.0";

export interface SiloPackageData {
  manifest: SiloManifest;
  content: SiloContent;
  toBlob(): Promise<Blob>;
  toJSON(): { manifest: string; content: string };
}

export class SiloWriter {
  private id: string;
  private title: string;
  private mode: SiloMode;
  private description?: string;
  private creatorName?: string;
  private creatorUri?: string;
  private tags?: string[];
  private subjectEntityId?: string;
  private config: Partial<SiloConfig> = {};

  private memories: SiloMemory[] = [];
  private entities: SiloEntity[] = [];
  private relationships: SiloRelationship[] = [];
  private memoryEntityLinks: MemoryEntityLink[] = [];

  private memoryCounter = 0;
  private entityCounter = 0;
  private relationshipCounter = 0;

  constructor(title: string, mode: SiloMode) {
    this.id = generateId();
    this.title = title;
    this.mode = mode;
  }

  // ---------------------------------------------------------------------------
  // Memories
  // ---------------------------------------------------------------------------

  addFact(content: string, metadata?: Partial<FactMetadata>): this {
    this.pushMemory("fact", content, metadata);
    return this;
  }

  addDecision(content: string, metadata?: Partial<DecisionMetadata>): this {
    this.pushMemory("decision", content, metadata);
    return this;
  }

  addNarrative(content: string, metadata?: Partial<NarrativeMetadata>): this {
    this.pushMemory("narrative", content, metadata);
    return this;
  }

  addInsight(content: string, metadata?: Partial<InsightMetadata>): this {
    this.pushMemory("insight", content, metadata);
    return this;
  }

  addOpenItem(content: string, metadata?: Partial<OpenItemMetadata>): this {
    this.pushMemory("open_item", content, metadata);
    return this;
  }

  addCustom(content: string, customType: string, data?: unknown): this {
    this.pushMemory("custom", content, {
      custom_type: customType,
      ...(data !== undefined ? { data } : {}),
    });
    return this;
  }

  // ---------------------------------------------------------------------------
  // Entities & relationships
  // ---------------------------------------------------------------------------

  addEntity(
    name: string,
    type: string,
    properties?: Record<string, unknown>
  ): this {
    const now = iso();
    this.entityCounter++;
    const id = `e_${String(this.entityCounter).padStart(3, "0")}`;
    const entity: SiloEntity = {
      id,
      name,
      type,
      created_at: now,
      updated_at: now,
      ...(properties ? { properties } : {}),
    };
    this.entities.push(entity);
    return this;
  }

  addRelationship(
    sourceEntityId: string,
    targetEntityId: string,
    type: string
  ): this {
    this.relationshipCounter++;
    const id = `r_${String(this.relationshipCounter).padStart(3, "0")}`;
    this.relationships.push({
      id,
      source_entity_id: sourceEntityId,
      target_entity_id: targetEntityId,
      type,
      created_at: iso(),
    });
    return this;
  }

  linkMemoryToEntity(
    memoryId: string,
    entityId: string,
    role?: string
  ): this {
    this.memoryEntityLinks.push({
      memory_id: memoryId,
      entity_id: entityId,
      ...(role ? { role } : {}),
    });
    return this;
  }

  // ---------------------------------------------------------------------------
  // Manifest metadata
  // ---------------------------------------------------------------------------

  setConfig(config: Partial<SiloConfig>): this {
    this.config = { ...this.config, ...config };
    return this;
  }

  setSubjectEntity(entityId: string): this {
    this.subjectEntityId = entityId;
    return this;
  }

  setCreator(name: string, uri?: string): this {
    this.creatorName = name;
    this.creatorUri = uri;
    return this;
  }

  setDescription(description: string): this {
    this.description = description;
    return this;
  }

  setTags(tags: string[]): this {
    this.tags = tags;
    return this;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  build(): SiloPackageData {
    const now = iso();

    const manifest: SiloManifest = {
      spec: SPEC_VERSION,
      min_reader: SPEC_VERSION,
      id: this.id,
      title: this.title,
      created_at: now,
      updated_at: now,
      mode: this.mode,
      ...(this.description ? { description: this.description } : {}),
      ...(this.creatorName
        ? {
            creator: {
              name: this.creatorName,
              ...(this.creatorUri ? { uri: this.creatorUri } : {}),
            },
          }
        : {}),
      ...(this.subjectEntityId
        ? { subject_entity_id: this.subjectEntityId }
        : {}),
      ...(this.tags && this.tags.length > 0 ? { tags: this.tags } : {}),
      stats: {
        memory_count: this.memories.length,
        entity_count: this.entities.length,
        ref_count: 0,
        ref_size_bytes: 0,
      },
    };

    const content: SiloContent = {
      memories: [...this.memories],
      entities: [...this.entities],
      relationships: [...this.relationships],
      topics: [],
      memory_entity_links: [...this.memoryEntityLinks],
      memory_ref_links: [],
      refs: [],
      config: { ...this.config } as SiloConfig,
    };

    return {
      manifest,
      content,
      toBlob: () => createSiloPackage(manifest, content),
      toJSON: () => ({
        manifest: JSON.stringify(manifest, null, 2),
        content: JSON.stringify(content, null, 2),
      }),
    };
  }

  /** Returns the last memory ID that was added (useful for linkMemoryToEntity). */
  get lastMemoryId(): string {
    if (this.memories.length === 0)
      throw new Error("No memories have been added");
    return this.memories[this.memories.length - 1].id;
  }

  /** Returns the last entity ID that was added (useful for addRelationship). */
  get lastEntityId(): string {
    if (this.entities.length === 0)
      throw new Error("No entities have been added");
    return this.entities[this.entities.length - 1].id;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  private pushMemory(
    type: SiloMemory["type"],
    content: string,
    metadata?: Record<string, unknown>
  ): void {
    const now = iso();
    this.memoryCounter++;
    const id = `m_${String(this.memoryCounter).padStart(3, "0")}`;
    this.memories.push({
      id,
      type,
      content,
      created_at: now,
      updated_at: now,
      ...(metadata && Object.keys(metadata).length > 0
        ? { metadata }
        : {}),
    });
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function iso(): string {
  return new Date().toISOString();
}

function generateId(): string {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
  });
}
