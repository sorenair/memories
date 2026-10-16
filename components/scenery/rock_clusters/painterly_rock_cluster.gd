@tool
class_name PainterlyRockCluster
extends PainterlyBoulder
## A group of small stones using the boulder's geometry, palette, and paint shader.
## Merged surfaces avoid one draw call and material per stone.
@export_group("Cluster")
@export_range(0, 40, 1) var rock_count: int = 7:
	set(value):
		rock_count = clampi(value, 0, 40)
		_request_rebuild()
## Footprint of the rock centers. Actual edges extend beyond this by rock size.
@export var cluster_footprint := Vector2(2.1, 1.5):
	set(value):
		cluster_footprint = value.clamp(Vector2.ONE * 0.25, Vector2.ONE * 12.0)
		_request_rebuild()
## Multiplier applied to inherited boulder dimensions before individual variation.
@export_range(0.05, 1.0, 0.01) var rock_scale: float = 0.35:
	set(value):
		rock_scale = clampf(value, 0.05, 1.0)
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var size_variation: float = 0.8:
	set(value):
		size_variation = clampf(value, 0.0, 1.0)
		_request_rebuild()
@export_tool_button("Regenerate cluster") var regenerate_cluster = rebuild
var _rock_bounds: Array[AABB] = []

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name == "regenerate":
		property.usage = PROPERTY_USAGE_NONE

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_boulder", false):
			remove_child(child)
			child.queue_free()
	_rock_bounds.clear()
	_stone_material = null
	if rock_count == 0:
		scenery_changed.emit()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = boulder_seed ^ 0xC175
	var rotation := rng.randf() * TAU
	var stones := SurfaceTool.new()
	stones.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shadows := SurfaceTool.new()
	shadows.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "ClusterCollision"
	for index in range(rock_count):
		# A dominant stone, a companion, then a scattering of smaller satellites.
		var nominal := rng.randf_range(1.05, 1.25) if index == 0 else rng.randf_range(0.36, 0.90)
		if index == 1:
			nominal = rng.randf_range(0.82, 1.02)
		var size := rock_scale * lerpf(1.0, nominal, size_variation)
		var angle := rotation + float(index) * 2.399963 + rng.randf_range(-0.18, 0.18)
		var radial := sqrt(float(index) / float(maxi(rock_count - 1, 1))) * rng.randf_range(0.78, 1.0)
		var position := Vector3(cos(angle) * cluster_footprint.x * 0.5, 0, sin(angle) * cluster_footprint.y * 0.5) * radial
		var transform := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), position)
		var mesh := GEOMETRY.create_mesh(boulder_seed + index * 7919, dimensions * size, roundness, roughness, burial, shape_profile, variability)
		stones.append_from(mesh, 0, transform)
		var bounds: AABB = transform * mesh.get_aabb()
		_rock_bounds.append(bounds)
		_shadow_quad(shadows, bounds)
		if solid:
			var collision := CollisionShape3D.new()
			collision.name = "Rock%d" % (index + 1)
			collision.shape = mesh.create_convex_shape()
			collision.transform = transform
			body.add_child(collision)
	_stone_material = ShaderMaterial.new()
	_stone_material.shader = STONE_SHADER
	_update_colors()
	var rocks := MeshInstance3D.new()
	rocks.name = "Stones"
	rocks.mesh = stones.commit()
	rocks.material_override = _stone_material
	_add_generated(rocks)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadows"
	shadow.mesh = shadows.commit()
	var material := ShaderMaterial.new()
	material.shader = SHADOW_SHADER
	material.set_shader_parameter("shadow_color", Color(0.25, 0.29, 0.25, 0.28))
	shadow.material_override = material
	_add_generated(shadow)
	if solid:
		_add_generated(body)
	else:
		body.free()

	scenery_changed.emit()

func _shadow_quad(surface: SurfaceTool, bounds: AABB) -> void:
	var center := bounds.get_center()
	var half := Vector2(bounds.size.x, bounds.size.z) * 0.75
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for corner in [0, 1, 2, 0, 2, 3]:
		var q: Vector2 = corners[corner]
		surface.set_normal(Vector3.UP)
		surface.set_uv((q + Vector2.ONE) * 0.5)
		surface.add_vertex(Vector3(center.x + q.x * half.x, 0.014, center.z + q.y * half.y))
