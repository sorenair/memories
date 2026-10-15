@tool
class_name WaterShapes
extends RefCounted
## Shared analytic outlines used for surface, bank, collision, and foliage masking.
static func phase(seed_value: int) -> float:
	return float(posmod(seed_value, 1000)) * 0.173

static func pond_radius(angle: float, seed_value: int, irregularity: float) -> float:
	var p := phase(seed_value)
	return 1.0 + irregularity * (sin(angle * 3.0 + p) * 0.55 + sin(angle * 5.0 - p * 0.7) * 0.30 + sin(angle * 7.0 + p * 1.3) * 0.15)

static func stream_center(t: float, size: Vector2, bend: float, seed_value: int = 47) -> float:
	# Position and tangent return to zero at each end for aligned modules.
	if t <= 0.0 or t >= 1.0:
		return 0.0
	return sin(t * TAU + sin(phase(seed_value)) * 0.65) * pow(sin(t * PI), 2.0) * size.x * bend

static func outline(kind: int, size: Vector2, seed_value: int, irregularity: float, bend: float, detail: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	if kind == 0:
		for index in range(detail):
			var angle := float(index) * TAU / float(detail)
			points.append(Vector2(cos(angle), sin(angle)) * size * 0.5 * pond_radius(angle, seed_value, irregularity))
	else:
		for side in [1.0, -1.0]:
			for index in range(detail + 1):
				var t := float(index if side > 0.0 else detail - index) / float(detail)
				points.append(Vector2(stream_center(t, size, bend, seed_value) + side * size.x * 0.5, (t - 0.5) * size.y))
	return points

static func contains(kind: int, point: Vector2, size: Vector2, seed_value: int, irregularity: float, bend: float, margin: float = 0.0) -> bool:
	if kind == 0:
		var q := point / (size * 0.5)
		return q.length() <= pond_radius(atan2(q.y, q.x), seed_value, irregularity) + margin / (minf(size.x, size.y) * 0.5)
	var t := point.y / size.y + 0.5
	if t < 0.0 or t > 1.0:
		return false
	return absf(point.x - stream_center(t, size, bend, seed_value)) <= size.x * 0.5 + margin
