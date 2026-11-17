extends "res://tests/elk_render.gd"
## Matched inspection views; fixed positions, projection, recall state and clocks.
func run() -> void:
	root.content_scale_size = Vector2i(1600,900)
	var world: Node3D = load("res://scenes/world/northern_vietnam_world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 8: await process_frame
	world.get_node("Controls").hide()
	var player: MemoryExplorer = world.get_node("Explorer")
	player.set_physics_process(false)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.animation_player.pause()
	var memory: MemoryScene = world.get_node("Memory")
	for prop in memory.find_children("*","Node3D",true,false):
		if prop.has_method("get_recall_controller"):
			var effect: Node = prop.get_recall_controller()
			if effect:
				effect.seek(1)
				effect.set_process(false)
		if prop.has_method("seek_time"): prop.seek_time(6.0)
	var rig: Node3D = world.get_node("CameraRig")
	rig.set_process(false)
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	var prefix := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	var views := [
		["street",Vector3(0.2,0.06,14),Vector3(0.2,1.5,13),10.0],
		["lake-arrival",Vector3(18,0.04,3),Vector3(18,1.5,-0.5),17.0],
		["island-temple",Vector3(18,0.06,-11),Vector3(18,1.0,-12.5),9.5],
		["bank-walk",Vector3(31,0.04,-2),Vector3(31,1.0,-3),12.0],
		["bay-overlook",Vector3(45,0.6,-26.1),Vector3(45,3.8,-33),25.0],
		["overview",Vector3(0,0.04,26),Vector3(23,3,-8),68.0]]
	for view: Array in views:
		player.global_position = view[1]
		player.reset_physics_interpolation()
		rig.global_position = view[2]
		camera.size = view[3]
		for frame in 3: await process_frame
		await shot("res://docs/previews/north-polish-"+prefix+"-"+view[0]+".png")
	world.free()
	print("Northern Vietnam matched views: ",prefix)
	quit()
