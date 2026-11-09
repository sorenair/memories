extends Node
## A gentle light fade, using the same shared proximity setting as other components.
signal finished
const RECALL = preload("res://components/effects/recall/component_recall.gd")
var patch: PainterlyLightWash
var auto_discover: bool = false
var playing: bool = false
var progress: float = 0.0
var duration: float = 1.6
var _material: ShaderMaterial

func _ready() -> void:
	reset()
func bind_materials() -> void:
	_material = patch._material
func restore_state() -> void:
	_material.set_shader_parameter("recall_visibility", smoothstep(0.0, 1.0, progress))
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
	if auto_discover and not playing and progress == 0.0:
		var reach := Vector2(patch.footprint.x, 0.2) if patch.surface == 1 else patch.footprint
		if RECALL.explorer_near(patch, reach):
			play()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
