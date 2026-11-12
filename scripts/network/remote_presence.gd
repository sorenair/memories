extends Node
## Shared explorer recall. Callers own input, networking and scene navigation.
signal arrived
signal departed
const PAINT = preload("res://scripts/network/remote_presence.gdshader")
const ARRIVAL_DURATION := 1.25
const DEPARTURE_DURATION := 0.95
var progress := 0.0
var departing := false
var free_on_departure := true
var _explorer: MemoryExplorer
var _surfaces: Array[Dictionary] = []
var _shadow: MeshInstance3D
var _shadow_original: Material
var _shadow_material: ShaderMaterial
var _shadow_color: Color
var _scan_height := 1.35

func _ready() -> void:
	_explorer = get_parent() as MemoryExplorer
	_shadow = _explorer.get_node("ContactShadow")
	_shadow_original = _shadow.get_active_material(0)
	_shadow_material = _shadow.get_active_material(0).duplicate() as ShaderMaterial
	_shadow_color = _shadow_material.get_shader_parameter("shadow_color")
	_shadow.material_override = _shadow_material
	_scan_height = _height()
	_bind(_explorer.visual)
	_apply()

func _bind(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for surface in range(node.mesh.get_surface_count()):
			var source := node.get_active_material(surface) as BaseMaterial3D
			if not source:
				continue
			var paint := ShaderMaterial.new()
			paint.shader = PAINT
			paint.set_shader_parameter("base_color", source.albedo_color)
			paint.set_shader_parameter("base_texture", source.albedo_texture)
			paint.set_shader_parameter("roughness", source.roughness)
			paint.set_shader_parameter("metallic", source.metallic)
			# Each skinned mesh has different local coordinates; one explorer-height
			# range makes feet, clothing, hair and accessories resolve together.
			paint.set_shader_parameter("recall_solid_bounds", Vector2(0.0, _scan_height))
			_surfaces.append({"mesh": node, "surface": surface,
				"original": source, "paint": paint})
			node.set_surface_override_material(surface, paint)
	for child in node.get_children():
		_bind(child)

func _height() -> float:
	# Authored avatars share the explorer's ground origin. Include both variants
	# so a presence/avatar update during the scan cannot expose an unpainted mesh.
	var height := 1.35
	for mesh in _explorer.visual.find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = _explorer.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		height = maxf(height, bounds.end.y)
	return height + 0.04

func disappear() -> void:
	if departing:
		return
	departing = true
	_explorer.collision_layer = 0
	_explorer.collision_mask = 0
	_explorer.set_walking(false)
	# Completed arrivals restore the exact authored materials. Reinstall only
	# this replica's temporary scan materials to play the effect backward.
	for surface in _surfaces:
		surface.mesh.set_surface_override_material(surface.surface, surface.paint)
	_shadow.material_override = _shadow_material
	set_process(true)
	_apply()

func _process(delta: float) -> void:
	if departing:
		progress = maxf(0.0, progress - delta / DEPARTURE_DURATION)
	else:
		progress = minf(1.0, progress + delta / ARRIVAL_DURATION)
	_apply()
	if departing and progress <= 0.0:
		set_process(false)
		departed.emit()
		if free_on_departure:
			_explorer.queue_free()
	elif not departing and progress >= 1.0:
		restore()
		arrived.emit()

func restore() -> void:
	progress = 1.0
	departing = false
	for surface in _surfaces:
		surface.mesh.set_surface_override_material(surface.surface, surface.original)
	_shadow.material_override = _shadow_original
	set_process(false)

func _apply() -> void:
	for surface in _surfaces:
		surface.paint.set_shader_parameter("recall_solid_progress", smoothstep(0.0, 1.0, progress))
		surface.paint.set_shader_parameter("base_y", _explorer.global_position.y)
	var color := _shadow_color
	color.a *= smoothstep(0.0, 0.85, progress)
	_shadow_material.set_shader_parameter("shadow_color", color)
