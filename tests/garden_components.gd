extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func run() -> void:
	for file in ["painterly_raked_gravel","painterly_stone_lantern"]:
		var item: PainterlyConcertComponent = load("res://components/scenery/gardens/"+file+".tscn").instantiate()
		root.add_child(item)
		await process_frame
		var mesh: Mesh = item._generated_root.get_node("PaintedProp").mesh
		var data := mesh.surface_get_arrays(0)
		var valid: bool = mesh.get_surface_count()==1 and mesh.surface_get_array_index_len(0)/3<6000
		for p: Vector3 in data[Mesh.ARRAY_VERTEX]: valid=valid and p.is_finite()
		for n: Vector3 in data[Mesh.ARRAY_NORMAL]: valid=valid and n.is_finite() and n.length_squared()>.1
		check(valid,"Garden pieces need finite, compact, opaque geometry: "+file)
		check(not item.is_processing(),"Static garden props should not need CPU animation callbacks")
		item.rebuild()
		check(item._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==data[Mesh.ARRAY_VERTEX],"Garden geometry should regenerate deterministically")
		item.recall_enabled=true
		var effect: Node = item.get_recall_controller()
		effect.set_process(false)
		effect.seek(.5)
		item.rebuild()
		check(item.get_recall_controller()==effect and effect.progress==.5,"Garden recall must survive rebuilds")
		check(item.excludes_ground_point(item.global_position) and not item.excludes_ground_point(Vector3(30,0,30)),"Garden ground exclusions should follow their actual shapes")
		if item is PainterlyRakedGravel:
			mesh=item._generated_root.get_node("PaintedProp").mesh
			item.rake_spacing=.31
			item.rock_centers=PackedVector2Array([Vector2(-1,0),Vector2(2,1)])
			check(item._generated_root.get_node("PaintedProp").mesh==mesh,"Rake pattern edits must not rebuild the gravel mesh")
			check(item._material.get_shader_parameter("rock_centers").size()==3,"The shader center array must remain padded and bounded")
			check(item.get_ground_outline().size()==64,"The bed should expose its outline for surrounding planting")
			item.footprint=Vector2(14,10)
			item.rebuild()
			check(item.get_recall_controller().progress==.5,"Changing gravel dimensions must preserve recall")
		else:
			check(item._generated_root.has_node("Collision") and item._generated_root.get_node("PaintedProp").mesh.get_aabb().size.y>1.7,"The stone lantern needs a full-height silhouette and solid exterior")
		var packed := PackedScene.new()
		check(packed.pack(item)==OK,"Garden pieces must serialize")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(),"Generated garden geometry must stay internal")
		copy.free()
		item.free()
		await process_frame
	print("Garden components: ","PASS" if failures==0 else "FAIL")
	quit(failures)
