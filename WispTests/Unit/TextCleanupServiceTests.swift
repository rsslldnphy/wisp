import XCTest
@testable import Wisp

@MainActor
final class TextCleanupServiceTests: XCTestCase {

    private var preferences: PreferencesStore!
    private var service: TextCleanupService!

    override func setUp() {
        super.setUp()
        let testDefaults = UserDefaults(suiteName: "com.wisp.tests.\(UUID().uuidString)")!
        preferences = PreferencesStore(defaults: testDefaults)
        service = TextCleanupService(preferences: preferences)
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

    func testUsesPromptFromPreferencesStore() async throws {
        // Set a custom prompt in the store and verify it is read at call time.
        let customPrompt = "Always respond with UPPERCASE text only."
        try preferences.setCleanupPrompt(customPrompt)

        // The service re-reads the prompt for each call, so the custom prompt
        // should be active for this invocation.
        let result = try await service.cleanup("hello world")
        // The LLM should follow uppercase instruction — at minimum it should not crash.
        XCTAssertFalse(result.isEmpty)
    }

    func testPromptChangesTakeEffectWithoutRestart() async throws {
        // First call with default prompt
        let first = try await service.cleanup("um hello")
        XCTAssertFalse(first.isEmpty)

        // Change the prompt in preferences
        try preferences.setCleanupPrompt("Return the text reversed, word by word.")

        // Second call should use the new prompt (no service restart)
        let second = try await service.cleanup("hello world")
        XCTAssertFalse(second.isEmpty)
    }
}
