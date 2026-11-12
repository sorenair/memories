extends Node
## Small, depth-tested silhouette passes. No screen texture, extra viewport, or idle draw.
const PAINT = preload("res://scripts/interaction/interaction_outline.gdshader")
var _entries: Dictionary = {}
var _meshes: Dictionary = {}

func _ready() -> void:
	set_process(false)

func refresh(available: Array[Node3D], selected: Node3D) -> void:
	for entry in _entries.values(): entry.desired = 0.0
	for target in available:
		if target.has_method("interaction_outline_selected_only") and target.interaction_outline_selected_only() and target != selected:
			continue
		var id := target.get_instance_id()
		var sources: Array[MeshInstance3D] = []
		var custom := target.has_method("set_interaction_outline")
		if not custom:
			if target.has_method("get_interaction_outline_meshes"):
				sources.assign(target.get_interaction_outline_meshes())
			else:
				_find_meshes(target, sources)
		if _entries.has(id) and not _matches(_entries[id], sources):
			_dispose(_entries[id])
			_entries.erase(id)
		if not _entries.has(id):
			var entry := {"target":weakref(target), "parts":[], "custom":custom, "amount":0.0, "desired":0.0, "selected":false}
			for source in sources:
				if not is_instance_valid(source) or source.mesh == null: continue
				var outline := MeshInstance3D.new()
				outline.name = "InteractionOutline"
				var silhouette: Mesh = target.get_interaction_outline_mesh(source) if target.has_method("get_interaction_outline_mesh") else source.mesh
				outline.mesh = _silhouette_mesh(silhouette)
				outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				outline.extra_cull_margin = 0.12
				outline.layers = source.layers
				var material := ShaderMaterial.new()
				material.shader = PAINT
				outline.material_override = material
				source.add_child(outline, false, Node.INTERNAL_MODE_BACK)
				entry.parts.append({"source":weakref(source), "mesh":source.mesh, "outline":weakref(outline), "material":material})
			_entries[id] = entry
		var entry: Dictionary = _entries[id]
		entry.desired = 1.0
		entry.selected = target == selected
	# Settled outlines breathe on the GPU; only fades need frame callbacks.
	for entry in _entries.values():
		if not is_equal_approx(entry.amount, entry.desired): set_process(true)
		_apply(entry)

func _process(delta: float) -> void:
	var fading := false
	for id in _entries.keys():
		var entry: Dictionary = _entries[id]
		entry.amount = move_toward(entry.amount, entry.desired, delta * 7.0)
		_apply(entry)
		if not is_instance_valid(entry.target.get_ref()) or (entry.desired == 0.0 and entry.amount == 0.0):
			_dispose(entry)
			_entries.erase(id)
		elif not is_equal_approx(entry.amount, entry.desired):
			fading = true
	set_process(fading)

func _apply(entry: Dictionary) -> void:
	var target: Node3D = entry.target.get_ref()
	if not is_instance_valid(target): return
	if entry.custom:
		target.set_interaction_outline(entry.amount, entry.selected)
	for part in entry.parts:
		part.material.set_shader_parameter("visibility", entry.amount)
		part.material.set_shader_parameter("selected", 1.0 if entry.selected else 0.0)

func _matches(entry: Dictionary, sources: Array[MeshInstance3D]) -> bool:
	if entry.custom: return true
	if entry.parts.size() != sources.size(): return false
	for i in sources.size():
		if entry.parts[i].source.get_ref() != sources[i] or not is_instance_valid(sources[i]) or entry.parts[i].mesh != sources[i].mesh:
			return false
	return true

func _dispose(entry: Dictionary) -> void:
	if entry.custom and is_instance_valid(entry.target.get_ref()):
		entry.target.get_ref().set_interaction_outline(0.0, false)
	for part in entry.parts:
		var outline: MeshInstance3D = part.outline.get_ref()
		if is_instance_valid(outline): outline.free()

func _exit_tree() -> void:
	for entry in _entries.values(): _dispose(entry)

func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	# Flat/transparent effect cards need their own contour hook (see MemoryFragment).
	if node is MeshInstance3D and node.mesh != null and not (node.mesh is QuadMesh or node.mesh is PlaneMesh):
		result.append(node)
	for child in node.get_children(true):
		if child.name != &"InteractionOutline": _find_meshes(child, result)

func _silhouette_mesh(source: Mesh) -> ArrayMesh:
	var id := source.get_instance_id()
	if _meshes.has(id) and _meshes[id].source.get_ref() == source: return _meshes[id].mesh
	# Weld split normals in the proxy only. This closes cracks on hard-edged cabinets
	# without changing their painted geometry, normals, or materials.
	var positions := PackedVector3Array()
	var normals: Array[Vector3] = []
	var indices := PackedInt32Array()
	var welded: Dictionary = {}
	for surface in source.get_surface_count():
		if source.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES: continue
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if ids.is_empty():
			for i in vertices.size(): ids.append(i)
		for tri in range(0, ids.size(), 3):
			var a := ids[tri]; var b := ids[tri+1]; var c := ids[tri+2]
			var face := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
			if face.length_squared() < 0.000000000001: continue
			var outward := ns[a]+ns[b]+ns[c] if not ns.is_empty() else -face
			# Godot front faces wind clockwise. Some authored two-sided profiles don't.
			var order := [a,c,b] if face.dot(outward)>0.0 else [a,b,c]
			for v: int in order:
				var key := Vector3i((vertices[v]*10000.0).round())
				if not welded.has(key):
					welded[key] = positions.size()
					positions.append(vertices[v])
					normals.append(Vector3.ZERO)
				var index: int = welded[key]
				normals[index] += ns[v] if not ns.is_empty() else outward.normalized()
				indices.append(index)
	var smooth := PackedVector3Array()
	for normal in normals: smooth.append(normal.normalized())
	var result := ArrayMesh.new()
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = positions
	data[Mesh.ARRAY_NORMAL] = smooth
	data[Mesh.ARRAY_INDEX] = indices
	if not positions.is_empty(): result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	# Bound the cache across memory changes/regeneration. Live passes retain resources.
	if _meshes.size() >= 32: _meshes.erase(_meshes.keys()[0])
	_meshes[id] = {"source":weakref(source), "mesh":result}
	return result
