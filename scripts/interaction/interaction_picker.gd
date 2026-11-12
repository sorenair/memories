extends RefCounted
## Screen picking happens only on press/release, against visible target geometry.
var _faces: Dictionary = {}

func pick(controller: Node, point: Vector2) -> Node3D:
	if not controller.input_allowed():
		return null
	var camera: Camera3D = controller.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var winner: Node3D
	var nearest := INF
	for candidate in controller.get_tree().get_nodes_in_group(&"memory_interactables"):
		if not controller.is_available(candidate):
			continue
		var hit: Variant = null
		if candidate.has_method("get_interaction_tap_position"):
			var position: Vector3 = candidate.get_interaction_tap_position()
			var radius: float = candidate.get_interaction_tap_radius()
			if not camera.is_position_behind(position) and camera.unproject_position(position).distance_to(point) <= radius:
				hit = position
		else:
			var sources: Array[MeshInstance3D] = []
			if candidate.has_method("get_interaction_tap_meshes"):
				sources.assign(candidate.get_interaction_tap_meshes())
			elif candidate.has_method("get_interaction_outline_meshes"):
				sources.assign(candidate.get_interaction_outline_meshes())
			else:
				_find_meshes(candidate, sources)
			var depth := INF
			for source in sources:
				if not is_instance_valid(source) or not source.is_visible_in_tree() or source.mesh == null or (source.layers & camera.cull_mask) == 0:
					continue
				var intersection: Variant = _mesh_hit(source, origin, direction)
				if intersection != null and origin.distance_squared_to(intersection) < depth:
					depth = origin.distance_squared_to(intersection)
					hit = intersection
		if hit == null or origin.distance_squared_to(hit) >= nearest:
			continue
		# Stop at opaque scenery, but allow a component's own broad collision shell.
		var ray := PhysicsRayQueryParameters3D.create(origin, hit)
		if controller.actor is CollisionObject3D:
			ray.exclude = [controller.actor.get_rid()]
		var obstruction: Dictionary = candidate.get_world_3d().direct_space_state.intersect_ray(ray)
		var occlusion_root: Node = candidate.get_interaction_occlusion_root() if candidate.has_method("get_interaction_occlusion_root") else candidate
		if not obstruction.is_empty() and obstruction.collider != occlusion_root and not occlusion_root.is_ancestor_of(obstruction.collider):
			continue
		nearest = origin.distance_squared_to(hit)
		winner = candidate
	return winner

func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null and not (node.mesh is QuadMesh or node.mesh is PlaneMesh):
		result.append(node)
	for child in node.get_children(true):
		if child.name != &"InteractionOutline":
			_find_meshes(child, result)

func _mesh_hit(source: MeshInstance3D, origin: Vector3, direction: Vector3) -> Variant:
	var inverse := source.global_transform.affine_inverse()
	var local_origin := inverse * origin
	var local_direction := (inverse.basis * direction).normalized()
	if source.get_aabb().intersects_ray(local_origin, local_direction) == null:
		return null
	var id := source.mesh.get_instance_id()
	if not _faces.has(id) or _faces[id].source.get_ref() != source.mesh:
		if _faces.size() >= 32:
			_faces.erase(_faces.keys()[0])
		_faces[id] = {"source": weakref(source.mesh), "triangles": source.mesh.get_faces()}
	var vertices: PackedVector3Array = _faces[id].triangles
	var nearest: Variant = null
	var depth := INF
	for i in range(0, vertices.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(local_origin, local_direction, vertices[i], vertices[i + 1], vertices[i + 2])
		if hit != null and local_origin.distance_squared_to(hit) < depth:
			depth = local_origin.distance_squared_to(hit)
			nearest = hit
	return source.global_transform * nearest if nearest != null else null
