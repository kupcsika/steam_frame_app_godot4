extends Node3D

## Steam Frame 3D STL Inspector (Godot 4)
## Immersive PBR Showroom with OpenXR Hand Tracking, Studio Lighting, and Gamepad Controls.

const STLLoader = preload("res://scripts/stl_loader.gd")

var is_xr: bool = false
var xr_interface: XRInterface

# Scene references
var model_pivot: Node3D
var model_instance: MeshInstance3D
var turntable_stand: Node3D
var orbiting_light: OmniLight3D
var light_marker: MeshInstance3D
var desktop_camera: Camera3D

# Interaction state
var model_yaw: float = 25.0
var model_pitch: float = 15.0
var model_scale: float = 1.0
var turntable_active: bool = false
var turntable_speed: float = 30.0 # deg/sec
var light_angle: float = 0.0

# Mouse navigation
var mouse_dragging: bool = false
var mouse_panning: bool = false
var mouse_last_pos: Vector2 = Vector2.ZERO

# Material presets
var materials: Array[StandardMaterial3D] = []
var cur_mat_idx: int = 0
var wireframe_active: bool = false
var wireframe_mat: StandardMaterial3D

# XR Hand controllers
var left_controller: XRController3D
var right_controller: XRController3D
var prev_buttons_left: Dictionary = {}
var prev_buttons_right: Dictionary = {}


var is_test_run: bool = false
var test_frames_left: int = 30

func _ready() -> void:
	print("[Godot] Initializing Steam Frame STL Inspector...")
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--test":
			is_test_run = true

	_setup_xr()
	_setup_materials()
	_build_environment()
	_load_model()
	print("[Godot] Ready! Launch mode: ", "OpenXR (Immersive VR)" if is_xr else "Desktop / Gamescope 2D")


func _setup_xr() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("[Godot] OpenXR successfully connected to SteamVR runtime!")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		is_xr = true
	else:
		print("[Godot] OpenXR not detected. Running in standard 2D / desktop mode.")
		is_xr = false


