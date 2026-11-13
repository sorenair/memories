@tool
class_name PainterlyMarketStage
extends PainterlyStadiumPiece
## Three acoustic performers with instrument-relative, connected two-bone arms.
signal ground_exclusion_changed
const DETAILS = preload("res://components/scenery/christmas_market/market_geometry.gd")
@export_range(0.0,1.0,0.05) var performance_strength := 0.65
var _musicians: Array[Node3D] = []
const UPPER_LENGTH := 0.32
const FORE_LENGTH := 0.30
var _rigs: Array[Dictionary] = []
var _hand_mesh: Mesh
var _time := 0.0

func _ready() -> void:
	set_notify_transform(true)
	super._ready()
	set_process(not Engine.is_editor_hint())
func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready(): ground_exclusion_changed.emit()
func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return absf(p.x)<3.25 and absf(p.z)<1.65
func rebuild() -> void:
	_musicians.clear()
	_rigs.clear()
	super.rebuild()
	if not is_inside_tree(): return
	_hand_mesh = _make_hand_mesh()
	for i in 3: _performer(i)
	_apply_performance(_time)
	ground_exclusion_changed.emit()

func _build(b: RefCounted) -> void:
	var wood := Color("8f755c")
	b.soft_box(Vector3(0,0.14,0),Vector3(6.4,0.28,3.2),wood,0.05,1.0)
	for plank in 15:
		b.box(Vector3(-3.0+plank*0.43,0.284,0),Vector3(0.012,0.008,3.0),wood.darkened(0.18),1.0)
	b.box(Vector3(0,1.35,-1.45),Vector3(6.15,2.3,0.12),Color("59695c"),1.0)
	for x in [-3.05,3.05]:
		b.box(Vector3(x,1.65,-1.35),Vector3(0.15,3.3,0.15),wood,1.0)
	# Recall only the rear canopy strip. A complete roof obscures the players
	# from the game's elevated camera; the open front keeps their hands readable.
	b.box(Vector3(0,3.1,-1.05),Vector3(6.6,0.18,1.2),wood.darkened(0.08),1.0)
	b.soft_box(Vector3(0,3.22,-1.05),Vector3(6.7,0.12,1.28),Color("f0f2e8"),0.055,1.0)
	DETAILS.garland(b,Vector3(0,3.03,-0.38),6.1)
	DETAILS.wreath(b,Vector3(0,2.35,-1.32),0.34)
	for x in [-2.7,2.7]:
		b.soft_box(Vector3(x,0.7,1.0),Vector3(0.45,0.85,0.4),Color("5e625e"),0.04,1.0)
		b.disc(Vector3(x,0.72,1.22),0.13,0.012,Color("494e4b"),Vector3.BACK,1.0,16)
	_box_collision("Stage",Vector3(0,1.5,0),Vector3(6.45,3.0,3.25))

func _builder() -> RefCounted:
	var b := GEOMETRY.new()
	b.s = SurfaceTool.new()
	b.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	b.s.set_uv(Vector2.ZERO)
	return b

func _performer(index: int) -> void:
	var actor := Node3D.new()
	actor.name = ["Guitarist","Fiddler","Bassist"][index]
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.position = Vector3((index-1)*1.7,0.29,0.15)
	actor.set_meta(&"rest_position",actor.position)
	_generated(actor)
	_musicians.append(actor)
	var coat: Color = [Color("9e6b5e"),Color("677a70"),Color("77758a")][index]
	var body := _builder()
	DETAILS.person(body,Vector3.ZERO,1.3,[0,1,6][index],coat,false)
	_add_mesh(actor,body.s.commit(),"Body")
	var instrument := _builder()
	_build_instrument(instrument,index)
	_add_mesh(actor,instrument.s.commit(),"Instrument")
	var upper := _segment_mesh(UPPER_LENGTH,0.060,coat,true)
	var fore := _segment_mesh(FORE_LENGTH,0.043,coat,false)
	var rig := {"arms":[],"bow":null}
	for side: float in [-1.0,1.0]:
		var arm := Node3D.new()
		arm.name = "LeftArm" if side<0 else "RightArm"
		actor.add_child(arm)
		rig.arms.append({"shoulder":Vector3(side*0.205,1.12,0),
			"upper":_add_mesh(arm,upper,"UpperArm"),
			"fore":_add_mesh(arm,fore,"Forearm"),
			"hand":_add_mesh(arm,_hand_mesh,"Hand")})
	if index==1:
		var bow := _builder()
		bow.rod(Vector3(-0.50,0.25,0),Vector3(0.12,-0.06,0),0.009,Color("a78c62"),6)
		bow.rod(Vector3(-0.48,0.24,0.012),Vector3(0.10,-0.05,0.012),0.003,Color("e1d7bc"),5)
		rig.bow = _add_mesh(actor,bow.s.commit(),"Bow")
	_rigs.append(rig)

