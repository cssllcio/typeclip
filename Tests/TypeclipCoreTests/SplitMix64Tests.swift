import XCTest
@testable import TypeclipCore

final class SplitMix64Tests: XCTestCase {

    /// Known-answer vectors from Sebastiano Vigna's reference splitmix64.c (seed 0).
    /// If this fails, diff the implementation against the C reference constants
    /// (0x9E3779B97F4A7C15, 0xBF58476D1CE4E5B9, 0x94D049BB133111EB) — do NOT
    /// adjust the expected values to match the code.
    func testKnownAnswerSeedZero() {
        var rng = SplitMix64(seed: 0)
        XCTAssertEqual(rng.next(), 0xE220A8397B1DCDAF)
        XCTAssertEqual(rng.next(), 0x6E789E6AA1B965F4)
        XCTAssertEqual(rng.next(), 0x06C45D188009454F)
    }

    func testDeterminismSameSeed() {
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        for _ in 0..<64 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testDifferentSeedsDiffer() {
        var a = SplitMix64(seed: 1)
        var b = SplitMix64(seed: 2)
        XCTAssertNotEqual((0..<8).map { _ in a.next() }, (0..<8).map { _ in b.next() })
    }

    func testUniformRange() {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<10_000 {
            let u = rng.uniform()
            XCTAssertGreaterThanOrEqual(u, 0.0)
            XCTAssertLessThan(u, 1.0)
        }
    }

    func testGaussianMoments() {
        var rng = SplitMix64(seed: 7)
        let n = 20_000
        let samples = (0..<n).map { _ in rng.gaussian() }
        let mean = samples.reduce(0, +) / Double(n)
        let variance = samples.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(n)
        XCTAssertEqual(mean, 0.0, accuracy: 0.05)
        XCTAssertEqual(variance, 1.0, accuracy: 0.1)
    }
}
