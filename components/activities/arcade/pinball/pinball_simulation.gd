extends RefCounted
## Continuous swept-circle collisions in local playfield coordinates.
## Independent of the cabinet's world collider, scale, rotation, or frame rate.
const LAYOUT = preload("res://components/activities/arcade/pinball/pinball_layout.gd")
const MAX_STEP := 1.0/240.0
const SEPARATION := 0.000025
var position := LAYOUT.HOME
var velocity := Vector2.ZERO
var elapsed := 0.0
var duration := 5.0
var running := false
var bumper_hits := 0
var reached_top := false
var _rng := RandomNumberGenerator.new()
var _circles: Array[Dictionary] = []
var _segments: Array[Dictionary] = []
var _bumper_cooldowns := PackedFloat32Array([0.0,0.0,0.0])

func _init() -> void:
	for i in range(LAYOUT.BUMPERS.size()):
		_circles.append({"center":LAYOUT.BUMPERS[i],"radius":LAYOUT.BUMPER_RADIUS,"bumper":i})
	for point in LAYOUT.posts(): _circles.append({"center":point,"radius":LAYOUT.POST_RADIUS,"bumper":-1})
	_segments.assign(LAYOUT.flippers())
	for center in LAYOUT.slings():
		_segments.append({"a":center-Vector2(0,LAYOUT.SLING_HALF_RUN),"b":center+Vector2(0,LAYOUT.SLING_HALF_RUN),"radius":LAYOUT.SLING_RADIUS})
	_segments.append({"a":LAYOUT.GUIDE_A,"b":LAYOUT.GUIDE_B,"radius":LAYOUT.GUIDE_RADIUS})
	_segments.append({"a":LAYOUT.DEFLECTOR_A,"b":LAYOUT.DEFLECTOR_B,"radius":LAYOUT.DEFLECTOR_RADIUS})

func launch(seed_value: int, play_duration: float, launch_speed: float) -> void:
	_rng.seed = seed_value
	position = LAYOUT.HOME
	velocity = Vector2(_rng.randf_range(-0.012,0.012),-launch_speed*_rng.randf_range(0.97,1.03))
	elapsed = 0.0
	duration = maxf(1.0,play_duration)
	running = true
	bumper_hits = 0
	reached_top = false
	_bumper_cooldowns.fill(0.0)

func advance(delta: float) -> void:
	var remaining := minf(maxf(0.0,delta),duration-elapsed)
	while running and remaining>0.0000001:
		var step := minf(remaining,MAX_STEP)
		_step(step)
		remaining -= step
	if running and elapsed>=duration-0.000001:
		velocity = Vector2.ZERO
		running = false

func _step(delta: float) -> void:
	elapsed = minf(duration,elapsed+delta)
	for i in range(_bumper_cooldowns.size()):
		_bumper_cooldowns[i] = maxf(0.0,_bumper_cooldowns[i]-delta)
	# Let the last part of a long run settle gently, instead of freezing at speed.
	var settle := smoothstep(maxf(0.0,duration-0.65),duration,elapsed)
	velocity.y += 0.92*(1.0-settle)*delta
	velocity *= exp(-(0.12+settle*settle*20.0)*delta)
	var time_left := delta
	for iteration in range(5):
		if time_left<0.0000001 or velocity.length_squared()<0.0000001: break
		var move := velocity*time_left
		var hit := _earliest_hit(position,move)
		if hit.is_empty():
			position += move
			break
		var fraction: float = hit.time
		var normal: Vector2 = hit.normal
		position += move*fraction+normal*SEPARATION
		if hit.get("drain",false) and elapsed>0.65:
			velocity = Vector2.ZERO
			running = false
			break
		velocity = velocity.bounce(normal)*0.91
		var bumper: int = hit.get("bumper",-1)
		if bumper>=0 and _bumper_cooldowns[bumper]<=0.0:
			velocity += normal*(0.32*(1.0-settle))
			_bumper_cooldowns[bumper] = 0.09
			bumper_hits += 1
		velocity = velocity.limit_length(3.4)
		time_left *= 1.0-fraction
	position = position.clamp(LAYOUT.FIELD_MIN+Vector2.ONE*LAYOUT.BALL_RADIUS,LAYOUT.FIELD_MAX-Vector2.ONE*LAYOUT.BALL_RADIUS)
	reached_top = reached_top or position.y<-0.40

