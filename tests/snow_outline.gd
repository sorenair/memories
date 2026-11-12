extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	# An off-center L tests concavity and footprint mapping beyond the oval's origin.
	var outline := Curve2D.new()
	for point in [Vector2(2,-3), Vector2(8,-3), Vector2(8,0), Vector2(5,0), Vector2(5,5), Vector2(2,5)]:
		outline.add_point(point)
	var patch := load("res://components/groundcover/snow/painterly_snow_patch.tscn").instantiate() as PainterlySnowPatch
	patch.custom_outline = outline
	patch.track_footprints = false
	patch.position = Vector3(10,2,-4)
	patch.rotation.y = 0.3
	root.add_child(patch)
	var faces: PackedVector3Array = patch.get_node("SnowSurface").mesh.get_faces()
	var area := 0.0
	var valid := true
	for index in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		var cross_y := (b-a).cross(c-a).y
		area += cross_y*0.5
		var middle := (a+b+c)/3.0
		valid = valid and a.is_finite() and cross_y > 0.00000001 and Geometry2D.is_point_in_polygon(Vector2(middle.x,middle.z),patch._outline)
	check(valid and absf(area-33.0)<0.01 and faces.size()/3<15000,
		"Concave mesh must fill the whole 33-square-meter L, face upward and leave its cutout empty")
	for point in [Vector3(3,0,-2), Vector3(6.5,0,-1.5), Vector3(3.5,0,1), Vector3(3.5,0,4)]:
		check(patch.excludes_ground_point(patch.to_global(point)), "All arms and joins must exclude grass")
		check(patch.stamp_footprint(patch.to_global(point),patch.global_basis*Vector3.FORWARD),
			"Footprints must work in every arm, including areas far from the local origin")
		var pixel := Vector2i(patch._point_to_uv(Vector2(point.x,point.z))*patch._field.get_width())
		check(patch._field.get_pixelv(pixel).r>0.1, "Footprint UVs must agree with the translated geometry")
	check(not patch.stamp_footprint(patch.to_global(Vector3(6.5,0,3)),Vector3.FORWARD)
		and not patch.excludes_ground_point(patch.to_global(Vector3(6.5,0,3))),
		"Concave cutouts must reject footprints and leave ground visible")
	var visual := patch.get_node("SnowSurface")
	patch.snow_color = Color("eaf2ef")
	patch.footprint_linger = 3.0
	check(patch.get_node("SnowSurface") == visual and patch._stamp_count == 4,
		"Color and fade edits must preserve the connected snow and its footprints")
	var packed := PackedScene.new()
	packed.pack(patch)
	var restored := packed.instantiate() as PainterlySnowPatch
	root.add_child(restored)
	check(restored._custom_shape and restored._stamp_count == 0
		and restored.excludes_ground_point(restored.to_global(Vector3(3,0,4))),
		"Custom outlines must survive scene saving without runtime trails")
	restored.free()
	# Editing the shared curve must invalidate the editor preview and coverage.
	outline.set_point_position(4,Vector2(5,6))
	outline.set_point_position(5,Vector2(2,6))
	await process_frame
	check(patch.excludes_ground_point(patch.to_global(Vector3(3,0,5.5))),
		"Editing a shared outline must rebuild snow coverage")
	patch.free()
	await create_timer(0.2).timeout
	print("Concave snow coverage: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
