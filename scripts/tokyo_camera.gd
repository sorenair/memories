extends "res://scripts/follow_camera.gd"
## Stay close on paths; reveal landmark silhouettes briefly and retain fixed yaw.
@export var meiji_gate: Node3D
@export var meiji_hall: Node3D
@export var senso_gate: Node3D
@export var senso_hall: Node3D
@export var crossing: Node3D
@export var walking_size := 3.5
@export var torii_size := 8.5
@export var shrine_size := 10.5
@export var lantern_gate_size := 12.0
@export var temple_size := 12.5
@export var veranda_size := 5.5
@export var crossing_size := 9.0

func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		for gate: Node3D in [meiji_gate,senso_gate]:
			if not is_instance_valid(gate): continue
			var p := gate.to_local(at)
			var weight := (1.0-smoothstep(2.0,6.5,p.z))*smoothstep(-4.0,-1.2,p.z)
			weight *= 1.0-smoothstep(3.5,6.0,absf(p.x))
			size = lerpf(size,torii_size if gate==meiji_gate else lantern_gate_size,weight)
			var height := 2.1 if gate==meiji_gate else 3.0
			offset = offset.lerp(gate.global_position-at+Vector3(0,height,0.25),weight)
		for hall: PainterlyJapaneseHall in [meiji_hall,senso_hall]:
			if not is_instance_valid(hall): continue
			var p := hall.to_local(at)
			var front := hall.footprint.y*0.5
			var weight := (1.0-smoothstep(front+4.0,front+7.0,p.z))*smoothstep(front-0.4,front+0.4,p.z)
			weight *= 1.0-smoothstep(2.6,6.0,absf(p.x))
			var overview := smoothstep(front+0.8,front+3.4,p.z)
			var wide := shrine_size if hall==meiji_hall else temple_size
			size = lerpf(size,lerpf(veranda_size,wide,overview),weight)
			var composition := Vector3(0,1.0,-0.6).lerp(hall.global_position-at+Vector3(0,2.2,1.0),overview)
			offset = offset.lerp(composition,weight)
		if is_instance_valid(crossing):
			var p := crossing.to_local(at)
			var city := 1.0-smoothstep(12.0,17.0,Vector2(p.x,p.z).length())
			size = lerpf(size,crossing_size,city)
			offset = offset.lerp(Vector3(0,1.5,-1.5),city)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
