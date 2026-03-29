import XCTest
@testable import Wisp

final class WordExtractionTests: XCTestCase {

    // MARK: - Basic extraction

    func testExtract_newWordDetected() {
        let result = WordDictionaryStore.extractNewWords(from: "hello world", to: "hello SwiftUI")
        XCTAssertEqual(result, ["SwiftUI"])
    }

    func testExtract_unchangedWordsNotReturned() {
        let result = WordDictionaryStore.extractNewWords(from: "hello world", to: "hello world")
        XCTAssertTrue(result.isEmpty)
    }

    func testExtract_allNewWords() {
        let result = WordDictionaryStore.extractNewWords(from: "foo", to: "bar baz")
        XCTAssertEqual(Set(result), Set(["bar", "baz"]))
    }

    func testExtract_emptyOldText() {
        let result = WordDictionaryStore.extractNewWords(from: "", to: "WhisperKit")
        XCTAssertEqual(result, ["WhisperKit"])
    }

    func testExtract_emptyNewText() {
        let result = WordDictionaryStore.extractNewWords(from: "hello", to: "")
        XCTAssertTrue(result.isEmpty)
    }

    func testExtract_bothEmpty() {
        let result = WordDictionaryStore.extractNewWords(from: "", to: "")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Punctuation stripping

    func testExtract_punctuationWrappedWordStripped() {
        let result = WordDictionaryStore.extractNewWords(from: "hello", to: "hello, SwiftUI.")
        XCTAssertEqual(result, ["SwiftUI"])
    }

    func testExtract_punctuationOnlyTokenIgnored() {
        let result = WordDictionaryStore.extractNewWords(from: "hello", to: "hello ...")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Case-insensitive comparison

    func testExtract_caseInsensitiveComparison_sameWordNotReturned() {
        let result = WordDictionaryStore.extractNewWords(from: "Hello", to: "hello")
        XCTAssertTrue(result.isEmpty)
    }

    func testExtract_preservesOriginalCasing() {
        let result = WordDictionaryStore.extractNewWords(from: "ui", to: "SwiftUI")
        XCTAssertEqual(result, ["SwiftUI"])
    }

    // MARK: - Deduplication

    func testExtract_deduplicatesNewWords() {
        let result = WordDictionaryStore.extractNewWords(from: "", to: "Wisp Wisp wisp")
        XCTAssertEqual(result.count, 1)
    }

    func testExtract_preservesFirstOccurrence() {
        let result = WordDictionaryStore.extractNewWords(from: "", to: "SwiftUI swiftui")
        XCTAssertEqual(result, ["SwiftUI"])
    }

    // MARK: - Whitespace handling

    func testExtract_multipleSpacesHandled() {
        let result = WordDictionaryStore.extractNewWords(from: "old", to: "new  word")
        XCTAssertEqual(Set(result), Set(["new", "word"]))
    }

    func testExtract_newlinesSeparateTokens() {
        let result = WordDictionaryStore.extractNewWords(from: "", to: "line1\nline2")
        XCTAssertEqual(Set(result), Set(["line1", "line2"]))
    }
}
