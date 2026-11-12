@tool
class_name PainterlyMuseumHighlight
extends PainterlyStadiumPiece
## Small sculptural studies of Mia's Jade Mountain and Kii Tokugawa armor.
## Existing boulder geometry supplies the mountain's irregular carved mass.
const STONE = preload("res://components/scenery/boulders/boulder_geometry.gd")
@export_enum("Jade Mountain", "Kii Tokugawa Armor") var exhibit: int = 0:
	set(value):
		exhibit = clampi(value,0,1)
		_request_rebuild()

func _build(b: RefCounted) -> void:
	if exhibit==0: _jade(b)
	else: _armor(b)

func _plinth(b: RefCounted, width: float, depth: float, height: float) -> void:
	var stone := Color("c7c1af")
	b.soft_box(Vector3(0,height*0.5,0),Vector3(width,height,depth),stone,0.045,1.0)
	b.box(Vector3(0,height+0.035,0),Vector3(width+0.08,0.07,depth+0.08),stone.lightened(0.045),1.0)

func _carved_mass(b: RefCounted, at: Vector3, size: Vector3, seed: int, jade: Color) -> void:
	var mesh := STONE.create_mesh(seed,Vector3.ONE,0.8,0.08,0.0,STONE.Profile.WEATHERED,0.65)
	var bounds := mesh.get_aabb()
	var scale := size/bounds.size
	var basis := Basis.IDENTITY.scaled(scale)
	b.append(mesh,Transform3D(basis,at-basis*bounds.get_center()),jade,1.0)

func _jade(b: RefCounted) -> void:
	var jade := Color("b8c7aa")
	_plinth(b,3.8,1.65,0.85)
	_carved_mass(b,Vector3(0,1.83,-0.07),Vector3(2.5,1.82,0.95),4324,jade)
	_carved_mass(b,Vector3(-1.17,1.37,0),Vector3(1.12,0.88,0.95),29,jade.darkened(0.025))
	_carved_mass(b,Vector3(1.23,1.42,0),Vector3(0.9,1.03,0.87),43,jade.darkened(0.035))
	# Quiet relief: stream, winding path, cypresses and a two-tier pavilion.
	var light := jade.lightened(0.1)
	var stream: Array[Vector3] = [Vector3(-1.5,1.03,0.45),Vector3(-0.65,1.08,0.52),Vector3(0.1,1.05,0.52),Vector3(1.45,1.11,0.43)]
	b.tube(stream,0.026,light,6)
	for i in 6:
		b.box(Vector3(-1.28+i*0.065,1.1+i*0.075,0.48),Vector3(0.23,0.035,0.13),light,1.0)
	for at in [Vector3(-0.7,1.36,0.49),Vector3(1.3,1.23,0.43)]:
		b.rod(at,at+Vector3(0.04,0.61,-0.02),0.024,light,6)
		for branch in 4:
			b.ball(at+Vector3((0.1 if branch%2==0 else -0.08),0.24+branch*0.12,0),Vector3(0.34,0.11,0.19),jade.lightened(0.055),1.0)
	for tier in 2:
		var y := 1.18+tier*0.37
		b.box(Vector3(0.6,y,0.55),Vector3(0.74,0.055,0.35),light,1.0)
		for x in [0.32,0.87]:
			b.rod(Vector3(x,y,0.62),Vector3(x,y+0.27,0.62),0.021,light,6)
		b.profile(PackedVector2Array([Vector2(-0.45,0),Vector2(0.45,0),Vector2(0,0.15)]),Vector3(0.6,y+0.28,0.55),0.42,light,1.0)
	for x in [-0.25,0.1,0.95]:
		b.ball(Vector3(x,1.16,0.61),Vector3(0.075,0.16,0.065),light,1.0)
		b.ball(Vector3(x,1.28,0.61),Vector3.ONE*0.065,light,1.0)
	_box_collision("JadePedestal",Vector3(0,1.4,0),Vector3(3.9,2.8,1.75))

func _armor(b: RefCounted) -> void:
	var lacquer := Color("363d42")
	var red := Color("955b48")
	var gold := Color("c7ae71")
	var blue := Color("465666")
	_plinth(b,1.9,1.6,0.3)
	# Seated armor: separate laced chest plates, flared skirt and fur boots.
	b.soft_box(Vector3(0,0.77,-0.12),Vector3(0.85,0.82,0.7),Color("695a4c"),0.04,1.0)
	for side in [-1.0,1.0]:
		b.ball(Vector3(side*0.34,0.43,0.37),Vector3(0.35,0.22,0.54),lacquer,1.0)
		b.rod(Vector3(side*0.33,0.52,0.29),Vector3(side*0.36,1.04,0.22),0.12,red,10)
		b.ball(Vector3(side*0.33,1.05,0.23),Vector3(0.35,0.19,0.36),blue,1.0)
		b.rod(Vector3(side*0.5,1.98,0),Vector3(side*0.7,1.42,0.05),0.13,red,10)
		b.rod(Vector3(side*0.7,1.42,0.05),Vector3(side*0.45,1.13,0.32),0.1,lacquer,10)
		b.ball(Vector3(side*0.45,1.11,0.32),Vector3(0.2,0.12,0.22),lacquer,1.0)
		for row in 5:
			b.soft_box(Vector3(side*(0.5+row*0.025),1.9-row*0.085,0),Vector3(0.3,0.07,0.5),red if row%2 else lacquer,0.015,1.0)
		for row in 6:
			b.box(Vector3(side*0.51,1.16-row*0.075,0.27),Vector3(0.27,0.064,0.24),red,1.0)
	for row in 10:
		var y := 1.22+row*0.073
		var width := 0.88-absf(row-5)*0.017
		b.soft_box(Vector3(0,y,0),Vector3(width,0.062,0.53),lacquer,0.014,1.0)
		b.rod(Vector3(-width*0.45,y,0.284),Vector3(width*0.45,y,0.284),0.012,gold,6)
		for x in [-0.3,-0.22,0.22,0.3]:
			b.ball(Vector3(x,y,0.293),Vector3(0.023,0.045,0.018),red if row%2 else blue,1.0)
	b.ball(Vector3(0,2.12,0),Vector3(0.4,0.39,0.37),lacquer,1.0)
	b.ball(Vector3(0,2.09,0.19),Vector3(0.32,0.17,0.1),lacquer.lightened(0.05),1.0)
	# Broad helmet skirt and the reference's upright, split gold crest.
	for row in 3:
		b.disc(Vector3(0,2.21+row*0.065,-0.02),0.4-row*0.04,0.055,lacquer,Vector3.UP,1.0,16)
	b.ball(Vector3(0,2.48,-0.035),Vector3(0.51,0.45,0.45),lacquer,1.0)
	for side in [-1.0,1.0]:
		b.profile(PackedVector2Array([Vector2(0,0),Vector2(side*0.24,0.55),Vector2(side*0.16,0.62),Vector2(side*0.055,0.16)]),Vector3(0,2.43,0.24),0.035,gold,1.0)
	b.disc(Vector3(0,2.6,0.28),0.055,0.035,gold,Vector3.BACK,1.0,10)
	_box_collision("ArmorPedestal",Vector3(0,1.55,0),Vector3(1.95,3.1,1.65))
