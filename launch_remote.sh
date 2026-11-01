#!/usr/bin/env bash
# Launch Steam Frame STL Inspector (Godot 4) remotely on the Steam Frame via SSH.
# Strictly contained to ~/work/steam_frame_app_godot4/ on the remote host.
#
# Usage:
#   ./launch_remote.sh --vr                   # Immersive 3D VR world mode (SteamVR OpenXR)
#   ./launch_remote.sh --vr model.stl         # Immersive 3D VR world with custom STL
#   ./launch_remote.sh                        # Gamescope desktop / floating window mode
#   ./launch_remote.sh --sync                 # Sync changes first, then launch
#   ./launch_remote.sh --test                 # Headless test run on frame

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_HOST="${FRAME_HOST:-steamos@frame}"
REMOTE_DIR="${FRAME_DIR:-~/work/steam_frame_app_godot4}"

DO_SYNC=false
VR_MODE=false
TEST_MODE=false
EXTRA_USER_ARGS=()
LOCAL_STL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sync|-s)
            DO_SYNC=true
            shift
            ;;
        --vr|-v|--world|--immersive)
            VR_MODE=true
            shift
            ;;
        --test)
            TEST_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--vr] [--sync] [--test] [stl_file]"
            exit 0
            ;;
        *)
            if [[ -f "$1" && "$1" == *.stl ]]; then
                LOCAL_STL="$1"
                shift
            else
                EXTRA_USER_ARGS+=("$1")
                shift
            fi
            ;;
    esac
done

echo "=========================================================="
echo "Steam Frame Remote Launcher (Godot 4)"
echo "Target Host : $REMOTE_HOST"
echo "Remote Dir  : $REMOTE_DIR"
echo "VR Mode     : $VR_MODE"
echo "=========================================================="

# 1. Test SSH connection
echo "[1/4] Verifying SSH connection to $REMOTE_HOST..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "echo 'Connected OK'" >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to $REMOTE_HOST via SSH."
    echo "Make sure the Steam Frame is powered on and Wi-Fi is connected."
    exit 1
fi
echo "SSH connection verified."

# 2. Sync codebase if requested or if remote dir doesn't exist
if [ "$DO_SYNC" = true ]; then
    echo "[2/4] Syncing codebase with rsync..."
    "$SCRIPT_DIR/sync.sh"
else
    echo "[2/4] Checking remote codebase directory..."
    if ! ssh -o BatchMode=yes "$REMOTE_HOST" "bash -c '[ -d $REMOTE_DIR ]'"; then
        echo "Remote directory $REMOTE_DIR does not exist yet. Syncing now..."
        "$SCRIPT_DIR/sync.sh"
    fi
fi

# 3. Transfer custom STL file if specified
REMOTE_STL_ARG=""
if [ -n "$LOCAL_STL" ]; then
    STL_NAME="$(basename "$LOCAL_STL")"
    REMOTE_STL_PATH="/tmp/$STL_NAME"
    echo "[3/4] Copying $LOCAL_STL to $REMOTE_HOST:$REMOTE_STL_PATH..."
    scp -o BatchMode=yes "$LOCAL_STL" "$REMOTE_HOST:$REMOTE_STL_PATH"
    REMOTE_STL_ARG="$REMOTE_STL_PATH"
else
    echo "[3/4] No custom STL specified. Godot will inspect built-in sample model."
fi

# 4. Construct Godot flags
GODOT_FLAGS=()
if [ "$VR_MODE" = true ]; then
    GODOT_FLAGS+=("--xr-mode" "on")
else
    GODOT_FLAGS+=("--xr-mode" "off")
fi

# Pass user arguments after '--'
USER_CLI_ARGS=()
if [ "$TEST_MODE" = true ]; then
    USER_CLI_ARGS+=("--test")
fi
if [ -n "$REMOTE_STL_ARG" ]; then
    USER_CLI_ARGS+=("$REMOTE_STL_ARG")
fi
if [ ${#EXTRA_USER_ARGS[@]} -gt 0 ]; then
    USER_CLI_ARGS+=("${EXTRA_USER_ARGS[@]}")
fi

USER_CLI_STR=""
if [ ${#USER_CLI_ARGS[@]} -gt 0 ]; then
    USER_CLI_STR="-- ${USER_CLI_ARGS[*]}"
fi

echo "[4/4] Launching Godot 4 on Steam Frame..."
ssh -t "$REMOTE_HOST" "bash -l -c '
    set -e
    cd $REMOTE_DIR

    export DISPLAY=\${DISPLAY:-:0}
    export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/1000}
    if [ -S \"/run/user/1000/gamescope-0\" ]; then
        export WAYLAND_DISPLAY=gamescope-0
    fi

    # Ensure executable permissions on ARM64 binary
    chmod +x bin/godot.arm64

    echo \"[Frame] Display set to \$DISPLAY (Wayland: \$WAYLAND_DISPLAY)\"
    echo \"[Frame] Starting Godot 4 STL Inspector...\"
    exec bin/godot.arm64 ${GODOT_FLAGS[*]} $USER_CLI_STR
'"
