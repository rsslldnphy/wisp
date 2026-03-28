import XCTest
@testable import Wisp

final class TextCleanupServiceTests: XCTestCase {

    private var service: TextCleanupService!

    override func setUp() {
        super.setUp()
        service = TextCleanupService()
    }

    func testCleanTextPassesThrough() async throws {
        let input = "Hello, world. How are you?"
        let result = try await service.cleanup(input)
        // Clean text should come back essentially unchanged
        XCTAssertTrue(result.contains("Hello"))
        XCTAssertTrue(result.contains("world"))
    }

    func testRemovesFillerWords() async throws {
        let input = "So um I was thinking uh that we should go"
        let result = try await service.cleanup(input)
        XCTAssertFalse(result.lowercased().contains(" um "))
        XCTAssertFalse(result.lowercased().contains(" uh "))
        XCTAssertTrue(result.lowercased().contains("thinking"))
        XCTAssertTrue(result.lowercased().contains("should go"))
    }

    func testPreservesMeaning() async throws {
        let input = "Please send the report to John and Mary."
        let result = try await service.cleanup(input)
        XCTAssertTrue(result.contains("John"))
        XCTAssertTrue(result.contains("Mary"))
        XCTAssertTrue(result.contains("report"))
    }

    func testHandlesEmptyString() async throws {
        let result = try await service.cleanup("")
        // Should return empty or the original
        XCTAssertTrue(result.count < 50, "Should not generate content from empty input")
    }
}
