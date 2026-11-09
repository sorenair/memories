extends SceneTree
## One shared distance must control every adapter, including scaled/rotated instances.
const RECALL = preload("res://components/effects/recall/component_recall.gd")
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var settings: Resource = RECALL.settings
	var saved: float = settings.proximity_distance
	var explorer := Node3D.new()
	explorer.add_to_group(&"explorers")
	root.add_child(explorer)
	var paths := [
		"res://components/foliage/painterly_grass_patch.tscn",
		"res://components/foliage/painterly_bush.tscn",
		"res://components/foliage/painterly_tree.tscn",
		"res://components/scenery/boulders/painterly_boulder.tscn",
		"res://components/scenery/rock_clusters/painterly_rock_cluster.tscn",
		"res://components/scenery/water/painterly_water.tscn",
		"res://components/lighting/light_wash/painterly_light_wash.tscn",
		"res://components/lighting/light_shaft/painterly_light_shaft.tscn",
		"res://components/vfx/smoke/painterly_smoke.tscn"]
	for path in paths:
		for scaled in [false, true]:
			explorer.position = Vector3(100, 0, 100)
			var component := load(path).instantiate() as Node3D
			component.recall_enabled = true
			if scaled:
				component.scale = Vector3(2, 1, 0.7)
				component.rotation.y = 0.55
			root.add_child(component)
			var effect: Node = component.get_recall_controller()
			effect.set_process(false)
			var edge := Vector3.ZERO
			if component is PainterlyGrassPatch:
				edge.x = component.patch_size.x * 0.5
			elif component is PainterlyLightWash or component is PainterlyLightShaft or component is PainterlySmoke:
				edge.x = component.footprint.x * 0.5
			elif component is PainterlyBush:
				edge.x = component.footprint.x * 0.5
			elif component is PainterlyTree:
				edge.x = component.crown_width * float(component._variant.width) * 0.5
			elif component is PainterlyBoulder:
				var bounds: AABB = component.get_recall_mesh().mesh.get_aabb()
				edge = Vector3(bounds.end.x, 0, bounds.get_center().z)
			elif component is PainterlyWater:
				var maximum := -INF
				for point in component._shape_data.outline:
					if point.x > maximum:
						maximum = point.x
						edge = Vector3(point.x, 0, point.y)
			explorer.global_position = component.to_global(edge) + component.global_basis.x.normalized() * 2.5
			settings.proximity_distance = 0.5
			effect._process(0.1)
			check(effect.progress == 0.0, "Small global reach must keep distant component hidden: " + path)
			settings.proximity_distance = 4.0
			effect._process(0.1)
			check(effect.playing and effect.progress > 0.0, "Increasing shared reach must trigger without rebuilding: " + path)
			check(component.get_recall_controller() == effect, "Distance changes must not replace effect controllers")
			explorer.global_position = Vector3(100, 0, 100)
			effect._process(effect.duration * 2.0)
			check(effect.progress == 1.0, "Started recall must finish when the player leaves")
			settings.proximity_distance = 0.0
			effect.reset()
			explorer.global_position = component.global_position
			effect._process(0.1)
			check(effect.playing, "Zero margin must still discover inside the footprint")
			component.free()
	settings.proximity_distance = saved
	print("Shared recall settings checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