func _earliest_hit(from: Vector2, move: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var minimum: Vector2 = LAYOUT.FIELD_MIN+Vector2.ONE*LAYOUT.BALL_RADIUS
	var maximum: Vector2 = LAYOUT.FIELD_MAX-Vector2.ONE*LAYOUT.BALL_RADIUS
	for axis in range(2):
		if absf(move[axis])<0.00000001: continue
		var boundary: float = minimum[axis] if move[axis]<0.0 else maximum[axis]
		var t: float = (boundary-from[axis])/move[axis]
		var n := Vector2.ZERO
		n[axis] = 1.0 if move[axis]<0.0 else -1.0
		if t>=-0.0000001 and t<=1.0:
			best = _closer(best,{"time":maxf(0.0,t),"normal":n,"drain":axis==1 and move.y>0.0})
	for circle in _circles:
		var hit := _circle_hit(from,move,circle.center,circle.radius+LAYOUT.BALL_RADIUS)
		if not hit.is_empty():
			hit["bumper"] = circle.bumper
			best = _closer(best,hit)
	for segment in _segments:
		var a: Vector2 = segment.a
		var b: Vector2 = segment.b
		var radius: float = segment.radius+LAYOUT.BALL_RADIUS
		var line := b-a
		var tangent := line.normalized()
		var normal := Vector2(-tangent.y,tangent.x)
		var speed := move.dot(normal)
		if absf(speed)>0.00000001:
			for side in [-1.0,1.0]:
				if speed*side>=0.0: continue
				var t: float = (side*radius-(from-a).dot(normal))/speed
				if t<0.0 or t>1.0: continue
				var along: float = (from+move*t-a).dot(tangent)
				if along>=0.0 and along<=line.length():
					best = _closer(best,{"time":t,"normal":normal*side})
		best = _closer(best,_circle_hit(from,move,a,radius))
		best = _closer(best,_circle_hit(from,move,b,radius))
	return best

func _circle_hit(from: Vector2, move: Vector2, center: Vector2, radius: float) -> Dictionary:
	var offset := from-center
	var a := move.length_squared()
	if a<0.0000000001: return {}
	var b := offset.dot(move)
	if b>=0.0: return {}
	var c := offset.length_squared()-radius*radius
	var discriminant := b*b-a*c
	if discriminant<0.0: return {}
	var t := (-b-sqrt(discriminant))/a
	if t< -0.000001 or t>1.0: return {}
	t = maxf(0.0,t)
	var normal := (from+move*t-center).normalized()
	return {"time":t,"normal":normal}

func _closer(current: Dictionary, candidate: Dictionary) -> Dictionary:
	if candidate.is_empty(): return current
	if current.is_empty() or candidate.time<current.time: return candidate
	return current

## Useful for authoring checks as well as gameplay: overlap includes ball radius.
func contains_ball(point: Vector2, tolerance: float = 0.00001) -> bool:
	var minimum: Vector2 = LAYOUT.FIELD_MIN+Vector2.ONE*LAYOUT.BALL_RADIUS-Vector2.ONE*tolerance
	var maximum: Vector2 = LAYOUT.FIELD_MAX-Vector2.ONE*LAYOUT.BALL_RADIUS+Vector2.ONE*tolerance
	if point.x<minimum.x or point.x>maximum.x or point.y<minimum.y or point.y>maximum.y: return false
	for circle in _circles:
		if point.distance_to(circle.center)<circle.radius+LAYOUT.BALL_RADIUS-tolerance: return false
	for segment in _segments:
		var closest := Geometry2D.get_closest_point_to_segment(point,segment.a,segment.b)
		if point.distance_to(closest)<segment.radius+LAYOUT.BALL_RADIUS-tolerance: return false
	return true
