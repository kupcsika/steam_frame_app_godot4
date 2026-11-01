#!/usr/bin/env bash
# Local launcher for Steam Frame STL Inspector (Godot 4)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GODOT_BIN="$SCRIPT_DIR/bin/godot.x86_64"

if [ ! -f "$GODOT_BIN" ]; then
    echo "ERROR: Godot binary not found at $GODOT_BIN"
    exit 1
fi

DRIVER_ARG=""
if [[ "$*" != *"--rendering-driver"* ]]; then
    DRIVER_ARG="--rendering-driver opengl3"
fi

exec "$GODOT_BIN" $DRIVER_ARG "$@"
