extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)

func run() -> void:
	var study: Node3D=load("res://tests/scenes/graduation_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	var setup: Node3D=study.subject
	var deck: PainterlyCommencementStage=setup.get_node("CommencementStage")
	var chairs: PainterlyCeremonySeating=setup.get_node("Chairs")
	var graduates: PainterlyGraduateCrowd=setup.get_node("SeatedGraduates")
	var lectern: PainterlyLectern=setup.get_node("Lectern")
	var diplomas: PainterlyDiplomaTable=setup.get_node("DiplomaTable")
	check(chairs.get_seat_transforms().size()==24 and graduates.generated_count==24,"All twenty-four authored chairs must have matching graduates")
	check(chairs._generated_root.get_node("ChairRows").multimesh.instance_count==24,"Chairs must share one repeated mesh batch")
	check(chairs._generated_root.get_node("Collision").get_child_count()==24,"Each chair must have solid collision")
	check(graduates.get_statistics().hitboxes==24,"Graduates must retain the crowd's individual hitboxes")
	check(not graduates.is_processing() and not deck.is_processing(),"Crowd idle and banner wind must use no CPU frame callbacks")
	var poses := graduates._placements.duplicate()
	graduates.rebuild()
	check(graduates._placements==poses,"Graduates must reproduce their seeded seat identities")
	for index in range(graduates.generated_count):
		var hip: Vector3=graduates.to_global(graduates._placements[index].origin+Vector3.UP*graduates.person_scale*0.32)
		var seat: Vector3=chairs.to_global(chairs.get_seat_transforms()[index].origin)
		check(hip.distance_to(seat)<0.001,"Every seated hip must align with its actual chair surface")
	for prop in [deck,chairs,lectern,diplomas,graduates]:
		prop.recall_enabled=true
		var effect: Node=prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.4)
		prop.rebuild()
		check(prop.get_recall_controller()==effect and is_equal_approx(effect.progress,0.4),"Graduation component edits must preserve recall progress")
		prop.recall_enabled=false
		var packed := PackedScene.new()
		check(packed.pack(prop)==OK,"Ceremony components must save as reusable parameter scenes")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(),"Generated ceremony parts must not serialize")
		copy.free()
	chairs.rows=2
	chairs.seats_per_row=6
	chairs.aisle_width=2
	await process_frame
	await process_frame
	check(graduates.generated_count==12,"Editing chair rows must regenerate and cap seated occupants")
	chairs.rotation.y=0.3
	chairs.position.x=0.4
	await process_frame
	await process_frame
	var hip: Vector3=graduates.to_global(graduates._placements[0].origin+Vector3.UP*graduates.person_scale*0.32)
	check(hip.distance_to(chairs.to_global(chairs.get_seat_transforms()[0].origin))<0.001,"Seated occupants must follow moved and rotated chair layouts")
	graduates.count=6
	for side in [PainterlyGraduateCrowd.SeatingSide.LEFT,PainterlyGraduateCrowd.SeatingSide.RIGHT]:
		graduates.seating_side=side
		await process_frame
		await process_frame
		check(graduates.generated_count==6,"Each half must contain only its own six seats")
		for pose in graduates._placements:
			var local := chairs.to_local(graduates.to_global(pose.origin))
			check(local.x<0 if side==PainterlyGraduateCrowd.SeatingSide.LEFT else local.x>0,"Seat filtering must follow rotated chair-local coordinates")
	graduates.seating_side=PainterlyGraduateCrowd.SeatingSide.ALL
	graduates.count=24
	graduates.cap_matches_gown=false
	graduates.cap_color=Color.WHITE
	graduates.gown_color=Color.PURPLE
	check(graduates._material.get_shader_parameter("cap_color")==Color.WHITE,"Caps must support a separate paint color")
	graduates.cap_matches_gown=true
	check(graduates._material.get_shader_parameter("cap_color")==Color.PURPLE,"The default cap mode must continue following robe edits")
	chairs.rotation.y=0
	chairs.position.x=0
	chairs.rows=3
	chairs.seats_per_row=8
	chairs.aisle_width=1.8
	await process_frame
	await process_frame
	# Traverse the occupied seating's center aisle and the inherited real ramp.
	var actor: MemoryExplorer=study.get_node("Explorer")
	actor.set_physics_process(false)
	actor.position=Vector3(0,0.03,8.2)
	actor.reset_physics_interpolation()
	for frame in range(250):
		await physics_frame
		actor.velocity=Vector3(0,-0.8,-1.8)
		actor.move_and_slide()
	check(actor.position.z<1.25 and actor.position.y>0.40,"Explorer must walk through the occupied aisle and onto the ceremony deck")
	for frame in range(250):
		await physics_frame
		actor.velocity=Vector3(0,-0.8,1.8)
		actor.move_and_slide()
	check(actor.position.z>7.8 and actor.position.y<0.08,"Explorer must descend the ramp and return through the aisle")
	deck.banners_enabled=false
	deck.rebuild()
	check(not deck._generated_root.has_node("CeremonyBanners"),"Banner toggle must remove the fabric layer")
	check(deck._generated_root.get_node("Collision").get_child_count()==2,"Banner toggle must also remove both pole colliders")
	graduates.seating=null
	graduates.count=4
	graduates.rebuild()
	check(not graduates._material.get_shader_parameter("seated_posture") and graduates.generated_count==4,"Clearing Seating must restore the inherited standing layout")
	chairs.collision_enabled=false
	chairs.rebuild()
	check(not chairs._generated_root.has_node("Collision"),"Scenery-only chair rows must support disabling collision")
	for variant in range(8):
		var size: Vector3=graduates.ACADEMIC.head(variant).get_aabb().size
		check(size.x<0.48 and size.z<0.48 and size.y<0.55,"Caps and tassels must stay compact, including longer hair silhouettes")
	print("Graduation components: ","PASS" if failures==0 else "FAIL"," | standing fallback: ",graduates.get_statistics())
	study.free()
	await process_frame
	quit(failures)
