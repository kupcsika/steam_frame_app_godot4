# PowerShell Launcher for Steam Frame Godot VR Inspector
param(
    [string]$StlFile,
    [switch]$Desktop,
    [switch]$Test
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ExePath = "$ScriptDir\steam_frame_godot_vr.exe"
if (-not (Test-Path $ExePath)) {
    $ExePath = "$ScriptDir\dist\steam_frame_godot_vr.exe"
}

$Arguments = @()
if ($Desktop) { $Arguments += "--desktop" }
if ($Test) { $Arguments += "--test" }
if ($StlFile) { $Arguments += "`"$StlFile`"" }

if (Test-Path $ExePath) {
    Write-Host "[Launcher] Starting $ExePath..." -ForegroundColor Green
    & $ExePath $Arguments
} else {
    Write-Host "[Launcher] Starting python steam_frame_godot_vr.py..." -ForegroundColor Yellow
    python "$ScriptDir\steam_frame_godot_vr.py" $Arguments
}
