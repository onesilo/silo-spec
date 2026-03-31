import Foundation

// MARK: - Manifest

public struct SiloManifest: Codable, Sendable {
    public var spec: String
    public var minReader: String
    public var id: String
    public var title: String
    public var createdAt: String
    public var updatedAt: String
    public var mode: SiloMode

    public var description: String?
    public var icon: String?
    public var creator: SiloCreator?
    public var subjectEntityId: String?
    public var sharing: SiloSharing?
    public var tags: [String]?
    public var stats: SiloStats?
    public var extensions: [String: AnyCodable]?

    public init(
        spec: String = "1.0",
        minReader: String = "1.0",
        id: String = UUID().uuidString,
        title: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        mode: SiloMode,
        description: String? = nil,
        icon: String? = nil,
        creator: SiloCreator? = nil,
        subjectEntityId: String? = nil,
        sharing: SiloSharing? = nil,
        tags: [String]? = nil,
        stats: SiloStats? = nil,
        extensions: [String: AnyCodable]? = nil
    ) {
        let now = ISO8601DateFormatter().string(from: Date())
        self.spec = spec
        self.minReader = minReader
        self.id = id
        self.title = title
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
        self.mode = mode
        self.description = description
        self.icon = icon
        self.creator = creator
        self.subjectEntityId = subjectEntityId
        self.sharing = sharing
        self.tags = tags
        self.stats = stats
        self.extensions = extensions
    }

    enum CodingKeys: String, CodingKey {
        case spec, id, title, mode, description, icon, creator, sharing, tags, stats, extensions
        case minReader = "min_reader"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case subjectEntityId = "subject_entity_id"
    }
}

public enum SiloMode: String, Codable, Sendable {
    case container
    case augmented
    case open
}

public struct SiloCreator: Codable, Sendable {
    public let name: String
    public let uri: String?

    public init(name: String, uri: String? = nil) {
        self.name = name
        self.uri = uri
    }
}

public struct SiloSharing: Codable, Sendable {
    public let accessMode: String?
    public let allowReshare: Bool?

    public init(accessMode: String? = nil, allowReshare: Bool? = nil) {
        self.accessMode = accessMode
        self.allowReshare = allowReshare
    }

    enum CodingKeys: String, CodingKey {
        case accessMode = "access_mode"
        case allowReshare = "allow_reshare"
    }
}

public struct SiloStats: Codable, Sendable {
    public var memoryCount: Int?
    public var entityCount: Int?
    public var refCount: Int?
    public var refSizeBytes: Int?

    public init(memoryCount: Int? = nil, entityCount: Int? = nil, refCount: Int? = nil, refSizeBytes: Int? = nil) {
        self.memoryCount = memoryCount
        self.entityCount = entityCount
        self.refCount = refCount
        self.refSizeBytes = refSizeBytes
    }

    enum CodingKeys: String, CodingKey {
        case memoryCount = "memory_count"
        case entityCount = "entity_count"
        case refCount = "ref_count"
        case refSizeBytes = "ref_size_bytes"
    }
}

// MARK: - Silo Content

public struct SiloContent: Codable, Sendable {
    public var memories: [SiloMemory]
    public var entities: [SiloEntity]
    public var relationships: [SiloRelationship]
    public var topics: [SiloTopic]
    public var memoryEntityLinks: [MemoryEntityLink]
    public var memoryRefLinks: [MemoryRefLink]
    public var refs: [SiloRef]
    public var config: SiloConfig

    public init(
        memories: [SiloMemory] = [],
        entities: [SiloEntity] = [],
        relationships: [SiloRelationship] = [],
        topics: [SiloTopic] = [],
        memoryEntityLinks: [MemoryEntityLink] = [],
        memoryRefLinks: [MemoryRefLink] = [],
        refs: [SiloRef] = [],
        config: SiloConfig = SiloConfig()
    ) {
        self.memories = memories
        self.entities = entities
        self.relationships = relationships
        self.topics = topics
        self.memoryEntityLinks = memoryEntityLinks
        self.memoryRefLinks = memoryRefLinks
        self.refs = refs
        self.config = config
    }

    enum CodingKeys: String, CodingKey {
        case memories, entities, relationships, topics, refs, config
        case memoryEntityLinks = "memory_entity_links"
        case memoryRefLinks = "memory_ref_links"
    }
}

// MARK: - Memory

public struct SiloMemory: Codable, Sendable {
    public let id: String
    public let type: MemoryType
    public let content: String
    public let createdAt: String
    public let updatedAt: String
    public let metadata: [String: AnyCodable]?
    public let updatedBy: String?

    public init(
        id: String = UUID().uuidString,
        type: MemoryType,
        content: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        updatedBy: String? = nil
    ) {
        let now = ISO8601DateFormatter().string(from: Date())
        self.id = id
        self.type = type
        self.content = content
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
        self.metadata = metadata
        self.updatedBy = updatedBy
    }

