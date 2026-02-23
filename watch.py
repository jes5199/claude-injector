#!/usr/bin/env python3
"""Watch an empty file; when written to, wait 1s, read, print, truncate, and exit."""

import sys
import time
import os


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <file>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]

    if not os.path.exists(path):
        print(f"Error: {path} does not exist", file=sys.stderr)
        sys.exit(1)

    # Poll until the file becomes non-empty
    while os.path.getsize(path) == 0:
        time.sleep(0.1)

    # Wait 1 second after detecting content
    time.sleep(1)

    with open(path, "r") as f:
        content = f.read()

    sys.stdout.write(content)

    # Truncate the file
    with open(path, "w") as f:
        pass


if __name__ == "__main__":
    main()
