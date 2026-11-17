extends SceneTree
const BUILDER = preload("res://components/scenery/flatirons/flatiron_geometry.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func validate(mesh: Mesh) -> int:
	var a := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var ids: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var valid := true
	var edges := {}
	var welded := {}
	var canonical := PackedInt32Array()
	for p in points:
		if not welded.has(p): welded[p] = welded.size()
		canonical.append(welded[p])
	for i in range(0,ids.size(),3):
		var x := ids[i]
		var y := ids[i+1]
		var z := ids[i+2]
		var normal := (points[z]-points[x]).cross(points[y]-points[x])
		valid = valid and normal.length_squared()>0.00000001 and normal.dot(normals[x])>0
		for edge: Vector2i in [Vector2i(x,y),Vector2i(y,z),Vector2i(z,x)]:
			var pair := Vector2i(mini(canonical[edge.x],canonical[edge.y]),maxi(canonical[edge.x],canonical[edge.y]))
			edges[pair] = edges.get(pair,0)+1
	for i in range(points.size()):
		valid = valid and points[i].is_finite() and normals[i].is_finite() and is_equal_approx(normals[i].length(),1.0)
	var closed := true
	for uses in edges.values(): closed = closed and uses==2
	check(valid,"Flatiron faces must be finite, nondegenerate, normalized and wound outward")
	check(closed,"Every fractured plate and backing must form a closed shell")
	check(mesh.get_surface_count()==1 and ids.size()/3<1800,"Flatiron must stay in one compact opaque batch")
	return ids.size()/3
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/flatiron_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var rock: PainterlyFlatiron = stage.subject.get_node("Classic")
	var budgets := {}
	for form in range(3):
		var c := rock._config()
		c.formation_type = form
		for seed_value in [7,94,181]:
			c.prop_seed = seed_value
			var data: Dictionary = BUILDER.new().create(c)
			budgets[form] = validate(data.mesh)
			check(data.colliders.size()>=3 and data.colliders.size()<=20,"Flatiron collision must follow the fractured plates")
			var points: PackedVector3Array = data.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			check(BUILDER.new().create(c).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==points,"Flatiron seed must regenerate deterministic geometry")
	# Protect thin/wide and steep/tall authoring extremes from inverted plates.
	for steep: bool in [false,true]:
		var c := rock._config()
		c.formation_width = 35.0
		c.formation_height = 60.0 if steep else 4.0
		c.slope_angle = 80.0 if steep else 40.0
		c.thickness = 0.6
		c.jaggedness = 1.0
		c.fracture_count = 7 if steep else 1
		validate(BUILDER.new().create(c).mesh)
	var mesh: Mesh = rock._generated_root.get_node("PaintedProp").mesh
	for preset in range(1,7):
		rock.palette_preset = preset
		check(rock._generated_root.get_node("PaintedProp").mesh==mesh and rock._material.get_shader_parameter("mid_color")==rock.palette.mid_color,"Existing stone palette selection must update without rebuilding")
	rock.palette_preset = 4
	rock.palette.mid_color = Color("cda38b")
	check(rock.palette_preset==0 and rock._material.get_shader_parameter("mid_color")==rock.palette.mid_color,"Editing a palette must switch to Custom and update paint")
	rock.recall_enabled = true
	var effect: Node = rock.get_recall_controller()
	effect.set_process(false)
	effect.seek(0.5)
	rock.rebuild()
	check(effect==rock.get_recall_controller() and is_equal_approx(effect.progress,0.5) and is_equal_approx(rock._material.get_shader_parameter("assembly_progress"),0.5),"Flatiron recall must survive rebuilds")
	check(rock._generated_root.has_node("Collision"),"Large stone collision must remain present during recall")
	rock.recall_enabled = false
	check(not rock.is_processing(),"Static Flatirons must not need CPU frame callbacks")
	# Sweep the actual explorer into the cliff at its authored approach point.
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	stage.get_node("Partner").set_physics_process(false)
	actor.position = rock.get_anchor(&"Approach").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	await physics_frame
	await physics_frame
	var hit := actor.move_and_collide(rock.global_basis*Vector3(0,0,-7))
	check(hit!=null and hit.get_collider()==rock._generated_root.get_node("Collision"),"Flatiron must block an explorer at its front face")
	check(rock.excludes_ground_point(rock.global_position),"Flatirons must expose groundcover exclusion through their hulls")
	var packed := PackedScene.new()
	check(packed.pack(rock)==OK,"Flatiron settings must pack")
	var copy: PainterlyFlatiron = packed.instantiate()
	check(copy.get_children().is_empty() and copy.palette_preset==0 and copy.palette.mid_color==rock.palette.mid_color,"Only authored settings and the custom stone palette must serialize")
	copy.free()
	rock.collision_enabled = false
	rock.rebuild()
	check(not rock._generated_root.has_node("Collision"),"Distant Flatirons must support collision off")
	print("Flatiron component checks: ","PASS" if failures==0 else "FAIL"," | triangles by form: ",budgets)
	stage.free()
	await process_frame
	quit(failures)
