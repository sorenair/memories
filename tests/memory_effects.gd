extends SceneTree
## Audit the actual current timeline catalog, including nested packed components.
const RECALL = preload("res://components/effects/recall/component_recall.gd")
var failures := 0
var totals: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func collect(node: Node, result: Array[Node3D]) -> void:
	if node is Node3D and node.has_method("get_recall_controller"): result.append(node)
	for child in node.get_children(true): collect(child, result)
func capture(id: String, phase: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("/tmp/memory-effects-%s-%s.png" % [id,phase])
func reaction(component: Node3D, player: Node3D, guest: Node3D) -> bool:
	if component is PainterlyGrassPatch:
		check(component.react_to_explorer and component.is_processing(), "Grass response disabled: " + str(component.get_path()))
		component._process(0.5)
		var a: Vector3 = component._foliage_material.get_shader_parameter("explorer_position")
		var b: Vector3 = component._foliage_material.get_shader_parameter("explorer_position_2")
		check(a.distance_to(player.global_position) < 0.05 and b.distance_to(guest.global_position) < 0.05, "Grass must react to local and LAN positions")
		# Cancelling departure can restore the local actor after the LAN actor
		# has occupied the first slot. Each source must still represent one actor.
		player.remove_from_group(&"explorers")
		component._process(0.5)
		player.add_to_group(&"explorers")
		component._process(0.5)
		a = component._foliage_material.get_shader_parameter("explorer_position")
		b = component._foliage_material.get_shader_parameter("explorer_position_2")
		check(a.distance_to(guest.global_position) < 0.05 and b.distance_to(player.global_position) < 0.05, "Grass must keep distinct actors after a cancelled departure")
		return true
	if component is PainterlyBush or component is PainterlyWallVine or component is PainterlyTree:
		check(component.react_to_explorers and component.is_processing(), "Canopy response disabled: " + str(component.get_path()))
		if component is PainterlyBush: component._scan_timer = 0.0
		component._process(0.5)
		var material: ShaderMaterial = component._canopy_material if component is PainterlyTree else component._leaf_material
		var sources: PackedVector4Array = material.get_shader_parameter("disturbance_sources")
		check(sources.size() == 2 and sources[0].w > 0.5 and sources[1].w > 0.5, "Both explorers must disturb low foliage: " + str(component.get_path()))
		return true
	if component is PainterlyFlowerPatch:
		check(component.react_to_explorers, "Flower response disabled")
		component._process(0.5)
		check(component._material.get_shader_parameter("explorer_0").w > 0.5 and component._material.get_shader_parameter("explorer_1").w > 0.5, "Both explorers must disturb flowers")
		return true
	return false
func run() -> void:
	physics_interpolation = false
	var catalog: Array = load("res://UI/memory_lane/memory_lane.gd").MEMORIES
	for entry in catalog:
		var world := load(entry.scene).instantiate() as Node3D
		root.add_child(world)
		world.set_physics_process(false)
		var player: MemoryExplorer = world.get_node("Explorer")
		player.set_physics_process(false)
		player.global_position = Vector3.ONE * 10000
		await process_frame
		await process_frame
		var memory: MemoryScene = world.get_node("Memory")
		var guest := Node3D.new()
		guest.add_to_group(&"foliage_explorers")
		world.add_child(guest)
		var components: Array[Node3D] = []
		collect(memory, components)
		check(not components.is_empty(), "No recallable scenery found: " + entry.title)
		var reactions := 0
		for component in components:
			var context := "%s: %s" % [entry.title, memory.get_path_to(component)]
			check(component.recall_enabled, "Recall disabled: " + context)
			var effect: Node = component.get_recall_controller()
			check(is_instance_valid(effect), "Recall controller missing: " + context)
			if not is_instance_valid(effect): continue
			effect.set_process(false)
			player.global_position = Vector3.ONE * 10000
			guest.global_position = Vector3.ONE * 10000
			effect.reset()
			effect._process(0.1)
			check(effect.progress == 0.0 and not effect.playing, "Distant object recalled: " + context)
			var near := component.global_position
			if component.has_method("get_recall_anchor") and component.get_recall_anchor():
				near = component.get_recall_anchor().global_position
			elif component is PainterlyWater:
				var edge: Vector2 = component._shape_data.outline[0]
				near = component.to_global(Vector3(edge.x,0,edge.y))
			# Verify LAN presence alone can discover it, then test local response too.
			guest.global_position = near
			effect._process(0.1)
			check(effect.progress > 0.0 and effect.playing, "Nearby LAN explorer failed to recall: " + context)
			player.global_position = near
			guest.global_position = near + Vector3.RIGHT * 0.25
			reactions += int(reaction(component, player, guest))
			effect._process(effect.duration * 2.0)
			check(effect.progress == 1.0 and not effect.playing, "Recall failed to finish: " + context)
			# Near objects must still wait when both actors are hidden.
			player.hide()
			guest.hide()
			effect.reset()
			effect._process(0.1)
			check(effect.progress == 0.0, "Hidden explorers must not recall objects: " + context)
			player.show()
			guest.show()
			player.global_position = near
			guest.global_position = Vector3.ONE * 10000
			effect._process(0.1)
			check(effect.progress > 0.0, "Nearby local explorer failed to recall: " + context)
			effect.seek(1.0)
		if memory.memory_id == &"snowy_stadium":
			var field := memory.get_node("Zones/Stadium/Scenery/Field")
			check(field.recall_anchor != null and field.recall_anchor.global_position.y > field.global_position.y + 5.0, "Scenic field needs a reachable lookout trigger")
		if "--capture" in OS.get_cmdline_user_args():
			guest.global_position = Vector3.ONE * 10000
			player.global_transform = memory.get_entry_transform()
			if memory.memory_id == &"snowy_stadium": player.global_position = memory.get_node("Zones/Stadium/Scenery/ViewingPlatform").global_position
			world.get_node("CameraRig").set_process(false)
			world.get_node("CameraRig").global_position = player.global_position
			world.get_node("Controls/FPSLabel").hide()
			for component in components: component.get_recall_controller().reset()
			await capture(str(memory.memory_id), "hidden")
			for component in components: component.get_recall_controller()._process(0.95)
			# A held midpoint overview makes every component's shader inspectable;
			# individual distance gating is verified independently above.
			var progress_values: Array[float] = []
			for component in components:
				progress_values.append(component.get_recall_controller().progress)
				component.get_recall_controller().seek(0.5)
			var views := {
				&"first_meeting": Vector4(6,1,1,28), &"snowy_stadium": Vector4(0,-2,-12,58),
				&"art_museum": Vector4(0,1,-6,36), &"christmas_market": Vector4(-2,1,-8,38),
				&"new_years_eve": Vector4(0,1,-5,30), &"foliage_demo": Vector4(0,1,0,52)}
			var view: Vector4 = views.get(memory.memory_id, Vector4(0,1,0,30))
			world.get_node("CameraRig").global_position = Vector3(view.x,view.y,view.z)
			world.get_node("CameraRig/Camera3D").size = view.w
			await capture(str(memory.memory_id), "recalling")
			for index in components.size(): components[index].get_recall_controller().seek(progress_values[index])
			for component in components:
				var effect: Node = component.get_recall_controller()
				if effect.playing: effect.seek(1.0)
			await capture(str(memory.memory_id), "nearby")
		var row := {"memory":entry.title,"recall":components.size(),"foliage_response":reactions}
		totals.append(row)
		print("Memory effects: ", JSON.stringify(row))
		world.free()
		await process_frame
	print("All current memories effects: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
