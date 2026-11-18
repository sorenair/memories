@tool
class_name PainterlyCoastalHeadland
extends PainterlyVietnamPiece
const COAST = preload("res://components/scenery/vietnam/shared/southern_geometry.gd")
## Optional existing walk surfaces. The rock shoulders rise underneath their tread.
@export var ridge_routes: Array[PainterlyCurvedPath] = []:
	set(value):
		for route in ridge_routes:
			if is_instance_valid(route) and route.ground_exclusion_changed.is_connected(_request_rebuild):
				route.ground_exclusion_changed.disconnect(_request_rebuild)
		ridge_routes = value
		_watch_routes()
		_request_rebuild()
@export var footprint := Vector2(11,8):
	set(value):
		footprint = value.clamp(Vector2(6,5),Vector2(20,16))
		_request_rebuild()
@export_range(1.5,7.0,0.25) var cliff_height := 3.2:
	set(value):
		cliff_height = clampf(value,1.5,7)
		_request_rebuild()

func _ready() -> void:
	super._ready()
	_watch_routes()

func _watch_routes() -> void:
	if not is_inside_tree():
		return
	for route in ridge_routes:
		if is_instance_valid(route) and not route.ground_exclusion_changed.is_connected(_request_rebuild):
			route.ground_exclusion_changed.connect(_request_rebuild)

var _ridge_faces := PackedVector3Array()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"cliff_height":cliff_height})
	var ridges: Array[PackedVector3Array] = []
	for route in ridge_routes:
		if not is_instance_valid(route) or not route.curve:
			continue
		var ridge := PackedVector3Array()
		for point in route.get_route_points(0.0, 1.0, 0.9, 0.0):
			ridge.append(to_local(point))
		ridges.append(ridge)
	c.ridges = ridges
	var result: Dictionary = COAST.new().headland(c)
	_ridge_faces = result.ridge_faces
	return result

func _build_details() -> void:
	if not collision_enabled or _ridge_faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(_ridge_faces)
	var body := StaticBody3D.new()
	body.name = "RockRidges"
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	_generated_root.add_child(body)
