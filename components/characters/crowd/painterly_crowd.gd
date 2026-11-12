@tool
class_name PainterlyCrowd
extends Node3D
## Decorative standing crowds. Origin is ground level; placement uses local X/Z.
## People are shared opaque meshes with GPU idle motion, not individual actors.
const GEOMETRY = preload("res://components/characters/crowd/crowd_geometry.gd")
const PAINT = preload("res://components/characters/crowd/crowd.gdshader")
const CONTACT = preload("res://shaders/contact_shadow.gdshader")
## Indices match crowd_poses.gdshaderinc; poses are independent of clothing and hair.
const POSE_NAMES := ["Relaxed", "Folded arms", "Left hand on hip", "Right hand on hip", "Hands in pockets", "Hands clasped", "Hands behind back", "Hand to chin", "Hand over chest", "Conversational gesture", "Hand behind head", "Small greeting"]
const POSE_MIXES := [
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	[0, 1, 2, 3, 4, 5, 6, 7],
	[0, 2, 3, 5, 7, 8, 9, 10, 11]
]
const PALETTES := [
	[Color("729179"), Color("ab8265"), Color("7094aa"), Color("b4a072")],
	[Color("6b9662"), Color("cf9274"), Color("679fae"), Color("c5a45e")],
	[Color("b47b48"), Color("ae5f53"), Color("7a8c50"), Color("c8a065")],
	[Color("7798ad"), Color("9586a9"), Color("96aca2"), Color("b18580")]
]

@export_group("People")
@export_range(0, 1000, 1) var count: int = 20:
	set(value):
		count = clampi(value, 0, 1000)
		_request_rebuild()
@export var crowd_seed: int = 42:
	set(value):
		crowd_seed = value
		_request_rebuild()
## Mesh height is approximately 1.24 m before this scale and per-person variation.
@export_range(0.3, 2.0, 0.025) var person_scale: float = 0.95:
	set(value):
		person_scale = clampf(value, 0.3, 2.0)
		_request_rebuild()
@export_range(0.0, 0.35, 0.01) var height_variation: float = 0.12:
	set(value):
		height_variation = clampf(value, 0, 0.35)
		_request_rebuild()
@export_range(0.0, 0.35, 0.01) var build_variation: float = 0.16:
	set(value):
		build_variation = clampf(value, 0, 0.35)
		_request_rebuild()
## Independent leg length, shoulder/waist shape, head scale, and relaxed posture.
@export_range(0.0, 1.0, 0.05) var silhouette_variation: float = 0.8:
	set(value):
		silhouette_variation = clampf(value, 0, 1)
		_apply_paint()

@export_group("Standing Layout")
@export_enum("Loose Gathering", "Standing Rows") var layout: int = 0:
	set(value):
		layout = clampi(value, 0, 1)
		_request_rebuild()
@export var footprint := Vector2(4.5, 3.5):
	set(value):
		footprint = value.clamp(Vector2(0.4, 0.4), Vector2(100, 100))
		_request_rebuild()
## Minimum center spacing. Count is capped by the available space, never overlapped to fit.
@export_range(0.25, 3.0, 0.025) var spacing: float = 0.55:
	set(value):
		spacing = clampf(value, 0.25, 3.0)
		_request_rebuild()
## Zero faces local +Z, as do the explorer models. Rotate the component to orient a group.
@export_range(-180.0, 180.0, 1.0) var facing_degrees: float = 0.0:
	set(value):
		facing_degrees = value
		_request_rebuild()
@export_range(0.0, 90.0, 1.0) var facing_variation: float = 18.0:
	set(value):
		facing_variation = clampf(value, 0, 90)
		_request_rebuild()
## Local X/Z rectangles left empty for paths, approaches, or the explorers.
@export var empty_areas: Array[Rect2] = []:
	set(value):
		empty_areas = value
		_request_rebuild()

@export_group("Painterly Colors")
@export_enum("Quiet Neutrals", "Summer Gathering", "Autumn Gathering", "Winter Gathering", "Custom") var palette: int = 0:
	set(value):
		palette = clampi(value, 0, 4)
		_apply_paint()
