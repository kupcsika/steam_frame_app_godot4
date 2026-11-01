class_name STLLoader
extends RefCounted

## Loads binary and ASCII STL files into a centered Godot ArrayMesh.

static func load_stl(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open STL: " + path)
		return {}

	var length = file.get_length()
	file.seek(80)
	var num_triangles = file.get_32()
	var expected_bin_size = 84 + num_triangles * 50
	var is_binary = (length >= expected_bin_size and num_triangles > 0)

	file.seek(0)
	if is_binary:
		return _parse_binary(file, num_triangles)
	else:
		return _parse_ascii(file)


static func _parse_binary(file: FileAccess, count: int) -> Dictionary:
	file.seek(84)
	var raw = file.get_buffer(count * 50)
	var spb = StreamPeerBuffer.new()
	spb.data_array = raw

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	vertices.resize(count * 3)
	normals.resize(count * 3)

	var min_bound = Vector3(1e9, 1e9, 1e9)
	var max_bound = Vector3(-1e9, -1e9, -1e9)

	var v_idx = 0
	for i in range(count):
		var nx = spb.get_float()
		var ny = spb.get_float()
		var nz = spb.get_float()
		var norm = Vector3(nx, ny, nz)

		var v0 = Vector3(spb.get_float(), spb.get_float(), spb.get_float())
		var v1 = Vector3(spb.get_float(), spb.get_float(), spb.get_float())
		var v2 = Vector3(spb.get_float(), spb.get_float(), spb.get_float())
		spb.get_16() # attribute byte count

		# Update bounding box
		min_bound = min_bound.min(v0).min(v1).min(v2)
		max_bound = max_bound.max(v0).max(v1).max(v2)

		# Auto-compute face normal if missing
		if norm.length_squared() < 0.0001:
			norm = (v1 - v0).cross(v2 - v0).normalized()
		else:
			norm = norm.normalized()

		vertices[v_idx] = v0
		normals[v_idx] = norm
		vertices[v_idx + 1] = v1
		normals[v_idx + 1] = norm
		vertices[v_idx + 2] = v2
		normals[v_idx + 2] = norm
		v_idx += 3

	var center = (min_bound + max_bound) / 2.0
	var dims = max_bound - min_bound
	var max_dim = max(dims.x, max(dims.y, dims.z))
	if max_dim <= 0.0:
		max_dim = 1.0
	var scale_factor = 0.45 / max_dim # Scale to fit 0.45m inspection tabletop

	# Center and normalize vertices
	var centered_verts = PackedVector3Array()
	centered_verts.resize(vertices.size())
	for j in range(vertices.size()):
		centered_verts[j] = (vertices[j] - center) * scale_factor

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = centered_verts
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return {
		"mesh": mesh,
		"triangle_count": count,
		"dimensions": dims,
		"center": center,
		"scale_factor": scale_factor
	}


static func _parse_ascii(file: FileAccess) -> Dictionary:
	var verts = PackedVector3Array()
	var norms = PackedVector3Array()
	var cur_normal = Vector3.UP

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var tokens = line.split(" ", false)
		var cmd = tokens[0].to_lower()

		if cmd == "facet" and tokens.size() >= 5 and tokens[1].to_lower() == "normal":
			cur_normal = Vector3(float(tokens[2]), float(tokens[3]), float(tokens[4])).normalized()
		elif cmd == "vertex" and tokens.size() >= 4:
			var v = Vector3(float(tokens[1]), float(tokens[2]), float(tokens[3]))
			verts.append(v)
			norms.append(cur_normal)

	var count = verts.size() / 3
	if count == 0:
		return {}

	var min_bound = Vector3(1e9, 1e9, 1e9)
	var max_bound = Vector3(-1e9, -1e9, -1e9)
	for v in verts:
		min_bound = min_bound.min(v)
		max_bound = max_bound.max(v)

	var center = (min_bound + max_bound) / 2.0
	var dims = max_bound - min_bound
	var max_dim = max(dims.x, max(dims.y, dims.z))
	if max_dim <= 0.0:
		max_dim = 1.0
	var scale_factor = 0.45 / max_dim

	var centered_verts = PackedVector3Array()
	centered_verts.resize(verts.size())
	for j in range(verts.size()):
		centered_verts[j] = (verts[j] - center) * scale_factor

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = centered_verts
	arrays[Mesh.ARRAY_NORMAL] = norms

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return {
		"mesh": mesh,
		"triangle_count": count,
		"dimensions": dims,
		"center": center,
		"scale_factor": scale_factor
	}
