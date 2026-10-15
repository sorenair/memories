extends SceneTree
## godot --headless --path . --script tests/boulder_variations.gd
## Exercise the closed cutting-plane shell across shape extremes.
func _initialize() -> void:
	var failures := 0
	for shape_seed in [24, 25, 26, 27, 28, 29]:
		for roundness in [0.0, 0.45, 1.0]:
			for roughness in [0.0, 0.35]:
				var mesh := BoulderGeometry.create_mesh(shape_seed, Vector3(1.8, 1.25, 1.4), roundness, roughness, 0.12)
				var data := mesh.surface_get_arrays(0)
				var points: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
				var welded := {}
				var ids := PackedInt32Array()
				for point in points:
					if not welded.has(point):
						welded[point] = welded.size()
					ids.append(welded[point])
				var edges := {}
				var valid := true
				for triangle in range(0, indices.size(), 3):
					var a := indices[triangle]
					var b := indices[triangle + 1]
					var c := indices[triangle + 2]
					valid = valid and (points[c] - points[a]).cross(points[b] - points[a]).length_squared() > 0.00000000000001
					for pair in [[a,b],[b,c],[c,a]]:
						var key := "%d:%d" % [mini(ids[pair[0]],ids[pair[1]]),maxi(ids[pair[0]],ids[pair[1]])]
						edges[key] = edges.get(key, 0) + 1
				for count in edges.values():
					valid = valid and count == 2
				valid = valid and welded.size() - edges.size() + indices.size() / 3 == 2
				if not valid:
					print("Invalid variant: ", shape_seed, " / ", roundness, " / ", roughness, " | euler:", welded.size() - edges.size() + indices.size() / 3, " | edges:", edges.values().filter(func(n): return n != 2))
					failures += 1
	var min_height := INF
	var max_height := 0.0
	var min_aspect := INF
	var max_aspect := 0.0
	for shape_seed in range(24, 30):
		var mesh := BoulderGeometry.create_mesh(shape_seed, Vector3(1.8, 1.25, 1.4), 0.45, 0.12, 0.12)
		var size := mesh.get_aabb().size
		min_height = minf(min_height, size.y)
		max_height = maxf(max_height, size.y)
		min_aspect = minf(min_aspect, size.x / size.y)
		max_aspect = maxf(max_aspect, size.x / size.y)
	if max_height / min_height < 2.0 or max_aspect / min_aspect < 2.0:
		print("Seed silhouettes must differ substantially in height and aspect")
		failures += 1
	# Explicit family selection must override automatic seed cycling.
	var slab := BoulderGeometry.create_mesh(73, Vector3(1.8, 1.25, 1.4), 0.45, 0.12, 0.12, BoulderGeometry.Profile.SLAB)
	var upright := BoulderGeometry.create_mesh(73, Vector3(1.8, 1.25, 1.4), 0.45, 0.12, 0.12, BoulderGeometry.Profile.UPRIGHT)
	if upright.get_aabb().size.y < slab.get_aabb().size.y * 2.0:
		print("Explicit profiles must have distinct proportions")
		failures += 1
	print("Height spread: ", max_height / min_height, " | aspect spread: ", max_aspect / min_aspect)
	print("36 seeded shape variations and silhouette checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
