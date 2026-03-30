import Foundation
import SiloReader

guard CommandLine.arguments.count > 1 else {
    print("Usage: silo-reader <path-to-silo-file> [search-query]")
    print("  Opens a .silo file, imports into SQLite, and optionally searches.")
    exit(1)
}

let siloPath = CommandLine.arguments[1]
let searchQuery = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil

do {
    let url = URL(fileURLWithPath: siloPath)
    print("Opening \(url.lastPathComponent)...\n")

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
    print("Entities:       \(package.content.entities.count)")
    print("Relationships:  \(package.content.relationships.count)")
    print("Topics:         \(package.content.topics.count)")
    print("Ref files:      \(package.content.refs.count)")
    print()

    let typeCounts = Dictionary(grouping: package.content.memories, by: \.type)
    print("=== Memory Breakdown ===")
    for (type, memories) in typeCounts.sorted(by: { $0.value.count > $1.value.count }) {
        print("  \(type.rawValue): \(memories.count)")
    }
    print()

    let dbPath = FileManager.default.temporaryDirectory
        .appendingPathComponent("silo-example-\(UUID().uuidString).sqlite").path
    let store = try SiloStore(databasePath: dbPath)
    print("Importing into SQLite at \(dbPath)...")
    try store.importContent(package.content)
    print("Import complete.\n")

    if let query = searchQuery {
        print("=== Search: \"\(query)\" ===")
        let results = try store.searchMemories(query: query)
        if results.isEmpty {
            print("No results found.")
        } else {
            for (i, result) in results.enumerated() {
                let preview = String(result.content.prefix(120))
                print("  \(i + 1). [\(result.type)] \(preview)...")
            }
        }
        print()
    }

    if let prompts = package.content.config.suggestedPrompts, !prompts.isEmpty {
        print("=== Suggested Prompts ===")
        for prompt in prompts {
            print("  • \(prompt)")
        }
    }

} catch {
    print("Error: \(error)")
    exit(1)
}
