@tool
class_name PainterlyCampusArches
extends PainterlyConservatoryPiece
## A freestanding pair of low pointed stone arches, inspired by the supplied campus reference.
const SEGMENTS := 32
const PIER := 0.72
const RING := 0.37
@export_group("Twin Arches")
@export_range(1.8,4.0,0.1) var opening_width: float = 2.7:
	set(value):
		opening_width=clampf(value,1.8,4)
		_request_rebuild()
@export_range(2.0,4.2,0.1) var spring_height: float = 2.7:
	set(value):
		spring_height=clampf(value,2,4.2)
		_request_rebuild()
@export_range(0.6,1.8,0.05) var arch_rise: float = 1.1:
	set(value):
		arch_rise=clampf(value,0.6,1.8)
		_request_rebuild()
@export_range(0.45,1.2,0.05) var depth: float = 0.72:
	set(value):
		depth=clampf(value,0.45,1.2)
		_request_rebuild()
@export var stone_color := Color("d5cbb6"):
	set(value):
		stone_color=value
		_request_rebuild()

func passage_center(index: int) -> Vector3:
	return Vector3((-0.5 if index<=0 else 0.5)*(opening_width+PIER),0,0)

func _curve(u: float) -> Vector2:
	# Mirrored quadratic halves retain the reference's broad, gently pointed crown.
	var left := u<=0.5
	var t := (u if left else 1.0-u)*2
	var a := Vector2(-opening_width*0.5,spring_height)
	var b := Vector2(-opening_width*0.34,spring_height+arch_rise*0.60)
	var c := Vector2(0,spring_height+arch_rise)
	var p := a*(1-t)*(1-t)+b*2*(1-t)*t+c*t*t
	return p if left else Vector2(-p.x,p.y)

func _outward(u: float) -> Vector2:
	var a := _curve(maxf(0,u-0.0002))
	var b := _curve(minf(1,u+0.0002))
	var tangent := (b-a).normalized()
	return Vector2(-tangent.y,tangent.x)

func _at(center: float,u: float,offset: float,z: float) -> Vector3:
	var p := _curve(u)+_outward(u)*offset
	return Vector3(center+p.x,p.y,z)

func _band(b: RefCounted,center: float,inner: float,outer: float,thickness: float,z: float,color: Color,joints: bool) -> void:
	for segment in range(SEGMENTS):
		var gap := 0.0007 if joints and segment%2==0 else 0.0
		var a := float(segment)/SEGMENTS+gap
		var c := float(segment+1)/SEGMENTS-(0.0007 if joints and segment%2==1 else 0.0)
		var il := _at(center,a,inner,z+thickness*0.5)
		var ir := _at(center,c,inner,z+thickness*0.5)
		var ol := _at(center,a,outer,z+thickness*0.5)
		var oright := _at(center,c,outer,z+thickness*0.5)
		var painted: Color=color.lightened(b.rng.randf_range(-0.028,0.028)) if joints else color
		b.quad(il,ir,oright,ol,painted,1)
		var back := Vector3.FORWARD*thickness
		b.quad(ol+back,oright+back,ir+back,il+back,painted.darkened(0.015),1)
		var na := _outward(a)
		var nc := _outward(c)
		# Smooth intrados normals avoid obvious polygon bands inside the opening.
		for v in [[il,-na],[il+back,-na],[ir+back,-nc],[il,-na],[ir+back,-nc],[ir,-nc]]:
			b.vertex(v[0],Vector3(v[1].x,v[1].y,0),painted.darkened(0.05),1)
		b.quad(ol,oright,oright+back,ol+back,painted,1)
		b.quad(il,ol,ol+back,il+back,painted,1)
		b.quad(ir+back,oright+back,oright,ir,painted,1)

func _arch_collision(center: float) -> void:
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name="ArchVault"
	for segment in range(SEGMENTS/2):
		var points := PackedVector3Array()
		for u in [float(segment)/(SEGMENTS/2),float(segment+1)/(SEGMENTS/2)]:
			for offset in [0.0,RING]:
				for z in [-depth*0.5,depth*0.5]:
					points.append(_at(center,u,offset,z))
		var shape := ConvexPolygonShape3D.new()
		shape.points=points
		var collider := CollisionShape3D.new()
		collider.shape=shape
		body.add_child(collider)
	_generated(body)

func _build(b: RefCounted) -> void:
	var stride := opening_width+PIER
	for index in range(3):
		var x := float(index-1)*stride
		var height := spring_height+arch_rise+RING+0.10 if index==1 else spring_height+0.28
		# A lightly recessed core keeps fine masonry joints warm rather than black.
		b.soft_box(Vector3(x,height*0.5,0),Vector3(PIER-0.018,height,depth-0.025),stone_color.darkened(0.08),0.025,1)
		var rows := maxi(1,roundi(height/0.34))
		for row in range(rows):
			var h := height/rows
			b.soft_box(Vector3(x,h*(row+0.5),0),Vector3(PIER,h-0.008,depth),stone_color.lightened(b.rng.randf_range(-0.035,0.035)),0.014,1)
		b.soft_box(Vector3(x,0.08,0),Vector3(PIER+0.15,0.16,depth+0.13),stone_color.darkened(0.025),0.025,1)
		b.soft_box(Vector3(x,0.22,0),Vector3(PIER+0.07,0.07,depth+0.07),stone_color.lightened(0.025),0.012,1)
		b.soft_box(Vector3(x,height+0.02,0),Vector3(PIER+0.12,0.09,depth+0.10),stone_color.lightened(0.04),0.018,1)
		_box_collision("StonePier",Vector3(x,height*0.5,0),Vector3(PIER+0.08,height,depth+0.10))
		if index==1:
			# A small pointed coping recalls the central Gothic finial, without the building/statue.
			b.profile(PackedVector2Array([Vector2(-PIER*0.61,0),Vector2(PIER*0.61,0),Vector2(0,0.35)]),Vector3(0,height+0.065,0),depth+0.08,stone_color.lightened(0.035),1)
	for index in range(2):
		var x := passage_center(index).x
		# Recess the mortar core on every exposed side, avoiding coplanar intrados/
		# outer faces against the dressed stone rings.
		_band(b,x,0.007,RING-0.007,depth-0.018,0,stone_color.darkened(0.075),false)
		_band(b,x,0,0.12,depth+0.018,0,stone_color.lightened(0.025),true)
		_band(b,x,0.12,0.18,depth+0.072,0,stone_color.lightened(0.065),false)
		_band(b,x,0.18,0.29,depth+0.025,0,stone_color,true)
		_band(b,x,0.29,RING,depth+0.105,0,stone_color.lightened(0.08),false)
		_arch_collision(x)
		_anchor("LeftPassage" if index==0 else "RightPassage",passage_center(index))
	_anchor("Approach",Vector3(0,0,depth*0.5+1.25))

func _build_layers() -> void:
	for index in range(3):
		_contact(Vector2(1.18,depth+0.72),Vector3(float(index-1)*(opening_width+PIER),0,0))
		get_children(true)[-1].name="Contact_Pier_%d"%index

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	for index in range(3):
		if absf(p.x-float(index-1)*(opening_width+PIER))<PIER*0.5+0.09 and absf(p.z)<depth*0.5+0.09:
			return true
	return false