## Used by the Custom palette. Missing entries fall back to Quiet Neutrals.
@export var clothing_colors := PackedColorArray([Color("729179"), Color("ab8265"), Color("7094aa"), Color("b4a072")]):
	set(value):
		clothing_colors = value
		_apply_paint()
@export var skin_colors := PackedColorArray([Color("d4ae8c"), Color("ad7d5c"), Color("785445"), Color("e3c4a6")]):
	set(value):
		skin_colors = value
		_apply_paint()
@export var hair_colors := PackedColorArray([Color("48423b"), Color("765c45"), Color("ab976e"), Color("929085")]):
	set(value):
		hair_colors = value
		_apply_paint()
## Mixes in the memory's cream atmosphere to keep explorers visually prominent.
@export_range(0.0, 0.65, 0.01) var softness: float = 0.06:
	set(value):
		softness = clampf(value, 0, 0.65)
		_apply_paint()
@export var atmosphere_color := Color(0.94, 0.935, 0.89):
	set(value):
		atmosphere_color = value
		_apply_paint()

@export_group("Poses and Subtle Animation")
@export_enum("Everyday Mix", "Quiet", "Social") var pose_mix: int = 0:
	set(value):
		pose_mix = clampi(value, 0, 2)
		_request_rebuild()
## Blends the independent arm poses back to a neutral stance at zero.
@export_range(0.0, 1.0, 0.05) var pose_strength: float = 1.0:
	set(value):
		pose_strength = clampf(value, 0, 1)
		_apply_motion()
@export_range(0.0, 1.0, 0.05) var motion_strength: float = 0.45:
	set(value):
		motion_strength = clampf(value, 0, 1)
		_apply_motion()
@export_range(0.0, 2.0, 0.05) var motion_speed: float = 0.75:
	set(value):
		motion_speed = clampf(value, 0, 2)
		_apply_motion()

@export_group("Hitboxes")
## One stationary capsule per person. Visual idle motion does not move obstacles.
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
## Mesh-space radius, scaled to each person's width. Keep narrow for walking gaps.
@export_range(0.06, 0.4, 0.01) var hitbox_radius: float = 0.17:
	set(value):
		hitbox_radius = clampf(value, 0.06, 0.4)
		_request_rebuild()
@export_range(0.5, 2.0, 0.05) var hitbox_height: float = 1.3:
	set(value):
		hitbox_height = clampf(value, 0.5, 2)
		_request_rebuild()
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		_request_rebuild()

@export_group("Rendering")
@export var contact_shadows: bool = true:
	set(value):
		contact_shadows = value
		_request_rebuild()
## Independently culled blocks sharing eight bodies and eight interchangeable heads.
@export_range(2.0, 16.0, 0.5) var chunk_size: float = 6.0:
	set(value):
		chunk_size = clampf(value, 2, 16)
		_request_rebuild()
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 55.0:
	set(value):
		visibility_distance = clampf(value, 10, 150)
		_request_rebuild()
@export_tool_button("Regenerate crowd") var regenerate = rebuild

var generated_count: int = 0
var _queued: bool = false
var _generated: Node3D
var _material: ShaderMaterial
var _placements: Array[Transform3D] = []
var _appearances: Array[Vector2i] = []
var _instance_data: Array[Color] = []
var _pose_indices := PackedInt32Array()
var _hitboxes: Node3D
var _hitbox_shapes: Array[CollisionShape3D] = []
var _batch_count: int = 0
var _triangle_count: int = 0

