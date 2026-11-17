extends SceneTree
var failures := 0
const PRESETS = ["earth_trail","gravel_walk","field_track","flagstone_path","urban_paver_path"]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func curve() -> Curve3D:
	var c := Curve3D.new()
	c.bake_interval = 0.05
	c.add_point(Vector3(0,0,6),Vector3.ZERO,Vector3(0,0,-1.8))
	c.add_point(Vector3(2,0.4,2.5),Vector3(0.2,0,1.6),Vector3(-0.2,0,-1.6))
	c.add_point(Vector3(-1.6,0.8,-2),Vector3(0,0,1.7),Vector3(0,0,-1.7))
	c.add_point(Vector3(0,1.2,-6),Vector3(-0.8,0,1.6),Vector3.ZERO)
	return c
func run() -> void:
	var budgets := {}
	for preset: String in PRESETS:
		var path: PainterlySurfacePath = load("res://components/groundcover/paths/"+preset+".tscn").instantiate()
		path.curve = curve()
		path.position = Vector3(8,0.4,-3)
		path.rotation.y = 0.6
		root.add_child(path)
		for i in range(3): await physics_frame
		var mesh: Mesh = path.get_node("PaintedRibbon").mesh
		var a := mesh.surface_get_arrays(0)
		var valid := true
		for p: Vector3 in a[Mesh.ARRAY_VERTEX]: valid = valid and p.is_finite()
		for n: Vector3 in a[Mesh.ARRAY_NORMAL]: valid = valid and n.is_finite() and is_equal_approx(n.length(),1.0)
		check(valid and mesh.get_surface_count()==1 and path.generated_triangles<14000,preset+": one finite, compact painted batch")
		budgets[preset] = path.generated_triangles
		check(not path.is_processing() and not path.is_physics_processing(),preset+": no per-frame geometry callbacks")
		var space := path.get_world_3d().direct_space_state
		var support := path.get_node("WalkingSurface")
		var length := path.get_path_length()
		var supported := true
		for i in range(1,80):
			var d := length*float(i)/80.0
			for across: float in [-0.34,0.0,0.34]:
				var p := path._edge(d,path.path_width*across,0.0125)
				var at := path.to_global(p)
				var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.20,at-Vector3.UP*0.20)
				query.hit_back_faces = false
				var hit := space.intersect_ray(query)
				supported = supported and not hit.is_empty() and hit.collider==support
		check(supported,preset+": continuous front-facing support along center and both passing lanes on a raised S curve")
		var d := length*0.45
		var at := path.to_global(path.point_at(d))
		check(path.excludes_ground_point(at)==not path.twin_tracks,preset+": exclusion follows the tread and preserves a field-track median")
		check(path.excludes_ground_point(path.to_global(path._edge(d,path.path_width*0.26,0.0125))),preset+": worn walking lane excludes grass")
		var outside := path.to_global(Vector3(-8,0,4))
		check(not path.excludes_ground_point(outside) and space.intersect_ray(PhysicsRayQueryParameters3D.create(outside+Vector3.UP*3,outside-Vector3.UP*3)).is_empty(),preset+": support/exclusion must not fill rectangular bounds")
		var fades := path.end_fade
		path.end_fade = Vector2.ZERO
		var beyond := path.point_at(0)+(path.point_at(0)-path.point_at(0.1)).normalized()*5.0
		check(not path.excludes_ground_point(path.to_global(beyond)),preset+": solid end connections must not exclude grass indefinitely beyond the curve")
		path.end_fade = fades
		var route := path.get_route_points(0,1,0.6)
		check(route.size()>15 and route[0].distance_to(path.to_global(path.point_at(0))+Vector3.UP*0.76)<0.01,preset+": existing world-space route API remains intact")
		path.rebuild()
		check(path.get_node("PaintedRibbon").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==a[Mesh.ARRAY_VERTEX] and path.get_node("PaintedRibbon").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]==a[Mesh.ARRAY_COLOR],preset+": seeded surfaces regenerate identically")
		mesh = path.get_node("PaintedRibbon").mesh
		path.paving_color = Color("bda98a")
		path.stone_color = Color("c9c3ae")
		check(path.get_node("PaintedRibbon").mesh==mesh,preset+": paint edits retain geometry")
		path.curve.set_point_position(1,Vector3(2.2,0.4,2.5))
		await process_frame
		await process_frame
		check(path.get_node("PaintedRibbon").mesh!=mesh and path.get_node("WalkingSurface").get_child_count()==1,preset+": handle edits replace one mesh and one collider")
		var packed := PackedScene.new()
		check(packed.pack(path)==OK,preset+": settings must pack")
		var copy: PainterlySurfacePath = packed.instantiate()
		check(copy.get_children().is_empty() and copy.curve.point_count==4 and copy.surface_style==path.surface_style,preset+": curve/style persist without generated children")
		copy.free()
		path.collision_enabled = false
		path.rebuild()
		check(not path.has_node("WalkingSurface"),preset+": optional collision off")
		path.curve = Curve3D.new()
		await process_frame
		await process_frame
		check(not path.has_node("PaintedRibbon"),preset+": empty curves clear stale meshes")
		path.free()
		await process_frame
	print("Path surface component checks: ","PASS" if failures==0 else "FAIL"," | triangles on raised S curve: ",budgets)
	quit(failures)
