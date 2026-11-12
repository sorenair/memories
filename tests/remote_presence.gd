extends SceneTree
const PRESENCE = preload("res://scripts/network/remote_presence.gd")
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
	root.get_texture().get_image().save_png("/tmp/remote-presence-%s.png" % label)
func run() -> void:
	var session := root.get_node("LanSession")
	var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	root.add_child(world)
	world.set_physics_process(false) # Test transport delivery without sending RPCs.
	world.player.set_physics_process(false)
	session.partner_id = 2
	session.partner_memory = session.local_memory
	session.partner_visit = 1
	session.partner_avatar = MemoryExplorer.Avatar.VIVIAN
	world._update_lan()
	check(world._remote == null, "Presence alone must not spawn a replica before its first valid pose")
	var point: Vector3 = world.player.global_position + Vector3.RIGHT * 1.7
	world._receive_snapshot(1.0, point, 0.0, false)
	var remote: MemoryExplorer = world._remote
	var effect: Node = remote.get_node("PresenceRecall")
	effect.set_process(false)
	check(effect.progress == 0.0 and not remote.visible, "Replica must begin hidden at zero recall")
	check(not effect._surfaces.is_empty(), "Both skinned avatars need recall materials")
	check(not world.player.has_node("PresenceRecall"), "Local player materials and arrival must stay independent")
	world._process(0.016)
	check(remote.visible and remote.global_position.is_equal_approx(point), "First playback must show the zero-recall replica at its actual pose")
	for surface in effect._surfaces:
		check(surface.paint.get_shader_parameter("recall_solid_progress") == 0.0, "Replica surfaces must not flash before arrival")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("hidden")
	effect._process(PRESENCE.ARRIVAL_DURATION * 0.5)
	check(is_equal_approx(effect.progress, 0.5), "Arrival must advance smoothly")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("arriving")
	session.partner_avatar = MemoryExplorer.Avatar.SOREN
	world._update_lan()
	check(world._remote == remote and remote.avatar == MemoryExplorer.Avatar.SOREN, "Avatar updates must preserve the current scan")
	effect._process(PRESENCE.ARRIVAL_DURATION)
	check(effect.progress == 1.0 and not effect.is_processing(), "Completed arrival must stop processing")
	for surface in effect._surfaces:
		check(surface.mesh.get_surface_override_material(surface.surface) == surface.original, "Arrival must restore exact authored materials")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("present")
	var local_position: Vector3 = world.player.global_position
	session.partner_memory = ""
	world._update_lan()
	check(world._remote == null and world._motion == null and world.get_node_or_null("Partner") == null, "Departure must immediately release active replica and buffer")
	check(is_instance_valid(remote) and remote.visible and effect.departing, "Departure must retain the last visible pose for the reverse scan")
	check(remote.collision_layer == 0 and remote.collision_mask == 0 and not remote.walking, "Departing replica must not block or continue walking")
	effect.set_process(false)
	effect._process(PRESENCE.DEPARTURE_DURATION * 0.5)
	check(is_equal_approx(effect.progress, 0.5), "Departure must reverse smoothly")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("departing")
	world._receive_snapshot(2.0, point + Vector3.ONE * 999, 0.0, true)
	check(world._remote == null, "Old pose delivery after departure must not recreate a partner")
	# A fresh visit must coexist safely with the dissolving old replica.
	session.partner_visit += 1
	session.partner_memory = session.local_memory
	world._update_lan()
	world._receive_snapshot(3.0, point + Vector3.RIGHT, 0.0, false)
	var fresh: MemoryExplorer = world._remote
	var fresh_effect: Node = fresh.get_node("PresenceRecall")
	fresh_effect.set_process(false)
	check(fresh != remote and fresh_effect.progress == 0.0, "Quick return must create a fresh recall and motion buffer")
	effect._process(PRESENCE.DEPARTURE_DURATION)
	await process_frame
	check(not is_instance_valid(remote) and is_instance_valid(fresh), "Old departure must free only its own replica")
	fresh_effect._process(0.15)
	var partial: float = fresh_effect.progress
	session.partner_id = 0
	world._update_lan()
	fresh_effect.set_process(false)
	check(fresh_effect.departing and fresh_effect.progress == partial, "Disconnect during arrival must reverse from the current progress")
	fresh_effect._process(PRESENCE.DEPARTURE_DURATION)
	await process_frame
	check(not is_instance_valid(fresh), "Interrupted arrival must finish cleanup")
	check(world.player.global_position.is_equal_approx(local_position), "Presence effects must not move the local player")
	session.partner_memory = ""
	session.partner_visit = 0
	world.free()
	print("Remote presence recall: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
