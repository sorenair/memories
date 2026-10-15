extends SceneTree
## Requires graphics: godot --path . --script tests/bush_interaction_render.gd
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
	root.content_scale_size = Vector2i(512, 512)
	var world: Node3D = load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	var bush: PainterlyBush = world.get_node("Memory/Environment/MeadowBush")
	for sibling in bush.get_parent().get_children():
		if sibling != bush and sibling is Node3D:
			sibling.hide()
	var player: Node3D = world.get_node("Explorer")
	player.hide()
	world.get_node("Controls").hide()
	world.get_node("CameraRig").target = null
	world.get_node("CameraRig").global_position = bush.global_position + Vector3.UP * 0.3
	world.get_node("CameraRig/Camera3D").size = 3.2
	bush.wind_strength = 0.0
	player.global_position = bush.global_position + Vector3(3, 0, 0)
	player.reset_physics_interpolation()
	await create_timer(0.9).timeout
	var resting: Image = await snapshot()
	player.global_position = bush.global_position + Vector3(0.2, 0, 0.1)
	player.reset_physics_interpolation()
	await create_timer(0.7).timeout
	var disturbed: Image = await snapshot()
	player.global_position = bush.global_position + Vector3(3, 0, 0)
	player.reset_physics_interpolation()
	await create_timer(0.9).timeout
	var released: Image = await snapshot()
	bush.wind_strength = 0.055
	await create_timer(0.2).timeout
	var wind_a: Image = await snapshot()
	await create_timer(0.7).timeout
	var wind_b: Image = await snapshot()
	var disturbance_changes := changes(resting, disturbed)
	var release_changes := changes(resting, released)
	var wind_changes := changes(wind_a, wind_b)
	print("Bush render check | disturbed: ", disturbance_changes, " | returned to rest: ", release_changes, " | wind: ", wind_changes)
	quit(0 if disturbance_changes > 500 and release_changes < 100 and wind_changes > 100 else 1)
