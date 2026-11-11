@tool
class_name MemoryFragment
extends Node3D
## Place at ground level. A shared FragmentInteraction UI handles tap picking and notes.
signal activated(fragment: MemoryFragment)
signal note_requested(title: String, text: String)
signal state_changed(state: State)

enum State { INACTIVE, ACTIVE, DECAYING }

@export_group("Appearance")
@export var glow_color := Color(1.0, 1.0, 1.0):
	set(value):
		glow_color = value
		_refresh()
@export_range(0.1, 1.0, 0.01) var orb_radius: float = 0.22:
	set(value):
		orb_radius = value
		_refresh()
@export_range(0.3, 3.0, 0.05) var float_height: float = 1.15:
	set(value):
		float_height = value
		_refresh()
@export_range(0.0, 0.5, 0.01) var bob_amount: float = 0.12:
	set(value):
		bob_amount = value
		_refresh()
@export_range(0.1, 4.0, 0.1) var animation_speed: float = 1.0:
	set(value):
		animation_speed = value
		_refresh()
@export_range(0, 16, 1) var mote_count: int = 8:
	set(value):
		mote_count = value
		_refresh()
@export_range(0.0, 2.0, 0.05) var wisp_strength: float = 1.0:
	set(value):
		wisp_strength = value
		_refresh()
@export var fragment_seed: int = 1:
	set(value):
		fragment_seed = value
		_refresh()
@export_range(0.3, 3.0, 0.05) var decay_duration: float = 0.65
@export_group("Interaction")
@export_range(0.5, 8.0, 0.1) var interaction_range: float = 2.5
@export_range(20.0, 80.0, 1.0) var tap_radius_pixels: float = 36.0
@export var once_per_visit: bool = true
@export var note_title: String = "A fragment"
@export_multiline var notes: Array[String] = ["Something here feels familiar."]

const PAINT := preload("res://components/interactables/fragments/fragment.gdshader")
var state: State = State.INACTIVE
var collected: bool = false
var _reading: bool = false
var _activity: float = 0.0
var _visual: Node3D
var _material: ShaderMaterial
var _time: float = 0.0
var _cooldown: float = 0.0
var _tap_feedback: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"memory_fragments")
		add_to_group(&"memory_interactables")
	_visual = Node3D.new()
	_visual.name = "Orb"
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_visual)
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	var core := MeshInstance3D.new()
	var veil := QuadMesh.new()
	veil.size = Vector2(6.0, 8.0)
	core.mesh = veil
	core.material_override = _material
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(core)
	var halo := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(6.0, 6.0)
	halo.mesh = quad
	var halo_material := ShaderMaterial.new()
	halo_material.shader = preload("res://components/interactables/fragments/fragment_halo.gdshader")
	halo.material_override = halo_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(halo)
	_refresh()
	_set_decay(0.0)
	_process(0.0)

func _refresh() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.scale = Vector3.ONE * orb_radius
	_material.set_shader_parameter("glow_color", glow_color)
	_material.set_shader_parameter("speed", animation_speed)
	_material.set_shader_parameter("seed", float(fragment_seed))
	_material.set_shader_parameter("mote_count", mote_count)
	_material.set_shader_parameter("wisp_strength", wisp_strength)
	var halo_material: ShaderMaterial = _visual.get_child(1).material_override
	halo_material.set_shader_parameter("glow_color", glow_color)
	halo_material.set_shader_parameter("speed", animation_speed)
	halo_material.set_shader_parameter("seed", float(fragment_seed))

func _process(delta: float) -> void:
	_time += delta * animation_speed
	_cooldown = maxf(0.0, _cooldown - delta)
	_visual.position = Vector3(sin(_time * 0.7 + fragment_seed) * bob_amount * 0.3,
		float_height + sin(_time * 1.6 + fragment_seed) * bob_amount, 0.0)
	_visual.rotation.y = _time * 0.22
	if state != State.DECAYING:
		var nearby := Engine.is_editor_hint() or _reading
		if not nearby and not collected:
			for explorer in get_tree().get_nodes_in_group(&"explorers"):
				if explorer.get_viewport() == get_viewport() and can_interact(explorer):
					nearby = true
					break
		_set_state(State.ACTIVE if nearby else State.INACTIVE)
	var target := 1.0 if state != State.INACTIVE else 0.0
	_activity = lerpf(_activity, target, 1.0 - exp(-delta * 9.0))
	_material.set_shader_parameter("activity", _activity)
	var halo_material: ShaderMaterial = _visual.get_child(1).material_override
	halo_material.set_shader_parameter("activity", _activity)

func _set_state(value: State) -> void:
	if state != value:
		state = value
		state_changed.emit(state)

func get_orb_position() -> Vector3:
	return _visual.global_position if is_instance_valid(_visual) else global_position + Vector3.UP * float_height

func can_interact(explorer: Node3D) -> bool:
	if not is_instance_valid(explorer) or not is_visible_in_tree() or collected or _reading or state == State.DECAYING or _cooldown > 0.0:
		return false
	return global_position.distance_to(explorer.global_position) <= interaction_range

func try_activate(explorer: Node3D) -> bool:
	if not can_interact(explorer):
		return false
	_cooldown = 1.0
	collected = once_per_visit
	_reading = true
	_play_tap_feedback()
	_set_state(State.ACTIVE)
	activated.emit(self)
	var pages: Array[String] = []
	for text in notes:
		if not text.strip_edges().is_empty():
			pages.append(text)
	var queue: Node
	for candidate in get_tree().get_nodes_in_group(&"fragment_note_queue"):
		if candidate.get_viewport() == get_viewport():
			queue = candidate
			break
	for index in range(pages.size()):
		note_requested.emit(note_title, pages[index])
		if queue:
			var finished := finish_reading if index == pages.size() - 1 else Callable()
			queue.enqueue_note(note_title, pages[index], finished)
	# Hosts with custom note presentation can call finish_reading explicitly.
	if pages.is_empty():
		finish_reading()
	return true

func _play_tap_feedback() -> void:
	_set_tap_feedback(1.0)
	var flash := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash.tween_method(_set_tap_feedback, 1.0, 0.0, 0.4)
	var bounce := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bounce.tween_property(_visual, "scale", Vector3(1.10, 0.88, 1.0) * orb_radius, 0.07)
	bounce.tween_property(_visual, "scale", Vector3(0.97, 1.08, 1.0) * orb_radius, 0.12)
	bounce.tween_property(_visual, "scale", Vector3.ONE * orb_radius, 0.18)

func _set_tap_feedback(amount: float) -> void:
	_tap_feedback = amount
	_material.set_shader_parameter("tap_feedback", amount)
	var halo_material: ShaderMaterial = _visual.get_child(1).material_override
	halo_material.set_shader_parameter("tap_feedback", amount)

func finish_reading() -> void:
	if not _reading:
		return
	_reading = false
	_set_state(State.DECAYING)
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_decay, 0.0, 1.0, decay_duration)
	tween.tween_callback(_finish_decay)

func _set_decay(amount: float) -> void:
	_material.set_shader_parameter("decay", amount)
	var halo_material: ShaderMaterial = _visual.get_child(1).material_override
	halo_material.set_shader_parameter("decay", amount)

func _finish_decay() -> void:
	if once_per_visit:
		_visual.hide()
		set_process(false)
	else:
		_set_decay(0.0)
		_set_state(State.INACTIVE)
