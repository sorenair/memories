extends SceneTree
## Reusable variants, live controls, recall, groundcover and actual movement blockers.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func triangles(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	return (ids.size() if not ids.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3

func run() -> void:
	var study: Node3D = load("res://components/scenery/conservatory/conservatory_study.tscn").instantiate()
	root.add_child(study)
	var flowers: PainterlyFlowerBush = study.get_node("OpenFlowers")
	check(flowers is PainterlyBush and flowers.get_node("Blossoms").multimesh.instance_count == flowers.flower_count, "Flowering bush must extend the existing bush and honor head count")
	check(flowers.get_node("Foliage").multimesh.mesh == PainterlyLeafGeometry.leaf_spray_mesh(), "Flowering foliage must share the existing cached leaf geometry")
	var heads: MultiMeshInstance3D = flowers.get_node("Blossoms")
	var before := heads.multimesh
	flowers.flower_color = Color("e68092")
	check(heads.multimesh == before, "Changing flower colors must preserve seeded geometry")
	flowers._source_positions[0] = Vector3(1, 0, 2)
	flowers._source_weights[0] = 0.5
	flowers._send_disturbance()
	check(flowers._bloom_material.get_shader_parameter("disturbance_sources") == flowers._leaf_material.get_shader_parameter("disturbance_sources"), "Blossoms and leaves must share smoothed disturbance sources")
	flowers.flower_count = 0
	flowers.rebuild()
	check(not flowers.has_node("Blossoms") and flowers.get_node("Foliage").multimesh.instance_count > 0, "Zero bloom count must retain an ordinary leafy bush")
	flowers.flower_count = 20
	flowers.rebuild()
	var wall: PainterlyStoneWall = study.get_node("StackedWall")
	check(wall.get_node("Visual").mesh.get_surface_count() == 1, "Masonry must remain one opaque surface")
	var seeded: Array = wall.get_node("Visual").mesh.surface_get_arrays(0)
	wall.rebuild()
	check(wall.get_node("Visual").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] == seeded[Mesh.ARRAY_COLOR], "Masonry generation must be deterministic")
	check(wall.get_anchor(&"Start").position.is_equal_approx(wall.point_at(0)) and wall.get_anchor(&"End").position.is_equal_approx(wall.point_at(1)), "Wall connectors must follow the curved centerline")
	check(wall.excludes_ground_point(wall.to_global(wall.point_at(0.25))), "Curved walls must exclude groundcover along their arc")
	var bonsai: PainterlyBonsai = study.get_node("TwistedBonsai")
	check(bonsai is PainterlyTree and not bonsai.is_physics_processing(), "Bonsai must reuse tree geometry without adding physics callbacks")
	var form_a: AABB = bonsai.get_node("TrunkAndBranches").mesh.get_aabb()
	bonsai.bonsai_form = 2
	bonsai.rebuild()
	var form_b: AABB = bonsai.get_node("TrunkAndBranches").mesh.get_aabb()
	check(form_b.size.x > form_a.size.x and form_b.size.y < form_a.size.y, "Cascade must change the trunk silhouette rather than only leaf colors")
	check(bonsai.has_node("TrayCollision"), "Potted bonsai must have simple display collision")
	var fountain: PainterlyMarbleFountain = study.get_node("Fountain")
	check(not fountain.is_processing() and fountain.has_node("LivingWater"), "Fountain motion must remain GPU-only")
	fountain.seek_time(2.5)
	fountain.rebuild()
	check(fountain._water_material.get_shader_parameter("animation_time") == 2.5, "Rebuilding the fountain must preserve an authored visual clock")
	fountain.water_enabled = false
	fountain.rebuild()
	check(not fountain.has_node("LivingWater") and fountain.has_node("BasinCollision"), "A dry fountain must retain its stone shell and collision")
	fountain.water_enabled = true
	fountain.rebuild()
	# All four components must integrate with optional assembled recall.
	for item in [flowers, wall, bonsai, fountain]:
		item.recall_enabled = true
		var recall: Node = item.get_recall_controller()
		recall.set_process(false)
		recall.seek(0.4)
		item.rebuild()
		check(item.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.4), "Component rebuild must preserve recall progress")
		item.recall_enabled = false
		var packed := PackedScene.new()
		check(packed.pack(item) == OK, "Configured components must pack as reusable scenes")
		var restored: Node = packed.instantiate()
		check(restored.get_children().is_empty(), "Generated geometry must not serialize into authored component scenes")
		restored.free()
	# Test collision with the real explorer, independently of the study composition.
	var floor_body := StaticBody3D.new()
	var floor_collider := CollisionShape3D.new()
	floor_collider.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_collider)
	root.add_child(floor_body)
	var actor: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	actor.position = Vector3(0, 0.02, 3)
	root.add_child(actor)
	actor.set_physics_process(false)
	for frame in range(150):
		await physics_frame
		actor.velocity = Vector3(0, -2, -1.8)
		actor.move_and_slide()
	check(Vector2(actor.position.x, actor.position.z).length() > fountain.basin_radius * 1.03 + 0.12, "Explorers must be blocked from entering fountain water")
	var wall_test: PainterlyStoneWall = load("res://components/scenery/conservatory/walls/painterly_stone_wall.tscn").instantiate()
	wall_test.position = Vector3(12, 0, 0)
	root.add_child(wall_test)
	actor.position = Vector3(12, 0.02, 2)
	for frame in range(150):
		await physics_frame
		actor.velocity = Vector3(0, -2, -1.8)
		actor.move_and_slide()
	check(actor.position.z > wall_test.thickness * 0.5 + 0.12, "Wall collision must match the visible masonry")
	wall_test.collision_enabled = false
	wall_test.rebuild()
	check(not wall_test.has_node("WallSection_0"), "Disabling wall collision must remove all old blockers")
	var budgets := {}
	for id in ["OpenFlowers", "TwistedBonsai", "Fountain", "StackedWall"]:
		var item := study.get_node(id)
		var total := 0
		for child in item.get_children(true):
			if child is MultiMeshInstance3D:
				total += triangles(child.multimesh.mesh) * child.multimesh.instance_count
			elif child is MeshInstance3D:
				total += triangles(child.mesh)
		budgets[id] = total
		check(total < 30000, "Each default component must stay within a modest geometry budget")
	print("Conservatory component checks: ", "PASS" if failures == 0 else "FAIL", " | study budgets: ", budgets)
	study.free()
	wall_test.free()
	actor.free()
	floor_body.free()
	await process_frame
	quit(failures)
