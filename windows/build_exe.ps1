# PowerShell Build Script for Steam Frame Godot VR Inspector (Windows Standalone EXE)
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Building Steam Frame Godot VR Inspector Standalone Windows EXE " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Check Python
$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    Write-Host "[Error] Python not found in PATH." -ForegroundColor Red
    Exit 1
}

# Run PyInstaller
Write-Host "[1/2] Compiling standalone executable with PyInstaller..." -ForegroundColor Yellow
python -m PyInstaller --clean --noconfirm steam_frame_godot_vr.spec

# Copy output to windows root for easy access
if (Test-Path "$ScriptDir\dist\steam_frame_godot_vr.exe") {
    Copy-Item "$ScriptDir\dist\steam_frame_godot_vr.exe" "$ScriptDir\steam_frame_godot_vr.exe" -Force
    Write-Host "`n[2/2] Build succeeded!" -ForegroundColor Green
    Write-Host "Executable generated at:" -ForegroundColor Green
    Write-Host "  -> $ScriptDir\steam_frame_godot_vr.exe" -ForegroundColor White
    Write-Host "`nYou can now launch it directly or drag-and-drop any .stl file onto it!" -ForegroundColor Cyan
} else {
    Write-Host "`n[Error] Build completed but dist\steam_frame_godot_vr.exe was not found." -ForegroundColor Red
    Exit 1
}
