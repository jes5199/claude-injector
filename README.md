# claude-injector

Inject text into a running Claude Code session. A file watcher runs in the background via a Claude Code [stop hook](https://docs.anthropic.com/en/docs/claude-code/hooks). When you write to the session's watch file, the content is printed to Claude's terminal, effectively injecting it into the conversation.

## How it works

1. A **stop hook** runs after every Claude response, ensuring a watcher process is alive for the current session.
2. **watch.py** creates `/tmp/claude-injector/{session-id}`, then polls it for content.
3. When the file is written to, it waits 1 second, reads the content, prints it to stdout, truncates the file, cleans up, and exits.
4. The next time Claude responds, the stop hook starts a fresh watcher.

Duplicate watchers for the same session are prevented via `fcntl.flock`.

## Setup

### Prerequisites

- [uv](https://docs.astral.sh/uv/)
- `jq`

### Install

1. Clone this repo somewhere permanent:

   ```bash
   git clone <repo-url> ~/claude-injector
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

The watcher prints the content to the terminal and deletes the file.

## Standalone usage

You can also run the watcher directly:

```bash
uv run watch.py <session-id>
```

This creates `/tmp/claude-injector/<session-id>`, waits for content, prints it, and cleans up on exit.
