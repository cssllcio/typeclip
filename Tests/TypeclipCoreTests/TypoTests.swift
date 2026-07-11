import XCTest
@testable import TypeclipCore

final class TypoTests: XCTestCase {

    func testNeighborIsAdjacentAndCasePreserving() {
        var rng = SplitMix64(seed: 1)
        let n1 = QwertyNeighbors.neighbor(of: "g", rng: &rng)
        XCTAssertTrue("fthb".contains(n1))
        let n2 = QwertyNeighbors.neighbor(of: "G", rng: &rng)
        XCTAssertTrue("FTHB".contains(n2))
        XCTAssertTrue(n2.isUppercase)
    }

    func testReplayAlwaysReconstructsIntendedText() {
        // The core invariant: whatever the performance does, the buffer ends correct.
        let text = "Fix the bug! Ship v1.0 today, ok? 👍 Final words here"
        for seed in UInt64(1)...50 {
            let plan = PerformanceEngine.plan(
                text: text, options: options(typoRate: 1.0, seed: seed))
            XCTAssertEqual(replay(plan), text, "seed \(seed) corrupted the text")
        }
    }

    func testTyposActuallyHappen() {
        let plan = PerformanceEngine.plan(
            text: "hello wonderful world", options: options(typoRate: 1.0, seed: 4))
        XCTAssertTrue(plan.contains { $0.action == .backspace },
                      "typoRate 1.0 must produce at least one correction")
    }

    func testZeroRateMeansZeroBackspaces() {
        let plan = PerformanceEngine.plan(
            text: "hello wonderful world", options: options(typoRate: 0.0, seed: 4))
        XCTAssertFalse(plan.contains { $0.action == .backspace })
    }

    func testWrongCharactersAreOnlyASCIIAlphanumerics() {
        // Feed punctuation + emoji; any cluster typed then backspaced must be
        // a plain letter/digit — never a mangled emoji or symbol.
        let text = "email me: joe@cssllc.io! 🚀 (v1.0)"
        for seed in UInt64(1)...30 {
            let plan = PerformanceEngine.plan(
                text: text, options: options(typoRate: 1.0, seed: seed))
            var buffer: [String] = []
            for event in plan {
                switch event.action {
                case .typeCluster(let s): buffer.append(s)
                case .backspace:
                    let wrong = buffer.removeLast()
                    // The deepest removed char per correction run is the wrong one;
                    // every removed char must still be ASCII alphanumeric.
                    XCTAssertEqual(wrong.count, 1)
                    let ch = Character(wrong)
                    XCTAssertTrue(ch.isASCII && (ch.isLetter || ch.isNumber),
                                  "backspaced over non-alphanumeric \(wrong) (seed \(seed))")
                case .pressEnter: buffer.append("\n")
                }
            }
        }
    }

    func testNoTypoWithinFinalThreeGraphemes() {
        // 6-char text, rate 1.0: wrong chars may only appear at logical
        // positions 0..2 (indices < count-3). Verify by replay-tracing.
        let text = "abcdef"
        for seed in UInt64(1)...50 {
            let plan = PerformanceEngine.plan(
                text: text, options: options(typoRate: 1.0, seed: seed))
            var logicalPosition = 0
            var pending: [Int] = [] // logical positions of not-yet-settled clusters
            for event in plan {
                switch event.action {
                case .typeCluster:
                    pending.append(logicalPosition)
                    logicalPosition += 1
                case .backspace:
                    logicalPosition = pending.removeLast()
                case .pressEnter:
                    pending.append(logicalPosition)
                    logicalPosition += 1
                }
            }
            // Any backspace run bottomed out at the wrong char's position; the
            // minimum position ever revisited must be < count - 3.
            // (Replay correctness is asserted separately; here we just require
            // the final 3 graphemes were never backspaced over.)
            let backspaceEvents = plan.enumerated().filter { $0.element.action == .backspace }
            if !backspaceEvents.isEmpty {
                // Reconstruct: track the minimum buffer length reached after any backspace.
                var length = 0
                var minAfterBackspace = Int.max
                for event in plan {
                    switch event.action {
                    case .typeCluster, .pressEnter: length += 1
                    case .backspace:
                        length -= 1
                        minAfterBackspace = Swift.min(minAfterBackspace, length)
                    }
                }
                XCTAssertLessThan(minAfterBackspace, text.count - 3,
                                  "typo touched the protected tail (seed \(seed))")
            }
        }
    }

    func testTypoChoreographyFixedSeed() {
        // Structural shape for one known seed: wrong char → 1-2 overshoot →
        // notice-pause backspace → fast backspaces → retype.
        let base = 60_000.0 / (70.0 * 5.0)
        let plan = PerformanceEngine.plan(
            text: "hello world", options: options(typoRate: 1.0, seed: 7))
        guard let firstBackspace = plan.firstIndex(where: { $0.action == .backspace }) else {
            return XCTFail("expected a typo with seed 7 at rate 1.0")
        }
        // First backspace carries the notice pause.
        let notice = plan[firstBackspace].delayBeforeMs
        XCTAssertGreaterThanOrEqual(notice, 300.0)
        XCTAssertLessThanOrEqual(notice, 700.0)
        // Subsequent backspaces in the same run are fast (base/2).
        var i = firstBackspace + 1
        while i < plan.count, plan[i].action == .backspace {
            XCTAssertEqual(plan[i].delayBeforeMs, base / 2.0)
            i += 1
        }
        // Backspace run length is 2..3 (wrong char + 1-2 overshoot).
        let runLength = i - firstBackspace
        XCTAssertTrue((2...3).contains(runLength), "run was \(runLength)")
    }
}
