import Foundation
import FoundationModels

final class TextCleanupService: @unchecked Sendable {

    private let session: LanguageModelSession
    private let preferences: PreferencesStore

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        session = LanguageModelSession()
    }

    func cleanup(_ text: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        // Read the prompt at call time so changes take effect without restarting the service.
        let basePrompt = await MainActor.run { preferences.cleanupPrompt }
        let prompt = basePrompt + "\n\nTranscribed text: \(text)"

        let response = try await session.respond(to: prompt)
        let cleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
}