    enum CodingKeys: String, CodingKey {
        case id, type, content, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
    }
}

public enum MemoryType: String, Codable, Sendable {
    case fact
    case decision
    case narrative
    case insight
    case openItem = "open_item"
    case custom
}

// MARK: - Entity

public struct SiloEntity: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: String
    public let createdAt: String
    public let updatedAt: String
    public let properties: [String: AnyCodable]?
    public let alternateNames: [String]?

    public init(
        id: String = UUID().uuidString,
        name: String,
        type: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        properties: [String: AnyCodable]? = nil,
        alternateNames: [String]? = nil
    ) {
        let now = ISO8601DateFormatter().string(from: Date())
        self.id = id
        self.name = name
        self.type = type
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
        self.properties = properties
        self.alternateNames = alternateNames
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, properties
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case alternateNames = "alternate_names"
    }
}

// MARK: - Relationship

public struct SiloRelationship: Codable, Sendable {
    public let id: String
    public let sourceEntityId: String
    public let targetEntityId: String
    public let type: String
    public let createdAt: String
    public let weight: Double?
    public let metadata: [String: AnyCodable]?

    public init(
        id: String = UUID().uuidString,
        sourceEntityId: String,
        targetEntityId: String,
        type: String,
        createdAt: String? = nil,
        weight: Double? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.sourceEntityId = sourceEntityId
        self.targetEntityId = targetEntityId
        self.type = type
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
        self.weight = weight
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case id, type, weight, metadata
        case sourceEntityId = "source_entity_id"
        case targetEntityId = "target_entity_id"
        case createdAt = "created_at"
    }
}

// MARK: - Topic

public struct SiloTopic: Codable, Sendable {
    public let id: String
    public let name: String
    public let parentId: String?
    public let sortOrder: Int?

    public init(id: String = UUID().uuidString, name: String, parentId: String? = nil, sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case parentId = "parent_id"
        case sortOrder = "sort_order"
    }
}

// MARK: - Links

public struct MemoryEntityLink: Codable, Sendable {
    public let memoryId: String
    public let entityId: String
    public let role: String?

    public init(memoryId: String, entityId: String, role: String? = nil) {
        self.memoryId = memoryId
        self.entityId = entityId
        self.role = role
    }

    enum CodingKeys: String, CodingKey {
        case role
        case memoryId = "memory_id"
        case entityId = "entity_id"
    }
}

public struct MemoryRefLink: Codable, Sendable {
    public let memoryId: String
    public let refId: String
    public let relationship: String?

    public init(memoryId: String, refId: String, relationship: String? = nil) {
        self.memoryId = memoryId
        self.refId = refId
        self.relationship = relationship
    }

    enum CodingKeys: String, CodingKey {
        case relationship
        case memoryId = "memory_id"
        case refId = "ref_id"
    }
}

// MARK: - Ref

public struct SiloRef: Codable, Sendable {
    public let id: String
    public let filename: String
    public let path: String
    public let mimeType: String
    public let createdAt: String
    public let description: String?
    public let sizeBytes: Int?

    public init(
        id: String = UUID().uuidString,
        filename: String,
        path: String,
        mimeType: String,
        createdAt: String? = nil,
        description: String? = nil,
        sizeBytes: Int? = nil
    ) {
        self.id = id
        self.filename = filename
        self.path = path
        self.mimeType = mimeType
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
        self.description = description
        self.sizeBytes = sizeBytes
    }

    enum CodingKeys: String, CodingKey {
        case id, filename, path, description
        case mimeType = "mime_type"
        case createdAt = "created_at"
        case sizeBytes = "size_bytes"
    }
}

// MARK: - Config

public struct SiloConfig: Codable, Sendable {
    public var systemInstructions: String?
    public var modeInstructions: String?
    public var welcomeSummary: String?
    public var welcomeMessage: String?
    public var suggestedPrompts: [String]?
    public var citationRequired: Bool?

    public init(
        systemInstructions: String? = nil,
        modeInstructions: String? = nil,
        welcomeSummary: String? = nil,
        welcomeMessage: String? = nil,
        suggestedPrompts: [String]? = nil,
        citationRequired: Bool? = nil
    ) {
        self.systemInstructions = systemInstructions
        self.modeInstructions = modeInstructions
        self.welcomeSummary = welcomeSummary
        self.welcomeMessage = welcomeMessage
        self.suggestedPrompts = suggestedPrompts
        self.citationRequired = citationRequired
    }

    enum CodingKeys: String, CodingKey {
        case systemInstructions = "system_instructions"
        case modeInstructions = "mode_instructions"
        case welcomeSummary = "welcome_summary"
        case welcomeMessage = "welcome_message"
        case suggestedPrompts = "suggested_prompts"
        case citationRequired = "citation_required"
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { value = NSNull() }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map(\.value) }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict.mapValues(\.value) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type") }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull: try container.encodeNil()
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case let array as [Any]: try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
}
