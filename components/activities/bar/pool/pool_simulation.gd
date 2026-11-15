extends RefCounted
## Equal-mass disk collisions and pocket capture. No scene nodes or rigid bodies.
const LAYOUT = preload("res://components/activities/bar/pool/pool_layout.gd")
const STEP := 1.0 / 240.0
const FRICTION := 0.26
const BALL_RESTITUTION := 0.96
const CUSHION_RESTITUTION := 0.80
const MAX_DURATION := 20.0
var positions := PackedVector2Array()
var previous := PackedVector2Array()
var velocities := PackedVector2Array()
var pocket_ids := PackedInt32Array()
var pocket_times := PackedFloat32Array()
var elapsed: float = 0.0
var running: bool = false
var ball_hits: int = 0
var cushion_hits: int = 0
var _accumulator: float = 0.0
var _quiet_time: float = 0.0
var _pockets := LAYOUT.pockets()

func _init() -> void:
	reset()

func reset() -> void:
	positions = LAYOUT.rack()
	previous = positions.duplicate()
	velocities.resize(16)
	velocities.fill(Vector2.ZERO)
	pocket_ids.resize(16)
	pocket_ids.fill(-1)
	pocket_times.resize(16)
	pocket_times.fill(-1.0)
	elapsed = 0
	_accumulator = 0
	_quiet_time = 0
	running = false
	ball_hits = 0
	cushion_hits = 0

func break_shot(seed_value: int, speed: float = 3.8) -> void:
	reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# A small seeded aim offset breaks the perfect symmetry of an ideal rack.
	var target := LAYOUT.APEX + Vector2(rng.randf_range(-0.018, 0.018), 0)
	velocities[0] = (target - positions[0]).normalized() * clampf(speed, 1.5, 5.5)
	running = true

func advance(delta: float) -> void:
	if not running:
		return
	# Bound catch-up work after backgrounding; normal render rates share exact ticks.
	_accumulator += clampf(delta, 0.0, 0.25)
	while running and _accumulator + 0.000000001 >= STEP:
		_accumulator = maxf(0.0, _accumulator - STEP)
		_step()

func visual_position(index: int) -> Vector2:
	if not running or pocket_ids[index] >= 0:
		return positions[index]
	return previous[index].lerp(positions[index], clampf(_accumulator / STEP, 0, 1))

func _step() -> void:
	previous = positions.duplicate()
	elapsed += STEP
	var drag := FRICTION + smoothstep(MAX_DURATION - 1.5, MAX_DURATION, elapsed) * 9.0
	for index in range(16):
		if pocket_ids[index] >= 0:
			continue
		positions[index] += velocities[index] * STEP
		var speed := velocities[index].length()
		velocities[index] = velocities[index] * maxf(0.0, speed - drag * STEP) / speed if speed > 0.00001 else Vector2.ZERO
		_capture(index)
	# Several sequential impulse passes propagate the break through a tight rack.
	for iteration in range(4):
		for a in range(15):
			if pocket_ids[a] >= 0:
				continue
			for b in range(a + 1, 16):
				if pocket_ids[b] >= 0:
					continue
				var delta := positions[b] - positions[a]
				var distance_sq := delta.length_squared()
				var diameter: float = LAYOUT.RADIUS * 2.0
				if distance_sq >= diameter * diameter:
					continue
				var distance := sqrt(distance_sq)
				var normal := delta / distance if distance > 0.000001 else Vector2.RIGHT
				var correction := normal * ((diameter - distance) * 0.5 + 0.0000005)
				positions[a] -= correction
				positions[b] += correction
				var closing := (velocities[b] - velocities[a]).dot(normal)
				if closing < -0.00001:
					var impulse := -(1.0 + BALL_RESTITUTION) * closing * 0.5
					velocities[a] -= normal * impulse
					velocities[b] += normal * impulse
					if impulse > 0.025:
						ball_hits += 1
		for index in range(16):
			if pocket_ids[index] < 0 and not _capture(index):
				_cushions(index)
	var moving := false
	for index in range(16):
		if pocket_ids[index] < 0 and velocities[index].length_squared() > 0.0004:
			moving = true
	_quiet_time = 0.0 if moving else _quiet_time + STEP
	if _quiet_time >= 0.35 or elapsed >= MAX_DURATION:
		velocities.fill(Vector2.ZERO)
		running = false

func _capture(index: int) -> bool:
	if pocket_ids[index] >= 0:
		return true
	for pocket in range(6):
		if positions[index].distance_squared_to(_pockets[pocket]) < LAYOUT.POCKET_RADIUS * LAYOUT.POCKET_RADIUS:
			pocket_ids[index] = pocket
			pocket_times[index] = elapsed
			velocities[index] = Vector2.ZERO
			return true
	return false

func _cushions(index: int) -> void:
	var limit := LAYOUT.HALF - Vector2.ONE * LAYOUT.RADIUS
	var point := positions[index]
	var velocity := velocities[index]
	for axis in range(2):
		if absf(point[axis]) > limit[axis]:
			var side := signf(point[axis])
			point[axis] = side * limit[axis]
			if velocity[axis] * side > 0:
				velocity[axis] *= -CUSHION_RESTITUTION
				cushion_hits += 1
	positions[index] = point
	velocities[index] = velocity

func pocketed_count() -> int:
	var count := 0
	for index in range(1, 16):
		if pocket_ids[index] >= 0:
			count += 1
	return count

func scratched() -> bool:
	return pocket_ids[0] >= 0

func energy() -> float:
	var result := 0.0
	for velocity in velocities:
		result += velocity.length_squared() * 0.5
	return result
