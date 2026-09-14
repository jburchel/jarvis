# Jarvis — free voice feedback for Claude Code

A Claude Code plugin that gives Claude a voice without an ElevenLabs key.

- **Edge TTS** (Microsoft's free neural voices, no API key) for quality when online
- **Piper** (fully offline, ~60 MB voice) as the automatic fallback
- **espeak-ng** as a last resort if installed

## What it says

| Event | Hook | Behaviour |
|---|---|---|
| Claude finishes a turn | `Stop` | Short replies are read directly; longer ones are summarised into 1–2 spoken sentences by Haiku (`claude -p`), heuristic fallback if that fails |
| Claude needs approval / input | `Notification` | "Sir, I need your approval to use Bash." |
| Tool use | `PreToolUse` | "Editing config", "Running tests" — low priority, dropped if already speaking, de-duplicated |
| Session starts | `SessionStart` | Time-of-day greeting |

All hooks run `async`, so Claude never waits on audio.

## Install

```bash
claude plugin marketplace add ~/Work/jarvis     # or the git URL once pushed
claude plugin install jarvis@jarvis-local
~/.claude/plugins/... /bin/jarvis setup          # or just: /jarvis setup inside Claude
```

`setup` creates `~/.local/share/jarvis/venv` with `edge-tts` + `piper-tts`, downloads the
`en_GB-alan-medium` Piper voice, and writes `~/.config/jarvis/config.sh`.

Requirements: Python 3, `jq`, and one of `mpv` / `ffplay` / `pw-play`.

## Control

`/jarvis mute`, `/jarvis unmute`, `/jarvis test piper`, `/jarvis voice en-GB-ThomasNeural`,
`/jarvis status` — or run `plugins/jarvis/bin/jarvis` directly.

Config keys (all optional) are in `~/.config/jarvis/config.sh`; defaults and docs are in
`plugins/jarvis/bin/jarvis-env`.

## Layout

```
.claude-plugin/marketplace.json   local marketplace manifest
plugins/jarvis/
  .claude-plugin/plugin.json
  hooks/hooks.json                event → bin/jarvis-hook
  bin/jarvis-env                  defaults + config loading
  bin/jarvis-say                  synth (edge → piper → espeak) + locked playback
  bin/jarvis-hook                 turns hook JSON into speech
  bin/jarvis                      setup / mute / test / voice / status
  skills/jarvis/SKILL.md          the /jarvis command
```
