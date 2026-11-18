extends Area3D
## A passing explorer lifts a handful of loose leaves from the gate.

const LEAVES = preload("res://components/foliage/shared/leaf_geometry.gd")
const PAINT = preload("res://scenes/memories/first_meeting/gate_leaves.gdshader")
const LEAF_COUNT := 13
const DURATION := 1.5

var _batch: MultiMeshInstance3D
var _paint: ShaderMaterial
var _elapsed := 0.0

func _ready() -> void:
	var leaves := MultiMesh.new()
	leaves.transform_format = MultiMesh.TRANSFORM_3D
	leaves.use_custom_data = true
	leaves.mesh = LEAVES.falling_leaf_mesh()
	leaves.instance_count = LEAF_COUNT
	var random := RandomNumberGenerator.new()
	random.seed = 531
	for index in LEAF_COUNT:
		leaves.set_instance_transform(index, Transform3D.IDENTITY)
		leaves.set_instance_custom_data(index, Color(random.randf(), random.randf(), random.randf(), random.randf()))
	leaves.custom_aabb = AABB(Vector3(-1.8, -0.2, -1.8), Vector3(3.6, 1.25, 3.6))
	_paint = ShaderMaterial.new()
	_paint.shader = PAINT
	_batch = MultiMeshInstance3D.new()
	_batch.name = "LiftedLeaves"
	_batch.multimesh = leaves
	_batch.material_override = _paint
	_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The area is waist high so it detects a crossing. Leaves start at ground level.
	_batch.position.y = -0.42
	_batch.hide()
	add_child(_batch, false, Node.INTERNAL_MODE_BACK)
	set_process(false)
	body_entered.connect(_on_explorer_entered)

func _on_explorer_entered(body: Node3D) -> void:
	if not body is MemoryExplorer or not body.is_in_group(&"explorers") or is_processing():
		return
	var explorer := body as MemoryExplorer
	var motion := global_basis.inverse() * explorer.get_real_velocity()
	var heading := Vector2(motion.x, motion.z)
	if heading.length() < 0.4:
		return
	_paint.set_shader_parameter("breeze", heading.normalized())
	_paint.set_shader_parameter("elapsed", 0.0)
	_elapsed = 0.0
	_batch.show()
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	_paint.set_shader_parameter("elapsed", _elapsed / DURATION)
	if _elapsed >= DURATION:
		_batch.hide()
		set_process(false)
