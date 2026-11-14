@tool
class_name PainterlyGreenhouseFrame
extends PainterlyConservatoryPiece
## A few open barrel-vault ribs recall the glasshouse without hiding exploration.
@export var footprint := Vector2(12,8):
	set(value):
		footprint = value.clamp(Vector2(5,3),Vector2(18,18))
		_request_rebuild()
@export_range(2.5,6.0,0.1) var eave_height := 3.4:
	set(value):
		eave_height = value
		_request_rebuild()
@export_range(1.0,4.5,0.1) var roof_rise := 2.8:
	set(value):
		roof_rise = value
		_request_rebuild()
@export_range(2,5,1) var rib_count := 3:
	set(value):
		rib_count = value
		_request_rebuild()
@export var frame_color := Color("9ebfba"):
	set(value):
		frame_color = value
		_request_rebuild()
## Omit the near/east half of the vault for the inherited three-quarter camera.
@export var open_view_side := true:
	set(value):
		open_view_side = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	for rib in rib_count:
		var z := lerpf(-footprint.y*0.5,footprint.y*0.5,float(rib)/(rib_count-1))
		for side in [-1.0,1.0]:
			if open_view_side and side>0.0: continue
			var post := Vector3(side*footprint.x*0.5,0,z)
			b.rod(post,post+Vector3.UP*eave_height,0.055,frame_color,8)
			if collision_enabled:
				_box_collision("Post_%s_%s" % [rib,side],post+Vector3.UP*eave_height*0.5,Vector3(0.14,eave_height,0.14))
		var arch: Array[Vector3] = []
		for step in range(16 if open_view_side else 0,33):
			var angle := PI*step/32.0
			arch.append(Vector3(cos(angle)*footprint.x*0.5,eave_height+sin(angle)*roof_rise,z))
		b.tube(arch,0.045,frame_color,8)
	# Only five thin longitudinal members: no opaque roof or full enclosing shell.
	for step: int in ([16,20,24,28,32] if open_view_side else [0,8,16,24,32]):
		var angle := PI*step/32.0
		var at := Vector3(cos(angle)*footprint.x*0.5,eave_height+sin(angle)*roof_rise,0)
		b.rod(at+Vector3.FORWARD*footprint.y*0.5,at+Vector3.BACK*footprint.y*0.5,0.028,frame_color,6)
	_anchor("Center",Vector3(0,0,0))
