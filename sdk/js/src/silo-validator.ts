import type {
  SiloManifest,
  SiloContent,
  SiloPackage,
} from "./types.js";

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
}

export interface ValidationIssue {
  field: string;
  message: string;
}

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------

const VALID_MODES = new Set(["container", "augmented", "open"]);
const VALID_MEMORY_TYPES = new Set([
  "fact",
  "decision",
  "narrative",
  "insight",
  "open_item",
  "custom",
]);

export function validateManifest(manifest: SiloManifest): ValidationResult {
  const errors: ValidationIssue[] = [];
  const warnings: ValidationIssue[] = [];

  requireString(manifest, "spec", errors);
  requireString(manifest, "min_reader", errors);
  requireString(manifest, "id", errors);
  requireString(manifest, "title", errors);
  requireISODate(manifest, "created_at", errors);
  requireISODate(manifest, "updated_at", errors);

  if (!manifest.mode) {
    errors.push({ field: "mode", message: "mode is required" });
  } else if (!VALID_MODES.has(manifest.mode)) {
    errors.push({
      field: "mode",
      message: `mode must be one of: container, augmented, open — got "${manifest.mode}"`,
    });
  }

  if (manifest.stats) {
    if (
      manifest.stats.memory_count !== undefined &&
      manifest.stats.memory_count < 0
    ) {
      warnings.push({
        field: "stats.memory_count",
        message: "memory_count should not be negative",
      });
    }
  }

  return { isValid: errors.length === 0, errors, warnings };
}

export function validateContent(content: SiloContent): ValidationResult {
  const errors: ValidationIssue[] = [];
  const warnings: ValidationIssue[] = [];

  if (!Array.isArray(content.memories)) {
    errors.push({ field: "memories", message: "memories must be an array" });
  } else {
    validateMemories(content.memories, errors);
  }

  if (!Array.isArray(content.entities)) {
    errors.push({ field: "entities", message: "entities must be an array" });
  } else {
    validateEntities(content.entities, errors);
  }

  if (!Array.isArray(content.relationships)) {
    errors.push({
      field: "relationships",
      message: "relationships must be an array",
    });
  }

  if (!Array.isArray(content.topics)) {
    errors.push({ field: "topics", message: "topics must be an array" });
  }

  if (!Array.isArray(content.memory_entity_links)) {
    errors.push({
      field: "memory_entity_links",
      message: "memory_entity_links must be an array",
    });
  }

  if (!Array.isArray(content.memory_ref_links)) {
    errors.push({
      field: "memory_ref_links",
      message: "memory_ref_links must be an array",
    });
  }

  if (!Array.isArray(content.refs)) {
    errors.push({ field: "refs", message: "refs must be an array" });
  }

  if (content.config === undefined || content.config === null) {
    errors.push({ field: "config", message: "config object is required" });
  }

  // Cross-reference checks (warnings only — broken links are not fatal)
  if (errors.length === 0) {
    checkBrokenLinks(content, warnings);
  }

  return { isValid: errors.length === 0, errors, warnings };
}

