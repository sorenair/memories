extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func has_collision(node: Node) -> bool:
	if node is CollisionObject3D: return true
	for child in node.get_children(true):
		if has_collision(child): return true
	return false
func run() -> void:
	var echoes: PainterlyArcadeEchoes = load("res://components/activities/arcade/echoes/painterly_arcade_echoes.tscn").instantiate()
	root.add_child(echoes)
	check(not has_collision(echoes),"Decorative echoes must never recreate a physical room or floor")
	check(not echoes.is_processing() and not echoes.is_physics_processing(),"Ambient animation must avoid CPU frame callbacks")
	check(echoes.get_children().is_empty(),"Generated scenery must remain internal")
	var triangles := 0
	for name in ["FadingTraces","SuspendedBulbs"]:
		var visual: MeshInstance3D = echoes.get_node(name)
		var mesh: ArrayMesh = visual.mesh
		triangles += mesh.get_faces().size()/3
		for point in mesh.get_faces():
			check(point.is_finite(),"Ground traces and light supports must remain finite")
		var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		for color in colors:
			check(is_finite(color.a) and color.a>=0.0 and color.a<=1.0,"Fading paint must have valid opacity")
	check(triangles<5000,"Default decorative mesh budget must remain modest")
	var halos: MultiMeshInstance3D = echoes.get_node("BulbHalos")
	check(halos.multimesh.instance_count==echoes.light_count,"Each suspended bulb must have a batched halo")
	for i in range(echoes.light_count):
		# Headless Godot uses a dummy renderer; its MultiMesh getters return zero.
		# Check the authored path and full pendant-jitter/billboard envelope instead.
		var center := echoes.sample_light(float(i+1)/(echoes.light_count+1))-Vector3.UP*0.11
		check(halos.multimesh.custom_aabb.has_point(center+Vector3.ONE*0.31) and halos.multimesh.custom_aabb.has_point(center-Vector3.ONE*0.31),"Culling bounds must cover the billboard halo")
	var original: PackedVector3Array = echoes.get_node("FadingTraces").mesh.get_faces()
	echoes.rebuild()
	check(original==echoes.get_node("FadingTraces").mesh.get_faces(),"Scenery generation must be deterministic")
	var authored := Node3D.new()
	authored.name = "AuthoredDecoration"
	echoes.add_child(authored)
	echoes.echo_seed=173
	echoes.light_count=5
	echoes.floor_trace_opacity=0.28
	echoes.rebuild()
	check(is_instance_valid(authored) and authored.get_parent()==echoes,"Regeneration must preserve authored children")
	check(echoes.get_node("BulbHalos").multimesh.instance_count==5,"Light count must be editable")
	var packed:=PackedScene.new()
	check(packed.pack(echoes)==OK,"Decorative settings must save successfully")
	var restored: PainterlyArcadeEchoes = packed.instantiate()
	root.add_child(restored)
	check(restored.echo_seed==173 and restored.light_count==5 and is_equal_approx(restored.floor_trace_opacity,0.28),"Echo controls must survive saving and reloading")
	restored.light_count=0
	restored.rebuild()
	check(not restored.has_node("BulbHalos") and not restored.has_node("SuspendedBulbs"),"The suspended strand must be optional")
	check(not has_collision(restored),"Editing or disabling the lights must not add blockers")
	restored.free()
	echoes.free()
	print("Arcade echoes checks: ","PASS" if failures==0 else "FAIL"," | mesh triangles: ",triangles)
	quit(failures)
