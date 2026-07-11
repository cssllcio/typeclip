import XCTest
@testable import TypeclipCore

final class PlatformTests: XCTestCase {

    func testLiteralSourceNormalizes() throws {
        XCTAssertEqual(try TextSource.literal("hi\r\nthere\n").resolve(), "hi\nthere")
    }

    func testEmptyLiteralThrows() {
        XCTAssertThrowsError(try TextSource.literal("").resolve()) { error in
            guard case TextSource.SourceError.empty = error else {
                return XCTFail("expected .empty, got \(error)")
            }
        }
    }

    func testWhitespaceOnlyTrailingNewlineStillThrows() {
        XCTAssertThrowsError(try TextSource.literal("\n").resolve())
    }

    func testUnpinnedFocusGuardReportsNoChange() {
        // Never pinned → never halts (also holds on headless CI where
        // frontmostApplication is nil).
        let guardian = FocusGuard()
        XCTAssertFalse(guardian.focusChanged)
        XCTAssertEqual(guardian.pinnedName, "?")
    }

    func testKeyPosterEmptyPlanIsHeadlessSafeNoOp() throws {
        // Constructing the CGEventSource and performing an empty plan must
        // work headless (no events posted, no Accessibility needed).
        try KeyPoster().perform([], focusGuard: FocusGuard())
    }
}
