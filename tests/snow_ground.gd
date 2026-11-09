extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var patch: PainterlySnowPatch=load("res://components/groundcover/snow/painterly_snow_patch.tscn").instantiate()
	patch.track_footprints=false
	root.add_child(patch)
	check(patch.get_children().is_empty(),"Generated snow must stay internal")
	var mesh: Mesh=patch.get_node("SnowSurface").mesh
	var faces:=mesh.get_faces()
	var valid:=true
	for index in range(0,faces.size(),3):
		valid=valid and faces[index].is_finite() and (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).length_squared()>0.000000001
	check(valid and faces.size()/3<7000,"Snow must have finite noncollapsed geometry within budget")
	check(patch.excludes_ground_point(Vector3.ZERO) and not patch.excludes_ground_point(Vector3(20,0,20)),"Grass exclusion must follow the snow footprint")
	check(patch._field.get_width()==256 and patch._field.get_format()==Image.FORMAT_RGF,"Balanced field must retain precise two-channel timestamps")
	check(patch.stamp_footprint(Vector3.ZERO,Vector3.FORWARD),"A shoe must stamp inside the snow")
	check(not patch.stamp_footprint(Vector3(20,0,20),Vector3.FORWARD),"Out-of-patch steps must not write the field")
	check(not patch.stamp_footprint(Vector3(0,2,0),Vector3.FORWARD),"Airborne height must not stamp")
	var visual:=patch.get_node("SnowSurface")
	patch.footprint_linger=3.0
	patch.footprint_fade_duration=1.0
	patch.snow_color=Color("eaf2ef")
	check(patch.get_node("SnowSurface")==visual,"Color and lifetime edits must preserve mesh and history")
	# Exercise distance sampling for two independent walking actors.
	var player:=Node3D.new()
	root.add_child(player)
	player.position=Vector3(-1.5,0,0)
	patch._track_player(player)
	var before:=patch._stamp_count
	for step in range(25):
		player.position.x+=0.08
		patch._track_player(player)
	check(patch._stamp_count>=before+4,"Walking must leave spaced alternating footsteps")
	before=patch._stamp_count
	for step in range(10):patch._track_player(player)
	check(patch._stamp_count==before,"Standing still must not emit footprints")
	player.position=Vector3(2.1,0,-0.4)
	patch._track_player(player)
	check(patch._stamp_count==before,"Teleporting must not stamp a connecting trail")
	var second:=Node3D.new()
	root.add_child(second)
	patch._track_player(second)
	check(patch._trackers.size()==2,"Players must retain independent stride state")
	var packed:=PackedScene.new()
	packed.pack(patch)
	var restored: PainterlySnowPatch=packed.instantiate()
	root.add_child(restored)
	check(restored.footprint_linger==3.0 and restored.footprint_fade_duration==1.0 and restored._stamp_count==0,"Settings must persist without runtime trails")
	restored.free()
	player.free()
	second.free()
	patch.free()
	# Confirm actual explorer movement writes prints in the integrated demo patch.
	var world: Node3D=load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	for frame in range(5):await physics_frame
	var demo: PainterlySnowPatch=world.get_node("Memory/Environment/Winter/SnowGround")
	var explorer: CharacterBody3D = world.get_node("Explorer")
	explorer.global_position = demo.global_position + Vector3(-0.5,0,-1.0)
	explorer.reset_physics_interpolation()
	Input.action_press("move_forward")
	for frame in range(65):await physics_frame
	Input.action_release("move_forward")
	check(demo._stamp_count>=2,"Walking the demo explorer must create footprints")
	world.free()
	print("Snow ground checks: ","PASS" if failures==0 else "FAIL"," | triangles: ",faces.size()/3)
	quit(failures)
