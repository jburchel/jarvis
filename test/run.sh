#!/bin/bash
# test/run.sh — feed Claude Code hook payloads to bin/jarvis-hook against a fake core
# and check what would have been spoken. Runs on bash 3.2 (macOS) and 5. Needs jq, python3.
#   ./test/run.sh        run all
#   ./test/run.sh -v     also print every spoken line
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/plugins/jarvis/bin/jarvis-hook"
export JARVIS_CORE="$ROOT/test/fakecore"
verbose=0; [ "$1" = -v ] && verbose=1
pass=0; fail=0

fresh() { # fresh — new cache dir per test so sessions/debounce state don't leak
  JARVIS_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-test.XXXXXX")"; export JARVIS_CACHE
  export JARVIS_SUMMARY=heuristic JARVIS_SESSION_TAG=auto JARVIS_SESSION_WINDOW=600 \
         JARVIS_IDLE_ALERT=1 JARVIS_CONVERSE=0
}
run() { # run <event> <json>  — invoke the hook
  printf '%s' "$2" | "$HOOK" "$1"
}
spoken() { cat "$JARVIS_CACHE/spoken" 2>/dev/null; }
check() { # check <name> <regex>  — against the LAST spoken line
  local got; got="$(spoken | tail -n 1)"
  if printf '%s' "$got" | grep -qE -- "$2"; then
    pass=$((pass + 1)); [ "$verbose" = 1 ] && printf '  ok   %s\n       %s\n' "$1" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %s\n  want /%s/\n  got  %s\n' "$1" "$2" "${got:-<nothing>}"
  fi
}
check_log() { # check_log <name> <exact whole log>
  local got; got="$(spoken)"
  if [ "$got" = "$2" ]; then
    pass=$((pass + 1)); [ "$verbose" = 1 ] && printf '  ok   %s\n       %s\n' "$1" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %s\n  want %s\n  got  %s\n' "$1" "$2" "${got:-<nothing>}"
  fi
}
check_not() { # check_not <name> <substring that must be absent>
  if spoken | grep -qF -- "$2"; then fail=$((fail + 1)); printf 'FAIL   %s\n  must not contain %s\n' "$1" "$2"
  else pass=$((pass + 1)); [ "$verbose" = 1 ] && printf '  ok   %s\n' "$1"; fi
}
check_any() { # check_any <name> <regex>  — some spoken line matches
  if spoken | grep -qE -- "$2"; then pass=$((pass + 1)); [ "$verbose" = 1 ] && printf '  ok   %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL   %s\n  want /%s/ somewhere in\n  %s\n' "$1" "$2" "$(spoken)"; fi
}
check_silent() { # check_silent <name>
  if [ -z "$(spoken)" ]; then pass=$((pass + 1)); [ "$verbose" = 1 ] && printf '  ok   %s (silent)\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL   %s\n  want silence\n  got  %s\n' "$1" "$(spoken)"; fi
}
payload() { # payload <event> <session> <cwd> [jq-args...]  — hook JSON with the common fields
  local ev="$1" sid="$2" cwd="$3"; shift 3
  jq -cn --arg _ev "$ev" --arg _sid "$sid" --arg _cwd "$cwd" "$@" \
    '{hook_event_name:$_ev, session_id:$_sid, cwd:$_cwd, transcript_path:"/dev/null"} + $ARGS.named
     | del(._ev, ._sid, ._cwd)'
}
stop_msg() { payload Stop "${2:-s1}" "${3:-/home/me/CG-One}" --arg last_assistant_message "$1"; }

# --- stop: short reply is read as-is, with --replace --------------------------------
fresh
run stop "$(stop_msg 'Done. Tests pass.')"
check "short reply read verbatim" '^--replace Done\. Tests pass\.$'

# --- stop: markdown is cleaned ----------------------------------------------------
fresh
run stop "$(stop_msg '## Fixed ✅

