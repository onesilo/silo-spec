import Foundation

/// Generates mode-specific system prompts for LLM queries against a silo.
///
/// Mode enforcement is defense-in-depth:
/// 1. manifest.json declares the mode
/// 2. config.system_instructions carries silo-specific LLM instructions
/// 3. This service generates mode-specific enforcement prompts
/// 4. The reader app injects these into every query context
public enum SiloModeEnforcer {

    /// Generates the standard mode enforcement system prompt.
    public static func systemPrompt(for mode: SiloMode, siloTitle: String) -> String {
        switch mode {
        case .container:
            return """
            === SILO MODE: CONTAINER ===
            You are answering questions using the "\(siloTitle)" silo.
            You MUST answer using ONLY content from this silo.
            Do NOT use general world knowledge.
            Do NOT infer, extrapolate, or fabricate information that is not explicitly present.
            If the answer is not present in the silo content, respond clearly:
            "This information is not covered in the \(siloTitle) silo."
            Every claim in your response must be traceable to specific silo content.
            """

        case .augmented:
            return """
            === SILO MODE: AUGMENTED ===
            You are answering questions using the "\(siloTitle)" silo.
            The silo's content is your primary source of truth.
            The recipient's personal context (provided separately) may enrich your answers — for example, dietary preferences, interests, or constraints.
            Do NOT use general world knowledge to fill gaps.
            If you draw on the recipient's personal context, label it: "[from your context]".
            If information is not present in either the silo or personal context, say so explicitly.
            """

        case .open:
            return """
            === SILO MODE: OPEN ===
            You are answering questions using the "\(siloTitle)" silo as context.
            The silo's content is your primary reference, but you may use your full capabilities.
            When your answer draws from the silo, note it.
            When your answer draws from general knowledge, note it.
            Prefer silo content over general knowledge when they overlap.
            """
        }
    }

    /// Builds the full system context for querying a silo, combining mode enforcement,
    /// custom instructions, personal context, and citation requirements.
    public static func buildContext(
        mode: SiloMode,
        siloTitle: String,
        config: SiloConfig?,
        personalContext: String?
    ) -> String {
        var parts: [String] = []

        parts.append(systemPrompt(for: mode, siloTitle: siloTitle))

        if let custom = config?.systemInstructions, !custom.isEmpty {
            parts.append(custom)
        }

        if let modeCustom = config?.modeInstructions, !modeCustom.isEmpty {
            parts.append(modeCustom)
        }

        if mode == .augmented || mode == .open, let personal = personalContext, !personal.isEmpty {
            parts.append("=== RECIPIENT PERSONAL CONTEXT ===\n\(personal)")
        }

        if config?.citationRequired == true {
            parts.append(citationInstructions)
        }

        return parts.joined(separator: "\n\n")
    }

    private static let citationInstructions = """
    === CITATION REQUIRED ===
    This silo requires citations. For each factual claim in your response, reference the source from the silo content that supports it. Use the format: [Source: memory title or description].
    """
}