func _build_instrument(b: RefCounted, index: int) -> void:
	var brown := Color("b18454")
	var neck := Color("655644")
	if index==0:
		# Neck extends to the fretting hand's side. The right forearm reaches over
		# the upper bout, with the strumming fingers just in front of the strings.
		b.ball(Vector3(0.08,0.83,0.24),Vector3(0.43,0.50,0.15),brown,1.0)
		b.ball(Vector3(-0.02,1.0,0.24),Vector3(0.30,0.27,0.14),brown,1.0)
		b.disc(Vector3(0.03,0.95,0.325),0.065,0.006,Color("5e4938"),Vector3.BACK,1.0,14)
		b.rod(Vector3(-0.12,1.02,0.24),Vector3(-0.50,1.28,0.24),0.030,neck,8)
		for offset in [-0.012,0.0,0.012]:
			b.rod(Vector3(0.12+offset,0.77,0.329),Vector3(-0.49+offset,1.28,0.279),0.002,Color("d9c9a6"),5)
	elif index==1:
		b.ball(Vector3(-0.10,1.30,0.25),Vector3(0.28,0.14,0.18),brown,1.0)
		b.rod(Vector3(-0.10,1.32,0.27),Vector3(-0.52,1.34,0.27),0.024,neck,8)
		for offset in [-0.008,0.008]:
			b.rod(Vector3(-0.20,1.30+offset,0.346),Vector3(0.0,1.30+offset,0.346),0.002,Color("ddcda9"),5)
	else:
		# Stand beside the bass instead of putting its neck across the face.
		b.ball(Vector3(-0.34,0.57,0.23),Vector3(0.55,0.78,0.20),brown.darkened(0.08),1.0)
		b.ball(Vector3(-0.32,0.91,0.23),Vector3(0.36,0.34,0.18),brown.darkened(0.08),1.0)
		b.rod(Vector3(-0.32,1.0,0.23),Vector3(-0.38,1.90,0.23),0.030,neck,8)
		b.rod(Vector3(-0.34,0.24,0.23),Vector3(-0.34,0.02,0.23),0.014,neck,6)
		b.box(Vector3(-0.32,0.72,0.34),Vector3(0.13,0.035,0.018),Color("d2b48a"),1.0)
		for offset in [-0.012,0.0,0.012]:
			b.rod(Vector3(-0.32+offset,0.72,0.351),Vector3(-0.38+offset,1.88,0.269),0.002,Color("d8c5a2"),5)

func _segment_mesh(length: float, radius: float, coat: Color, elbow: bool) -> Mesh:
	var b := _builder()
	b.rod(Vector3.ZERO,Vector3.UP*length,radius,coat,10)
	if elbow: b.ball(Vector3.UP*length,Vector3.ONE*radius*2.0,coat,1.0)
	return b.s.commit()

func _make_hand_mesh() -> Mesh:
	var b := _builder()
	var skin := Color("c4a18b")
	b.ball(Vector3.ZERO,Vector3(0.085,0.10,0.06),skin,1.0)
	b.ball(Vector3(0,-0.025,-0.025),Vector3(0.078,0.045,0.05),skin,1.0)
	return b.s.commit()

func _add_mesh(parent_node: Node3D, shape: Mesh, id: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = id
	mesh.mesh = shape
	mesh.material_override = _material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent_node.add_child(mesh)
	return mesh

func _pose_arm(arm: Dictionary, wrist: Vector3, pole: Vector3) -> void:
	var shoulder: Vector3 = arm.shoulder
	var offset := wrist-shoulder
	var distance := clampf(offset.length(),0.025,UPPER_LENGTH+FORE_LENGTH-0.001)
	var direction := offset.normalized()
	var along := (UPPER_LENGTH*UPPER_LENGTH-FORE_LENGTH*FORE_LENGTH+distance*distance)/(2.0*distance)
	var height := sqrt(maxf(0.0,UPPER_LENGTH*UPPER_LENGTH-along*along))
	var bend := (pole-direction*pole.dot(direction)).normalized()
	var elbow := shoulder+direction*along+bend*height
	_aim(arm.upper,shoulder,elbow)
	_aim(arm.fore,elbow,wrist)
	arm.hand.position = wrist

func _aim(part: Node3D, start: Vector3, end: Vector3) -> void:
	var y := (end-start).normalized()
	var reference := Vector3.BACK if absf(y.dot(Vector3.BACK))<0.97 else Vector3.RIGHT
	var x := y.cross(reference).normalized()
	part.transform = Transform3D(Basis(x,y,x.cross(y)),start)

func _apply_performance(seconds: float) -> void:
	for i in _musicians.size():
		var phase := seconds*TAU*1.6+i*1.7
		var motion := sin(phase)*performance_strength
		var actor := _musicians[i]
		var rest: Vector3 = actor.get_meta(&"rest_position")
		actor.position = rest+Vector3.UP*sin(phase*0.5)*0.012*performance_strength
		actor.rotation.z = sin(phase*0.5)*0.018*performance_strength
		var rig := _rigs[i]
		if i==0:
			_pose_arm(rig.arms[0],Vector3(-0.36-motion*0.010,1.18+motion*0.007,0.316),Vector3(-1,-0.6,0))
			_pose_arm(rig.arms[1],Vector3(0.08,0.94+motion*0.045,0.385),Vector3(1,0.9,0))
		elif i==1:
			_pose_arm(rig.arms[0],Vector3(-0.42+motion*0.008,1.33,0.333),Vector3(-1,-0.4,0))
			var wrist := Vector3(0.20,1.20,0.370)+Vector3(0.07,-0.035,0)*motion
			_pose_arm(rig.arms[1],wrist,Vector3(1,-0.65,0.1))
			rig.bow.position = wrist+Vector3(0,0,-0.005)
		else:
			_pose_arm(rig.arms[0],Vector3(-0.35,1.38+motion*0.012,0.337),Vector3(-1,-0.2,0))
			_pose_arm(rig.arms[1],Vector3(-0.22,0.99+motion*0.012,0.370),Vector3(1,0.8,0))

func _process(delta: float) -> void:
	_time += delta
	_apply_performance(_time)
