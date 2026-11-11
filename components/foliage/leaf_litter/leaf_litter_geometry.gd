@tool
class_name PainterlyLeafLitterGeometry
extends RefCounted
## CPU-only mesh/layout generation also permits reliable headless verification.
static func create_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The tree's falling leaves are broad curved ovals. Resting leaves use that
	# same visual language, with more rim segments for a soft close-up silhouette.
	const SEGMENTS := 24
	var center := Vector3(0, 0.085, 0)
	for index in range(SEGMENTS):
		var a := _rim(float(index) * TAU / float(SEGMENTS))
		var b := _rim(float(index + 1) * TAU / float(SEGMENTS))
		for point in [center, b, a]:
			# Constant normals deliberately avoid a faceted cone / triangle wedges.
			# Painterly folds and color washes interpolate continuously over UVs.
			surface.set_normal(Vector3.UP)
			surface.set_color(Color.WHITE)
			surface.set_uv(Vector2(point.x, point.z))
			surface.add_vertex(point)
	return surface.commit()

static func _rim(angle: float) -> Vector3:
	var x := cos(angle) * 0.57 * (1.0 + sin(angle) * 0.10)
	var z := sin(angle) * 0.96 * (1.0 + cos(angle) * 0.07)
	# A tiny upturn on one rounded end reads as curled paper, not a sharp point.
	var curl := pow(maxf(0.0, sin(angle)), 2.0) * 0.042
	return Vector3(x, 0.012 + curl + cos(angle) * 0.006, z)

static func create_layout(seed_value: int, count: int, footprint: Vector2, sizes: Vector2, edge_bias: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for index in range(count):
		var p := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		var edge := p / maxf(maxf(absf(p.x), absf(p.y)), 0.001)
		p = p.lerp(edge, edge_bias * rng.randf_range(0.4, 1.0))
		var position := Vector3(p.x * footprint.x * 0.5, rng.randf_range(0.002, 0.007), p.y * footprint.y * 0.5)
		var size := lerpf(sizes.x, sizes.y, pow(rng.randf(), 1.4))
		var scale := Vector3(size * rng.randf_range(0.82, 1.12), size, size)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(scale)
		transforms.append(Transform3D(basis, position))
		colors.append(Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	return {"transforms": transforms, "colors": colors}
