@tool
extends RefCounted
## Smooth sculpted stone / ceramic profiles. Vector2 = radius, height.
static func lathe(b: RefCounted, profile: Array[Vector2], color: Color, kind: float = 2.0, sides: int = 48, flute: float = 0.0) -> void:
	for ring in range(profile.size() - 1):
		for side in range(sides):
			for corner in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]:
				var row: int = ring + corner.x
				var angle := TAU * float(side + corner.y) / sides
				var p := profile[row]
				var previous := profile[maxi(row - 1, 0)]
				var following := profile[mini(row + 1, profile.size() - 1)]
				var delta := following - previous
				var ripple := 1.0 + flute * cos(angle * 16.0)
				var normal := Vector3(cos(angle) * delta.y, -delta.x, sin(angle) * delta.y).normalized()
				b.vertex(Vector3(cos(angle) * p.x * ripple, p.y, sin(angle) * p.x * ripple), normal, color, kind)
