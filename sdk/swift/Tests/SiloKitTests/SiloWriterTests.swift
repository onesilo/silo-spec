import XCTest
@testable import SiloKit

final class SiloWriterTests: XCTestCase {

    func testBuilderProducesValidManifest() {
        let data = SiloWriter(title: "Test Silo", mode: .container)
            .addFact(content: "The earth orbits the sun")
            .addFact(content: "Water boils at 100°C at sea level")
            .addDecision(content: "Use Swift for the SDK", title: "Language Choice", why: "Type safety")
            .addEntity(name: "Earth", type: "planet")
            .setCreator(name: "SiloKit Tests", uri: "https://example.com")
            .build()

        XCTAssertEqual(data.manifest.title, "Test Silo")
        XCTAssertEqual(data.manifest.mode, .container)
        XCTAssertEqual(data.manifest.spec, "1.0")
        XCTAssertEqual(data.manifest.stats?.memoryCount, 3)
        XCTAssertEqual(data.manifest.stats?.entityCount, 1)
        XCTAssertEqual(data.manifest.creator?.name, "SiloKit Tests")
        XCTAssertEqual(data.manifest.creator?.uri, "https://example.com")
        XCTAssertFalse(data.manifest.id.isEmpty)
        XCTAssertFalse(data.manifest.createdAt.isEmpty)
    }

    func testBuilderMemoryTypes() {
        let data = SiloWriter(title: "Types Test", mode: .open)
            .addFact(content: "fact content", key: "key1", confidence: 0.9)
            .addDecision(content: "decision content", title: "D1", why: "because", alternatives: ["alt1"])
            .addNarrative(content: "narrative content", title: "N1", topic: "topic1")
            .addInsight(content: "insight content", title: "I1", confidence: 0.8, supportingIds: ["m1"])
            .addOpenItem(content: "open item content", priority: "high")
            .build()

        let types = data.content.memories.map(\.type)
        XCTAssertEqual(types, [.fact, .decision, .narrative, .insight, .openItem])

        XCTAssertEqual(data.content.memories[0].content, "fact content")
        XCTAssertEqual(data.content.memories[4].content, "open item content")
    }

    func testBuilderEntitiesAndRelationships() {
        let data = SiloWriter(title: "Graph Test", mode: .augmented)
            .addEntity(name: "Alice", type: "person")
            .addEntity(name: "Bob", type: "person")
            .addRelationship(sourceId: "alice-id", targetId: "bob-id", type: "knows")
            .build()

        XCTAssertEqual(data.content.entities.count, 2)
        XCTAssertEqual(data.content.relationships.count, 1)
        XCTAssertEqual(data.content.relationships[0].type, "knows")
    }

    func testBuilderConfig() {
        let data = SiloWriter(title: "Config Test", mode: .container)
            .setConfig(
                systemInstructions: "Be helpful",
                modeInstructions: "Container rules",
                welcome: "Welcome!",
                prompts: ["Tell me about X", "Summarize Y"],
                citationRequired: true
            )
            .build()

        XCTAssertEqual(data.content.config.systemInstructions, "Be helpful")
        XCTAssertEqual(data.content.config.modeInstructions, "Container rules")
        XCTAssertEqual(data.content.config.welcomeMessage, "Welcome!")
        XCTAssertEqual(data.content.config.suggestedPrompts, ["Tell me about X", "Summarize Y"])
        XCTAssertEqual(data.content.config.citationRequired, true)
    }

    func testBuilderSubjectEntityAndTags() {
        let data = SiloWriter(title: "Meta Test", mode: .open)
            .setSubjectEntity(id: "entity-123")
            .setDescription("A test silo")
            .setIcon("📦")
            .setTags(["test", "sdk"])
            .build()

        XCTAssertEqual(data.manifest.subjectEntityId, "entity-123")
        XCTAssertEqual(data.manifest.description, "A test silo")
        XCTAssertEqual(data.manifest.icon, "📦")
        XCTAssertEqual(data.manifest.tags, ["test", "sdk"])
    }

    func testWriteToDirectoryProducesFiles() throws {
        let data = SiloWriter(title: "File Test", mode: .container)
            .addFact(content: "Test fact")
            .build()

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("silokit-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let outputDir = try data.writeToDirectory(tempDir)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("manifest.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("silo.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("refs").path))

        let manifestData = try Data(contentsOf: outputDir.appendingPathComponent("manifest.json"))
        let manifest = try JSONDecoder().decode(SiloManifest.self, from: manifestData)
        XCTAssertEqual(manifest.title, "File Test")

        let contentData = try Data(contentsOf: outputDir.appendingPathComponent("silo.json"))
        let content = try JSONDecoder().decode(SiloContent.self, from: contentData)
        XCTAssertEqual(content.memories.count, 1)
        XCTAssertEqual(content.memories[0].type, .fact)
    }

    func testRoundTripEncodeDecode() throws {
        let original = SiloWriter(title: "Round Trip", mode: .augmented)
            .addFact(content: "Fact A")
            .addDecision(content: "Decision B", title: "DB")
            .addEntity(name: "Entity1", type: "thing")
            .setCreator(name: "Tester")
            .build()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let manifestJSON = try encoder.encode(original.manifest)
        let contentJSON = try encoder.encode(original.content)

        let decoder = JSONDecoder()
        let decodedManifest = try decoder.decode(SiloManifest.self, from: manifestJSON)
        let decodedContent = try decoder.decode(SiloContent.self, from: contentJSON)

        XCTAssertEqual(decodedManifest.title, "Round Trip")
        XCTAssertEqual(decodedManifest.mode, .augmented)
        XCTAssertEqual(decodedManifest.stats?.memoryCount, 2)
        XCTAssertEqual(decodedManifest.stats?.entityCount, 1)
        XCTAssertEqual(decodedContent.memories.count, 2)
        XCTAssertEqual(decodedContent.entities.count, 1)
        XCTAssertEqual(decodedContent.memories[0].type, .fact)
        XCTAssertEqual(decodedContent.memories[1].type, .decision)
    }

    func testBuildValidatesWithValidator() {
        let data = SiloWriter(title: "Validated", mode: .container)
            .addFact(content: "Something important")
            .addEntity(name: "Important Thing", type: "concept")
            .build()

        let package = SiloPackage(manifest: data.manifest, content: data.content)
        let result = SiloValidator.validate(package: package)

        XCTAssertTrue(result.isValid, "Builder output should pass validation. Errors: \(result.errors.map(\.message))")
        XCTAssertTrue(result.errors.isEmpty)
    }
}
