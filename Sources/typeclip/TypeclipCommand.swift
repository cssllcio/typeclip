import ArgumentParser

@main
struct Typeclip: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "typeclip",
        abstract: "Types your clipboard into the focused field with human cadence.",
        version: Version.current
    )

    mutating func run() throws {
        print("typeclip \(Version.current) — CLI lands in Task 9")
    }
}
