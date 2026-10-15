extends SceneTree
## godot --headless --path . --script tests/boulder_smoke.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var boulder: PainterlyBoulder = load("res://components/scenery/boulders/painterly_boulder.tscn").instantiate()
	root.add_child(boulder)
	check(boulder.get_children().is_empty(), "Boulder scenes must save authoring parameters only")
	check(boulder.get_children(true).size() == 3, "Component must contain one stone, a shadow, and optional collision")
	var stone: MeshInstance3D = boulder.get_node("Stone")
	var mesh := stone.mesh
	check(mesh.get_surface_count() == 1, "Boulder must be a single stone surface")
	var data := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
	check(indices.size() / 3 < 200, "Plane-sculpted boulder must stay below 200 triangles")
	# Hard normals split vertices along physical plane edges. Weld positions for
	# topology checks; those shading splits must not be mistaken for open seams.
	var welded := {}
	var canonical := PackedInt32Array()
	for point in points:
		if not welded.has(point):
			welded[point] = welded.size()
		canonical.append(welded[point])
	var edges := {}
	var valid_faces := true
	var outward_faces := 0
	var center := mesh.get_aabb().get_center()
	for triangle in range(0, indices.size(), 3):
		var a := indices[triangle]
		var b := indices[triangle + 1]
		var c := indices[triangle + 2]
		var normal := (points[c] - points[a]).cross(points[b] - points[a])
		valid_faces = valid_faces and normal.length_squared() > 0.00000001
		if normal.dot((points[a] + points[b] + points[c]) / 3.0 - center) > 0.0:
			outward_faces += 1
		for pair in [[a, b], [b, c], [c, a]]:
			var key := "%d:%d" % [mini(canonical[pair[0]], canonical[pair[1]]), maxi(canonical[pair[0]], canonical[pair[1]])]
			edges[key] = edges.get(key, 0) + 1
	check(valid_faces, "Stone must have no collapsed triangles")
	check(float(outward_faces) / float(indices.size() / 3) > 0.95, "Stone faces must point outward")
	var closed := true
	for uses in edges.values():
		closed = closed and uses == 2
	check(closed and welded.size() - edges.size() + indices.size() / 3 == 2, "Stone must be one closed manifold shell")
	for index in range(points.size()):
		check(points[index].is_finite() and normals[index].is_finite(), "Geometry must be finite")
		check(absf(normals[index].length() - 1.0) < 0.001, "Plane normals must be normalized")
	for triangle in range(0, indices.size(), 3):
		check(normals[indices[triangle]].is_equal_approx(normals[indices[triangle + 1]]) and normals[indices[triangle]].is_equal_approx(normals[indices[triangle + 2]]), "Each triangle must retain one physical plane normal")
	check(mesh.get_aabb().position.y < 0.0, "Boulder base must sink into the ground")
	boulder.rebuild()
	check(boulder.get_node("Stone").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == points, "Seed must reproduce shape")
	var current: MeshInstance3D = boulder.get_node("Stone")
	for preset in range(1, 7):
		boulder.palette_preset = preset
		check(boulder.get_node("Stone") == current, "Palette selection must not rebuild geometry")
		check(current.material_override.get_shader_parameter("mid_color") == boulder.palette.mid_color, "Palette must update painted materials")
	var packed := PackedScene.new()
	check(packed.pack(boulder) == OK, "Boulder scene must pack")
	var restored: PainterlyBoulder = packed.instantiate()
	root.add_child(restored)
	check(restored.palette_preset == 6, "Preset must survive scene packing")
	boulder.boulder_seed += 1
	boulder.rebuild()
	check(boulder.get_node("Stone").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != points, "Different seeds must produce different shapes")
	var player := CharacterBody3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 1.2
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	player.add_child(collision)
	root.add_child(player)
	player.position = Vector3(-3, 0.6, 0)
	# Remove the packed duplicate so the collision check targets this boulder only.
	restored.free()
	await physics_frame
	await physics_frame
	var hit := player.move_and_collide(Vector3(6, 0, 0))
	check(hit != null and hit.get_collider() == boulder.get_node("BoulderCollision"), "Player must collide with the single stone hull")
	boulder.solid = false
	boulder.rebuild()
	check(not boulder.has_node("BoulderCollision"), "Decorative boulders must support disabled collision")
	print("Boulder smoke checks: ", "PASS" if failures == 0 else "FAIL", " | triangles: ", indices.size() / 3)
	quit(failures)
