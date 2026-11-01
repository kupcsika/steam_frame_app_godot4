#!/usr/bin/env bash
# Sync steam_frame_app_godot4 to the Steam Frame using rsync.
# Strictly contained to ~/work/steam_frame_app_godot4/ on the remote host.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_HOST="${FRAME_HOST:-steamos@frame}"
REMOTE_DIR="${FRAME_DIR:-~/work/steam_frame_app_godot4}"

echo "=========================================================="
echo "Syncing Godot 4 Project to Steam Frame"
echo "Source : $SCRIPT_DIR"
echo "Target : $REMOTE_HOST:$REMOTE_DIR"
echo "=========================================================="

ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

rsync -avz --delete \
    --exclude '.git' \
    --exclude '.godot' \
    --exclude 'bin/godot.x86_64' \
    "$SCRIPT_DIR/" "$REMOTE_HOST:$REMOTE_DIR/"

echo "[sync.sh] Sync complete!"
