# typeclip

Types your clipboard into the focused text field **as if a human were typing it** —
jittered rhythm, natural pauses, optional typos-and-corrections, and reproducible
takes. Built for screen recordings and demo videos where pasted text looks fake.

## Install

```sh
brew install cssllcio/tap/typeclip
```

Or from source (needs Xcode command-line tools):

```sh
git clone https://github.com/cssllcio/typeclip.git
cd typeclip && swift build -c release
sudo cp .build/release/typeclip /usr/local/bin/
```

## First run: Accessibility permission

typeclip posts real keyboard events, which macOS gates behind the Accessibility
permission. On first run you'll get the system prompt; enable the app **hosting**
typeclip — your terminal (Terminal, iTerm2, …) — under
**System Settings → Privacy & Security → Accessibility**, then re-run.

## Usage

Copy some text, then:

```sh
typeclip                 # 5s countdown — click into the target field, it types
typeclip -d 3 --wpm 85   # faster typist, shorter countdown
typeclip --seed 42       # same "performance" every take (seed prints on every run)
typeclip --typo-rate 0.02 --submit   # occasional corrected typos; Enter at the end
typeclip --app "TextEdit"            # focus TextEdit for you after the countdown
typeclip --text 'demo prompt' --dry-run   # inspect the keystroke timeline, type nothing
```

Recording workflow: start your screen recorder, run `typeclip` in an off-screen
terminal, click into the on-camera field during the countdown, and let it perform.
Every run prints its seed — if a take was good, `--seed <that number>` replays it
keystroke-for-keystroke.

## Flags

| Flag | Default | Meaning |
|---|---|---|
| `-d, --delay <sec>` | 5 | Countdown before typing starts |
| `--app <name>` | — | Activate this running app before typing |
| `--wpm <n>` | 70 | Target speed; delays jitter around it |
| `--flat` | off | Constant delay, no jitter |
| `--typo-rate <p>` | 0 | Per-word typo+correction probability |
| `--seed <n>` | random | Reproducible performance (always printed) |
| `--newline <mode>` | `shift-enter` | `shift-enter` \| `enter` \| `strip` — chat boxes submit on plain Enter |
| `--submit` | off | Press Enter once at the end |
| `--text <s>` | clipboard | Type this instead; `-` reads stdin |
| `--dry-run` | off | Print the timeline; don't type |
| `--yes` | off | Skip the >2,000-char confirm |

## Safety

- **Focus guard:** typing halts the instant the frontmost app changes — click
  anywhere else or Cmd+Tab to abort a take (exit code 2).
- **Preview:** the countdown shows a preview of what's about to be typed.
- **Oversize confirm:** clipboards over 2,000 chars ask first (`--yes` to skip).

Exit codes: `0` done · `1` `--app` activation failure (no match, or app never became frontmost) · `2` focus-change halt · `3` Accessibility missing ·
`4` no text · `5` confirm declined.

## Release verification recipe (maintainers)

Run before every tag — CI cannot exercise real keystrokes:

1. `pbcopy < fixture.txt` where fixture.txt contains 2+ lines and an emoji.
2. `typeclip -d 3 --seed 42 --typo-rate 0.02` into TextEdit → text matches the
   clipboard exactly; rhythm looks human; typo corrections read naturally.
3. Re-run with the same seed → identical performance.
4. Start a run, Cmd+Tab away mid-take → halts immediately, exit 2, no strays.
5. `typeclip --newline enter --submit --text $'line1\nline2'` into TextEdit →
   two lines plus a final Enter.

## License

MIT © CSS LLC
