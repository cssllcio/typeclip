import XCTest
@testable import TypeclipCore

final class TextNormalizerTests: XCTestCase {

    func testCRLFAndCRBecomeLF() {
        XCTAssertEqual(TextNormalizer.normalize("a\r\nb\rc"), "a\nb\nc")
    }

    func testTrimsExactlyOneTrailingNewline() {
        // pbcopy from a shell pipeline almost always appends one \n; typing it
        // would add a stray blank line on camera.
        XCTAssertEqual(TextNormalizer.normalize("hello\n"), "hello")
        XCTAssertEqual(TextNormalizer.normalize("hello\n\n"), "hello\n")
    }

    func testInteriorNewlinesUntouched() {
        XCTAssertEqual(TextNormalizer.normalize("a\nb"), "a\nb")
    }

    func testEmptyStaysEmpty() {
        XCTAssertEqual(TextNormalizer.normalize(""), "")
    }

    func testNewlineModeRawValues() {
        XCTAssertEqual(NewlineMode(rawValue: "shift-enter"), .shiftEnter)
        XCTAssertEqual(NewlineMode(rawValue: "enter"), .enter)
        XCTAssertEqual(NewlineMode(rawValue: "strip"), .strip)
        XCTAssertNil(NewlineMode(rawValue: "bogus"))
    }
}
