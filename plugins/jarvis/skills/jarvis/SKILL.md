---
name: jarvis
description: Control the Jarvis voice assistant — hush/interrupt, mute/unmute, "Hey Jarvis" wake word, dictation, pronunciations, test or change voices, check status, run setup, diagnose the mic, and give a spoken tour of how Jarvis works. Use when the user says things like "jarvis mute", "be quiet", "shut up", "stop talking", "change your voice", "jarvis status", "set up jarvis", "how do you pronounce X", "turn on the wake word", "why can't jarvis hear me", "jarvis tour", "how does jarvis work", "what can jarvis do".
---

# Jarvis voice control

Jarvis speaks through hooks (task summaries, permission requests, tool narration).
All control goes through one script: `jarvis` on PATH (from the core: omarchy-jarvis on
Linux, mac-jarvis on macOS). The plugin adds two of its own under `${CLAUDE_PLUGIN_ROOT}/bin/`.

Map the user's request to a command and run it with Bash:

| User wants | Command |
|---|---|
| **a tour / "how do you work" / "what can you do"** | see *Tour* below |
| first-time install / repair | `jarvis setup` |
| **stop talking right now** (interrupt) | `jarvis hush` |
| silence until told otherwise | `jarvis mute` |
| talk again | `jarvis unmute` |
| fix how a word is said ("plugin" → "plug-in") | `jarvis pronounce plugin "plug-in"` |
| list pronunciations | `jarvis pronounce` |
| turn the "Hey Jarvis" wake word on / off | `jarvis listen enable` / `jarvis listen disable` |
| pause / resume the wake word without uninstalling | `jarvis listen stop` / `jarvis listen start` |
| ignore dictation for a while / act on it again | `jarvis pause` / `jarvis resume` (macOS) |
| dictate one utterance now (no wake word) | `jarvis dictate` |
| hear a test line (optionally per engine) | `jarvis test [edge\|piper\|espeak\|macos]` |
| say something specific | `jarvis say "text"` |
| current settings / health | `jarvis status` |
| **it can't hear me / won't type** | `jarvis doctor` (macOS) |
| list voices | `jarvis voices` |
| change the online voice | `jarvis voice en-GB-ThomasNeural` |
| change the offline voice | `jarvis piper-voice en_US-ryan-high` / `jarvis macos-voice Oliver` |
| pick a microphone | `jarvis mic` / `jarvis mic "Device Name"` (macOS) |
| more accurate dictation | `jarvis stt-model small.en` (macOS) |
| see recent errors | `jarvis log` |

With no argument, `/jarvis` means: run `status` and report it briefly.

## Tour

Jarvis explains himself out loud — what he says and when, how to stop him, the wake word and
dictation, voices, settings, this command. It adapts to the platform and current settings.

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/jarvis-tour" --outline          # sections, one line each
nohup "${CLAUDE_PLUGIN_ROOT}/bin/jarvis-tour" >/dev/null 2>&1 &            # full tour, ~3 min
nohup "${CLAUDE_PLUGIN_ROOT}/bin/jarvis-tour" listening >/dev/null 2>&1 &  # one section
"${CLAUDE_PLUGIN_ROOT}/bin/jarvis-tour" --text [section]   # the script, printed, silent
```

Run the spoken tour **detached** (`nohup … &`) so the turn ends immediately, then reply with one
short line ("Starting the tour — hush me to stop.") and the outline. Don't restate the tour's
content in text. Any hush (a new prompt, Right Alt, "Hey Jarvis") ends it. If Jarvis is muted,
the tour refuses; offer `--text` or `jarvis unmute`. Sections: `intro speaking quiet listening
voice settings commands`.

## Platform notes

**Linux / Omarchy** — keyboard: **Right Alt** = hush + toggle dictation; **SUPER + SHIFT + J** =
hush. Bar widget: click = mute/unmute, right-click = hush, middle-click = wake word on/off.
The wake word runs as a systemd user service, `jarvis-listen.service`.

**macOS** — the menu bar item (SwiftBar) shows state with hush / mute / wake word. The wake
word runs as a launchd agent, `com.jburchel.jarvis-listen`. `jarvis doctor` checks sox, afplay,
whisper.cpp, the model, openWakeWord, live microphone level, Accessibility permission, and the
agent. Two failures need **System Settings → Privacy & Security**:

- **microphone: SILENT** → grant *Microphone* to the process running the wake word.
- **accessibility: BLOCKED** → grant *Accessibility*, or dictation cannot paste.

Dictation is local on both platforms: recorded until you stop talking, transcribed on the
machine, pasted into the focused window. Edge TTS (the default voice) sends the *text being
spoken* to Microsoft; set `JARVIS_ENGINE="piper"` (Linux) or `"macos"` (Mac) for fully offline.

## Settings

Narration on/off, which tools to narrate, summary mode, how Jarvis addresses the user,
wake-word sensitivity, dictation silence timeout, conversation mode, session tagging — all in
`~/.config/jarvis/config.sh`. Edit that file directly when asked; every key is documented with
its default in the core's `bin/jarvis-env` (adapter keys `JARVIS_SESSION_TAG`,
`JARVIS_SESSION_WINDOW` in this plugin's `bin/jarvis-hook`).
