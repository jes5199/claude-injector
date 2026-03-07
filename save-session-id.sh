#!/bin/bash
# SessionStart hook: save the session ID so we can resume after crashes.
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

if [ -n "$SESSION_ID" ]; then
    mkdir -p .claude
    echo "$SESSION_ID" > .claude/last-session-id
fi
