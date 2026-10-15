extends SceneTree
## godot --headless --path . --script tests/bush_interaction.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	# Synthetic render timesteps isolate smoothing from physics interpolation.
	physics_interpolation = false
	var bush: PainterlyBush = load("res://components/foliage/painterly_bush.tscn").instantiate()
	root.add_child(bush)
	bush.set_process(false)
	var first := Node3D.new()
	var second := Node3D.new()
	first.add_to_group("explorers")
	second.add_to_group("explorers")
	root.add_child(first)
	root.add_child(second)
	first.position = Vector3(-0.5, 0, 0)
	second.position = Vector3(0.5, 0, 0)
	bush._process(1.0 / 60.0)
	check(bush._sources[0] == first and bush._sources[1] == second, "Bush must track both explorers independently")
	check(bush._source_weights[0] > 0.0 and bush._source_weights[0] < 0.3, "Disturbance must ease in")
	for frame in range(60):
		bush._process(1.0 / 60.0)
	first.position.x = 0.5
	bush._process(1.0 / 60.0)
	check(bush._source_positions[0].x > -0.5 and bush._source_positions[0].x < 0.0, "Position must follow smoothly instead of snapping")
	bush._source_positions[0] = Vector3(-0.5, 0, 0)
	for frame in range(60):
		bush._update_disturbance(1.0 / 60.0)
	var high_fps: Vector3 = bush._source_positions[0]
	bush._source_positions[0] = Vector3(-0.5, 0, 0)
	for frame in range(30):
		bush._update_disturbance(1.0 / 30.0)
	check(high_fps.distance_to(bush._source_positions[0]) < 0.0001, "Smoothing must agree at 30 and 60 FPS")
	first.remove_from_group("explorers")
	bush._scan_timer = 0.0
	var previous := bush._source_weights[0]
	bush._process(1.0 / 60.0)
	check(bush._source_weights[0] > 0.0 and bush._source_weights[0] < previous, "Removed players must release foliage gradually")
	check(bush._sources[1] == second, "Remaining explorer must retain its slot")
	second.position.x = 100.0
	bush._process(1.0 / 60.0)
	check(bush._source_positions[1].is_equal_approx(second.position), "Teleports must reset the interaction center")
	check(bush._source_weights[1] < 0.3, "Teleports must ease disturbance back in")
	bush.react_to_explorers = false
	check(not bush.is_processing(), "Disabled interaction must stop the script callback")
	check(bush._source_weights[0] == 0.0 and bush._source_weights[1] == 0.0, "Disabling interaction must clear residual disturbance")
	check(bush.wind_strength > 0.0, "Disabling disturbance must preserve wind")
	print("Bush interaction checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
