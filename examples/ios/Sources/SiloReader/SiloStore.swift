import Foundation
import GRDB

/// Imports silo.json content into a local SQLite database for querying.
public final class SiloStore {
    private let dbQueue: DatabaseQueue

    public init(databasePath: String) throws {
        dbQueue = try DatabaseQueue(path: databasePath)
        try createTables()
    }

    private func createTables() throws {
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS memories (
                    id TEXT PRIMARY KEY,
                    type TEXT NOT NULL,
                    content TEXT NOT NULL,
                    metadata TEXT,
                    updated_by TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS entities (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    properties TEXT,
                    alternate_names TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS relationships (
                    id TEXT PRIMARY KEY,
                    source_entity_id TEXT NOT NULL,
                    target_entity_id TEXT NOT NULL,
                    type TEXT NOT NULL,
                    weight REAL DEFAULT 1.0,
                    metadata TEXT,
                    created_at TEXT NOT NULL
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS memory_entity_links (
                    memory_id TEXT NOT NULL,
                    entity_id TEXT NOT NULL,
                    role TEXT,
                    PRIMARY KEY (memory_id, entity_id)
                )
            """)

            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts
                USING fts5(content, content='memories', content_rowid='rowid')
            """)

            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(type)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(type)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_mel_memory ON memory_entity_links(memory_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_mel_entity ON memory_entity_links(entity_id)")
        }
    }

    // MARK: - Import

    public func importContent(_ content: SiloContent) throws {
        try dbQueue.write { db in
            let encoder = JSONEncoder()

            for memory in content.memories {
                let metadataJSON = memory.metadata.map { try? encoder.encode($0) }.flatMap { $0 }
                try db.execute(
                    sql: "INSERT OR REPLACE INTO memories (id, type, content, metadata, updated_by, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    arguments: [memory.id, memory.type.rawValue, memory.content,
                                metadataJSON.map { String(data: $0, encoding: .utf8) },
                                memory.updatedBy, memory.createdAt, memory.updatedAt]
                )

                try db.execute(
                    sql: "INSERT INTO memories_fts (rowid, content) SELECT rowid, content FROM memories WHERE id = ?",
                    arguments: [memory.id]
                )
            }

            for entity in content.entities {
                let propsJSON = entity.properties.map { try? encoder.encode($0) }.flatMap { $0 }
                let altJSON = entity.alternateNames.map { try? encoder.encode($0) }.flatMap { $0 }
                try db.execute(
                    sql: "INSERT OR REPLACE INTO entities (id, name, type, properties, alternate_names, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    arguments: [entity.id, entity.name, entity.type,
                                propsJSON.map { String(data: $0, encoding: .utf8) },
                                altJSON.map { String(data: $0, encoding: .utf8) },
                                entity.createdAt, entity.updatedAt]
                )
            }

            for rel in content.relationships {
                let metaJSON = rel.metadata.map { try? encoder.encode($0) }.flatMap { $0 }
                try db.execute(
                    sql: "INSERT OR REPLACE INTO relationships (id, source_entity_id, target_entity_id, type, weight, metadata, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    arguments: [rel.id, rel.sourceEntityId, rel.targetEntityId, rel.type,
                                rel.weight ?? 1.0,
                                metaJSON.map { String(data: $0, encoding: .utf8) },
                                rel.createdAt]
                )
            }

            for link in content.memoryEntityLinks {
                try db.execute(
                    sql: "INSERT OR REPLACE INTO memory_entity_links (memory_id, entity_id, role) VALUES (?, ?, ?)",
                    arguments: [link.memoryId, link.entityId, link.role]
                )
            }
        }
    }

    // MARK: - Query

    public func searchMemories(query: String, limit: Int = 10) throws -> [(id: String, type: String, content: String, rank: Double)] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT m.id, m.type, m.content, fts.rank
                FROM memories_fts fts
                JOIN memories m ON m.rowid = fts.rowid
                WHERE memories_fts MATCH ?
                ORDER BY fts.rank
                LIMIT ?
            """, arguments: [query, limit])

            return rows.map { row in
                (id: row["id"] as String,
                 type: row["type"] as String,
                 content: row["content"] as String,
                 rank: row["rank"] as Double)
            }
        }
    }

    public func getMemoriesByType(_ type: MemoryType) throws -> [SiloMemory] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, type, content, metadata, updated_by, created_at, updated_at
                FROM memories WHERE type = ? ORDER BY created_at
            """, arguments: [type.rawValue])

            return rows.map { row in
                let metadataDict: [String: AnyCodable]? = nil
                return SiloMemory(
                    id: row["id"],
                    type: type,
                    content: row["content"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    metadata: metadataDict,
                    updatedBy: row["updated_by"]
                )
            }
        }
    }

    public func getEntity(id: String) throws -> SiloEntity? {
        try dbQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: "SELECT * FROM entities WHERE id = ?", arguments: [id]) else {
                return nil
            }
            return SiloEntity(
                id: row["id"], name: row["name"], type: row["type"],
                createdAt: row["created_at"], updatedAt: row["updated_at"],
                properties: nil, alternateNames: nil
            )
        }
    }

    public func getLinkedEntities(memoryId: String) throws -> [(entityId: String, name: String, role: String?)] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT mel.entity_id, e.name, mel.role
                FROM memory_entity_links mel
                JOIN entities e ON e.id = mel.entity_id
                WHERE mel.memory_id = ?
            """, arguments: [memoryId])

            return rows.map { (entityId: $0["entity_id"], name: $0["name"], role: $0["role"]) }
        }
    }
}
