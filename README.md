# Jarvis — Claude Code adapter

Gives Claude Code a voice through an agent-agnostic core — [omarchy-jarvis](https://github.com/jburchel/omarchy-jarvis)
on Linux, mac-jarvis on macOS — that does TTS, hush/interrupt, the "Hey Jarvis" wake word, local
dictation and a bar / menu-bar widget. This repo is only the Claude Code side: hooks that decide
*when* to speak and *what* to say, and the `/jarvis` command. One adapter, both platforms
(bash 3.2-clean).

| Event | Hook | Behaviour |
|---|---|---|
| Claude finishes a turn | `Stop` | Short replies are read directly; longer ones are summarised into 1–2 spoken sentences by Haiku (`claude -p`), heuristic fallback if that fails |
| Claude needs approval / input | `Notification` | "Sir, I need your approval to use Bash." |
| Tool use | `PreToolUse` | "Editing config", "Running tests" — low priority, dropped if already speaking, de-duplicated |
| Session starts | `SessionStart` | Time-of-day greeting |
| You send a new prompt / close the session | `UserPromptSubmit`, `SessionEnd` | Hush — Jarvis stops talking over the next turn |

All hooks run `async`, so Claude never waits on audio.

Some details of what gets said:

- A turn that ends with a question is never lost: the last `?` sentence is appended verbatim
  to the summary if the summary didn't already include it.
- Summaries are `jarvis say --replace`: if you fire off several turns quickly, only the latest
  summary is spoken (whatever is already playing finishes; the stale ones in the queue drop).
- With more than one Claude Code session talking, lines are prefixed with the repo name —
  "CG One: tests pass" — so you know which one. `JARVIS_SESSION_TAG=auto|always|never`
  (auto = only when another session spoke in the last `JARVIS_SESSION_WINDOW` seconds, 600).
- Markdown is cleaned for speech by `bin/jarvis-clean`: code blocks and links dropped, tables read
  as "cell, cell.", paths collapsed to basenames, emoji removed.
- Conversation mode (macOS core, `JARVIS_CONVERSE=1`): after a reply is read, the mic opens for a
  follow-up with no wake word. Only after a line that actually played — a superseded or hushed
  summary (`jarvis-say` exits 3) doesn't open the mic.

## Install

1. Install the core and put `jarvis` on your PATH — on Omarchy:
   ```bash
   omarchy plugin add https://github.com/jburchel/omarchy-jarvis --enable
   ~/.config/omarchy/plugins/io.github.jburchel.jarvis/bin/jarvis setup
   ln -s ~/.config/omarchy/plugins/io.github.jburchel.jarvis/bin/jarvis ~/.local/bin/jarvis
   ```
   On any other Linux: clone omarchy-jarvis anywhere, run `bin/jarvis setup`, symlink
   `bin/jarvis` onto your PATH. The bar widget and visualizer are Omarchy-only; everything
   else works without them. On macOS: clone mac-jarvis, `bin/jarvis setup`, same symlink.
2. Install this plugin:
   ```bash
   claude plugin marketplace add jburchel/jarvis      # or a local path
   claude plugin install jarvis@jarvis
   ```

If `jarvis` isn't on PATH for the process Claude Code runs hooks in, set `JARVIS_CORE` to the
core's `bin/` directory.

## Control

`/jarvis hush` (interrupt), `/jarvis mute`, `/jarvis unmute`, `/jarvis pronounce plugin "plug-in"`,
`/jarvis listen enable` (wake word), `/jarvis voice en-GB-ThomasNeural`, `/jarvis status` —
the skill maps these to the `jarvis` CLI.

**`/jarvis tour`** — Jarvis explains himself out loud, in his own voice: what he says and when,
how to stop him, the wake word and dictation, voices, settings, the command. About three minutes;
`/jarvis tour listening` for one section; any hush ends it. It adapts to the platform and to
what's currently enabled (wake word, conversation mode). `bin/jarvis-tour --text` prints the
script; `--outline` lists the sections.

Narration on/off, which tools to narrate, summary mode, and how Jarvis addresses you live in
`~/.config/jarvis/config.sh` (documented in the core's `bin/jarvis-env`); the adapter-only keys
(`JARVIS_SESSION_TAG`, `JARVIS_SESSION_WINDOW`) go in the same file.

## Tests

```bash
./test/run.sh       # ./test/run.sh -v prints every line that would have been spoken
```

Feeds sample hook payloads through `bin/jarvis-hook` against `test/fakecore/`, a stub core that
records what `jarvis-say` would say instead of speaking. Needs `jq` and `python3`; runs on
bash 3.2 (macOS) and 5.

## Other agents

See [ADAPTERS.md](ADAPTERS.md) for the CLI contract and Codex / Gemini / generic examples.

## Layout

```
.claude-plugin/marketplace.json   local marketplace manifest
plugins/jarvis/
  .claude-plugin/plugin.json
  hooks/hooks.json                event → bin/jarvis-hook
  bin/jarvis-hook                 turns hook JSON into `jarvis say` calls
  bin/jarvis-clean                markdown → speakable text (python, no Jarvis dependencies)
  bin/jarvis-tour                 the spoken tour
  skills/jarvis/SKILL.md          the /jarvis command
test/run.sh, test/fakecore/       hook tests against a stub core
ADAPTERS.md                       hooking other agents to the core
```

Bump `version` in `plugins/jarvis/.claude-plugin/plugin.json` after edits, then
`claude plugin marketplace update <name> && claude plugin update jarvis@<name>` — the installed
copy is cached per version. For rapid iteration: `claude --plugin-dir ./plugins/jarvis`.
