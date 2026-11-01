@echo off
setlocal
cd /d "%~dp0"

echo ================================================================
echo  Steam Frame 3D STL Inspector (Godot 4) - Windows SteamVR
echo ================================================================
echo.

if exist "steam_frame_godot_vr.exe" (
    echo [Launcher] Starting compiled executable steam_frame_godot_vr.exe...
    steam_frame_godot_vr.exe %*
) else if exist "dist\steam_frame_godot_vr.exe" (
    echo [Launcher] Starting compiled executable dist\steam_frame_godot_vr.exe...
    dist\steam_frame_godot_vr.exe %*
) else (
    echo [Launcher] Compiled .exe not found; running via Python...
    python steam_frame_godot_vr.py %*
)

if %errorlevel% neq 0 (
    echo.
    echo [Launcher] Application exited with code %errorlevel%.
    pause
)
