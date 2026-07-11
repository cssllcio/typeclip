import XCTest
import TypeclipCore
@testable import typeclip

final class CliParseTests: XCTestCase {

    func testDefaults() throws {
        let cmd = try Typeclip.parse([])
        XCTAssertEqual(cmd.delay, 5)
        XCTAssertEqual(cmd.wpm, 70)
        XCTAssertFalse(cmd.flat)
        XCTAssertEqual(cmd.typoRate, 0)
        XCTAssertNil(cmd.seed)
        XCTAssertEqual(cmd.newline, .shiftEnter)
        XCTAssertFalse(cmd.submit)
        XCTAssertNil(cmd.text)
        XCTAssertFalse(cmd.dryRun)
        XCTAssertFalse(cmd.yes)
        XCTAssertNil(cmd.app)
    }

    func testFullFlagSurface() throws {
        let cmd = try Typeclip.parse([
            "-d", "3", "--app", "Claude", "--wpm", "55", "--flat",
            "--typo-rate", "0.02", "--seed", "42", "--newline", "enter",
            "--submit", "--text", "hi", "--dry-run", "--yes",
        ])
        XCTAssertEqual(cmd.delay, 3)
        XCTAssertEqual(cmd.app, "Claude")
        XCTAssertEqual(cmd.wpm, 55)
        XCTAssertTrue(cmd.flat)
        XCTAssertEqual(cmd.typoRate, 0.02)
        XCTAssertEqual(cmd.seed, 42)
        XCTAssertEqual(cmd.newline, .enter)
        XCTAssertTrue(cmd.submit)
        XCTAssertEqual(cmd.text, "hi")
        XCTAssertTrue(cmd.dryRun)
        XCTAssertTrue(cmd.yes)
    }

    func testInvalidNewlineRejected() {
        XCTAssertThrowsError(try Typeclip.parse(["--newline", "bogus"]))
    }

    func testInvalidNumbersRejected() {
        XCTAssertThrowsError(try Typeclip.validated(["--wpm", "0"]))
        XCTAssertThrowsError(try Typeclip.validated(["--typo-rate", "1.5"]))
        XCTAssertThrowsError(try Typeclip.validated(["-d", "-1"]))
    }

    func testPreviewLine() {
        XCTAssertEqual(Typeclip.previewLine("ab\ncd"), "ab⏎cd")
        let long = String(repeating: "x", count: 100)
        XCTAssertEqual(Typeclip.previewLine(long).count, 60)
    }
}
