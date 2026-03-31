import type { SiloMode, SiloConfig } from "./types.js";

/**
 * Returns the mode-specific system prompt for an LLM, matching the Swift
 * SiloModeEnforcer implementation.
 */
export function getModeSystemPrompt(
  mode: SiloMode,
  siloTitle: string
): string {
  switch (mode) {
    case "container":
      return [
        "=== SILO MODE: CONTAINER ===",
        `You are answering questions using the "${siloTitle}" silo.`,
        "You MUST answer using ONLY content from this silo.",
        "Do NOT use general world knowledge.",
        "Do NOT infer, extrapolate, or fabricate information that is not explicitly present.",
        "If the answer is not present in the silo content, respond clearly:",
        `"This information is not covered in the ${siloTitle} silo."`,
        "Every claim in your response must be traceable to specific silo content.",
      ].join("\n");

    case "augmented":
      return [
        "=== SILO MODE: AUGMENTED ===",
        `You are answering questions using the "${siloTitle}" silo.`,
        "The silo's content is your primary source of truth.",
        "The recipient's personal context (provided separately) may enrich your answers — for example, dietary preferences, interests, or constraints.",
        "Do NOT use general world knowledge to fill gaps.",
        'If you draw on the recipient\'s personal context, label it: "[from your context]".',
        "If information is not present in either the silo or personal context, say so explicitly.",
      ].join("\n");

    case "open":
      return [
        "=== SILO MODE: OPEN ===",
        `You are answering questions using the "${siloTitle}" silo as context.`,
        "The silo's content is your primary reference, but you may use your full capabilities.",
        "When your answer draws from the silo, note it.",
        "When your answer draws from general knowledge, note it.",
        "Prefer silo content over general knowledge when they overlap.",
      ].join("\n");
  }
}

const CITATION_INSTRUCTIONS = [
  "=== CITATION REQUIRED ===",
  "This silo requires citations. For each factual claim in your response,",
  "reference the source from the silo content that supports it.",
  "Use the format: [Source: memory title or description].",
].join("\n");

/**
 * Builds the full system context for querying a silo, combining mode
 * instructions, custom config, and optional personal context.
 * Matches the Swift SiloModeEnforcer.buildSystemContext method.
 */
export function buildModeContext(
  mode: SiloMode,
  siloTitle: string,
  config?: SiloConfig,
  personalContext?: string
): string {
  const parts: string[] = [];

  parts.push(getModeSystemPrompt(mode, siloTitle));

  if (config?.system_instructions) {
    parts.push(config.system_instructions);
  }

  if (config?.mode_instructions) {
    parts.push(config.mode_instructions);
  }

  if (
    (mode === "augmented" || mode === "open") &&
    personalContext
  ) {
    parts.push(`=== RECIPIENT PERSONAL CONTEXT ===\n${personalContext}`);
  }

  if (config?.citation_required) {
    parts.push(CITATION_INSTRUCTIONS);
  }

  return parts.join("\n\n");
}
