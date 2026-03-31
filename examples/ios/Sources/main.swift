import Foundation
import SiloKit

guard CommandLine.arguments.count > 1 else {
    print("Usage: silo-example <command> [args]")
    print("")
    print("Commands:")
    print("  read <path.silo>              Open and inspect a .silo file")
    print("  create <title> <output-dir>   Create a sample .silo file")
    print("  validate <path.silo>          Validate a .silo file against the spec")
    exit(1)
}

let command = CommandLine.arguments[1]

switch command {
case "read":
    guard CommandLine.arguments.count > 2 else {
        print("Usage: silo-example read <path.silo>")
        exit(1)
    }
    let path = CommandLine.arguments[2]
    let url = URL(fileURLWithPath: path)

    do {
        let package = try SiloPackage.open(at: url)

        print("=== Manifest ===")
        print("Title: \(package.manifest.title)")
        print("Mode:  \(package.manifest.mode.rawValue)")
        print("Spec:  \(package.manifest.spec)")
        if let desc = package.manifest.description { print("Desc:  \(desc)") }
        if let creator = package.manifest.creator { print("By:    \(creator.name)") }
        print()

        if let welcome = package.content.config.welcomeSummary {
            print("=== Welcome ===")
            print(welcome)
            print()
        }

        print("=== Contents ===")
        print("Memories:      \(package.content.memories.count)")
        print("Entities:      \(package.content.entities.count)")
        print("Relationships: \(package.content.relationships.count)")
        print("Topics:        \(package.content.topics.count)")
        print("Refs:          \(package.content.refs.count)")
        print()

        let typeCounts = Dictionary(grouping: package.content.memories, by: \.type)
        print("=== Memory Breakdown ===")
        for (type, memories) in typeCounts.sorted(by: { $0.value.count > $1.value.count }) {
            print("  \(type.rawValue): \(memories.count)")
        }
        print()

        if let prompts = package.content.config.suggestedPrompts, !prompts.isEmpty {
            print("=== Suggested Prompts ===")
            for prompt in prompts {
                print("  - \(prompt)")
            }
        }

        let validation = SiloValidator.validate(package: package)
        print()
        print("=== Validation ===")
        print("Valid: \(validation.isValid)")
        if !validation.errors.isEmpty {
            print("Errors:")
            for e in validation.errors { print("  [\(e.field)] \(e.message)") }
        }
        if !validation.warnings.isEmpty {
            print("Warnings:")
            for w in validation.warnings { print("  [\(w.field)] \(w.message)") }
        }
    } catch {
        print("Error: \(error)")
        exit(1)
    }

case "create":
    guard CommandLine.arguments.count > 3 else {
        print("Usage: silo-example create <title> <output-dir>")
        exit(1)
    }
    let title = CommandLine.arguments[2]
    let outputDir = URL(fileURLWithPath: CommandLine.arguments[3])

    do {
        let data = SiloWriter(title: title, mode: .augmented)
            .addFact("This is a sample silo created by the SiloKit SDK.", key: "sample")
            .addEntity(name: "SiloKit", type: .concept, properties: ["role": "SDK"])
            .setWelcome(
                summary: "A sample silo demonstrating the SiloKit SDK.",
                prompts: ["What is this silo?", "How was it created?"]
            )
            .setCreator(name: "SiloKit Example")
            .build()

        let fileURL = try data.createPackage(at: outputDir, name: title.lowercased().replacingOccurrences(of: " ", with: "-"))
        print("Created: \(fileURL.path)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }

case "validate":
    guard CommandLine.arguments.count > 2 else {
        print("Usage: silo-example validate <path.silo>")
        exit(1)
    }
    let path = CommandLine.arguments[2]
    let url = URL(fileURLWithPath: path)

    do {
        let package = try SiloPackage.open(at: url)
        let result = SiloValidator.validate(package: package)

        if result.isValid {
            print("PASS - Package is valid")
        } else {
            print("FAIL - \(result.errors.count) error(s)")
        }
        for e in result.errors { print("  ERROR [\(e.field)] \(e.message)") }
        for w in result.warnings { print("  WARN  [\(w.field)] \(w.message)") }
    } catch {
        print("Error: \(error)")
        exit(1)
    }

default:
    print("Unknown command: \(command)")
    exit(1)
}
