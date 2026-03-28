import AppKit
import XCTest
@testable import Wisp

@MainActor
final class PasteServiceTests: XCTestCase {

    func testServiceCreation() {
        let service = PasteService()
        XCTAssertNotNil(service)
    }

    func testPasteSetsClipboard() {
        let service = PasteService()
        let expectation = expectation(description: "Paste completes")

        service.paste(text: "Test text") { _ in
            let pasteboard = NSPasteboard.general
            let text = pasteboard.string(forType: .string)
            XCTAssertEqual(text, "Test text")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testTransientTypeIsSet() {
        let service = PasteService()
        let expectation = expectation(description: "Paste completes")

        service.paste(text: "Transient test") { _ in
            let pasteboard = NSPasteboard.general
            let transientData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
            )
            XCTAssertNotNil(transientData)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
}
