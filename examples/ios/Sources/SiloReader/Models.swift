import Foundation

// MARK: - Manifest

public struct SiloManifest: Codable {
    public let spec: String
    public let minReader: String
    public let id: String
    public let title: String
    public let createdAt: String
    public let updatedAt: String
    public let mode: SiloMode

    public let description: String?
    public let icon: String?
    public let creator: SiloCreator?
    public let subjectEntityId: String?
    public let sharing: SiloSharing?
    public let tags: [String]?
    public let stats: SiloStats?
    public let extensions: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case spec, id, title, mode, description, icon, creator, sharing, tags, stats, extensions
        case minReader = "min_reader"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case subjectEntityId = "subject_entity_id"
    }
}

public enum SiloMode: String, Codable {
    case container
    case augmented
    case open
}

public struct SiloCreator: Codable {
    public let name: String
    public let uri: String?
}

public struct SiloSharing: Codable {
    public let accessMode: String?
    public let allowReshare: Bool?

    enum CodingKeys: String, CodingKey {
        case accessMode = "access_mode"
        case allowReshare = "allow_reshare"
    }
}

public struct SiloStats: Codable {
    public let memoryCount: Int?
    public let entityCount: Int?
    public let refCount: Int?
    public let refSizeBytes: Int?

    enum CodingKeys: String, CodingKey {
        case memoryCount = "memory_count"
        case entityCount = "entity_count"
        case refCount = "ref_count"
        case refSizeBytes = "ref_size_bytes"
    }
}

// MARK: - Silo Content

public struct SiloContent: Codable {
    public let memories: [SiloMemory]
    public let entities: [SiloEntity]
    public let relationships: [SiloRelationship]
    public let topics: [SiloTopic]
    public let memoryEntityLinks: [MemoryEntityLink]
    public let memoryRefLinks: [MemoryRefLink]
    public let refs: [SiloRef]
    public let config: SiloConfig

    enum CodingKeys: String, CodingKey {
        case memories, entities, relationships, topics, refs, config
        case memoryEntityLinks = "memory_entity_links"
        case memoryRefLinks = "memory_ref_links"
    }
}

// MARK: - Memory

public struct SiloMemory: Codable {
    public let id: String
    public let type: MemoryType
    public let content: String
    public let createdAt: String
    public let updatedAt: String
    public let metadata: [String: AnyCodable]?
    public let updatedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, type, content, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
    }
}

public enum MemoryType: String, Codable {
    case fact
    case decision
    case narrative
    case insight
    case openItem = "open_item"
    case custom
}

// MARK: - Entity

public struct SiloEntity: Codable {
    public let id: String
    public let name: String
    public let type: String
    public let createdAt: String
    public let updatedAt: String
    public let properties: [String: AnyCodable]?
    public let alternateNames: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, properties
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case alternateNames = "alternate_names"
    }
}

// MARK: - Relationship

public struct SiloRelationship: Codable {
    public let id: String
    public let sourceEntityId: String
    public let targetEntityId: String
    public let type: String
    public let createdAt: String
    public let weight: Double?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id, type, weight, metadata
        case sourceEntityId = "source_entity_id"
        case targetEntityId = "target_entity_id"
        case createdAt = "created_at"
    }
}

// MARK: - Topic

public struct SiloTopic: Codable {
    public let id: String
    public let name: String
    public let parentId: String?
    public let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case parentId = "parent_id"
        case sortOrder = "sort_order"
    }
}

// MARK: - Links

public struct MemoryEntityLink: Codable {
    public let memoryId: String
    public let entityId: String
    public let role: String?

    enum CodingKeys: String, CodingKey {
        case role
        case memoryId = "memory_id"
        case entityId = "entity_id"
    }
}

public struct MemoryRefLink: Codable {
    public let memoryId: String
    public let refId: String
    public let relationship: String?

    enum CodingKeys: String, CodingKey {
        case relationship
        case memoryId = "memory_id"
        case refId = "ref_id"
    }
}

// MARK: - Ref

public struct SiloRef: Codable {
    public let id: String
    public let filename: String
    public let path: String
    public let mimeType: String
    public let createdAt: String
    public let description: String?
    public let sizeBytes: Int?

    enum CodingKeys: String, CodingKey {
        case id, filename, path, description
        case mimeType = "mime_type"
        case createdAt = "created_at"
        case sizeBytes = "size_bytes"
    }
}

// MARK: - Config

public struct SiloConfig: Codable {
    public let systemInstructions: String?
    public let modeInstructions: String?
    public let welcomeSummary: String?
    public let welcomeMessage: String?
    public let suggestedPrompts: [String]?
    public let citationRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case systemInstructions = "system_instructions"
        case modeInstructions = "mode_instructions"
        case welcomeSummary = "welcome_summary"
        case welcomeMessage = "welcome_message"
        case suggestedPrompts = "suggested_prompts"
        case citationRequired = "citation_required"
    }
}

// MARK: - AnyCodable (lightweight type-erased wrapper)

public struct AnyCodable: Codable {
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
        default: throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
