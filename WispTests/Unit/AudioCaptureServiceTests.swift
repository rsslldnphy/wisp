import XCTest
@testable import Wisp

final class AudioCaptureServiceTests: XCTestCase {

    func testInitialBufferDurationIsZero() {
        let service = AudioCaptureService()
        XCTAssertEqual(service.currentBufferDuration, 0, accuracy: 0.01)
    }

    func testTargetSampleRate() {
        XCTAssertEqual(AudioCaptureService.targetSampleRate, 16000)
    }

    func testMaxDurationIsFiveMinutes() {
        XCTAssertEqual(AudioCaptureService.maxDurationSeconds, 300)
    }

    func testMinimumDurationIsHalfSecond() {
        XCTAssertEqual(AudioCaptureService.minimumDurationSeconds, 0.5)
    }

    func testStopWithoutStartReturnsNil() {
        let service = AudioCaptureService()
        let result = service.stopRecording()
        XCTAssertNil(result)
    }
}
