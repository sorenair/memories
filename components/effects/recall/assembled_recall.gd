extends Node
## One proximity-triggered upward scan for a component made of several paint batches.
## Collision remains in place so buildings and stairs stay safe during manifestation.
signal finished
@export var patch: Node3D
@export_range(0.5, 10.0, 0.1) var duration: float = 2.4
var auto_discover: bool = false
var progress: float = 0.0
var playing: bool = false
var _materials: Array[ShaderMaterial] = []
var _details: Array[GeometryInstance3D] = []
var _shadows: Array[Dictionary] = []
var _bounds := AABB()
const RECALL = preload("res://components/effects/recall/component_recall.gd")

static func geometry(component: Node) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	for child in component.get_children(true):
		# Authored nested components own their recall lifecycle.
		if child.has_method("get_recall_controller"):
			continue
		if child is GeometryInstance3D:
			result.append(child)
		result.append_array(geometry(child))
	return result

static func has_scan(material: ShaderMaterial) -> bool:
	if not material or not material.shader:
		return false
	for uniform in material.shader.get_shader_uniform_list():
		if uniform.name == "assembly_progress":
			return true
	return false

static func restore_component(component: Node) -> void:
	for visual in geometry(component):
		var material := visual.material_override as ShaderMaterial
		if has_scan(material):
			material.set_shader_parameter("assembly_progress", 1.0)
		if visual.has_meta(&"recall_detail_visible"):
			visual.visible = visual.get_meta(&"recall_detail_visible")
		if visual.has_meta(&"recall_shadow_color") and material:
			material.set_shader_parameter("shadow_color", visual.get_meta(&"recall_shadow_color"))

func _ready() -> void:
	reset()

func bind_materials() -> void:
	_materials.clear()
	_details.clear()
	_shadows.clear()
	var first := true
	for visual in geometry(patch):
		var material := visual.material_override as ShaderMaterial
		if has_scan(material):
			if not _materials.has(material):
				_materials.append(material)
			var local_bounds: AABB = visual.custom_aabb if visual.custom_aabb.has_volume() else visual.get_aabb()
			var bounds: AABB = patch.global_transform.affine_inverse() * visual.global_transform * local_bounds
			_bounds = bounds if first else _bounds.merge(bounds)
			first = false
		elif (visual.name == &"ContactShadow" or str(visual.name).begins_with("Contact_")) and material:
			if not visual.has_meta(&"recall_shadow_color"):
				visual.set_meta(&"recall_shadow_color", material.get_shader_parameter("shadow_color"))
			_shadows.append({"material": material, "color": visual.get_meta(&"recall_shadow_color")})
		else:
			# Score displays and impact overlays retain their authored visibility;
			# they become available after the cabinet resolves.
			if not visual.has_meta(&"recall_detail_visible"):
				visual.set_meta(&"recall_detail_visible", visual.visible)
			_details.append(visual)
	var world_bounds: AABB = patch.global_transform * _bounds
	for material in _materials:
		material.set_shader_parameter("assembly_bounds", Vector2(world_bounds.position.y, world_bounds.end.y))

func reset() -> void:
	playing = false
	bind_materials()
	seek(0.0)

func play() -> void:
	playing = progress < 1.0

func replay() -> void:
	reset()
	play()

func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	restore_state()

func restore_state() -> void:
	for material in _materials:
		material.set_shader_parameter("assembly_progress", smoothstep(0.0, 1.0, progress))
	for detail in _details:
		detail.visible = progress >= 1.0 and detail.get_meta(&"recall_detail_visible", true)
	for shadow in _shadows:
		var color: Color = shadow.color
		color.a *= smoothstep(0.0, 0.85, progress)
		shadow.material.set_shader_parameter("shadow_color", color)

func _process(delta: float) -> void:
	if auto_discover and not playing and progress == 0.0:
		# Buildings, roof leaves and overhead vines are approached at ground level.
		# Measure their horizontal footprint so elevated accents can resolve too.
		if _explorer_near():
			play()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()

func _explorer_near() -> bool:
	if patch.has_method("get_recall_anchor"):
		var anchor: Node3D = patch.get_recall_anchor()
		if is_instance_valid(anchor):
			return RECALL.explorer_near(anchor, Vector2.ZERO)
	var world: AABB = patch.global_transform * _bounds
	var center := world.get_center()
	var reach := Vector2(world.size.x, world.size.z) * 0.5 + Vector2.ONE * RECALL.proximity_distance()
	for explorer in RECALL.explorers(patch):
		if explorer is Node3D:
			var point: Vector3 = explorer.global_position - center
			if Vector2(point.x / maxf(reach.x, 0.001), point.z / maxf(reach.y, 0.001)).length() <= 1.0:
				return true
	return false
