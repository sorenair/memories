@tool
class_name PainterlyDJBooth
extends PainterlyConcertComponent
## Compact mixer and performer, using the existing painted crowd geometry.
const PERSON = preload("res://components/scenery/christmas_market/market_geometry.gd")
const ARM_LENGTH := 0.36
@export_group("DJ Performance")
@export_range(0.0,180.0,1.0) var beat_bpm := 120.0:
	set(value):
		beat_bpm = value
		_apply_material()
		_update_playback()
@export_range(0.0,1.0,0.05) var performance_strength := 0.8:
	set(value):
		performance_strength = clampf(value,0.0,1.0)
		_apply_performance(_clock)
		_update_playback()
var _clock := 0.0
var _arms: Array[Dictionary] = []
var _platters: Array[MeshInstance3D] = []

func _ready() -> void:
	super._ready()
	_update_playback()

func rebuild() -> void:
	_arms.clear()
	_platters.clear()
	super.rebuild()

func _update_playback() -> void:
	if is_inside_tree():
		set_process(not Engine.is_editor_hint() and beat_bpm>0.0 and performance_strength>0.0)

func _build_geometry() -> Dictionary:
	var b := GEOMETRY.new()
	b.begin(_config())
	b.soft_box(Vector3(0,0.45,0.45),Vector3(2.4,0.90,0.70),body_color,0.055)
	b.box(Vector3(0,0.92,0.45),Vector3(2.48,0.04,0.76),accent_color)
	b.soft_box(Vector3(0,0.96,0.44),Vector3(0.40,0.05,0.51),Color("444852"),0.02)
	for row in 4:
		for column in 3:
			var at := Vector3(-0.12+column*0.12,1.0,0.27+row*0.105)
			b.disc(at,0.023,0.025,trim_color,Vector3.UP,0,8)
			if column==1: b.box(at+Vector3(0.045,0.005,0),Vector3(0.02,0.008,0.035),Color("8eb9b5"),2)
	PERSON.person(b,Vector3(0,0,-0.12),1.2,0,accent_color,false)
	for side: float in [-1.0,1.0]:
		b.ball(Vector3(side*0.135,1.33,-0.12),Vector3(0.08,0.13,0.10),Color("41454c"))
	var band: Array[Vector3] = []
	for segment in 17:
		var angle := PI*segment/16.0
		band.append(Vector3(cos(angle)*0.16,1.35+sin(angle)*0.21,-0.12))
	b.tube(band,0.019,Color("41454c"),6)
	b.collider(Vector3(0,0.8,0.17),Vector3(2.5,1.6,1.3),"DJConsole")
	b.anchors["Controls"] = Vector3(0,1.0,0.45)
	return b.finish()

func _build_details() -> void:
	# Build once, then move only eight small mesh instances. Render-frame motion
	# bypasses physics interpolation; all parts share the prop's paint/recall.
	var performance := Node3D.new()
	performance.name = "Performance"
	performance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated_root.add_child(performance)
	var upper := GEOMETRY.new()
	upper.begin(_config())
	upper.rod(Vector3.ZERO,Vector3.UP*ARM_LENGTH,0.055,accent_color,10)
	upper.ball(Vector3.UP*ARM_LENGTH,Vector3.ONE*0.105,accent_color)
	var upper_mesh: Mesh = upper.finish().mesh
	var fore := GEOMETRY.new()
	fore.begin(_config())
	fore.rod(Vector3.ZERO,Vector3.UP*ARM_LENGTH,0.040,accent_color,10)
	var fore_mesh: Mesh = fore.finish().mesh
	var hand := GEOMETRY.new()
	hand.begin(_config())
	hand.ball(Vector3.ZERO,Vector3(0.09,0.045,0.10),Color("c4a18b"))
	hand.ball(Vector3(0,-0.027,0.035),Vector3(0.075,0.03,0.07),Color("c4a18b"))
	var hand_mesh: Mesh = hand.finish().mesh
	var record := GEOMETRY.new()
	record.begin(_config())
	record.disc(Vector3.ZERO,0.23,0.025,Color("343b46"),Vector3.UP,0,24)
	record.disc(Vector3(0,0.018,0),0.10,0.008,trim_color,Vector3.UP,0,16)
	# One painted marker makes the otherwise circular platter's rotation readable.
	record.box(Vector3(0,0.016,0.17),Vector3(0.025,0.005,0.065),trim_color)
	var record_mesh: Mesh = record.finish().mesh
	for side: float in [-1.0,1.0]:
		var id := "Left" if side<0.0 else "Right"
		var platter := _part(performance,record_mesh,id+"Platter")
		platter.position = Vector3(side*0.65,0.955,0.45)
		_platters.append(platter)
		_arms.append({"side":side,"shoulder":Vector3(side*0.18,1.04,-0.12),
			"upper":_part(performance,upper_mesh,id+"UpperArm"),
			"fore":_part(performance,fore_mesh,id+"Forearm"),
			"hand":_part(performance,hand_mesh,id+"Hand")})
	_apply_performance(_clock)

func _part(parent_node: Node3D, mesh: Mesh, id: String) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = id
	visual.mesh = mesh
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end = visibility_distance
	parent_node.add_child(visual)
	return visual

func _aim(part: Node3D, start: Vector3, end: Vector3) -> void:
	var y := (end-start).normalized()
	var x := y.cross(Vector3.BACK).normalized()
	part.transform = Transform3D(Basis(x,y,x.cross(y)),start)

func _apply_performance(seconds: float) -> void:
	for i in _arms.size():
		var arm := _arms[i]
		var side: float = arm.side
		var phase := seconds*TAU*beat_bpm/120.0 + i*1.4
		var arc := (sin(phase)*0.56+sin(phase*0.5)*0.06)*performance_strength
		var platter := _platters[i]
		platter.rotation.y = arc
		# Each hand follows a fixed contact point on its own rotating record.
		var wrist := platter.position+Vector3(-side*0.10,0.07,-0.12).rotated(Vector3.UP,arc)
		var shoulder: Vector3 = arm.shoulder
		var reach := wrist-shoulder
		var direction := reach.normalized()
		var half_reach := minf(reach.length()*0.5,ARM_LENGTH-0.001)
		var bend := Vector3(side*0.9,0.8,-0.2)
		bend = (bend-direction*bend.dot(direction)).normalized()
		var elbow := shoulder+direction*half_reach+bend*sqrt(maxf(0.0,ARM_LENGTH*ARM_LENGTH-half_reach*half_reach))
		_aim(arm.upper,shoulder,elbow)
		_aim(arm.fore,elbow,wrist)
		arm.hand.transform = Transform3D(Basis(Vector3.UP,arc),wrist)

func seek_time(seconds: float) -> void:
	_clock = maxf(0.0,seconds)
	_apply_performance(_clock)

func _process(delta: float) -> void:
	_clock += delta
	_apply_performance(_clock)

func _apply_material() -> void:
	super._apply_material()
	if _material:
		_material.set_shader_parameter("beat_bpm",beat_bpm)
		_material.set_shader_parameter("pulse_amount",0.12)
		_material.set_shader_parameter("light_intensity",0.6)
