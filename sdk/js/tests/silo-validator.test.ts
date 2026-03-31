import { describe, it, expect } from "vitest";
import {
  validateManifest,
  validateContent,
  validatePackage,
} from "../src/silo-validator.js";
import type {
  SiloManifest,
  SiloContent,
  SiloPackage,
} from "../src/types.js";

function validManifest(overrides?: Partial<SiloManifest>): SiloManifest {
  return {
    spec: "0.1.0",
    min_reader: "0.1.0",
    id: "test-id",
    title: "Test Silo",
    created_at: "2025-01-01T00:00:00.000Z",
    updated_at: "2025-01-01T00:00:00.000Z",
    mode: "container",
    ...overrides,
  };
}

function validContent(overrides?: Partial<SiloContent>): SiloContent {
  return {
    memories: [
      {
        id: "m_001",
        type: "fact",
        content: "Test fact",
        created_at: "2025-01-01T00:00:00.000Z",
        updated_at: "2025-01-01T00:00:00.000Z",
      },
    ],
    entities: [
      {
        id: "e_001",
        name: "Test Entity",
        type: "concept",
        created_at: "2025-01-01T00:00:00.000Z",
        updated_at: "2025-01-01T00:00:00.000Z",
      },
    ],
    relationships: [],
    topics: [],
    memory_entity_links: [],
    memory_ref_links: [],
    refs: [],
    config: {},
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// validateManifest
// ---------------------------------------------------------------------------

describe("validateManifest", () => {
  it("passes for a valid manifest", () => {
    const result = validateManifest(validManifest());
    expect(result.isValid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it("fails when required string fields are missing", () => {
    const result = validateManifest(
      validManifest({ id: "", title: "" } as unknown as Partial<SiloManifest>)
    );
    expect(result.isValid).toBe(false);
    expect(result.errors.some((e) => e.field === "id")).toBe(true);
    expect(result.errors.some((e) => e.field === "title")).toBe(true);
  });

  it("fails for an invalid mode", () => {
    const result = validateManifest(
      validManifest({ mode: "invalid" as SiloManifest["mode"] })
    );
    expect(result.isValid).toBe(false);
    expect(result.errors[0].field).toBe("mode");
  });

  it("fails when dates are missing", () => {
    const result = validateManifest(
      validManifest({ created_at: "", updated_at: "" })
    );
    expect(result.isValid).toBe(false);
    expect(result.errors.some((e) => e.field === "created_at")).toBe(true);
  });

  it("warns on negative memory_count in stats", () => {
    const result = validateManifest(
      validManifest({ stats: { memory_count: -1 } })
    );
    expect(result.isValid).toBe(true);
    expect(result.warnings.some((w) => w.field === "stats.memory_count")).toBe(
      true
    );
  });
});

// ---------------------------------------------------------------------------
// validateContent
// ---------------------------------------------------------------------------

describe("validateContent", () => {
  it("passes for valid content", () => {
    const result = validateContent(validContent());
    expect(result.isValid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it("fails when memories is not an array", () => {
    const result = validateContent(
      validContent({ memories: "bad" as unknown as SiloContent["memories"] })
    );
    expect(result.isValid).toBe(false);
    expect(result.errors[0].field).toBe("memories");
  });

  it("fails when a memory is missing required fields", () => {
    const result = validateContent(
      validContent({
        memories: [
          {
            id: "",
            type: "fact",
            content: "",
            created_at: "2025-01-01T00:00:00.000Z",
            updated_at: "2025-01-01T00:00:00.000Z",
          },
        ],
      })
    );
    expect(result.isValid).toBe(false);
    expect(result.errors.some((e) => e.field === "memories[0].id")).toBe(true);
    expect(result.errors.some((e) => e.field === "memories[0].content")).toBe(
      true
    );
  });

  it("fails when config is missing", () => {
    const result = validateContent(
      validContent({ config: null as unknown as SiloContent["config"] })
    );
    expect(result.isValid).toBe(false);
    expect(result.errors.some((e) => e.field === "config")).toBe(true);
  });

  it("warns on broken memory_entity_links", () => {
    const result = validateContent(
      validContent({
        memory_entity_links: [
          { memory_id: "m_nonexistent", entity_id: "e_nonexistent" },
        ],
      })
    );
    expect(result.isValid).toBe(true);
    expect(result.warnings.length).toBeGreaterThanOrEqual(2);
    expect(
      result.warnings.some((w) => w.message.includes("m_nonexistent"))
    ).toBe(true);
    expect(
      result.warnings.some((w) => w.message.includes("e_nonexistent"))
    ).toBe(true);
  });

  it("warns on broken memory_ref_links", () => {
    const result = validateContent(
      validContent({
        memory_ref_links: [
          { memory_id: "m_001", ref_id: "ref_nonexistent" },
        ],
      })
    );
    expect(result.isValid).toBe(true);
    expect(
      result.warnings.some((w) => w.message.includes("ref_nonexistent"))
    ).toBe(true);
  });

  it("warns on broken relationship entity references", () => {
    const result = validateContent(
      validContent({
        relationships: [
          {
            id: "r_001",
            source_entity_id: "e_missing_src",
            target_entity_id: "e_missing_tgt",
            type: "related_to",
            created_at: "2025-01-01T00:00:00.000Z",
          },
        ],
      })
    );
    expect(result.isValid).toBe(true);
    expect(result.warnings.length).toBeGreaterThanOrEqual(2);
  });
});

// ---------------------------------------------------------------------------
// validatePackage
// ---------------------------------------------------------------------------

describe("validatePackage", () => {
  it("passes for a fully valid package", () => {
    const pkg: SiloPackage = {
      manifest: validManifest({
        stats: { memory_count: 1, entity_count: 1 },
      }),
      content: validContent(),
      refFiles: new Map(),
    };

    const result = validatePackage(pkg);
    expect(result.isValid).toBe(true);
    expect(result.errors).toHaveLength(0);
    expect(result.warnings).toHaveLength(0);
  });

  it("warns when manifest stats don't match content", () => {
    const pkg: SiloPackage = {
      manifest: validManifest({
        stats: { memory_count: 99, entity_count: 42 },
      }),
      content: validContent(),
      refFiles: new Map(),
    };

    const result = validatePackage(pkg);
    expect(result.isValid).toBe(true);
    expect(
      result.warnings.some((w) => w.field === "stats.memory_count")
    ).toBe(true);
    expect(
      result.warnings.some((w) => w.field === "stats.entity_count")
    ).toBe(true);
  });

  it("warns when subject_entity_id references nonexistent entity", () => {
    const pkg: SiloPackage = {
      manifest: validManifest({ subject_entity_id: "e_nonexistent" }),
      content: validContent(),
      refFiles: new Map(),
    };

    const result = validatePackage(pkg);
    expect(result.isValid).toBe(true);
    expect(
      result.warnings.some((w) => w.field === "subject_entity_id")
    ).toBe(true);
  });

  it("collects errors from both manifest and content", () => {
    const pkg: SiloPackage = {
      manifest: validManifest({ id: "" }),
      content: validContent({
        memories: "bad" as unknown as SiloContent["memories"],
      }),
      refFiles: new Map(),
    };

    const result = validatePackage(pkg);
    expect(result.isValid).toBe(false);
    expect(result.errors.length).toBeGreaterThanOrEqual(2);
  });
});
