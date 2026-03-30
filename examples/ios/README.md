# iOS / Swift Example — SiloReader

A minimal Swift Package that demonstrates importing a `.silo` file, parsing `silo.json`, writing to SQLite (via GRDB), building a full-text search index, and running queries.

## Structure

- **SiloReader** — library target with models (`Models.swift`), package parser (`SiloPackage.swift`), and SQLite store (`SiloStore.swift`)
- **SiloReaderCLI** — command-line tool that opens a `.silo` file and demonstrates the full import + query flow

## Usage

```bash
# Build
cd examples/ios
swift build

# Create an example .silo package first
cd ../trip-planning
zip -r ../../trip-planning.silo manifest.json silo.json refs/
cd ../ios

# Run
swift run silo-reader ../../trip-planning.silo

# Run with a search query
swift run silo-reader ../../trip-planning.silo "Florence"
```

## What It Demonstrates

1. **Unzip** the `.silo` package
2. **Parse** `manifest.json` and `silo.json` using `Codable`
3. **Import** all memories, entities, relationships, and links into SQLite
4. **Build** an FTS5 full-text search index on memory content
5. **Query** using full-text search
6. **Display** manifest metadata, content breakdown, and suggested prompts

This is a reference implementation — not production code. A real app would add embedding generation, semantic search, and richer query capabilities.
