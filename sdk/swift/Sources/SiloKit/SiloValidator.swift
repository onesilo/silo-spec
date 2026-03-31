import Foundation

// MARK: - Validation Types

public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [ValidationIssue]
    public let warnings: [ValidationIssue]

    public init(isValid: Bool, errors: [ValidationIssue], warnings: [ValidationIssue]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }

    static func combining(_ results: [ValidationResult]) -> ValidationResult {
        let allErrors = results.flatMap(\.errors)
        let allWarnings = results.flatMap(\.warnings)
        return ValidationResult(isValid: allErrors.isEmpty, errors: allErrors, warnings: allWarnings)
    }
}

public struct ValidationIssue: Sendable {
    public let field: String
    public let message: String

    public init(field: String, message: String) {
        self.field = field
        self.message = message
    }
}

// MARK: - Validator

public enum SiloValidator {

    public static func validate(manifest: SiloManifest) -> ValidationResult {
        var errors: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []

        if manifest.id.isEmpty {
            errors.append(ValidationIssue(field: "manifest.id", message: "Manifest id is required"))
        }
        if manifest.title.isEmpty {
            errors.append(ValidationIssue(field: "manifest.title", message: "Manifest title is required"))
        }
        if manifest.spec.isEmpty {
            errors.append(ValidationIssue(field: "manifest.spec", message: "Spec version is required"))
        }
        if !isValidVersionFormat(manifest.spec) {
            errors.append(ValidationIssue(field: "manifest.spec", message: "Spec version must be in semver format (e.g. \"1.0\" or \"1.0.0\")"))
        }
        if manifest.minReader.isEmpty {
            errors.append(ValidationIssue(field: "manifest.min_reader", message: "min_reader version is required"))
        }
        if !isValidVersionFormat(manifest.minReader) {
            errors.append(ValidationIssue(field: "manifest.min_reader", message: "min_reader must be in semver format"))
        }
        if manifest.createdAt.isEmpty {
            errors.append(ValidationIssue(field: "manifest.created_at", message: "created_at is required"))
        }
        if manifest.updatedAt.isEmpty {
            errors.append(ValidationIssue(field: "manifest.updated_at", message: "updated_at is required"))
        }

        if let stats = manifest.stats {
            if let mc = stats.memoryCount, mc < 0 {
                warnings.append(ValidationIssue(field: "manifest.stats.memory_count", message: "memory_count should not be negative"))
            }
            if let ec = stats.entityCount, ec < 0 {
                warnings.append(ValidationIssue(field: "manifest.stats.entity_count", message: "entity_count should not be negative"))
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    public static func validate(content: SiloContent) -> ValidationResult {
        var errors: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []

        let validMemoryTypes = Set(["fact", "decision", "narrative", "insight", "open_item", "custom"])

        for (i, memory) in content.memories.enumerated() {
            if memory.id.isEmpty {
                errors.append(ValidationIssue(field: "memories[\(i)].id", message: "Memory id is required"))
            }
            if memory.content.isEmpty {
                errors.append(ValidationIssue(field: "memories[\(i)].content", message: "Memory content is required"))
            }
            if !validMemoryTypes.contains(memory.type.rawValue) {
                errors.append(ValidationIssue(field: "memories[\(i)].type", message: "Invalid memory type: \(memory.type.rawValue)"))
            }
        }

        let memoryIds = Set(content.memories.map(\.id))
        let entityIds = Set(content.entities.map(\.id))
        let refIds = Set(content.refs.map(\.id))

        for (i, entity) in content.entities.enumerated() {
            if entity.id.isEmpty {
                errors.append(ValidationIssue(field: "entities[\(i)].id", message: "Entity id is required"))
            }
            if entity.name.isEmpty {
                errors.append(ValidationIssue(field: "entities[\(i)].name", message: "Entity name is required"))
            }
            if entity.type.isEmpty {
                errors.append(ValidationIssue(field: "entities[\(i)].type", message: "Entity type is required"))
            }
        }

        for (i, rel) in content.relationships.enumerated() {
            if rel.id.isEmpty {
                errors.append(ValidationIssue(field: "relationships[\(i)].id", message: "Relationship id is required"))
            }
            if !entityIds.contains(rel.sourceEntityId) {
                warnings.append(ValidationIssue(
                    field: "relationships[\(i)].source_entity_id",
                    message: "Source entity \(rel.sourceEntityId) not found in entities"
                ))
            }
            if !entityIds.contains(rel.targetEntityId) {
                warnings.append(ValidationIssue(
                    field: "relationships[\(i)].target_entity_id",
                    message: "Target entity \(rel.targetEntityId) not found in entities"
                ))
            }
        }

        for (i, link) in content.memoryEntityLinks.enumerated() {
            if !memoryIds.contains(link.memoryId) {
                warnings.append(ValidationIssue(
                    field: "memory_entity_links[\(i)].memory_id",
                    message: "Memory \(link.memoryId) not found in memories"
                ))
            }
            if !entityIds.contains(link.entityId) {
                warnings.append(ValidationIssue(
                    field: "memory_entity_links[\(i)].entity_id",
                    message: "Entity \(link.entityId) not found in entities"
                ))
            }
        }

        for (i, link) in content.memoryRefLinks.enumerated() {
            if !memoryIds.contains(link.memoryId) {
                warnings.append(ValidationIssue(
                    field: "memory_ref_links[\(i)].memory_id",
                    message: "Memory \(link.memoryId) not found in memories"
                ))
            }
            if !refIds.contains(link.refId) {
                warnings.append(ValidationIssue(
                    field: "memory_ref_links[\(i)].ref_id",
                    message: "Ref \(link.refId) not found in refs"
                ))
            }
        }

        let duplicateMemoryIds = findDuplicates(content.memories.map(\.id))
        for id in duplicateMemoryIds {
            warnings.append(ValidationIssue(field: "memories", message: "Duplicate memory id: \(id)"))
        }

        let duplicateEntityIds = findDuplicates(content.entities.map(\.id))
        for id in duplicateEntityIds {
            warnings.append(ValidationIssue(field: "entities", message: "Duplicate entity id: \(id)"))
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    public static func validate(package: SiloPackage) -> ValidationResult {
        let manifestResult = validate(manifest: package.manifest)
        let contentResult = validate(content: package.content)

        var warnings = manifestResult.warnings + contentResult.warnings

        if let stats = package.manifest.stats {
            if let expected = stats.memoryCount, expected != package.content.memories.count {
                warnings.append(ValidationIssue(
                    field: "manifest.stats.memory_count",
                    message: "Manifest declares \(expected) memories but content has \(package.content.memories.count)"
                ))
            }
            if let expected = stats.entityCount, expected != package.content.entities.count {
                warnings.append(ValidationIssue(
                    field: "manifest.stats.entity_count",
                    message: "Manifest declares \(expected) entities but content has \(package.content.entities.count)"
                ))
            }
        }

        let errors = manifestResult.errors + contentResult.errors
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }

    // MARK: - Helpers

    private static func isValidVersionFormat(_ version: String) -> Bool {
        let pattern = #"^\d+(\.\d+){0,2}$"#
        return version.range(of: pattern, options: .regularExpression) != nil
    }

    private static func findDuplicates(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for id in ids {
            if seen.contains(id) {
                duplicates.insert(id)
            }
            seen.insert(id)
        }
        return Array(duplicates).sorted()
    }
}
