import AppKit
import XCTest
@testable import Wisp

@MainActor
final class MenuBarControllerTests: XCTestCase {

    func testIdleState() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = MenuBarController(statusItem: statusItem)
        controller.updateState(.idle)
        XCTAssertNotNil(statusItem.button?.image)
        XCTAssertEqual(
            statusItem.button?.image?.accessibilityDescription,
            "Wisp — Idle"
        )
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func testRecordingState() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = MenuBarController(statusItem: statusItem)
        controller.updateState(.recording)
        XCTAssertEqual(
            statusItem.button?.image?.accessibilityDescription,
            "Wisp — Recording"
        )
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func testProcessingState() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = MenuBarController(statusItem: statusItem)
        controller.updateState(.processing)
        XCTAssertEqual(
            statusItem.button?.image?.accessibilityDescription,
            "Wisp — Processing"
        )
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}
