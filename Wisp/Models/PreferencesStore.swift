import Foundation
import Observation

enum PreferencesError: Error, Equatable {
    case emptyPrompt
}

@MainActor
@Observable
final class PreferencesStore {

    static let defaultCleanupPrompt: String = """
        You are a dictation cleanup assistant. Clean up the following \
        transcribed speech. Rules:
        - Remove filler words (um, uh, like when used as filler, you know, etc.)
        - Fix punctuation and capitalization
        - Preserve the original meaning exactly — do NOT rephrase or rewrite
        - Do NOT add any commentary, just return the cleaned text
        - If the input is already clean, return it unchanged
        """

    private(set) var cleanupPrompt: String
    private(set) var selectedMicrophoneUID: String?

    private let defaults: UserDefaults

    private enum Keys {
        static let cleanupPrompt = "com.wisp.cleanupPrompt"
        static let selectedMicrophoneUID = "com.wisp.selectedMicrophoneUID"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.cleanupPrompt) ?? ""
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cleanupPrompt = trimmed.isEmpty ? Self.defaultCleanupPrompt : trimmed
        self.selectedMicrophoneUID = defaults.string(forKey: Keys.selectedMicrophoneUID)
    }

    // MARK: - Cleanup Prompt

    func setCleanupPrompt(_ prompt: String) throws {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PreferencesError.emptyPrompt }
        cleanupPrompt = trimmed
        defaults.set(trimmed, forKey: Keys.cleanupPrompt)
    }

    func resetCleanupPrompt() {
        cleanupPrompt = Self.defaultCleanupPrompt
        defaults.removeObject(forKey: Keys.cleanupPrompt)
    }

    // MARK: - Microphone

    func setMicrophoneUID(_ uid: String?) {
        selectedMicrophoneUID = uid
        if let uid {
            defaults.set(uid, forKey: Keys.selectedMicrophoneUID)
        } else {
            defaults.removeObject(forKey: Keys.selectedMicrophoneUID)
        }
    }

    func resetMicrophone() {
        setMicrophoneUID(nil)
    }
}
