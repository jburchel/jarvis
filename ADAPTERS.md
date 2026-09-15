# Using Jarvis with any AI agent

Jarvis is three agent-neutral pieces plus one adapter per agent:

| Piece | What | Depends on |
|---|---|---|
| `omarchy-jarvis/bin/` | `jarvis say`, `jarvis hush`, `jarvis dictate`, `jarvis listen` — the voice | nothing agent-specific |
| `omarchy-jarvis/BarWidget.qml` | bar widget: state, mute, hush, wake word | the state file + `jarvis` CLI |
| `omarchy-jarvis/bin/jarvis-listen` | "Hey Jarvis" → hush → chime → dictation (Voxtype) | types into **whatever window is focused** |
| `plugins/jarvis/hooks/hooks.json` (this repo) | **the Claude Code adapter** | Claude Code hook events |

Nothing in the first three knows which LLM is running. Dictation lands in the focused
terminal regardless of who is reading it. To make Jarvis *speak for* another agent, that
agent just needs to call the CLI at the right moments.

## The contract

```
jarvis say "text"          # speak, queued behind anything already playing
jarvis say --low "text"    # speak only if idle; drop otherwise (tool narration)
jarvis hush                # stop now, drop the queue
jarvis state               # idle | speaking | listening | muted | off
```

Text is cleaned of markdown by the caller (see `plugins/jarvis/bin/jarvis-hook`'s `clean()` if
you want to copy it). Pronunciation fixes in `~/.config/jarvis/pronounce.txt` apply to every caller.

## Adapters

### Claude Code (shipped)
`plugins/jarvis/hooks/hooks.json` → `bin/jarvis-hook`. Events: `Stop` (summary),
`Notification` (approval / input needed), `PreToolUse` (narration), `SessionStart` (greeting).

### OpenAI Codex CLI
Codex has a `notify` hook in `~/.codex/config.toml` that runs a program with a JSON payload
when a turn completes:

```toml
notify = ["/path/to/codex-notify.sh"]
```

```bash
#!/bin/bash
# codex-notify.sh — Codex calls this with one JSON argument.
payload="$1"
type="$(printf '%s' "$payload" | jq -r '.type // empty')"
case "$type" in
  agent-turn-complete)
    msg="$(printf '%s' "$payload" | jq -r '."last-assistant-message" // empty')"
    [ -n "$msg" ] && jarvis say "$(printf '%s' "$msg" | head -c 400)" ;;
esac
```

Verify the payload field names against the Codex version you run — they have changed.

### Gemini CLI / OpenCode / others with hooks
Same shape: on "turn finished" → `jarvis say "<last message>"`; on "needs approval" →
`jarvis say "Sir, I need your approval."`; on "tool starting" → `jarvis say --low "<what>"`.
Check the agent's hook docs for event names and payload fields.

### Anything without hooks
Wrap the agent and speak its final output:

```bash
some-agent "$@" | tee /dev/tty | tail -n 5 | jarvis say
```

Crude, but it works for one-shot CLIs.

## Making the wake word target a specific agent
By default "Hey Jarvis" starts dictation into the focused window. If you want it to also
focus a particular terminal first, set in `~/.config/jarvis/config.sh`:

```sh
JARVIS_DICTATE_CMD="hyprctl dispatch focuswindow class:Alacritty; voxtype record toggle"
```
