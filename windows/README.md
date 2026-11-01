# Steam Frame STL Inspector (Godot 4) — Windows 11 Port

This directory provides the native Windows 11 adaptation of the **Godot 4 PBR 3D STL Inspector**. It compiles into a standalone `.exe` that launches on your PC and streams the immersive 6-DoF 3D world directly to your **Valve Steam Frame** via **SteamVR** and **OpenXR**.

---

## Quick Start: Launching the App

The pre-compiled standalone executable is ready to use:

```text
C:\Users\kupcs\gitprojects\steam_frame_app_godot4\windows\steam_frame_godot_vr.exe
```

### 1. Launch with Steam Frame (VR Streaming)
1. Ensure **Steam** and **SteamVR** are running on your Windows PC.
2. Turn on your **Steam Frame** headset and verify **Steam Link** is connected (via the 6GHz wireless adapter or Wi-Fi).
3. Double-click [`steam_frame_godot_vr.exe`](file:///C:/Users/kupcs/gitprojects/steam_frame_app_godot4/windows/steam_frame_godot_vr.exe) (or run [`launch_vr.bat`](file:///C:/Users/kupcs/gitprojects/steam_frame_app_godot4/windows/launch_vr.bat)).
4. Put on the headset — you are immediately placed inside the modern PBR showroom with your 3D model!

> [!TIP]
> **If your Steam Frame is currently powered off when launching:**
> The app detects this and holds an interactive prompt:
> ```text
> [SteamVR Status] Steam Frame headset is currently powered off or disconnected.
> >> Please turn ON your Steam Frame headset and ensure Steam Link is connected.
> 
> Options:
>   [Enter] Retry connection (after turning on your Steam Frame)
>   [D]     Open Desktop 3D Preview (keyboard / mouse / gamepad)
>   [Q]     Quit
> ```
> Simply turn on your Frame, wait for Steam Link to connect, and press **Enter**!

---

## Inspecting Custom STL Models

You have three easy ways to inspect any custom `.stl` file:

- **Drag-and-Drop**: Drag any `.stl` file from File Explorer and drop it directly onto `steam_frame_godot_vr.exe` (or `launch_vr.bat`).
- **PowerShell / Terminal**:
  ```powershell
  .\steam_frame_godot_vr.exe "C:\path\to\my_model.stl"
  ```
- **Desktop 2D Showroom Mode (Without Headset)**:
  ```powershell
  .\steam_frame_godot_vr.exe --desktop "C:\path\to\my_model.stl"
  ```

---

## Steam Frame VR Controller Controls (OpenXR)

Full 6-DoF roomscale tracking and controller mapping:

| Controller | Input | Action |
| :--- | :--- | :--- |
| **Left Hand** | **Thumbstick** | **Orbit Model** (Pitch & Yaw rotation) |
| **Left Hand** | **Index Trigger** | **Scale Down** (Smoothly shrink model) |
| **Left Hand** | **Button X** | **Cycle PBR Materials** (*Studio Clay, Steam Orange, Cobalt Blue, Emerald Metal, Stealth Graphite*) |
| **Left Hand** | **Button Y** | **Toggle Wireframe Overlay** |
| **Right Hand** | **Thumbstick** | **Move Model** (Horizontal X & Depth Z translation) |
| **Right Hand** | **Index Trigger** | **Scale Up** (Smoothly enlarge model) |
| **Right Hand** | **Button A** | **Reset Model** to center of pedestal |
| **Right Hand** | **Button B** | **Toggle Turntable** auto-rotation |

---

## Desktop Companion Window Controls (Fallback)

| Input | Action |
| :--- | :--- |
| **Left Mouse Drag** / **Left Stick** | Orbit / Rotate Model |
| **Right Mouse Drag** / **Right Stick** | Pan Model |
| **Scroll Wheel** | Zoom / Scale Model |
| **Space** | Toggle Turntable Auto-Rotation |
| **M** | Cycle PBR Material Palette |
| **W** | Toggle Wireframe Overlay |
| **R** | Reset Model View |
| **Esc / Q** | Exit Application |

---

## Rebuilding the Standalone `.exe`

If you modify the launcher or Godot project files, rebuild in one step:

### Via PowerShell:
```powershell
.\build_exe.ps1
```

### Via Command Prompt:
```cmd
build_exe.bat
```
