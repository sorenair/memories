@tool
class_name PainterlyLightShaft
extends Node3D
## A slanted brush-soft sunbeam, suspended motes, and an optional grounding wash.
const BEAM_SHADER = preload("res://components/lighting/light_shaft/light_shaft.gdshader")
const MOTE_SHADER = preload("res://components/lighting/light_shaft/light_motes.gdshader")
const WASH = preload("res://components/lighting/light_wash/painterly_light_wash.tscn")
const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_group("Shaft Shape")
@export_range(0.5, 10.0, 0.1) var beam_height: float = 4.5:
	set(value):
		beam_height = clampf(value, 0.5, 10.0)
		_request_rebuild()
## Source position in local X/Z relative to the illuminated pool at the root.
@export var source_offset := Vector2(-1.5, -1.0):
	set(value):
		source_offset = value
		_request_rebuild()
@export var footprint := Vector2(2.8, 1.8):
	set(value):
		footprint = value.clamp(Vector2.ONE * 0.2, Vector2.ONE * 12.0)
		_request_rebuild()
@export_range(0.1, 4.0, 0.05) var source_width: float = 0.75:
	set(value):
		source_width = clampf(value, 0.1, 4.0)
		_request_rebuild()
@export_group("Paint and Light")
@export var light_color := Color(1.0, 0.92, 0.75, 1.0):
	set(value):
		light_color = value
		_update_materials()
@export_range(0.0, 0.6, 0.01) var opacity: float = 0.18:
	set(value):
		opacity = clampf(value, 0.0, 0.6)
		_update_materials()
@export_range(0.0, 1.0, 0.01) var paint_variation: float = 0.28:
	set(value):
		paint_variation = clampf(value, 0.0, 1.0)
		_update_materials()
@export var shaft_seed: int = 71:
	set(value):
		shaft_seed = value
		_request_rebuild()
@export_group("Motes")
@export_range(0, 256, 1) var mote_count: int = 72:
	set(value):
		mote_count = clampi(value, 0, 256)
		_request_rebuild()
@export var mote_color := Color(1.0, 0.96, 0.84, 1.0):
	set(value):
		mote_color = value
		_update_materials()
## A muted pigment edge keeps motes legible against light interiors too.
@export var mote_edge_color := Color(0.72, 0.65, 0.47, 1.0):
	set(value):
		mote_edge_color = value
		_update_materials()
@export var mote_size := Vector2(0.025, 0.055):
	set(value):
		var minimum := clampf(value.x, 0.005, 0.2)
		mote_size = Vector2(minimum, clampf(value.y, minimum, 0.3))
		_update_materials()
		_update_bounds()
## Meters per second; zero freezes motes, shaft breathing and the grounding wash.
@export_range(0.0, 0.6, 0.01) var drift_speed: float = 0.08:
	set(value):
		drift_speed = clampf(value, 0.0, 0.6)
		_update_materials()
@export_range(0.0, 0.4, 0.01) var wander: float = 0.10:
	set(value):
		wander = clampf(value, 0.0, 0.4)
		_update_materials()
		_update_bounds()
@export_group("Grounding Wash")
@export var ground_wash_enabled: bool = true:
	set(value):
		ground_wash_enabled = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.01) var ground_wash_intensity: float = 0.32:
	set(value):
		ground_wash_intensity = clampf(value, 0.0, 1.0)
		_update_materials()
@export_group("Rendering")
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 50.0:
	set(value):
		visibility_distance = value
		if is_inside_tree():
			for child in get_children(true):
				if child is GeometryInstance3D:
					child.visibility_range_end = value
			if _wash:
				_wash.visibility_distance = value

var _beam_material: ShaderMaterial
var _mote_material: ShaderMaterial
var _wash: PainterlyLightWash
var _recall_effect: Node
var _queued: bool = false

func _ready() -> void:
	rebuild()

func get_recall_controller() -> Node:
	return _recall_effect

