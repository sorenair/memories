extends SceneTree
## Seven silhouettes, shared geometry, deterministic placement and recall-safe collision.
const PLANT = preload("res://components/foliage/jungle/painterly_palm.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var budgets := {}
	var plant: PainterlyJunglePlant = PLANT.instantiate()
	root.add_child(plant)
	plant.react_to_explorers = false
	plant.regenerate.call()
	check(plant.has_node("Foliage") and not plant.has_node("Canopy"), "The inherited regeneration button must rebuild the jungle plant")
	for form in range(7):
		plant.plant_form = form
		plant.plant_height = [3.8, 3.4, 1.5, 1.3, 1.4, 0.5, 2.9][form]
		plant.spread = [3.3, 2.8, 1.8, 1.8, 1.8, 1.55, 1.9][form]
		plant.rebuild()
		var batch: MultiMeshInstance3D = plant.get_node("Foliage")
		check(batch.multimesh.instance_count > 0, "Every plant form must produce foliage")
		check(batch.multimesh.mesh == plant.JUNGLE_LEAVES.mesh_for(form), "Immutable leaf geometry must be cached across instances")
		var geometry := batch.multimesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = geometry[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = geometry[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = geometry[Mesh.ARRAY_TEX_UV]
		for index in range(vertices.size()):
			check(vertices[index].is_finite() and normals[index].is_normalized(), "Leaf vertices/normals must be valid, including narrow tips")
			check(uvs[index].y >= 0.0 and uvs[index].y <= 1.0, "Motion weights must anchor roots and remain bounded")
		var counts: PackedInt32Array = geometry[Mesh.ARRAY_INDEX]
		var total := counts.size() / 3 * batch.multimesh.instance_count
		if plant.has_node("Stems"):
			total += plant.get_node("Stems").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
		budgets[form] = total
		check(total < 22000, "A default jungle plant must keep a modest geometry budget")
		var previous := plant._leaves.duplicate()
		plant.rebuild()
		check(plant._leaves == previous, "The same seed/settings must reproduce placement")
		plant.plant_seed += 1
		plant.rebuild()
		check(plant._leaves != previous, "Seed must vary plant growth instead of only changing colors")
		var generated: Node = plant.get_node("Foliage")
		plant.palette_preset = 6
		check(plant.get_node("Foliage") == generated and plant._canopy_material.get_shader_parameter("leaf_color") == plant.palette.leaf_color, "Palette selection must update existing geometry")
		plant.recall_enabled = true
		var recall: Node = plant.get_recall_controller()
		recall.set_process(false)
		recall.seek(0.45)
		plant.rebuild()
		check(plant.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.45), "Rebuild must retain recall state")
		check(plant.has_node("StemCollision") == (form != 5 and not plant._blockers.is_empty()), "Recall must preserve the appropriate solid stem collision")
		plant.recall_enabled = false
		check(plant._canopy_material.get_shader_parameter("assembly_progress") == 1.0, "Disabling recall must restore all leaves")
		var packed := PackedScene.new()
		check(packed.pack(plant) == OK, "Each form must save as an editable component")
		var restored: PainterlyJunglePlant = packed.instantiate()
		check(restored.plant_form == form and restored.get_children().is_empty(), "Saved components must retain the form without generated children")
		restored.free()
	# Walk the actual explorer along the study's intended central approach.
	plant.free()
	var study: Node3D = load("res://components/foliage/jungle/jungle_study.tscn").instantiate()
	root.add_child(study)
	var ground := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = WorldBoundaryShape3D.new()
	ground.add_child(collider)
	root.add_child(ground)
	var actor: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	actor.position = Vector3(0, 0.03, 3.7)
	root.add_child(actor)
	actor.set_physics_process(false)
	for frame in range(120):
		await physics_frame
		actor.velocity = Vector3(0, -2, -1.3)
		actor.move_and_slide()
	check(actor.position.z < 1.4 and actor.position.z > 0.5, "Explorers must reach the fountain along a clear approach")
	print("Jungle component checks: ", "PASS" if failures == 0 else "FAIL", " | triangles by form: ", budgets)
	study.free()
	ground.free()
	actor.free()
	await process_frame
	quit(failures)
