extends RefCounted
## On-demand walking routes. All input and output positions are in world space.
## Authored strokes form a bidirectional backbone; the grid is only a fallback.

const GRID_STEP := 0.6
const MAX_SEARCH_NODES := 2500
const BACKBONE_STEP := 0.85

var _space: PhysicsDirectSpaceState3D
var _query := PhysicsShapeQueryParameters3D.new()
var _platforms: Array[MemoryPlatform] = []
var _point_cache := {}
var _segment_cache := {}
var _capsule_y := 0.68
var _stroke_y := 0.72
var _bounds := Rect2()

func build(memory: MemoryScene, actor: Node3D, destination: MemoryFragment, routes: Array[Node3D]) -> PackedVector3Array:
	_point_cache.clear()
	_segment_cache.clear()
	_platforms.clear()
	_space = null
	if not is_instance_valid(memory) or not is_instance_valid(actor) or not is_instance_valid(destination):
		return PackedVector3Array()
	_space = memory.get_world_3d().direct_space_state
	var entry_y := memory.get_entry_transform().origin.y
	_capsule_y = entry_y + 0.68
	_stroke_y = entry_y + 0.72
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.3
	_query.shape = capsule
	_query.collision_mask = 1
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	var excluded: Array[RID] = []
	_collect_characters(memory.get_tree().root, actor, excluded)
	_query.exclude = excluded
	_collect_platforms(memory)
	var start := actor.global_position + Vector3.UP * 0.72
	var finish := destination.to_global(Vector3.UP * destination.float_height)
	_set_bounds(start, finish)
	if _point_status(start) == 0 or _point_status(finish) == 0:
		return PackedVector3Array()
	if segment_clear(start, finish):
		return PackedVector3Array([start, finish])
	var authored := _backbone_path(start, finish, routes)
	if not authored.is_empty():
		authored = _simplify(authored)
		if _path_length(authored) <= start.distance_to(finish) * 1.65 + 2.0:
			return authored
	# A distant visible join may exist while all the nearby backbone samples
	# are behind a house. Compare that detour with the bounded local search.
	var fallback := _simplify(_grid_path(start, finish))
	if fallback.is_empty() or (not authored.is_empty() and _path_length(authored) <= _path_length(fallback)):
		return authored
	return fallback

func _path_length(path: PackedVector3Array) -> float:
	var length := 0.0
	for index in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	return length

func _collect_characters(node: Node, actor: Node3D, excluded: Array[RID]) -> void:
	# Remote explorers may use the static layer too. Never let another player
	# change the route, and also exclude collision descendants of the caller.
	if node is CollisionObject3D and (node is CharacterBody3D or node == actor or actor.is_ancestor_of(node)):
		excluded.append(node.get_rid())
	for child in node.get_children(true):
		_collect_characters(child, actor, excluded)

func _collect_platforms(node: Node) -> void:
	if node is MemoryPlatform:
		_platforms.append(node)
	for child in node.get_children(true):
		_collect_platforms(child)

func _set_bounds(start: Vector3, finish: Vector3) -> void:
	var low := Vector2(minf(start.x, finish.x), minf(start.z, finish.z))
	var high := Vector2(maxf(start.x, finish.x), maxf(start.z, finish.z))
	if _platforms.is_empty():
		var padding := clampf(start.distance_to(finish) * 0.6, 10.0, 30.0)
		low -= Vector2.ONE * padding
		high += Vector2.ONE * padding
	else:
		for platform in _platforms:
			for point in platform.make_outline():
				var world := platform.to_global(Vector3(point.x, 0.0, point.y))
				low = low.min(Vector2(world.x, world.z))
				high = high.max(Vector2(world.x, world.z))
	_bounds = Rect2(low, high - low)

func _on_platform(point: Vector3) -> bool:
	if _platforms.is_empty():
		return true
	for platform in _platforms:
		if platform.contains_ground_point(point, 0.32):
			return true
	return false

func _ground(point: Vector3) -> Vector3:
	return Vector3(point.x, _capsule_y, point.z)

func _is_ramp(hit: Dictionary) -> bool:
	var body := hit.get("collider") as CollisionObject3D
	if not is_instance_valid(body):
		return false
	var owner_id := body.shape_find_owner(int(hit["shape"]))
	var owner := body.shape_owner_get_owner(owner_id) as Node
	return is_instance_valid(owner) and owner.name == &"StairRamp"

func _point_status(point: Vector3) -> int:
	var key := Vector2(point.x, point.z)
	if _point_cache.has(key):
		return _point_cache[key]
	var status := 1
	if not _on_platform(point):
		status = 0
	else:
		_query.transform = Transform3D(Basis.IDENTITY, _ground(point))
		_query.motion = Vector3.ZERO
		for hit in _space.intersect_shape(_query, 64):
			if not _is_ramp(hit):
				status = 0
				break
			status = 2
	_point_cache[key] = status
	return status

func segment_clear(a: Vector3, b: Vector3) -> bool:
	if not _space:
		return false
	var first := Vector2(a.x, a.z)
	var last := Vector2(b.x, b.z)
	if first.x > last.x or (first.x == last.x and first.y > last.y):
		var swap := first
		first = last
		last = swap
	var key := Vector4(first.x, first.y, last.x, last.y)
	if _segment_cache.has(key):
		return _segment_cache[key]
	var clear := _check_segment(a, b)
	_segment_cache[key] = clear
	return clear

