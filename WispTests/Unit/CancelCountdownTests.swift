import XCTest
@testable import Wisp

/// Tests for the cancel-countdown state machine behavior.
///
/// AppDelegate's private coordinator methods (beginCancelCountdown,
/// restoreFromCancelling) cannot be called directly from tests. These tests
/// verify the AppState transitions those methods rely on, plus the
/// TranscriptionLogEntry semantics that record the paste/no-paste outcome.
final class CancelCountdownTests: XCTestCase {

    // MARK: - T006: beginCancelCountdown() state machine (≥ 0.5 s path)
    // Verifies: recording → cancelling is valid (the transition beginCancelCountdown uses)

    func testRecordingToCancellingTransitionIsValid() {
        // beginCancelCountdown() transitions recording → cancelling when audio ≥ 0.5 s
        let result = AppState.recording.transition(to: .cancelling)
        XCTAssertEqual(try result.get(), .cancelling,
                       "beginCancelCountdown() must be able to enter .cancelling from .recording")
    }

    func testCancellingToProcessingTransitionIsValid() {
        // Countdown expiry path: cancelling → processing (for silent transcription)
        let result = AppState.cancelling.transition(to: .processing)
        XCTAssertEqual(try result.get(), .processing,
                       "Countdown expiry must be able to transition .cancelling → .processing")
    }

    // MARK: - T007: beginCancelCountdown() short-recording path (< 0.5 s)
    // Verifies: the short-recording discard path goes cancelling → idle
    // (AppDelegate checks duration first; if too short it never enters .cancelling,
    //  but cancelling → idle is still valid for any unexpected short-path)

    func testCancellingToIdleTransitionIsValid() {
        // Short-recording discard path: cancelling → idle
        let result = AppState.cancelling.transition(to: .idle)
        XCTAssertEqual(try result.get(), .idle,
                       "Short-recording discard must be able to transition .cancelling → .idle")
    }

    func testShortRecordingNeverEntersCancellingViaStateCheck() {
        // The short-recording guard fires before the state transition to .cancelling.
        // This test documents the invariant: .recording can still transition directly
        // to .idle for the discard path (via cancelRecording / handleResult).
        // Since AppState does not have recording → idle, the discard is handled
        // by skipping the .cancelling entry entirely (guard in beginCancelCountdown).
        // We verify .recording → .idle is intentionally invalid.
        let result = AppState.recording.transition(to: .idle)
        if case .failure = result {
            // Correct: short-recording discard skips .cancelling and calls handleResult directly
        } else {
            XCTFail(".recording → .idle must remain invalid; short-recording discard bypasses state machine")
        }
    }

    // MARK: - T021 (US3): restoreFromCancelling() state machine
    // Verifies: cancelling → processing (second Escape restores paste path)

    func testRestoreFromCancellingTransitionIsValid() {
        // restoreFromCancelling() transitions cancelling → processing
        let result = AppState.cancelling.transition(to: .processing)
        XCTAssertEqual(try result.get(), .processing,
                       "restoreFromCancelling() must be able to transition .cancelling → .processing")
    }

    func testCancellingIsNotDirectlyReachableFromIdle() {
        // Prevents accidentally entering cancelling without a prior recording
        let result = AppState.idle.transition(to: .cancelling)
        if case .failure = result {
            // Correct: .cancelling is only reachable from .recording
        } else {
            XCTFail(".idle → .cancelling must be invalid")
        }
    }

    // MARK: - wasPasted semantics (US2 & US3)

    func testLogEntryDefaultsToWasPastedTrue() {
        let entry = TranscriptionLogEntry(text: "hello")
        XCTAssertTrue(entry.wasPasted,
                      "Entries from normal (pasted) recordings must have wasPasted = true by default")
    }

    func testLogEntryCanBeMarkedNotPasted() {
        let entry = TranscriptionLogEntry(text: "hello", wasPasted: false)
        XCTAssertFalse(entry.wasPasted,
                       "Entries from cancelled recordings must be stored with wasPasted = false")
    }

    func testLogEntryWasPastedSurvivesRoundTrip() throws {
        let entry = TranscriptionLogEntry(text: "test", wasPasted: false)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionLogEntry.self, from: data)
        XCTAssertFalse(decoded.wasPasted,
                       "wasPasted = false must survive JSON encode/decode round-trip")
    }

    func testLegacyLogEntryWithoutWasPastedKeyDecodesAsTrue() throws {
        // Legacy JSON entries written before this feature have no "wasPasted" key.
        // They must decode with wasPasted = true (assumed pasted).
        let legacyJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "text": "legacy entry",
            "timestamp": 0
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let entry = try JSONDecoder().decode(TranscriptionLogEntry.self, from: data)
        XCTAssertTrue(entry.wasPasted,
                      "Legacy log entries without wasPasted key must default to wasPasted = true")
    }
}
