extends SceneTree
## Run with -- host and -- guest in two processes on the same machine.
const MAIN := "res://UI/main_menu/main_menu.tscn"
const TIMELINE := "res://UI/memory_lane/memory_lane.tscn"
const WORLDS := ["res://scenes/world/first_meeting_world.tscn", "res://scenes/world/snowy_stadium_world.tscn", "res://scenes/world/art_museum_world.tscn", "res://scenes/world/memory_world.tscn"]
const RemoteMotion := preload("res://scripts/network/remote_motion.gd")
var failures := 0
var session: Node
var sync: TestSync

class TestSync extends Node:
	var phase := 0
	var acknowledged := 0
	@rpc("any_peer", "reliable")
	func command(value: int) -> void:
		phase = value
	@rpc("any_peer", "reliable")
	func acknowledge(value: int) -> void:
		acknowledged = value

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func wait_for(condition: Callable, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return condition.call()

func in_scene(path: String) -> bool:
	return is_instance_valid(current_scene) and current_scene.scene_file_path == path

func wait_scene(path: String) -> void:
	check(await wait_for(func(): return in_scene(path)), "Navigation should open " + path)

func timeline() -> void:
	if in_scene(MAIN):
		current_scene.enter_timeline()
	elif not in_scene(TIMELINE):
		current_scene.get_node("Controls/ReturnToTimeline").return_to_timeline()
	await wait_scene(TIMELINE)
	check(await wait_for(func(): return in_scene(TIMELINE) and not current_scene._bridge_active), "Timeline must finish its shared menu transition before navigation")
	check(not current_scene.has_node("LAN"), "Connection controls must be absent from the timeline")
	check(session.partner_id != 0, "Returning to the timeline must preserve the connection")

func enter(index: int) -> void:
	await timeline()
	# Match by scene, not timeline order: new memories may be inserted before Demo.
	var selected := -1
	for entry in range(current_scene.MEMORIES.size()):
		if current_scene.MEMORIES[entry].scene == WORLDS[index]:
			selected = entry
	check(selected >= 0, "Requested test memory must exist in the timeline")
	current_scene.select_memory(selected)
	current_scene.recall()
	await wait_scene(WORLDS[index])
	check(await wait_for(func(): return not current_scene.has_node("MemoryArrival")), "Arrival should finish normally")

func main_menu() -> void:
	await timeline()
	current_scene.return_to_main_menu()
	await wait_scene(MAIN)

func shared() -> void:
	check(await wait_for(func(): return session.shares_memory() and current_scene.get_node_or_null("Partner") != null), "Matching memories must show the partner")
	var remote = current_scene.get_node_or_null("Partner")
	if remote:
		check(await wait_for(func(): return remote.visible), "Buffered partner playback must become visible")
		check(remote.avatar == session.partner_avatar and remote.collision_layer == 2, "Partner must have the chosen avatar and local collision")

func solo() -> void:
	check(await wait_for(func(): return not session.shares_memory() and current_scene.get_node_or_null("Partner") == null), "Different memories/menus must remove the partner")
	check(current_scene.get_node("Explorer").is_physics_processing(), "Solo exploration must keep movement enabled")

func moving_partner() -> void:
	var remote: Node3D = current_scene.get_node("Partner")
	var start := remote.global_position
	var observed := {"walking": false}
	var listen := func(_time: float, _point: Vector3, _heading: float, walking: bool): observed.walking = observed.walking or walking
	session.snapshot_received.connect(listen)
	Input.action_press("move_forward")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_forward")
	await create_timer(0.25).timeout
	session.snapshot_received.disconnect(listen)
	check(observed.walking and remote.global_position.distance_to(start) > 0.1, "Live partner snapshots must animate and move smoothly during shared exploration")

func command(value: int) -> void:
	sync.command.rpc_id(session.partner_id, value)

func acknowledged(value: int) -> void:
	check(await wait_for(func(): return sync.acknowledged >= value), "Guest must finish phase %d" % value)

func guest_phase(value: int) -> void:
	check(await wait_for(func(): return sync.phase >= value, 20.0), "Host must start phase %d" % value)

func ack(value: int) -> void:
	sync.acknowledge.rpc_id(1, value)

func run() -> void:
	session = root.get_node("LanSession")
	sync = TestSync.new()
	sync.name = "TestSync"
	root.add_child(sync)
	var host := OS.get_cmdline_user_args().has("host")
	if not host:
		# The other test process owns this machine's listening port already.
		session._main_menu_opened = true
	change_scene_to_file(MAIN)
	await wait_scene(MAIN)
	current_scene.get_node("CharacterPicker/Vivian" if host else "CharacterPicker/Soren").pressed.emit()
	var controls = current_scene.get_node("LAN")
	if host:
		check(session.state == session.State.HOSTING and not controls._address.editable, "Fresh launch must host on the main menu and show its IP")
		print("LAN host ready")
	else:
		controls._join.pressed.emit()
		check(controls._row.visible, "Join must reveal its address field")
		controls._address.text = "invalid"
		controls._submit.pressed.emit()
		check(session.state == session.State.OFFLINE and not session.status.is_empty(), "Invalid IP must leave solo play available")
		controls._address.text = "127.0.0.1"
		controls._submit.pressed.emit()
	check(await wait_for(func(): return session.partner_id != 0), "Both menu peers must connect")
	check(in_scene(MAIN), "Connecting must not choose or enter a memory")
	check(controls._connection.connected and not controls._status.visible, "Connected rings must replace routine connection text")
	check(session.local_memory.is_empty() and session.partner_memory.is_empty(), "Menu connection must start without a shared memory")
	if host:
		await host_checks()
	else:
		await guest_checks()
	check_jitter_playback()
	print("Persistent LAN %s: %s" % ["host" if host else "guest", "PASS" if failures == 0 else "FAIL"])
	if is_instance_valid(current_scene): current_scene.free()
	session.leave()
	await create_timer(0.35).timeout
	quit(failures)

func host_checks() -> void:
	command(1)
	await enter(0)
	await acknowledged(1)
	check(session.partner_memory == "foliage_demo", "The guest must retain their own memory selection")
	await solo()
	command(2)
	await acknowledged(2)
	await shared()
	command(3)
	await acknowledged(3)
	await solo()
	await create_timer(0.25).timeout
	check(current_scene.get_node_or_null("Partner") == null, "Delayed old-visit poses must not resurrect a partner who left")
	command(4)
	await enter(1)
	await acknowledged(4)
	await solo()
	check(session.state == session.State.HOSTING, "Independent memory changes must keep hosting")
	command(5)
	await acknowledged(5)
	await shared()
	command(6)
	await main_menu()
	current_scene.get_node("CharacterPicker/Soren").pressed.emit()
	await acknowledged(6)
	check(not current_scene.get_node("LAN")._address.editable and current_scene.get_node("LAN")._address.text.is_valid_ip_address(), "Host IP must remain available after returning through menus")
	var previous_id: int = session.partner_id
	command(7)
	check(await wait_for(func(): return session.partner_id == 0), "Host should detect the guest disconnecting")
	check(await wait_for(func(): return session.partner_id != 0), "Host should accept a reconnect without leaving the menu")
	await acknowledged(7)
	check(session.partner_id != previous_id, "Reconnect must use a fresh peer identity")
	command(8)
	await enter(2)
	await acknowledged(8)
	await shared()
	command(9)
	await moving_partner()
	await acknowledged(9)
	var position: Vector3 = current_scene.get_node("Explorer").global_position
	session.leave()
	await solo()
	check(current_scene.get_node("Explorer").global_position.distance_to(position) < 0.1, "Disconnect must not move the local player")

func guest_checks() -> void:
	await guest_phase(1)
	await enter(3)
	await solo()
	ack(1)
	await guest_phase(2)
	await enter(0)
	await shared()
	ack(2)
	await guest_phase(3)
	var old_visit: int = session.local_visit
	var old_host_visit: int = session.partner_visit
	await timeline()
	# Deliberately send a stale pose through the real RPC transport after announcing exit.
	session._receive_snapshot.rpc_id(1, "first_meeting", old_visit, old_host_visit, 99999.0, Vector3.ONE * 999, 0.0, false)
	check(session.state == session.State.GUEST and session.local_memory.is_empty(), "Menus must retain the connection and clear memory presence")
	ack(3)
	await guest_phase(4)
	await enter(0)
	check(await wait_for(func(): return session.partner_memory == "snowy_stadium"), "Guest must receive the host's independent location")
	await solo()
	ack(4)
	await guest_phase(5)
	await enter(1)
	await shared()
	ack(5)
	await guest_phase(6)
	check(await wait_for(func(): return session.partner_memory.is_empty()), "Partner menus must clear their in-memory presence")
	await solo()
	ack(6)
	await guest_phase(7)
	await main_menu()
	var controls = current_scene.get_node("LAN")
	controls._join.pressed.emit()
	check(session.state == session.State.OFFLINE, "Selected Join must allow explicit disconnect")
	await create_timer(0.5).timeout
	controls._address.text = "127.0.0.1"
	controls._submit.pressed.emit()
	check(await wait_for(func(): return session.state == session.State.GUEST), "Join arrow must reconnect in place")
	check(in_scene(MAIN), "Reconnect must not force a scene change")
	ack(7)
	await guest_phase(8)
	await enter(2)
	await shared()
	check(session.partner_avatar == MemoryExplorer.Avatar.SOREN, "Main-menu character changes must be reflected after reconnect")
	ack(8)
	await guest_phase(9)
	await moving_partner()
	ack(9)
	check(await wait_for(func(): return session.state == session.State.OFFLINE), "Host loss must fall back to solo")
	await solo()
	check(in_scene(WORLDS[2]), "Host loss must leave the guest in the museum memory")
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
