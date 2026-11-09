extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func tap(ui: Control, point: Vector2, drag: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = point
	event.pressed = true
	ui._unhandled_input(event)
	if drag:
		var motion := InputEventScreenDrag.new()
		motion.index = 1
		motion.position = point + Vector2(30, 0)
		ui._unhandled_input(motion)
	event.pressed = false
	ui._unhandled_input(event)
func run() -> void:
	root.size = Vector2i(960, 540)
	var world := Node3D.new()
	root.add_child(world)
	var player: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 4, 8)
	camera.look_at(Vector3(0, 1, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7
	camera.current = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var ui: Control = load("res://UI/fragments/fragment_interaction.tscn").instantiate()
	layer.add_child(ui)
	var first: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	first.notes = ["First", "Second"]
	world.add_child(first)
	var second: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	second.position.x = 1
	second.notes = ["Third"]
	world.add_child(second)
	await physics_frame
	await process_frame
	var point := camera.unproject_position(first.get_orb_position())
	player.position.x = 8
	first._process(0.1)
	check(first.state == MemoryFragment.State.INACTIVE, "Out-of-range fragment must be inactive")
	check(ui.pick_fragment(point) == null, "Distant fragment must not be tappable")
	player.position = Vector3(0, 0, 1)
	first._process(0.1)
	check(first.state == MemoryFragment.State.ACTIVE, "In-range fragment must become active")
	point = camera.unproject_position(first.get_orb_position())
	check(ui.pick_fragment(point) == first, "Visible nearby orb must be picked")
	tap(ui, point, true)
	check(not first.collected, "Dragging across a fragment must cancel activation")
	tap(ui, point)
	check(first.collected and ui.current_note.text == "First", "Tap should activate and show first note")
	check(first._tap_feedback > 0.9, "Accepted tap must immediately pulse the orb")
	check(ui.pending_notes.size() == 1, "Additional notes should queue")
	check(not first.try_activate(player), "One-shot fragment must reject duplicate activation")
	check(second.try_activate(player), "Second fragment must activate while notes are open")
	check(ui.pending_notes.size() == 2, "Second fragment should append instead of replace current note")
	await create_timer(first.decay_duration + 0.2).timeout
	check(is_zero_approx(first._tap_feedback) and first._visual.scale.is_equal_approx(Vector3.ONE * first.orb_radius), "Tap feedback must settle without consuming the orb")
	check(first.state == MemoryFragment.State.ACTIVE and first._visual.visible, "Orb must remain active and visible while notes are being read")
	check(is_zero_approx(first._material.get_shader_parameter("decay")), "Reading must not start the puff")
	player.position.x = 8
	first._process(0.1)
	check(first.state == MemoryFragment.State.ACTIVE, "Reading must hold active presentation even if the player moves away")
	player.position = Vector3(0, 0, 1)
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.position = ui._next.get_global_rect().get_center()
	touch.pressed = true
	ui._input(touch)
	touch.pressed = false
	ui._input(touch)
	check(ui.current_note.text == "Second", "Native touch must advance note without mouse emulation")
	check(first.state == MemoryFragment.State.ACTIVE, "Intermediate pages must not decay the fragment")
	ui.advance_note()
	check(ui.current_note.text == "Third", "Queue must retain cross-fragment ordering")
	check(first.state == MemoryFragment.State.DECAYING and second.state == MemoryFragment.State.ACTIVE, "Only the fragment whose final page was dismissed should decay")
	ui.advance_note()
	check(ui.current_note.is_empty() and not ui._panel.visible, "Final close should dismiss note panel")
	check(second.state == MemoryFragment.State.DECAYING, "Closing the final note must start its fragment decay")
	var occluded: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	occluded.position = second.position
	world.add_child(occluded)
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 4, 0.5)
	collision.shape = shape
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.position = Vector3(0, 2, 4)
	await physics_frame
	await physics_frame
	check(ui.pick_fragment(camera.unproject_position(occluded.get_orb_position())) == null, "Opaque collision geometry must block taps")
	var demo: Node = load("res://scenes/memories/foliage_demo.tscn").instantiate()
	check(demo.find_children("*", "MemoryFragment", true, false).size() == 2, "Demo should contain exactly two fragments")
	demo.free()
	await create_timer(first.decay_duration + 0.1).timeout
	check(not first._visual.visible and not first.is_processing(), "Collected orb must finish its wisp decay and stop animation")
	var repeatable: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	repeatable.once_per_visit = false
	repeatable.notes = ["Replay"]
	world.add_child(repeatable)
	check(repeatable.try_activate(player), "Repeatable fragment must activate")
	repeatable._cooldown = 0
	check(not repeatable.try_activate(player), "Reading must block repeat taps even for repeatable fragments")
	ui.advance_note()
	check(repeatable.state == MemoryFragment.State.DECAYING, "Repeatable fragments must also puff after reading")
	await create_timer(repeatable.decay_duration + 0.1).timeout
	check(repeatable._visual.visible and not repeatable.collected and repeatable.state != MemoryFragment.State.DECAYING, "Repeatable fragment must return after its puff")
	var empty: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	empty.notes = []
	world.add_child(empty)
	check(empty.try_activate(player) and empty.state == MemoryFragment.State.DECAYING, "Empty note list must not leave a fragment waiting for reading")
	world.queue_free()
	layer.queue_free()
	await process_frame
	print("Fragments: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
