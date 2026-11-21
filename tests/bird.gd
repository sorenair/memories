extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var bird: PainterlyBird = load("res://components/animals/bird/painterly_bird.tscn").instantiate()
	root.add_child(bird)
	var player := Node3D.new()
	root.add_child(player)
	player.add_to_group(&"explorers")
	player.position = Vector3(10, 0, 0)
	bird._process(0.2)
	check(bird.state == PainterlyBird.State.IDLE, "Distant player must leave bird idle")
	check(bird.get_children().is_empty(), "Generated bird must not serialize into the authoring scene")
	var triangles := 0
	for mesh_name in ["Bird/Body", "Bird/Feet", "Bird/LeftWing/Feathers", "Bird/RightWing/Feathers"]:
		var instance: MeshInstance3D = bird.get_node(mesh_name)
		check(instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Bird geometry must avoid shadow-map passes")
		var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		triangles += vertices.size() / 3
	check(triangles < 3000, "Simple bird must stay under 3000 triangles")
	var initial_pose := bird._visual.position
	bird._process(0.15)
	check(bird._visual.position != initial_pose, "Idle breathing should move subtly")
	player.position = Vector3(0.5, 0, 0)
	bird._process(0.13)
	check(bird.state == PainterlyBird.State.TAKING_OFF, "Entering scare radius must trigger takeoff")
	var away := bird._origin - player.global_position
	away.y = 0.0
	check(bird._direction.dot(away.normalized()) > 0.9, "Flight must lead away from the explorer")
	var original_direction := bird._direction
	player.position = Vector3(-0.5, 0, 0)
	bird.flee_from(player)
	check(bird._direction == original_direction, "Subsequent approaches must not restart takeoff")
	for index in range(60):
		bird._process(1.0 / 60.0)
	check(bird.state == PainterlyBird.State.FLYING, "Takeoff must become sustained flight")
	check(bird._visual.global_position.y > 1.0, "Bird must climb above the grass")
	check(bird._visual.global_position.x < -2.0, "Bird must travel away from the player")
	var wing := bird._wings[0].rotation.z
	bird._process(0.06)
	check(absf(bird._wings[0].rotation.z - wing) > 0.1, "Wings must flap during flight")
	while bird.state != PainterlyBird.State.DEPARTED:
		bird._process(0.1)
	check(not bird._visual.visible and not bird.is_processing(), "Once-per-visit bird must depart and stop updating")
	bird.respawn_delay = 0.5
	bird.rebuild()
	bird.flee_from(player)
	bird._process(bird.flight_duration)
	check(bird.state == PainterlyBird.State.DEPARTED and bird.is_processing(), "Optional respawn must keep its timer active")
	bird._process(0.6)
	check(bird.state == PainterlyBird.State.IDLE and bird._visual.visible, "Respawn must restore the ground bird")
	bird.rotation.y = 1.1
	player.position = bird.global_position
	bird.flee_from(player)
	bird._process(0.4)
	check(bird._visual.global_position.is_finite(), "Coincident explorer and rotated component must produce a valid takeoff")
	bird.behavior = PainterlyBird.Behavior.GROUND
	bird.palette_preset = 5
	bird.rebuild()
	var start := bird._visual.position
	var max_lift := 0.0
	for frame in 180:
		bird._process(1.0 / 60.0)
		var at := bird._visual.position
		max_lift = maxf(max_lift, at.y - bird.ground_offset)
		check(Vector2(at.x, at.z).length() <= bird.hop_radius + 0.001, "Hops stay near the placed origin")
	check(max_lift > 0.06 and not start.is_equal_approx(bird._visual.position), "Ground birds make visible hops")
	check(bird.state == PainterlyBird.State.IDLE, "Ground-only behavior does not flee on proximity")
	check(bird.take_off(Vector3.RIGHT), "Ground birds support a directed departure")
	bird.behavior = PainterlyBird.Behavior.CIRCLING
	bird.rebuild()
	var orbit_start := bird._visual.position
	var initial_wing := bird._wings[0].rotation.z
	var flap_range := 0.0
	for frame in 150:
		bird._process(1.0 / 60.0)
		flap_range = maxf(flap_range, absf(bird._wings[0].rotation.z - initial_wing))
	var at := bird._visual.position
	check(bird.state == PainterlyBird.State.CIRCLING and not bird.take_off(), "Circling birds keep their own flight state")
	check(absf(Vector2(at.x, at.z).length() - bird.circle_radius) < 0.01
		and absf(at.y - bird.circle_height) < 0.2 and orbit_start.distance_to(at) > 1.0, "Orbit follows its configured radius and height")
	check(flap_range > 0.3 and not bird._shadow.visible, "Circling alternates visible flaps and glides without a ground shadow")
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	root.add_child(camera)
	camera.position = Vector3(0, 2, 6)
	camera.look_at(Vector3(0, 1, 0))
	camera.make_current()
	bird._visual.global_position = Vector3(0, 1, 0)
	check(not bird._clear_of_camera(), "The departure must not remove a visible bird")
	bird._visual.global_position = Vector3(20, 1, 0)
	check(bird._clear_of_camera(), "The departure may remove a bird beyond the camera's edge")
	camera.free()
	bird.queue_free()
	player.queue_free()
	await process_frame
	print("Bird component: ", "PASS" if failures == 0 else "FAIL", " | triangles: ", triangles)
	quit(failures)