export function validatePackage(pkg: SiloPackage): ValidationResult {
  const manifestResult = validateManifest(pkg.manifest);
  const contentResult = validateContent(pkg.content);

  const errors = [...manifestResult.errors, ...contentResult.errors];
  const warnings = [...manifestResult.warnings, ...contentResult.warnings];

  // Cross-check manifest stats vs actual content
  if (pkg.manifest.stats) {
    const { stats } = pkg.manifest;
    if (
      stats.memory_count !== undefined &&
      stats.memory_count !== pkg.content.memories.length
    ) {
      warnings.push({
        field: "stats.memory_count",
        message: `manifest declares ${stats.memory_count} memories but content has ${pkg.content.memories.length}`,
      });
    }
    if (
      stats.entity_count !== undefined &&
      stats.entity_count !== pkg.content.entities.length
    ) {
      warnings.push({
        field: "stats.entity_count",
        message: `manifest declares ${stats.entity_count} entities but content has ${pkg.content.entities.length}`,
      });
    }
  }

  // Check subject_entity_id references an actual entity
  if (pkg.manifest.subject_entity_id) {
    const entityIds = new Set(pkg.content.entities.map((e) => e.id));
    if (!entityIds.has(pkg.manifest.subject_entity_id)) {
      warnings.push({
        field: "subject_entity_id",
        message: `subject_entity_id "${pkg.manifest.subject_entity_id}" does not match any entity`,
      });
    }
  }

  return { isValid: errors.length === 0, errors, warnings };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function validateMemories(
  memories: SiloContent["memories"],
  errors: ValidationIssue[]
): void {
  for (let i = 0; i < memories.length; i++) {
    const m = memories[i];
    const prefix = `memories[${i}]`;
    if (!m.id) errors.push({ field: `${prefix}.id`, message: "id is required" });
    if (!m.content)
      errors.push({ field: `${prefix}.content`, message: "content is required" });
    if (!m.type) {
      errors.push({ field: `${prefix}.type`, message: "type is required" });
    } else if (!VALID_MEMORY_TYPES.has(m.type)) {
      errors.push({
        field: `${prefix}.type`,
        message: `unknown memory type "${m.type}"`,
      });
    }
  }
}

function validateEntities(
  entities: SiloContent["entities"],
  errors: ValidationIssue[]
): void {
  for (let i = 0; i < entities.length; i++) {
    const e = entities[i];
    const prefix = `entities[${i}]`;
    if (!e.id) errors.push({ field: `${prefix}.id`, message: "id is required" });
    if (!e.name)
      errors.push({ field: `${prefix}.name`, message: "name is required" });
    if (!e.type)
      errors.push({ field: `${prefix}.type`, message: "type is required" });
  }
}

function checkBrokenLinks(
  content: SiloContent,
  warnings: ValidationIssue[]
): void {
  const memoryIds = new Set(content.memories.map((m) => m.id));
  const entityIds = new Set(content.entities.map((e) => e.id));
  const refIds = new Set(content.refs.map((r) => r.id));

  for (const link of content.memory_entity_links) {
    if (!memoryIds.has(link.memory_id)) {
      warnings.push({
        field: "memory_entity_links",
        message: `memory_id "${link.memory_id}" does not match any memory`,
      });
    }
    if (!entityIds.has(link.entity_id)) {
      warnings.push({
        field: "memory_entity_links",
        message: `entity_id "${link.entity_id}" does not match any entity`,
      });
    }
  }

  for (const link of content.memory_ref_links) {
    if (!memoryIds.has(link.memory_id)) {
      warnings.push({
        field: "memory_ref_links",
        message: `memory_id "${link.memory_id}" does not match any memory`,
      });
    }
    if (!refIds.has(link.ref_id)) {
      warnings.push({
        field: "memory_ref_links",
        message: `ref_id "${link.ref_id}" does not match any ref`,
      });
    }
  }

  for (const rel of content.relationships) {
    if (!entityIds.has(rel.source_entity_id)) {
      warnings.push({
        field: "relationships",
        message: `source_entity_id "${rel.source_entity_id}" does not match any entity`,
      });
    }
    if (!entityIds.has(rel.target_entity_id)) {
      warnings.push({
        field: "relationships",
        message: `target_entity_id "${rel.target_entity_id}" does not match any entity`,
      });
    }
  }
}

function requireString(
  obj: object,
  field: string,
  errors: ValidationIssue[]
): void {
  const val = (obj as Record<string, unknown>)[field];
  if (val === undefined || val === null || val === "") {
    errors.push({ field, message: `${field} is required` });
  }
}

function requireISODate(
  obj: object,
  field: string,
  errors: ValidationIssue[]
): void {
  const val = (obj as Record<string, unknown>)[field];
  if (val === undefined || val === null || val === "") {
    errors.push({ field, message: `${field} is required` });
  } else if (typeof val === "string" && isNaN(Date.parse(val))) {
    errors.push({ field, message: `${field} must be a valid ISO 8601 date` });
  }
}
