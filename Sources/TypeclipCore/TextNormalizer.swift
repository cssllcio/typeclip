import Foundation

public enum TextNormalizer {
    /// CRLF/CR → LF, then trims exactly one trailing newline (shell `pbcopy` artifact).
    public static func normalize(_ text: String) -> String {
        var t = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if t.hasSuffix("\n") { t.removeLast() }
        return t
    }
}
