import { openDB, type IDBPDatabase } from "idb";
import type { SiloContent, SiloMemory, SiloEntity, MemoryType } from "./types.js";

const DB_VERSION = 1;

interface SiloDB {
  memories: { key: string; value: SiloMemory; indexes: { "by-type": string } };
  entities: { key: string; value: SiloEntity; indexes: { "by-type": string } };
  memory_entity_links: {
    key: string;
    value: { memory_id: string; entity_id: string; role?: string };
    indexes: { "by-memory": string; "by-entity": string };
  };
}

export class SiloStore {
  private db: IDBPDatabase<SiloDB> | null = null;
  private dbName: string;

  constructor(siloId: string) {
    this.dbName = `silo-${siloId}`;
  }

  async open(): Promise<void> {
    this.db = await openDB<SiloDB>(this.dbName, DB_VERSION, {
      upgrade(db) {
        const memoryStore = db.createObjectStore("memories", { keyPath: "id" });
        memoryStore.createIndex("by-type", "type");

        const entityStore = db.createObjectStore("entities", { keyPath: "id" });
        entityStore.createIndex("by-type", "type");

        const linkStore = db.createObjectStore("memory_entity_links", {
          keyPath: ["memory_id", "entity_id"],
        });
        linkStore.createIndex("by-memory", "memory_id");
        linkStore.createIndex("by-entity", "entity_id");
      },
    });
  }

  async importContent(content: SiloContent): Promise<void> {
    if (!this.db) throw new Error("Database not open");

    const tx = this.db.transaction(
      ["memories", "entities", "memory_entity_links"],
      "readwrite"
    );

    for (const memory of content.memories) {
      await tx.objectStore("memories").put(memory);
    }
    for (const entity of content.entities) {
      await tx.objectStore("entities").put(entity);
    }
    for (const link of content.memory_entity_links) {
      await tx.objectStore("memory_entity_links").put(link);
    }

    await tx.done;
  }

  async searchMemories(query: string, limit = 10): Promise<SiloMemory[]> {
    if (!this.db) throw new Error("Database not open");

    const all = await this.db.getAll("memories");
    const q = query.toLowerCase();

    return all
      .map((m) => ({ memory: m, score: scoreMatch(m.content, q) }))
      .filter((r) => r.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map((r) => r.memory);
  }

  async getMemoriesByType(type: MemoryType): Promise<SiloMemory[]> {
    if (!this.db) throw new Error("Database not open");
    return this.db.getAllFromIndex("memories", "by-type", type);
  }

  async getEntity(id: string): Promise<SiloEntity | undefined> {
    if (!this.db) throw new Error("Database not open");
    return this.db.get("entities", id);
  }

  async getLinkedEntities(
    memoryId: string
  ): Promise<{ entity: SiloEntity; role?: string }[]> {
    if (!this.db) throw new Error("Database not open");

    const links = await this.db.getAllFromIndex(
      "memory_entity_links",
      "by-memory",
      memoryId
    );
    const results: { entity: SiloEntity; role?: string }[] = [];

    for (const link of links) {
      const entity = await this.db.get("entities", link.entity_id);
      if (entity) results.push({ entity, role: link.role });
    }

    return results;
  }

  async close(): Promise<void> {
    this.db?.close();
    this.db = null;
  }
}

function scoreMatch(content: string, query: string): number {
  const lower = content.toLowerCase();
  const terms = query.split(/\s+/).filter(Boolean);
  let score = 0;

  for (const term of terms) {
    const idx = lower.indexOf(term);
    if (idx !== -1) {
      score += 1;
      if (idx === 0 || lower[idx - 1] === " ") score += 0.5;
    }
  }

  return score;
}
