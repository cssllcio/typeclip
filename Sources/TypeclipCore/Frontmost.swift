import AppKit

/// The current frontmost application, read *live*.
///
/// `NSWorkspace.shared.frontmostApplication` is fed by notifications delivered
/// on the run loop. typeclip's typing loop (`KeyPoster.perform`) and the
/// `AppActivator` poll never spin the run loop, so without draining pending
/// sources first the value goes stale — the focus guard would keep seeing the
/// pinned app and never halt on a real focus change (verified on a live
/// desktop). Draining pending sources with a zero timeout makes the read
/// reflect the actual frontmost app without blocking.
enum Frontmost {
    private static func drainPendingSources() {
        while CFRunLoopRunInMode(.defaultMode, 0, true) == .handledSource {}
    }

    static func app() -> NSRunningApplication? {
        drainPendingSources()
        return NSWorkspace.shared.frontmostApplication
    }

    static func pid() -> pid_t? {
        app()?.processIdentifier
    }
}
