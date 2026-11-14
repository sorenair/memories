@tool
class_name PainterlyBonsai
extends PainterlyTree
## Reuses the tree's smooth sculpted wood, leaf masses, palettes and GPU wind.
signal ground_exclusion_changed
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
const POT_BUILDER = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const POT_PAINT = preload("res://components/scenery/conservatory/shared/stone_paint.gdshader")
@export_group("Bonsai Form")
@export_enum("Twisted Upright", "Windswept", "Half Cascade") var bonsai_form: int = 0:
	set(value):
		bonsai_form = clampi(value, 0, 2)
		_request_rebuild()
## Plant height above the soil; the tray and optional pedestal add to this.
@export_range(0.55, 1.6, 0.05) var bonsai_height: float = 0.95:
	set(value):
		bonsai_height = clampf(value, 0.55, 1.6)
		_request_rebuild()
@export_range(0.7, 2.0, 0.05) var spread: float = 1.25:
	set(value):
		spread = clampf(value, 0.7, 2.0)
		_request_rebuild()
@export_range(0.1, 0.7, 0.05) var trunk_curve: float = 0.4:
	set(value):
		trunk_curve = clampf(value, 0.1, 0.7)
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var canopy_fullness: float = 0.7:
	set(value):
		canopy_fullness = clampf(value, 0, 1)
		_request_rebuild()
@export_group("Container")
@export var pot_color := Color("658187"):
	set(value):
		pot_color = value
		_request_rebuild()
@export_range(0.0, 0.8, 0.05) var pedestal_height: float = 0.0:
	set(value):
		pedestal_height = clampf(value, 0, 0.8)
		_request_rebuild()

func _init() -> void:
	# Normalize the hidden forest-scale helpers for programmatic instances too.
	tree_height = 1.5
	crown_width = 1.5
	wind_strength = 0.02
	falling_leaf_count = 0

func _ready() -> void:
	set_notify_transform(true)
	super._ready()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		ground_exclusion_changed.emit()

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	# Keep the useful shared palette/bark/wind/seed controls, hide forest-only ones.
	if property.name in ["tree_type", "tree_height", "crown_width", "trunk_radius", "trunk_bend", "branch_count", "leaf_sprays_per_cluster", "falling_leaf_count", "falling_leaf_rate", "use_type_bark"]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_palette_materials.clear()
	for child in get_children(true):
		if child.get_meta(&"generated_tree", false):
			remove_child(child)
			child.queue_free()
	_variant = VARIANTS.definition(0)
	var colors: GrassPalette = palette if palette else DEFAULT_PALETTE
	_canopy_material = _material(CANOPY_SHADER, colors)
	_update_wind()
	var wood_material := _material(BARK_SHADER, colors)
	wood_material.set_shader_parameter("bark_shadow", bark_shadow)
	wood_material.set_shader_parameter("bark_light", bark_light)
	var rng := RandomNumberGenerator.new()
	rng.seed = tree_seed
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := pedestal_height + 0.215
	var h := bonsai_height
	var points: Array[Vector3] = []
	var widths: Array[float] = []
	var shape_phase := rng.randf_range(-0.45, 0.45)
	for index in range(7):
		var t := float(index) / 6.0
		var x := (sin(t * TAU * 0.9 + shape_phase) - sin(shape_phase)) * trunk_curve * spread * 0.52
		var y := t * h * 0.84
		if bonsai_form == 1:
			x = pow(t, 1.1) * spread * trunk_curve + sin(t * TAU) * spread * 0.06
		elif bonsai_form == 2:
			if t <= 0.38:
				x = sin(t / 0.76 * PI) * spread * 0.20
				y = t / 0.38 * h * 0.62
			else:
				var u := (t - 0.38) / 0.62
				x = spread * (0.20 + (0.45 + trunk_curve * 0.25) * u)
				y = h * (0.62 * (1.0 - u) + 0.12 * u + sin(u * PI) * 0.20)
		points.append(Vector3(x, base + y, sin(t * PI) * spread * 0.055))
		widths.append(h * lerpf(0.105, 0.019, t))
	_tube(bark, points, widths, rng)
	# Three thick, soft root flares stay within the soil tray.
	for index in range(3):
		var a := float(index) * TAU / 3.0 + 0.6
		var out := Vector3(cos(a), 0, sin(a))
		_tube(bark, [Vector3(0, base + 0.10, 0), out * 0.12 + Vector3.UP * (base + 0.015), out * 0.22 + Vector3.UP * (base - 0.008)], [h * 0.065, h * 0.040, h * 0.009], rng)
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	for pad in range(4):
		var t: float = [0.44, 0.64, 0.79, 1.0][pad]
		var attach := points[mini(5, roundi(t * 5.0))]
		var direction := -1.0 if pad % 2 == 0 else 1.0
		var tip := attach + Vector3(direction * spread * (0.28 if pad < 3 else 0.08), h * (0.10 if pad < 3 else 0.03), (0.14 if pad == 1 else -0.06) * spread)
		if bonsai_form == 1:
			tip.x = attach.x + spread * (0.22 if pad < 3 else 0.08)
		elif bonsai_form == 2:
			attach = points[[2, 4, 5, 6][pad]]
			tip = attach + Vector3(spread * 0.12, h * 0.08, direction * spread * 0.14)
		_organic_limb(bark, attach, tip, h * (0.045 if pad < 3 else 0.032), rng)
		var scale_value := 1.0 - pad * 0.10
		_leaf_mass(tip + Vector3.UP * h * 0.035, Vector3(spread * 0.28, h * 0.115, spread * 0.22) * scale_value, rng, transforms, tints, roundi(24 + canopy_fullness * 52), spread / crown_width * 1.6)
	_add_mesh("TrunkAndBranches", bark.commit(), wood_material)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = LEAF_GEOMETRY.leaf_spray_mesh()
	batch.instance_count = transforms.size()
	var bounds := AABB()
	for index in range(transforms.size()):
		batch.set_instance_transform(index, transforms[index])
		batch.set_instance_custom_data(index, tints[index])
		var extent := transforms[index] * batch.mesh.get_aabb()
		bounds = extent if index == 0 else bounds.merge(extent)
	batch.custom_aabb = bounds.grow(0.35)
	var leaves := MultiMeshInstance3D.new()
	leaves.name = "Canopy"
	leaves.multimesh = batch
	leaves.material_override = _canopy_material
	_add_generated(leaves)
	_build_container()
	_sync_recall()
	ground_exclusion_changed.emit()

