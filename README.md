# claude-injector

Inject text into a running Claude Code session from outside the UI.

A [stop hook](https://docs.anthropic.com/en/docs/claude-code/hooks) checks after each Claude response whether a file watcher is running. If not, it asks Claude to start one as a background process. When you write to the session's watch file, the watcher picks up the content and delivers it to Claude as a background task completion — effectively injecting a message into the conversation.

## How it works

1. A **stop hook** (`ensure-watcher.sh`) runs after every Claude response. It checks whether a watcher process holds a lock for the current session.
2. If no watcher is running, the hook returns a `block` decision that asks Claude to start one as a background process.
3. Claude runs **`watch.py`** in the background with the session ID. The watcher creates `/tmp/claude-injector/{session-id}` and polls it for content.
4. When the file is written to, the watcher waits 1 second, reads the content, prints it to stdout (delivered as background task output), truncates the file, cleans up, and exits.
5. On the next response, the stop hook starts a fresh watcher.

Duplicate watchers are prevented via `fcntl.flock`.

## Limitations

- Injection is delivered when Claude is **idle** (waiting for user input). If Claude is mid-turn (running tools, generating a response), the message is queued and delivered after the turn completes.
- The watcher exits after each injection, so there's a brief gap before the stop hook starts a new one.

## Setup

### Prerequisites

- [uv](https://docs.astral.sh/uv/)
- `jq`

### Install

1. Clone this repo:

   ```bash
   git clone https://github.com/jes5199/claude-injector.git ~/claude-injector
   ```

2. Make the hook script executable (should already be, but just in case):

   ```bash
   chmod +x ~/claude-injector/ensure-watcher.sh
   ```

3. Add a `Stop` hook to your Claude Code settings. Edit `~/.claude/settings.json` and merge a `Stop` entry into the existing `hooks` object (create `hooks` if it doesn't exist):

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "/absolute/path/to/claude-injector/ensure-watcher.sh"
             }
           ]
         }
       ]
     }
   }
   ```

   **Important:** The `command` must be an absolute path. Update it to match where you cloned the repo.

4. Restart Claude Code (or start a new session) for the hook to take effect.

## Usage

Find your session's watch file:

```bash
ls /tmp/claude-injector/
```

Write to it to inject text into that session:

```bash
echo "hello from outside" > /tmp/claude-injector/<session-id>
```

The watcher delivers the content to Claude as a background task completion.
