import {
  SiloWriter,
  validateContent,
  validateManifest,
  getModeSystemPrompt,
  buildModeContext,
} from "@onesilo/silo-sdk";

// Create a silo using the builder
const silo = new SiloWriter("Italy Trip — June 2026", "augmented")
  .setDescription("Two-week trip through Rome, Florence, and the Amalfi Coast.")
  .setCreator("Demo Script", "https://onesilo.com")
  .setTags(["travel", "italy"])
  .addFact("Trip dates: June 12–22, 2026", { key: "dates", confidence: 1.0 })
  .addFact("Budget: $5,000 per person", { key: "budget", confidence: 1.0 })
  .addDecision("Chose Ravello over Positano for the coast", {
    title: "Ravello over Positano",
    alternatives_considered: ["Positano", "Praiano"],
    confidence: 1.0,
    status: "final",
  })
  .addNarrative(
    "Rome — June 12–15. Airbnb in Trastevere. Day 1: recovery. Day 2: Colosseum. Day 3: Vatican.",
    { title: "Rome Itinerary", topic: "rome", section_order: 1 }
  )
  .addInsight("The trip prioritizes local immersion over tourist attractions.", {
    title: "Local immersion focus",
    confidence: 0.85,
  })
  .addOpenItem("Book Rome to Florence train tickets", {
    priority: "high",
    status: "open",
  })
  .addEntity("Trastevere Airbnb", "place", { city: "Rome", nights: 3 })
  .addEntity("Marco", "person", { role: "Rome Airbnb host" })
  .setConfig({
    welcome_summary: "Two-week Italy trip covering Rome, Florence, and the Amalfi Coast.",
    suggested_prompts: [
      "What's the plan for Florence?",
      "Where should we eat in Rome?",
      "Why did we skip Venice?",
    ],
  })
  .build();

// Inspect the result
console.log("=== Manifest ===");
console.log(`Title: ${silo.manifest.title}`);
console.log(`Mode:  ${silo.manifest.mode}`);
console.log(`Memories: ${silo.manifest.stats?.memory_count}`);
console.log(`Entities: ${silo.manifest.stats?.entity_count}`);
console.log();

// Validate
const manifestResult = validateManifest(silo.manifest);
const contentResult = validateContent(silo.content);
console.log("=== Validation ===");
console.log(`Manifest valid: ${manifestResult.isValid}`);
console.log(`Content valid:  ${contentResult.isValid}`);
if (manifestResult.errors.length) {
  console.log("Manifest errors:", manifestResult.errors);
}
if (contentResult.warnings.length) {
  console.log("Content warnings:", contentResult.warnings);
}
console.log();

// Mode enforcement
console.log("=== Mode System Prompt ===");
console.log(getModeSystemPrompt("augmented", "Italy Trip"));
console.log();

// Full context with personal lens
const context = buildModeContext("augmented", "Italy Trip", silo.content.config, "User is gluten-free and prefers local restaurants");
console.log("=== Full Context (truncated) ===");
console.log(context.substring(0, 500) + "...");
console.log();

// JSON output
const json = silo.toJSON();
console.log("=== JSON Sizes ===");
console.log(`manifest.json: ${json.manifest.length} bytes`);
console.log(`silo.json:     ${json.content.length} bytes`);
