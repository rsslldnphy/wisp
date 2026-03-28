import XCTest
@testable import Wisp

final class DictationSessionTests: XCTestCase {

    func testSessionCreation() {
        let session = DictationSession()
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
        XCTAssertNil(session.result)
    }

    func testSessionStop() {
        var session = DictationSession()
        let stopTime = Date().addingTimeInterval(3)
        session.stop(at: stopTime)
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endTime)
    }

    func testAudioDuration() {
        let start = Date()
        var session = DictationSession(startTime: start)
        let stopTime = start.addingTimeInterval(5.0)
        session.stop(at: stopTime)
        XCTAssertEqual(session.audioDuration, 5.0, accuracy: 0.01)
    }

    func testStopIsIdempotent() {
        var session = DictationSession()
        let firstStop = Date().addingTimeInterval(2)
        let secondStop = Date().addingTimeInterval(5)
        session.stop(at: firstStop)
        session.stop(at: secondStop)
        XCTAssertEqual(session.endTime, firstStop)
    }

    func testCompleteWithResult() {
        var session = DictationSession()
        session.stop()
        session.complete(with: .completed(text: "Hello"))
        if case .completed(let text) = session.result {
            XCTAssertEqual(text, "Hello")
        } else {
            XCTFail("Expected completed result")
        }
    }

    func testCompleteWithDiscard() {
        var session = DictationSession()
        session.stop()
        session.complete(with: .discarded(reason: .tooShort))
        if case .discarded(let reason) = session.result {
            XCTAssertEqual(reason, .tooShort)
        } else {
            XCTFail("Expected discarded result")
        }
    }
}
