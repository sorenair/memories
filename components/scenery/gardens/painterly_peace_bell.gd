@tool
extends PainterlyConcertComponent
## An open timber shelter with a suspended cast-bronze temple bell.
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
const BELL_POSITION := Vector3(0.27, 0, 0.46)
const STRIKER_PIVOT := Vector3(1.54, 2.75, 0.46)
const LOG_Y := -1.55
const HALF_LOG := 0.48

signal struck

@export var strike_sound: AudioStream

var _bell: MeshInstance3D
var _striker: MeshInstance3D
var _gong: AudioStreamPlayer
var _swing: Tween

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		add_to_group(&"memory_interactables")

func can_interact(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.get_viewport() != get_viewport():
		return false
	if not is_visible_in_tree() or (_swing != null and _swing.is_running()):
		return false
	if recall_enabled and (not is_instance_valid(_recall_effect) or _recall_effect.progress < 1.0):
		return false
	var offset := to_local(actor.global_position) - STRIKER_PIVOT
	return Vector2(offset.x, offset.z).length_squared() <= 2.8 * 2.8 and absf(offset.y + STRIKER_PIVOT.y) < 1.35

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor) or not is_instance_valid(_striker):
		return false
	_swing = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing.tween_property(_striker, "rotation:z", 0.32, 0.43)
	_swing.tween_interval(0.38)
	_swing.tween_property(_striker, "rotation:z", -0.168, 0.29).set_ease(Tween.EASE_IN)
	_swing.tween_callback(_ring)
	var rebound := _swing.parallel().tween_property(_striker, "rotation:z", 0.105, 0.24)
	rebound.set_ease(Tween.EASE_OUT)
	_swing.tween_property(_striker, "rotation:z", -0.05, 0.31)
	_swing.tween_property(_striker, "rotation:z", 0.0, 0.29)
	_swing.tween_interval(0.48)
	return true

func _ring() -> void:
	if is_instance_valid(_gong) and strike_sound:
		_gong.stream = strike_sound
		_gong.play()
	var vibration := create_tween().bind_node(_bell).set_trans(Tween.TRANS_SINE)
	for angle: float in [0.085, -0.053, 0.034, -0.021, 0.012, 0.0]:
		vibration.tween_property(_bell, "rotation:z", angle, 0.22)
	struck.emit()

func get_interaction_tap_position() -> Vector3:
	return _striker.to_global(Vector3(0, LOG_Y, 0))

func get_interaction_tap_radius() -> float:
	return 30.0

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_striker, _bell]

