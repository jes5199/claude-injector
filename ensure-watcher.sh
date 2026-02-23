#!/bin/bash
# Stop hook: ensure watch.py is running for this session
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# watch.py handles file creation, locking, and dedup — just start it
nohup uv run /home/jes/claude-injector/watch.py "$SESSION_ID" > /dev/tty 2>&1 &

exit 0
