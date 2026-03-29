import Foundation

enum IndicatorState: Equatable, Sendable {
    case modelLoading
    case recording
    case cancelling
    case transcribing
    case error(String)
    case hidden

    static func from(_ appState: AppState) -> IndicatorState {
        switch appState {
        case .loading:
            return .modelLoading
        case .idle:
            return .hidden
        case .recording:
            return .recording
        case .cancelling:
            return .cancelling
        case .processing:
            return .transcribing
        }
    }
}
