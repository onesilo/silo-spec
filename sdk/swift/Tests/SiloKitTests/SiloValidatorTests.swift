import XCTest
@testable import SiloKit

final class SiloValidatorTests: XCTestCase {

    // MARK: - Valid Package

    func testValidPackagePasses() {
        let data = SiloWriter(title: "Valid Silo", mode: .container)
            .addFact(content: "The sky is blue")
            .addEntity(name: "Sky", type: "concept")
            .build()

        let package = SiloPackage(manifest: data.manifest, content: data.content)
        let result = SiloValidator.validate(package: package)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    // MARK: - Manifest Validation

    func testMissingManifestIdFails() {
        var manifest = makeValidManifest()
        manifest.id = ""

        let result = SiloValidator.validate(manifest: manifest)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "manifest.id" }))
    }

    func testMissingManifestTitleFails() {
        var manifest = makeValidManifest()
        manifest.title = ""

        let result = SiloValidator.validate(manifest: manifest)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "manifest.title" }))
    }

    func testInvalidSpecVersionFails() {
        var manifest = makeValidManifest()
        manifest.spec = "not-a-version"

        let result = SiloValidator.validate(manifest: manifest)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "manifest.spec" }))
    }

    func testValidSpecVersionFormats() {
        for version in ["1.0", "1.0.0", "2.1", "10.20.30"] {
            var manifest = makeValidManifest()
            manifest.spec = version
            manifest.minReader = version

            let result = SiloValidator.validate(manifest: manifest)
            XCTAssertTrue(result.isValid, "Version '\(version)' should be valid")
        }
    }

    // MARK: - Content Validation

    func testEmptyMemoryIdFails() {
        let memory = SiloMemory(id: "", type: .fact, content: "content")
        let content = SiloContent(memories: [memory])

        let result = SiloValidator.validate(content: content)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "memories[0].id" }))
    }

    func testEmptyMemoryContentFails() {
        let memory = SiloMemory(id: "m1", type: .fact, content: "")
        let content = SiloContent(memories: [memory])

        let result = SiloValidator.validate(content: content)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "memories[0].content" }))
    }

    func testEmptyEntityNameFails() {
        let entity = SiloEntity(id: "e1", name: "", type: "thing")
        let content = SiloContent(entities: [entity])

        let result = SiloValidator.validate(content: content)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains(where: { $0.field == "entities[0].name" }))
    }

    // MARK: - Broken Links

    func testBrokenEntityLinksProduceWarnings() {
        let memory = SiloMemory(type: .fact, content: "A fact")
        let link = MemoryEntityLink(memoryId: memory.id, entityId: "nonexistent-entity")
        let content = SiloContent(memories: [memory], memoryEntityLinks: [link])

        let result = SiloValidator.validate(content: content)

        XCTAssertTrue(result.isValid, "Broken links are warnings, not errors")
        XCTAssertFalse(result.warnings.isEmpty)
        XCTAssertTrue(result.warnings.contains(where: {
            $0.field.contains("entity_id") && $0.message.contains("nonexistent-entity")
        }))
    }

    func testBrokenRelationshipLinksProduceWarnings() {
        let rel = SiloRelationship(sourceEntityId: "missing-src", targetEntityId: "missing-tgt", type: "knows")
        let content = SiloContent(relationships: [rel])

        let result = SiloValidator.validate(content: content)

        XCTAssertTrue(result.isValid, "Broken relationship links are warnings, not errors")
        XCTAssertEqual(result.warnings.count, 2)
    }

    func testBrokenRefLinksProduceWarnings() {
        let memory = SiloMemory(type: .fact, content: "A fact")
        let link = MemoryRefLink(memoryId: memory.id, refId: "nonexistent-ref")
        let content = SiloContent(memories: [memory], memoryRefLinks: [link])

        let result = SiloValidator.validate(content: content)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.contains(where: {
            $0.field.contains("ref_id") && $0.message.contains("nonexistent-ref")
        }))
    }

    // MARK: - Duplicate IDs

    func testDuplicateMemoryIdsWarn() {
        let m1 = SiloMemory(id: "dup", type: .fact, content: "First")
        let m2 = SiloMemory(id: "dup", type: .fact, content: "Second")
        let content = SiloContent(memories: [m1, m2])

        let result = SiloValidator.validate(content: content)

        XCTAssertTrue(result.warnings.contains(where: { $0.message.contains("Duplicate memory id") }))
    }

    func testDuplicateEntityIdsWarn() {
        let e1 = SiloEntity(id: "dup", name: "First", type: "thing")
        let e2 = SiloEntity(id: "dup", name: "Second", type: "thing")
        let content = SiloContent(entities: [e1, e2])

        let result = SiloValidator.validate(content: content)

        XCTAssertTrue(result.warnings.contains(where: { $0.message.contains("Duplicate entity id") }))
    }

    // MARK: - Package-level Stats Mismatch

    func testStatsMismatchProducesWarning() {
        var manifest = makeValidManifest()
        manifest.stats = SiloStats(memoryCount: 10, entityCount: 5)

        let memory = SiloMemory(type: .fact, content: "One fact")
        let content = SiloContent(memories: [memory])

        let package = SiloPackage(manifest: manifest, content: content)
        let result = SiloValidator.validate(package: package)

        XCTAssertTrue(result.isValid, "Stats mismatch is a warning, not an error")
        XCTAssertTrue(result.warnings.contains(where: { $0.message.contains("declares 10 memories") }))
        XCTAssertTrue(result.warnings.contains(where: { $0.message.contains("declares 5 entities") }))
    }

    // MARK: - Helpers

    private func makeValidManifest() -> SiloManifest {
        SiloManifest(title: "Test", mode: .container)
    }
}
