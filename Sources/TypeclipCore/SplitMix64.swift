import Foundation

/// Seeded, portable PRNG (Vigna's splitmix64). One instance drives every random
/// draw in a performance so that --seed reproduces takes keystroke-for-keystroke.
public struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1) with 53-bit precision.
    public mutating func uniform() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    /// Standard normal via Box-Muller.
    public mutating func gaussian() -> Double {
        let u1 = max(uniform(), .leastNonzeroMagnitude) // avoid log(0)
        let u2 = uniform()
        return (-2.0 * Foundation.log(u1)).squareRoot() * Foundation.cos(2.0 * .pi * u2)
    }
}
