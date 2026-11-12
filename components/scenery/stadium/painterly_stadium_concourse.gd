@tool
extends PainterlyStadiumPiece
## Small arrival landing and its narrower railed connection to the viewing bay.
@export var bridge_only := false:
	set(value):
		bridge_only = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	var concrete := Color("c9c9be")
	var rail := Color("667476")
	var maroon := Color("7a0019")
	var snow := Color("edeede")
	if bridge_only:
		b.box(Vector3(0, 0.012, 0), Vector3(2.9, 0.025, 4.6), concrete, 1.0)
		for x in [-1.5, 1.5]:
			_railing(b, Vector3(x, 0, -1.9), Vector3(x, 0, 2.5), rail)
		return
	# A distinct, intimate landing: painted slabs, a snowy bench and an opening
	# onto a narrow aisle. The shared platform supplies continuous floor collision.
	b.box(Vector3(0, 0.012, 0.25), Vector3(6.95, 0.025, 5.45), concrete, 1.0)
	for z in [-1.25, 0.25, 1.75]:
		b.box(Vector3(0, 0.028, z), Vector3(6.8, 0.012, 0.025), concrete.darkened(0.12), 1.0)
	for x in [-3.5, 3.5]:
		_railing(b, Vector3(x, 0, -2.5), Vector3(x, 0, 3.0), rail)
	_railing(b, Vector3(-3.5, 0, 3.0), Vector3(3.5, 0, 3.0), rail)
	_railing(b, Vector3(-3.5, 0, -2.5), Vector3(-1.5, 0, -2.5), rail)
	_railing(b, Vector3(1.5, 0, -2.5), Vector3(3.5, 0, -2.5), rail)
	var center := Vector3(0.8, 0, 2.25)
	b.box(center + Vector3(0, 0.46, 0), Vector3(3.8, 0.16, 0.55), maroon, 1.0)
	b.box(center + Vector3(0, 0.85, 0.25), Vector3(3.8, 0.55, 0.13), maroon, 1.0)
	b.box(center + Vector3(0, 1.15, 0.25), Vector3(3.85, 0.05, 0.18), snow, 2.0)
	for x in [-0.65, 2.25]:
		b.box(Vector3(x, 0.22, 2.25), Vector3(0.12, 0.44, 0.45), rail, 1.0)
	_box_collision("ArrivalBench", center + Vector3(0, 0.6, 0.1), Vector3(3.9, 1.2, 0.75))

func _railing(b: RefCounted, a: Vector3, c: Vector3, color: Color) -> void:
	var count := maxi(1, ceili(a.distance_to(c) / 1.5))
	b.rod(a + Vector3.UP, c + Vector3.UP, 0.045, color)
	b.rod(a + Vector3.UP * 0.45, c + Vector3.UP * 0.45, 0.03, color)
	for step in count + 1:
		var at := a.lerp(c, float(step) / count)
		b.rod(at, at + Vector3.UP, 0.035, color)
