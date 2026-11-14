extends RefCounted
## Runtime lifecycle and shared proximity settings for all recallable components.
static var settings: Resource = preload("res://components/effects/recall/recall_settings.tres")
static func explorers(component: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for group in [&"explorers", &"foliage_explorers"]:
		for explorer in component.get_tree().get_nodes_in_group(group):
			if explorer is Node3D and explorer.is_inside_tree() and explorer.is_visible_in_tree() and explorer.get_viewport() == component.get_viewport() and not result.has(explorer):
				result.append(explorer)
	return result
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

static func proximity_distance() -> float:
	return settings.proximity_distance

static func local_margin(component: Node3D) -> Vector2:
	# Keep the shared reach in world meters even when an instance is scaled.
	return Vector2(settings.proximity_distance / maxf(component.global_basis.x.length(), 0.001),
		settings.proximity_distance / maxf(component.global_basis.z.length(), 0.001))

static func explorer_near(component: Node3D, footprint: Vector2, center: Vector2 = Vector2.ZERO) -> bool:
	for explorer in explorers(component):
		if explorer is Node3D:
			var point := component.to_local(explorer.global_position)
			var radius := footprint * 0.5 + local_margin(component)
			if absf(explorer.global_position.y - component.global_position.y) < 1.5 and Vector2((point.x - center.x) / maxf(radius.x, 0.001), (point.z - center.y) / maxf(radius.y, 0.001)).length() <= 1.0:
				return true
	return false

static func explorer_near_outline(component: Node3D, outline: PackedVector2Array) -> bool:
	for explorer in explorers(component):
		if not explorer is Node3D or absf(explorer.global_position.y - component.global_position.y) >= 1.5:
			continue
		var point: Vector3 = component.to_local(explorer.global_position)
		if Geometry2D.is_point_in_polygon(Vector2(point.x, point.z), outline):
			return true
		var player := Vector2(explorer.global_position.x, explorer.global_position.z)
		# Measure in world space for concave/custom outlines and scaled water.
		for index in range(outline.size()):
			var a := component.to_global(Vector3(outline[index].x, 0, outline[index].y))
			var b := component.to_global(Vector3(outline[(index + 1) % outline.size()].x, 0, outline[(index + 1) % outline.size()].y))
			var nearest := Geometry2D.get_closest_point_to_segment(player, Vector2(a.x, a.z), Vector2(b.x, b.z))
			if player.distance_squared_to(nearest) <= settings.proximity_distance * settings.proximity_distance:
				return true
	return false
