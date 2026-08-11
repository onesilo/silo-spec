# .silo — Portable, Interactive Knowledge Packages for AI

A `.silo` file is a self-contained package of structured knowledge designed to be queried interactively, not just read.

Unlike documents, spreadsheets, or chat exports, a silo carries structured memories, entities, relationships, and configuration that allow any AI system to understand and reason over the knowledge inside.

## SDKs

Official SDKs for reading and writing `.silo` files:

| Platform | Package | Path |
|----------|---------|------|
| **Swift** (iOS, macOS) | `SiloKit` | [`sdk/swift/`](sdk/swift/) |
| **TypeScript** (Web, Node) | `@onesilo/silo-sdk` | [`sdk/js/`](sdk/js/) |

### Swift (SPM)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/onesilo/silo-spec.git", from: "0.1.0"),
],
targets: [
    .target(dependencies: [.product(name: "SiloKit", package: "silo-spec")]),
]
```

```swift
import SiloKit

// Create a silo
let silo = SiloWriter(title: "Italy Trip", mode: .augmented)
    .addFact("Budget is $5K per person", key: "budget")
    .addDecision("Ravello over Positano", why: "Less crowded in June")
    .addEntity(name: "Marco", type: .person)
    .setWelcome(summary: "Two-week Italy trip plan", prompts: ["What's the plan?"])
    .build()

let fileURL = try silo.createPackage(at: outputDir, name: "italy-trip")

// Open a silo
let package = try SiloPackage.open(at: fileURL)
print(package.manifest.title)       // "Italy Trip"
print(package.content.memories.count) // 2

// Validate
let result = SiloValidator.validate(package: package)
print(result.isValid) // true

// Mode enforcement
let prompt = SiloModeEnforcer.systemPrompt(for: .augmented, siloTitle: "Italy Trip")
```

### TypeScript (npm)

```bash
npm install @onesilo/silo-sdk
```

```typescript
import { SiloWriter, openSiloPackage, validatePackage, getModeSystemPrompt } from "@onesilo/silo-sdk";

// Create a silo
const silo = new SiloWriter("Italy Trip", "augmented")
  .addFact("Budget is $5K per person", { key: "budget" })
  .addDecision("Ravello over Positano", { why: "Less crowded in June" })
  .addEntity("Marco", "person")
  .setWelcome({ summary: "Two-week Italy trip plan", prompts: ["What's the plan?"] })
  .build();

const blob = await silo.toBlob(); // .silo zip as Blob

// Open a silo
const pkg = await openSiloPackage(blob);
console.log(pkg.manifest.title);         // "Italy Trip"
console.log(pkg.content.memories.length); // 2

// Validate
const result = validatePackage(pkg);
console.log(result.isValid); // true

// Mode enforcement
const prompt = getModeSystemPrompt("augmented", "Italy Trip");
```

## What's in a .silo file?

A `.silo` file is a zip archive containing:

```
example.silo
├── manifest.json    # Metadata, mode, versioning
├── silo.json        # Structured knowledge content
└── refs/            # Optional reference files (PDFs, images, data)
```

**manifest.json** describes the silo — its title, creator, interaction mode, and format version.

**silo.json** contains the knowledge — memories (facts, decisions, insights, narratives), entities (people, places, companies), relationships between entities, and configuration for how the silo should behave when queried.

**refs/** holds reference files — documents, images, or structured data that memories can link to.

## Knowledge, Not Data

A silo stores knowledge at the right level of abstraction. Individual data points (heart rate readings, raw chat messages, email threads) are distilled into meaningful memories before storage:

- **Facts** — concrete, stated knowledge: "Budget is $5K per person"
- **Decisions** — choices with reasoning: "Chose Ravello over Positano because..."
- **Narratives** — rich topic summaries: the GTM strategy writeup, the Rome itinerary
- **Insights** — semantic reasoning about the silo's subject: "Prefers adventure over sightseeing"
- **Open Items** — unresolved questions: "Still need to book the wine tour"
- **Custom** — app-specific structured content with a natural language summary for search

Raw data can be stored as reference files in `refs/` and linked to the memories that summarize it.

## Interaction Modes

Every silo declares an interaction mode that governs how an AI should respond when querying it:

- **Container** — answers must come exclusively from silo content. If the answer isn't present, say so. No fabrication.
- **Augmented** — silo content is primary. The querying user's personal context can fill gaps. No general world knowledge.
- **Open** — silo content is context, but the AI can use its full capabilities. Provenance should be labeled.

The mode is set by the silo's creator and travels with the file. It cannot be overridden by the recipient.

## Portable and Implementation-Agnostic

The `.silo` format is JSON-based and does not prescribe how content should be stored or indexed. Each platform imports `silo.json` into its own infrastructure:

- An iOS app might use SQLite + on-device embeddings
- A server might use Postgres + Pinecone
- A web app might use IndexedDB + an API embedding service

The format defines *what* knowledge a silo contains. *How* it's stored and queried is up to the implementation.

## Versioning

The format follows additive-only evolution:

- New fields may be added in future versions
- Readers must ignore unknown fields ([Postel's Law](https://en.wikipedia.org/wiki/Robustness_principle))
- Writers must not remove fields that existed in earlier versions
- Breaking changes require a major version bump

`manifest.json` includes a `spec` version and a `min_reader` version so readers can determine compatibility.

## Specification

The full format specification is in [`spec/v0.1.1.md`](spec/v0.1.1.md) (v0.1.0 in [`spec/v0.1.0.md`](spec/v0.1.0.md)).

The **MemoryStore interface** — the standard memory abstraction One Silo agents use to remember/recall/forget against a silo, wherever it lives (cloud, node, relay, file) — is specified in [`spec/memory-store-v0.1.0.md`](spec/memory-store-v0.1.0.md).

## Examples

Complete, valid `.silo` packages:

- [`examples/trip-planning/`](examples/trip-planning/) — a two-week Italy trip with itinerary, decisions, restaurants, and open items
- [`examples/company-knowledge-base/`](examples/company-knowledge-base/) — an internal company knowledge base with vision, strategy, team, financials, and competitive landscape

Demo apps using the SDKs:

- [`examples/ios/`](examples/ios/) — Swift CLI that reads, creates, and validates `.silo` files
- [`examples/web/`](examples/web/) — TypeScript script that creates a silo and demonstrates validation and mode enforcement

## License

Apache 2.0 — see [LICENSE](LICENSE).
