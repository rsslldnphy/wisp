import Foundation

struct TranscriptionLogEntry: Codable, Identifiable, Sendable {
    let id: UUID
    var text: String
    let timestamp: Date
    let wasPasted: Bool

    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), wasPasted: Bool = true) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.wasPasted = wasPasted
    }

    // Custom decoder for backward compatibility: existing log entries that have no
    // "wasPasted" key are treated as pasted (the only outcome that existed before
    // this feature was added).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        wasPasted = try container.decodeIfPresent(Bool.self, forKey: .wasPasted) ?? true
    }
}