Edited `src/api/donors.ts:42` and `/Users/me/.config/jarvis/config.sh` — see [the PR](https://github.com/x/y/pull/1) and/or `README.md`.

| Where | Change |
|---|---|
| config.sh | 1.5 s |

```bash
rm -rf /
```
- **Bold** item → done 🎉')"
check "heading gets a stop, emoji dropped"     'Fixed\. Edited'
check "paths collapse to basename"            'Edited donors\.ts and config\.sh'
check "and/or survives, links become text"    'see the PR and/or README\.md'
check "table rows read as cells"              'Where, Change\. config\.sh, 1\.5 s\.'
check_not "code fences dropped"               'rm -rf'
check "bullets + arrows"                      'Bold item to done\.$'

# --- stop: long reply → first two sentences, question preserved ---------------------
fresh
long="$(python3 -c 'print("This sentence pads the reply out well past the short limit so the heuristic path is taken. " * 4)')"
run stop "$(stop_msg "${long}Second bit. Shall I push it to main?")"
check "heuristic keeps 2 sentences"  '^--replace This sentence pads.*taken\. This sentence pads.*taken\.'
check "trailing question appended"   'taken\. Shall I push it to main\?$'

fresh
run stop "$(stop_msg "Want me to push it? ${long}")"
check "no duplicate when question already spoken" '^--replace Want me to push it\? This sentence.*taken\.$'

fresh
run stop "$(stop_msg "${long}")"
check "no question, nothing appended" 'taken\. This sentence pads[^?]*taken\.$'

# --- stop: session tagging ---------------------------------------------------------
fresh
run stop "$(stop_msg 'Done.' s1 /home/me/CG-One)"
check "single session: no tag" '^--replace Done\.$'
run stop "$(stop_msg 'Also done.' s2 /home/me/omarchy-jarvis)"
check "second session within window: tagged" '^--replace omarchy jarvis: Also done\.$'
run stop "$(stop_msg 'And again.' s1 /home/me/CG-One)"
check "first session now tagged too" '^--replace CG One: And again\.$'

fresh; export JARVIS_SESSION_TAG=always
run stop "$(stop_msg 'Done.' s1 /home/me/CG-One)"
check "always: tagged alone" '^--replace CG One: Done\.$'

fresh; export JARVIS_SESSION_TAG=never
run stop "$(stop_msg 'Done.' s1 /home/me/a)"; run stop "$(stop_msg 'Done.' s2 /home/me/b)"
check_log "never: no tag with two sessions" '--replace Done.
--replace Done.'

fresh; export JARVIS_SESSION_WINDOW=1
run stop "$(stop_msg 'Done.' s1 /home/me/a)"; sleep 2
run stop "$(stop_msg 'Done.' s2 /home/me/b)"
check_log "other session outside window: no tag" '--replace Done.
--replace Done.'

# --- notification --------------------------------------------------------------------
fresh
run notification "$(payload Notification s1 /home/me/CG-One --arg notification_type permission_prompt --arg message 'Claude needs your permission to use Bash')"
check "permission prompt" '^Sir, I need your approval to use Bash\.$'
run notification "$(payload Notification s2 /home/me/other --arg notification_type permission_prompt --arg message 'Claude needs your permission to use Edit')"
check "permission prompt tagged when another session is live" '^other: Sir, I need your approval to use Edit\.$'
fresh
run notification "$(payload Notification s1 /x --arg notification_type idle_prompt --arg message 'x')"
check "idle prompt" '^Awaiting your input, sir\.$'
fresh; export JARVIS_IDLE_ALERT=0
run notification "$(payload Notification s1 /x --arg notification_type idle_prompt --arg message 'x')"
check_silent "idle prompt off"

# --- pre-tool narration ------------------------------------------------------------
fresh
run pre-tool "$(payload PreToolUse s1 /x --arg tool_name Bash --argjson tool_input '{"command":"npm test","description":"Run the test suite"}')"
check "bash narrates its description" '^--low Run the test suite$'
run pre-tool "$(payload PreToolUse s1 /x --arg tool_name Edit --argjson tool_input '{"file_path":"/a/b/config.sh"}')"
check "edit narrates basename sans extension" '^--low Editing config$'
run pre-tool "$(payload PreToolUse s1 /x --arg tool_name Edit --argjson tool_input '{"file_path":"/a/b/config.sh"}')"
check_log "identical line debounced" '--low Run the test suite
--low Editing config'
run pre-tool "$(payload PreToolUse s1 /x --arg tool_name Read --argjson tool_input '{"file_path":"/a"}')"
check_log "un-narrated tool stays silent" '--low Run the test suite
--low Editing config'
run pre-tool "$(payload PreToolUse s1 /x --arg tool_name WebFetch --argjson tool_input '{"url":"https://docs.example.com/a/b"}')"
check "webfetch narrates host" '^--low Fetching docs\.example\.com$'

# --- hush on new prompt / session end, even when muted -----------------------------
fresh
run prompt-submit "$(payload UserPromptSubmit s1 /x --arg prompt 'hello')"
check "prompt submit hushes" '^jarvis hush$'
fresh; mkdir -p "$JARVIS_CACHE/config"; touch "$JARVIS_CACHE/config/muted"
run session-end "$(payload SessionEnd s1 /x --arg reason exit)"
check_log "session end hushes while muted" 'jarvis hush'
run stop "$(stop_msg 'Done.')"
check_log "muted: stop stays silent" 'jarvis hush'

# --- conversational mode: mic opens after a spoken reply, not after a dropped one -----
converse_wait() { sleep 0.3; } # `jarvis converse` is launched detached
fresh; export JARVIS_CONVERSE=1
run stop "$(stop_msg 'Done.')"; converse_wait
check_log "converse after spoken reply" '--replace Done.
jarvis converse'
fresh; export JARVIS_CONVERSE=1
run stop "$(stop_msg 'Done. [drop]')"; converse_wait
check_log "no converse after a dropped (superseded) line" '--replace Done. [drop]'
fresh; export JARVIS_CONVERSE=1; mkdir -p "$JARVIS_CACHE/config"; touch "$JARVIS_CACHE/config/paused"
run stop "$(stop_msg 'Done.')"; converse_wait
check_log "no converse while paused" '--replace Done.'
fresh; export JARVIS_CONVERSE=0
run stop "$(stop_msg 'Done.')"; converse_wait
check_log "converse off" '--replace Done.'
fresh; export JARVIS_CONVERSE=1
run notification "$(payload Notification s1 /x --arg notification_type idle_prompt --arg message x)"; converse_wait
check_log "converse after idle prompt" 'Awaiting your input, sir.
jarvis converse'


# --- tour ---------------------------------------------------------------------------
TOUR="$ROOT/plugins/jarvis/bin/jarvis-tour"
fresh
"$TOUR" --outline | grep -q '^listening ' && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   tour outline"; }
"$TOUR" --text | grep -q 'I am Jarvis' && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   tour --text"; }
check_silent "tour --text speaks nothing"
"$TOUR" intro >/dev/null
check "tour intro spoken" '^Everything I do is one of three things'
[ "$(spoken | wc -l | tr -d ' ')" = 2 ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   tour intro is two paragraphs: $(spoken | wc -l)"; }
fresh; FAKE_WAKE="active (pid 1)" "$TOUR" listening >/dev/null
check_any "tour adapts to wake word on" '^Third, listening\. The wake word is on\.'
# Paragraphs that say "Hey Jarvis" would wake the listener and hush the tour: the
# listener is stopped just for those lines, then started again.
fresh; FAKE_WAKE="active (pid 1)" "$TOUR" listening >/dev/null
[ "$(spoken | sed -n '1p;2p;3p' | cut -c1-18 | tr '\n' '|')" = "jarvis listen stop|Third, listening. |jarvis listen star|" ] \
  && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   tour shuts the listener's ears around the wake phrase: $(spoken | head -3)"; }
[ "$(spoken | grep -c '^jarvis listen stop')" = "$(spoken | grep -c '^jarvis listen start')" ] \
  && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   every listen stop has a matching start"; }
fresh; FAKE_WAKE="active (pid 1)" "$TOUR" voice >/dev/null
spoken | grep -q '^jarvis listen' && { fail=$((fail + 1)); echo "FAIL   no wake phrase, listener left alone"; } || pass=$((pass + 1))
fresh; "$TOUR" listening >/dev/null
spoken | grep -q '^jarvis listen' && { fail=$((fail + 1)); echo "FAIL   wake word off, listener left alone"; } || pass=$((pass + 1))
fresh; "$TOUR" bogus >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL   tour rejects unknown section"; } || pass=$((pass + 1))
fresh; FAKE_HUSH=1 "$TOUR" intro speaking | grep -q '(tour interrupted)' && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   tour stops on hush"; }
[ "$(spoken | wc -l | tr -d ' ')" = 1 ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL   hushed tour spoke only one paragraph: $(spoken | wc -l)"; }
fresh; echo $$ > "$JARVIS_CACHE/tour.pid"
run stop "$(stop_msg 'Starting the tour.')"
check_silent "stop hook is silent while a tour is playing"
echo 999999 > "$JARVIS_CACHE/tour.pid"
run stop "$(stop_msg 'Done.')"
check "stale tour pid is ignored" '^--replace Done\.$'

# --- session start / recursion guard -------------------------------------------------
fresh
run session-start "$(payload SessionStart s1 /x --arg source startup)"
check "greeting" '^Good (morning|afternoon|evening), sir\. Jarvis is online\.$'
fresh
JARVIS_SILENT=1 run stop "$(stop_msg 'Done.')"
check_silent "JARVIS_SILENT child never speaks"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
