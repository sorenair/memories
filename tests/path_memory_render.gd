extends "res://tests/elk_render.gd"
## Focused, fully recalled views of the actual memories after surface replacement.
func run() -> void:
	root.content_scale_size = Vector2i(1600,900)
	var groups := [
		["tokyo",[["Zones/Meiji/Scenery/ForestWalk",0.22,7.5,"tokyo-gravel"],["Zones/Sensoji/Scenery/TempleWalk",0.63,7.0,"tokyo-pavers"]]],
		["bean_bear",[["Zones/Trailhead/Scenery/ForestTrail",0.25,5.5,"bean-bear-trail"]]],
		["vineyard",[["Zones/Rows/Scenery/Trail",0.35,6.2,"vineyard-track"]]],
		["duluth_autumn",[["Zones/Trail/Scenery/ForestTrail",0.28,6.5,"fall-trail"],["Zones/Garden/Scenery/GardenCircuit",0.28,7.0,"garden-stones"]]]]
	for group: Array in groups:
		var world: Node3D = load("res://scenes/world/"+group[0]+"_world.tscn").instantiate()
		root.add_child(world)
		current_scene = world
		for i in range(6): await process_frame
		var memory: MemoryScene = world.get_node("Memory")
		for prop in memory.find_children("*","Node3D",true,false):
			if prop.has_method("get_recall_controller"):
				var effect: Node = prop.get_recall_controller()
				if effect:
					effect.seek(1)
					effect.set_process(false)
		var player: MemoryExplorer = world.get_node("Explorer")
		player.set_physics_process(false)
		player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		player.animation_player.pause()
		world.get_node("Controls").hide()
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		var camera: Camera3D = world.get_node("CameraRig/Camera3D")
		for config: Array in group[1]:
			var path := memory.get_node_or_null(config[0]) as PainterlySurfacePath
			check(path!=null,"Updated memory must instantiate the new path: "+str(config[0]))
			if not path: continue
			var d: float = path.get_path_length()*config[1]
			var position: Vector3 = path.to_global(path._edge(d,0,0.0125))
			player.global_position = position+Vector3.UP*0.035
			player.reset_physics_interpolation()
			rig.global_position = position+Vector3.UP*0.55
			camera.size = config[2]
			await shot("res://docs/previews/path-memory-"+config[3]+".png")
		world.queue_free()
		await process_frame
		await process_frame
	print("Updated path memory Mobile views: ","PASS" if failures==0 else "FAIL")
	quit(failures)
