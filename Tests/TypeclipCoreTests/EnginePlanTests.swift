import XCTest
@testable import TypeclipCore

final class EnginePlanTests: XCTestCase {

    func testFlatDelaysAreConstant() {
        // 60 wpm → 60000/(60*5) = 200 ms per keystroke, no jitter, no multipliers.
        let plan = PerformanceEngine.plan(text: "ab. c", options: options(wpm: 60, flat: true))
        XCTAssertEqual(plan.count, 5)
        for event in plan { XCTAssertEqual(event.delayBeforeMs, 200.0) }
    }

    func testShiftEnterMode() {
        let plan = PerformanceEngine.plan(text: "a\nb", options: options(flat: true))
        XCTAssertEqual(plan.map(\.action), [
            .typeCluster("a"), .pressEnter(shift: true), .typeCluster("b"),
        ])
    }

    func testEnterMode() {
        let plan = PerformanceEngine.plan(text: "a\nb", options: options(flat: true, newlineMode: .enter))
        XCTAssertEqual(plan.map(\.action), [
            .typeCluster("a"), .pressEnter(shift: false), .typeCluster("b"),
        ])
    }

    func testStripModeNewlinesBecomeSpaces() {
        let plan = PerformanceEngine.plan(text: "a\nb", options: options(flat: true, newlineMode: .strip))
        XCTAssertEqual(plan.map(\.action), [
            .typeCluster("a"), .typeCluster(" "), .typeCluster("b"),
        ])
    }

    func testSubmitAppendsPlainEnterAfter500ms() {
        let plan = PerformanceEngine.plan(text: "hi", options: options(flat: true, submit: true))
        let last = try! XCTUnwrap(plan.last)
        XCTAssertEqual(last.action, .pressEnter(shift: false))
        XCTAssertEqual(last.delayBeforeMs, 500.0)
    }

    func testEmojiIsOneCluster() {
        let plan = PerformanceEngine.plan(text: "a👍b", options: options(flat: true))
        XCTAssertEqual(plan.map(\.action), [
            .typeCluster("a"), .typeCluster("👍"), .typeCluster("b"),
        ])
    }

    func testOversizedClusterChunksAtScalarBoundaries() {
        // One grapheme: "e" + 25 combining acute accents = 26 UTF-16 units.
        let monster = "e" + String(repeating: "\u{0301}", count: 25)
        XCTAssertEqual(Array(monster).count, 1)
        let plan = PerformanceEngine.plan(text: monster, options: options(flat: true))
        XCTAssertEqual(plan.count, 2, "26 units should split into 20 + 6")
        guard case .typeCluster(let first) = plan[0].action,
              case .typeCluster(let second) = plan[1].action else {
            return XCTFail("expected two typeCluster events")
        }
        XCTAssertEqual(first.utf16.count, 20)
        XCTAssertEqual(second.utf16.count, 6)
        XCTAssertEqual(plan[1].delayBeforeMs, 0.0, "continuation chunk types instantly")
        XCTAssertEqual(replay(plan), monster, "chunks reassemble the grapheme")
    }

    func testReplayReconstructsText() {
        let text = "Hello, world!\nSecond line."
        let plan = PerformanceEngine.plan(text: text, options: options(flat: true))
        XCTAssertEqual(replay(plan), text)
    }
}
