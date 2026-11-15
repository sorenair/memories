@tool
class_name PainterlyAdirondackChair
extends PainterlyConservatoryPiece
## Ground-centered, front +Z. Wide arms, low raked seat and a fanned slat back.
@export var chair_color := Color("7b8983"):
	set(value):
		chair_color = value
		_request_rebuild()
@export_range(0.6,0.95,0.05) var seat_width := 0.75:
	set(value):
		seat_width = value
		_request_rebuild()
@export_range(0.65,1.05,0.05) var back_height := 0.82:
	set(value):
		back_height = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	var w := seat_width
	# Two broad runners and front legs make the silhouette read from above.
	for side: float in [-1.0,1.0]:
		b.rod(Vector3(side*w*0.46,0.065,-0.56),Vector3(side*w*0.46,0.42,0.40),0.055,chair_color,8)
		b.soft_box(Vector3(side*w*0.55,0.31,0.32),Vector3(0.075,0.58,0.085),chair_color,0.018)
		b.soft_box(Vector3(side*w*0.57,0.64,0.02),Vector3(0.21,0.065,0.94),chair_color.lightened(0.04),0.035)
		b.rod(Vector3(side*w*0.46,0.46,-0.38),Vector3(side*w*0.57,0.61,-0.29),0.036,chair_color,8)
	# Sloping seat: each wide slat follows the same gentle backward rake.
	for slat in 5:
		var z := lerpf(-0.34,0.36,float(slat)/4.0)
		b.box(Vector3(0,0.36+(z+0.34)*0.10,z),Vector3(w,0.045,0.16),chair_color.lightened(b.rng.randf_range(-0.025,0.025)),0,Basis(Vector3.RIGHT,-0.10))
	# Five tapered, slightly splayed back boards and a rounded fan crest.
	for slat in 5:
		var u := float(slat-2)/2.0
		var h := back_height*(1.0-absf(u)*0.10)
		b.frame = Transform3D(Basis(Vector3.RIGHT,-0.24)*Basis(Vector3.BACK,-u*0.055),Vector3(u*w*0.19,0.35,-0.35))
		var half := w*0.105
		var points := PackedVector2Array([Vector2(-half,0),Vector2(half,0),Vector2(half,h-0.035),Vector2(half-0.025,h),Vector2(-half+0.025,h),Vector2(-half,h-0.035)])
		b.profile(points,Vector3.ZERO,0.043,chair_color.lightened(b.rng.randf_range(-0.035,0.035)))
	b.frame = Transform3D.IDENTITY
	b.box(Vector3(0,0.47,-0.38),Vector3(w*1.05,0.065,0.06),chair_color.darkened(0.08))
	_box_collision("ChairBody",Vector3(0,0.55,-0.04),Vector3(w*1.45,1.10,1.18))
	_anchor("Front",Vector3(0,0,1.05))

func _build_layers() -> void:
	_contact(Vector2(seat_width*1.7,1.45))

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return absf(p.x)<seat_width*0.72 and absf(p.z+0.04)<0.6
