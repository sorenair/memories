class_name GrassRecall
extends Node
## Opt-in grass adapter. Existing components and their default shaders are unchanged.
## Each component independently discovers explorers and plays its local animation.
signal finished

const GRASS_SHADER = preload("res://components/effects/recall/shaders/grass_recall.gdshader")
const WASH_SHADER = preload("res://components/effects/recall/shaders/wash_recall.gdshader")

@export var patch: PainterlyGrassPatch
@export var origin: Node3D
@export_range(0.5, 10.0, 0.1) var duration: float = 3.2
@export_range(0.2, 4.0, 0.1) var feather: float = 1.5

var progress: float = 0.0
var playing: bool = false
var auto_discover: bool = false
var wave_origin := Vector3.ZERO
var _materials: Array[ShaderMaterial] = []
var _tufts: ShaderMaterial
var _leaves: ShaderMaterial
var _extent: float = 0.0
var _wave_radius: float = -0.3
var _wave_complete: bool = false

func _ready() -> void:
	reset()

func reset() -> void:
	playing = false
	wave_origin = origin.global_position if origin else patch.global_position
	_extent = 0.0
	# Include the entire wash plane and arbitrary patch rotation/scale.
	for x in [-0.625, 0.625]:
		for z in [-0.625, 0.625]:
			var corner := patch.to_global(Vector3(patch.patch_size.x * x, 0, patch.patch_size.y * z))
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
	apply_wave(wave_origin, lerpf(-0.3, _extent + feather + 0.3, progress), progress >= 1.0)

func bind_materials() -> void:
	_tufts = patch.get_node("GrassTufts").material_override
	_tufts.shader = GRASS_SHADER
	_leaves = _tufts.duplicate() as ShaderMaterial
	_leaves.set_shader_parameter("recall_groundcover", true)
	patch.get_node("PaintedLeaves").material_override = _leaves
	var wash: ShaderMaterial = patch.get_node("GroundPigment").mesh.material
	wash.shader = WASH_SHADER
	_materials.assign([_tufts, _leaves, wash])

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

func restore_state() -> void:
	apply_wave(wave_origin, _wave_radius, _wave_complete)

func _process(delta: float) -> void:
	if auto_discover and not playing and progress == 0.0:
		if preload("res://components/effects/recall/component_recall.gd").explorer_near(patch, patch.patch_size):
			play()
	# The authoring component may replace its materials after a shape/seed change.
	if patch.get_node("GrassTufts").material_override != _tufts:
		bind_materials()
		apply_wave(wave_origin, _wave_radius, _wave_complete)
	# The component maintains wind, player and palette on its original material.
	for key in [&"wind_strength", &"wind_speed", &"explorer_position", &"root_color", &"shade_color", &"leaf_color", &"sun_color"]:
		_leaves.set_shader_parameter(key, _tufts.get_shader_parameter(key))
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
