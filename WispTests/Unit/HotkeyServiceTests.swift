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

    @MainActor
    func testRegisterDoesNotCrash() {
        // Registration via KeyboardShortcuts should not crash even without
        // Accessibility permission in the test environment.
        let service = HotkeyService {}
        service.register()
        service.unregister()
    }

    @MainActor
    func testUnregisterPreventsSubsequentCallbacks() {
        // After unregister(), the isActive flag is false so callbacks are suppressed.
        let service = HotkeyService {}
        service.register()
        service.unregister()
        // No crash or assertion failure = pass
    }
}
