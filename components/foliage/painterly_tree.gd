@tool
class_name PainterlyTree
extends Node3D
## One seeded tree: merged bark and a canopy made entirely from clustered leaf geometry.
## Internal generated nodes keep memory scenes small and editable.
const CANOPY_SHADER = preload("res://components/foliage/shaders/tree_canopy.gdshader")
const BARK_SHADER = preload("res://components/foliage/shaders/tree_bark.gdshader")
const SHADOW_SHADER = preload("res://shaders/contact_shadow.gdshader")
const DEFAULT_PALETTE = preload("res://components/foliage/palettes/meadow.tres")
const SUN_DIRECTION = Vector3(-0.45, 0.82, -0.35)

@export var palette: GrassPalette = DEFAULT_PALETTE:
	set(value):
		if palette and palette.changed.is_connected(_request_rebuild):
			palette.changed.disconnect(_request_rebuild)
		palette = value
		if palette:
			palette.changed.connect(_request_rebuild)
		_request_rebuild()
@export var tree_seed: int = 84:
	set(value):
		tree_seed = value
		_request_rebuild()
@export_range(1.5, 8.0, 0.1) var tree_height: float = 3.8:
	set(value):
		tree_height = clampf(value, 1.5, 8.0)
		_request_rebuild()
@export_range(1.0, 7.0, 0.1) var crown_width: float = 3.6:
	set(value):
		crown_width = clampf(value, 1.0, 7.0)
		_request_rebuild()
@export_range(0.08, 0.45, 0.01) var trunk_radius: float = 0.14:
	set(value):
		trunk_radius = clampf(value, 0.08, 0.45)
		_request_rebuild()
@export_range(0.0, 0.16, 0.005) var trunk_bend: float = 0.075:
	set(value):
		trunk_bend = clampf(value, 0.0, 0.16)
		_request_rebuild()
@export_range(4, 10, 1) var branch_count: int = 6:
	set(value):
		branch_count = clampi(value, 4, 10)
		_request_rebuild()
## Density of the leaf masses themselves, rather than surface decoration.
@export_range(0, 240, 1) var leaf_sprays_per_cluster: int = 120:
	set(value):
		leaf_sprays_per_cluster = clampi(value, 0, 240)
		_request_rebuild()
@export var bark_shadow := Color("55463b"):
	set(value):
		bark_shadow = value
		_request_rebuild()
@export var bark_light := Color("ae9470"):
	set(value):
		bark_light = value
		_request_rebuild()
@export_range(0.0, 0.25, 0.005) var wind_strength: float = 0.09:
	set(value):
		wind_strength = value
		_update_wind()
@export_range(0.0, 3.0, 0.05) var wind_speed: float = 0.8:
	set(value):
		wind_speed = value
		_update_wind()
@export var trunk_collision: bool = true:
	set(value):
		trunk_collision = value
		_request_rebuild()
@export_range(15.0, 150.0, 1.0) var visibility_distance: float = 55.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate tree") var regenerate = rebuild

const LEAF_GEOMETRY = preload("res://components/foliage/shared/leaf_geometry.gd")
var _queued: bool = false
var _canopy_material: ShaderMaterial

func _ready() -> void:
	if palette and not palette.changed.is_connected(_request_rebuild):
		palette.changed.connect(_request_rebuild)
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_wind() -> void:
	for material in [_canopy_material]:
		if material:
			material.set_shader_parameter("wind_strength", wind_strength)
			material.set_shader_parameter("wind_speed", wind_speed)

