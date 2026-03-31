// Package I/O
export { openSiloPackage, createSiloPackage } from "./silo-package.js";

// IndexedDB store
export { SiloStore } from "./silo-store.js";

// Builder
export { SiloWriter } from "./silo-writer.js";
export type { SiloPackageData } from "./silo-writer.js";

// Mode prompts
export { getModeSystemPrompt, buildModeContext } from "./silo-mode.js";

// Validation
export {
  validateManifest,
  validateContent,
  validatePackage,
} from "./silo-validator.js";
export type { ValidationResult, ValidationIssue } from "./silo-validator.js";

// Types
export type {
  SiloMode,
  SiloManifest,
  SiloCreator,
  SiloSharing,
  SiloStats,
  MemoryType,
  SiloMemory,
  FactMetadata,
  DecisionMetadata,
  NarrativeMetadata,
  InsightMetadata,
  OpenItemMetadata,
  CustomMetadata,
  SiloEntity,
  SiloRelationship,
  SiloTopic,
  MemoryEntityLink,
  MemoryRefLink,
  SiloRef,
  RefDataSummary,
  SiloConfig,
  SiloContent,
  SiloPackage,
} from "./types.js";
