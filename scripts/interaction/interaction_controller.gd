extends Node
## Targets join memory_interactables and expose can_interact(actor) / try_activate(actor).
signal target_changed(target: Node3D)
signal interaction_requested(target: Node3D, actor: Node3D)
signal interaction_performed(target: Node3D, actor: Node3D)

@export var actor: Node3D
var target: Node3D
var _outlines: Node
var _picker := preload("res://scripts/interaction/interaction_picker.gd").new()
var _tap_pointer: int = -1
var _tap_start := Vector2.ZERO
var _tap_target: Node3D
var _tap_serial: int = 0

func _ready() -> void:
	add_to_group(&"interaction_controllers")
	_outlines = preload("res://scripts/interaction/interaction_outlines.gd").new()
	_outlines.name = "Outlines"
	add_child(_outlines)

func _physics_process(_delta: float) -> void:
	refresh_target()

func input_allowed() -> bool:
	if not is_instance_valid(actor) or not actor.can_process() or not actor.is_physics_processing():
		return false
	for blocker in get_tree().get_nodes_in_group(&"interaction_blockers"):
		if blocker.get_viewport() == get_viewport() and blocker.blocks_interaction():
			return false
	return true

func refresh_target() -> void:
	if not is_instance_valid(target): target = null
	var nearest: Node3D
	var distance := INF
	var available: Array[Node3D] = []
	if input_allowed():
		for candidate in get_tree().get_nodes_in_group(&"memory_interactables"):
			if not is_available(candidate):
				continue
			available.append(candidate)
			var separation: float = actor.global_position.distance_squared_to(candidate.global_position)
			if separation < distance:
				distance = separation
				nearest = candidate
	if target != nearest:
		target = nearest
		target_changed.emit(target)
	if is_instance_valid(_outlines): _outlines.refresh(available, target)

func request_interaction(expected_target: Node3D = null) -> bool:
	# Explicit requests use the tapped component, even when another one is nearer.
	refresh_target()
	var selected := expected_target if is_instance_valid(expected_target) else target
	if not input_allowed() or not is_available(selected):
		return false
	interaction_requested.emit(selected, actor)
	if not is_available(selected):
		refresh_target()
		return false
	var accepted: bool = selected.try_activate(actor)
	if accepted:
		interaction_performed.emit(selected, actor)
	refresh_target()
	return accepted

func is_available(candidate: Node) -> bool:
	return input_allowed() and is_instance_valid(candidate) and candidate is Node3D and get_parent().is_ancestor_of(candidate) \
		and candidate.get_viewport() == get_viewport() and candidate.can_process() and candidate.is_visible_in_tree() \
		and candidate.has_method("can_interact") and candidate.has_method("try_activate") and candidate.can_interact(actor)

func pick_interactable(point: Vector2) -> Node3D:
	return _picker.pick(self, point)

func _reset_tap() -> void:
	_tap_pointer = -1
	_tap_target = null
	_tap_serial += 1

func _clear_released_pointer(pointer: int, serial: int) -> void:
	if _tap_pointer == pointer and _tap_serial == serial:
		_reset_tap()

func _input(event: InputEvent) -> void:
	# A release consumed by a GUI control must still clean up a world-space press.
	if event is InputEventScreenTouch and not event.pressed and event.index == _tap_pointer:
		_clear_released_pointer.call_deferred(_tap_pointer, _tap_serial)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _tap_pointer == -2:
		_clear_released_pointer.call_deferred(_tap_pointer, _tap_serial)

func _unhandled_input(event: InputEvent) -> void:
	if not input_allowed():
		_reset_tap()
		return
	var point := Vector2.ZERO
	var pointer := -1
	var pressed := false
	var cancelled := false
	if event is InputEventScreenTouch:
		point = event.position
		pointer = event.index
		pressed = event.pressed
		cancelled = event.canceled
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
		pointer = -2
		pressed = event.pressed
	elif (event is InputEventScreenDrag and event.index == _tap_pointer) or (event is InputEventMouseMotion and _tap_pointer == -2):
		if event.position.distance_to(_tap_start) > 20.0:
			_tap_target = null
		get_viewport().set_input_as_handled()
		return
	else:
		return
	if pressed and _tap_pointer == -1 and not cancelled:
		_tap_target = pick_interactable(point)
		if _tap_target != null:
			_tap_pointer = pointer
			_tap_start = point
			_tap_serial += 1
			get_viewport().set_input_as_handled()
	elif not pressed and pointer == _tap_pointer:
		var selected := _tap_target
		_reset_tap()
		if not cancelled and is_instance_valid(selected) and point.distance_to(_tap_start) <= 20.0 and pick_interactable(point) == selected:
			request_interaction(selected)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_tap()
