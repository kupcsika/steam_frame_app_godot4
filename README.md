# Steam Frame STL Inspector — Godot 4 Edition

An immersive 3D STL inspection application built on the **Godot 4 Engine** for the **Steam Frame** / SteamOS handheld. It delivers real-time Physically Based Rendering (PBR), studio showroom lighting, Screen-Space Ambient Occlusion (SSAO), Screen-Space Reflections (SSR), native OpenXR 6-DoF VR tracking, and full hand controller interaction.

---

## Visual Features & Environment Assets

- **Modern PBR Inspection Showroom**:
  - **Pedestal / Turntable Stand**: Chamfered brushed metal cylinder with an emissive blue status ring.
  - **Reflective Studio Floor**: Dark satin floor providing soft contact reflections of the inspected model.
  - **4-Point Studio Lighting**:
    - **Key Directional Light**: Warm studio light casting real-time soft shadows with PCF filtering.
    - **Fill OmniLight**: Cool diffuse fill light softening shadows.
    - **Rim SpotLight**: Back-facing silhouette rim light defining crisp contours.
    - **Orbiting Inspection Light**: Circling amber spotlight casting dynamic glints across facets.
  - **WorldEnvironment Effects**:
    - **SSAO (Screen-Space Ambient Occlusion)**: Rich, dark contact shadows in every crevice and groove of the STL model.
    - **SSR (Screen-Space Reflections)**: Real-time reflections on the floor and pedestal.
    - **Glow / Bloom**: Soft specular highlights on metallic materials.
    - **ACES Film Tonemapping**: High dynamic range color grading.

---

## Controls

### Steam Frame VR Hand Controllers (OpenXR)

| Controller | Input | Action |
| :--- | :--- | :--- |
| **Left Hand** | **Thumbstick** | **Orbit Model** (Pitch & Yaw rotation) |
| **Left Hand** | **Index Trigger** | **Scale Down** (Smoothly shrink model) |
| **Left Hand** | **Button X** | **Cycle PBR Materials** (Clay, Steam Orange, Cobalt Blue, Emerald Metal, Stealth Graphite) |
| **Left Hand** | **Button Y** | **Toggle Wireframe Overlay** |
| **Right Hand** | **Thumbstick** | **Move Model** (Horizontal X & Depth Z translation) |
| **Right Hand** | **Index Trigger** | **Scale Up** (Smoothly enlarge model) |
| **Right Hand** | **Button A** | **Reset Model** to center of pedestal |
| **Right Hand** | **Button B** | **Toggle Turntable** auto-rotation |

### Desktop / Keyboard & Mouse Fallback

| Input | Action |
| :--- | :--- |
| **Left Mouse Drag** / **Left Stick** | Orbit / Rotate Model |
| **Right Mouse Drag** / **Right Stick** | Pan Model |
| **Scroll Wheel** | Zoom / Scale Model |
| **Space** | Toggle Turntable Auto-Rotation |
| **M** | Cycle PBR Material Palette |
| **W** | Toggle Wireframe Overlay |
| **R** | Reset Model View |
| **Q / Esc** | Exit Application |

---

## Usage

### 1. Run Locally on PC
```bash
cd ~/gitprojects/steam_frame_app_godot4
./run.sh
```

### 2. Launch on the Steam Frame via SSH (Immersive 3D VR Mode)
Transitions directly into the SteamVR 3D world with physical 6-DoF roomscale head tracking and VR hand controllers:
```bash
./launch_remote.sh --vr
```

### 3. Launch with Custom STL File
```bash
./launch_remote.sh --vr path/to/your_model.stl
```

### 4. Floating 2D Window Mode (Gamescope Desktop)
```bash
./launch_remote.sh
```

### 5. Sync Project Codebase
```bash
./sync.sh
```
*(Strictly isolated to `~/work/steam_frame_app_godot4/` on the Steam Frame)*
