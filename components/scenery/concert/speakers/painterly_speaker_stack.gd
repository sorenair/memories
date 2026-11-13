@tool
class_name PainterlySpeakerStack
extends PainterlyConcertComponent
## A subwoofer and modular main cabinets, with restrained GPU-driven cone motion.
@export_group("Speaker Stack")
@export_range(1, 4, 1) var cabinet_count: int = 2:
	set(value):
		cabinet_count = clampi(value, 1, 4)
		_request_rebuild()
@export var subwoofer_enabled: bool = true:
	set(value):
		subwoofer_enabled = value
		_request_rebuild()
@export_range(0.6, 1.8, 0.05) var cabinet_width: float = 1.0:
	set(value):
		cabinet_width = clampf(value, 0.6, 1.8)
		_request_rebuild()
@export_range(0.45, 1.2, 0.05) var cabinet_depth: float = 0.78:
	set(value):
		cabinet_depth = clampf(value, 0.45, 1.2)
		_request_rebuild()
@export_group("Cone Motion")
## Visual tempo only; audio is authored on the memory/zone, not embedded here.
@export_range(0.0, 180.0, 1.0) var beat_bpm: float = 112.0:
	set(value):
		beat_bpm = clampf(value, 0, 180)
		_apply_material()
@export_range(0.0, 0.02, 0.001) var cone_motion: float = 0.008:
	set(value):
		cone_motion = clampf(value, 0, 0.02)
		_apply_material()
@export_range(0.0, 6.283, 0.1) var beat_phase: float = 0.0:
	set(value):
		beat_phase = value
		_apply_material()

func _build_geometry() -> Dictionary:
	var config := _config()
	for key in ["cabinet_count", "subwoofer_enabled", "cabinet_width", "cabinet_depth"]:
		config[key] = get(key)
	return GEOMETRY.new().speakers(config)

func _apply_material() -> void:
	super._apply_material()
	if _material:
		_material.set_shader_parameter("beat_bpm", beat_bpm)
		_material.set_shader_parameter("beat_phase", beat_phase)
		_material.set_shader_parameter("cone_motion", cone_motion)

func _build_details() -> void:
	var visual := _generated_root.get_node("PaintedProp") as MeshInstance3D
	visual.custom_aabb = visual.mesh.get_aabb().grow(0.025)
