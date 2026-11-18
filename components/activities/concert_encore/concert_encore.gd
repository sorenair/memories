extends Node3D
## Cue a short stage finale and hand control back to the normal show.
const BUILDER = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/scenery/stadium/stadium_paint.gdshader")
@export var screen: PainterlyConcertScreen
@export var rig: PainterlyRaveLights
@export var confetti_offset := Vector3(-1.6, 2.0, -4.5)
@onready var _pad: MeshInstance3D = $Pad
@onready var _confetti: GPUParticles3D = $Confetti
var _cue: Tween
var _resting_intensity: float
var _resting_pattern: int

func _ready() -> void:
	var builder := BUILDER.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.soft_box(Vector3(0, 0.14, 0), Vector3(0.9, 0.28, 0.77), Color("38364e"), 0.09)
	builder.disc(Vector3(0, 0.29, 0), 0.28, 0.10, Color("bb83da"), Vector3.UP, 3, 16)
	# Three gold marks suggest the burst of color this pad cues.
	for index in 3:
		builder.rod(Vector3((index-1)*0.12, 0.35, 0.025),
			Vector3((index-1)*0.19, 0.35, -0.15), 0.018, Color("ffe39a"), 6)
	_pad.mesh = builder.s.commit()
	var material := ShaderMaterial.new()
	material.shader = PAINT
	_pad.material_override = material
	_confetti.position = confetti_offset
	add_to_group(&"memory_interactables")

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_pad]

func can_interact(actor: Node3D) -> bool:
	return is_instance_valid(actor) and is_instance_valid(screen) and is_instance_valid(rig) \
		and (_cue == null or not _cue.is_running()) \
		and global_position.distance_squared_to(actor.global_position) < 2.7 ** 2

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
	_cue.tween_interval(1.40)
	_cue.tween_property(rig, "intensity", _resting_intensity, 1.25)
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
