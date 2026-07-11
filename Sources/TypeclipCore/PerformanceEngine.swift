import Foundation

public enum PerformanceEngine {

    static let sigma = 0.35
    static let noticePauseMinMs = 300.0
    static let noticePauseMaxMs = 700.0
    static let newlineDelayCapMs = 1_200.0
    static let submitDelayMs = 500.0
    static let maxUTF16PerEvent = 20
    static let typoSafeTailGraphemes = 3

    public static func plan(text: String, options: PerformanceOptions) -> [KeystrokeEvent] {
        let working = options.newlineMode == .strip
            ? text.replacingOccurrences(of: "\n", with: " ")
            : text
        let clusters = Array(working) // [Character] — grapheme clusters
        let baseMs = 60_000.0 / (options.wpm * 5.0)

        func drawDelay(after previous: Character?) -> Double {
            if options.flat { return baseMs }
            // Task 5 replaces this stub with log-normal jitter + context multipliers.
            return baseMs
        }

        var events: [KeystrokeEvent] = []
        var previous: Character? = nil

        /// Emits one grapheme cluster, splitting >20-UTF-16-unit clusters at
        /// scalar boundaries; continuation chunks carry zero delay.
        func emitCluster(_ ch: Character, delay: Double) {
            if String(ch).utf16.count <= maxUTF16PerEvent {
                events.append(KeystrokeEvent(action: .typeCluster(String(ch)), delayBeforeMs: delay))
                return
            }
            var chunk = ""
            var unitCount = 0
            var isFirst = true
            for scalar in String(ch).unicodeScalars {
                let width = UTF16.width(scalar)
                if unitCount + width > maxUTF16PerEvent, !chunk.isEmpty {
                    events.append(KeystrokeEvent(action: .typeCluster(chunk),
                                                 delayBeforeMs: isFirst ? delay : 0))
                    isFirst = false
                    chunk = ""
                    unitCount = 0
                }
                chunk.unicodeScalars.append(scalar)
                unitCount += width
            }
            if !chunk.isEmpty {
                events.append(KeystrokeEvent(action: .typeCluster(chunk),
                                             delayBeforeMs: isFirst ? delay : 0))
            }
        }

        var index = 0
        while index < clusters.count {
            let ch = clusters[index]
            if ch == "\n" {
                let shift = options.newlineMode == .shiftEnter
                events.append(KeystrokeEvent(action: .pressEnter(shift: shift),
                                             delayBeforeMs: drawDelay(after: previous)))
                previous = "\n"
                index += 1
                continue
            }
            emitCluster(ch, delay: drawDelay(after: previous))
            previous = ch
            index += 1
        }

        if options.submit {
            events.append(KeystrokeEvent(action: .pressEnter(shift: false),
                                         delayBeforeMs: submitDelayMs))
        }
        return events
    }
}
