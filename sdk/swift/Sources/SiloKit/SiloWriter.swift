import Foundation

/// Builder for creating silo packages programmatically.
///
/// Usage:
/// ```swift
/// let data = try SiloWriter(title: "My Silo", mode: .container)
///     .addFact(content: "The sky is blue")
///     .addEntity(name: "Sky", type: "concept")
///     .setConfig(systemInstructions: "Answer only from silo content.")
///     .build()
///
/// let packageURL = try data.createPackage(at: outputDir, name: "my-silo")
/// ```
public final class SiloWriter {
    private let title: String
    private let mode: SiloMode
    private let siloId: String

    private var memories: [SiloMemory] = []
    private var entities: [SiloEntity] = []
    private var relationships: [SiloRelationship] = []
    private var topics: [SiloTopic] = []
    private var memoryEntityLinks: [MemoryEntityLink] = []
    private var config = SiloConfig()
    private var description: String?
    private var icon: String?
    private var tags: [String]?
    private var subjectEntityId: String?
    private var creator: SiloCreator?

    public init(title: String, mode: SiloMode) {
        self.title = title
        self.mode = mode
        self.siloId = UUID().uuidString
    }

    // MARK: - Memories

    @discardableResult
    public func addFact(content: String, key: String? = nil, confidence: Double? = nil) -> Self {
        var metadata: [String: AnyCodable]?
        if key != nil || confidence != nil {
            var dict: [String: AnyCodable] = [:]
            if let key { dict["key"] = AnyCodable(key) }
            if let confidence { dict["confidence"] = AnyCodable(confidence) }
            metadata = dict
        }
        memories.append(SiloMemory(type: .fact, content: content, metadata: metadata))
        return self
    }

    @discardableResult
    public func addDecision(content: String, title: String? = nil, why: String? = nil, alternatives: [String]? = nil) -> Self {
        var metadata: [String: AnyCodable]?
        if title != nil || why != nil || alternatives != nil {
            var dict: [String: AnyCodable] = [:]
            if let title { dict["title"] = AnyCodable(title) }
            if let why { dict["why"] = AnyCodable(why) }
            if let alternatives { dict["alternatives"] = AnyCodable(alternatives) }
            metadata = dict
        }
        memories.append(SiloMemory(type: .decision, content: content, metadata: metadata))
        return self
    }

    @discardableResult
    public func addNarrative(content: String, title: String? = nil, topic: String? = nil) -> Self {
        var metadata: [String: AnyCodable]?
        if title != nil || topic != nil {
            var dict: [String: AnyCodable] = [:]
            if let title { dict["title"] = AnyCodable(title) }
            if let topic { dict["topic"] = AnyCodable(topic) }
            metadata = dict
        }
        memories.append(SiloMemory(type: .narrative, content: content, metadata: metadata))
        return self
    }

    @discardableResult
    public func addInsight(content: String, title: String? = nil, confidence: Double? = nil, supportingIds: [String]? = nil) -> Self {
        var metadata: [String: AnyCodable]?
        if title != nil || confidence != nil || supportingIds != nil {
            var dict: [String: AnyCodable] = [:]
            if let title { dict["title"] = AnyCodable(title) }
            if let confidence { dict["confidence"] = AnyCodable(confidence) }
            if let supportingIds { dict["supporting_ids"] = AnyCodable(supportingIds) }
            metadata = dict
        }
        memories.append(SiloMemory(type: .insight, content: content, metadata: metadata))
        return self
    }

    @discardableResult
    public func addOpenItem(content: String, priority: String? = nil) -> Self {
        var metadata: [String: AnyCodable]?
        if let priority {
            metadata = ["priority": AnyCodable(priority)]
        }
        memories.append(SiloMemory(type: .openItem, content: content, metadata: metadata))
        return self
    }

    // MARK: - Entities & Relationships

    @discardableResult
    public func addEntity(name: String, type: String, properties: [String: AnyCodable]? = nil) -> Self {
        entities.append(SiloEntity(name: name, type: type, properties: properties))
        return self
    }

