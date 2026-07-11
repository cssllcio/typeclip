@testable import TypeclipCore

/// Simulates a text editor applying the plan: clusters append, Enter (either kind)
/// appends "\n", backspace deletes one grapheme. Chunked oversized clusters
/// concatenate back into the original grapheme.
func replay(_ plan: [KeystrokeEvent]) -> String {
    var buffer = ""
    for event in plan {
        switch event.action {
        case .typeCluster(let s): buffer += s
        case .pressEnter: buffer += "\n"
        case .backspace: if !buffer.isEmpty { buffer.removeLast() }
        }
    }
    return buffer
}

func options(
    wpm: Double = 70, flat: Bool = false, typoRate: Double = 0,
    newlineMode: NewlineMode = .shiftEnter, submit: Bool = false, seed: UInt64 = 1
) -> PerformanceOptions {
    PerformanceOptions(wpm: wpm, flat: flat, typoRate: typoRate,
                       newlineMode: newlineMode, submit: submit, seed: seed)
}
