@tool
class_name WaterShoreField
extends RefCounted
const BODY = preload("res://components/scenery/water/water_body_geometry.gd")

static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	return bounds

## RGBA float field: signed shore distance in meters, local flow X/Z, local speed.
static func bake(data: Dictionary, obstacles: Array[PackedVector2Array], stream: bool, cap_ends: bool, flow_direction: Vector2, resolution: int) -> Dictionary:
	var polygon: PackedVector2Array = data.outline
	var bounds := polygon_bounds(polygon).grow(0.9)
	var image := Image.create(resolution, resolution, false, Image.FORMAT_RGBAH)
	var obstacle_centers: Array[Vector2] = []
	for obstacle in obstacles:
		obstacle_centers.append(polygon_bounds(obstacle).get_center())
	var skip := PackedInt32Array()
	if stream and not cap_ends:
		skip.append(data.centers.size() - 1)
		skip.append(polygon.size() - 1)
	for y in range(resolution):
		for x in range(resolution):
			var point := bounds.position + Vector2((float(x) + 0.5) / resolution, (float(y) + 0.5) / resolution) * bounds.size
			var distance := BODY.polygon_distance(point, polygon, skip)
			if not Geometry2D.is_point_in_polygon(point, polygon):
				distance = -distance
			var flow := BODY.stream_flow(point, data) if stream else flow_direction
			var obstacle_distance := INF
			var obstacle_normal := Vector2.ZERO
			for obstacle_index in range(obstacles.size()):
				var obstacle := obstacles[obstacle_index]
				var d := BODY.polygon_distance(point, obstacle)
				if Geometry2D.is_point_in_polygon(point, obstacle):
					d = -d
				distance = minf(distance, d)
				if d < obstacle_distance:
					obstacle_distance = d
					obstacle_normal = (point - obstacle_centers[obstacle_index]).normalized()
			if obstacle_distance < 1.2:
				var influence := 1.0 - smoothstep(0.0, 1.2, maxf(0.0, obstacle_distance))
				flow -= obstacle_normal * minf(flow.dot(obstacle_normal), 0.0) * influence
			var speed := lerpf(0.18, 1.0, smoothstep(0.0, 0.8, maxf(distance, 0.0)))
			var direction := flow.normalized() if flow.length_squared() > 0.0001 else Vector2.ZERO
			image.set_pixel(x, y, Color(distance, direction.x, direction.y, speed * (minf(flow.length(), 1.0) if stream else 1.0)))
	return {"texture": ImageTexture.create_from_image(image), "image": image, "bounds": bounds}

## Slice convex collision geometry at the water plane. Pairwise intersections include
## the hull edges; taking their 2D convex hull recovers the exact convex cross-section.
static func convex_slice(points: PackedVector3Array, transform: Transform3D, level: float = 0.035) -> PackedVector2Array:
	var local := PackedVector3Array()
	var section := PackedVector2Array()
	for point in points:
		local.append(transform * point)
	for index in range(local.size()):
		var a := local[index]
		if absf(a.y - level) < 0.0001:
			section.append(Vector2(a.x, a.z))
		for next in range(index + 1, local.size()):
			var b := local[next]
			if (a.y - level) * (b.y - level) < 0.0:
				var p := a.lerp(b, (level - a.y) / (b.y - a.y))
				section.append(Vector2(p.x, p.z))
	if section.size() < 3:
		return PackedVector2Array()
	var hull := Geometry2D.convex_hull(section)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.resize(hull.size() - 1)
	return hull

static func _find_root(parents: Array[int], index: int) -> int:
	while parents[index] != index:
		parents[index] = parents[parents[index]]
		index = parents[index]
	return index

## Visual geometry fallback for decorative stones with collision disabled.
## Keep disconnected shells separate so a cluster does not fill gaps between rocks.
static func mesh_sections(mesh: Mesh, transform: Transform3D) -> Array[PackedVector2Array]:
	var faces := mesh.get_faces()
	var lookup := {}
	var points := PackedVector3Array()
	var parents: Array[int] = []
	for triangle in range(0, faces.size(), 3):
		var ids: Array[int] = []
		for corner in range(3):
			var point := faces[triangle + corner]
			if not lookup.has(point):
				lookup[point] = points.size()
				parents.append(points.size())
				points.append(point)
			ids.append(lookup[point])
		var root := _find_root(parents, ids[0])
		for id in ids:
			parents[_find_root(parents, id)] = root
	var groups := {}
	for index in range(points.size()):
		var root := _find_root(parents, index)
		if not groups.has(root):
			groups[root] = PackedVector3Array()
		groups[root].append(points[index])
	var sections: Array[PackedVector2Array] = []
	for group in groups.values():
		var section := convex_slice(group, transform)
		if section.size() >= 3:
			sections.append(section)
	return sections
