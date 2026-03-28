import XCTest
@testable import Wisp

@MainActor
final class TranscriptionLogStoreTests: XCTestCase {

    private var testURL: URL!

    override func setUp() {
        super.setUp()
        testURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("wisp-test-log-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        testURL = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testAppend_addsEntry() {
        let store = TranscriptionLogStore(url: testURL)
        XCTAssertEqual(store.entries.count, 0)
        store.append(text: "Hello world")
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].text, "Hello world")
    }

    func testAppend_capsAt500_dropsOldest() {
        let store = TranscriptionLogStore(url: testURL)
        for i in 0..<500 {
            store.append(text: "Entry \(i)")
        }
        XCTAssertEqual(store.entries.count, 500)
        // Adding one more should drop the oldest entry
        store.append(text: "Entry 500")
        XCTAssertEqual(store.entries.count, 500)
        // Entries are stored newest-first; oldest (Entry 0) should be gone
        XCTAssertFalse(store.entries.contains(where: { $0.text == "Entry 0" }))
        XCTAssertTrue(store.entries.contains(where: { $0.text == "Entry 500" }))
    }

    func testPersistence_survivesReinit() {
        let store1 = TranscriptionLogStore(url: testURL)
        store1.append(text: "Persisted entry")

        // Create a new store pointing at the same file
        let store2 = TranscriptionLogStore(url: testURL)
        XCTAssertEqual(store2.entries.count, 1)
        XCTAssertEqual(store2.entries[0].text, "Persisted entry")
    }

    func testCorruptFile_startsEmpty() throws {
        // Write corrupt JSON to the file
        let corrupt = Data("not valid json {{{{".utf8)
        try corrupt.write(to: testURL)

        let store = TranscriptionLogStore(url: testURL)
        XCTAssertEqual(store.entries.count, 0)
    }
}