func _setup_materials() -> void:
	# 0: Studio Matte Clay
	var mat_clay = StandardMaterial3D.new()
	mat_clay.albedo_color = Color(0.88, 0.85, 0.82)
	mat_clay.roughness = 0.80
	mat_clay.metallic = 0.05
	materials.append(mat_clay)

	# 1: Valve Steam Orange
	var mat_orange = StandardMaterial3D.new()
	mat_orange.albedo_color = Color(1.0, 0.45, 0.08)
	mat_orange.roughness = 0.28
	mat_orange.metallic = 0.60
	mat_orange.clearcoat_enabled = true
	mat_orange.clearcoat = 0.4
	materials.append(mat_orange)

	# 2: Anodized Cobalt
	var mat_blue = StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.12, 0.45, 0.95)
	mat_blue.roughness = 0.20
	mat_blue.metallic = 0.88
	mat_blue.clearcoat_enabled = true
	mat_blue.clearcoat = 0.6
	materials.append(mat_blue)

	# 3: Metallic Emerald
	var mat_green = StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.10, 0.85, 0.50)
	mat_green.roughness = 0.22
	mat_green.metallic = 0.82
	materials.append(mat_green)

	# 4: Stealth Graphite
	var mat_graphite = StandardMaterial3D.new()
	mat_graphite.albedo_color = Color(0.20, 0.22, 0.26)
	mat_graphite.roughness = 0.35
	mat_graphite.metallic = 0.85
	materials.append(mat_graphite)

	# Wireframe overlay material
	wireframe_mat = StandardMaterial3D.new()
	wireframe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wireframe_mat.albedo_color = Color(0.1, 0.1, 0.1, 0.8)
	wireframe_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wireframe_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_environment() -> void:
	# 1. WorldEnvironment with PBR features (SSAO, SSR, Glow, Tonemap)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.24, 0.28)
	env.ambient_light_energy = 0.6

	# Screen-Space Ambient Occlusion (contact shadows in crevices)
	env.ssao_enabled = true
	env.ssao_radius = 0.45
	env.ssao_intensity = 2.5
	env.ssao_power = 1.5

	# Screen-Space Reflections (pedestal & floor reflections)
	env.ssr_enabled = true
	env.ssr_max_steps = 64

	# Glow / Bloom for metallic specular highlights
	env.glow_enabled = true
	env.glow_bloom = 0.18
	env.glow_hdr_threshold = 0.9

	# ACES Film Tonemapper
	env.tonemap_mode = Environment.TONE_MAPPER_ACES

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# 2. Studio Lighting Rig
	# Key Directional Light with soft shadows
	var key_light = DirectionalLight3D.new()
	add_child(key_light)
	key_light.position = Vector3(2.5, 4.0, 2.5)
	key_light.look_at(Vector3(0, 0.95, -1.2), Vector3.UP)
	key_light.light_color = Color(1.0, 0.96, 0.90)
	key_light.light_energy = 1.4
	key_light.shadow_enabled = true
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key_light.directional_shadow_blend_splits = true
	key_light.shadow_blur = 1.2

	# Cool Fill Light
	var fill_light = OmniLight3D.new()
	add_child(fill_light)
	fill_light.position = Vector3(-2.2, 0.8, 0.5)
	fill_light.light_color = Color(0.40, 0.55, 0.75)
	fill_light.light_energy = 0.9
	fill_light.omni_range = 8.0
	fill_light.omni_attenuation = 1.2

	# Rim Spotlight
	var rim_light = SpotLight3D.new()
	add_child(rim_light)
	rim_light.position = Vector3(-1.5, 2.5, -3.2)
	rim_light.look_at(Vector3(0, 0.95, -1.2), Vector3.UP)
	rim_light.light_color = Color(0.70, 0.85, 1.0)
	rim_light.light_energy = 1.8
	rim_light.spot_range = 6.0
	rim_light.spot_angle = 45.0

	# Dynamic Orbiting Inspection Light
	orbiting_light = OmniLight3D.new()
	orbiting_light.light_color = Color(1.0, 0.80, 0.35)
	orbiting_light.light_energy = 1.6
	orbiting_light.omni_range = 4.0
	orbiting_light.omni_attenuation = 1.4
	add_child(orbiting_light)

	# Light Marker glowing diamond
	light_marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	var marker_mat = StandardMaterial3D.new()
	marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_mat.albedo_color = Color(1.0, 0.85, 0.40)
	sphere.material = marker_mat
	light_marker.mesh = sphere
	add_child(light_marker)

	# 3. Studio Room Floor & Pedestal
	_build_studio_assets()

	# 4. Cameras
	_setup_cameras()


func _build_studio_assets() -> void:
	# Room Floor (Large circular studio floor with subtle reflections)
	var floor_mesh = CylinderMesh.new()
	floor_mesh.top_radius = 5.0
	floor_mesh.bottom_radius = 5.0
	floor_mesh.height = 0.02
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.10, 0.12, 0.16)
	floor_mat.roughness = 0.32
	floor_mat.metallic = 0.15
	floor_mesh.material = floor_mat

	var floor_inst = MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.position = Vector3(0, -0.01, -1.2)
	add_child(floor_inst)

	# Turntable Stand / Pedestal
	turntable_stand = Node3D.new()
	turntable_stand.position = Vector3(0, 0, -1.2)
	add_child(turntable_stand)

	# Pedestal Base Cylinder (Height 0.9m, radius 0.42m)
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.42
	base_mesh.bottom_radius = 0.46
	base_mesh.height = 0.90
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.18, 0.20, 0.24)
	base_mat.roughness = 0.22
	base_mat.metallic = 0.85
	base_mesh.material = base_mat

	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.position = Vector3(0, 0.45, 0)
	turntable_stand.add_child(base_inst)

	# Glowing Accent Ring at the neck of the pedestal
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.41
	ring_mesh.outer_radius = 0.435
	var ring_mat = StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(0.2, 0.6, 1.0)
	ring_mesh.material = ring_mat

	var ring_inst = MeshInstance3D.new()
	ring_inst.mesh = ring_mesh
	ring_inst.position = Vector3(0, 0.88, 0)
	turntable_stand.add_child(ring_inst)


