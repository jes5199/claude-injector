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

REASON=""

# Check if watcher needs starting
(
    flock -n 9 || exit 1
    exit 0
) 9>"$LOCKFILE"

if [ $? -eq 0 ]; then
    REASON="Please run the claude-injector watcher as a background process: uv run /home/jes/claude-injector/watch.py ${SESSION_ID}. When the watcher exits, read its output file to see the injected message."
fi

# Check for pending IRC invite
IRC_INVITE="/tmp/claude-chat/invites/${SESSION_ID}"
if [ -f "$IRC_INVITE" ]; then
    INVITE_MSG=$(cat "$IRC_INVITE")
    rm -f "$IRC_INVITE"
    if [ -n "$REASON" ]; then
        REASON="${REASON}. Also: ${INVITE_MSG}"
    else
        REASON="${INVITE_MSG}"
    fi
fi

if [ -n "$REASON" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"${REASON}\"}"
fi

exit 0
