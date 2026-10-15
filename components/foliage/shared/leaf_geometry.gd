@tool
@static_unload
class_name PainterlyLeafGeometry
extends RefCounted
## Shared curved leaf geometry for tree crowns and shrubs.
static var _shared_leaf_spray: ArrayMesh
static var _shared_needle_spray: ArrayMesh

static func leaf_spray_mesh() -> ArrayMesh:
	if _shared_leaf_spray:
		return _shared_leaf_spray
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three curved oval leaves form one dimensional brush spray. Each leaf has
	# a gently raised center and bent rim; these are not flat decal layers.
	for leaf in range(3):
		var angle := float(leaf) * 2.39996
		var side := Vector3(cos(angle), 0, sin(angle))
		var forward := Vector3(-sin(angle), 0, cos(angle))
		var center := forward * 0.28 + Vector3.UP * (leaf * 0.16)
		for segment in range(10):
			var a0 := float(segment) * TAU / 10.0
			var a1 := float(segment + 1) * TAU / 10.0
			var p0 := center + side * cos(a0) * 0.62 + forward * sin(a0) * 0.95 + Vector3.UP * sin(a0) * 0.18
			var p1 := center + side * cos(a1) * 0.62 + forward * sin(a1) * 0.95 + Vector3.UP * sin(a1) * 0.18
			for point in [center + Vector3.UP * 0.16, p0, p1]:
				surface.set_normal(Vector3.UP)
				surface.set_color(Color.WHITE)
				surface.set_uv(Vector2(point.x, point.z))
				surface.add_vertex(point)
	_shared_leaf_spray = surface.commit()
	return _shared_leaf_spray

static func needle_spray_mesh() -> ArrayMesh:
	if _shared_needle_spray:
		return _shared_needle_spray
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two overlapping scalloped brush masses, not individually resolved needles.
	# Curved wings form broad, slightly upturned boughs with irregular painted rims.
	for layer in range(2):
		var center := Vector3(0, float(layer) * 0.22, float(layer) * 0.28)
		for segment in range(12):
			var rim: Array[Vector3] = []
			for offset in range(2):
				var index := (segment + offset) % 12
				var angle := float(index) * TAU / 12.0
				var scallop := 1.0 if index % 2 == 0 else 0.80
				var x := cos(angle) * 1.12 * scallop
				var z := sin(angle) * 0.82 * scallop
				rim.append(center + Vector3(x, -0.10 + x * x * 0.22 + sin(angle) * 0.12, z))
			for point in [center + Vector3.UP * 0.24, rim[0], rim[1]]:
				surface.set_normal(Vector3.UP)
				surface.set_color(Color.WHITE)
				surface.set_uv(Vector2(point.x, point.z))
				surface.add_vertex(point)
	_shared_needle_spray = surface.commit()
	return _shared_needle_spray
