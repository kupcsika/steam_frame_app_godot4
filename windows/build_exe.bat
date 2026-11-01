@echo off
setlocal
echo ================================================================
echo  Building Steam Frame Godot VR Inspector Standalone Windows EXE
echo ================================================================

cd /d "%~dp0"

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [Error] Python is not installed or not in PATH.
    pause
    exit /b 1
)

echo [1/2] Compiling standalone executable with PyInstaller...
python -m PyInstaller --clean --noconfirm steam_frame_godot_vr.spec

if exist "dist\steam_frame_godot_vr.exe" (
    copy /y "dist\steam_frame_godot_vr.exe" "steam_frame_godot_vr.exe" >nul
    echo.
    echo ================================================================
    echo [2/2] Build succeeded!
    echo Executable generated: %~dp0steam_frame_godot_vr.exe
    echo ================================================================
    echo.
    echo You can now launch steam_frame_godot_vr.exe directly
    echo or drag-and-drop any .stl file onto it.
) else (
    echo.
    echo [Error] PyInstaller build failed.
    pause
    exit /b 1
)

pause
