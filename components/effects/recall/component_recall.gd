extends RefCounted
## Runtime lifecycle shared by recallable components; editor previews remain complete.
static func configure(component: Node3D, adapter_path: String, current: Node) -> Node:
	if Engine.is_editor_hint():
		return null
	if not component.recall_enabled:
		if is_instance_valid(current):
			component.remove_child(current)
			current.queue_free()
		return null
	if not is_instance_valid(current):
		current = load(adapter_path).new()
		current.name = "RecallEffect"
		current.patch = component
		current.auto_discover = true
		component.add_child(current, false, Node.INTERNAL_MODE_BACK)
	else:
		# Rebind immediately so a rebuild never flashes fully visible geometry.
		current.bind_materials()
		current.restore_state()
	return current

static func explorer_near(component: Node3D, footprint: Vector2) -> bool:
	for explorer in component.get_tree().get_nodes_in_group(&"explorers"):
		if explorer is Node3D:
			var point := component.to_local(explorer.global_position)
			var radius := footprint * 0.5 + Vector2.ONE * 1.4
			if absf(explorer.global_position.y - component.global_position.y) < 1.5 and Vector2(point.x / radius.x, point.z / radius.y).length() <= 1.0:
				return true
	return false