func _build_geometry() -> Dictionary:
	var builder := GEOMETRY.new()
	builder.begin(_config())
	for x: float in [-1.22, 1.22]:
		for z: float in [-0.94, 0.94]:
			builder.soft_box(Vector3(x, 0.10, z), Vector3(0.37, 0.2, 0.37), trim_color)
			builder.box(Vector3(x, 1.53, z), Vector3(0.20, 2.86, 0.22), body_color)
			builder.box(Vector3(x, 2.77, z), Vector3(0.32, 0.23, 0.35), body_color.lightened(0.04))
			builder.rod(Vector3(x, 2.24, z), Vector3(x * 0.64, 2.78, z), 0.058, body_color, 6)
			builder.colliders.append({"name": "Column", "center": Vector3(x, 1.42, z), "size": Vector3(0.31, 2.84, 0.31)})
		builder.box(Vector3(x, 2.81, 0), Vector3(0.25, 0.23, 2.73), body_color)
	for z: float in [-0.94, 0.94]:
		builder.box(Vector3(0, 2.81, z), Vector3(3.20, 0.22, 0.24), body_color)
	builder.box(Vector3(0.33, 2.87, 0.46), Vector3(3.10, 0.23, 0.24), body_color.darkened(0.17))

	# Three broad shingled courses carry a shallow curve down to the eaves.
	var widths := PackedFloat32Array([0.0, 0.65, 1.30, 1.80])
	var heights := PackedFloat32Array([3.71, 3.41, 3.11, 3.04])
	var depths := PackedFloat32Array([0.92, 1.09, 1.31, 1.39])
	for side: float in [-1.0, 1.0]:
		for course in range(3):
			var a := Vector3(widths[course] * side, heights[course], depths[course])
			var b := Vector3(widths[course+1] * side, heights[course+1], depths[course+1])
			var c := b * Vector3(1,1,-1)
			var d := a * Vector3(1,1,-1)
			builder.quad(a, b, c, d, accent_color.lightened(float(course - 1) * 0.023))
			builder.rod(b, c, 0.049, accent_color.darkened(0.11), 8)
			builder.rod(a, b, 0.042, body_color.darkened(0.10), 8)
			builder.rod(d, c, 0.042, body_color.darkened(0.10), 8)
	builder.rod(Vector3(0, 3.74, -1.02), Vector3(0, 3.74, 1.02), 0.078, accent_color.darkened(0.13), 12)

	builder.box(Vector3(1.54, 2.80, 0.46), Vector3(0.19, 0.18, 1.54), body_color.darkened(0.11))
	for x: float in [STRIKER_PIVOT.x - 0.32, STRIKER_PIVOT.x + 0.32]:
		builder.rod(Vector3(x, 2.80, 0.29), Vector3(x, 2.80, 0.63), 0.035, trim_color.darkened(0.15), 8)
	builder.colliders.append({"name": "Bell", "center": BELL_POSITION + Vector3(0, 1.55, 0), "size": Vector3(1.15, 1.22, 1.15)})
	return builder.finish()

func _build_details() -> void:
	if _swing != null:
		_swing.kill()
	var builder := GEOMETRY.new()
	builder.begin(_config())
	builder.frame = Transform3D(Basis.IDENTITY, Vector3.DOWN * 2.76)
	var bronze := Color("687d60")
	var silhouette: Array[Vector2] = [
		Vector2(0, 2.32), Vector2(0.21, 2.32), Vector2(0.38, 2.23),
		Vector2(0.47, 2.09), Vector2(0.51, 1.91), Vector2(0.55, 1.18),
		Vector2(0.61, 1.03), Vector2(0.62, 0.96), Vector2(0.53, 0.94),
		Vector2(0.47, 1.10), Vector2(0.39, 1.91), Vector2(0, 2.03)]
	TURNED.lathe(builder, silhouette, bronze, 0, 36)
	for y: float in [1.11, 1.64, 2.04]:
		builder.disc(Vector3(0, y, 0), lerpf(0.565, 0.49, (y - 1.11) / 0.93), 0.028,
			bronze.lightened(0.11), Vector3.UP, 0, 36)
	builder.rod(Vector3(0, 2.25, 0), Vector3(0, 2.80, 0), 0.077, bronze.darkened(0.16), 12)
	_bell = _add_visual("Bell", builder.finish().mesh)
	_bell.position = BELL_POSITION + Vector3.UP * 2.76

	# The log's long axis points at the bell. Both ropes swing with the log.
	builder = GEOMETRY.new()
	builder.begin(_config())
	builder.rod(Vector3(-HALF_LOG, LOG_Y, 0), Vector3(HALF_LOG, LOG_Y, 0), 0.105, Color("9b744e"), 14)
	builder.disc(Vector3(-HALF_LOG, LOG_Y, 0), 0.102, 0.024, Color("c89b69"), Vector3.RIGHT, 0, 14)
	for x: float in [-0.32, 0.32]:
		for side: float in [-1, 1]:
			builder.rod(Vector3(x, LOG_Y, side * 0.084), Vector3(x, 0, side * 0.05), 0.018, trim_color, 8)
	_striker = _add_visual("Striker", builder.finish().mesh)
	_striker.position = STRIKER_PIVOT

	# The nearby tap already gates this cue. Keep its level independent of camera distance.
	_gong = AudioStreamPlayer.new()
	_gong.name = "Gong"
	_gong.bus = &"SFX"
	_gong.volume_db = -3.0
	_generated_root.add_child(_gong)
