#!/usr/bin/env python3
"""Watch a session file; when written to, wait 1s, read, print, truncate, and exit."""

import os
import signal
import sys
import time

WATCH_DIR = "/tmp/claude-injector"


def is_pid_alive(pid):
    """Check if a process with the given PID is still running."""
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <session-id>", file=sys.stderr)
        sys.exit(1)

    session_id = sys.argv[1]
    os.makedirs(WATCH_DIR, exist_ok=True)

    path = os.path.join(WATCH_DIR, session_id)
    lockpath = path + ".lock"

    # PID-based locking: check if an existing watcher is still alive
    if os.path.exists(lockpath):
        try:
            with open(lockpath, "r") as f:
                old_pid = int(f.read().strip())
            if is_pid_alive(old_pid):
                sys.exit(0)  # Another instance is still running
        except (ValueError, FileNotFoundError):
            pass  # Stale/corrupt lockfile — take over

    # Write our PID to the lockfile
    with open(lockpath, "w") as f:
        f.write(str(os.getpid()))

    # Create the watch file
    open(path, "a").close()

    def cleanup(*args):
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
        try:
            os.unlink(lockpath)
        except FileNotFoundError:
            pass
        if args:  # Called from signal handler
            sys.exit(0)

    # Register cleanup for both normal exit and signals
    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    # Poll until the file becomes non-empty
    while os.path.getsize(path) == 0:
        time.sleep(0.1)

    # Wait 1 second after detecting content
    time.sleep(1)

    with open(path, "r") as f:
        content = f.read().strip()

    if not content:
        cleanup()
        return  # Nothing to inject — exit silently

    sys.stdout.write(f"[session: {session_id}] {content}")

    # Truncate the file
    with open(path, "w") as f:
        pass

    cleanup()


if __name__ == "__main__":
    main()
