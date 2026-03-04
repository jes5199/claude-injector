#!/usr/bin/env python3
"""Watch a session file; when written to, wait 1s, read, print, truncate, and exit."""

import atexit
import fcntl
import os
import sys
import time

WATCH_DIR = "/tmp/claude-injector"


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <session-id>", file=sys.stderr)
        sys.exit(1)

    session_id = sys.argv[1]
    os.makedirs(WATCH_DIR, exist_ok=True)

    path = os.path.join(WATCH_DIR, session_id)
    lockpath = path + ".lock"

    # Acquire exclusive lock (non-blocking) to prevent duplicate watchers
    lockfile = open(lockpath, "w")
    try:
        fcntl.flock(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit(0)  # Another instance is already watching

    # Create the watch file
    open(path, "a").close()

    def cleanup():
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
        try:
            fcntl.flock(lockfile, fcntl.LOCK_UN)
            lockfile.close()
            os.unlink(lockpath)
        except (OSError, FileNotFoundError):
            pass

    atexit.register(cleanup)

    # Poll until the file becomes non-empty
    while os.path.getsize(path) == 0:
        time.sleep(0.1)

    # Wait 1 second after detecting content
    time.sleep(1)

    with open(path, "r") as f:
        content = f.read().strip()

    if not content:
        return  # Nothing to inject — exit silently

    sys.stdout.write(f"[session: {session_id}] {content}")

    # Truncate the file
    with open(path, "w") as f:
        pass


if __name__ == "__main__":
    main()
