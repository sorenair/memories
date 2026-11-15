@tool
class_name PainterlyPoolTable
extends PainterlyArcadeComponent
## Tap the table near any edge to rack and play a short physical break.
signal interaction_requested
signal interaction_started
signal interaction_cancelled
signal ball_pocketed(ball_number: int)
signal interaction_finished(pocketed_balls: int, scratched: bool)
const BAR_GEOMETRY = preload("res://components/activities/bar/shared/bar_geometry.gd")
const LAYOUT = preload("res://components/activities/bar/pool/pool_layout.gd")
const SIMULATION = preload("res://components/activities/bar/pool/pool_simulation.gd")
const BALL_PAINT = preload("res://components/activities/bar/pool/painted_pool_balls.gdshader")
const SOUNDS = preload("res://components/activities/arcade/shared/arcade_sounds.gd")
const WINDUP := 0.34
@export_group("Pool")
@export var cloth_color := Color("497e77"):
	set(value):
		cloth_color = value
		_request_rebuild()
@export_range(0.5, 3.0, 0.05) var interaction_range: float = 1.1:
	set(value):
		interaction_range = clampf(value, 0.5, 3)
@export_range(1.5, 5.5, 0.1) var launch_speed: float = 3.8:
	set(value):
		launch_speed = clampf(value, 1.5, 5.5)
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var sound_volume_db: float = -15.0:
	set(value):
		sound_volume_db = value
		if is_instance_valid(_sounds):
			_sounds.set_volume_db(value)
@export_tool_button("Preview pool break") var preview_pool = start_interaction

var last_pocketed_count: int = 0
var last_scratched: bool = false
var _simulation := SIMULATION.new()
var _balls: MultiMeshInstance3D
var _cue: MeshInstance3D
var _sounds: Node
var _playing: bool = false
var _launched: bool = false
var _clock: float = 0.0
var _pending_seed: int = 0
var _shown_hits: int = 0
var _shown_pockets := PackedInt32Array()
var _orientations: Array[Quaternion] = []
var _shown_positions := PackedVector2Array()
var _random := RandomNumberGenerator.new()

func _kind() -> StringName:
	return &"pool_table"

func _ready() -> void:
	_random.randomize()
	if not interaction_requested.is_connected(start_interaction):
		interaction_requested.connect(start_interaction)
	super._ready()
	if not Engine.is_editor_hint():
		add_to_group(&"memory_interactables")

func _build_geometry() -> Dictionary:
	return BAR_GEOMETRY.new().pool_table({"cabinet_color": cabinet_color, "accent_color": accent_color, "metal_color": metal_color, "cream_color": cream_color, "prop_seed": prop_seed, "cloth_color": cloth_color})

func rebuild() -> void:
	var cancelled := _playing
	_playing = false
	_simulation.running = false
	set_process(false)
	super.rebuild()
	if cancelled:
		interaction_cancelled.emit()

func _build_details(_result: Dictionary) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = LAYOUT.RADIUS
	sphere.height = LAYOUT.RADIUS * 2
	sphere.radial_segments = 24
	sphere.rings = 12
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = sphere
	batch.instance_count = 16
	batch.custom_aabb = AABB(Vector3(-LAYOUT.HALF.x - 0.1, LAYOUT.CLOTH_Y - 0.2, -LAYOUT.HALF.y - 0.1), Vector3(LAYOUT.FIELD_SIZE.x + 0.2, 0.30, LAYOUT.FIELD_SIZE.y + 0.2))
	for id in range(16):
		var color := Color(LAYOUT.COLORS[id]).srgb_to_linear()
		color.a = float(id) / 16.0
		batch.set_instance_custom_data(id, color)
	_balls = MultiMeshInstance3D.new()
	_balls.name = "BilliardBalls"
	_balls.multimesh = batch
	var paint := ShaderMaterial.new()
	paint.shader = BALL_PAINT
	_balls.material_override = paint
	_balls.scale = Vector3.ONE * prop_scale
	_balls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_balls.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated(_balls)
	var builder := GEOMETRY.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.rod(Vector3.ZERO, Vector3(0, 0, 0.73), 0.009, Color("c8ae7c"), 12)
	builder.rod(Vector3(0, 0, 0.73), Vector3(0, 0, 0.94), 0.013, cabinet_color.darkened(0.10), 12)
	builder.rod(Vector3(0, 0, -0.018), Vector3.ZERO, 0.008, Color("aac6c7"), 10)
	_cue = MeshInstance3D.new()
	_cue.name = "ShotCue"
	_cue.mesh = builder.s.commit()
	_cue.material_override = _material
	_cue.scale = Vector3.ONE * prop_scale
	# Raise the butt so the shaft clears the back cushion while the tip meets the ball.
	_cue.rotation.x = -0.17
	_cue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cue.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated(_cue)
	_sounds = SOUNDS.new()
	_sounds.name = "Sounds"
	_generated(_sounds)
	for pair in [[&"Strike", "pool_strike"], [&"Clack", "pool_clack"], [&"Pocket", "pool_pocket"]]:
		_sounds.add_cue(pair[0], load("res://components/activities/bar/audio/" + pair[1] + ".wav"), 0.0, 2)
	_sounds.set_volume_db(sound_volume_db)
	_reset_board()