func _ready() -> void:
	rebuild()
	set_process(false)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _apply_paint() -> void:
	if not _material:
		return
	var clothes: Array = PALETTES[palette] if palette < 4 else Array(clothing_colors)
	var default_skin := [Color("d4ae8c"), Color("ad7d5c"), Color("785445"), Color("e3c4a6")]
	var default_hair := [Color("48423b"), Color("765c45"), Color("ab976e"), Color("929085")]
	for index in range(4):
		var suffix: String = ["a", "b", "c", "d"][index]
		_material.set_shader_parameter("clothing_" + suffix, clothes[index] if index < clothes.size() else PALETTES[0][index])
		_material.set_shader_parameter("skin_" + suffix, skin_colors[index] if index < skin_colors.size() else default_skin[index])
		_material.set_shader_parameter("hair_" + suffix, hair_colors[index] if index < hair_colors.size() else default_hair[index])
	_material.set_shader_parameter("softness", softness)
	_material.set_shader_parameter("atmosphere_color", atmosphere_color)
	_material.set_shader_parameter("silhouette_variation", silhouette_variation)

func _apply_motion() -> void:
	if _material:
		_material.set_shader_parameter("motion_strength", motion_strength)
		_material.set_shader_parameter("motion_speed", motion_speed)
		_material.set_shader_parameter("pose_strength", pose_strength)

