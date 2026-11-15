extends SceneTree
const MODEL = preload("res://components/activities/bar/pool/pool_simulation.gd")
const LAYOUT = preload("res://components/activities/bar/pool/pool_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	check(LAYOUT.cloth_outline().size() == 54 and not Geometry2D.triangulate_polygon(LAYOUT.cloth_outline()).is_empty(), "The cloth must triangulate with all six pocket openings")
	var model := MODEL.new()
	var initial: PackedVector2Array = model.positions.duplicate()
	for a in range(15):
		for b in range(a + 1, 16):
			check(initial[a].distance_to(initial[b]) >= LAYOUT.RADIUS * 2 - 0.000001, "Racked balls must not overlap before the shot")
	var results := []
	for seed_value in [1, 4, 42, 113, 921, 3331]:
		model.break_shot(seed_value)
		var maximum_energy := model.energy()
		var moved := PackedByteArray()
		moved.resize(16)
		moved.fill(0)
		for frame in range(700):
			if not model.running:
				break
			model.advance(1.0 / 30.0)
			check(model.energy() <= maximum_energy + 0.00001, "Friction and collisions must not create energy")
			for id in range(16):
				check(model.positions[id].is_finite() and model.velocities[id].is_finite(), "Pool state must remain finite")
				if model.positions[id].distance_to(initial[id]) > 0.04:
					moved[id] = 1
				if model.pocket_ids[id] < 0:
					check(absf(model.positions[id].x) <= LAYOUT.HALF.x - LAYOUT.RADIUS + 0.00001 and absf(model.positions[id].y) <= LAYOUT.HALF.y - LAYOUT.RADIUS + 0.00001, "Every active ball must stay inside the cushions")
		var count := 0
		for value in moved:
			count += value
		check(not model.running and model.energy() < 0.000001, "Every break must settle and finish")
		check(count >= 12 and model.ball_hits > 15, "A real break must propagate through the triangle and scatter most balls")
		results.append({"seed": seed_value, "hits": model.ball_hits, "moved": count, "potted": model.pocketed_count()})
	var slow := MODEL.new()
	var fast := MODEL.new()
	slow.break_shot(531)
	fast.break_shot(531)
	for frame in range(90):
		slow.advance(1.0 / 30.0)
	for frame in range(432):
		fast.advance(1.0 / 144.0)
	check(slow.positions == fast.positions and slow.pocket_ids == fast.pocket_ids, "30 and 144 FPS must produce identical fixed-step physical state")
	for pocket in range(6):
		model.reset()
		model.positions[0] = LAYOUT.pockets()[pocket].lerp(Vector2.ZERO, 0.012)
		model.running = true
		model.advance(MODEL.STEP)
		check(model.pocket_ids[0] == pocket and model.scratched(), "Every pocket must capture the cue ball")
		check(model.pocketed_count() == 0, "A scratch must not count as a potted object ball")
	model.break_shot(7)
	model.positions[0] = Vector2(LAYOUT.HALF.x - 0.045, 0.6)
	model.velocities[0] = Vector2(1, 0)
	model.advance(0.08)
	check(model.velocities[0].x < 0 and model.cushion_hits > 0, "Cushions must reflect a ball heading into a solid rail")
	model.reset()
	check(model.positions == initial and not model.running and not model.scratched(), "A new rack must restore all sixteen balls")
	print("Pool simulation: ", "PASS" if failures == 0 else "FAIL", " | ", results)
	quit(failures)
