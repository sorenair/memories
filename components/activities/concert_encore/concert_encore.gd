@tool
extends Node3D
## Cue a short stage finale and hand control back to the normal show.
const BUILDER = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const CAP_REST := 0.87
const CAP_PRESSED := 0.78
const PAINT = preload("res://components/scenery/stadium/stadium_paint.gdshader")
@export var screen: PainterlyConcertScreen
@export var rig: PainterlyRaveLights
@export var confetti_offset := Vector3(-1.6, 2.0, -4.5)
@onready var _pad: MeshInstance3D = $Pad
@onready var _button: MeshInstance3D = $Button
@onready var _confetti: GPUParticles3D = $Confetti
var _cue: Tween
var _resting_intensity: float
var _resting_pattern: int

func _ready() -> void:
	_build_console()
	if Engine.is_editor_hint():
		return
	_confetti.position = confetti_offset
	add_to_group(&"memory_interactables")

func _build_console() -> void:
	var material := ShaderMaterial.new()
	material.shader = PAINT
	var ink := Color("332e49")
	var lavender := Color("826aab")
	var trim := Color("d0b774")
	var case := BUILDER.new()
	case.s = SurfaceTool.new()
	case.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	case.soft_box(Vector3(0, 0.13, 0), Vector3(2.02, 0.26, 1.60), ink, 0.10)
	case.soft_box(Vector3(0, 0.40, 0), Vector3(2.28, 0.35, 1.82), Color("514362"), 0.13)
	case.soft_box(Vector3(0, 0.64, 0), Vector3(2.32, 0.18, 1.85), lavender, 0.08)
	case.disc(Vector3(0, 0.744, 0), 0.82, 0.07, ink, Vector3.UP, 0, 40)
	case.disc(Vector3(0, 0.775, 0), 0.79, 0.06, trim, Vector3.UP, 0, 40)
	for x in [-0.91, 0.91]:
		for z in [-0.67, 0.67]:
			case.disc(Vector3(x, 0.736, z), 0.064, 0.025, trim, Vector3.UP, 0, 12)
	case.soft_box(Vector3(0, 0.43, 0.92), Vector3(0.62, 0.09, 0.045), Color("79c4ad"), 0.025, 3)
	_pad.mesh = case.s.commit()
	_pad.material_override = material

	var cap := BUILDER.new()
	cap.s = SurfaceTool.new()
	cap.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	cap.disc(Vector3.ZERO, 0.75, 0.15, Color("8151a3"), Vector3.UP, 0, 40)
	cap.disc(Vector3.UP * 0.075, 0.70, 0.08, Color("cc91ed"), Vector3.UP, 3, 40)
	# An inlaid fan of confetti distinguishes this button from the stadium launcher.
	for index in 5:
		var angle := (index - 2) * 0.43
		var direction := Vector3(sin(angle), 0, -cos(angle))
		var origin := Vector3(0, 0.125, 0.33)
		var length := 0.52 if index % 2 == 0 else 0.65
		cap.rod(origin + direction * 0.22, origin + direction * length, 0.024, ink, 8)
		cap.disc(origin + direction * (length + 0.09), 0.047, 0.018, ink, Vector3.UP, 0, 12)
	_button.mesh = cap.s.commit()
	_button.material_override = material
	_button.position.y = CAP_REST

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_button]

func get_interaction_tap_meshes() -> Array[MeshInstance3D]:
	return [_pad, _button]

func can_interact(actor: Node3D) -> bool:
	return is_instance_valid(actor) and is_instance_valid(screen) and is_instance_valid(rig) \
		and (_cue == null or not _cue.is_running()) \
		and global_position.distance_squared_to(actor.global_position) < 3.4 ** 2

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	_resting_intensity = rig.intensity
	_resting_pattern = screen.pattern_mode
	screen.pattern_mode = 6
	_confetti.restart()
	_confetti.emitting = true
	_cue = create_tween().set_trans(Tween.TRANS_SINE)
	_cue.tween_property(rig, "intensity", 1.38, 0.55)
	_cue.parallel().tween_property(_button, "position:y", CAP_PRESSED, 0.12)
	_cue.tween_interval(1.40)
	_cue.tween_property(rig, "intensity", _resting_intensity, 1.25)
	_cue.parallel().tween_property(_button, "position:y", CAP_REST, 0.28)
	_cue.tween_callback(_restore_pattern)
	return true

func _restore_pattern() -> void:
	if is_instance_valid(screen):
		screen.pattern_mode = _resting_pattern

func _exit_tree() -> void:
	if _cue and _cue.is_running():
		_cue.kill()
		if is_instance_valid(rig):
			rig.intensity = _resting_intensity
		_restore_pattern()
