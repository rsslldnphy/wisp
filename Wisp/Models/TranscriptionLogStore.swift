import Foundation

// Persists transcription history to:
// ~/Library/Application Support/Wisp/transcription-log.json

@MainActor
@Observable
final class TranscriptionLogStore {

    private(set) var entries: [TranscriptionLogEntry] = []
    private let url: URL

    static var storageURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("Wisp", isDirectory: true)
            .appendingPathComponent("transcription-log.json")
    }

    init(url: URL = TranscriptionLogStore.storageURL) {
        self.url = url
        self.entries = Self.load(from: url)
    }

    func update(id: UUID, text: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].text = text
        save()
    }

    func append(text: String, wasPasted: Bool = true) {
        let entry = TranscriptionLogEntry(text: text, wasPasted: wasPasted)
        entries.insert(entry, at: 0)
        if entries.count > 500 {
            entries.removeLast()
        }
        save()
    }

    // MARK: - Private

    private static func load(from url: URL) -> [TranscriptionLogEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let decoded = try? JSONDecoder().decode([TranscriptionLogEntry].self, from: data)
        else { return [] }
        return decoded
    }

    private func save() {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
