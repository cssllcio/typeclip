import ArgumentParser
import Foundation
import TypeclipCore

extension NewlineMode: ExpressibleByArgument {} // RawRepresentable<String> → free init

@main
struct Typeclip: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "typeclip",
        abstract: "Types your clipboard into the focused field with human cadence.",
        discussion: """
        Built for screen recordings: jittered keystroke timing, natural pauses, \
        optional typo-and-correction performances, and reproducible takes via --seed.
        Requires the Accessibility permission (System Settings → Privacy & Security \
        → Accessibility) for the app hosting this process — usually your terminal.
        """,
        version: Version.current
    )

    @Option(name: .shortAndLong, help: "Countdown seconds before typing starts.")
    var delay: Int = 5

    @Option(help: "Activate this app right before typing (matches running app names).")
    var app: String?

    @Option(help: "Target words per minute.")
    var wpm: Double = 70

    @Flag(help: "Constant delay, no jitter (mechanical mode).")
    var flat = false

    @Option(name: .customLong("typo-rate"),
            help: "Per-word probability of a typo + backspace correction (0 disables).")
    var typoRate: Double = 0

    @Option(help: "Seed for a reproducible performance (default: random, printed).")
    var seed: UInt64?

    @Option(help: "Newline handling: shift-enter | enter | strip.")
    var newline: NewlineMode = .shiftEnter

    @Flag(help: "Press Enter once after all text is typed.")
    var submit = false

    @Option(help: "Type this text instead of the clipboard; \"-\" reads stdin.")
    var text: String?

    @Flag(name: .customLong("dry-run"),
          help: "Print the keystroke timeline to stdout; don't type anything.")
    var dryRun = false

    @Flag(help: "Skip the confirm prompt for texts over 2,000 characters.")
    var yes = false

    func validate() throws {
        guard delay >= 0 else { throw ValidationError("--delay must be ≥ 0") }
        guard wpm > 0 else { throw ValidationError("--wpm must be > 0") }
        guard (0.0...1.0).contains(typoRate) else {
            throw ValidationError("--typo-rate must be between 0 and 1")
        }
    }

    /// Test helper: parse + validate in one call.
    static func validated(_ arguments: [String]) throws -> Typeclip {
        let cmd = try Typeclip.parse(arguments)
        try cmd.validate()
        return cmd
    }

    static func previewLine(_ text: String, limit: Int = 60) -> String {
        String(text.prefix(limit)).replacingOccurrences(of: "\n", with: "⏎")
    }

    mutating func run() throws {
        // 1. Resolve text.
        let source: TextSource
        switch text {
        case .none: source = .clipboard
        case .some("-"): source = .stdin
        case .some(let literal): source = .literal(literal)
        }
        let resolved: String
        do {
            resolved = try source.resolve()
        } catch {
            logErr("typeclip: no text to type (empty clipboard/input)")
            throw ExitCode(4)
        }

        // 2. Seed — always printed so any take can be reproduced.
        let chosenSeed = seed ?? UInt64.random(in: .min ... .max)
        logErr("seed: \(chosenSeed)")

        // 3. Build the performance plan.
        let opts = PerformanceOptions(wpm: wpm, flat: flat, typoRate: typoRate,
                                      newlineMode: newline, submit: submit, seed: chosenSeed)
        let plan = PerformanceEngine.plan(text: resolved, options: opts)

        // 4. Dry run needs no permissions and touches nothing.
        if dryRun {
            print(DryRunRenderer.render(plan))
            return
        }

        // 5. Oversize confirm (before the AX gate: keeps exit 5 reachable headlessly).
        if resolved.count > 2_000 && !yes {
            guard isatty(STDIN_FILENO) != 0 else {
                logErr("typeclip: refusing to type \(resolved.count) chars non-interactively without --yes")
                throw ExitCode(5)
            }
            logErr("about to type \(resolved.count) characters — continue? [y/N]")
            let answer = (readLine() ?? "").lowercased()
            guard answer == "y" || answer == "yes" else {
                logErr("typeclip: cancelled")
                throw ExitCode(5)
            }
        }

        // 6. Accessibility gate (triggers the system prompt when missing).
        guard Accessibility.ensureTrusted() else {
            logErr("""
            typeclip: Accessibility permission required.
            Enable the app hosting this process (your terminal) in:
              System Settings → Privacy & Security → Accessibility
            then re-run.
            """)
            throw ExitCode(3)
        }

        // 7. Preview + countdown (Ctrl+C freely here).
        logErr("will type \(resolved.count) chars — preview: \(Self.previewLine(resolved))")
        if delay > 0 {
            logErr("click into the target field…")
            for remaining in stride(from: delay, through: 1, by: -1) {
                logErr("  \(remaining)…")
                Thread.sleep(forTimeInterval: 1)
            }
        }

        // 8. Optional app activation, then pin focus.
        if let appName = app {
            do {
                try AppActivator.activate(nameContaining: appName)
            } catch {
                logErr("typeclip: \(error)")
                throw ExitCode(1)
            }
        }
        let guardian = FocusGuard()
        guardian.pin()
        logErr("typing into \(guardian.pinnedName)…")

        // 9. Perform.
        do {
            try KeyPoster().perform(plan, focusGuard: guardian)
        } catch KeyPoster.Halt.focusChanged(let count) {
            logErr("typeclip: focus left \(guardian.pinnedName) — halted after \(count) events")
            throw ExitCode(2)
        }
        logErr("done.")
    }
}

func logErr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