    @discardableResult
    public func addRelationship(sourceId: String, targetId: String, type: String) -> Self {
        relationships.append(SiloRelationship(sourceEntityId: sourceId, targetEntityId: targetId, type: type))
        return self
    }

    // MARK: - Config

    @discardableResult
    public func setConfig(
        systemInstructions: String? = nil,
        modeInstructions: String? = nil,
        welcome: String? = nil,
        prompts: [String]? = nil,
        citationRequired: Bool? = nil
    ) -> Self {
        config = SiloConfig(
            systemInstructions: systemInstructions,
            modeInstructions: modeInstructions,
            welcomeMessage: welcome,
            suggestedPrompts: prompts,
            citationRequired: citationRequired
        )
        return self
    }

    @discardableResult
    public func setSubjectEntity(id: String) -> Self {
        subjectEntityId = id
        return self
    }

    @discardableResult
    public func setCreator(name: String, uri: String? = nil) -> Self {
        creator = SiloCreator(name: name, uri: uri)
        return self
    }

    @discardableResult
    public func setDescription(_ description: String) -> Self {
        self.description = description
        return self
    }

    @discardableResult
    public func setIcon(_ icon: String) -> Self {
        self.icon = icon
        return self
    }

    @discardableResult
    public func setTags(_ tags: [String]) -> Self {
        self.tags = tags
        return self
    }

    // MARK: - Build

    public func build() -> SiloPackageData {
        let now = ISO8601DateFormatter().string(from: Date())

        let stats = SiloStats(
            memoryCount: memories.count,
            entityCount: entities.count,
            refCount: 0,
            refSizeBytes: 0
        )

        let manifest = SiloManifest(
            spec: "1.0",
            minReader: "1.0",
            id: siloId,
            title: title,
            createdAt: now,
            updatedAt: now,
            mode: mode,
            description: description,
            icon: icon,
            creator: creator,
            subjectEntityId: subjectEntityId,
            tags: tags,
            stats: stats
        )

        let content = SiloContent(
            memories: memories,
            entities: entities,
            relationships: relationships,
            topics: topics,
            memoryEntityLinks: memoryEntityLinks,
            config: config
        )

        return SiloPackageData(manifest: manifest, content: content)
    }
}

// MARK: - SiloPackageData

public struct SiloPackageData: Sendable {
    public let manifest: SiloManifest
    public let content: SiloContent

    public init(manifest: SiloManifest, content: SiloContent) {
        self.manifest = manifest
        self.content = content
    }

    /// Writes manifest.json, silo.json, and creates refs/ directory.
    /// Returns the URL of the directory containing the written files.
    public func writeToDirectory(_ directory: URL) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: directory.appendingPathComponent("manifest.json"))

        let contentData = try encoder.encode(content)
        try contentData.write(to: directory.appendingPathComponent("silo.json"))

        let refsDir = directory.appendingPathComponent("refs")
        try fm.createDirectory(at: refsDir, withIntermediateDirectories: true)

        return directory
    }

    /// Creates a .silo zip package at the given directory with the specified name.
    /// Returns the URL of the created .silo file.
    public func createPackage(at directory: URL, name: String) throws -> URL {
        let stagingDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("silo-stage-\(UUID().uuidString)")
        _ = try writeToDirectory(stagingDir)
        defer { try? FileManager.default.removeItem(at: stagingDir) }

        var error: NSError?
        var resultURL: URL?

        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: stagingDir,
            options: .forUploading,
            error: &error
        ) { zipURL in
            let sanitized = name.replacingOccurrences(of: "/", with: "-")
            let dest = directory.appendingPathComponent("\(sanitized).silo")
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? FileManager.default.copyItem(at: zipURL, to: dest)
            resultURL = dest
        }

        if let error { throw error }
        guard let result = resultURL else {
            throw SiloPackageError.zipFailed
        }
        return result
    }
}
