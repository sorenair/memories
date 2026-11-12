extends SceneTree
const MARK = preload("res://components/scenery/stadium/minnesota_marks.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var zone := load("res://scenes/memories/snowy_stadium/stadium_zone.tscn").instantiate() as MemoryZone
	root.add_child(zone)
	var field: PainterlyFootballField = zone.get_node("Scenery/Field")
	var stands: PainterlyStadiumStands = zone.get_node("Scenery/Stands")
	check(field.minnesota_branding and stands.minnesota_branding,
		"The actual memory must enable Minnesota markings on both components")
	check(field.end_zone_color.is_equal_approx(MARK.MAROON)
		and stands.seat_color.is_equal_approx(MARK.MAROON),
		"Field and seats must use the reference's maroon")
	for polygon in [MARK.OUTER, MARK.GOLD_BORDER, MARK.INNER]:
		check(not Geometry2D.triangulate_polygon(PackedVector2Array(polygon)).is_empty(),
			"All three supplied-logo layers must be valid triangulated polygons")
	var arrays := field.get_node("Visual").mesh.surface_get_arrays(0) as Array
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var kinds: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var middle := 0
	var ends := [0, 0]
	for index in vertices.size():
		if not is_equal_approx(kinds[index].x, 4.0): continue
		if absf(vertices[index].x) < 10.0:
			middle += 1
		elif vertices[index].x < 0.0:
			ends[0] += 1
		else:
			ends[1] += 1
	check(middle > 100 and ends[0] > 100 and ends[1] > 100,
		"The actual field mesh must contain its traced midfield mark and both wordmarks")
	arrays = stands.get_node("Visual").mesh.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	kinds = arrays[Mesh.ARRAY_TEX_UV2]
	var paint_uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	check(paint_uv.size() == vertices.size() and stands._material.get_shader_parameter("minnesota_mark") != null,
		"The curved seating mark must retain the supplied image and UV coordinates")
	var lower_logo := 0
	var upper_text := 0
	var centers: Array[Vector3] = []
	var glow_sums: Array[Vector3] = []
	var glow_counts: Array[int] = []
	for x in [-46.0, 46.0]:
		for z in [-50.0, -9.0]:
			centers.append(Vector3(x, 24.0, z))
			glow_sums.append(Vector3.ZERO)
			glow_counts.append(0)
	for index in vertices.size():
		var vertex := vertices[index]
		if is_equal_approx(kinds[index].x, 6.0):
			lower_logo += 1
			check(paint_uv[index].x >= 0.0 and paint_uv[index].x < 0.93
				and paint_uv[index].y >= 0.0 and paint_uv[index].y < 0.99,
				"Seat art must sample the M crop, excluding the detached registered mark")
		if is_equal_approx(kinds[index].x, 4.0): upper_text += 1
		if not is_equal_approx(kinds[index].x, 3.0): continue
		var nearest := 0
		for candidate in centers.size():
			if vertex.distance_squared_to(centers[candidate]) < vertex.distance_squared_to(centers[nearest]):
				nearest = candidate
		glow_sums[nearest] += vertex
		glow_counts[nearest] += 1
	check(lower_logo > 100 and upper_text > 100, "Both seating-level Minnesota graphics must be in the final mesh")
	for index in centers.size():
		check(glow_counts[index] > 0, "Each stadium mast must contain emitting lamp faces")
		if glow_counts[index] == 0: continue
		var expected := (Vector3(0, 0, stands.FIELD_Z) - centers[index]).normalized()
		var offset := glow_sums[index] / glow_counts[index] - centers[index]
		check(offset.dot(expected) > 0.14 and offset.y < 0.0,
			"Actual lamp geometry must face inward and downward, including opposite masts")
	check(not zone.has_node("Scenery/FieldDriftLeft") and not zone.has_node("Scenery/FieldDriftRight"),
		"Regular oval field patches must not cover the new organic snow overlay")
	zone.free()
	await create_timer(0.35).timeout
	print("Minnesota marks / inward stadium lights: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
