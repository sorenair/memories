@tool
extends Node3D
## Local, replayable celebration. All sparks share one moving instance batch.
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/scenery/stadium/stadium_paint.gdshader")
const CAP_REST := 1.30
const CAP_PRESSED := 1.18
const LAUNCH_ORIGIN := Vector3(0, 1.55, 0)
const SPARKS_PER_BURST := 72
const COLORS := [Color("b82855"), Color("d98527"), Color("f9ce64")]
const DELAYS := [0.0, 0.36, 0.72]
const ASCENT := 0.8
const LIFETIME := 2.1

@export var burst_centers := PackedVector3Array([
	Vector3(-15, 7, -34), Vector3(0, 11, -37), Vector3(15, 7, -32)])
@export_range(1.0, 6.0, 0.1) var interaction_distance := 3.8
@export_group("Sound Effects")
## Played at the console each time a firework launches. Leave empty for silence.
@export var launch_sound: AudioStream
## Played over the field at each burst. Leave empty for silence.
@export var burst_sound: AudioStream
@onready var _button: MeshInstance3D = $Button
@onready var _base: MeshInstance3D = $Console
@onready var _sparks: MultiMeshInstance3D = $Sparks
var _elapsed := -1.0
var _velocities := PackedVector3Array()
var _batch: MultiMesh
var _launch_voices: Array[AudioStreamPlayer3D] = []
var _burst_voices: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	_build_console()
	set_process(false)
	if Engine.is_editor_hint():
		return
	add_to_group(&"memory_interactables")
	var spark := SphereMesh.new()
	spark.radius = 0.5
	spark.height = 1.0
	spark.radial_segments = 6
	spark.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	spark.material = material
	_batch = MultiMesh.new()
	_batch.transform_format = MultiMesh.TRANSFORM_3D
	_batch.use_colors = true
	_batch.mesh = spark
	_batch.instance_count = burst_centers.size() * SPARKS_PER_BURST
	_batch.visible_instance_count = 0
	var bounds := AABB(Vector3.ZERO, Vector3.ZERO)
	for center in burst_centers:
		bounds = bounds.expand(center)
	_batch.custom_aabb = bounds.grow(16.0)
	_sparks.multimesh = _batch
	for center in burst_centers:
		_launch_voices.append(_make_voice(LAUNCH_ORIGIN, 16.0, -6.0))
		_burst_voices.append(_make_voice(center, 28.0, -4.0))

func _build_console() -> void:
	var material := ShaderMaterial.new()
	material.shader = PAINT
	var maroon := Color("76233e")
	var dark := Color("47303e")
	var brass := Color("bd9959")
	var case := GEOMETRY.new()
	case.s = SurfaceTool.new()
	case.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	case.soft_box(Vector3(0, 0.14, 0), Vector3(2.88, 0.28, 2.02), dark, 0.11)
	case.soft_box(Vector3(0, 0.62, 0), Vector3(3.10, 0.84, 2.24), maroon, 0.15)
	case.soft_box(Vector3(0, 1.06, 0), Vector3(3.16, 0.17, 2.28), maroon.lightened(0.09), 0.07)
	case.disc(Vector3(0, 1.17, 0), 1.095, 0.09, dark, Vector3.UP, 0, 48)
	case.disc(Vector3(0, 1.21, 0), 1.065, 0.07, brass, Vector3.UP, 0, 48)
	for x in [-1.29, 1.29]:
		for z in [-0.88, 0.88]:
			case.disc(Vector3(x, 1.151, z), 0.075, 0.035, brass, Vector3.UP, 0, 12)
	case.soft_box(Vector3(0, 0.47, 1.125), Vector3(1.16, 0.25, 0.04), dark, 0.06)
	for x in [-0.37, 0.0, 0.37]:
		case.soft_box(Vector3(x, 0.47, 1.151), Vector3(0.19, 0.045, 0.016), brass, 0.02)
	_base.mesh = case.s.commit()
	_base.material_override = material

	var cap := GEOMETRY.new()
	cap.s = SurfaceTool.new()
	cap.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	cap.disc(Vector3(0, 0, 0), 1.02, 0.19, Color("c58a30"), Vector3.UP, 0, 48)
	cap.disc(Vector3(0, 0.095, 0), 0.96, 0.09, Color("f3bc53"), Vector3.UP, 3, 48)
	# An inlaid burst stays readable from the wide overlook camera.
	var inlay := Color("824127")
	cap.disc(Vector3(0, 0.146, 0), 0.115, 0.016, inlay, Vector3.UP, 0, 16)
	for spoke in 8:
		var angle := TAU * float(spoke) / 8.0 + PI / 8.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var length := 0.62 if spoke % 2 == 0 else 0.46
		var surface := Vector3.UP * 0.146
		cap.rod(surface + direction * 0.23, surface + direction * length, 0.033, inlay, 8)
		cap.disc(surface + direction * (length + 0.10), 0.048, 0.016, inlay, Vector3.UP, 0, 12)
	_button.mesh = cap.s.commit()
	_button.material_override = material
	_button.position.y = CAP_REST

