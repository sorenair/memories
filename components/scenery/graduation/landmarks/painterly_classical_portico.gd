@tool
class_name PainterlyClassicalPortico
extends PainterlyConservatoryPiece
## Open Ionic colonnade and broad stairs. No building walls or enterable interior.
const MUSEUM = preload("res://components/scenery/museum/painterly_museum_portico.gd")
@export_group("Portico")
@export_range(8.0,18.0,0.1) var width: float = 12.4:
	set(value):
		width=clampf(value,8,18)
		_request_rebuild()
@export_range(4,10,1) var column_count: int = 8:
	set(value):
		column_count=clampi(value,4,10)
		_request_rebuild()
@export_range(3.2,7.0,0.1) var column_height: float = 4.8:
	set(value):
		column_height=clampf(value,3.2,7)
		_request_rebuild()
@export var stone_color := Color("ddd7c9"):
	set(value):
		stone_color=value
		_request_rebuild()
@export var frieze_text: String = "":
	set(value):
		frieze_text=value.left(72)
		_request_rebuild()
@export_group("Stairs and Landing")
@export_range(3,14,1) var step_count: int = 8:
	set(value):
		step_count=clampi(value,3,14)
		_request_rebuild()
@export_range(0.08,0.14,0.005) var step_rise: float = 0.105:
	set(value):
		step_rise=clampf(value,0.08,0.14)
		_request_rebuild()
@export_range(0.35,0.65,0.025) var tread_depth: float = 0.45:
	set(value):
		tread_depth=clampf(value,0.35,0.65)
		_request_rebuild()
@export_range(2.0,4.0,0.1) var landing_depth: float = 2.5:
	set(value):
		landing_depth=clampf(value,2,4)
		_request_rebuild()
@export var railings_enabled: bool = true:
	set(value):
		railings_enabled=value
		_request_rebuild()

func landing_height() -> float:
	return step_count*step_rise

func stair_front() -> float:
	return landing_depth*0.5+step_count*tread_depth

func column_x(index: int) -> float:
	return lerpf(-width*0.5+0.80,width*0.5-0.80,float(clampi(index,0,column_count-1))/float(column_count-1))

func column_radius_scale() -> float:
	# Keep a useful gap even when more columns are requested on a narrow portico.
	return clampf((width-1.6)/float(column_count-1)/1.65,0.57,1.0)

## The same shallow beveled tread profile drives visible stone and collision.
func stair_profile() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(stair_front(),0)])
	var bevel := minf(tread_depth*0.45,step_rise/0.65)
	for step in range(step_count):
		var start := stair_front()-float(step)*tread_depth
		points.append(Vector2(start-bevel,(step+1)*step_rise))
		points.append(Vector2(start-tread_depth,(step+1)*step_rise))
	points.append(Vector2(-landing_depth*0.5,landing_height()))
	return points

func stair_height_at(z: float) -> float:
	var profile := stair_profile()
	for i in range(profile.size()-1):
		var a := profile[i]
		var b := profile[i+1]
		if z<=a.x and z>=b.x:
			return lerpf(a.y,b.y,(a.x-z)/maxf(a.x-b.x,0.00001))
	return landing_height() if z<0 else 0.0

func _stair_collision(profile: PackedVector2Array) -> void:
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name="PorticoStairs"
	for i in range(profile.size()-1):
		var points := PackedVector3Array()
		for p in [profile[i],profile[i+1]]:
			for x in [-width*0.5,width*0.5]:
				points.append(Vector3(x,p.y,p.x))
				points.append(Vector3(x,-0.025,p.x))
		var shape := ConvexPolygonShape3D.new()
		shape.points=points
		var collider := CollisionShape3D.new()
		collider.name="Tread_%02d"%i
		collider.shape=shape
		body.add_child(collider)
	_generated(body)

