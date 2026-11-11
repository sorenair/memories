extends SceneTree
## Run once with -- host and once with -- guest in a second process.
const MENU := "res://UI/memory_lane/memory_lane.tscn"
# Exercise each catalog entry with the same host / guest test.
var memory_index: int = 1 if OS.get_cmdline_user_args().has("demo") else 0
var world_path: String = "res://scenes/world/memory_world.tscn" if OS.get_cmdline_user_args().has("demo") else "res://scenes/world/first_meeting_world.tscn"
const Session := preload("res://scripts/network/lan_session.gd")
const RemoteMotion := preload("res://scripts/network/remote_motion.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func wait_for(condition: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return condition.call()

func in_scene(path: String) -> bool:
	return is_instance_valid(current_scene) and current_scene.scene_file_path == path

func check_jitter_playback() -> void:
	var explorer := load("res://scenes/player/explorer.tscn").instantiate() as MemoryExplorer
	root.add_child(explorer)
	explorer.set_physics_process(false)
	var motion := RemoteMotion.new()
	var snapshot := 0
	var advancing_frames := 0
	var largest_step := 0.0
	var shortest_turn := true
	for frame in range(300):
		var elapsed := frame / 120.0
		var sent := snapshot / 20.0
		# Vary packet delay, dropping one snapshot in six.
		if elapsed >= sent + 0.01 * (snapshot % 3):
			if snapshot % 6 != 3:
				motion.push(sent, Vector3.RIGHT * minf(sent, 1.5) * 3.2,
					3.12 if sent < 0.8 else -3.12, sent < 1.5)
			snapshot += 1
		var previous := explorer.position.x
		motion.apply(1.0 / 120.0, explorer)
		if elapsed > 0.3 and elapsed < 1.5:
			var step := explorer.position.x - previous
			largest_step = maxf(absf(step), largest_step)
			advancing_frames += int(step > 0.001)
			shortest_turn = shortest_turn and absf(explorer.visual.rotation.y) > 3.0
	check(advancing_frames > 130 and largest_step < 0.04,
		"Playback should stay smooth through delayed and dropped packets")
	check(shortest_turn, "Interpolated facing should cross ±π by the short path")
	check(is_equal_approx(explorer.position.x, 4.8) and not explorer.walking,
		"Playback should settle exactly at the last resting pose")
	explorer.free()

func run() -> void:
	var host := OS.get_cmdline_user_args().has("host")
	var session := root.get_node("LanSession") as Session
	change_scene_to_file(MENU)
	if not await wait_for(func() -> bool: return in_scene(MENU), 3.0):
		push_error("Could not open the timeline")
		quit(1)
		return
	var menu := current_scene
	var controls := menu.get_node("LAN")
	var address := controls._address as LineEdit
	var join := controls._join as Button
	var host_button := controls._host as Button
	menu.select_memory(memory_index if host else 1 - memory_index)
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	if host:
		host_button.pressed.emit()
		if session.state != Session.State.HOSTING:
			push_error(session.status)
			quit(1)
			return
	else:
		address.text = "invalid"
		join.pressed.emit()
		check(session.state == Session.State.OFFLINE and not session.status.is_empty(),
			"Invalid IP should keep the timeline available and show feedback")
		address.text = "127.0.0.1"
		var touch := InputEventScreenTouch.new()
		touch.position = address.get_global_rect().get_center()
		touch.pressed = true
		menu._input(touch)
		touch.pressed = false
		menu._input(touch)
		check(address.has_focus(), "Tapping the IP field must focus it with mouse emulation disabled")
		address.text_submitted.emit(address.text)
		check(menu.get_node("Recall").disabled and session.state == Session.State.JOINING,
			"IP submission should lock solo Recall while joining")

	if not await wait_for(func() -> bool: return in_scene(world_path), 12.0):
		push_error("Did not reach the memory: %s" % session.status)
		quit(1)
		return
	var world := current_scene
	check(world.get_node("Memory").memory_id == (&"first_meeting" if memory_index == 0 else &"foliage_demo"), "Both peers must load the host's actual memory content")
	var local := world.get_node("Explorer") as MemoryExplorer
	var local_avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	var remote_avatar := MemoryExplorer.Avatar.SOREN if host else MemoryExplorer.Avatar.VIVIAN
	check(session.memory_index == memory_index, "Both peers should use the host's selected memory")
	check(local.avatar == local_avatar, "The local explorer should use this device's menu choice")
	if not await wait_for(func() -> bool:
		var partner := world.get_node_or_null("Partner") as MemoryExplorer
		return partner != null and partner.visible and not world.has_node("MemoryArrival")
	, 8.0):
		push_error("Never saw the other explorer: %s" % session.status)
		quit(1)
		return
	var remote := world.get_node("Partner") as MemoryExplorer
	check(remote.avatar == remote_avatar, "Partner should show the other device's menu choice")
	check(remote.get_node("Visual/Vivian").visible == (remote_avatar == MemoryExplorer.Avatar.VIVIAN),
		"Partner should render the selected character model")
	check(world.get_node("CameraRig").target == local and not remote.is_physics_processing()
		and remote.collision_layer == 0 and remote.movement_input == null,
		"Only the local explorer should drive input, camera, and collisions")
	check(remote.global_position.distance_to(local.global_position) > 0.8, "Spawn points should be separate")

	var local_start := local.global_position
	var remote_start := remote.global_position
	# Both routes head into the platform from the recalled landing, avoiding its outer rim.
	# First Meeting has a real yard fence: host goes straight through its opening,
	# guest walks along the sidewalk. The demo retains its original open routes.
	var actions: Array[StringName] = []
	if memory_index == 0:
		actions.assign([&"move_forward", &"move_right"] if host else [&"move_back", &"move_right"])
	else:
		actions.assign([&"move_forward"] if host else [&"move_right"])
	var previous := remote_start
	var render_moves := 0
	var saw_walk := false
	var largest_step := 0.0
	for action in actions:
		Input.action_press(action)
	var deadline := Time.get_ticks_msec() + 1250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var step := remote.global_position.distance_to(previous)
		largest_step = maxf(step, largest_step)
		if step > 0.001:
			render_moves += 1
		previous = remote.global_position
		saw_walk = saw_walk or remote.animation_player.assigned_animation == MemoryExplorer.WALK_ANIMATION
	for action in actions:
		Input.action_release(action)
	await create_timer(0.6).timeout
	var local_travel := local.global_position - local_start
	var remote_travel := remote.global_position - remote_start
	var forward := Vector3.FORWARD if memory_index == 0 else Vector3(-1.0, 0.0, -1.0).normalized()
	var right := Vector3.RIGHT if memory_index == 0 else Vector3(1.0, 0.0, -1.0).normalized()
	check(local_travel.dot(forward if host else right) > 1.5,
		"Local input should move the local player (%s)" % local_travel)
	check(remote_travel.dot(right if host else forward) > 1.5,
		"The other peer should follow its own input (%s)" % remote_travel)
	check(saw_walk and remote.animation_player.assigned_animation == MemoryExplorer.IDLE_ANIMATION,
		"Remote animation must follow walking and stopping")
	var travel := (remote.global_position - remote_start).normalized()
	check(Vector3(sin(remote.visual.rotation.y), 0.0, cos(remote.visual.rotation.y)).dot(travel) > 0.9,
		"Remote facing must track its motion")
	check(render_moves > 35 and largest_step < 0.25,
		"Remote motion must advance between the 20 Hz packets without snapshot-sized jumps (%d rendered moves, %.3f m max)" % [render_moves, largest_step])

	if not host:
		world.get_node("Controls/ReturnToTimeline").return_to_timeline()
		check(await wait_for(func() -> bool: return in_scene(MENU), 3.0),
			"Guest should return to the timeline")
		check(session.state == Session.State.OFFLINE, "Returning to the timeline should close the guest connection")
		if in_scene(MENU):
			check(current_scene.selected_index == memory_index, "Timeline should remember the shared selection")
			current_scene.get_node("LAN")._join.pressed.emit()
			if await wait_for(func() -> bool: return in_scene(world_path), 5.0):
				check(await wait_for(func() -> bool: return session.state == Session.State.OFFLINE, 7.0),
					"Guest should detect the host leaving after reconnecting")
				check(await wait_for(func() -> bool:
					return in_scene(world_path) and current_scene.get_node_or_null("Partner") == null
				, 2.0),
					"Guest should remain in the memory solo when the host leaves")
			else:
				check(false, "Guest could not reconnect: %s" % session.status)
	else:
		check(await wait_for(func() -> bool: return session.partner_id == 0, 5.0),
			"Host should immediately detect guest leaving")
		check(await wait_for(func() -> bool: return world.get_node_or_null("Partner") == null, 2.0),
			"Host should remove the guest replica")
		check(await wait_for(func() -> bool: return world.get_node_or_null("Partner") != null, 8.0),
			"Host should accept the returning guest")
		world.get_node("Controls/ReturnToTimeline").return_to_timeline()
		check(await wait_for(func() -> bool: return in_scene(MENU), 3.0),
			"Host should return to the timeline")
		check_jitter_playback()
	print("LAN %s checks: %s" % ["host" if host else "guest", "PASS" if failures == 0 else "FAIL"])
	quit(failures)
