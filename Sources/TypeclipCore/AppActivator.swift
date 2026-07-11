import AppKit

public enum AppActivator {
    public enum ActivationError: Error, CustomStringConvertible {
        case notRunning(String)
        case didNotActivate(String)
        public var description: String {
            switch self {
            case .notRunning(let name):
                return "no running application matches \"\(name)\""
            case .didNotActivate(let name):
                return "\"\(name)\" did not become frontmost — not typing"
            }
        }
    }

    /// Activates the first regular (Dock-visible) running app whose name contains
    /// `name` (case-insensitive), then verifies it actually became frontmost so
    /// keystrokes can never land in whatever happened to keep focus.
    public static func activate(nameContaining name: String) throws {
        let match = NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular
                && ($0.localizedName ?? "").localizedCaseInsensitiveContains(name)
        }
        guard let app = match else { throw ActivationError.notRunning(name) }
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        // Poll up to 1s for the activation to take; bail rather than mis-type.
        // Frontmost.pid() drains pending run-loop sources so the read reflects
        // the activation we just triggered instead of a stale cached value.
        for _ in 0..<10 {
            usleep(100_000)
            if Frontmost.pid() == app.processIdentifier {
                return
            }
        }
        throw ActivationError.didNotActivate(app.localizedName ?? name)
    }
}
