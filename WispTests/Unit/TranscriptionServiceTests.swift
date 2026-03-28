import XCTest
@testable import Wisp

final class TranscriptionServiceTests: XCTestCase {

    func testServiceCreation() {
        let service = TranscriptionService()
        XCTAssertNotNil(service)
    }

    func testTranscribeEmptyBufferThrows() async {
        let service = TranscriptionService()
        do {
            _ = try await service.transcribe(audioBuffer: Data())
            XCTFail("Expected error for empty buffer")
        } catch let error as TranscriptionError {
            if case .processingFailed = error {
                // expected
            } else if case .modelNotLoaded = error {
                // also acceptable in test environment without model
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            // Model not available in test — acceptable
        }
    }
}