func _build_container() -> void:
	var b := POT_BUILDER.new()
	b.s = SurfaceTool.new()
	b.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	if pedestal_height > 0:
		b.soft_box(Vector3(0, pedestal_height * 0.5, 0), Vector3(0.66, pedestal_height, 0.57), Color("c5c5b4"), 0.04, 1)
		b.soft_box(Vector3(0, pedestal_height - 0.015, 0), Vector3(0.80, 0.08, 0.68), Color("dad7c6"), 0.025, 1)
	b.frame = Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, 0.74)), Vector3.UP * pedestal_height)
	TURNED.lathe(b, [Vector2(0.29, 0.035), Vector2(0.31, 0.07), Vector2(0.42, 0.18), Vector2(0.435, 0.22), Vector2(0.39, 0.24), Vector2(0.36, 0.205)], pot_color, 1, 32)
	b.disc(Vector3(0, 0.203, 0), 0.365, 0.018, Color("58614a"), Vector3.UP, 1, 32)
	for x in [-0.23, 0.23]:
		b.soft_box(Vector3(x, 0.025, 0), Vector3(0.13, 0.05, 0.45), pot_color.darkened(0.15), 0.015, 1)
	var material := ShaderMaterial.new()
	material.shader = POT_PAINT
	material.set_shader_parameter("paint_phase", float(tree_seed) * 0.073)
	_add_mesh("CeramicTray", b.s.commit(), material)
	if trunk_collision:
		var body := StaticBody3D.new()
		body.name = "TrayCollision"
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.86, pedestal_height + 0.24, 0.67)
		collider.shape = box
		collider.position.y = box.size.y * 0.5
		body.add_child(collider)
		_add_generated(body)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.25, 1.0)
	shadow.mesh = plane
	var paint := ShaderMaterial.new()
	paint.shader = SHADOW_SHADER
	paint.set_shader_parameter("shadow_color", Color(0.25, 0.29, 0.23, 0.23))
	shadow.material_override = paint
	shadow.position.y = 0.012
	_add_generated(shadow)

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall_effect)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return Vector2(p.x / 0.48, p.z / 0.38).length() < 1.0
