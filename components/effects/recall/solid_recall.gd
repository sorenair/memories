class_name SolidRecall
extends Node
## Default solid recall adapter: scan existing geometry upward with a white edge.
## Components provide their mesh, shadow material and optional collision body.
signal finished
@export var patch: Node3D
@export var origin: Node3D # Common effects-study API; scan stays local to the mesh.
@export_range(0.5, 10.0, 0.1) var duration: float = 2.4
var progress: float = 0.0
var playing: bool = false
var auto_discover: bool = false
var _material: ShaderMaterial
var _shadow: ShaderMaterial
var _shadow_color := Color(0.25, 0.29, 0.25, 0.28)
var _bounds := AABB()

func _ready() -> void:
	reset()

func reset() -> void:
	playing = false
	bind_materials()
	seek(0.0)

func play() -> void:
	playing = progress < 1.0

func replay() -> void:
	reset()
	play()

func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	restore_state()

func bind_materials() -> void:
	var mesh: MeshInstance3D = patch.get_recall_mesh()
	_material = null
	_shadow = null
	if not mesh:
		return # Empty rock clusters have no surfaces.
	_bounds = mesh.mesh.get_aabb()
	_material = mesh.material_override
	_material.shader = patch.get_recall_shader()
	_material.set_shader_parameter("recall_solid_bounds", Vector2(_bounds.position.y, _bounds.end.y))
	_shadow = patch.get_recall_shadow_material()

func restore_state() -> void:
	if _material:
		_material.set_shader_parameter("recall_solid_progress", smoothstep(0.0, 1.0, progress))
	if _shadow:
		var color := _shadow_color
		color.a *= smoothstep(0.0, 0.85, progress)
		_shadow.set_shader_parameter("shadow_color", color)
	var body: Node = patch.get_recall_collision_body()
	if body:
		for collision in body.get_children():
			# Always queue the latest state: a rebuild may have an older change pending.
			collision.set_deferred("disabled", progress < 1.0)

func _process(delta: float) -> void:
	if not _material:
		return
	if auto_discover and not playing and progress == 0.0:
		var center := _bounds.get_center()
		if preload("res://components/effects/recall/component_recall.gd").explorer_near(patch, Vector2(_bounds.size.x, _bounds.size.z), Vector2(center.x, center.z)):
			play()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
