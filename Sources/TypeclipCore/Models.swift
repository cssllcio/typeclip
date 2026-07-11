/// How newline characters in the source text are typed.
public enum NewlineMode: String, CaseIterable, Sendable {
    case shiftEnter = "shift-enter" // line break without submitting (chat-safe default)
    case enter = "enter"            // literal Enter (editors, terminals)
    case strip = "strip"            // flatten to one line (newlines become spaces)
}

public enum KeyAction: Equatable, Sendable {
    case typeCluster(String)
    case pressEnter(shift: Bool)
    case backspace
}

public struct KeystrokeEvent: Equatable, Sendable {
    public var action: KeyAction
    public var delayBeforeMs: Double

    public init(action: KeyAction, delayBeforeMs: Double) {
        self.action = action
        self.delayBeforeMs = delayBeforeMs
    }
}

public struct PerformanceOptions: Sendable {
    public var wpm: Double
    public var flat: Bool
    public var typoRate: Double
    public var newlineMode: NewlineMode
    public var submit: Bool
    public var seed: UInt64

    public init(wpm: Double, flat: Bool, typoRate: Double,
                newlineMode: NewlineMode, submit: Bool, seed: UInt64) {
        self.wpm = wpm
        self.flat = flat
        self.typoRate = typoRate
        self.newlineMode = newlineMode
        self.submit = submit
        self.seed = seed
    }
}