func _setup_cameras() -> void:
	if is_xr:
		# OpenXR Rig: XROrigin3D at room center
		var xr_origin = XROrigin3D.new()
		xr_origin.name = "XROrigin3D"
		add_child(xr_origin)

		var xr_camera = XRCamera3D.new()
		xr_camera.name = "XRCamera3D"
		xr_camera.current = true
		xr_origin.add_child(xr_camera)

		# Left & Right Hand Controllers
		left_controller = XRController3D.new()
		left_controller.tracker = "left_hand"
		left_controller.name = "LeftHand"
		xr_origin.add_child(left_controller)
		_attach_controller_gizmo(left_controller, Color(1.0, 0.3, 0.3))

		right_controller = XRController3D.new()
		right_controller.tracker = "right_hand"
		right_controller.name = "RightHand"
		xr_origin.add_child(right_controller)
		_attach_controller_gizmo(right_controller, Color(0.3, 0.7, 1.0))
	else:
		# Desktop 2D Camera overlooking the pedestal
		desktop_camera = Camera3D.new()
		add_child(desktop_camera)
		desktop_camera.current = true
		desktop_camera.position = Vector3(0, 1.35, 0.4)
		desktop_camera.look_at(Vector3(0, 1.05, -1.2), Vector3.UP)


func _attach_controller_gizmo(controller: XRController3D, color: Color) -> void:
	var gizmo = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.12)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	box.material = mat
	gizmo.mesh = box
	controller.add_child(gizmo)


func _load_model() -> void:
	# Parse command-line STL path or use default res://sample.stl
	var stl_path = "res://sample.stl"
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.ends_with(".stl") and FileAccess.file_exists(arg):
			stl_path = arg
			break

	print("[Godot] Loading STL: ", stl_path)
	var result = STLLoader.load_stl(stl_path)
	if result.is_empty():
		push_error("Failed to parse STL: " + stl_path)
		return

	print("[Godot] Loaded ", result["triangle_count"], " triangles successfully!")

	# Model Pivot on top of the Pedestal (height 0.95m, z=-1.2m)
	model_pivot = Node3D.new()
	model_pivot.position = Vector3(0, 1.05, -1.2)
	add_child(model_pivot)

	model_instance = MeshInstance3D.new()
	model_instance.mesh = result["mesh"]
	model_instance.material_override = materials[cur_mat_idx]
	model_pivot.add_child(model_instance)


func _process(dt: float) -> void:
	if is_test_run:
		test_frames_left -= 1
		if test_frames_left <= 0:
			print("[Godot] Test run completed after 30 frames. Exiting cleanly.")
			get_tree().quit(0)
			return

	# Orbiting Inspection Light animation
	light_angle += 1.0 * dt
	if light_angle > TAU:
		light_angle -= TAU
	var lx = 1.3 * cos(light_angle)
	var lz = -1.2 + 1.3 * sin(light_angle)
	var ly = 1.3 + 0.35 * sin(light_angle * 1.5)
	orbiting_light.position = Vector3(lx, ly, lz)
	light_marker.position = Vector3(lx, ly, lz)

	# Continuous Turntable Auto-Rotation
	if turntable_active:
		model_yaw += turntable_speed * dt

	# Process VR Hand Controller Input
	if is_xr:
		_process_xr_input(dt)
	else:
		_process_desktop_gamepad_input(dt)

	# Apply Rotation & Scale to Model Pivot
	if model_pivot:
		model_pivot.rotation_degrees = Vector3(model_pitch, model_yaw, 0)
		model_pivot.scale = Vector3(model_scale, model_scale, model_scale)


