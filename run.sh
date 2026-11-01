#!/usr/bin/env bash
# Local launcher for Steam Frame STL Inspector (Godot 4)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GODOT_BIN="$SCRIPT_DIR/bin/godot.x86_64"

if [ ! -f "$GODOT_BIN" ]; then
    echo "[run.sh] Godot binary not found. Downloading Godot 4.7.2 for Linux x86_64..."
    mkdir -p "$SCRIPT_DIR/bin"
    curl -L -o "$SCRIPT_DIR/bin/godot.zip" "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip"
    unzip -q "$SCRIPT_DIR/bin/godot.zip" -d "$SCRIPT_DIR/bin"
    mv "$SCRIPT_DIR/bin/Godot_v4.7.2-stable_linux.x86_64" "$GODOT_BIN"
    chmod +x "$GODOT_BIN"
    rm -f "$SCRIPT_DIR/bin/godot.zip"
fi

DRIVER_ARG=""
if [[ "$*" != *"--rendering-driver"* ]]; then
    DRIVER_ARG="--rendering-driver opengl3"
fi

exec "$GODOT_BIN" $DRIVER_ARG "$@"
