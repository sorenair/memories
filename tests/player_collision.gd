extends SceneTree
## Godot --headless --path . --script tests/player_collision.gd
## Exercise the actual LAN replica setup and buffered playback against local physics.

class MovementInput extends Node:
	var axis := Vector2.ZERO

	func get_movement() -> Vector2:
		return axis

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := load("res://scenes/world/memory_world.tscn").instantiate() as Node3D
	root.add_child(world)
	world._setup_lan()
	var local := world.get_node("Explorer") as MemoryExplorer
	var controls := MovementInput.new()
	world.add_child(controls)
	local.movement_input = controls
	local.movement_camera = null
	# Isolate player contact from the memory's scenery and platform boundary.
	var origin := Vector3(200, 0, 200)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20, 0.5, 20)
	collision.shape = floor_shape
	floor_body.add_child(collision)
	floor_body.position = origin - Vector3.UP * 0.25
	world.add_child(floor_body)
	local.global_position = origin
	local.reset_physics_interpolation()
	world._remote_id = 1
	world._receive_snapshot(0.0, origin + Vector3.RIGHT * 1.4, 0.0, false)
	var remote := world.get_node("Partner") as MemoryExplorer
	var remote_point := remote.global_position
	check(local.collision_mask & remote.collision_layer != 0, "Local player must detect the partner")
	check(remote.collision_mask == 0 and not remote.is_physics_processing(),
		"The partner must remain driven by snapshots")
	for frame in range(150):
		if frame % 3 == 0:
			world._receive_snapshot(frame / 60.0, remote_point, 0.0, false)
		controls.axis = Vector2.RIGHT
		await physics_frame
		await process_frame
	check(local.position.x < origin.x + 0.94, "Held movement must stop at the partner's capsule")
	check(local.position.distance_to(remote.position) >= 0.48, "Player capsules must not overlap at rest")
	check(not local.walking, "Blocked movement should settle into idle")

	# A partner arriving via buffered snapshots must also displace an idle local
	# player instead of passing through it.
	controls.axis = Vector2.ZERO
	var minimum_distance := INF
	for frame in range(120):
		if frame % 3 == 0:
			remote_point.x -= 0.05
			world._receive_snapshot(2.5 + frame / 60.0, remote_point, 0.0, true)
		await physics_frame
		await process_frame
		minimum_distance = minf(minimum_distance, local.position.distance_to(remote.position))
	check(minimum_distance >= 0.44, "An approaching network replica must not pass through an idle player (%.3f)" % minimum_distance)

	controls.axis = Vector2.RIGHT
	minimum_distance = INF
	for frame in range(60):
		if frame % 3 == 0:
			remote_point.x -= 0.075
			world._receive_snapshot(4.5 + frame / 60.0, remote_point, 0.0, true)
		await physics_frame
		await process_frame
		minimum_distance = minf(minimum_distance, local.position.distance_to(remote.position))
	check(minimum_distance >= 0.44 and local.position.x < remote.position.x,
		"Head-on movement must keep the player on their side of the partner (%.3f)" % minimum_distance)

	# A small sideways move must let the local player walk around the partner.
	controls.axis = Vector2.DOWN
	var start := local.position
	for frame in range(50):
		await physics_frame
	check(local.position.z - start.z > 0.7, "Player contact must still allow sliding past the partner")
	controls.axis = Vector2.ZERO
	world._update_lan()
	await process_frame
	check(world.get_node_or_null("Partner") == null, "Disconnect must remove the partner's collider")
	print("LAN player collision checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