func _material(shader: Shader, colors: GrassPalette) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in [&"root_color", &"shade_color", &"leaf_color", &"sun_color"]:
		if shader == CANOPY_SHADER or key == &"root_color":
			material.set_shader_parameter(key, colors.get(key))
	if shader == CANOPY_SHADER:
		material.set_shader_parameter("tree_height", tree_height)
		material.set_shader_parameter("tree_phase", float(posmod(tree_seed, 1000)) * 0.173)
	return material

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_tree", false):
			remove_child(child)
			child.queue_free()
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
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	# A separate seeded stream bends the trunk without reshuffling the foliage.
	var lean := Vector3(rng.randf_range(-0.14, 0.14), 0, rng.randf_range(-0.14, 0.14))
	var shape_rng := RandomNumberGenerator.new()
	shape_rng.seed = tree_seed ^ 0x51A7
	var bend_angle := shape_rng.randf_range(-PI, PI)
	var bend_direction := Vector3(cos(bend_angle), 0, sin(bend_angle))
	var trunk_points: Array[Vector3] = []
	var trunk_radii: Array[float] = []
	for fraction in [0.0, 0.12, 0.26, 0.42, 0.60, 0.75, 0.88]:
		trunk_points.append(_trunk_center(fraction, lean, bend_direction))
		trunk_radii.append(trunk_radius * (1.75 if fraction == 0.0 else lerpf(1.10, 0.12, fraction / 0.88)))
	# Keep wood color randomness separate too, preserving existing canopy placement.
	_tube(bark, trunk_points, trunk_radii, shape_rng)
	for draw in range(29):
		rng.randf()
	for root in range(5):
		var angle := float(root) * TAU / 5.0 + rng.randf_range(-0.2, 0.2)
		var out := Vector3(cos(angle), 0, sin(angle))
		_tube(bark, [Vector3.UP * 0.28, out * trunk_radius * 1.8 + Vector3.UP * 0.075, out * trunk_radius * rng.randf_range(2.8, 3.8) + Vector3.UP * 0.012], [trunk_radius * 0.55, trunk_radius * 0.30, 0.006], rng)
	# Staggered branch-tip leaf masses preserve gaps and a readable fork silhouette.
	for branch in range(branch_count):
		var angle := float(branch) * 2.39996 + rng.randf_range(-0.22, 0.22)
		var out := Vector3(cos(angle), 0, sin(angle))
		var center := out * crown_width * rng.randf_range(0.25, 0.37)
		center.y = tree_height * (0.67 + float(branch % 3) * 0.085 + rng.randf_range(-0.025, 0.025))
		# Lift the near-side masses so an elevated view retains visible forks.
		center.y += tree_height * maxf(0.0, out.x + out.z) * 0.055
		var start_fraction := rng.randf_range(0.32, 0.53)
		var start := _trunk_center(start_fraction, lean, bend_direction)
		var elbow := start.lerp(center, 0.52) - Vector3.UP * tree_height * 0.08
		_tube(bark, [start, elbow, center], [trunk_radius * 0.53, trunk_radius * 0.31, 0.018], rng)
		var radii := Vector3(crown_width * rng.randf_range(0.17, 0.22), tree_height * rng.randf_range(0.10, 0.14), crown_width * rng.randf_range(0.17, 0.23))
		# Two finer forks connect into each leaf mass and remain visible through gaps.
		for fork in range(2):
			var tip := center + Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0.03, 0.25), rng.randf_range(-0.35, 0.35))
			_tube(bark, [elbow, elbow.lerp(tip, 0.65), tip], [trunk_radius * 0.22, trunk_radius * 0.10, 0.006], rng)
		_leaf_mass(center, radii, rng, transforms, tints)
	_leaf_mass(Vector3(-0.1, tree_height * 0.89, -0.05), Vector3(crown_width * 0.23, tree_height * 0.12, crown_width * 0.23), rng, transforms, tints)
	_add_mesh("TrunkAndBranches", bark.commit(), wood_material)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = _leaf_spray_mesh()
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_custom_data(index, tints[index])
	var bounds := AABB(Vector3(-crown_width * 0.85, 0.0, -crown_width * 0.85), Vector3(crown_width * 1.7, tree_height * 1.25, crown_width * 1.7))
	multimesh.custom_aabb = bounds
	var leaves := MultiMeshInstance3D.new()
	leaves.name = "Canopy"
	leaves.multimesh = multimesh
	leaves.material_override = _canopy_material
	_add_generated(leaves)
	_add_shadow()
	if trunk_collision:
		var body := StaticBody3D.new()
		body.name = "TrunkCollision"
		# Short aligned capsules follow the bent lower stem.
		for segment in range(4):
			var collision := CollisionShape3D.new()
			var capsule := CapsuleShape3D.new()
			var delta := trunk_points[segment + 1] - trunk_points[segment]
			capsule.radius = maxf(trunk_radius * 1.15, trunk_radii[segment] * 0.85)
			capsule.height = delta.length() + capsule.radius * 2.0
			collision.shape = capsule
			collision.position = (trunk_points[segment] + trunk_points[segment + 1]) * 0.5
			collision.quaternion = Quaternion(Vector3.UP, delta.normalized())
			body.add_child(collision)
		_add_generated(body)

func _trunk_center(fraction: float, lean: Vector3, bend_direction: Vector3) -> Vector3:
	var sideways := Vector3(-bend_direction.z, 0, bend_direction.x)
	var curve := bend_direction * sin(fraction * PI) + sideways * sin(fraction * TAU) * 0.30
	return Vector3.UP * fraction * tree_height + curve * trunk_bend * tree_height + lean * fraction * fraction * 1.8

