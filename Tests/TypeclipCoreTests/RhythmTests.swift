import XCTest
@testable import TypeclipCore

final class RhythmTests: XCTestCase {

    func testContextMultiplierTable() {
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: "."), 3.5)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: "!"), 3.5)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: "?"), 3.5)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: ","), 2.0)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: ";"), 2.0)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: ":"), 2.0)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: " "), 1.3)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: "\n"), 5.0)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: "a"), 1.0)
        XCTAssertEqual(PerformanceEngine.contextMultiplier(after: nil), 1.0)
    }

    func testSameSeedIdenticalPlan() {
        let text = "The quick brown fox, obviously! Jumps.\nDone now."
        let a = PerformanceEngine.plan(text: text, options: options(seed: 42))
        let b = PerformanceEngine.plan(text: text, options: options(seed: 42))
        XCTAssertEqual(a, b)
    }

    func testDifferentSeedDifferentDelays() {
        let text = "The quick brown fox jumps over the lazy dog."
        let a = PerformanceEngine.plan(text: text, options: options(seed: 1))
        let b = PerformanceEngine.plan(text: text, options: options(seed: 2))
        XCTAssertEqual(a.map(\.action), b.map(\.action), "same text, same actions")
        XCTAssertNotEqual(a.map(\.delayBeforeMs), b.map(\.delayBeforeMs))
    }

    func testJitterVaries() {
        let plan = PerformanceEngine.plan(text: String(repeating: "a", count: 50),
                                          options: options(seed: 3))
        let delays = Set(plan.map(\.delayBeforeMs))
        XCTAssertGreaterThan(delays.count, 40, "jittered delays should almost never repeat")
    }

    func testMeanDelayNearBase() {
        // 5000 'a' keystrokes (multiplier 1.0): sample mean of the mean-preserving
        // log-normal must sit within 10% of base (171.43 ms at 70 wpm).
        let plan = PerformanceEngine.plan(text: String(repeating: "a", count: 5_000),
                                          options: options(seed: 9))
        let mean = plan.map(\.delayBeforeMs).reduce(0, +) / Double(plan.count)
        let base = 60_000.0 / (70.0 * 5.0)
        XCTAssertEqual(mean, base, accuracy: base * 0.10)
    }

    func testNewlineDelayCapped() {
        // wpm 5 → base 2400 ms; after-newline ×5 would be ~12s — must cap at 1200.
        for seed in UInt64(1)...20 {
            let plan = PerformanceEngine.plan(text: "a\nb", options: options(wpm: 5, seed: seed))
            let afterNewline = plan[2] // events: type a, enter, type b
            XCTAssertLessThanOrEqual(afterNewline.delayBeforeMs, 1_200.0)
        }
    }

    func testFlatBypassesJitterAndMultipliers() {
        let plan = PerformanceEngine.plan(text: "a. b\nc", options: options(wpm: 60, flat: true))
        for event in plan { XCTAssertEqual(event.delayBeforeMs, 200.0) }
    }
}
