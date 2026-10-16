extends Node
## One-shot presentation for entering a memory from Recall.
## Animate only the visual: the body and camera remain at the landing position.

signal finished

const REQUEST_META := &"memory_recall_arrival"
const PAPER := Color("faf9f6")
const DURATION := 1.95
const VEIL_LAYER_NAME := "MemoryTransitionVeil"

static func get_transition_veil(tree: SceneTree) -> ColorRect:
	# Keep one veil alive across the scene swap, including any empty render frame.
	var layer := tree.root.get_node_or_null(VEIL_LAYER_NAME) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = VEIL_LAYER_NAME
		layer.layer = 100
		tree.root.add_child(layer)
		var veil := ColorRect.new()
		veil.name = "Paper"
		veil.color = PAPER
		veil.modulate.a = 0.0
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(veil)
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer.get_node("Paper") as ColorRect

var _player: CharacterBody3D
var _visual: Node3D
var _controls: Control
var _shadow: MeshInstance3D
var _veil: ColorRect
var _fps: CanvasItem
var _elapsed: float = 0.0
var _drop_height: float = 8.0
var _materials: Array[Dictionary] = []
var _shadow_material: ShaderMaterial
var _shadow_original: Material
var _shadow_color: Color
var _visual_origin := Vector3.ZERO
var _shadow_scale := Vector3.ONE
var _interpolation: int
var _controls_mode: int
var _fps_was_visible: bool

func begin(world: Node3D, drop_height: float) -> void:
	_drop_height = drop_height
	_player = world.get_node("Explorer")
	_visual = _player.get_node("Visual")
	_controls = world.get_node("Controls/ExplorationInput")
	_shadow = _player.get_node("ContactShadow")
	_fps = world.get_node("Controls/FPSLabel")
	_visual_origin = _visual.position
	_shadow_scale = _shadow.scale
	_interpolation = _visual.physics_interpolation_mode
	# Tweened visual motion must not be interpolated again on physics ticks.
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_controls_mode = _controls.process_mode
	_controls._release()
	_controls.process_mode = Node.PROCESS_MODE_DISABLED
	_fps_was_visible = _fps.visible
	_fps.hide()
	for child in _visual.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			var original := mesh.material_override
			var material := mesh.get_active_material(0).duplicate() as StandardMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_materials.append({"mesh": mesh, "original": original, "material": material, "color": material.albedo_color})
			mesh.material_override = material
	_shadow_original = _shadow.material_override
	_shadow_material = _shadow.get_active_material(0).duplicate() as ShaderMaterial
	_shadow_color = _shadow_material.get_shader_parameter("shadow_color")
	_shadow.material_override = _shadow_material
	_veil = get_transition_veil(get_tree())
	_veil.get_parent().reparent(self)
	_update_presentation()

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_elapsed = minf(_elapsed + delta, DURATION)
	_update_presentation()
	if _elapsed >= DURATION:
		_complete()

func _update_presentation() -> void:
	# Blend the UI paper into the world's actual rendered colors over the descent.
	_veil.modulate.a = 1.0 - smoothstep(0.0, 1.8, _elapsed)
	var descent := smoothstep(0.25, 1.8, _elapsed)
	_visual.position = _visual_origin + Vector3.UP * _drop_height * (1.0 - descent)
	var opacity := smoothstep(0.75, 1.65, _elapsed)
	for entry in _materials:
		var color: Color = entry.color
		color.a *= opacity
		entry.material.albedo_color = color
	var shadow_alpha := smoothstep(1.15, 1.8, _elapsed)
	_shadow_material.set_shader_parameter("shadow_color", Color(_shadow_color, _shadow_color.a * shadow_alpha))
	_shadow.scale = _shadow_scale * lerpf(1.3, 1.0, shadow_alpha)

func _complete() -> void:
	set_process(false)
	_visual.position = _visual_origin
	for entry in _materials:
		entry.mesh.material_override = entry.original
	_shadow.material_override = _shadow_original
	_shadow.scale = _shadow_scale
	_visual.physics_interpolation_mode = _interpolation
	_player.reset_physics_interpolation()
	_controls._release()
	_controls.process_mode = _controls_mode
	_player.set_physics_process(true)
	_fps.visible = _fps_was_visible
	finished.emit()
	queue_free()