func _build(b: RefCounted) -> void:
	var stone := stone_color
	var height := landing_height()
	var profile := stair_profile()
	var outline := profile.duplicate()
	outline.append(Vector2(-landing_depth*0.5,-0.025))
	outline.append(Vector2(stair_front(),-0.025))
	b.frame=Transform3D(Basis(Vector3.UP,-PI*0.5),Vector3.ZERO)
	b.profile(outline,Vector3.ZERO,width,stone,1)
	b.frame=Transform3D.IDENTITY
	# Very quiet tread-sized color pools, without a dirty stone texture.
	for i in range(step_count):
		var front := profile[i*2+1]
		var back := profile[i*2+2]
		b.quad(Vector3(-width*0.5+0.015,front.y+0.001,front.x),Vector3(width*0.5-0.015,front.y+0.001,front.x),Vector3(width*0.5-0.015,back.y+0.001,back.x),Vector3(-width*0.5+0.015,back.y+0.001,back.x),stone.lightened(b.rng.randf_range(-0.012,0.012)),1)
	_stair_collision(profile)
	var scale_x := column_radius_scale()
	for i in range(column_count):
		var x := column_x(i)
		b.frame=Transform3D(Basis.IDENTITY.scaled(Vector3(scale_x,column_height/5.35,scale_x)),Vector3(x,height,0))
		MUSEUM.build_ionic_column(b,Vector3.ZERO,stone.lightened(b.rng.randf_range(-0.012,0.012)))
		b.frame=Transform3D.IDENTITY
		_box_collision("Column",Vector3(x,height+column_height*0.5,0),Vector3(0.86*scale_x,column_height,0.86*scale_x))
	# Flat architrave/frieze/cornice matches the reference's broad classical band.
	var top := height+column_height
	for layer in [[0.06,0.14,0.10,1.30],[0.19,0.12,0.23,1.45],[0.49,0.50,0.30,1.68],[0.80,0.12,0.45,1.86],[0.92,0.12,0.58,2.02]]:
		b.soft_box(Vector3(0,top+layer[0],-0.13),Vector3(width+layer[2],layer[1],layer[3]),stone.lightened(0.02 if layer[1]<0.2 else -0.015),0.025,1)
	# Small dentils and circular wreaths are subordinate to the larger paint planes.
	var dentils := maxi(12,roundi(width/0.29))
	for i in range(dentils):
		b.box(Vector3(lerpf(-width*0.5+0.14,width*0.5-0.14,float(i)/float(dentils-1)),top+0.19,0.64),Vector3(0.09,0.10,0.10),stone.lightened(0.035),1)
	for i in range(column_count):
		var at := Vector3(column_x(i),top+0.79,0.815)
		for section in range(24):
			var a := TAU*float(section)/24
			var c := TAU*float(section+1)/24
			var outer_a := Vector3(cos(a),sin(a),0)*0.11
			var outer_c := Vector3(cos(c),sin(c),0)*0.11
			b.quad(at+outer_a,at+outer_c,at+outer_c*0.69,at+outer_a*0.69,stone.lightened(0.065),1)
	if not frieze_text.is_empty():
		b.text(frieze_text,Vector3(0,top+0.49,0.724),minf(0.12,width*0.80/maxf(frieze_text.length(),1)),stone.darkened(0.18))
	_box_collision("Entablature",Vector3(0,top+0.46,-0.13),Vector3(width+0.4,0.96,1.95))
	if railings_enabled:
		var rail := Color("778080")
		for side: float in [-1.0,1.0]:
			var x := side*width*0.30
			var low := Vector3(x,0.80,stair_front()-0.06)
			var high := Vector3(x,height+0.80,landing_depth*0.5)
			b.rod(low,high,0.017,rail,10)
			b.rod(high,high+Vector3.FORWARD*0.40,0.017,rail,10)
			for post in range(4):
				var t := float(post)/3
				var p := low.lerp(high,t)
				var floor_y := stair_height_at(p.z)
				b.rod(Vector3(x,floor_y,p.z),p,0.014,rail,8)
				_box_collision("RailPost",Vector3(x,(floor_y+p.y)*0.5,p.z),Vector3(0.045,p.y-floor_y,0.045))
	_anchor("Approach",Vector3(0,0,stair_front()+0.8))
	_anchor("Landing",Vector3(0,height,0.85))
	_anchor("RearLanding",Vector3(0,height,-landing_depth*0.5+0.35))

func _build_layers() -> void:
	_contact(Vector2(width+0.8,stair_front()+landing_depth*0.5+0.7),Vector3(0,0,(stair_front()-landing_depth*0.5)*0.5))

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return absf(p.x)<width*0.5+0.04 and p.z>-landing_depth*0.5-0.04 and p.z<stair_front()+0.04
