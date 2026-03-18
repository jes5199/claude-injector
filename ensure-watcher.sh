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

WATCHDIR="/tmp/friendly-claude-message-alerts"
LOCKFILE="${WATCHDIR}/${SESSION_ID}.lock"

mkdir -p "$WATCHDIR"

REASON=""

# PID-based check: is a watcher already running for this session?
NEEDS_WATCHER=true
if [ -f "$LOCKFILE" ]; then
    OLD_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        NEEDS_WATCHER=false
    fi
fi

if [ "$NEEDS_WATCHER" = "true" ]; then
    REASON="Please run the friendly-claude-message-alerts watcher as a background process: uv run /home/jes/friendly-claude-message-alerts/watch.py ${SESSION_ID}. When the watcher exits, read its output file to see the injected message."
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
