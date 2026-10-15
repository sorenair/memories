@tool
class_name BoulderGeometry
extends RefCounted
## Intersect seeded cut planes to sculpt one contiguous, convex stone.
## Each polygon retains a single normal and paint value across its triangles.
enum Profile { AUTO, BLOCK, SLAB, UPRIGHT, WEDGE, SHARD, WEATHERED }

static func create_mesh(shape_seed: int, dimensions: Vector3, roundness: float, roughness: float, burial: float, profile: int = Profile.AUTO, variability: float = 0.85) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	# Consecutive seeds explore different families instead of tiny box variations.
	var family := posmod(shape_seed, 6) + 1 if profile == Profile.AUTO else clampi(profile, 1, 6)
	var proportions := Vector3.ONE
	var slope := Vector2(rng.randf_range(-0.32, 0.32), rng.randf_range(-0.32, 0.32))
	var lean := Vector2(rng.randf_range(-0.22, 0.22), rng.randf_range(-0.22, 0.22))
	match family:
		Profile.BLOCK:
			proportions = Vector3(rng.randf_range(0.85, 1.2), rng.randf_range(0.8, 1.1), rng.randf_range(0.8, 1.2))
		Profile.SLAB:
			proportions = Vector3(rng.randf_range(1.15, 1.45), rng.randf_range(0.32, 0.50), rng.randf_range(0.8, 1.15))
			slope *= 0.3
			lean *= 0.3
		Profile.UPRIGHT:
			proportions = Vector3(rng.randf_range(0.65, 0.85), rng.randf_range(1.35, 1.65), rng.randf_range(0.65, 0.95))
		Profile.WEDGE:
			proportions = Vector3(rng.randf_range(1.1, 1.35), rng.randf_range(0.8, 1.15), rng.randf_range(0.7, 1.0))
			slope = Vector2(rng.randf_range(0.65, 0.95), rng.randf_range(-0.3, 0.3))
		Profile.SHARD:
			proportions = Vector3(rng.randf_range(0.6, 0.8), rng.randf_range(1.15, 1.5), rng.randf_range(0.45, 0.7))
			lean = Vector2(rng.randf_range(0.35, 0.55), rng.randf_range(-0.3, 0.3))
			slope = Vector2(-0.55, 0.3)
		Profile.WEATHERED:
			proportions = Vector3(rng.randf_range(1.0, 1.3), rng.randf_range(0.65, 0.95), rng.randf_range(0.85, 1.2))
	proportions = Vector3.ONE.lerp(proportions, variability)
	lean *= variability
	var planes: Array[Plane] = []
	for axis in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var normal: Vector3 = (axis + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * (0.08 + roughness) * 0.9).normalized()
		planes.append(Plane(normal, rng.randf_range(0.75, 1.08)))
	planes.append(Plane(Vector3(slope.x, 1, slope.y).normalized(), rng.randf_range(0.76, 0.94)))
	planes.append(Plane(Vector3.DOWN, 1.0))
	for corner in [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]:
		var bevel := lerpf(1.45, 0.95, roundness) + rng.randf_range(-0.14, 0.14)
		planes.append(Plane(Vector3(corner.x, rng.randf_range(-0.35, 0.35), corner.y).normalized(), bevel))
		# Unequal shoulders and crown cuts; avoid four matching chamfers.
		if rng.randf() < 0.8 or family == Profile.WEATHERED:
			planes.append(Plane(Vector3(corner.x * rng.randf_range(0.45, 1.0), 1, corner.y * rng.randf_range(0.45, 1.0)).normalized(), bevel + rng.randf_range(-0.18, 0.16)))
		planes.append(Plane(Vector3(corner.x * 0.65, -1, corner.y * 0.65).normalized(), rng.randf_range(1.15, 1.35)))
	# One or two dominant fracture cuts define an asymmetric face or shoulder.
	for cut in range(2 if family == Profile.WEATHERED or family == Profile.SHARD else 1):
		var angle := rng.randf() * TAU
		var normal := Vector3(cos(angle), rng.randf_range(0.1, 0.65), sin(angle)).normalized()
		planes.append(Plane(normal, rng.randf_range(0.62, 0.92)))
	var scale := dimensions * proportions * 0.5
	var shape_basis := Basis(Vector3(scale.x, 0, 0), Vector3(lean.x * scale.x, scale.y, lean.y * scale.z), Vector3(0, 0, scale.z))
	shape_basis = Basis(Vector3.UP, rng.randf() * TAU) * shape_basis
	var normal_basis := shape_basis.inverse().transposed()
	var ground_offset := Vector3.UP * dimensions.y * proportions.y * (0.5 - burial)
	var hull := Geometry3D.compute_convex_mesh_points(planes)
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for plane in planes:
		var face: Array[int] = []
		var center := Vector3.ZERO
		for index in range(hull.size()):
			if absf(plane.distance_to(hull[index])) < 0.00001:
				face.append(index)
				center += hull[index]
		if face.size() < 3:
			continue
		center /= float(face.size())
		var u := plane.normal.cross(Vector3.UP).normalized()
		if u.length_squared() < 0.1:
			u = plane.normal.cross(Vector3.RIGHT).normalized()
		var v := plane.normal.cross(u).normalized()
		face.sort_custom(func(a: int, b: int) -> bool:
			var pa := hull[a] - center
			var pb := hull[b] - center
			return atan2(pa.dot(v), pa.dot(u)) < atan2(pb.dot(v), pb.dot(u)))
		var start := points.size()
		var face_tint := Color(rng.randf(), 0, 0, 1)
		# Normals transform inversely to authoring dimensions for correct planes.
		var normal := (normal_basis * plane.normal).normalized()
		for index in face:
			var p := hull[index]
			points.append(shape_basis * p + ground_offset)
			normals.append(normal)
			colors.append(face_tint)
		for triangle in range(1, face.size() - 1):
			indices.append_array(PackedInt32Array([start, start + triangle + 1, start + triangle]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
