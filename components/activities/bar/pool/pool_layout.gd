extends RefCounted
## Shared by the rendered table and its local X/Z-plane simulation. Cue end is +Z.
const FIELD_SIZE := Vector2(1.18, 2.22)
const HALF := FIELD_SIZE * 0.5
const RADIUS := 0.033
const POCKET_RADIUS := 0.076
const CLOTH_Y := 0.85
const RAIL := 0.16
const HOME := Vector2(0, 0.70)
const APEX := Vector2(0, -0.30)
const RACK_ORDER = [1, 10, 2, 3, 8, 11, 12, 4, 13, 5, 14, 6, 15, 7, 9]
const COLORS = ["f3eddc", "e1b650", "548ca7", "bb655b", "8576ab", "d29150", "659074", "92545d", "303738", "e1b650", "548ca7", "bb655b", "8576ab", "d29150", "659074", "92545d"]

static func pockets() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-HALF.x, -HALF.y), Vector2(HALF.x, -HALF.y), Vector2(HALF.x, 0), Vector2(HALF.x, HALF.y), Vector2(-HALF.x, HALF.y), Vector2(-HALF.x, 0)])

static func rack() -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(16)
	result[0] = HOME
	var next := 0
	for row in range(5):
		for column in range(row + 1):
			var id: int = RACK_ORDER[next]
			result[id] = APEX + Vector2((float(column) - row * 0.5) * RADIUS * 2.015, -float(row) * sqrt(3.0) * RADIUS * 1.0075)
			next += 1
	return result

static func cloth_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	var r := POCKET_RADIUS * 1.04
	_arc(result, Vector2(HALF.x, -HALF.y), r, PI, PI * 0.5)
	_arc(result, Vector2(HALF.x, 0), r, -PI * 0.5, -PI * 1.5)
	_arc(result, Vector2(HALF.x, HALF.y), r, -PI * 0.5, -PI)
	_arc(result, Vector2(-HALF.x, HALF.y), r, 0, -PI * 0.5)
	_arc(result, Vector2(-HALF.x, 0), r, PI * 0.5, -PI * 0.5)
	_arc(result, Vector2(-HALF.x, -HALF.y), r, PI * 0.5, 0)
	return result

static func _arc(points: PackedVector2Array, center: Vector2, radius: float, start: float, end: float) -> void:
	for index in range(9):
		var angle := lerpf(start, end, float(index) / 8)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
