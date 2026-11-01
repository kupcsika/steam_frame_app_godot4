"""
Steam Frame 3D STL Inspector (Godot 4) - Windows Edition
=========================================================
Launches the Godot 4 PBR 3D STL Inspector on Windows 11 and streams
the immersive 6-DoF scene directly to the Valve Steam Frame via SteamVR OpenXR.

Features:
- High-fidelity Physically Based Rendering (PBR) with SSAO, SSR, and studio lighting.
- OpenXR 6-DoF roomscale head tracking and Steam Frame hand controller interaction.
- Automatic SteamVR detection and launch assistance.
- Graceful connection retry if the Steam Frame is powered off or reconnecting.
- Instant fallback to desktop 3D viewer if VR is unavailable or on user request.
- Drag-and-drop support for .stl files in Windows Explorer.
"""

import argparse
import os
import subprocess
import sys
import time

# Ensure high-DPI scaling on Windows displays
if sys.platform == "win32":
    try:
        import ctypes
        ctypes.windll.shcore.SetProcessDpiAwareness(2)  # Per-monitor DPI aware
    except Exception:
        try:
            import ctypes
            ctypes.windll.user32.SetProcessDPIAware()
        except Exception:
            pass

# Robust path resolution for both Python script and PyInstaller frozen executable
if getattr(sys, "frozen", False):
    WINDOWS_DIR = os.path.dirname(os.path.abspath(sys.executable))
else:
    WINDOWS_DIR = os.path.dirname(os.path.abspath(__file__))

REPO_ROOT = os.path.abspath(os.path.join(WINDOWS_DIR, ".."))

try:
    import openvr
    HAVE_OPENVR = True
except ImportError:
    openvr = None
    HAVE_OPENVR = False


def find_godot_binary() -> str:
    """Locate Godot 4 Windows executable."""
    candidates = [
        os.path.join(WINDOWS_DIR, "bin", "godot_console.exe"),
        os.path.join(WINDOWS_DIR, "bin", "godot.exe"),
        os.path.join(REPO_ROOT, "bin", "godot_console.exe"),
        os.path.join(REPO_ROOT, "bin", "godot.exe"),
    ]

    # Check winget packages
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        winget_pattern = os.path.join(local_app_data, "Microsoft", "WinGet", "Packages")
        if os.path.exists(winget_pattern):
            for root, _, files in os.walk(winget_pattern):
                if "GodotEngine" in root:
                    for f in files:
                        if f.startswith("Godot") and f.endswith(".exe"):
                            candidates.append(os.path.join(root, f))

    for c in candidates:
        if os.path.exists(c):
            return os.path.abspath(c)

    # Check PATH
    import shutil
    for name in ["godot_console.exe", "godot.exe", "godot"]:
        which = shutil.which(name)
        if which:
            return which

    raise FileNotFoundError(
        "Godot 4 executable not found. Please ensure godot.exe is placed in windows\\bin\\godot.exe"
    )


def is_steamvr_running() -> bool:
    """Check if SteamVR vrserver process is currently running on Windows."""
    try:
        output = subprocess.check_output(
            'tasklist /FI "IMAGENAME eq vrserver.exe" /NH',
            shell=True,
            text=True,
            stderr=subprocess.DEVNULL
        )
        return "vrserver.exe" in output.lower()
    except Exception:
        return False


def launch_steamvr_service() -> bool:
    """Trigger Steam to launch SteamVR runtime via steam:// URI."""
    try:
        print("[SteamVR] Requesting Steam to start SteamVR...")
        os.startfile("steam://rungameid/250820")
        print("[SteamVR] Waiting for vrserver to initialize...")
        for _ in range(15):
            time.sleep(1.0)
            if is_steamvr_running():
                print("[SteamVR] vrserver.exe is now running.")
                time.sleep(2.0)
                return True
        return is_steamvr_running()
    except Exception as e:
        print(f"[SteamVR] Could not automatically trigger SteamVR launch: {e}")
        return False


def check_vr_ready() -> tuple[bool, str]:
    """
    Probe OpenVR to check if the Steam Frame headset is connected and ready.
    Returns (is_ready, message).
    """
    if not HAVE_OPENVR:
        return True, "OpenVR Python probe not available; launching Godot OpenXR directly."

    try:
        vr = openvr.init(openvr.VRApplication_Scene)
        openvr.shutdown()
        return True, "Headset connected."
    except openvr.OpenVRError as err:
        err_name = type(err).__name__
        err_msg = str(err).strip()
        if "WirelessHmdNotConnected" in err_name or "HmdNotFound" in err_name:
            return False, "Steam Frame headset is currently powered off or disconnected."
        elif "NoServer" in err_name:
            return False, "SteamVR runtime server is not responding."
        return False, f"{err_name}: {err_msg}"
    except Exception as e:
        return False, str(e)


