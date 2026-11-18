extends Node3D
## Local, replayable celebration. All sparks share one moving instance batch.
const SPARKS_PER_BURST := 72
const COLORS := [Color("b82855"), Color("d98527"), Color("f9ce64")]
const DELAYS := [0.0, 0.36, 0.72]
const ASCENT := 0.8
const LIFETIME := 2.1

@export var burst_centers := PackedVector3Array([
	Vector3(-15, 7, -34), Vector3(0, 11, -37), Vector3(15, 7, -32)])
@export_range(1.0, 6.0, 0.1) var interaction_distance := 3.8
@onready var _button: MeshInstance3D = $Button
@onready var _base: MeshInstance3D = $Console
@onready var _sparks: MultiMeshInstance3D = $Sparks
var _elapsed := -1.0
var _velocities := PackedVector3Array()
var _batch: MultiMesh

func _ready() -> void:
	# The shared tap picker reads triangle topology from ArrayMesh.
	for visual in [_base, _button]:
		var source: Mesh = visual.mesh
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, source.surface_get_arrays(0))
		mesh.surface_set_material(0, source.surface_get_material(0))
		visual.mesh = mesh
	add_to_group(&"memory_interactables")
	set_process(false)
	var spark := SphereMesh.new()
	spark.radius = 0.5
	spark.height = 1.0
	spark.radial_segments = 6
	spark.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	spark.material = material
	_batch = MultiMesh.new()
	_batch.transform_format = MultiMesh.TRANSFORM_3D
	_batch.use_colors = true
	_batch.mesh = spark
	_batch.instance_count = burst_centers.size() * SPARKS_PER_BURST
	_batch.visible_instance_count = 0
	var bounds := AABB(Vector3.ZERO, Vector3.ZERO)
	for center in burst_centers:
		bounds = bounds.expand(center)
	_batch.custom_aabb = bounds.grow(16.0)
	_sparks.multimesh = _batch

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_base, _button]

func can_interact(actor: Node3D) -> bool:
	return _elapsed < 0.0 and not burst_centers.is_empty() and is_instance_valid(actor) \
		and global_position.distance_squared_to(actor.global_position) <= interaction_distance ** 2

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	_velocities.clear()
	var random := RandomNumberGenerator.new()
	random.randomize()
	for index in _batch.instance_count:
		var y := random.randf_range(-1.0, 1.0)
		var angle := random.randf_range(0.0, TAU)
		var radius := sqrt(1.0 - y * y)
		_velocities.append(Vector3(cos(angle) * radius, y, sin(angle) * radius)
			* random.randf_range(6.0, 15.5))
	_elapsed = 0.0
	_button.position.y = 0.93
	set_process(true)
	return true

func _process(delta: float) -> void:
	_elapsed += delta
	var drawn := 0
	var active := false
	for burst in burst_centers.size():
		var time: float = _elapsed - DELAYS[burst % DELAYS.size()] - 0.63 * floorf(float(burst) / 3.0)
		if time >= ASCENT + LIFETIME:
			continue
		active = true
		if time < 0.0:
			continue
		var center := burst_centers[burst]
		if time < ASCENT:
			for tail in 9:
				var progress := clampf((time - tail * 0.038) / ASCENT, 0.0, 1.0)
				var point := Vector3(0, 1.25, 0).lerp(center, progress)
				point.y += sin(progress * PI) * 2.1
				_draw(drawn, point, center, 0.48 - tail * 0.037, COLORS[2])
				drawn += 1
			continue
		var age := time - ASCENT
		for spark in SPARKS_PER_BURST:
			var velocity := _velocities[burst * SPARKS_PER_BURST + spark]
			var point := center + velocity * (1.0 - exp(-1.5 * age)) / 1.5
			point.y -= 1.8 * age * age
			var fade := 1.0 - smoothstep(0.48, LIFETIME, age)
			var width := (0.38 if spark % 4 else 0.58) * fade
			var color: Color = COLORS[burst % COLORS.size()]
			if spark % 4 == 0 or age < 0.12:
				color = COLORS[2]
			_draw(drawn, point, velocity * exp(-1.5 * age) + Vector3.DOWN * (3.6 * age),
				width, color)
			drawn += 1
	_batch.visible_instance_count = drawn
	if not active:
		_elapsed = -1.0
		_button.position.y = 1.02
		set_process(false)

func _draw(index: int, point: Vector3, direction: Vector3, width: float, color: Color) -> void:
	var axis := direction.normalized()
	var up := Vector3.RIGHT if absf(axis.y) > 0.96 else Vector3.UP
	var orientation := Basis.looking_at(axis, up)
	_batch.set_instance_transform(index, Transform3D(
		orientation.scaled_local(Vector3(width, width, width * 2.6)), point))
	_batch.set_instance_color(index, color.srgb_to_linear())
