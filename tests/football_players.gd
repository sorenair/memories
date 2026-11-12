extends SceneTree
const PLAYERS = preload("res://components/scenery/stadium/football_players.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var field := load("res://components/scenery/stadium/painterly_football_field.tscn").instantiate() as PainterlyFootballField
	root.add_child(field)
	var players := field.get_node("Players")
	players.set_process(false)
	check(players._bodies.size() == 2 and players.get_child_count() == 7,
		"Two eleven-player teams must use six mesh batches and one football")
	var gpu_instances := DisplayServer.get_name() != "headless"
	var initial: Transform3D = players._bodies[0].get_instance_transform(0)
	var initial_position: Vector3 = players.sample_player(0, 0, 0).position
	players.advance(1.0)
	players.advance(1.0)
	var moved: Transform3D = players._bodies[0].get_instance_transform(0)
	check(initial_position.distance_to(players.sample_player(0, 0, 2).position) > 1.0 and players.position == Vector3.ZERO,
		"Actors must run while the team container stays fixed")
	var relative_at_start: Vector3 = players.route_position(1, 0, 0) - players.route_position(0, 0, 0)
	var relative_later: Vector3 = players.route_position(1, 0, 5) - players.route_position(0, 0, 5)
	check(relative_at_start.distance_to(relative_later) > 0.5,
		"Individual staggered routes must change the formation, beyond group translation")
	var forward := false
	var backward := false
	var bob_min := 1.0
	var bob_max := 0.0
	for sample in 440:
		var at := sample * 0.1
		for team in 2:
			for index in 11:
				var pose: Dictionary = players.sample_player(index, team, at)
				var point: Vector3 = pose.position
				check(point.is_finite() and absf(point.x) < 35.0 and absf(point.z) < 18.0,
					"All routes must stay finite and inside the marked playing field")
		var pose: Dictionary = players.sample_player(0, 0, at)
		forward = forward or sin(pose.yaw) > 0.9
		backward = backward or sin(pose.yaw) < -0.9
		bob_min = minf(bob_min, pose.bob)
		bob_max = maxf(bob_max, pose.bob)
	check(forward and backward and bob_max - bob_min > 0.04,
		"Players must turn with their routes and have a visible independent running bob")
	# Dummy rendering doesn't retain MultiMesh transforms; inspect real GPU uploads
	# in the rendered run as well as the deterministic route math above.
	if gpu_instances:
		check(initial.origin.distance_to(moved.origin) > 1.0, "The uploaded body instances must actually move")
		check(not players._left_legs[0].get_instance_transform(1).basis.is_equal_approx(
			players._right_legs[0].get_instance_transform(1).basis), "Running legs must swing in opposition")
	var one_step := PLAYERS.new()
	one_step.animate = false
	root.add_child(one_step)
	one_step.advance(2.0)
	check(one_step._bodies[0].get_instance_transform(0).is_equal_approx(moved),
		"Pose evaluation must be independent of rendered frame partition")
	one_step.free()
	field.animate_players = false
	await process_frame
	players = field.get_node("Players")
	check(not players.is_processing(), "The field must support a static authoring/animation toggle")
	field.show_teams = false
	await process_frame
	check(not field.has_node("Players"), "Disabling teams must remove every animated actor")
	field.free()
	await create_timer(0.3).timeout
	print("Individual football motion: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
