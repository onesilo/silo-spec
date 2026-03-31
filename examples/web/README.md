# Web Example — @onesilo/silo-sdk

A minimal TypeScript demo showing the [@onesilo/silo-sdk](../../sdk/js/).

## Usage

```bash
cd examples/web
npm install
npm run build
npm start
```

## What It Demonstrates

- Creating a silo with the `SiloWriter` builder (facts, decisions, entities, config)
- Validating manifest and content with `validateManifest` / `validateContent`
- Generating mode system prompts with `getModeSystemPrompt`
- Building full context with personal lens via `buildModeContext`
- Serializing to JSON with `toJSON()`
