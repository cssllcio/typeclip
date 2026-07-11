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

    func testFrontmostAppDrainTerminates() {
        // The focus guard's run-loop drain must always return, never spin. On
        // headless CI the value may be nil; we only assert that reading it (and
        // thus draining an empty/small source queue) terminates promptly.
        _ = Frontmost.app()
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

    func testDelayMicrosecondConversionClampsAndRounds() {
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: 171.43), 171_430)
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: 0), 0)
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: -5), 0)
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: .nan), 0)
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: .infinity), 0)
        XCTAssertEqual(KeyPoster.microseconds(forDelayMs: 1e12), UInt32.max)
    }

    func testActivatorThrowsForUnknownApp() {
        XCTAssertThrowsError(try AppActivator.activate(nameContaining: "zz-nonexistent-app-zz")) { error in
            guard case AppActivator.ActivationError.notRunning = error else {
                return XCTFail("expected .notRunning, got \(error)")
            }
        }
    }
}
