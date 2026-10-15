extends SceneTree
## Requires graphics: godot --path . --script tests/tree_wind_render.gd
## Isolates the tree and compares rendered motion with wind off and on.
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.resize(256, 256)
	return frame
func changes(a: Image, b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var changed := 0
	for index in range(first.size()):
		if absi(int(first[index]) - int(second[index])) > 3:
			changed += 1
	return changed
func run() -> void:
	root.content_scale_size = Vector2i(800, 800)
	var world: Node3D = load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	world.get_node("Memory/Environment/Meadow").hide()
	world.get_node("Explorer").hide()
	world.get_node("Controls").hide()
	var tree: PainterlyTree = world.get_node("Memory/Environment/MeadowTree")
	for sibling in tree.get_parent().get_children():
		if sibling != tree and sibling is Node3D:
			sibling.hide()
	world.get_node("CameraRig").target = null
	world.get_node("CameraRig").global_position = tree.global_position + Vector3.UP * 1.4
	world.get_node("CameraRig/Camera3D").size = 5.8
	tree.wind_strength = 0.0
	await create_timer(0.3).timeout
	var still_a: Image = await snapshot()
	await create_timer(0.7).timeout
	var still_b: Image = await snapshot()
	tree.wind_strength = 0.09
	await create_timer(0.3).timeout
	var moving_a: Image = await snapshot()
	await create_timer(0.7).timeout
	var moving_b: Image = await snapshot()
	var still_changes := changes(still_a, still_b)
	var wind_changes := changes(moving_a, moving_b)
	print("Wind render check | still changed channels: ", still_changes, " | wind changed channels: ", wind_changes)
	quit(0 if still_changes == 0 and wind_changes > 500 else 1)
