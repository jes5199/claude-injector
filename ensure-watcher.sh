#!/bin/bash
# Stop hook: check if watch.py is running for this session.
# If not, ask Claude to start it as a background process.
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')

# Don't recurse — if we're already in a hook-triggered response, bail
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

WATCHDIR="/tmp/claude-injector"
LOCKFILE="${WATCHDIR}/${SESSION_ID}.lock"

mkdir -p "$WATCHDIR"

# Try to grab the lock. If we succeed, no watcher holds it — ask Claude to start one.
# If we fail, a watcher is already running.
(
    flock -n 9 || exit 1
    # We got the lock — no watcher is running
    exit 0
) 9>"$LOCKFILE"

if [ $? -eq 0 ]; then
    echo '{"decision":"block","reason":"Please run the claude-injector watcher as a background process: uv run /home/jes/claude-injector/watch.py '"$SESSION_ID"'"}'
fi

exit 0
