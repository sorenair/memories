@tool
class_name WaterBodyGeometry
extends RefCounted
const SHAPES = preload("res://components/scenery/water/water_shapes.gd")

static func make_shape(kind: int, size: Vector2, seed_value: int, irregularity: float, bend: float, detail: int, pond_curve: Curve2D = null, stream_curve: Curve3D = null, width_curve: Curve = null) -> Dictionary:
	var data := {"outline": PackedVector2Array(), "centers": PackedVector2Array(), "sides": PackedVector2Array(), "widths": PackedFloat32Array(), "lengths": PackedFloat32Array()}
	if kind == 0:
		if pond_curve and pond_curve.point_count >= 3:
			var polygon := PackedVector2Array()
			var curve := pond_curve.duplicate() as Curve2D
			# Curve2D defaults to pixel-scale baking; these coordinates are meters.
			curve.bake_interval = minf(curve.bake_interval, 0.05)
			if not curve.get_point_position(0).is_equal_approx(curve.get_point_position(curve.point_count - 1)):
				curve.add_point(curve.get_point_position(0), curve.get_point_in(0), curve.get_point_out(0))
			var length := curve.get_baked_length()
			for index in range(detail):
				polygon.append(curve.sample_baked(length * float(index) / float(detail)))
			if Geometry2D.is_polygon_clockwise(polygon):
				polygon.reverse()
			if not Geometry2D.triangulate_polygon(polygon).is_empty():
				data.outline = polygon
		if data.outline.is_empty():
			data.outline = SHAPES.outline(0, size, seed_value, irregularity, bend, detail)
		return data
	var length := stream_curve.get_baked_length() if stream_curve and stream_curve.point_count >= 2 else 0.0
	for index in range(detail + 1):
		var t := float(index) / float(detail)
		var center: Vector2
		var tangent: Vector2
		if length > 0.001:
			var point := stream_curve.sample_baked(t * length)
			var before := stream_curve.sample_baked(maxf(0.0, t * length - 0.02))
			var after := stream_curve.sample_baked(minf(length, t * length + 0.02))
			center = Vector2(point.x, point.z)
			tangent = Vector2(after.x - before.x, after.z - before.z).normalized()
		else:
			center = Vector2(SHAPES.stream_center(t, size, bend, seed_value), (t - 0.5) * size.y)
			# Keep legacy section mouths/widths stable even when wider than their bends.
			tangent = Vector2(0, 1)
		if tangent.length_squared() < 0.1:
			tangent = Vector2(0, 1)
		data.lengths.append(0.0 if index == 0 else data.lengths[index - 1] + center.distance_to(data.centers[index - 1]))
		data.centers.append(center)
		data.sides.append(Vector2(tangent.y, -tangent.x))
		data.widths.append(size.x * 0.5 * (clampf(width_curve.sample_baked(t), 0.25, 2.0) if width_curve else 1.0))
	for index in range(detail + 1):
		data.outline.append(data.centers[index] + data.sides[index] * data.widths[index])
	for index in range(detail, -1, -1):
		data.outline.append(data.centers[index] - data.sides[index] * data.widths[index])
	return data

static func polygon_distance(point: Vector2, polygon: PackedVector2Array, skip_edges: PackedInt32Array = PackedInt32Array()) -> float:
	var distance := INF
	for index in range(polygon.size()):
		if index in skip_edges:
			continue
		var a := polygon[index]
		var delta := polygon[(index + 1) % polygon.size()] - a
		var t := clampf((point - a).dot(delta) / maxf(delta.length_squared(), 0.000001), 0.0, 1.0)
		distance = minf(distance, point.distance_squared_to(a + delta * t))
	return sqrt(distance)

static func stream_flow(point: Vector2, data: Dictionary) -> Vector2:
	var nearest := INF
	var flow := Vector2(0, 1)
	for index in range(data.centers.size() - 1):
		var a: Vector2 = data.centers[index]
		var delta: Vector2 = data.centers[index + 1] - a
		var t := clampf((point - a).dot(delta) / maxf(delta.length_squared(), 0.000001), 0.0, 1.0)
		var distance := point.distance_squared_to(a + delta * t)
		if distance < nearest:
			nearest = distance
			flow = delta.normalized()
	return flow
