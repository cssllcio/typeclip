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
        var rng = SplitMix64(seed: options.seed)
        let working = options.newlineMode == .strip
            ? text.replacingOccurrences(of: "\n", with: " ")
            : text
        let clusters = Array(working) // [Character] — grapheme clusters
        let baseMs = 60_000.0 / (options.wpm * 5.0)

        // Pre-plan typos: cluster index of the wrong char → overshoot count (1-2).
        var typoAt: [Int: Int] = [:]
        if options.typoRate > 0 {
            var i = 0
            while i < clusters.count {
                guard isTypoEligible(clusters[i]) else { i += 1; continue }
                var end = i
                while end + 1 < clusters.count, isTypoEligible(clusters[end + 1]) { end += 1 }
                // Word span [i, end]. One roll per word.
                if rng.uniform() < options.typoRate {
                    let lastAllowed = clusters.count - typoSafeTailGraphemes - 1
                    // Wrong char needs ≥1 following in-word char to overshoot into.
                    let candidates = (i...end).filter { $0 < end && $0 <= lastAllowed }
                    if !candidates.isEmpty {
                        let pick = candidates[Int(rng.next() % UInt64(candidates.count))]
                        let maxOvershoot = Swift.min(2, end - pick)
                        let overshoot = maxOvershoot == 1 ? 1 : 1 + Int(rng.next() % 2)
                        typoAt[pick] = overshoot
                    }
                }
                i = end + 1
            }
        }

        func drawDelay(after previous: Character?) -> Double {
            if options.flat { return baseMs }
            // Log-normal with mean preserved at baseMs: μ = ln(base) − σ²/2.
            let mu = Foundation.log(baseMs) - (sigma * sigma) / 2.0
            let sample = Foundation.exp(mu + sigma * rng.gaussian())
            let value = sample * contextMultiplier(after: previous)
            if previous == "\n" { return Swift.min(value, newlineDelayCapMs) }
            return value
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
            if let overshoot = typoAt[index] {
                // 1) The wrong character.
                let wrong = QwertyNeighbors.neighbor(of: ch, rng: &rng)
                emitCluster(wrong, delay: drawDelay(after: previous))
                previous = wrong
                // 2) Overshoot: keep typing 1-2 correct characters.
                for j in 1...overshoot {
                    let c = clusters[index + j]
                    emitCluster(c, delay: drawDelay(after: previous))
                    previous = c
                }
                // 3) Notice (300-700 ms) on the first backspace, then fast erasing.
                let notice = noticePauseMinMs + rng.uniform() * (noticePauseMaxMs - noticePauseMinMs)
                for b in 0...overshoot { // overshoot + 1 backspaces
                    events.append(KeystrokeEvent(action: .backspace,
                                                 delayBeforeMs: b == 0 ? notice : baseMs / 2.0))
                }
                // 4) Retype the corrected sequence at normal rhythm.
                for j in 0...overshoot {
                    let c = clusters[index + j]
                    emitCluster(c, delay: drawDelay(after: previous))
                    previous = c
                }
                index += overshoot + 1
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

    /// Pause multiplier applied to the keystroke that FOLLOWS `previous`.
    static func contextMultiplier(after previous: Character?) -> Double {
        guard let p = previous else { return 1.0 }
        switch p {
        case ".", "!", "?": return 3.5
        case ",", ";", ":": return 2.0
        case " ": return 1.3
        case "\n": return 5.0
        default: return 1.0
        }
    }

    static func isTypoEligible(_ ch: Character) -> Bool {
        ch.isASCII && (ch.isLetter || ch.isNumber)
    }
}
