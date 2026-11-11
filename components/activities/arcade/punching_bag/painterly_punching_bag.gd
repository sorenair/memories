@tool
class_name PainterlyPunchingBag
extends PainterlyArcadeComponent
## A bounded, render-frame pendulum and strength counter on the shared interaction API.
signal interaction_requested
signal interaction_started
signal interaction_cancelled
signal score_awarded(score: int)
const SCORE_PAINT = preload("res://components/activities/arcade/shared/arcade_score.gdshader")
const IMPACT_PAINT = preload("res://components/activities/arcade/punching_bag/punch_impact.gdshader")
const PIVOT := Vector3(0,1.57,0.31)
const IMPACT_POINT := Vector3(0,1.22,0.535)
const WINDUP := 0.18
const IMPACT_TIME := 0.30

@export_group("Punching Interaction")
@export_range(0.5,4.0,0.05) var interaction_range: float = 1.35:
	set(value): interaction_range = clampf(value,0.5,4.0)
@export_range(1.8,5.0,0.1) var swing_duration: float = 2.8:
	set(value): swing_duration = clampf(value,1.8,5.0)
@export_range(10.0,35.0,1.0) var swing_angle: float = 28.0:
	set(value): swing_angle = clampf(value,10.0,35.0)
@export var score_range := Vector2i(300,999):
	set(value):
		var limits := value.clamp(Vector2i.ZERO,Vector2i.ONE*999)
		score_range = Vector2i(mini(limits.x,limits.y),maxi(limits.x,limits.y))
@export_tool_button("Preview punch") var preview_punch = start_interaction

var last_score: int = 0
var _playing := false
var _elapsed := 0.0
var _run_duration := 2.8
var _amplitude := 0.0
var _direction := 1.0
var _pending_score := 0
var _displayed_score := -1
var _random := RandomNumberGenerator.new()
var _pivot: Node3D
var _bag: MeshInstance3D
var _score_material: ShaderMaterial
var _impact: MeshInstance3D
var _impact_material: ShaderMaterial

func _init() -> void:
	cabinet_color = Color("a95e50")
	accent_color = Color("935548")

func _kind() -> StringName:
	return &"punching_bag"

func _ready() -> void:
	_random.randomize()
	if not interaction_requested.is_connected(start_interaction):
		interaction_requested.connect(start_interaction)
	super._ready()
	if not Engine.is_editor_hint(): add_to_group(&"memory_interactables")

func rebuild() -> void:
	var cancelled := _playing
	_playing = false
	set_process(false)
	super.rebuild()
	if not is_inside_tree(): return
	var builder := GEOMETRY.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.accent = accent_color
	builder.ivory = cream_color
	builder.frame = Transform3D(Basis.IDENTITY,-PIVOT)
	builder.punching_bag_leather()
	_pivot = Node3D.new()
	_pivot.name = "BagSwing"
	_pivot.position = PIVOT*prop_scale
	_pivot.scale = Vector3.ONE*prop_scale
	_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated(_pivot)
	_bag = MeshInstance3D.new()
	_bag.name = "LeatherBag"
	_bag.mesh = builder.s.commit()
	_bag.material_override = _material
	_bag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(_bag)
	var display := MeshInstance3D.new()
	display.name = "ScoreDisplay"
	var screen := QuadMesh.new()
	screen.size = Vector2(0.26,0.075)
	display.mesh = screen
	display.position = Vector3(0,1.86,0.597)*prop_scale
	display.scale = Vector3.ONE*prop_scale
	display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_score_material = ShaderMaterial.new()
	_score_material.shader = SCORE_PAINT
	_score_material.set_shader_parameter("digit_count",3)
	display.material_override = _score_material
	_generated(display)
	_impact = MeshInstance3D.new()
	_impact.name = "PaintedImpact"
	var splash := QuadMesh.new()
	splash.size = Vector2.ONE*0.42
	_impact.mesh = splash
	_impact.position = IMPACT_POINT*prop_scale
	_impact.scale = Vector3.ONE*prop_scale
	_impact.custom_aabb = AABB(Vector3.ONE*-0.30,Vector3.ONE*0.60)
	_impact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impact_material = ShaderMaterial.new()
	_impact_material.shader = IMPACT_PAINT
	_impact.material_override = _impact_material
	_generated(_impact)
	_reset_pose()
	_displayed_score = -1
	_set_score(last_score)
	if cancelled: interaction_cancelled.emit()

func can_interact(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not is_inside_tree(): return false
	if _playing or not is_visible_in_tree() or not can_process() or not is_instance_valid(_pivot): return false
	if actor.get_viewport()!=get_viewport(): return false
	var punch := get_anchor(&"Punch")
	if not is_instance_valid(punch): return false
	var approach := to_global(Vector3(punch.position.x,0.0,punch.position.z))
	return actor.global_position.distance_squared_to(approach)<=interaction_range*interaction_range

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor): return false
	return start_interaction()

func start_interaction() -> bool:
	if _playing or not is_inside_tree() or not is_instance_valid(_pivot): return false
	_pending_score = _random.randi_range(score_range.x,score_range.y)
	var strength := 0.5 if score_range.x==score_range.y else float(_pending_score-score_range.x)/(score_range.y-score_range.x)
	_amplitude = deg_to_rad(swing_angle)*lerpf(0.75,1.0,strength)
	_direction = -1.0 if _random.randf()<0.5 else 1.0
	_run_duration = swing_duration
	_elapsed = 0.0
	_playing = true
	_reset_pose()
	_set_score(0)
	set_process(true)
	interaction_started.emit()
	return true

func is_playing() -> bool:
	return _playing

func _process(delta: float) -> void:
	if not _playing: return
	_elapsed = minf(_run_duration,_elapsed+maxf(delta,0.0))
	if _elapsed<WINDUP:
		var anticipation := smoothstep(0.0,1.0,_elapsed/WINDUP)
		_pivot.rotation = Vector3(-0.035*anticipation,0,-_direction*0.05*anticipation)
	else:
		var t := _elapsed-WINDUP
		var fade := 1.0-smoothstep(_run_duration-0.35,_run_duration,_elapsed)
		var wave := sin(t*9.5)*exp(-2.2*t)*fade
		# Mostly sideways with a small backward deflection: the leather clears the column.
		_pivot.rotation = Vector3(-0.035*exp(-18.0*t)+0.10*wave,0,
			_direction*(-0.05*exp(-18.0*t)+_amplitude*wave))
		var squash := sin(PI*clampf(t/0.12,0.0,1.0))*0.12
		_bag.scale = Vector3(1.0+squash*0.5,1.0-squash,1.0+squash*0.5)
		_impact.visible = t<IMPACT_TIME
		if _impact.visible:
			_impact_material.set_shader_parameter("progress",clampf(t/IMPACT_TIME,0.0,1.0))
		var tally := clampf(t/0.85,0.0,1.0)
		_set_score(int(_pending_score*(1.0-pow(1.0-tally,3.0))))
	if _elapsed>=_run_duration:
		_playing = false
		set_process(false)
		_reset_pose()
		last_score = _pending_score
		_set_score(last_score)
		score_awarded.emit(last_score)

func _reset_pose() -> void:
	_pivot.rotation = Vector3.ZERO
	_bag.scale = Vector3.ONE
	_impact.hide()
	_impact_material.set_shader_parameter("progress",-1.0)

func _set_score(value: int) -> void:
	value = clampi(value,0,999)
	if value==_displayed_score: return
	_displayed_score = value
	_score_material.set_shader_parameter("score",value)
