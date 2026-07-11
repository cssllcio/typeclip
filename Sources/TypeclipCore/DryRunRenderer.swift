import Foundation

public enum DryRunRenderer {
    public static func render(_ plan: [KeystrokeEvent]) -> String {
        plan.map(line(for:)).joined(separator: "\n")
    }

    static func line(for event: KeystrokeEvent) -> String {
        String(format: "+%04dms  %@", Int(event.delayBeforeMs.rounded()), describe(event.action))
    }

    static func describe(_ action: KeyAction) -> String {
        switch action {
        case .typeCluster(let s):
            let escaped = s
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "type \"\(escaped)\""
        case .pressEnter(let shift):
            return shift ? "shift+enter" : "enter"
        case .backspace:
            return "backspace"
        }
    }
}
