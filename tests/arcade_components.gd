extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var examples := [
		["pinball/painterly_pinball",7000,[&"Play",&"Ball"]],
		["punching_bag/painterly_punching_bag",3500,[&"Punch",&"BagPivot"]],
		["mechanical_band/painterly_mechanical_band",12000,[&"Play",&"GuitarButton",&"KickButton",&"SnareButton",&"PianoButton",&"Guitar",&"Kick",&"Snare",&"Piano"]],
		["bar_corner/painterly_arcade_corner",6500,[]]
	]
	for example in examples:
		var prop: PainterlyArcadeComponent = load("res://components/activities/arcade/"+example[0]+".tscn").instantiate()
		root.add_child(prop)
		var visual: MeshInstance3D = prop.get_node("Visual")
		var mesh: ArrayMesh = visual.mesh
		var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var triangles := points.size()/3
		check(mesh.get_surface_count()==1 and triangles>0 and triangles<example[1],example[0]+": must use one opaque surface within its mobile mesh budget")
		for point in points:
			if not point.is_finite():
				check(false,example[0]+": vertices must be finite")
				break
		check(prop.has_node("Collision") and prop.get_node("Collision").get_child_count()>0,example[0]+": must have simple collision")
		check(prop.get_children().is_empty(),example[0]+": generated nodes must remain internal")
		check(not prop.is_processing() and not prop.is_physics_processing(),example[0]+": static props must not have frame callbacks")
		for id in example[2]:
			var marker := prop.get_anchor(id)
			check(marker!=null and marker.position.is_finite(),example[0]+": must expose a usable "+str(id)+" hook")
		prop.rebuild()
		check(prop.get_node("Visual").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==points,example[0]+": same settings must regenerate deterministically")
		prop.prop_scale=1.25
		prop.cabinet_color=Color("846d87")
		prop.prop_seed=921
		prop.rebuild()
		check(prop.get_node("Visual").scale.is_equal_approx(Vector3.ONE*1.25),example[0]+": size control must scale the visual")
		check(is_equal_approx(prop._material.get_shader_parameter("pigment_strength"),prop.pigment_strength),example[0]+": shader must receive paint controls")
		var packed:=PackedScene.new()
		check(packed.pack(prop)==OK,example[0]+": must save cleanly")
		var copy: PainterlyArcadeComponent = packed.instantiate()
		root.add_child(copy)
		check(copy.prop_seed==921 and is_equal_approx(copy.prop_scale,1.25) and copy.cabinet_color.is_equal_approx(prop.cabinet_color),example[0]+": exported settings must survive serialization")
		check(copy.get_node("Visual").mesh.get_faces()==prop.get_node("Visual").mesh.get_faces(),example[0]+": restored component must reproduce geometry")
		copy.collision_enabled=false
		copy.rebuild()
		check(not copy.has_node("Collision"),example[0]+": collision must be optional")
		copy.free()
		prop.free()
		print(example[0]," | triangles: ",triangles)
	print("Arcade component checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
