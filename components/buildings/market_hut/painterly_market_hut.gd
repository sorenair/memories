@tool
class_name PainterlyMarketHut
extends PainterlyStadiumPiece
## Open-front wooden chalet: warm counter, snow-capped roof and distinct goods.
signal ground_exclusion_changed
const DETAILS = preload("res://components/scenery/christmas_market/market_geometry.gd")
@export_enum("Bakery", "Handcrafted Gifts", "Warm Drinks") var goods := 0:
	set(value):
		goods = clampi(value,0,2)
		_request_rebuild()
@export var wood_color := Color("977659"):
	set(value):
		wood_color = value
		_request_rebuild()
@export var trim_color := Color("586c5e"):
	set(value):
		trim_color = value
		_request_rebuild()

func _ready() -> void:
	set_notify_transform(true)
	super._ready()
func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready(): ground_exclusion_changed.emit()
func excludes_ground_point(world_point: Vector3) -> bool:
	var at := to_local(world_point)
	return absf(at.x)<1.77 and at.z>-1.5 and at.z<1.7

func _build(b: RefCounted) -> void:
	var dark := wood_color.darkened(0.32)
	var snow := Color("f2f2e9")
	# Side/back panels and the lower counter face, with restrained plank seams.
	b.soft_box(Vector3(0,1.08,-1.22),Vector3(3.2,2.16,0.16),wood_color,0.04,1.0)
	for x in [-1.55,1.55]:
		b.box(Vector3(x,1.08,0),Vector3(0.15,2.16,2.55),wood_color.darkened(0.045),1.0)
		b.box(Vector3(x,1.15,1.25),Vector3(0.18,2.3,0.18),trim_color,1.0)
	b.box(Vector3(0,0.46,1.24),Vector3(3.12,0.92,0.15),wood_color,1.0)
	for i in 12:
		var x := -1.44+i*0.26
		b.box(Vector3(x,0.45,1.326),Vector3(0.011,0.83,0.008),dark.lightened(0.12),1.0)
		b.box(Vector3(x,1.1,-1.126),Vector3(0.009,2.08,0.008),dark.lightened(0.13),1.0)
	b.box(Vector3(0,1.0,1.35),Vector3(3.45,0.13,0.58),wood_color.darkened(0.12),1.0)
	b.box(Vector3(0,1.72,-1.10),Vector3(2.85,0.11,0.4),dark,1.0)
	# Interior backing, shelves and a quiet lamp; no opaque window over the vendor.
	b.box(Vector3(0,1.5,-1.12),Vector3(2.85,0.85,0.025),Color("74624e"),1.0)
	DETAILS.person(b,Vector3(0.35,0,1.08),1.27,[0,1,6][goods],trim_color)
	for x in [-1.0,1.0]:
		b.box(Vector3(x,1.86,-0.88),Vector3(0.18,0.24,0.18),DETAILS.BULB,3.0)
		b.box(Vector3(x,2.02,-0.88),Vector3(0.24,0.045,0.24),dark,1.0)
	# Gable and two pitched roof planes. Snow follows the roof, not the floor patch.
	b.profile(PackedVector2Array([Vector2(-1.7,0),Vector2(1.7,0),Vector2(0,1.0)]),Vector3(0,2.18,0),2.8,trim_color,1.0)
	for side in [-1.0,1.0]:
		var eave: float = side*1.88
		b.quad(Vector3(0,3.23,-1.5),Vector3(eave,2.18,-1.5),Vector3(eave,2.18,1.58),Vector3(0,3.23,1.58),dark,1.0)
		var edge_points: Array[Vector2] = []
		for joint in 10:
			edge_points.append(Vector2(eave+side*b.rng.randf_range(-0.025,0.045),2.23+b.rng.randf_range(0.025,0.065)))
		for strip in 9:
			var z0 := -1.53+strip*0.35
			var z1 := z0+0.35
			var a := edge_points[strip]
			var c := edge_points[strip+1]
			b.quad(Vector3(0,3.29,z0),Vector3(a.x,a.y,z0),Vector3(c.x,c.y,z1),Vector3(0,3.29,z1),snow.lightened(b.rng.randf_range(-0.02,0.005)),1.0)
		b.rod(Vector3(0,3.2,1.6),Vector3(eave,2.16,1.6),0.065,trim_color,8)
	DETAILS.wreath(b,Vector3(0,2.65,1.44),0.25)
	DETAILS.garland(b,Vector3(0,2.2,1.48),3.1)
	for i in 6:
		var at := Vector3(-1.15+i*0.44,1.105,1.32)
		match goods:
			0:
				b.ball(at,Vector3(0.26,0.14,0.22),Color("c99c68"),1.0)
				b.rod(at+Vector3(-0.07,0.065,-0.06),at+Vector3(0.04,0.065,0.06),0.009,Color("ead5ac"),5)
			1:
				b.soft_box(at+Vector3.UP*0.08,Vector3(0.21,0.16,0.18),trim_color if i%2 else Color("aa7565"),0.018,1.0)
				b.box(at+Vector3(0,0.17,0),Vector3(0.035,0.012,0.18),DETAILS.GOLD,1.0)
			2:
				b.disc(at+Vector3.UP*0.09,0.075,0.17,Color("dcccb1"),Vector3.UP,1.0,12)
				b.disc(at+Vector3.UP*0.18,0.061,0.008,Color("6e4d3d"),Vector3.UP,1.0,12)
				b.rod(at+Vector3(0.09,0.055,0),at+Vector3(0.09,0.13,0),0.018,Color("dcccb1"),6)
	_box_collision("HutAndCounter",Vector3(0,1.6,0.1),Vector3(3.35,3.2,3.2))
	ground_exclusion_changed.emit()