func _add_generated(node: Node) -> void:
	node.set_meta(&"generated_tree", true)
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _add_mesh(mesh_name: String, mesh: ArrayMesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	# Include shader sway in frustum culling.
	instance.custom_aabb = mesh.get_aabb().grow(0.25)
	_add_generated(instance)

func _add_shadow() -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "SoftGroundShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(crown_width * 1.35, crown_width * 1.15)
	var material := ShaderMaterial.new()
	material.shader = SHADOW_SHADER
	material.set_shader_parameter("shadow_color", Color(0.19, 0.25, 0.16, 0.27))
	plane.material = material
	shadow.mesh = plane
	shadow.position = Vector3(0.15, 0.016, 0.15)
	_add_generated(shadow)

func _tube(surface: SurfaceTool, points: Array[Vector3], radii: Array, rng: RandomNumberGenerator) -> void:
	var rings: Array[PackedVector3Array] = []
	var twist := rng.randf() * TAU
	for index in range(points.size()):
		var direction: Vector3 = points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		direction = direction.normalized()
		var side := direction.cross(Vector3.FORWARD).normalized()
		if side.length_squared() < 0.1:
			side = direction.cross(Vector3.RIGHT).normalized()
		var up := direction.cross(side).normalized()
		var ring := PackedVector3Array()
		for segment in range(7):
			var angle := float(segment) * TAU / 7.0 + twist
			ring.append(points[index] + (side * cos(angle) + up * sin(angle)) * float(radii[index]))
		rings.append(ring)
	for index in range(rings.size() - 1):
		for segment in range(7):
			var next := (segment + 1) % 7
			var tint := rng.randf_range(0.0, 0.12)
			_bark_face(surface, rings[index][segment], rings[index + 1][segment], rings[index + 1][next], tint)
			_bark_face(surface, rings[index][segment], rings[index + 1][next], rings[index][next], tint)

func _leaf_mass(center: Vector3, radii: Vector3, rng: RandomNumberGenerator, transforms: Array[Transform3D], tints: Array[Color]) -> void:
	# Brush clumps grow around branch tips. Leaves occupy volume, not a shell.
	# Neighboring leaves share lighting/color, creating connected painted masses.
	var clumps := 10
	for clump in range(clumps):
		var azimuth := float(clump) * 2.39996 + rng.randf_range(-0.25, 0.25)
		var elevation := rng.randf_range(-0.70, 0.95)
		var radial := sqrt(1.0 - elevation * elevation)
		var outward := Vector3(radial * cos(azimuth), elevation, radial * sin(azimuth))
		var clump_center := center + outward * radii * rng.randf_range(0.40, 0.73)
		var clump_tint := outward.dot(SUN_DIRECTION) * 0.22 + 0.46 + (clump_center.y / tree_height - 0.65) * 0.65
		var count := (leaf_sprays_per_cluster) / clumps
		if clump < (leaf_sprays_per_cluster) % clumps:
			count += 1
		for leaf in range(count):
			var y := rng.randf_range(-1.0, 1.0)
			var angle := rng.randf() * TAU
			var r := sqrt(1.0 - y * y)
			var direction := Vector3(r * cos(angle), y, r * sin(angle))
			var point := clump_center + direction * radii * pow(rng.randf(), 0.33333) * 0.36
			# Tilt the sculpted leaf spray into the clump's growth direction.
			var normal := (Vector3.UP * 0.8 + outward * 0.5 + direction * 0.3).normalized()
			var side := normal.cross(Vector3.FORWARD).normalized()
			if side.length_squared() < 0.1:
				side = normal.cross(Vector3.RIGHT).normalized()
			var forward := side.cross(normal).normalized()
			var basis := Basis(side, normal, forward) * Basis(Vector3.UP, rng.randf() * TAU)
			var size := rng.randf_range(0.15, 0.26) * crown_width / 3.6
			basis = basis.scaled(Vector3(size, size, size))
			transforms.append(Transform3D(basis, point))
			tints.append(Color(clampf(clump_tint + rng.randf_range(-0.045, 0.045), 0.03, 0.97), rng.randf(), rng.randf(), point.y / tree_height))

func _bark_face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, brush: float) -> void:
	var normal := (c - a).cross(b - a).normalized()
	var light := normal.dot(SUN_DIRECTION) * 0.38 + 0.48 + brush
	var color := Color(clampf(light, 0.02, 1.0), clampf(0.5 + brush * 3.0, 0.0, 1.0), 1, 1)
	for point in [a, b, c]:
		surface.set_normal(normal)
		surface.set_color(color)
		surface.add_vertex(point)

func _leaf_spray_mesh() -> ArrayMesh:
	return LEAF_GEOMETRY.leaf_spray_mesh()