def run_godot(vr_mode: bool, stl_file: str = None, test: bool = False, extra_args: list = None):
    """Execute the Godot 4 project with configured arguments."""
    godot_bin = find_godot_binary()

    cmd = [godot_bin, "--path", REPO_ROOT]

    if vr_mode:
        cmd.extend(["--xr-mode", "on"])
    else:
        cmd.extend(["--xr-mode", "off"])

    # User-space CLI arguments passed to Godot scripts via '--'
    user_args = []
    if test:
        user_args.append("--test")

    if stl_file:
        cleaned_stl = os.path.abspath(stl_file.strip('\'"'))
        if os.path.exists(cleaned_stl):
            user_args.append(cleaned_stl)
        else:
            print(f"[Warning] Specified STL file '{cleaned_stl}' not found. Loading default sample.")

    if extra_args:
        user_args.extend(extra_args)

    if user_args:
        cmd.append("--")
        cmd.extend(user_args)

    mode_label = "OpenXR (Immersive VR)" if vr_mode else "Desktop 2D Showroom"
    print("\n" + "=" * 70)
    print(f" Launching Godot 4 STL Inspector ({mode_label})")
    print(f" Engine binary : {godot_bin}")
    print(f" Project path  : {REPO_ROOT}")
    if stl_file:
        print(f" Target Model  : {stl_file}")
    else:
        print(f" Target Model  : res://sample.stl (Default Showroom Model)")
    print("=" * 70 + "\n")

    proc = subprocess.run(cmd)
    return proc.returncode


def main():
    parser = argparse.ArgumentParser(
        prog="steam_frame_godot_vr",
        description="Steam Frame 3D STL Inspector (Godot 4 Windows Edition) - Stream 6-DoF PBR VR to Valve Steam Frame via SteamVR."
    )
    parser.add_argument(
        "stl_file",
        nargs="?",
        default=None,
        help="Path to .stl file (binary or ASCII). If omitted, default sample model is loaded."
    )
    parser.add_argument(
        "--desktop", "-d",
        action="store_true",
        help="Launch in Desktop 2D showroom mode without VR."
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Automated test mode (runs 30 frames and exits)."
    )

    args, unknown = parser.parse_known_args()

    # Desktop mode requested explicitly
    if args.desktop:
        ret = run_godot(vr_mode=False, stl_file=args.stl_file, test=args.test, extra_args=unknown)
        sys.exit(ret)

    # Check if SteamVR is running
    if not is_steamvr_running():
        print("=" * 70)
        print(" [SteamVR] Notice: SteamVR is not currently running.")
        print("=" * 70)
        if not args.test:
            ans = input(" Would you like to launch SteamVR now? [Y/n]: ").strip().lower()
            if ans in ("", "y", "yes"):
                launch_steamvr_service()

    # Verify headset connection status
    while True:
        ready, msg = check_vr_ready()

        if ready:
            print(f"[SteamVR] Headset check OK: {msg}")
            ret = run_godot(vr_mode=True, stl_file=args.stl_file, test=args.test, extra_args=unknown)
            sys.exit(ret)

        # Headset is disconnected or powered off
        print("\n" + "!" * 70)
        print(f" [SteamVR Status] {msg}")
        print(" >> Please turn ON your Steam Frame headset and ensure Steam Link is connected.")
        print("!" * 70)

        if args.test:
            print("[Test Mode] Falling back to desktop test because VR is unavailable.")
            ret = run_godot(vr_mode=False, stl_file=args.stl_file, test=True, extra_args=unknown)
            sys.exit(ret)

        print("\nOptions:")
        print("  [Enter] Retry connection (after turning on your Steam Frame)")
        print("  [D]     Open Desktop 3D Preview (keyboard / mouse / gamepad)")
        print("  [Q]     Quit")
        choice = input("\nSelect option: ").strip().lower()

        if choice in ("d", "desktop"):
            ret = run_godot(vr_mode=False, stl_file=args.stl_file, test=False, extra_args=unknown)
            sys.exit(ret)
        elif choice in ("q", "quit", "exit"):
            print("[Info] Exiting.")
            sys.exit(0)
        else:
            print("[Info] Retrying SteamVR headset status...")
            time.sleep(1.5)


if __name__ == "__main__":
    main()
