extends SceneTree
## The lock body stays fixed while the connection shackle closes, reverses, and opens.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func run() -> void:
	var indicator = load("res://UI/main_menu/connection_indicator.gd").new()
	root.add_child(indicator)
	indicator.size = Vector2(64, 64)
	var body: PackedVector2Array = indicator._body.duplicate()
	var opened: PackedVector2Array = indicator._shackle_points()
	check(opened[0].y < 25.0, "The disconnected lock must have a visibly lifted free end")
	check(opened[0].x > indicator.HINGE.x, "The shackle must open and close on the right side")
	check(opened[-1].is_equal_approx(indicator.HINGE), "The shackle hinge must stay attached to the body")
	indicator.set_connection(true)
	await create_timer(0.2).timeout
	check(indicator._blend > 0.0 and indicator._blend < 1.0, "Connecting must animate rather than snap the shackle closed")
	check(indicator._body == body, "The lock body must not move during closing")
	var halfway: PackedVector2Array = indicator._shackle_points()
	indicator.set_connection(false)
	check(indicator._shackle_points() == halfway, "A connection change must reverse from the current shackle pose")
	await create_timer(0.55).timeout
	check(indicator._shackle_points() == opened, "Disconnecting must smoothly restore the open shackle")
	check(indicator._body == body, "Reversing must leave the body fixed")
	indicator.set_connection(true)
	await create_timer(0.55).timeout
	var closed: PackedVector2Array = indicator._shackle_points()
	check(closed[0].is_equal_approx(Vector2(41, 31)) and closed[-1].is_equal_approx(indicator.HINGE), "The connected shackle must close into the right contact with its left hinge fixed")
	check(indicator._body == body and indicator.tooltip_text == "Connected to your partner", "The body and connection meaning must remain stable")
	indicator.set_connection(false, true)
	await create_timer(0.55).timeout
	check(indicator._body == body and indicator.is_processing(), "Pending feedback must leave the body fixed")
	indicator.set_connection(false)
	check(not indicator.is_processing() and indicator.tooltip_text == "No partner connected", "Settled states must stop the pending pulse")
	indicator.free()
	print("Connection lock: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
