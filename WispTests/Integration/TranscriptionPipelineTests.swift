import XCTest
@testable import Wisp

@MainActor
final class TranscriptionPipelineTests: XCTestCase {

    private var preferences: PreferencesStore!
    private var service: TextCleanupService!

    override func setUp() {
        super.setUp()
        let testDefaults = UserDefaults(suiteName: "com.wisp.tests.\(UUID().uuidString)")!
        preferences = PreferencesStore(defaults: testDefaults)
        service = TextCleanupService(preferences: preferences)
    }

    func testCleanupRemovesFillers() async throws {
        let whisperOutput = "Um hello uh world. I think um we should go."
        let result = try await service.cleanup(whisperOutput)
        XCTAssertFalse(result.lowercased().contains(" um "))
        XCTAssertFalse(result.lowercased().contains(" uh "))
        XCTAssertTrue(result.lowercased().contains("hello"))
        XCTAssertTrue(result.lowercased().contains("world"))
    }

    func testCleanupPreservesSentenceStructure() async throws {
        let input = "This is a test. Another sentence here."
        let result = try await service.cleanup(input)
        XCTAssertTrue(result.contains("test"))
        XCTAssertTrue(result.contains("sentence"))
    }

    func testFixtureFilesExist() {
        let bundle = Bundle.module
        XCTAssertNotNil(
            bundle.url(forResource: "hello-world", withExtension: "wav"),
            "hello-world.wav fixture should exist"
        )
        XCTAssertNotNil(
            bundle.url(forResource: "silence", withExtension: "wav"),
            "silence.wav fixture should exist"
        )
        XCTAssertNotNil(
            bundle.url(forResource: "short-clip", withExtension: "wav"),
            "short-clip.wav fixture should exist"
        )
    }
}
