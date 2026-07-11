/// Physically adjacent keys on a US QWERTY layout, for plausible wrong-key typos.
public enum QwertyNeighbors {
    static let map: [Character: String] = [
        "q": "wa", "w": "qes", "e": "wrd", "r": "etf", "t": "ryg",
        "y": "tuh", "u": "yij", "i": "uok", "o": "ipl", "p": "ol",
        "a": "qsz", "s": "awdx", "d": "sefc", "f": "drgv", "g": "fthb",
        "h": "gyjn", "j": "hukm", "k": "jil", "l": "kop",
        "z": "asx", "x": "zsdc", "c": "xdfv", "v": "cfgb", "b": "vghn",
        "n": "bhjm", "m": "njk",
        "1": "2q", "2": "13w", "3": "24e", "4": "35r", "5": "46t",
        "6": "57y", "7": "68u", "8": "79i", "9": "80o", "0": "9p",
    ]

    /// A neighboring key for `ch`, preserving case. Falls back to `ch` itself if
    /// unmapped (callers filter with `isTypoEligible` first).
    public static func neighbor(of ch: Character, rng: inout SplitMix64) -> Character {
        guard let lower = ch.lowercased().first,
              let candidates = map[lower], !candidates.isEmpty else { return ch }
        let picked = Array(candidates)[Int(rng.next() % UInt64(candidates.count))]
        return ch.isUppercase ? Character(picked.uppercased()) : picked
    }
}
