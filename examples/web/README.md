# Web / TypeScript Example — SiloReader

A minimal TypeScript library that demonstrates importing a `.silo` file, parsing `silo.json`, storing in IndexedDB, and running basic keyword search.

## Structure

- **src/types.ts** — TypeScript types matching the .silo spec v0.1.0
- **src/silo-package.ts** — unzips a `.silo` file and parses manifest + content
- **src/silo-store.ts** — IndexedDB storage with import and keyword search
- **src/index.ts** — public API exports

## Usage

```bash
npm install
npm run build
```

### In a browser app:

```typescript
import { openSiloPackage, SiloStore } from "silo-reader-web";

// From a file input
const file = fileInput.files[0];
const pkg = await openSiloPackage(file);

console.log(pkg.manifest.title);     // "Italy Trip — June 2026"
console.log(pkg.manifest.mode);      // "augmented"
console.log(pkg.content.memories);   // [...memories]

// Import into IndexedDB
const store = new SiloStore(pkg.manifest.id);
await store.open();
await store.importContent(pkg.content);

// Search
const results = await store.searchMemories("Florence");
console.log(results);

// Get all decisions
const decisions = await store.getMemoriesByType("decision");
console.log(decisions);

// Get entities linked to a memory
const entities = await store.getLinkedEntities("m_013");
console.log(entities);
```

## What It Demonstrates

1. **Unzip** the `.silo` package using JSZip
2. **Parse** `manifest.json` and `silo.json` with full TypeScript types
3. **Import** memories, entities, and links into IndexedDB
4. **Query** using keyword matching across memory content
5. **Traverse** the entity graph via memory-entity links

This is a reference implementation — not production code. A real app would add embedding-based semantic search (via a service like OpenAI embeddings) and richer query capabilities.
