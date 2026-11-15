extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func finish_shot(pool: PainterlyPoolTable) -> void:
	for frame in range(1400):
		if not pool.is_playing():
			break
		pool._process(1.0 / 60.0)

func run() -> void:
	var stage: Node3D = load("res://tests/scenes/bar_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var pool: PainterlyPoolTable = stage.subject.get_node("PoolTable")
	var jukebox: PainterlyJukebox = stage.subject.get_node("Jukebox")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	var controller: Node = stage.get_node("InteractionController")
	check(pool.get_children().is_empty() and jukebox.get_children().is_empty(), "Generated bar parts must not serialize into authored scenes")
	check(not pool.is_processing() and not jukebox.is_processing(), "Idle pool and electronic display must not need CPU frame callbacks")
	check(pool.get_node("BilliardBalls").multimesh.instance_count == 16, "Pool must begin with fifteen object balls and a cue ball")
	check(pool.has_node("Collision") and jukebox.has_node("Collision"), "Both bar props must block explorer movement")
	var events := {"started": 0, "finished": 0, "cancelled": 0}
	pool.interaction_started.connect(func(): events.started += 1)
	pool.interaction_finished.connect(func(_count: int, _scratch: bool): events.finished += 1)
	pool.interaction_cancelled.connect(func(): events.cancelled += 1)
	actor.global_position = pool.to_global(Vector3(0, 0.03, 4))
	check(not pool.can_interact(actor) and not pool.try_activate(actor), "Out-of-range direct taps must be rejected")
	actor.global_position = pool.to_global(Vector3(1.0, 0.03, 0.2))
	actor.reset_physics_interpolation()
	check(pool.can_interact(actor), "Approaching a long side must allow interaction")
	controller.refresh_target()
	check(controller.request_interaction(pool), "The shared controller must start a pool break")
	check(pool.is_playing() and events.started == 1, "One accepted interaction must start one run")
	check(not controller.request_interaction(pool) and not pool.try_activate(actor), "Busy pool tables must reject repeated input")
	pool.set_process(false)
	pool._process(0.20)
	check(pool._simulation.positions[0] == pool.LAYOUT.HOME, "The cue must pull back before the ball launches")
	pool._process(0.20)
	check(pool._simulation.positions[0].y < pool.LAYOUT.HOME.y, "The cue must actually launch the ball toward the triangle")
	finish_shot(pool)
	check(not pool.is_playing() and events.finished == 1, "A shot must settle and emit exactly one result")
	check(pool.last_pocketed_count == pool._simulation.pocketed_count(), "Completion must report real pocketed balls")
	check(pool.can_interact(actor), "A settled table must become available for another break")
	pool.interaction_requested.emit()
	pool.set_process(false)
	check(pool.is_playing() and events.started == 2, "The component's standalone interaction signal must launch a run")
	pool.rebuild()
	check(not pool.is_playing() and events.cancelled == 1, "Rebuilding during a shot must cancel it cleanly")
	check(pool._simulation.positions == pool.LAYOUT.rack(), "A rebuilt table must restore a complete rack")
	pool.rotation.y = 0.7
	pool.prop_scale = 1.4
	pool.rebuild()
	actor.global_position = pool.to_global(Vector3(0, 0, -2.0))
	check(pool.can_interact(actor), "Range must work from either end after rotation and scaling")
	actor.global_position += Vector3.UP * 3
	check(not pool.can_interact(actor), "An explorer on another level must not activate the table")
	for prop in [pool, jukebox]:
		prop.recall_enabled = true
		var recall: Node = prop.get_recall_controller()
		recall.set_process(false)
		recall.seek(0.45)
		prop.rebuild()
		check(prop.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.45), "Rebuilding bar props must preserve recall progress")
		check(prop.has_node("Collision"), "Recall must keep solid body collision safe")
		prop.recall_enabled = false
		var packed := PackedScene.new()
		check(packed.pack(prop) == OK, "Bar props must pack as reusable parameter scenes")
		var restored: Node = packed.instantiate()
		check(restored.get_children().is_empty(), "Saved props must not contain generated meshes")
		restored.free()
	var screen: Node = jukebox.get_node("MusicDisplay")
	jukebox.screen_accent = Color("f6ba83")
	jukebox.animation_speed = 0
	check(jukebox.get_node("MusicDisplay") == screen, "Jukebox display controls must update without rebuilding geometry")
	pool.collision_enabled = false
	pool.rebuild()
	check(not pool.has_node("Collision"), "Scenery-only tables must support disabling their collision")
	print("Bar component checks: ", "PASS" if failures == 0 else "FAIL")
	stage.free()
	await create_timer(0.15).timeout
	quit(failures)
