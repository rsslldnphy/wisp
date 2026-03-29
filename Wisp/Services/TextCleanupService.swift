import Foundation
import FoundationModels

final class TextCleanupService: @unchecked Sendable {

    private let session: LanguageModelSession
    private let preferences: PreferencesStore

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        session = LanguageModelSession()
    }

    func cleanup(_ text: String, wordHints: [String] = []) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        // Read the prompt at call time so changes take effect without restarting the service.
        let basePrompt = await MainActor.run { preferences.cleanupPrompt }
        var prompt = basePrompt
        if !wordHints.isEmpty {
            prompt += "\nUse these exact spellings when they appear: \(wordHints.joined(separator: ", "))"
        }
        prompt += "\n\nTranscribed text: \(text)"

        let response = try await session.respond(to: prompt)
        let cleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
}