func _check_segment(a: Vector3, b: Vector3) -> bool:
	var start_status := _point_status(a)
	var end_status := _point_status(b)
	if start_status == 0 or end_status == 0:
		return false
	var distance := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
	# Endpoints alone cannot protect a segment crossing a concave platform rim.
	for index in range(1, ceili(distance / 0.2)):
		if not _on_platform(a.lerp(b, float(index) / ceili(distance / 0.2))):
			return false
	_query.transform = Transform3D(Basis.IDENTITY, _ground(a))
	_query.motion = _ground(b) - _ground(a)
	var fractions := _space.cast_motion(_query)
	if fractions.size() == 2 and fractions[0] >= 1.0:
		return true
	# A ramp shares its StaticBody with the house wall, so excluding that RID
	# would open the whole house. Filter individual shape owners instead.
	var ramp_seen := start_status == 2 or end_status == 2
	var samples := maxi(1, ceili(distance / 0.06))
	for index in range(1, samples):
		var status := _point_status(a.lerp(b, float(index) / samples))
		if status == 0:
			return false
		ramp_seen = ramp_seen or status == 2
	return ramp_seen

func _backbone_path(start: Vector3, finish: Vector3, routes: Array[Node3D]) -> PackedVector3Array:
	var points := PackedVector3Array([start, finish])
	var edges: Array[Array] = [[], []]
	var indices := {}
	for route in routes:
		if not is_instance_valid(route) or not route.has_method("get_route_points"):
			continue
		var authored: PackedVector3Array = route.get_route_points()
		var previous := -1
		for i in range(authored.size()):
			var count := 1 if i == 0 else maxi(1, ceili(authored[i - 1].distance_to(authored[i]) / BACKBONE_STEP))
			for sample in range(1, count + 1):
				var point := authored[i] if i == 0 else authored[i - 1].lerp(authored[i], float(sample) / count)
				var key := Vector2i(roundi(point.x * 100.0), roundi(point.z * 100.0))
				var index: int = indices.get(key, -1)
				if index == -1:
					index = points.size()
					indices[key] = index
					points.append(point)
					edges.append([])
				if previous >= 0 and previous != index and segment_clear(points[previous], point):
					edges[previous].append(index)
					edges[index].append(previous)
				previous = index
	for index in range(2, points.size()):
		if segment_clear(start, points[index]):
			edges[0].append(index)
		if segment_clear(points[index], finish):
			edges[index].append(1)
	var costs := {0: 0.0}
	var parents := {}
	var open: Array[int] = [0]
	while not open.is_empty():
		var current := open[0]
		for index in open:
			if costs[index] < costs[current]:
				current = index
		open.erase(current)
		if current == 1:
			var path := PackedVector3Array([finish])
			while parents.has(current):
				current = parents[current]
				path.append(points[current])
			path.reverse()
			return path
		for neighbor in edges[current]:
			var cost: float = costs[current] + points[current].distance_to(points[neighbor])
			if cost < costs.get(neighbor, INF):
				costs[neighbor] = cost
				parents[neighbor] = current
				if not open.has(neighbor):
					open.append(neighbor)
	return PackedVector3Array()

func _grid_point(cell: Vector2i, start: Vector3) -> Vector3:
	return Vector3(start.x + cell.x * GRID_STEP, _stroke_y, start.z + cell.y * GRID_STEP)

func _grid_path(start: Vector3, finish: Vector3) -> PackedVector3Array:
	var origin := Vector2i.ZERO
	var open: Array[Vector2i] = [origin]
	var costs := {origin: 0.0}
	var estimates := {origin: start.distance_to(finish)}
	var parents := {}
	var closed := {}
	while not open.is_empty() and closed.size() < MAX_SEARCH_NODES:
		var current := open[0]
		for cell in open:
			if estimates[cell] < estimates[current]:
				current = cell
		open.erase(current)
		closed[current] = true
		var point := _grid_point(current, start)
		if Vector2(point.x, point.z).distance_to(Vector2(finish.x, finish.z)) <= GRID_STEP * 2.0 and segment_clear(point, finish):
			var path := PackedVector3Array([finish, point])
			while parents.has(current):
				current = parents[current]
				path.append(_grid_point(current, start))
			path.reverse()
			path[0] = start
			return path
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				if dx == 0 and dz == 0:
					continue
				var neighbor := current + Vector2i(dx, dz)
				if closed.has(neighbor):
					continue
				var next := _grid_point(neighbor, start)
				if not _bounds.has_point(Vector2(next.x, next.z)):
					continue
				var cost: float = costs[current] + point.distance_to(next)
				if cost >= costs.get(neighbor, INF) or not segment_clear(point, next):
					continue
				costs[neighbor] = cost
				estimates[neighbor] = cost + next.distance_to(finish)
				parents[neighbor] = current
				if not open.has(neighbor):
					open.append(neighbor)
	return PackedVector3Array()

func _simplify(path: PackedVector3Array) -> PackedVector3Array:
	if path.size() < 3:
		return path
	var result := PackedVector3Array([path[0]])
	var current := 0
	while current < path.size() - 1:
		var next := path.size() - 1
		while next > current + 1 and not segment_clear(path[current], path[next]):
			next -= 1
		result.append(path[next])
		current = next
	return result
