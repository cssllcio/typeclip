import ApplicationServices

public enum Accessibility {
    /// True when this process may post keyboard events. When false, the system
    /// permission dialog is triggered as a side effect (prompt option).
    public static func ensureTrusted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }
}
