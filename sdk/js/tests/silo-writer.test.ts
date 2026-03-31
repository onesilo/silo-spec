import { describe, it, expect } from "vitest";
import { SiloWriter } from "../src/silo-writer.js";
import { validatePackage } from "../src/silo-validator.js";
import JSZip from "jszip";

describe("SiloWriter", () => {
  it("creates valid content with auto-generated IDs", () => {
    const writer = new SiloWriter("Test Silo", "container");
    writer
      .addFact("The sky is blue", { confidence: 1.0 })
      .addDecision("Use TypeScript", { status: "final" })
      .addNarrative("Once upon a time...", { title: "Intro" })
      .addInsight("Users prefer dark mode", { confidence: 0.8 })
      .addOpenItem("Decide on database", { priority: "high" })
      .addCustom("Custom data point", "recipe", { servings: 4 });

    const pkg = writer.build();

    expect(pkg.content.memories).toHaveLength(6);
    expect(pkg.content.memories[0].id).toBe("m_001");
    expect(pkg.content.memories[1].id).toBe("m_002");
    expect(pkg.content.memories[5].id).toBe("m_006");

    expect(pkg.content.memories[0].type).toBe("fact");
    expect(pkg.content.memories[0].metadata).toEqual({ confidence: 1.0 });
    expect(pkg.content.memories[5].type).toBe("custom");
    expect(pkg.content.memories[5].metadata).toEqual({
      custom_type: "recipe",
      data: { servings: 4 },
    });
  });

  it("auto-calculates stats in the manifest", () => {
    const writer = new SiloWriter("Stats Test", "open");
    writer
      .addFact("Fact 1")
      .addFact("Fact 2")
      .addEntity("Alice", "person")
      .addEntity("Acme", "company");

    const pkg = writer.build();

    expect(pkg.manifest.stats).toEqual({
      memory_count: 2,
      entity_count: 2,
      ref_count: 0,
      ref_size_bytes: 0,
    });
  });

  it("sets manifest metadata via fluent API", () => {
    const writer = new SiloWriter("Metadata Test", "augmented");
    writer
      .setDescription("A test silo")
      .setCreator("SDK Tests", "https://example.com")
      .setTags(["test", "demo"])
      .setConfig({ welcome_message: "Hello!" });

    const pkg = writer.build();

    expect(pkg.manifest.description).toBe("A test silo");
    expect(pkg.manifest.creator).toEqual({
      name: "SDK Tests",
      uri: "https://example.com",
    });
    expect(pkg.manifest.tags).toEqual(["test", "demo"]);
    expect(pkg.content.config.welcome_message).toBe("Hello!");
  });

  it("supports entities, relationships, and links", () => {
    const writer = new SiloWriter("Graph Test", "container");
    writer
      .addEntity("Alice", "person")
      .addEntity("Acme Corp", "company")
      .addRelationship("e_001", "e_002", "works_at")
      .addFact("Alice works at Acme")
      .linkMemoryToEntity("m_001", "e_001", "subject")
      .linkMemoryToEntity("m_001", "e_002", "mentioned");

    const pkg = writer.build();

    expect(pkg.content.entities).toHaveLength(2);
    expect(pkg.content.entities[0].id).toBe("e_001");
    expect(pkg.content.relationships).toHaveLength(1);
    expect(pkg.content.relationships[0].id).toBe("r_001");
    expect(pkg.content.memory_entity_links).toHaveLength(2);
  });

  it("produces valid output that passes validation", () => {
    const writer = new SiloWriter("Validation Test", "open");
    writer.addFact("Test fact").addEntity("TestEntity", "concept");

    const pkg = writer.build();
    const result = validatePackage({
      manifest: pkg.manifest,
      content: pkg.content,
      refFiles: new Map(),
    });

    expect(result.isValid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it("toJSON returns valid JSON strings", () => {
    const writer = new SiloWriter("JSON Test", "container");
    writer.addFact("Hello world");

    const pkg = writer.build();
    const json = pkg.toJSON();

    const manifest = JSON.parse(json.manifest);
    const content = JSON.parse(json.content);

    expect(manifest.title).toBe("JSON Test");
    expect(content.memories).toHaveLength(1);
  });

  it("toBlob produces a valid zip with manifest.json and silo.json", async () => {
    const writer = new SiloWriter("Blob Test", "open");
    writer.addFact("Zipped fact");

    const pkg = writer.build();
    const blob = await pkg.toBlob();

    expect(blob).toBeInstanceOf(Blob);
    expect(blob.size).toBeGreaterThan(0);

    // Node's JSZip doesn't support Blob directly — convert to ArrayBuffer
    const buffer = await blob.arrayBuffer();
    const zip = await JSZip.loadAsync(buffer);
    expect(zip.file("manifest.json")).not.toBeNull();
    expect(zip.file("silo.json")).not.toBeNull();

    const manifestText = await zip.file("manifest.json")!.async("text");
    const parsed = JSON.parse(manifestText);
    expect(parsed.title).toBe("Blob Test");
  });

  it("lastMemoryId and lastEntityId return most recent IDs", () => {
    const writer = new SiloWriter("ID Test", "container");
    writer.addFact("First").addFact("Second");
    expect(writer.lastMemoryId).toBe("m_002");

    writer.addEntity("Entity One", "thing").addEntity("Entity Two", "thing");
    expect(writer.lastEntityId).toBe("e_002");
  });

  it("setSubjectEntity is reflected in the manifest", () => {
    const writer = new SiloWriter("Subject Test", "container");
    writer.addEntity("Main Subject", "person").setSubjectEntity("e_001");

    const pkg = writer.build();
    expect(pkg.manifest.subject_entity_id).toBe("e_001");
  });
});
