import Foundation
import GRDB

/// Imports silo content into a local SQLite database for querying and mutation.
public final class SiloStore {
    private let dbQueue: DatabaseQueue

    public init(databasePath: String) throws {
        dbQueue = try DatabaseQueue(path: databasePath)
        try createTables()
    }

    /// In-memory store for testing or ephemeral use.
    public init() throws {
        dbQueue = try DatabaseQueue()
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
                CREATE TABLE IF NOT EXISTS topics (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    parent_id TEXT,
                    sort_order INTEGER
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
                CREATE TABLE IF NOT EXISTS memory_ref_links (
                    memory_id TEXT NOT NULL,
                    ref_id TEXT NOT NULL,
                    relationship TEXT,
                    PRIMARY KEY (memory_id, ref_id)
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS refs (
                    id TEXT PRIMARY KEY,
                    filename TEXT NOT NULL,
                    path TEXT NOT NULL,
                    mime_type TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    description TEXT,
                    size_bytes INTEGER
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
                let metadataJSON = memory.metadata.flatMap { try? encoder.encode($0) }
                try db.execute(
                    sql: """
                        INSERT OR REPLACE INTO memories (id, type, content, metadata, updated_by, created_at, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        memory.id, memory.type.rawValue, memory.content,
                        metadataJSON.flatMap { String(data: $0, encoding: .utf8) },
                        memory.updatedBy, memory.createdAt, memory.updatedAt
                    ]
                )

                try db.execute(
                    sql: "INSERT INTO memories_fts (rowid, content) SELECT rowid, content FROM memories WHERE id = ?",
                    arguments: [memory.id]
                )
            }

            for entity in content.entities {
                let propsJSON = entity.properties.flatMap { try? encoder.encode($0) }
                let altJSON = entity.alternateNames.flatMap { try? encoder.encode($0) }
                try db.execute(
                    sql: """
                        INSERT OR REPLACE INTO entities (id, name, type, properties, alternate_names, created_at, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        entity.id, entity.name, entity.type,
                        propsJSON.flatMap { String(data: $0, encoding: .utf8) },
                        altJSON.flatMap { String(data: $0, encoding: .utf8) },
                        entity.createdAt, entity.updatedAt
                    ]
                )
            }

            for rel in content.relationships {
                let metaJSON = rel.metadata.flatMap { try? encoder.encode($0) }
                try db.execute(
                    sql: """
                        INSERT OR REPLACE INTO relationships (id, source_entity_id, target_entity_id, type, weight, metadata, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        rel.id, rel.sourceEntityId, rel.targetEntityId, rel.type,
                        rel.weight ?? 1.0,
                        metaJSON.flatMap { String(data: $0, encoding: .utf8) },
                        rel.createdAt
                    ]
                )
            }

            for topic in content.topics {
                try db.execute(
                    sql: "INSERT OR REPLACE INTO topics (id, name, parent_id, sort_order) VALUES (?, ?, ?, ?)",
                    arguments: [topic.id, topic.name, topic.parentId, topic.sortOrder]
                )
            }

            for link in content.memoryEntityLinks {
                try db.execute(
                    sql: "INSERT OR REPLACE INTO memory_entity_links (memory_id, entity_id, role) VALUES (?, ?, ?)",
                    arguments: [link.memoryId, link.entityId, link.role]
                )
            }

            for link in content.memoryRefLinks {
                try db.execute(
                    sql: "INSERT OR REPLACE INTO memory_ref_links (memory_id, ref_id, relationship) VALUES (?, ?, ?)",
                    arguments: [link.memoryId, link.refId, link.relationship]
                )
            }

            for ref in content.refs {
                try db.execute(
                    sql: """
                        INSERT OR REPLACE INTO refs (id, filename, path, mime_type, created_at, description, size_bytes)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [ref.id, ref.filename, ref.path, ref.mimeType, ref.createdAt, ref.description, ref.sizeBytes]
                )
            }
        }
    }

    // MARK: - Write

    public func addMemory(_ memory: SiloMemory) throws {
        try dbQueue.write { db in
            let encoder = JSONEncoder()
            let metadataJSON = memory.metadata.flatMap { try? encoder.encode($0) }
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO memories (id, type, content, metadata, updated_by, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    memory.id, memory.type.rawValue, memory.content,
                    metadataJSON.flatMap { String(data: $0, encoding: .utf8) },
                    memory.updatedBy, memory.createdAt, memory.updatedAt
                ]
            )

            try db.execute(
                sql: "INSERT INTO memories_fts (rowid, content) SELECT rowid, content FROM memories WHERE id = ?",
                arguments: [memory.id]
            )
        }
    }

