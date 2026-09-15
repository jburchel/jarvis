---
name: jarvis
description: Control the Jarvis voice assistant plugin — hush/interrupt, mute/unmute, "Hey Jarvis" wake word, pronunciations, test or change voices, check status, run setup. Use when the user says things like "jarvis mute", "be quiet", "shut up", "stop talking", "change your voice", "jarvis status", "set up jarvis", "how do you pronounce X", "turn on the wake word".
---

# Jarvis voice control

Jarvis speaks through hooks (task summaries, permission requests, tool narration).
All control goes through one script: `jarvis` on PATH (installed by the omarchy-jarvis core plugin).

Map the user's request to a command and run it with Bash:

| User wants | Command |
|---|---|
| first-time install / repair | `jarvis setup` |
| **stop talking right now** (interrupt) | `jarvis hush` |
| silence until told otherwise | `jarvis mute` |
| talk again | `jarvis unmute` |
| fix how a word is said ("plugin" → "plug-in") | `jarvis pronounce plugin "plug-in"` |
| list pronunciations | `jarvis pronounce` |
| turn the "Hey Jarvis" wake word on / off | `jarvis listen enable` / `jarvis listen disable` |
| pause / resume the wake word without uninstalling | `jarvis listen stop` / `jarvis listen start` |
| hear a test line (optionally per engine) | `jarvis test [edge\|piper\|espeak]` |
| say something specific | `jarvis say "text"` |
| current settings / health | `jarvis status` |
| list voices | `jarvis voices` |
| change the online voice | `jarvis voice en-GB-ThomasNeural` |
| change the offline voice | `jarvis piper-voice en_US-ryan-high` |
| see recent errors | `jarvis log` |

Keyboard: **Right Alt** = hush + toggle dictation; **SUPER + SHIFT + J** = hush.
Bar widget (Omarchy): click = mute/unmute, right-click = hush, middle-click = wake word on/off.

Other settings (narration on/off, which tools to narrate, summary mode, how Jarvis
addresses the user, wake-word sensitivity, playback program) live in
`~/.config/jarvis/config.sh` — edit that file directly when asked; every key is documented
in `bin/jarvis-env` in the omarchy-jarvis repo.

With no argument, `/jarvis` means: run `status` and report it briefly.
