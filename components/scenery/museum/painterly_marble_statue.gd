@tool
class_name PainterlyMarbleStatue
extends PainterlyStadiumPiece
## Classical studies: elongated proportions, contrapposto, carved cloth and broken edges.
@export_enum("Athlete", "Draped Figure", "Bust", "Veiled Lady Study") var figure: int = 0:
	set(value):
		figure = clampi(value,0,3)
		_request_rebuild()
@export var marble_color := Color("e4e0d3"):
	set(value):
		marble_color = value
		_request_rebuild()
func _build(b: RefCounted) -> void:
	var marble := marble_color
	b.soft_box(Vector3(0,0.43,0),Vector3(1.2,0.86,1.1),Color("cfc8b6"),0.06,1.0)
	b.box(Vector3(0,0.9,0),Vector3(1.32,0.1,1.2),marble,1.0)
	if figure==3:
		_veiled_lady(b,marble)
		_box_collision("SculpturePlinth",Vector3(0,1.25,0),Vector3(1.3,2.5,1.2))
		return
	if figure==2:
		b.disc(Vector3(0,1.07,0),0.31,0.26,marble,Vector3.UP,1.0,16)
		b.ball(Vector3(0,1.42,0),Vector3(0.83,0.64,0.4),marble,1.0)
		_head(b,Vector3(0,1.95,0),marble)
	else:
		var hip := Vector3(0.03,1.9,0)
		b.ball(hip,Vector3(0.53,0.4,0.35),marble,1.0)
		b.ball(Vector3(-0.05,2.24,0),Vector3(0.63,0.74,0.38),marble,1.0)
		_head(b,Vector3(-0.11,2.83,0),marble)
		if figure==0:
			_limb(b,Vector3(-0.16,1.87,0),Vector3(-0.2,1.43,0.02),Vector3(-0.23,1.03,0.08),0.135,marble)
			_limb(b,Vector3(0.2,1.85,0),Vector3(0.37,1.48,-0.06),Vector3(0.28,1.04,0.12),0.12,marble)
			_limb(b,Vector3(-0.37,2.48,0),Vector3(-0.5,2.12,0),Vector3(-0.49,1.88,0.08),0.095,marble)
			_limb(b,Vector3(0.25,2.46,0),Vector3(0.47,2.19,0.02),Vector3(0.38,2.39,0.21),0.09,marble)
			for x in [-0.23,0.28]: b.ball(Vector3(x,1.01,0.16),Vector3(0.21,0.12,0.39),marble,1.0)
			b.box(Vector3(-0.48,1.4,-0.15),Vector3(0.12,0.9,0.16),marble.darkened(0.04),1.0)
		else:
			# A folded chiton flares gently onto the plinth, with uneven carved ridges.
			for segment in 20:
				var a := TAU*segment/20.0
				var c := TAU*(segment+1)/20.0
				var lower_a := Vector3(cos(a)*0.44,0.98,sin(a)*0.27)
				var lower_c := Vector3(cos(c)*0.44,0.98,sin(c)*0.27)
				var top_a := hip+Vector3(cos(a)*0.27,0,sin(a)*0.18)
				var top_c := hip+Vector3(cos(c)*0.27,0,sin(c)*0.18)
				b.quad(lower_a,lower_c,top_c,top_a,marble.lightened(0.025*(segment%3)),1.0)
				b.rod(lower_a,top_a,0.024,marble.lightened(0.045),5)
			_limb(b,Vector3(-0.36,2.46,0),Vector3(-0.48,2.17,0.1),Vector3(-0.19,2.06,0.2),0.085,marble)
			b.ball(Vector3(0.31,2.36,0),Vector3(0.17,0.31,0.2),marble,1.0)
			for fold in 5:
				b.rod(Vector3(-0.28+fold*0.12,2.44,0.17),Vector3(0.2,1.94,0.2),0.025,marble.lightened(0.05),5)
	_box_collision("SculpturePlinth",Vector3(0,1.55,0),Vector3(1.3,3.1,1.2))
func _veiled_lady(b: RefCounted, marble: Color) -> void:
	# Monti's flower wreath, veiled face and folded shoulders, interpreted as
	# opaque carved planes rather than translucent fabric.
	b.disc(Vector3(0,1.03,0),0.31,0.16,marble,Vector3.UP,1.0,20)
	var rings := [Vector3(0.42,1.15,0.24), Vector3(0.5,1.48,0.27),
		Vector3(0.23,1.75,0.23), Vector3(0.245,1.97,0.28),
		Vector3(0.27,2.16,0.25), Vector3(0.24,2.32,0.22), Vector3(0.035,2.4,0.035)]
	var sides := 32
	for ring in rings.size()-1:
		for segment in sides:
			var vertices: Array[Vector3] = []
			for ij in [Vector2i(ring,segment),Vector2i(ring,segment+1),Vector2i(ring+1,segment+1),Vector2i(ring+1,segment)]:
				var a: float = TAU*ij.y/sides
				var r: Vector3 = rings[ij.x]
				var fold := sin(a*13.0+r.y*2.0)*0.012
				var nose := 0.085*exp(-pow(wrapf(a,-PI,PI)/0.23,2.0))*exp(-pow((r.y-1.97)/0.13,2.0))
				vertices.append(Vector3(sin(a)*(r.x+fold),r.y,cos(a)*(r.z+fold)+nose))
			b.quad(vertices[0],vertices[1],vertices[2],vertices[3],marble,1.0)
	for side in [-1.0,1.0]:
		for fold in 3:
			var x: float = side*(0.12+fold*0.055)
			var crease: Array[Vector3] = [Vector3(x,2.29,0.22),Vector3(x*0.85,2.06,0.27),Vector3(x*0.7,1.77,0.24),Vector3(side*0.29,1.43,0.26)]
			b.tube(crease,0.012,marble.lightened(0.04),5)
	for flower in 9:
		var a := lerpf(-1.4,1.4,flower/8.0)
		var center := Vector3(sin(a)*0.265,2.29+cos(a)*0.035,cos(a)*0.23)
		b.ball(center,Vector3.ONE*0.09,marble.darkened(0.03),1.0)
		for petal in 5:
			var angle := TAU*petal/5.0
			b.ball(center+Vector3(cos(angle)*0.048,sin(angle)*0.048,0.018),Vector3(0.075,0.075,0.045),marble.lightened(0.025),1.0)

func _limb(b: RefCounted, shoulder: Vector3, elbow: Vector3, hand: Vector3, radius: float, color: Color) -> void:
	b.rod(shoulder,elbow,radius,color,10)
	b.ball(elbow,Vector3.ONE*radius*2.05,color,1.0)
	b.rod(elbow,hand,radius*0.7,color,10)
	b.ball(hand,Vector3.ONE*radius*1.5,color,1.0)
func _head(b: RefCounted, at: Vector3, color: Color) -> void:
	b.rod(at-Vector3.UP*0.3,at,0.09,color,10)
	b.ball(at,Vector3(0.32,0.43,0.34),color,1.0)
	b.soft_box(at+Vector3(0,-0.01,0.17),Vector3(0.055,0.11,0.07),color,0.01,1.0)
	for curl in 12:
		var a := TAU*curl/12.0
		b.ball(at+Vector3(cos(a)*0.145,0.1+0.065*sin(a*2),sin(a)*0.15-0.025),Vector3.ONE*0.1,color.darkened(0.035),1.0)
