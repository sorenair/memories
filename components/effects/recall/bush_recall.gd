class_name BushRecall
extends Node
## Opt-in shader adapter: pigment blooms, then the bush rises and leaves unfurl.
signal finished
const LEAF_SHADER = preload("res://components/effects/recall/shaders/bush_recall.gdshader")
const WASH_SHADER = preload("res://components/effects/recall/shaders/wash_recall.gdshader")
@export var patch: PainterlyBush
@export var origin: Node3D
@export_range(0.5, 10.0, 0.1) var duration: float = 3.2
@export_range(0.2, 4.0, 0.1) var feather: float = 1.5
var progress: float = 0.0
var playing: bool = false
var auto_discover: bool = false
var wave_origin := Vector3.ZERO
var _materials: Array[ShaderMaterial] = []
var _foliage: ShaderMaterial
var _extent: float = 0.0
var _wave_radius: float = -0.3
var _wave_complete: bool = false

func _ready() -> void:
	reset()

func reset() -> void:
	playing = false
	wave_origin = origin.global_position if origin else patch.global_position
	_extent = 0.0
	# Include actual leaf bounds as well as the wash, with the component's sway margin.
	var batch: MultiMeshInstance3D = patch.get_node("Foliage")
	var bounds := batch.multimesh.custom_aabb.merge(AABB(
		Vector3(-patch.footprint.x * 0.625, 0, -patch.footprint.y * 0.625),
		Vector3(patch.footprint.x * 1.25, 0.01, patch.footprint.y * 1.25)))
	for index in range(8):
		var corner := patch.to_global(bounds.get_endpoint(index))
		_extent = maxf(_extent, Vector2(corner.x - wave_origin.x, corner.z - wave_origin.z).length())
	bind_materials()
	seek(0.0)

func play() -> void:
	playing = progress < 1.0

func replay() -> void:
	reset()
	play()

func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	apply_wave(wave_origin, lerpf(-0.3, get_wave_extent(), progress), progress >= 1.0)

func bind_materials() -> void:
	_foliage = patch.get_node("Foliage").material_override
	_foliage.shader = LEAF_SHADER
	var wash: ShaderMaterial = patch.get_node("GroundPigment").mesh.material
	wash.shader = WASH_SHADER
	_materials.assign([_foliage, wash])

func get_wave_extent() -> float:
	return _extent + feather + 0.3

func apply_wave(center: Vector3, radius: float, complete: bool = false) -> void:
	wave_origin = center
	_wave_radius = radius
	_wave_complete = complete
	for material in _materials:
		material.set_shader_parameter("recall_origin", center)
		material.set_shader_parameter("recall_radius", radius)
		material.set_shader_parameter("recall_feather", feather)
		material.set_shader_parameter("recall_complete", 1.0 if complete else 0.0)
	_foliage.set_shader_parameter("recall_base_y", patch.global_position.y)

func restore_state() -> void:
	apply_wave(wave_origin, _wave_radius, _wave_complete)

func _process(delta: float) -> void:
	if auto_discover and not playing and progress == 0.0:
		if preload("res://components/effects/recall/component_recall.gd").explorer_near(patch, patch.footprint):
			play()
	if patch.get_node("Foliage").material_override != _foliage:
		bind_materials()
		apply_wave(wave_origin, _wave_radius, _wave_complete)
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
