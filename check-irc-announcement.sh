#!/bin/bash
# Stop hook: remind agents to share completed work in IRC.
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')

# Don't recurse
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

# Trigger when the assistant's last message mentions completing work
case "$LAST_MSG" in
    *[Cc]ommitted*|*[Pp]ushed*|*"bd close"*|*[Cc]losed*|*[Mm]erged*) ;;
    *) exit 0 ;;
esac

cat <<'EOF'
{"decision":"block","reason":"If this wraps up a piece of work, consider sharing what you accomplished in #loom (send_irc_message). Your teammates benefit from knowing what changed and why. No need if it's just a small intermediate step."}
EOF