    public func addEntity(_ entity: SiloEntity) throws {
        try dbQueue.write { db in
            let encoder = JSONEncoder()
            let propsJSON = entity.properties.flatMap { try? encoder.encode($0) }
            let altJSON = entity.alternateNames.flatMap { try? encoder.encode($0) }
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO entities (id, name, type, properties, alternate_names, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    entity.id, entity.name, entity.type,
                    propsJSON.flatMap { String(data: $0, encoding: .utf8) },
                    altJSON.flatMap { String(data: $0, encoding: .utf8) },
                    entity.createdAt, entity.updatedAt
                ]
            )
        }
    }

    /// Exports all stored data back into a `SiloContent` struct.
    public func exportContent() throws -> SiloContent {
        try dbQueue.read { db in
            let memoryRows = try Row.fetchAll(db, sql: "SELECT * FROM memories ORDER BY created_at")
            let memories: [SiloMemory] = memoryRows.map { row in
                SiloMemory(
                    id: row["id"],
                    type: MemoryType(rawValue: row["type"]) ?? .custom,
                    content: row["content"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    metadata: nil,
                    updatedBy: row["updated_by"]
                )
            }

            let entityRows = try Row.fetchAll(db, sql: "SELECT * FROM entities ORDER BY created_at")
            let entities: [SiloEntity] = entityRows.map { row in
                SiloEntity(
                    id: row["id"],
                    name: row["name"],
                    type: row["type"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    properties: nil,
                    alternateNames: nil
                )
            }

            let relRows = try Row.fetchAll(db, sql: "SELECT * FROM relationships ORDER BY created_at")
            let relationships: [SiloRelationship] = relRows.map { row in
                SiloRelationship(
                    id: row["id"],
                    sourceEntityId: row["source_entity_id"],
                    targetEntityId: row["target_entity_id"],
                    type: row["type"],
                    createdAt: row["created_at"],
                    weight: row["weight"],
                    metadata: nil
                )
            }

            let topicRows = try Row.fetchAll(db, sql: "SELECT * FROM topics ORDER BY sort_order")
            let topics: [SiloTopic] = topicRows.map { row in
                SiloTopic(id: row["id"], name: row["name"], parentId: row["parent_id"], sortOrder: row["sort_order"])
            }

            let melRows = try Row.fetchAll(db, sql: "SELECT * FROM memory_entity_links")
            let memoryEntityLinks: [MemoryEntityLink] = melRows.map { row in
                MemoryEntityLink(memoryId: row["memory_id"], entityId: row["entity_id"], role: row["role"])
            }

            let mrlRows = try Row.fetchAll(db, sql: "SELECT * FROM memory_ref_links")
            let memoryRefLinks: [MemoryRefLink] = mrlRows.map { row in
                MemoryRefLink(memoryId: row["memory_id"], refId: row["ref_id"], relationship: row["relationship"])
            }

            let refRows = try Row.fetchAll(db, sql: "SELECT * FROM refs ORDER BY created_at")
            let refs: [SiloRef] = refRows.map { row in
                SiloRef(
                    id: row["id"],
                    filename: row["filename"],
                    path: row["path"],
                    mimeType: row["mime_type"],
                    createdAt: row["created_at"],
                    description: row["description"],
                    sizeBytes: row["size_bytes"]
                )
            }

            return SiloContent(
                memories: memories,
                entities: entities,
                relationships: relationships,
                topics: topics,
                memoryEntityLinks: memoryEntityLinks,
                memoryRefLinks: memoryRefLinks,
                refs: refs,
                config: SiloConfig()
            )
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
                SiloMemory(
                    id: row["id"],
                    type: type,
                    content: row["content"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    metadata: nil,
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

    public func allMemories() throws -> [SiloMemory] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM memories ORDER BY created_at")
            return rows.map { row in
                SiloMemory(
                    id: row["id"],
                    type: MemoryType(rawValue: row["type"]) ?? .custom,
                    content: row["content"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    metadata: nil,
                    updatedBy: row["updated_by"]
                )
            }
        }
    }

    public func allEntities() throws -> [SiloEntity] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM entities ORDER BY created_at")
            return rows.map { row in
                SiloEntity(
                    id: row["id"],
                    name: row["name"],
                    type: row["type"],
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"],
                    properties: nil,
                    alternateNames: nil
                )
            }
        }
    }
}
