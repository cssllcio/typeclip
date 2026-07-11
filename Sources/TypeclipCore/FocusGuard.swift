import AppKit

/// Pins the frontmost application at typing start; any change means keystrokes
/// would land in the wrong window, so the poster halts.
public final class FocusGuard {
    private var pinnedPID: pid_t?
    public private(set) var pinnedName: String = "?"

    public init() {}

    public func pin() {
        let app = NSWorkspace.shared.frontmostApplication
        pinnedPID = app?.processIdentifier
        pinnedName = app?.localizedName ?? "?"
    }

    public var focusChanged: Bool {
        guard let pinned = pinnedPID else { return false }
        return NSWorkspace.shared.frontmostApplication?.processIdentifier != pinned
    }
}
