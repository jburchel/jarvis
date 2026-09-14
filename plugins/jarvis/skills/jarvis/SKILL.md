---
name: jarvis
description: Control the Jarvis voice assistant plugin — mute/unmute speech, test or change voices, check status, run setup. Use when the user says things like "jarvis mute", "be quiet", "change your voice", "jarvis status", "set up jarvis".
---

# Jarvis voice control

Jarvis speaks through hooks (task summaries, permission requests, tool narration).
All control goes through one script: `${CLAUDE_PLUGIN_ROOT}/bin/jarvis`.

Map the user's request to a command and run it with Bash:

| User wants | Command |
|---|---|
| first-time install / repair | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" setup` |
| silence / stop talking | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" mute` |
| talk again | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" unmute` |
| hear a test line (optionally per engine) | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" test [edge\|piper\|espeak]` |
| say something specific | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" say "text"` |
| current settings / health | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" status` |
| list voices | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" voices` |
| change the online voice | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" voice en-GB-ThomasNeural` |
| change the offline voice | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" piper-voice en_US-ryan-high` |
| see recent errors | `"${CLAUDE_PLUGIN_ROOT}/bin/jarvis" log` |

Other settings (narration on/off, which tools to narrate, summary mode, how Jarvis
addresses the user, playback program) live in `~/.config/jarvis/config.sh` — edit that
file directly when asked; every key is documented in `${CLAUDE_PLUGIN_ROOT}/bin/jarvis-env`.

With no argument, `/jarvis` means: run `status` and report it briefly.
