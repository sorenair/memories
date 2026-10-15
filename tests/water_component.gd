extends SceneTree
## Requires graphics for MultiMesh readback: godot --path . --script tests/water_component.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func vertices(water: Node) -> PackedVector3Array:
	return water.get_node("PaintedWater").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func run() -> void:
	var water: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	root.add_child(water)
	for kind in range(2):
		water.shape = kind
		water.rebuild()
		var original := vertices(water)
		check(original.size() / 3 < 1600, "Water surface must retain a small geometry budget")
		var valid := true
		var bound: AABB = water.get_node("PaintedWater").custom_aabb
		for point in original:
			valid = valid and point.is_finite() and bound.has_point(point)
		check(valid, "Water geometry must be finite and inside its animated bounds")
		for index in range(0, original.size(), 3):
			check((original[index + 1] - original[index]).cross(original[index + 2] - original[index]).length_squared() > 0.000000001, "Surface must not contain degenerate triangles")
		water.rebuild()
		check(vertices(water) == original, "Seeded outline must reproduce")
		check(water.get_children().is_empty(), "Generated water nodes must not serialize")
		var surface: MeshInstance3D = water.get_node("PaintedWater")
		for preset in range(1, 7):
			water.palette_preset = preset
			check(water.get_node("PaintedWater") == surface, "Palette edits must not rebuild geometry")
			check(water._water_material.get_shader_parameter("body_color").is_equal_approx(water.palette.body_color), "All water palettes must update live")
		water.flow_speed = 0.0
		check(water._water_material.get_shader_parameter("flow_speed") == 0.0, "Motion must support a live zero-speed setting")
		water.foam_width = 0.24
		water.foam_amount = 0.7
		check(water.get_node("PaintedWater") == surface and water._water_material.get_shader_parameter("foam_width") == 0.24, "Foam controls must update live without rebuilding geometry")
		var packed := PackedScene.new()
		check(packed.pack(water) == OK, "Water must pack")
		var restored: PainterlyWater = packed.instantiate()
		root.add_child(restored)
		check(restored.shape == kind and restored.palette_preset == 6 and restored.foam_width == 0.24 and restored.foam_amount == 0.7 and restored.palette.body_color.is_equal_approx(water.palette.body_color), "Water shape and palette must survive packing")
		restored.free()
		check(water.excludes_ground_point(water.global_position), "Water center must exclude ground foliage")
		check(not water.excludes_ground_point(water.to_global(Vector3(100, 0, 100))), "Distant ground must stay available")
		print("Water shape ", kind, " | surface triangles: ", original.size() / 3)
	water.palette.shallow_color = Color(0.8, 0.5, 0.9)
	check(water.palette_preset == 0, "Editing colors must switch to Custom")
	var custom := PackedScene.new()
	custom.pack(water)
	var restored_custom: PainterlyWater = custom.instantiate()
	root.add_child(restored_custom)
	check(restored_custom.palette_preset == 0 and restored_custom.palette.shallow_color.is_equal_approx(water.palette.shallow_color), "Custom water palette must survive packing")
	restored_custom.free()
	# Open stream joins share the same cross-section and world-space paint phase.
	var outline := WaterShapes.outline(1, water.footprint, 11, 0.2, 0.5, 48)
	check(outline[0].x == outline[48].x and outline[49].x == outline[97].x, "Stream mouths must have matching widths and centers")
	water.shape = 0
	water.rebuild()
	await physics_frame
	await physics_frame
	var from := water.to_global(Vector3(water.footprint.x, 0.3, 0))
	var to := water.to_global(Vector3(0, 0.3, 0))
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := water.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == water.get_node("ShoreCollision"), "Pond shoreline must block a ray crossing into water")
	water.block_water_entry = false
	water.rebuild()
	check(not water.has_node("ShoreCollision") and not water.has_node("PaintedBank"), "Water has no colored bank and blocking collision must be optional")
	water.free()
	if DisplayServer.get_name() != "headless":
		var memory: Node3D = load("res://scenes/memories/foliage_demo.tscn").instantiate()
		root.add_child(memory)
		await process_frame
		await process_frame
		var meadow: PainterlyGrassPatch = memory.get_node("Environment/Meadow")
		var pond: PainterlyWater = memory.get_node("Environment/ClearingPond")
		meadow.rebuild()
		for batch_name in ["PaintedLeaves", "GrassTufts"]:
			var batch: MultiMeshInstance3D = meadow.get_node(batch_name)
			var none_in_water := true
			for index in range(batch.multimesh.instance_count):
				var position := batch.to_global(batch.multimesh.get_instance_transform(index).origin)
				none_in_water = none_in_water and not pond.excludes_ground_point(position)
			check(none_in_water, "Grass scatter must exclude the actual pond shape")
		var old_batch := meadow.get_node("GrassTufts").get_instance_id()
		pond.footprint *= 1.05
		await process_frame
		await process_frame
		await process_frame
		check(meadow.get_node("GrassTufts").get_instance_id() != old_batch, "Water shape edits must refresh grass exclusion automatically")
		memory.free()
	print("Water component checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