func _reset_board() -> void:
	_simulation.reset()
	_shown_positions = _simulation.positions.duplicate()
	_shown_pockets.resize(16)
	_shown_pockets.fill(-1)
	_orientations.clear()
	for id in range(16):
		_orientations.append(Quaternion(Vector3.UP, id * 0.37))
	_cue.hide()
	_upload_balls()

func _recalled() -> bool:
	return not recall_enabled or not is_instance_valid(_recall) or _recall.progress >= 1.0

func can_interact(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not is_inside_tree():
		return false
	if _playing or not is_visible_in_tree() or not can_process() or not is_instance_valid(_balls) or not _recalled():
		return false
	if actor.get_viewport() != get_viewport():
		return false
	var local := to_local(actor.global_position) / prop_scale
	if absf(local.y * prop_scale * global_basis.y.length()) > 1.25:
		return false
	var half := LAYOUT.HALF + Vector2.ONE * LAYOUT.RAIL
	var at := Vector2(local.x, local.z)
	var closest := at.clamp(-half, half)
	var distance := global_basis * Vector3((at.x - closest.x) * prop_scale, 0, (at.y - closest.y) * prop_scale)
	return distance.length_squared() <= interaction_range * interaction_range

func try_activate(actor: Node3D) -> bool:
	return start_interaction() if can_interact(actor) else false

## Direct signal/Inspector hook; shared controller taps use try_activate(actor).
func start_interaction(seed_value: int = -1) -> bool:
	if _playing or not is_inside_tree() or not is_instance_valid(_balls) or not _recalled():
		return false
	_reset_board()
	_pending_seed = _random.randi() if seed_value < 0 else seed_value
	_clock = 0
	_shown_hits = 0
	_playing = true
	_launched = false
	_cue.show()
	_place_cue(0)
	set_process(true)
	interaction_started.emit()
	return true

func is_playing() -> bool:
	return _playing

func _process(delta: float) -> void:
	if not _playing:
		return
	var before := _clock
	_clock += clampf(delta, 0, 0.25)
	_place_cue(_clock)
	if not _launched and _clock >= WINDUP:
		_launched = true
		_simulation.break_shot(_pending_seed, launch_speed)
		_sounds.play(&"Strike")
	if _launched:
		_simulation.advance(maxf(0, _clock - WINDUP) - maxf(0, before - WINDUP))
		if _simulation.ball_hits + _simulation.cushion_hits > _shown_hits:
			_shown_hits = _simulation.ball_hits + _simulation.cushion_hits
			_sounds.play(&"Clack", 0.95 + float(_shown_hits % 5) * 0.035)
		_upload_balls()
		if not _simulation.running:
			_playing = false
			_cue.hide()
			set_process(false)
			last_pocketed_count = _simulation.pocketed_count()
			last_scratched = _simulation.scratched()
			interaction_finished.emit(last_pocketed_count, last_scratched)

func _place_cue(time: float) -> void:
	if time > WINDUP + 0.18:
		_cue.hide()
		return
	var draw := sin(clampf(time / WINDUP, 0, 1) * PI) * 0.14
	_cue.position = Vector3(LAYOUT.HOME.x, LAYOUT.CLOTH_Y + LAYOUT.RADIUS + draw * sin(0.17), LAYOUT.HOME.y + LAYOUT.RADIUS + 0.015 + draw * cos(0.17)) * prop_scale

func _upload_balls() -> void:
	var mouths := LAYOUT.pockets()
	for id in range(16):
		var at: Vector2 = _simulation.visual_position(id)
		var y: float = LAYOUT.CLOTH_Y + LAYOUT.RADIUS
		var size := 1.0
		if _simulation.pocket_ids[id] >= 0:
			if _shown_pockets[id] < 0:
				_shown_pockets[id] = _simulation.pocket_ids[id]
				_sounds.play(&"Pocket")
				ball_pocketed.emit(id)
			var t := smoothstep(0, 0.28, _simulation.elapsed - _simulation.pocket_times[id])
			at = at.lerp(mouths[_simulation.pocket_ids[id]], t)
			y -= t * 0.16
			size = 1.0 - t * 0.96
		else:
			var travel := at - _shown_positions[id]
			if travel.length_squared() > 0.000000001:
				_orientations[id] = (Quaternion(Vector3(travel.y, 0, -travel.x).normalized(), travel.length() / LAYOUT.RADIUS) * _orientations[id]).normalized()
		_shown_positions[id] = at
		_balls.multimesh.set_instance_transform(id, Transform3D(Basis(_orientations[id]).scaled(Vector3.ONE * size), Vector3(at.x, y, at.y)))