func _process_xr_input(dt: float) -> void:
	# Left Controller: Model Orbit (Thumbstick) & Scale Down (Trigger)
	if left_controller:
		var lx = left_controller.get_vector2("primary")
		if lx.length() > 0.15:
			model_yaw += lx.x * 120.0 * dt
			model_pitch += lx.y * 120.0 * dt
			model_pitch = clamp(model_pitch, -89.0, 89.0)

		# Scale Down with Left Index Trigger
		var lt = left_controller.get_float("trigger")
		if lt > 0.15:
			model_scale *= exp(-lt * 1.5 * dt)
			model_scale = max(0.1, model_scale)

		# Button X (Cycle Material)
		if left_controller.is_button_pressed("ax_button") and not prev_buttons_left.get("ax_button", false):
			_cycle_material()
		# Button Y (Toggle Wireframe)
		if left_controller.is_button_pressed("by_button") and not prev_buttons_left.get("by_button", false):
			_toggle_wireframe()

		prev_buttons_left["ax_button"] = left_controller.is_button_pressed("ax_button")
		prev_buttons_left["by_button"] = left_controller.is_button_pressed("by_button")

	# Right Controller: Move Model (Thumbstick), Scale Up (Trigger), Reset, Turntable
	if right_controller:
		var rx = right_controller.get_vector2("primary")
		if rx.length() > 0.15:
			model_pivot.position.x += rx.x * 1.2 * dt
			model_pivot.position.z -= rx.y * 1.2 * dt

		# Scale Up with Right Index Trigger
		var rt = right_controller.get_float("trigger")
		if rt > 0.15:
			model_scale *= exp(rt * 1.5 * dt)
			model_scale = min(10.0, model_scale)

		# Button A (Reset Model)
		if right_controller.is_button_pressed("ax_button") and not prev_buttons_right.get("ax_button", false):
			_reset_model()
		# Button B (Toggle Turntable)
		if right_controller.is_button_pressed("by_button") and not prev_buttons_right.get("by_button", false):
			turntable_active = not turntable_active
			print("[Godot] Turntable: ", "ON" if turntable_active else "OFF")

		prev_buttons_right["ax_button"] = right_controller.is_button_pressed("ax_button")
		prev_buttons_right["by_button"] = right_controller.is_button_pressed("by_button")


func _process_desktop_gamepad_input(dt: float) -> void:
	var lx = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ly = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(lx) > 0.15:
		model_yaw += lx * 110.0 * dt
	if abs(ly) > 0.15:
		model_pitch += ly * 110.0 * dt
		model_pitch = clamp(model_pitch, -89.0, 89.0)

	var rx = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(rx) > 0.15 and model_pivot:
		model_pivot.position.x += rx * 1.2 * dt
	if abs(ry) > 0.15 and model_pivot:
		model_pivot.position.z -= ry * 1.2 * dt


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_Q:
				get_tree().quit()
			KEY_SPACE:
				turntable_active = not turntable_active
			KEY_R:
				_reset_model()
			KEY_M:
				_cycle_material()
			KEY_W:
				_toggle_wireframe()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = event.pressed
			mouse_last_pos = event.position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_panning = event.pressed
			mouse_last_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			model_scale *= 1.10
			model_scale = min(10.0, model_scale)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			model_scale /= 1.10
			model_scale = max(0.1, model_scale)

	elif event is InputEventMouseMotion:
		var delta = event.position - mouse_last_pos
		mouse_last_pos = event.position
		if mouse_dragging:
			model_yaw += delta.x * 0.4
			model_pitch += delta.y * 0.4
			model_pitch = clamp(model_pitch, -89.0, 89.0)
		elif mouse_panning and model_pivot:
			model_pivot.position.x += delta.x * 0.003
			model_pivot.position.y -= delta.y * 0.003


func _cycle_material() -> void:
	cur_mat_idx = (cur_mat_idx + 1) % materials.size()
	if model_instance:
		model_instance.material_override = materials[cur_mat_idx]
	print("[Godot] Switched to Material ", cur_mat_idx)


func _toggle_wireframe() -> void:
	wireframe_active = not wireframe_active
	if model_instance:
		if wireframe_active:
			materials[cur_mat_idx].next_pass = wireframe_mat
		else:
			materials[cur_mat_idx].next_pass = null
	print("[Godot] Wireframe: ", "ON" if wireframe_active else "OFF")


func _reset_model() -> void:
	model_yaw = 25.0
	model_pitch = 15.0
	model_scale = 1.0
	if model_pivot:
		model_pivot.position = Vector3(0, 1.05, -1.2)
	print("[Godot] Model reset to default position and scale.")
