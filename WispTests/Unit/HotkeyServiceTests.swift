import XCTest
@testable import Wisp

final class HotkeyServiceTests: XCTestCase {

    @MainActor
    func testServiceCreation() {
        var callCount = 0
        let service = HotkeyService {
            callCount += 1
        }
        XCTAssertNotNil(service)
        XCTAssertEqual(callCount, 0)
    }

    @MainActor
    func testUnregisterDoesNotCrash() {
        let service = HotkeyService {}
        service.unregister()
    }
}
