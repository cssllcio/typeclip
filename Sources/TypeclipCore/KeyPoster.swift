import CoreGraphics
import Foundation

public struct KeyPoster {
    public enum Halt: Error { case focusChanged(afterEvents: Int) }

    private static let enterKeyCode: CGKeyCode = 36
    private static let backspaceKeyCode: CGKeyCode = 51

    /// Saturating ms→µs conversion for usleep: non-finite or negative delays
    /// sleep 0 (invalid upstream value — fail visible, not wedged); finite
    /// oversized delays saturate at UInt32.max.
    static func microseconds(forDelayMs ms: Double) -> UInt32 {
        guard ms.isFinite, ms > 0 else { return 0 }
        let us = (ms * 1_000).rounded()
        return us >= Double(UInt32.max) ? UInt32.max : UInt32(us)
    }

    private let source = CGEventSource(stateID: .combinedSessionState)

    public init() {}

    /// Plays the plan in real time. Checks the focus guard after each delay,
    /// BEFORE posting, so no keystroke ever lands in a newly-focused window.
    ///
    /// MUST run on the main thread: the focus guard drains this thread's run
    /// loop to refresh `NSWorkspace.frontmostApplication` (see Frontmost), and
    /// workspace notifications are delivered on the main run loop. Moving this
    /// to a background thread would silently make the guard stale again.
    public func perform(_ plan: [KeystrokeEvent], focusGuard: FocusGuard) throws {
        for (index, event) in plan.enumerated() {
            let sleepMicros = Self.microseconds(forDelayMs: event.delayBeforeMs)
            if sleepMicros > 0 {
                usleep(sleepMicros)
            }
            if focusGuard.focusChanged {
                throw Halt.focusChanged(afterEvents: index)
            }
            post(event.action)
        }
    }

    private func post(_ action: KeyAction) {
        switch action {
        // Zero flags: physically held modifiers (e.g. Cmd during a Cmd+Tab abort) must not turn typed characters into shortcuts.
        case .typeCluster(let s):
            let units = Array(s.utf16)
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            down?.flags = []
            down?.post(tap: .cghidEventTap)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            up?.flags = []
            up?.post(tap: .cghidEventTap)
        case .pressEnter(let shift):
            pressKey(Self.enterKeyCode, flags: shift ? [.maskShift] : [])
        case .backspace:
            pressKey(Self.backspaceKeyCode, flags: [])
        }
    }

    private func pressKey(_ code: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }
}
