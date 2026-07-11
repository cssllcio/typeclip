import XCTest
@testable import TypeclipCore

final class DryRunRendererTests: XCTestCase {

    func testLineFormat() {
        let plan = [
            KeystrokeEvent(action: .typeCluster("H"), delayBeforeMs: 171.4),
            KeystrokeEvent(action: .pressEnter(shift: true), delayBeforeMs: 398.0),
            KeystrokeEvent(action: .backspace, delayBeforeMs: 85.7),
            KeystrokeEvent(action: .pressEnter(shift: false), delayBeforeMs: 500.0),
        ]
        XCTAssertEqual(DryRunRenderer.render(plan), """
        +0171ms  type "H"
        +0398ms  shift+enter
        +0086ms  backspace
        +0500ms  enter
        """)
    }

    func testEscaping() {
        let plan = [
            KeystrokeEvent(action: .typeCluster("\""), delayBeforeMs: 100),
            KeystrokeEvent(action: .typeCluster("\\"), delayBeforeMs: 100),
        ]
        XCTAssertEqual(DryRunRenderer.render(plan), """
        +0100ms  type "\\""
        +0100ms  type "\\\\"
        """)
    }

    func testGoldenTimelineSeed42() throws {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: "golden-seed42", withExtension: "txt", subdirectory: "Fixtures"))
        let expected = try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .newlines)
        let plan = PerformanceEngine.plan(
            text: "Hello, world!\nDone.",
            options: options(typoRate: 0.05, submit: true, seed: 42))
        XCTAssertEqual(DryRunRenderer.render(plan), expected,
                       "Engine output drifted from the committed golden timeline. If the change is intentional, regenerate the fixture (see plan Task 7 Step 4) and eyeball the diff.")
    }
}
