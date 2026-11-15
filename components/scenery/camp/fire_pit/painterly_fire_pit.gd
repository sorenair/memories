@tool
class_name PainterlyFirePit
extends PainterlyConservatoryPiece
## Low open steel ring with logs and optional half grate. Fire is a reused child.
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
@export_range(0.45,1.0,0.05) var radius := 0.68:
	set(value):
		radius = value
		_request_rebuild()
@export var metal_color := Color("514d48"):
	set(value):
		metal_color = value
		_request_rebuild()
@export var grill_enabled := true:
	set(value):
		grill_enabled = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	var profile: Array[Vector2] = [Vector2(radius,0.07),Vector2(radius,0.35),Vector2(radius-0.045,0.35),Vector2(radius-0.045,0.10)]
	TURNED.lathe(b,profile,metal_color,0,48)
	b.disc(Vector3(0,0.12,0),radius-0.055,0.03,Color("44413e"),Vector3.UP,0,32)
	for i in 3:
		var angle := TAU*i/3.0
		b.soft_box(Vector3(cos(angle)*radius*0.76,0.055,sin(angle)*radius*0.76),Vector3(0.10,0.11,0.12),metal_color,0.015)
	for i in 4:
		var a := i*1.9
		var axis := Vector3(cos(a),0,sin(a))
		b.rod(-axis*radius*0.57+Vector3.UP*(0.16+i*0.018),axis*radius*0.57+Vector3.UP*(0.18+i*0.018),0.07,Color("76634f"),8)
	if grill_enabled:
		for i in 6:
			var x := lerpf(-radius*0.82,-radius*0.10,float(i)/5.0)
			var span := sqrt(radius*radius-x*x)*0.90
			b.rod(Vector3(x,0.395,-span),Vector3(x,0.395,span),0.015,metal_color.lightened(0.12),6)
		b.rod(Vector3(-radius*0.77,0.38,0),Vector3(-radius*0.1,0.38,0),0.018,metal_color,6)
		b.rod(Vector3(-radius*0.86,0.3,-radius*0.55),Vector3(-radius*0.86,0.62,-radius*0.55),0.018,metal_color,6)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "PitCollision"
		var shape := CylinderShape3D.new()
		shape.radius = radius+0.05
		shape.height = 0.65
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position.y = 0.325
		body.add_child(collider)
		_generated(body)
	_anchor("FireBase",Vector3(0,0.21,0))
	_anchor("Approach",Vector3(0,0,radius+0.9))

func _build_layers() -> void:
	_contact(Vector2.ONE*radius*2.8)

func _sync_recall() -> void:
	super._sync_recall()
	var fire := get_node_or_null("Fire")
	if fire:
		fire.recall_anchor = recall_anchor
		fire.recall_enabled = recall_enabled

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return Vector2(p.x,p.z).length()<radius+0.08
