import XCTest
@testable import Wisp

final class DictationFlowTests: XCTestCase {

    func testFullStateTransitionCycle() {
        var state = AppState.idle

        // idle → recording
        if case .success(let newState) = state.transition(to: .recording) {
            state = newState
        }
        XCTAssertEqual(state, .recording)

        // recording → processing
        if case .success(let newState) = state.transition(to: .processing) {
            state = newState
        }
        XCTAssertEqual(state, .processing)

        // processing → idle
        if case .success(let newState) = state.transition(to: .idle) {
            state = newState
        }
        XCTAssertEqual(state, .idle)
    }

    func testSessionLifecycleWithCompletedResult() {
        var session = DictationSession()
        XCTAssertTrue(session.isActive)

        session.stop()
        XCTAssertFalse(session.isActive)
        XCTAssertTrue(session.audioDuration >= 0)

        session.complete(with: .completed(text: "Hello world."))
        if case .completed(let text) = session.result {
            XCTAssertEqual(text, "Hello world.")
        } else {
            XCTFail("Expected completed result")
        }
    }

    func testSessionLifecycleWithError() {
        var session = DictationSession()
        session.stop()
        session.complete(with: .failed(error: .microphoneUnavailable))

        if case .failed(let error) = session.result {
            XCTAssertEqual(error, .microphoneUnavailable)
        } else {
            XCTFail("Expected failed result")
        }
    }

    func testHotkeyDuringProcessingIsIgnored() {
        let state = AppState.processing
        let result = state.transition(to: .recording)
        if case .failure = result {
            // Expected: processing → recording is invalid
        } else {
            XCTFail("Hotkey during processing should be ignored")
        }
    }
}
