import AppKit

public enum AppActivator {
    public enum ActivationError: Error, CustomStringConvertible {
        case notRunning(String)
        public var description: String {
            switch self {
            case .notRunning(let name): return "no running application matches \"\(name)\""
            }
        }
    }

    /// Activates the first running app whose name contains `name` (case-insensitive),
    /// then settles 300 ms so the pin that follows sees the new frontmost app.
    public static func activate(nameContaining name: String) throws {
        let match = NSWorkspace.shared.runningApplications.first {
            ($0.localizedName ?? "").localizedCaseInsensitiveContains(name)
        }
        guard let app = match else { throw ActivationError.notRunning(name) }
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        usleep(300_000)
    }
}