func _standing_points(rng: RandomNumberGenerator) -> PackedVector2Array:
	var result := PackedVector2Array()
	var margin := 0.25 * person_scale * (1.0 + build_variation)
	var available := (footprint - Vector2.ONE * margin * 2.0).max(Vector2.ZERO)
	if layout == 0:
		return _scatter_points(rng, available, margin)
	var step := spacing
	var columns := maxi(1, floori(available.x / step) + 1)
	var rows := maxi(1, floori(available.y / step) + 1)
	for row in range(rows):
		for column in range(columns):
			var point := Vector2(float(column) - float(columns - 1) * 0.5, float(row) - float(rows - 1) * 0.5) * step
			point = point.clamp(-available * 0.5, available * 0.5)
			var excluded := false
			for area in empty_areas:
				# Expand by body radius so shoulders cannot project into an authored aisle.
				if area.abs().grow(margin).has_point(point):
					excluded = true
					break
			if not excluded:
				result.append(point)
	# Local RNG only; changing a crowd never perturbs another component's seed.
	for index in range(result.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := result[index]
		result[index] = result[other]
		result[other] = swap
	return result

func _scatter_points(rng: RandomNumberGenerator, available: Vector2, margin: float) -> PackedVector2Array:
	# Seeded blue-noise spacing avoids the first pass's jittered-but-visible grid.
	# Neighbor cells keep generation cheap even for large decorative populations.
	var points := PackedVector2Array()
	var cells := {}
	var capacity := maxi(1, floori((available.x + spacing) * (available.y + spacing) / (spacing * spacing * 0.8)))
	var target := mini(count, capacity)
	for attempt in range(target * 64):
		if points.size() >= target:
			break
		var point := Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * available
		var valid := true
		for area in empty_areas:
			if area.abs().grow(margin).has_point(point):
				valid = false
				break
		if not valid:
			continue
		var cell := Vector2i(floori(point.x / spacing), floori(point.y / spacing))
		for row in range(-1, 2):
			for column in range(-1, 2):
				var nearby: Array = cells.get(cell + Vector2i(column, row), [])
				for previous: Vector2 in nearby:
					if point.distance_squared_to(previous) < spacing * spacing:
						valid = false
		if valid:
			points.append(point)
			if not cells.has(cell):
				cells[cell] = []
			cells[cell].append(point)
	return points

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.free()
	_generated = Node3D.new()
	_generated.name = "GeneratedCrowd"
	add_child(_generated, false, Node.INTERNAL_MODE_BACK)
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_apply_paint()
	_apply_motion()
	_placements.clear()
	_appearances.clear()
	_instance_data.clear()
	_pose_indices.clear()
	_batch_count = 0
	_triangle_count = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = crowd_seed
	var points := _standing_points(rng)
	generated_count = mini(count, points.size())
	var bodies: Dictionary = {}
	var heads: Dictionary = {}
	var shadows: Dictionary = {}
	var body_bag: Array[int] = []
	var head_bag: Array[int] = []
	var clothing_bag: Array[int] = []
	var pose_bag: Array[int] = []
	for index in range(generated_count):
		var point := points[index]
		var height := person_scale * rng.randf_range(1.0 - height_variation, 1.0 + height_variation)
		var width := person_scale * rng.randf_range(1.0 - build_variation, 1.0 + build_variation)
		var basis := Basis(Vector3.UP, deg_to_rad(facing_degrees + rng.randf_range(-facing_variation, facing_variation))).scaled(Vector3(width, height, width))
		var pose := Transform3D(basis, Vector3(point.x, 0, point.y))
		_placements.append(pose)
		# Independently shuffled bags use the complete vocabulary before repeating.
		# Heads are not permanently married to an outfit or a resting pose.
		var body := _draw_choice(body_bag, GEOMETRY.BODY_COUNT, rng)
		var head := _draw_choice(head_bag, GEOMETRY.HEAD_COUNT, rng)
		var shirt := _draw_choice(clothing_bag, 4, rng)
		var pose_options: Array = POSE_MIXES[pose_mix]
		var stance: int = pose_options[_draw_choice(pose_bag, pose_options.size(), rng)]
		_pose_indices.append(stance)
		# Avoid exact head/outfit twins standing directly beside one another.
		for attempt in range(GEOMETRY.HEAD_COUNT):
			var repeated := false
			for previous in range(_appearances.size()):
				if _appearances[previous] == Vector2i(body, head) and _placements[previous].origin.distance_squared_to(pose.origin) < spacing * spacing * 4.0:
					repeated = true
					break
			if not repeated:
				break
			head = (head + 1) % GEOMETRY.HEAD_COUNT
		_appearances.append(Vector2i(body, head))
		var cell := Vector2i(floori((point.x + footprint.x * 0.5) / chunk_size), floori((point.y + footprint.y * 0.5) / chunk_size))
		var body_key := Vector3i(cell.x, cell.y, body)
		var head_key := Vector3i(cell.x, cell.y, head)
		# Pose id and an independent fractional identity seed share INSTANCE_CUSTOM.a.
		var identity := (float(stance) + rng.randf_range(0.08, 0.92)) / float(POSE_NAMES.size())
		var custom := Color((float(shirt) + rng.randf_range(0.08, 0.92)) / 4.0, rng.randf(), rng.randf(), identity)
		_instance_data.append(custom)
		if not bodies.has(body_key):
			bodies[body_key] = []
		if not heads.has(head_key):
			heads[head_key] = []
		bodies[body_key].append([pose, custom])
		heads[head_key].append([pose, custom])
		if contact_shadows:
			if not shadows.has(cell):
				shadows[cell] = []
			shadows[cell].append([Transform3D(Basis.IDENTITY.scaled(Vector3(width, 1, width)), Vector3(point.x, 0.014, point.y)), Color.WHITE])
	for key: Vector3i in bodies:
		var mesh: ArrayMesh = GEOMETRY.get_body(key.z)
		_add_batch("Bodies_%s_%s_%s" % [key.x, key.y, key.z], mesh, _material, bodies[key])
		_triangle_count += mesh.surface_get_array_index_len(0) / 3 * bodies[key].size()
	for key: Vector3i in heads:
		var mesh: ArrayMesh = GEOMETRY.get_head(key.z)
		_add_batch("Heads_%s_%s_%s" % [key.x, key.y, key.z], mesh, _material, heads[key])
		_triangle_count += mesh.surface_get_array_index_len(0) / 3 * heads[key].size()
	if contact_shadows and not shadows.is_empty():
		var contact_material := ShaderMaterial.new()
		contact_material.shader = CONTACT
		contact_material.set_shader_parameter("shadow_color", Color(0.39, 0.39, 0.33, 0.18))
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.73, 0.56)
		for cell: Vector2i in shadows:
			_add_batch("Contact_%s_%s" % [cell.x, cell.y], plane, contact_material, shadows[cell])
	_rebuild_hitboxes()
	update_configuration_warnings()

