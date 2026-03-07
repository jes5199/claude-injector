#!/bin/bash
# Resume the last Claude Code session in this directory, or start a new one.
SESSION_FILE=".claude/last-session-id"

if [ -f "$SESSION_FILE" ]; then
    SESSION_ID=$(cat "$SESSION_FILE")
    if [ -n "$SESSION_ID" ]; then
        exec claude --resume "$SESSION_ID"
    fi
fi

exec claude
