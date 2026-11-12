extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var house: PainterlyHouse = load("res://components/buildings/house/painterly_house.tscn").instantiate()
	root.add_child(house)
	check(house.get_children().is_empty(), "Generated house nodes must not serialize into authored scenes")
	var exterior: MeshInstance3D = house.get_node("Exterior")
	var mesh: ArrayMesh = exterior.mesh
	check(mesh.get_surface_count() == 1, "House must render in a single opaque surface")
	check(exterior.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "House must avoid shadow-map passes")
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles := vertices.size() / 3
	check(triangles < 15000, "Default house must remain below 15k triangles")
	var finite := true
	for vertex in vertices:
		finite = finite and vertex.is_finite()
	check(finite, "Generated vertices must be finite")
	check(mesh.get_aabb().size.x > house.footprint.x, "Roof must extend beyond walls")
	check(mesh.get_aabb().size.z > house.footprint.y + house.step_count * house.step_depth, "Bounds must include front steps and roof")
	house.rebuild()
	check(house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == vertices, "Same settings must regenerate the same geometry")
	var original_colors: PackedColorArray = house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	house.house_seed += 1
	house.rebuild()
	check(house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] != original_colors, "Seed must vary quiet roof and plaster pigments")
	var full_count: int = house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
	house.dormer = false
	house.side_windows = false
	house.railings = false
	house.porch_lamp = false
	house.rebuild()
	check(house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() < full_count, "Optional details must be removable")
	house.footprint = Vector2(5.0, 4.0)
	house.foundation_height = 0.8
	house.step_count = 5
	house.rebuild()
	check(house.excludes_ground_point(Vector3.ZERO), "House body must exclude groundcover")
	check(house.excludes_ground_point(Vector3(0, 0, house.footprint.y * 0.5 + 0.4)), "Steps must exclude groundcover")
	check(not house.excludes_ground_point(Vector3(8, 0, 8)), "Open garden must remain plantable")
	house.position.x = 2
	house.rotation.y = 0.5
	check(house.excludes_ground_point(house.to_global(Vector3.ZERO)), "Ground exclusion must follow translated and rotated houses")
	house.position = Vector3.ZERO
	house.rotation = Vector3.ZERO
	# Walk a real CharacterBody up the ramp and verify the exterior blocks entry.
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = WorldBoundaryShape3D.new()
	ground.add_child(collision)
	root.add_child(ground)
	var player := CharacterBody3D.new()
	player.floor_snap_length = 0.25
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.35
	capsule.shape = shape
	capsule.position.y = 0.675
	player.add_child(capsule)
	root.add_child(player)
	player.position = Vector3(0, 0.05, house.footprint.y * 0.5 + house.step_count * house.step_depth + 0.8)
	var climbed := 0.0
	for step in range(180):
		await physics_frame
		player.velocity = Vector3(0, -3, -2.0)
		player.move_and_slide()
		climbed = maxf(climbed, player.position.y)
	check(climbed > house.foundation_height * 0.7, "Front steps must be walkable")
	check(player.position.z >= house.footprint.y * 0.5 + 0.20, "Exterior collision must stop players passing through the closed door")
	check(is_equal_approx(house.get_node("FrontDoor").position.y, house.foundation_height), "Door marker must follow foundation height")
	house.collision_enabled = false
	house.rebuild()
	check(not house.has_node("BuildingCollision"), "Scenery-only houses must support disabling collision")
	var study: Node = load("res://scenes/memories/first_meeting.tscn").instantiate()
	check(study.has_node("Zones/House/Scenery/House") and study.has_node("Zones/House/Scenery/AutumnTree"), "First Meeting must include the house in its autumn composition")
	study.free()
	house.queue_free()
	player.queue_free()
	ground.queue_free()
	await process_frame
	print("House component: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
