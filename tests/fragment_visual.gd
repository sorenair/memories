extends SceneTree
## Render study and structural checks for the shared, truly 3D fragment.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func capture(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.save_png("/tmp/fragment-3d-%s.png" % label)
	return frame
func changes(a: Image, b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var count := 0
	for index in range(first.size()):
		if absi(int(first[index]) - int(second[index])) > 3: count += 1
	return count
func run() -> void:
	var stage := load("res://tests/scenes/component_test.tscn").instantiate() as Node3D
	stage.subject_scene = load("res://components/interactables/fragments/memory_fragment.tscn")
	stage.camera_size = 3.5
	stage.camera_focus = Vector3(0, 1.15, 0)
	root.add_child(stage)
	await process_frame
	var fragment := stage.subject as MemoryFragment
	var core := fragment._visual.get_node("LightAndVeils") as MeshInstance3D
	check(core.mesh is ArrayMesh and core.mesh.get_aabb().size.z > 1.5, "Fragment must use volumetric geometry with real depth")
	var triangles := core.mesh.get_faces().size() / 3
	check(triangles < 1600, "Fragment must keep a modest merged geometry budget")
	check(not "MODELVIEW_MATRIX =" in core.material_override.shader.code, "The wisp must not billboard")
	var other: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	other.position.x = 100
	root.add_child(other)
	check(other._visual.get_child(0).mesh == core.mesh, "Fragments should share cached geometry")
	check(other._material != fragment._material, "Activity/decay materials must be private per fragment")
	other.free()
	var player: MemoryExplorer = stage.get_node("Explorer")
	player.set_physics_process(false)
	player.visual.hide()
	player.position = Vector3(0, 0, 1.5)
	fragment._process(1.0)
	check(fragment.state == MemoryFragment.State.ACTIVE, "Study must exercise the nearby active state")
	if "--capture" in OS.get_cmdline_user_args():
		var a := await capture("active")
		await create_timer(0.7).timeout
		var b := await capture("motion")
		check(changes(a, b) > 300, "GPU motion must change the rendered wisp and flecks")
		var camera: Camera3D = stage.get_node("Camera3D")
		camera.position = Vector3(5, 3.5, 0)
		camera.look_at(fragment.get_orb_position())
		await capture("side")
		camera.position = Vector3(0, 3.5, 5)
		camera.look_at(Vector3(0, 1.15, 0))
		stage.floor_color = Color("efeee8")
		await capture("white")
		stage.floor_color = Color("141722")
		await capture("dark")
		stage.floor_color = Color(0.28, 0.30, 0.33)
		player.position = Vector3(100, 0, 100)
		fragment._process(1.0)
		await capture("inactive")
		fragment._set_decay(0.40)
		await capture("release")
		fragment._set_decay(1.0)
		await capture("gone")
		fragment._set_decay(0.0)
		fragment._material.set_shader_parameter("activity", 1.0)
		fragment.set_process(false)
		fragment._visual.rotation = Vector3(0.05, 0.65, 0.08)
		camera.size = 1.6
		camera.position = Vector3(2.4, 2.8, 4.5)
		camera.look_at(fragment.get_orb_position())
		stage.floor_color = Color("353b49")
		stage.get_node("Controls").hide()
		await capture("preview")
		if "--motion" in OS.get_cmdline_user_args():
			# Use --fixed-fps 24 for a six-second, real-renderer animation study.
			root.size = Vector2i(960, 540)
			root.content_scale_size = Vector2i(960, 540)
			DirAccess.make_dir_recursive_absolute("/tmp/fragment-swirl-frames")
			for frame in range(144):
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/fragment-swirl-frames/%03d.png" % frame)
	stage.free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
		root.add_child(world)
		var fragments := world.get_node("Memory").find_children("*", "MemoryFragment", true, false)
		var fragment_in_memory := fragments[0] as MemoryFragment
		var explorer: MemoryExplorer = world.get_node("Explorer")
		explorer.set_physics_process(false)
		explorer.global_position = fragment_in_memory.global_position + Vector3(-0.8, 0.0, 0.25)
		world.get_node("CameraRig").global_position = explorer.global_position
		for component in world.get_node("Memory").find_children("*", "Node3D", true, false):
			if component.has_method("get_recall_controller"):
				var effect: Node = component.get_recall_controller()
				if effect:
					effect.seek(1.0)
					effect.set_process(false)
		fragment_in_memory._process(1.0)
		await capture("memory")
		world.free()
		await process_frame
	print("3D fragment visuals: ", "PASS" if failures == 0 else "FAIL", " | triangles: ", triangles)
	quit(failures)
