extends Node3D
## Ring the lantern to send a spiral of warm lights up a nearby evergreen.
const BUILDER = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/scenery/stadium/stadium_paint.gdshader")
const BULBS := 76
const FLOURISH := 24
const DURATION := 4.8

@export var tree: Node3D
@export var tree_height := 4.1
@export var tree_radius := 1.5
@export var interaction_range := 2.5
@onready var _lantern: MeshInstance3D = $Lantern
@onready var _lights: MultiMeshInstance3D = $Lights
var _clock := -1.0

func _ready() -> void:
	var builder := BUILDER.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color("735346")
	var brass := Color("c19650")
	builder.soft_box(Vector3(0, 0.27, 0), Vector3(0.27, 0.54, 0.27), wood, 0.035)
	builder.soft_box(Vector3(0, 0.62, 0), Vector3(0.46, 0.16, 0.43), brass, 0.05)
	builder.soft_box(Vector3(0, 0.84, 0), Vector3(0.32, 0.35, 0.30), Color("ffcc78"), 0.065, 3.0)
	builder.soft_box(Vector3(0, 1.04, 0), Vector3(0.44, 0.12, 0.40), wood, 0.045)
	for x in [-0.17, 0.17]:
		for z in [-0.15, 0.15]:
			builder.rod(Vector3(x, 0.67, z), Vector3(x, 1.03, z), 0.018, brass, 6)
	_lantern.mesh = builder.s.commit()
	var material := ShaderMaterial.new()
	material.shader = PAINT
	_lantern.material_override = material
	var bead := SphereMesh.new()
	bead.radial_segments = 6
	bead.rings = 3
	var bulb_paint := StandardMaterial3D.new()
	bulb_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bulb_paint.vertex_color_use_as_albedo = true
	bead.material = bulb_paint
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = bead
	batch.instance_count = BULBS + FLOURISH
	batch.visible_instance_count = 0
	if is_instance_valid(tree):
		batch.custom_aabb = AABB(to_local(tree.global_position) - Vector3(3, 1, 3), Vector3(6, tree_height + 4, 6))
	_lights.multimesh = batch
	add_to_group(&"memory_interactables")
	set_process(false)

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_lantern]

func can_interact(actor: Node3D) -> bool:
	return is_instance_valid(actor) and is_instance_valid(tree) and _clock < 0.0 \
		and global_position.distance_squared_to(actor.global_position) <= interaction_range ** 2

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	return play_shared_interaction(0)

func play_shared_interaction(_seed_value: int) -> bool:
	if not is_instance_valid(tree) or _clock >= 0.0:
		return false
	_clock = 0.0
	$Chime.play()
	set_process(true)
	return true

func _process(delta: float) -> void:
	_clock += delta
	var batch := _lights.multimesh
	if _clock >= DURATION:
		batch.visible_instance_count = 0
		_clock = -1.0
		set_process(false)
		return
	var origin := to_local(tree.global_position)
	var count := 0
	for index in BULBS:
		var t := float(index) / (BULBS - 1)
		var age := _clock - t * 2.30
		if age <= 0.0:
			break
		var angle := t * TAU * 3.15 + 0.5
		var radius := lerpf(tree_radius, 0.12, t)
		var point := origin + Vector3(cos(angle) * radius, 0.46 + t * (tree_height - 0.20), sin(angle) * radius)
		var pulse := exp(-age * 2.8)
		var fade := 1.0 - smoothstep(3.20 + t * 0.6, DURATION, _clock)
		var size := (0.105 + pulse * 0.14) * fade
		_put(batch, count, point, Vector3(size, size * 1.25, size),
			Color("ffedb0") if index % 3 else Color("e9a435"))
		count += 1
	var burst_age := _clock - 2.30
	if burst_age > 0.0 and burst_age < 1.25:
		for index in FLOURISH:
			var angle := float(index) * TAU / FLOURISH
			var distance := burst_age * (0.8 + (index % 4) * 0.23)
			var point := origin + Vector3(cos(angle) * distance,
				tree_height + 0.22 + sin(angle * 3.0) * distance - burst_age * burst_age * 0.64,
				sin(angle) * distance)
			var size := 0.16 * (1.0 - burst_age / 1.25)
			_put(batch, count, point, Vector3(size, size * 1.8, size), Color("ffd16c"))
			count += 1
	batch.visible_instance_count = count

func _put(batch: MultiMesh, index: int, point: Vector3, size: Vector3, color: Color) -> void:
	batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(size), point))
	batch.set_instance_color(index, color.srgb_to_linear())
