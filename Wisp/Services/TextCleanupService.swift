import Foundation
import FoundationModels

final class TextCleanupService: @unchecked Sendable {

    private let session: LanguageModelSession

    init() {
        session = LanguageModelSession()
    }

    func cleanup(_ text: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        let prompt = """
            You are a dictation cleanup assistant. Clean up the following \
            transcribed speech. Rules:
            - Remove filler words (um, uh, like when used as filler, you know, etc.)
            - Fix punctuation and capitalization
            - Preserve the original meaning exactly — do NOT rephrase or rewrite
            - Do NOT add any commentary, just return the cleaned text
            - If the input is already clean, return it unchanged

            Transcribed text: \(text)
            """

        let response = try await session.respond(to: prompt)
        let cleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
}