func recall_materials() -> Array[ShaderMaterial]:
	var materials: Array[ShaderMaterial] = [_beam_material]
	if _mote_material:
		materials.append(_mote_material)
	if is_instance_valid(_wash):
		materials.append(_wash._material)
	return materials

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/lighting/light_shaft/light_shaft_recall.gd", _recall_effect)
	if not recall_enabled:
		for material in recall_materials():
			material.set_shader_parameter("recall_visibility", 1.0)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_materials() -> void:
	for material in [_beam_material, _mote_material]:
		if not material:
			continue
		for key in [&"beam_height", &"source_offset", &"footprint", &"source_width", &"drift_speed"]:
			material.set_shader_parameter(key, get(key))
	if _beam_material:
		for key in [&"light_color", &"opacity", &"paint_variation"]:
			_beam_material.set_shader_parameter(key, get(key))
		_beam_material.set_shader_parameter("paint_seed", float(posmod(shaft_seed, 1000)) * 0.173)
	if _mote_material:
		for key in [&"mote_color", &"mote_edge_color", &"mote_size", &"wander"]:
			_mote_material.set_shader_parameter(key, get(key))
	if is_instance_valid(_wash):
		_wash.light_color = light_color
		_wash.intensity = ground_wash_intensity
		_wash.motion_speed = drift_speed

func _update_bounds() -> void:
	if not is_inside_tree():
		return
	# Camera-facing ribbons can extend sideways in any viewing direction.
	var spread := maxf(footprint.x, source_width) * 0.5 + wander + mote_size.y
	var bounds := AABB(Vector3.ZERO, Vector3(0, beam_height, 0))
	bounds = bounds.expand(Vector3(source_offset.x, beam_height, source_offset.y)).grow(spread)
	bounds = bounds.expand(Vector3(-footprint.x * 0.5, 0, -footprint.y * 0.5)).expand(Vector3(footprint.x * 0.5, 0, footprint.y * 0.5))
	for name in ["Shaft", "Motes"]:
		var node := get_node_or_null(NodePath(name)) as GeometryInstance3D
		if node:
			node.custom_aabb = bounds

func _add_geometry(node: GeometryInstance3D) -> void:
	node.set_meta(&"generated_shaft", true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_wash = null
	_beam_material = null
	_mote_material = null
	for child in get_children(true):
		if child.get_meta(&"generated_shaft", false):
			remove_child(child)
			child.queue_free()
	_beam_material = ShaderMaterial.new()
	_beam_material.shader = BEAM_SHADER
	_beam_material.render_priority = -1
	var beam := MeshInstance3D.new()
	beam.name = "Shaft"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
		surface.set_uv(uv)
		surface.set_normal(Vector3.FORWARD)
		surface.add_vertex(Vector3(uv.x * 2.0 - 1.0, uv.y, 0))
	beam.mesh = surface.commit()
	beam.material_override = _beam_material
	_add_geometry(beam)
	if mote_count > 0:
		_mote_material = ShaderMaterial.new()
		_mote_material.shader = MOTE_SHADER
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = QuadMesh.new()
		multi.instance_count = mote_count
		var rng := RandomNumberGenerator.new()
		rng.seed = shaft_seed
		for index in range(mote_count):
			var angle := rng.randf() * TAU
			var radius := sqrt(rng.randf())
			multi.set_instance_transform(index, Transform3D.IDENTITY)
			multi.set_instance_custom_data(index, Color(rng.randf(), cos(angle) * radius * 0.5 + 0.5, sin(angle) * radius * 0.5 + 0.5, rng.randf()))
		var motes := MultiMeshInstance3D.new()
		motes.name = "Motes"
		motes.multimesh = multi
		motes.material_override = _mote_material
		_add_geometry(motes)
	if ground_wash_enabled:
		_wash = WASH.instantiate() as PainterlyLightWash
		_wash.name = "GroundingWash"
		_wash.footprint = footprint
		_wash.light_color = light_color
		_wash.intensity = ground_wash_intensity
		_wash.softness = 0.85
		_wash.motion = 2
		_wash.motion_amount = 0.06
		_wash.motion_speed = drift_speed
		_wash.visibility_distance = visibility_distance
		_wash.set_meta(&"generated_shaft", true)
		add_child(_wash, false, Node.INTERNAL_MODE_BACK)
	_update_materials()
	_update_bounds()
	_sync_recall()
