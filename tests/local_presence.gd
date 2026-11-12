extends SceneTree
const Presence = preload("res://scripts/network/remote_presence.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/local-presence-%s.png" % label)
func run() -> void:
	for avatar in [MemoryExplorer.Avatar.SOREN, MemoryExplorer.Avatar.VIVIAN]:
		MemoryExplorer.preferred_avatar = avatar
		root.set_meta(&"memory_recall_arrival", true)
		var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
		root.add_child(world)
		current_scene = world
		var player: MemoryExplorer = world.player
		var landing: Vector3 = player.global_position
		var effect: Node = player.get_node("PresenceRecall")
		var arrival := world.get_node("MemoryArrival")
		effect.set_process(false)
		arrival.set_process(false)
		check(effect.progress == 0.0 and not effect.free_on_departure, "Local recall must start hidden and retain its player")
		check(not player.is_physics_processing(), "Arrival must pause local input")
		check(player.visual.position == Vector3.ZERO, "Local recall must stay grounded")
		effect._process(Presence.ARRIVAL_DURATION * 0.5)
		arrival._process(0.45)
		check(effect.progress == 0.5 and arrival._veil.modulate.a == 0.0, "Veil must uncover the local scan while it is playing")
		if "--capture" in OS.get_cmdline_user_args(): await capture("%d-arriving" % avatar)
		effect._process(Presence.ARRIVAL_DURATION)
		await process_frame
		check(not world.has_node("MemoryArrival") and player.is_physics_processing(), "Arrival completion must restore exploration")
		check(player.global_position.distance_to(landing) < 0.05 and player.visual.position == Vector3.ZERO, "Arrival must not drop, lift or displace the explorer")
		var button := world.get_node("Controls/ReturnToTimeline")
		button.return_to_timeline()
		effect.set_process(false)
		check(effect.departing and not player.is_physics_processing(), "Return must freeze movement and reverse the same effect")
		check(root.get_node("LanSession").local_memory.is_empty(), "Exit must notify peers when the local departure begins")
		check(player.collision_layer == 0, "A dissolving local player must stop blocking peers immediately")
		effect._process(Presence.DEPARTURE_DURATION * 0.5)
		check(effect.progress == 0.5 and current_scene == world, "Return must keep the world visible during the reverse scan")
		check(root.get_node("MemoryTransitionVeil/Paper").modulate.a == 0.0, "Screen fade must wait for the reverse scan")
		if "--capture" in OS.get_cmdline_user_args(): await capture("%d-departing" % avatar)
		effect._process(Presence.DEPARTURE_DURATION)
		check(is_instance_valid(player) and not player.is_queued_for_deletion(), "Local recall must never free the player itself")
		await create_timer(0.7).timeout
		check(current_scene.scene_file_path == "res://UI/memory_lane/memory_lane.tscn", "Reverse recall must navigate back to the timeline")
		current_scene.free()
		current_scene = null
	print("Local explorer recall: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
