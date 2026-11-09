extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var world: Node3D=load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var memory:=world.get_node("Memory")
	var environment:=memory.get_node("Environment")
	var platform: MemoryPlatform=environment.get_node("MemoryPlatform")
	for name in ["SummerSpring","Autumn","Winter"]:
		var zone:=environment.get_node(name)
		check(zone.has_node("Pond") and zone.has_node("Fire"),name+" must contain a pond and fire")
		var pond: PainterlyWater=zone.get_node("Pond")
		check(pond.palette_preset==({"SummerSpring":1,"Autumn":3,"Winter":4}[name]),"Pond colors must reflect the season")
		for component in zone.get_children():
			if component is PainterlyTree or component is PainterlyBush or component is PainterlyGrassPatch:
				var allowed: Array = [1,2] if name=="SummerSpring" else ([3,4] if name=="Autumn" else [5])
				check(component.palette_preset in allowed,"Every foliage instance must use its zone's seasonal palette")
				check(component.recall_enabled,"Scenery discovery must remain independently enabled")
			if component is Node3D:
				check(platform.contains_ground_point(component.global_position,0.5),"Seasonal scenery must stay inside the bounded memory")
	check(environment.get_node("SummerSpring").has_node("Rain") and environment.get_node("SummerSpring").has_node("Meadow"),"Summer must have rain and grass")
	check(not environment.get_node("Autumn").has_node("Rain") and not environment.get_node("Autumn").has_node("Snowfall") and environment.get_node("Autumn").has_node("Meadow"),"Autumn must have grass without weather")
	var winter:=environment.get_node("Winter")
	check(winter.has_node("Snowfall") and winter.has_node("SnowGround") and not winter.has_node("Meadow"),"Winter must have snowfall and snow groundcover instead of grass")
	var ground: PainterlySnowPatch=winter.get_node("SnowGround")
	var pond: PainterlyWater=winter.get_node("Pond")
	check(not ground.excludes_ground_point(pond.global_position),"Snow must leave the winter pond open")
	check(not ground.stamp_footprint(pond.global_position,Vector3.FORWARD),"Footsteps must not be stamped into the pond")
	check(ground.excludes_ground_point(winter.to_global(Vector3(-1,0,-1.2))),"Winter walking lane must be snow covered")
	# Walk the intended open route across all three clearings using real collision.
	var explorer: MemoryExplorer=world.get_node("Explorer")
	explorer.movement_camera=null
	explorer.walk_speed=6.0
	Input.action_press("move_right")
	for frame in range(330):
		await physics_frame
		if explorer.global_position.x>=12.0:break
	Input.action_release("move_right")
	check(explorer.global_position.x>=12.0 and explorer.is_on_floor(),"A player must be able to walk through all three zones without blockers")
	check(ground._stamp_count>=3,"Crossing the winter zone must create temporary footsteps")
	check(platform.contains_ground_point(explorer.global_position,0.5),"Connected route must stay safely on the platform")
	world.free()
	print("Seasonal demo checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
