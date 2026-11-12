@tool
class_name PainterlyMuseumPortico
extends PainterlyStadiumPiece
## The reference's six Ionic columns and pediment, with open void behind them.
@export var stone_color := Color("d5d1c4"):
	set(value):
		stone_color = value
		_request_rebuild()
# (local Z, height), front to back. Short bevels make each shallow tread
# walkable; the render mesh and floor collider share this exact profile.
const TREADS := [Vector2(3.5,0), Vector2(3.3,0.1), Vector2(2.7,0.1),
	Vector2(2.55,0.2), Vector2(1.95,0.2), Vector2(1.8,0.3),
	Vector2(-1.8,0.3), Vector2(-1.95,0.2), Vector2(-2.55,0.2),
	Vector2(-2.7,0.1), Vector2(-3.3,0.1), Vector2(-3.5,0)]
const HALF_WIDTH := 6.4
func _build(b: RefCounted) -> void:
	var stone := stone_color
	_steps(b,stone)
	for x in [-5.0,-3.2,-1.4,1.4,3.2,5.0]:
		var foot := Vector3(x,0.3,0)
		b.box(foot+Vector3.UP*0.1,Vector3(0.86,0.2,0.86),stone,1.0)
		b.disc(foot+Vector3.UP*0.27,0.37,0.16,stone,Vector3.UP,1.0,20)
		b.disc(foot+Vector3.UP*2.7,0.29,4.7,stone,Vector3.UP,1.0,20)
		for flute in 16:
			var angle := TAU*flute/16.0
			var offset := Vector3(cos(angle)*0.285,0,sin(angle)*0.285)
			b.rod(foot+offset+Vector3.UP*0.4,foot+offset+Vector3.UP*4.98,0.028,stone.lightened(0.055),6)
		b.disc(foot+Vector3.UP*5.05,0.37,0.16,stone,Vector3.UP,1.0,20)
		b.box(foot+Vector3.UP*5.23,Vector3(1.0,0.21,0.69),stone,1.0)
		for side in [-1.0,1.0]:
			var points: Array[Vector3] = []
			for segment in 17:
				var angle := float(segment)/16.0*TAU*1.3
				var radius := lerpf(0.17,0.025,float(segment)/16.0)
				points.append(foot+Vector3(side*0.35+cos(angle)*radius,5.21+sin(angle)*radius,0.39))
			b.tube(points,0.045,stone.lightened(0.04),6)
		_box_collision("Column",foot+Vector3.UP*2.8,Vector3(0.7,5.6,0.7))
	# Broad entablature and a quiet triangular tympanum. No building wings/walls.
	for layer in [Vector3(11.95,0.22,1.1),Vector3(12.35,0.6,1.25),Vector3(12.65,0.18,1.45)]:
		var y: float = 5.78 if layer.y<0.3 else 6.13
		if layer.x>12.6: y = 6.52
		b.box(Vector3(0,y,0),layer,stone,1.0)
	b.profile(PackedVector2Array([Vector2(-6.3,0),Vector2(6.3,0),Vector2(0,1.65)]),Vector3(0,6.64,0),1.0,stone,1.0)
	for side in [-1.0,1.0]:
		b.rod(Vector3(side*6.35,6.65,0.57),Vector3(0,8.32,0.57),0.105,stone.lightened(0.04),8)
	for index in 32:
		b.box(Vector3(-5.95+index*0.385,6.5,0.72),Vector3(0.1,0.12,0.12),stone.darkened(0.05),1.0)
	_landing_collision()
func _landing_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "PorticoSteps"
	var faces := PackedVector3Array()
	for i in TREADS.size()-1:
		var a := Vector3(-HALF_WIDTH,TREADS[i].y,TREADS[i].x)
		var c := Vector3(HALF_WIDTH,TREADS[i+1].y,TREADS[i+1].x)
		var b := Vector3(HALF_WIDTH,a.y,a.z)
		var d := Vector3(-HALF_WIDTH,c.y,c.z)
		# Godot's triangle front faces are clockwise when viewed from above.
		faces.append_array(PackedVector3Array([a,c,b,a,d,c]))
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = "StairRamp"
	collider.shape = shape
	body.add_child(collider)
	_generated(body)

func _steps(b: RefCounted, stone: Color) -> void:
	# One extruded outline, rather than overlapping boxes with coplanar tops.
	var outline := PackedVector2Array(TREADS)
	outline.append(Vector2(-3.5,-0.025))
	outline.append(Vector2(3.5,-0.025))
	var previous: Transform3D = b.frame
	b.frame = Transform3D(Basis(Vector3.UP,-PI*0.5),Vector3.ZERO)
	b.profile(outline,Vector3.ZERO,HALF_WIDTH*2.0,stone,1.0)
	b.frame = previous
