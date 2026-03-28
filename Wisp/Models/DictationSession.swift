import Foundation

struct DictationSession: Sendable {
    let id: UUID
    let startTime: Date
    private(set) var endTime: Date?
    private(set) var result: TranscriptionResult?

    var audioDuration: TimeInterval {
        guard let endTime else { return Date().timeIntervalSince(startTime) }
        return endTime.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        endTime == nil
    }

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
    }

    mutating func stop(at time: Date = Date()) {
        guard endTime == nil else { return }
        endTime = time
    }

    mutating func complete(with result: TranscriptionResult) {
        self.result = result
    }
}
