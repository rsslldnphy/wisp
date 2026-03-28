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

    func testPreferredDeviceUIDDefaultsToNil() {
        let service = AudioCaptureService()
        XCTAssertNil(service.preferredDeviceUID)
    }

    func testPreferredDeviceUIDCanBeSet() {
        let service = AudioCaptureService()
        let uid = "AppleUSBAudioEngine:Apple Inc.:Test:001"
        service.preferredDeviceUID = uid
        XCTAssertEqual(service.preferredDeviceUID, uid)
    }

    func testPreferredDeviceUIDCanBeClearedToNil() {
        let service = AudioCaptureService()
        service.preferredDeviceUID = "SomeDevice"
        service.preferredDeviceUID = nil
        XCTAssertNil(service.preferredDeviceUID)
    }
}
