extends Node
## One-shot presentation for entering a memory from Recall.
## Reuse the remote explorer scan; keep the body and camera grounded.

signal finished

const REQUEST_META := &"memory_recall_arrival"
const PAPER := Color("faf9f6")
const Presence := preload("res://scripts/network/remote_presence.gd")
const DURATION := Presence.ARRIVAL_DURATION
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

var _player: MemoryExplorer
var _controls: Control
var _veil: ColorRect
var _fps: CanvasItem
var _elapsed := 0.0
var _controls_mode: int
var _fps_was_visible: bool

func begin(world: Node3D) -> void:
	_player = world.get_node("Explorer")
	_controls = world.get_node("Controls/ExplorationInput")
	_fps = world.get_node("Controls/FPSLabel")
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_player.set_walking(false)
	_controls_mode = _controls.process_mode
	_controls._release()
	_controls.process_mode = Node.PROCESS_MODE_DISABLED
	_fps_was_visible = _fps.visible
	_fps.hide()
	_veil = get_transition_veil(get_tree())
	_veil.get_parent().reparent(self)
	var presence := Presence.new()
	presence.name = "PresenceRecall"
	presence.free_on_departure = false
	presence.arrived.connect(_complete, CONNECT_ONE_SHOT)
	_player.add_child(presence)
	_update_presentation()

func _process(delta: float) -> void:
	_elapsed += delta
	_update_presentation()

func _update_presentation() -> void:
	if is_instance_valid(_veil):
		# Uncover the world quickly so the same white-edged scan is visible locally.
		_veil.modulate.a = 1.0 - smoothstep(0.0, 0.45, _elapsed)

func _complete() -> void:
	set_process(false)
	_veil.modulate.a = 0.0
	_player.reset_physics_interpolation()
	_controls._release()
	_controls.process_mode = _controls_mode
	_player.set_physics_process(true)
	_fps.visible = _fps_was_visible
	finished.emit()
	queue_free()
