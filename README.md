# Jarvis — Claude Code adapter

Gives Claude Code a voice through [omarchy-jarvis](https://github.com/jburchel/omarchy-jarvis),
the agent-agnostic core (TTS, hush/interrupt, "Hey Jarvis" wake word, Omarchy bar widget).
This repo is only the Claude Code side: hooks that decide *when* to speak and *what* to say.

| Event | Hook | Behaviour |
|---|---|---|
| Claude finishes a turn | `Stop` | Short replies are read directly; longer ones are summarised into 1–2 spoken sentences by Haiku (`claude -p`), heuristic fallback if that fails |
| Claude needs approval / input | `Notification` | "Sir, I need your approval to use Bash." |
| Tool use | `PreToolUse` | "Editing config", "Running tests" — low priority, dropped if already speaking, de-duplicated |
| Session starts | `SessionStart` | Time-of-day greeting |

All hooks run `async`, so Claude never waits on audio.

## Install

1. Install the core and put `jarvis` on your PATH — on Omarchy:
   ```bash
   omarchy plugin add https://github.com/jburchel/omarchy-jarvis --enable
   ~/.config/omarchy/plugins/io.github.jburchel.jarvis/bin/jarvis setup
   ln -s ~/.config/omarchy/plugins/io.github.jburchel.jarvis/bin/jarvis ~/.local/bin/jarvis
   ```
   On any other Linux: clone omarchy-jarvis anywhere, run `bin/jarvis setup`, symlink
   `bin/jarvis` onto your PATH. The bar widget and visualizer are Omarchy-only; everything
   else works without them.
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

Narration on/off, which tools to narrate, summary mode, and how Jarvis addresses you live in
`~/.config/jarvis/config.sh` (documented in the core's `bin/jarvis-env`).

## Other agents

See [ADAPTERS.md](ADAPTERS.md) for the CLI contract and Codex / Gemini / generic examples.

## Layout

```
.claude-plugin/marketplace.json   local marketplace manifest
plugins/jarvis/
  .claude-plugin/plugin.json
  hooks/hooks.json                event → bin/jarvis-hook
  bin/jarvis-hook                 turns hook JSON into `jarvis say` calls
  skills/jarvis/SKILL.md          the /jarvis command
ADAPTERS.md                       hooking other agents to the core
```

Bump `version` in `plugins/jarvis/.claude-plugin/plugin.json` after edits, then
`claude plugin marketplace update <name> && claude plugin update jarvis@<name>` — the installed
copy is cached per version. For rapid iteration: `claude --plugin-dir ./plugins/jarvis`.
