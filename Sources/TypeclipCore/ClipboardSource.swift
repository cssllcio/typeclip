import AppKit

public enum TextSource {
    case clipboard
    case literal(String)
    case stdin

    public enum SourceError: Error { case empty }

    /// Raw text → normalized (CRLF→LF, one trailing newline trimmed). Throws on empty.
    public func resolve() throws -> String {
        let raw: String
        switch self {
        case .clipboard:
            raw = NSPasteboard.general.string(forType: .string) ?? ""
        case .literal(let s):
            raw = s
        case .stdin:
            let data = FileHandle.standardInput.readDataToEndOfFile()
            raw = String(data: data, encoding: .utf8) ?? ""
        }
        let normalized = TextNormalizer.normalize(raw)
        guard !normalized.isEmpty else { throw SourceError.empty }
        return normalized
    }
}
