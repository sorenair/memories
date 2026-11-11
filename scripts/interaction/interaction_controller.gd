extends Node
## Targets join memory_interactables and expose can_interact(actor) / try_activate(actor).
signal target_changed(target: Node3D)
signal interaction_requested(target: Node3D, actor: Node3D)
signal interaction_performed(target: Node3D, actor: Node3D)

@export var actor: Node3D
var target: Node3D

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
	var nearest: Node3D
	var distance := INF
	if input_allowed():
		for candidate in get_tree().get_nodes_in_group(&"memory_interactables"):
			if not candidate is Node3D or not get_parent().is_ancestor_of(candidate):
				continue
			if candidate.get_viewport() != get_viewport() or not candidate.can_process() or not candidate.is_visible_in_tree():
				continue
			if not candidate.has_method("can_interact") or not candidate.has_method("try_activate") or not candidate.can_interact(actor):
				continue
			var separation: float = actor.global_position.distance_squared_to(candidate.global_position)
			if separation < distance:
				distance = separation
				nearest = candidate
	if target != nearest:
		target = nearest
		target_changed.emit(target)

func request_interaction(expected_target: Node3D = null) -> bool:
	# Revalidate on release: walking away, closing a target, and modal changes gate input.
	refresh_target()
	if not is_instance_valid(target) or (expected_target != null and expected_target != target):
		return false
	var selected := target
	interaction_requested.emit(selected, actor)
	if not input_allowed() or not is_instance_valid(selected) or not selected.can_interact(actor):
		refresh_target()
		return false
	var accepted: bool = selected.try_activate(actor)
	if accepted:
		interaction_performed.emit(selected, actor)
	refresh_target()
	return accepted
