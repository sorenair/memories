@tool
class_name PainterlyPinball
extends PainterlyArcadeComponent
## Shared-controller target with a standalone authoring/preview hook.
signal interaction_requested
signal interaction_started
signal interaction_cancelled
signal score_awarded(score: int)
const LAYOUT = preload("res://components/activities/arcade/pinball/pinball_layout.gd")
const SIMULATION = preload("res://components/activities/arcade/pinball/pinball_simulation.gd")
const SCORE_PAINT = preload("res://components/activities/arcade/shared/arcade_score.gdshader")

@export_group("Pinball Interaction")
## World-space range measured from the floor in front of the play controls.
@export_range(0.5,4.0,0.05) var interaction_range: float = 1.35:
	set(value): interaction_range = clampf(value,0.5,4.0)
@export_range(2.0,8.0,0.1) var play_duration: float = 5.0:
	set(value): play_duration = clampf(value,2.0,8.0)
@export_range(1.8,3.0,0.05) var launch_speed: float = 2.4:
	set(value): launch_speed = clampf(value,1.8,3.0)
@export var score_range := Vector2i(100,9900):
	set(value):
		var limits := value.clamp(Vector2i.ZERO,Vector2i.ONE*999999)
		score_range = Vector2i(mini(limits.x,limits.y),maxi(limits.x,limits.y))
## Explicit authoring preview; it never starts automatically on load.
@export_tool_button("Preview pinball run") var preview_pinball = start_interaction

var last_score: int = 0
var _playing := false
var _pending_score := 0
var _shown_hits := 0
var _random := RandomNumberGenerator.new()
var _simulation: RefCounted = SIMULATION.new()
var _ball: MeshInstance3D
var _score_display: MeshInstance3D
var _score_material: ShaderMaterial

func _kind() -> StringName:
	return &"pinball"

func _ready() -> void:
	_random.randomize()
	if not interaction_requested.is_connected(start_interaction):
		interaction_requested.connect(start_interaction)
	super._ready()
	if not Engine.is_editor_hint():
		add_to_group(&"memory_interactables")

func rebuild() -> void:
	var cancelled := _playing
	_playing = false
	_simulation.running = false
	set_process(false)
	super.rebuild()
	if not is_inside_tree(): return
	# The cabinet remains a single static batch; only this small painted ball moves.
	var builder := GEOMETRY.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.ball(Vector3.ZERO,Vector3.ONE*LAYOUT.BALL_RADIUS*2.0,Color("d8ded6"))
	_ball = MeshInstance3D.new()
	_ball.name = "Ball"
	_ball.mesh = builder.s.commit()
	_ball.material_override = _material
	_ball.scale = Vector3.ONE*prop_scale
	_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ball.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated(_ball)
	_score_display = MeshInstance3D.new()
	_score_display.name = "ScoreDisplay"
	var screen := QuadMesh.new()
	screen.size = LAYOUT.SCORE_SIZE
	_score_display.mesh = screen
	_score_display.position = LAYOUT.SCORE_POSITION*prop_scale
	_score_display.scale = Vector3.ONE*prop_scale
	_score_display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_score_material = ShaderMaterial.new()
	_score_material.shader = SCORE_PAINT
	_score_display.material_override = _score_material
	_generated(_score_display)
	_place_ball(LAYOUT.HOME)
	_set_score(last_score)
	if cancelled: interaction_cancelled.emit()

## Side-effect-free availability contract used by InteractionController.
func can_interact(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not is_inside_tree(): return false
	if _playing or not is_visible_in_tree() or not can_process() or not is_instance_valid(_ball): return false
	if actor.get_viewport()!=get_viewport(): return false
	var play := get_anchor(&"Play")
	if not is_instance_valid(play): return false
	# Use the authored front-of-machine control point, projected to its local floor.
	var approach := to_global(Vector3(play.position.x,0.0,play.position.z))
	return actor.global_position.distance_squared_to(approach)<=interaction_range*interaction_range

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor): return false
	return start_interaction()

## Direct authoring/scripted launch; the shared button uses try_activate(actor).

## Returns false when a run is already active or the component is not ready.
func start_interaction() -> bool:
	if _playing or not is_inside_tree() or not is_instance_valid(_ball): return false
	_pending_score = _random.randi_range(score_range.x,score_range.y)
	_shown_hits = 0
	_simulation.launch(_random.randi(),play_duration,launch_speed)
	_playing = true
	_ball.rotation = Vector3.ZERO
	_place_ball(LAYOUT.HOME)
	_set_score(0)
	set_process(true)
	interaction_started.emit()
	return true

func is_playing() -> bool:
	return _playing

func _process(delta: float) -> void:
	if not _playing: return
	var previous: Vector2 = _simulation.position
	_simulation.advance(delta)
	var point: Vector2 = _simulation.position
	var travel := point-previous
	if travel.length_squared()>0.00000001:
		_ball.rotate(Vector3(travel.y,0,-travel.x).normalized(),travel.length()/LAYOUT.BALL_RADIUS)
	_place_ball(point)
	if _shown_hits!=_simulation.bumper_hits:
		_shown_hits = _simulation.bumper_hits
		_set_score(int(_pending_score*minf(0.9,_shown_hits*0.14)))
	if not _simulation.running:
		_playing = false
		set_process(false)
		last_score = _pending_score
		_set_score(last_score)
		# Completion is one event, after the final score and idle state are ready.
		score_awarded.emit(last_score)

func _place_ball(point: Vector2) -> void:
	_ball.position = LAYOUT.ball_center(point)*prop_scale
	var anchor := get_anchor(&"Ball")
	if anchor: anchor.position = _ball.position

func _set_score(value: int) -> void:
	_score_material.set_shader_parameter("score",clampi(value,0,999999))
