extends SceneTree
## New reusable geometry must remain finite, seeded and safely serializable.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	for file in ["buildings/painterly_hanoi_house","bridge/painterly_red_bridge","temple/painterly_lake_temple","karst/painterly_limestone_karst","imperial/painterly_meridian_gate","imperial/painterly_thai_hoa_hall","terraces/painterly_rice_terraces","coast/painterly_coastal_headland","city/painterly_lotus_tower","city/painterly_clustered_spire_tower"]:
		var prop: PainterlyConcertComponent = load("res://components/scenery/vietnam/"+file+".tscn").instantiate()
		root.add_child(prop)
		await process_frame
		var variants := 1
		if prop is PainterlyHanoiHouse or prop is PainterlyLakeTemple:
			variants = 3
		elif prop is PainterlyLimestoneKarst:
			variants = 5
		for variant in variants:
			if prop is PainterlyHanoiHouse: prop.profile = variant
			if prop is PainterlyLimestoneKarst:
				prop.formation_profile = mini(variant, 1)
				prop.contour = maxi(variant - 1, 0)
			if prop is PainterlyLakeTemple:
				prop.landmark = variant % 2
				prop.roof_tiles_enabled = variant==2
				if variant==2: prop.footprint = Vector2(6.4,4.2)
			prop.rebuild()
			var mesh: Mesh = prop._generated_root.get_node("PaintedProp").mesh
			var arrays := mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var vertex_limit := 120000 if prop is PainterlyRiceTerraces else (50000 if prop is PainterlySaigonTower else 22000)
			check(vertices.size()>20 and vertices.size()<vertex_limit,"Each kit component should fit a bounded static mesh budget: "+file)
			for i in vertices.size(): check(vertices[i].is_finite() and normals[i].is_finite() and normals[i].length()>0.8,"Generated geometry needs valid vertices and normals: "+file)
			prop.rebuild()
			check(prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices,"The same seed must rebuild deterministically: "+file)
			print(file," variant ",variant," triangles: ",mesh.get_faces().size()/3)
		if prop is PainterlyLimestoneKarst:
			var previous: PackedVector3Array = prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			prop.prop_seed += 17
			prop.rebuild()
			check(prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=previous,"Different seeds should change the limestone silhouette")
		prop.recall_enabled = true
		var effect := prop.get_recall_controller()
		check(effect!=null,"New kit scenery needs assembled recall")
		effect.seek(0.45)
		prop.rebuild()
		check(is_equal_approx(prop.get_recall_controller().progress,0.45),"Rebuilding must preserve recall progress")
		prop.collision_enabled = false
		prop.rebuild()
		check(not prop._generated_root.has_node("Collision"),"Scenic variants must allow disabling collision")
		var scene := PackedScene.new()
		check(scene.pack(prop)==OK,"Authored component must serialize")
		var clone := scene.instantiate()
		check(clone.get_child_count()==0,"Generated children should not serialize")
		clone.free()
		prop.free()
		await process_frame
	print("Vietnam components: ","PASS" if failures==0 else "FAIL")
	quit(failures)
