extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var scene := load("res://scenes/effects/water_recall_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var recall: WaterRecall = scene.recall
	var pond: PainterlyWater = scene.get_node("Subjects/Pond")
	check(recall.progress == 0.0 and not recall.playing, "Pond should wait for approach")
	check(pond.get_node("ShoreCollision").get_child(0).disabled, "Hidden pond must not block players")
	var mesh := pond.get_node("PaintedWater").mesh as ArrayMesh
	var shape := pond._shape_data.outline as PackedVector2Array
	check(Geometry2D.is_point_in_polygon(recall._center, shape), "Expansion must start inside the pond")
	recall.seek(0.25)
	var small: float = recall._material.get_shader_parameter("recall_scale")
	recall.seek(0.65)
	check(small > 0.0 and recall._material.get_shader_parameter("recall_scale") > small, "The water plane must grow outward")
	check(pond.get_node("PaintedWater").mesh == mesh and pond._shape_data.outline == shape, "Recall must not rebuild geometry, exclusions or shoreline data each frame")
	pond.foam_width = 0.44
	pond.foam_cell_size = 1.5
	check(recall._material.get_shader_parameter("foam_width") == 0.44 and recall._material.get_shader_parameter("foam_cell_size") == 1.5, "Foam controls must stay live")
	recall.play()
	pond.rebuild()
	check(pond.get_recall_controller() == recall and recall.progress == 0.65 and recall.playing, "Rebuild must preserve water recall state")
	# Keep a player inside during completion; do not trap them behind the final shore.
	scene.get_node("Explorer").position = pond.to_global(Vector3(recall._center.x, 0, recall._center.y))
	recall._process(recall.duration)
	await physics_frame
	await process_frame
	check(recall.progress == 1.0 and not recall.playing, "Water recall must finish")
	check(pond.get_node("ShoreCollision").get_child(0).disabled, "Completed shoreline must allow an inside explorer to leave")
	scene.get_node("Explorer").position = Vector3(0, 0, 10)
	recall._process(0.0)
	await physics_frame
	await process_frame
	check(not pond.get_node("ShoreCollision").get_child(0).disabled, "Shoreline blocking must return after explorers leave the pond")
	check(recall._material.get_shader_parameter("recall_scale") == 1.0, "Completed water must use the full original surface")
	pond.recall_enabled = false
	check(pond.get_recall_controller() == null and pond._water_material.get_shader_parameter("recall_progress") == null, "Toggle off must return to shader defaults")
	pond.recall_enabled = true
	recall = pond.get_recall_controller()
	scene.recall = recall
	scene._waiting = false
	recall.auto_discover = true
	scene.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(0.1)
	check(recall.progress == 0.0, "Distant pond must stay hidden")
	scene.get_node("Explorer").position = Vector3(0, 5, 0)
	recall._process(0.1)
	check(recall.progress == 0.0, "Airborne arrivals must not recall water")
	scene.get_node("Explorer").position = Vector3.ZERO
	recall._process(0.1)
	check(recall.playing, "Approaching the pond must trigger local recall")
	recall.auto_discover = false
	recall.playing = false
	# Registered rocks must get a separate outer field, not shrink with the surface.
	var rock := load("res://components/scenery/boulders/painterly_boulder.tscn").instantiate() as PainterlyBoulder
	rock.name = "ShoreStone"
	rock.dimensions = Vector3(1, 0.65, 1)
	rock.position = Vector3(0.8, 0, 0)
	scene.add_child(rock)
	pond.shore_obstacles = [NodePath("../../ShoreStone")]
	pond.rebuild()
	check(recall._outline_field != pond._shore_data.texture and pond._obstacle_regions.size() == 1, "Expansion must separate the moving shore from stationary obstacle holes")
	var outer := recall._outline_field
	recall.seek(0.5)
	check(recall._outline_field == outer, "Scrubbing must not rebake shore fields")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		scene.get_node("Explorer").position = Vector3(0, 0, 4.2)
		for stage in [0.0, 0.25, 0.55, 1.0]:
			recall.seek(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/water-recall-%d.png" % roundi(stage * 100.0))
	# Offset concave outlines must use a valid seed point and preserve their shape.
	pond.pond_outline = load("res://components/scenery/water/examples/pond_outline.tres")
	pond.rebuild()
	check(Geometry2D.is_point_in_polygon(recall._center, pond._shape_data.outline), "Custom concave ponds must start expanding from an interior point")
	check(recall.progress > 0.0, "Changing outline must preserve recall progress")
	print("Water recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
