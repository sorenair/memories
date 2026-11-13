extends SceneTree
## Geometry, collision, recall, editable variants and actual explorer ramp traversal.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var root_3d := Node3D.new()
	root.add_child(root_3d)
	var stage: PainterlyStage = load("res://components/scenery/concert/stage/painterly_stage.tscn").instantiate()
	root_3d.add_child(stage)
	var speakers: PainterlySpeakerStack = load("res://components/scenery/concert/speakers/painterly_speaker_stack.tscn").instantiate()
	speakers.position.x = 6
	root_3d.add_child(speakers)
	var lights: PainterlyRaveLights = load("res://components/scenery/concert/lights/painterly_rave_lights.tscn").instantiate()
	lights.position = Vector3(0, stage.deck_height, -1.25)
	lights.receiving_height = -stage.deck_height
	root_3d.add_child(lights)
	lights.set_process(false)
	check(not stage.is_processing() and not speakers.is_processing(), "Deck and speaker motion must not need CPU callbacks")
	check(stage.get_anchor(&"DeckCenter").position.y > 0.45, "Stage must expose a supported deck placement anchor")
	check(stage._generated_root.get_node("Collision/AccessRamp").shape is ConvexPolygonShape3D, "Access must use continuous sloping collision")
	check(stage.excludes_ground_point(Vector3(0, 0, 0)) and stage.excludes_ground_point(Vector3(0, 0, 3)), "Groundcover must exclude deck and ramp")
	check(speakers._collision_data.size() == speakers.cabinet_count + 1, "Each cabinet and subwoofer must have collision")
	var seeded: Array = stage._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
	stage.rebuild()
	var rebuilt: Array = stage._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
	check(seeded[Mesh.ARRAY_COLOR] == rebuilt[Mesh.ARRAY_COLOR], "Stage boards must reproduce seeded pigment")
	check(stage._material != speakers._material, "Separate component instances must keep separate materials")
	check(lights._beams.size() == 4 and lights._pools.size() == 4, "Default rig must create four beams and four floor pools")
	lights.seek_time(0)
	var before: Transform3D = lights._heads[0].transform
	var pool_before: Vector3 = lights._pools[0].position
	lights.seek_time(2.0)
	check(not lights._heads[0].transform.is_equal_approx(before) and lights._pools[0].position != pool_before, "Fixtures and receiving pools must sweep together")
	for index in range(lights.light_count):
		var beam := lights._beams[index]
		var source: Vector3 = lights._heads[index].position + lights._heads[index].basis * Vector3(0, 0, 0.216)
		var offset: Vector2 = beam.material_override.get_shader_parameter("source_offset")
		var height: float = beam.material_override.get_shader_parameter("beam_height")
		check((beam.position + Vector3(offset.x, height, offset.y)).distance_to(source) < 0.001, "Each visible beam must meet its moving lens")
		check(beam.custom_aabb.has_point(source - beam.position), "Beam culling bounds must contain its moving source")
	lights.beams_enabled = false
	lights.floor_pools_enabled = false
	lights.rebuild()
	check(lights._beams.is_empty() and lights._pools.is_empty(), "Optional light layers must disappear when disabled")
	lights.light_count = 1
	lights.rebuild()
	check(lights._heads.size() == 1 and is_finite(lights._heads[0].position.x), "A one-light rig must remain valid")
	lights.beams_enabled = true
	lights.floor_pools_enabled = true
	lights.rebuild()
	lights.recall_enabled = true
	var light_recall: Node = lights.get_recall_controller()
	light_recall.set_process(false)
	light_recall.seek(0.4)
	check(not lights._beams[0].visible and not lights._pools[0].visible, "Light overlays must wait for the recalled hardware to finish")
	lights.rebuild()
	check(is_equal_approx(light_recall.progress, 0.4) and not lights._beams[0].visible, "Rig rebuild must preserve recall and overlay visibility")
	light_recall.seek(1.0)
	check(lights._beams[0].visible and lights._pools[0].visible, "Beams and pools must turn on when hardware finishes recalling")
	lights.recall_enabled = false
	speakers.recall_enabled = true
	var speaker_recall: Node = speakers.get_recall_controller()
	speaker_recall.set_process(false)
	speaker_recall.seek(0.5)
	speakers.rebuild()
	check(speakers.get_recall_controller() == speaker_recall and is_equal_approx(speaker_recall.progress, 0.5), "Speaker stacks must preserve their recall progress")
	speakers.recall_enabled = false
	stage.recall_enabled = true
	var recall: Node = stage.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.5)
	stage.rebuild()
	check(stage.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.5), "Stage rebuild must preserve recall progress")
	check(stage._generated_root.has_node("Collision/AccessRamp"), "Recall must preserve safe walking collision")
	stage.recall_enabled = false
	check(stage._material.get_shader_parameter("assembly_progress") == 1.0, "Disabling recall must restore the painted deck")
	# Walk the real explorer up and down the new ramp on an ordinary supporting floor.
	var floor_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.5, 20)
	collider.shape = box
	collider.position.y = -0.25
	floor_body.add_child(collider)
	root_3d.add_child(floor_body)
	var actor: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	actor.position = Vector3(0, 0.03, stage.footprint.y * 0.5 + stage.ramp_length + 0.4)
	root_3d.add_child(actor)
	actor.set_physics_process(false)
	for frame in range(220):
		await physics_frame
		actor.velocity = Vector3(0, -0.8, -1.5)
		actor.move_and_slide()
	check(actor.position.z < 0.5 and actor.position.y > stage.deck_height - 0.06, "Explorer must reach the deck without snagging on the ramp")
	for frame in range(220):
		await physics_frame
		actor.velocity = Vector3(0, -0.8, 1.5)
		actor.move_and_slide()
	check(actor.position.z > 4.1 and actor.position.y < 0.08, "Explorer must return smoothly from the deck to the floor")
	stage.ramp_enabled = false
	stage.rebuild()
	check(not stage._generated_root.has_node("Collision/AccessRamp"), "Disabling the ramp must remove its old collider")
	speakers.collision_enabled = false
	speakers.rebuild()
	check(not speakers._generated_root.has_node("Collision"), "Disabling speaker collision must remove its old solids")
	print("Concert component checks: ", "PASS" if failures == 0 else "FAIL")
	root_3d.free()
	await process_frame
	quit(failures)
