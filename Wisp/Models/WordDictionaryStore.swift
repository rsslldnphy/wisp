import Foundation

@MainActor
@Observable
final class WordDictionaryStore {

    private(set) var words: [String] = []

    private let defaults: UserDefaults
    private let key = "com.wisp.wordDictionary"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.words = defaults.stringArray(forKey: key) ?? []
    }

    // MARK: - Mutation

    func add(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !contains(trimmed) else { return }
        words.append(trimmed)
        persist()
    }

    func update(at index: Int, word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard words.indices.contains(index) else { return }
        words[index] = trimmed
        persist()
    }

    func remove(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
        persist()
    }

    func remove(_ word: String) {
        guard let index = words.firstIndex(where: {
            $0.caseInsensitiveCompare(word) == .orderedSame
        }) else { return }
        words.remove(at: index)
        persist()
    }

    // MARK: - Query

    func contains(_ word: String) -> Bool {
        words.contains { $0.caseInsensitiveCompare(word) == .orderedSame }
    }

    // MARK: - Word Extraction

    /// Returns words present in `newText` but absent (case-insensitive) from `oldText`.
    /// Strips leading/trailing punctuation from each token before comparison.
    nonisolated static func extractNewWords(from oldText: String, to newText: String) -> [String] {
        let oldTokens = Set(
            tokenise(oldText).map { stripped($0).lowercased() }
        )
        var seen = Set<String>()
        var result: [String] = []
        for token in tokenise(newText) {
            let key = stripped(token).lowercased()
            guard !key.isEmpty, !oldTokens.contains(key), !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(stripped(token))
        }
        return result
    }

    // MARK: - Private

    private func persist() {
        defaults.set(words, forKey: key)
    }

    nonisolated private static func tokenise(_ text: String) -> [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    nonisolated private static func stripped(_ token: String) -> String {
        token.trimmingCharacters(in: .punctuationCharacters)
    }
}
