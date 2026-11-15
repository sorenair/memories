extends Node
## Shared proximity fade for procedural effects exposing recall_materials and footprint.
signal finished
const RECALL = preload("res://components/effects/recall/component_recall.gd")
var patch: Node3D
var auto_discover: bool = false
var playing: bool = false
var progress: float = 0.0
var duration: float = 1.8
var _materials: Array[ShaderMaterial] = []
func _ready() -> void:
	reset()
func bind_materials() -> void:
	_materials = patch.recall_materials().duplicate()
func restore_state() -> void:
	for material in _materials:
		material.set_shader_parameter("recall_visibility", smoothstep(0.0, 1.0, progress))
func reset() -> void:
	playing = false
	bind_materials()
	seek(0.0)
func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	restore_state()
func play() -> void:
	playing = progress < 1.0
func replay() -> void:
	reset()
	play()
func _process(delta: float) -> void:
	var near := false
	if auto_discover and not playing and progress == 0.0:
		var anchor: Node3D = patch.get_recall_anchor() if patch.has_method("get_recall_anchor") else null
		near = RECALL.explorer_near(anchor,Vector2.ZERO) if is_instance_valid(anchor) else RECALL.explorer_near(patch,patch.footprint)
	if near:
		play()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