func _rebuild_hitboxes() -> void:
	if is_instance_valid(_hitboxes):
		remove_child(_hitboxes)
		_hitboxes.free()
	_hitboxes = null
	_hitbox_shapes.clear()
	if not collision_enabled or generated_count == 0:
		return
	_hitboxes = Node3D.new()
	_hitboxes.name = "Hitboxes"
	add_child(_hitboxes, false, Node.INTERNAL_MODE_BACK)
	var chunks := {}
	for index in range(generated_count):
		var pose := _placements[index]
		var cell := Vector2i(floori((pose.origin.x + footprint.x * 0.5) / chunk_size), floori((pose.origin.z + footprint.y * 0.5) / chunk_size))
		if not chunks.has(cell):
			var body := StaticBody3D.new()
			body.name = "People_%s_%s" % [cell.x, cell.y]
			body.collision_layer = collision_layer
			body.collision_mask = 0
			_hitboxes.add_child(body)
			chunks[cell] = body
		var size := pose.basis.get_scale()
		var capsule := CapsuleShape3D.new()
		capsule.radius = hitbox_radius * maxf(size.x, size.z)
		capsule.height = maxf(hitbox_height * size.y, capsule.radius * 2.0)
		var collider := CollisionShape3D.new()
		collider.name = "Person_%03d" % index
		collider.shape = capsule
		collider.position = pose.origin + Vector3.UP * capsule.height * 0.5
		collider.set_meta(&"crowd_person_index", index)
		var body: StaticBody3D = chunks[cell]
		body.add_child(collider)
		_hitbox_shapes.append(collider)

## Resolve a physics ray/motion hit to a person, even though bodies are chunked.
func person_index_from_hit(collider: CollisionObject3D, shape_index: int) -> int:
	if not is_instance_valid(_hitboxes) or not is_instance_valid(collider) or not _hitboxes.is_ancestor_of(collider):
		return -1
	if shape_index < 0:
		return -1
	var owner_id := collider.shape_find_owner(shape_index)
	var shape_owner: Object = collider.shape_owner_get_owner(owner_id)
	return int(shape_owner.get_meta(&"crowd_person_index", -1)) if is_instance_valid(shape_owner) else -1

func _draw_choice(bag: Array[int], options: int, rng: RandomNumberGenerator) -> int:
	if bag.is_empty():
		for choice in range(options):
			bag.append(choice)
		for index in range(bag.size() - 1, 0, -1):
			var other := rng.randi_range(0, index)
			var swap := bag[index]
			bag[index] = bag[other]
			bag[other] = swap
	return bag.pop_back()

func _add_batch(batch_name: String, mesh: Mesh, material: Material, instances: Array) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = instances.size()
	var bounds: AABB = instances[0][0] * mesh.get_aabb()
	for index in range(instances.size()):
		multimesh.set_instance_transform(index, instances[index][0])
		multimesh.set_instance_custom_data(index, instances[index][1])
		bounds = bounds.merge(instances[index][0] * mesh.get_aabb())
	var batch := MultiMeshInstance3D.new()
	batch.name = batch_name
	batch.multimesh = multimesh
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.visibility_range_end = visibility_distance
	# Includes static proportion/posture deformation as well as the small idle motion.
	batch.custom_aabb = bounds.grow(0.26 * person_scale * (1.0 + maxf(height_variation, build_variation)))
	_generated.add_child(batch)
	_batch_count += 1

func get_statistics() -> Dictionary:
	var combinations := {}
	var poses := {}
	for index in range(_appearances.size()):
		var identity := _appearances[index]
		combinations[Vector3i(identity.x, identity.y, _pose_indices[index])] = true
		poses[_pose_indices[index]] = true
	return {"people": generated_count, "batches": _batch_count, "body_triangles": _triangle_count, "distinct_combinations": combinations.size(), "poses": poses.size(), "hitboxes": _hitbox_shapes.size()}

func _get_configuration_warnings() -> PackedStringArray:
	if is_inside_tree() and generated_count < count:
		return PackedStringArray(["Only %d of %d people fit. Enlarge Footprint, reduce Spacing, or remove empty areas." % [generated_count, count]])
	return PackedStringArray()
