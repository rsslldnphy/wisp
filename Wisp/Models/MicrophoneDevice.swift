import Foundation

struct MicrophoneDevice: Sendable, Identifiable, Equatable {
    var id: String { uid }
    let uid: String
    let displayName: String
    let isDefault: Bool

    static func == (lhs: MicrophoneDevice, rhs: MicrophoneDevice) -> Bool {
        lhs.uid == rhs.uid
    }
}
