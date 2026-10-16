class_name TreeRecall
extends Node
## One tree's proximity recall: wood first, then bush-style canopy unfurling.
signal finished
const BARK_SHADER = preload("res://components/effects/recall/shaders/tree_bark_recall.gdshader")
const CANOPY_SHADER = preload("res://components/effects/recall/shaders/bush_recall.gdshader")
@export var patch: PainterlyTree
@export var origin: Node3D # Common study API; tree animation is rooted at its own base.
@export_range(0.5, 10.0, 0.1) var duration: float = 4.5
var progress: float = 0.0
var playing: bool = false
var auto_discover: bool = false
var _bark: ShaderMaterial
var _canopy: ShaderMaterial
var _shadow: ShaderMaterial
var _shadow_color := Color(0.19, 0.25, 0.16, 0.27)

func _ready() -> void:
	reset()

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

func bind_materials() -> void:
	var trunk: MeshInstance3D = patch.get_node("TrunkAndBranches")
	_bark = trunk.material_override
	_bark.shader = BARK_SHADER
	var bounds := trunk.mesh.get_aabb()
	_bark.set_shader_parameter("recall_solid_bounds", Vector2(bounds.position.y, bounds.end.y))
	var canopy: MultiMeshInstance3D = patch.get_node("Canopy")
	_canopy = canopy.material_override
	_canopy.shader = CANOPY_SHADER
	_canopy.set_shader_parameter("recall_lift_distance", minf(0.45, patch.tree_height * 0.12) * patch.global_basis.y.length())
	# Include the short rise from the supporting branches in animated culling bounds.
	canopy.custom_aabb = canopy.multimesh.custom_aabb.grow(0.5)
	_shadow = patch.get_node("SoftGroundShadow").mesh.material

func restore_state() -> void:
	_bark.set_shader_parameter("recall_solid_progress", smoothstep(0.0, 0.42, progress))
	# Overlap leaf unfurling with the finishing branches for a continuous handoff.
	_canopy.set_shader_parameter("recall_local_progress", clampf((progress - 0.24) / 0.76, 0.0, 1.0))
	var shadow_color := _shadow_color
	shadow_color.a *= smoothstep(0.0, 0.85, progress)
	_shadow.set_shader_parameter("shadow_color", shadow_color)
	var falling := patch.get_node_or_null("FallingLeaves")
	if falling:
		falling.visible = progress >= 1.0 and patch.falling_leaf_rate > 0.0
	var body := patch.get_node_or_null("TrunkCollision")
	if body:
		for collision in body.get_children():
			# Always queue the latest state: a rebuild may have an older change pending.
			collision.set_deferred("disabled", progress < 0.42)

func _process(delta: float) -> void:
	if auto_discover and not playing and progress == 0.0:
		var width := patch.crown_width * float(patch._variant.width)
		if preload("res://components/effects/recall/component_recall.gd").explorer_near(patch, Vector2.ONE * width):
			play()
	if patch.get_node("Canopy").material_override != _canopy:
		bind_materials()
		restore_state()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
