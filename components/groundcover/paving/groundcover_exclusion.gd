@tool
extends MeshInstance3D
## Keep groundcover off paving meshes using the shared ground-exclusion API.
func excludes_ground_point(world_point: Vector3) -> bool:
	if not mesh:
		return false
	var point := to_local(world_point)
	var bounds := mesh.get_aabb()
	return point.x >= bounds.position.x and point.x <= bounds.end.x and point.z >= bounds.position.z and point.z <= bounds.end.z