func _make_voice(at: Vector3, unit_size: float, volume_db: float) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.position = at
	voice.unit_size = unit_size
	voice.volume_db = volume_db
	voice.bus = &"SFX"
	add_child(voice)
	return voice

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_button]

func get_interaction_tap_meshes() -> Array[MeshInstance3D]:
	return [_base, _button]

func can_interact(actor: Node3D) -> bool:
	return _elapsed < 0.0 and not burst_centers.is_empty() and is_instance_valid(actor) \
		and global_position.distance_squared_to(actor.global_position) <= interaction_distance ** 2

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	return play_shared_interaction(randi())

func play_shared_interaction(seed_value: int) -> bool:
	if _elapsed >= 0.0 or burst_centers.is_empty():
		return false
	# Read the current Inspector assignments for every replay.
	for voice in _launch_voices:
		voice.stream = launch_sound
	for voice in _burst_voices:
		voice.stream = burst_sound
	_velocities.clear()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in _batch.instance_count:
		var y := random.randf_range(-1.0, 1.0)
		var angle := random.randf_range(0.0, TAU)
		var radius := sqrt(1.0 - y * y)
		_velocities.append(Vector3(cos(angle) * radius, y, sin(angle) * radius)
			* random.randf_range(6.0, 15.5))
	_elapsed = 0.0
	_button.position.y = CAP_PRESSED
	set_process(true)
	return true

func _process(delta: float) -> void:
	var previous := _elapsed
	_elapsed += delta
	var drawn := 0
	var active := false
	for burst in burst_centers.size():
		var launch_at: float = DELAYS[burst % DELAYS.size()] + 0.63 * floorf(float(burst) / 3.0)
		var burst_at := launch_at + ASCENT
		if previous <= launch_at and _elapsed > launch_at and _launch_voices[burst].stream:
			_launch_voices[burst].play()
		if previous <= burst_at and _elapsed > burst_at and _burst_voices[burst].stream:
			_burst_voices[burst].play()
		var time := _elapsed - launch_at
		if time >= ASCENT + LIFETIME:
			continue
		active = true
		if time < 0.0:
			continue
		var center := burst_centers[burst]
		if time < ASCENT:
			for tail in 9:
				var progress := clampf((time - tail * 0.038) / ASCENT, 0.0, 1.0)
				var point := LAUNCH_ORIGIN.lerp(center, progress)
				point.y += sin(progress * PI) * 2.1
				_draw(drawn, point, center, 0.48 - tail * 0.037, COLORS[2])
				drawn += 1
			continue
		var age := time - ASCENT
		for spark in SPARKS_PER_BURST:
			var velocity := _velocities[burst * SPARKS_PER_BURST + spark]
			var point := center + velocity * (1.0 - exp(-1.5 * age)) / 1.5
			point.y -= 1.8 * age * age
			var fade := 1.0 - smoothstep(0.48, LIFETIME, age)
			var width := (0.38 if spark % 4 else 0.58) * fade
			var color: Color = COLORS[burst % COLORS.size()]
			if spark % 4 == 0 or age < 0.12:
				color = COLORS[2]
			_draw(drawn, point, velocity * exp(-1.5 * age) + Vector3.DOWN * (3.6 * age),
				width, color)
			drawn += 1
	_batch.visible_instance_count = drawn
	if not active:
		_elapsed = -1.0
		_button.position.y = CAP_REST
		set_process(false)

func _draw(index: int, point: Vector3, direction: Vector3, width: float, color: Color) -> void:
	var axis := direction.normalized()
	var up := Vector3.RIGHT if absf(axis.y) > 0.96 else Vector3.UP
	var orientation := Basis.looking_at(axis, up)
	_batch.set_instance_transform(index, Transform3D(
		orientation.scaled_local(Vector3(width, width, width * 2.6)), point))
	_batch.set_instance_color(index, color.srgb_to_linear())
