@tool
class_name PainterlyGraduateCrowd
extends PainterlyCrowd
## Existing crowd, with academic regalia and optional exact chair-row occupancy.
const ACADEMIC = preload("res://components/scenery/graduation/shared/academic_geometry.gd")
enum SeatingSide { ALL, LEFT, RIGHT }
@export_group("Academic Regalia")
@export var gown_color := Color("4c626e"):
	set(value):
		gown_color=value
		_apply_paint()
@export var cap_matches_gown := true:
	set(value):
		cap_matches_gown=value
		_apply_paint()
@export var cap_color := Color("ede9df"):
	set(value):
		cap_color=value
		_apply_paint()
@export var stole_color := Color("d0af70"):
	set(value):
		stole_color=value
		_apply_paint()
@export var tassel_color := Color("ead49a"):
	set(value):
		tassel_color=value
		_apply_paint()
## Assign a ceremony seating component to fill its seats, in order, up to Count.
## Clear this reference to use the inherited standing gathering/row layouts.
@export var seating: Node3D:
	set(value):
		if is_instance_valid(seating) and seating.has_signal("ground_exclusion_changed") and seating.ground_exclusion_changed.is_connected(_request_rebuild):
			seating.ground_exclusion_changed.disconnect(_request_rebuild)
		seating=value
		_bind_seating()
		_request_rebuild()
## Left/right use the chair block's local X, including when it is moved or rotated.
@export var seating_side: SeatingSide = SeatingSide.ALL:
	set(value):
		seating_side=value
		_request_rebuild()
var _seat_poses: Array[Transform3D]=[]

func _ready() -> void:
	set_notify_transform(true)
	_bind_seating()
	super._ready()

func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready() and is_instance_valid(seating):
		_request_rebuild()

func _bind_seating() -> void:
	if is_instance_valid(seating) and seating.has_method("get_seat_transforms") and seating.has_signal("ground_exclusion_changed") and not seating.ground_exclusion_changed.is_connected(_request_rebuild):
		seating.ground_exclusion_changed.connect(_request_rebuild)

func _validate_property(property: Dictionary) -> void:
	if property.name in ["palette","clothing_colors"]:
		property.usage=PROPERTY_USAGE_NO_EDITOR

func _apply_paint() -> void:
	super._apply_paint()
	if _material:
		_material.set_shader_parameter("gown_color",gown_color)
		_material.set_shader_parameter("cap_color",gown_color if cap_matches_gown else cap_color)
		_material.set_shader_parameter("stole_color",stole_color)
		_material.set_shader_parameter("tassel_color",tassel_color)
		_material.set_shader_parameter("seated_posture",is_instance_valid(seating) and seating.has_method("get_seat_transforms"))
		for suffix in ["a","b","c","d"]:
			_material.set_shader_parameter("clothing_"+suffix,gown_color.darkened(0.12))
		if is_instance_valid(seating) and seating.has_method("get_seat_transforms"):
			# Fixed leg/torso proportions keep the hip on its chair. Cached body/head
			# shapes, width, complexion, hair and independent poses still vary.
			_material.set_shader_parameter("silhouette_variation",0.0)

func _body_mesh(variant: int) -> ArrayMesh:
	return ACADEMIC.body(variant)

func _head_mesh(variant: int) -> ArrayMesh:
	return ACADEMIC.head(variant)

func _pose_options() -> Array:
	return [0,1,5,8] if not _seat_poses.is_empty() else super._pose_options()

func _standing_points(rng: RandomNumberGenerator) -> PackedVector2Array:
	_seat_poses.clear()
	if not is_instance_valid(seating) or not seating.has_method("get_seat_transforms"):
		return super._standing_points(rng)
	var points := PackedVector2Array()
	var from_seating := global_transform.affine_inverse()*seating.global_transform
	for seat: Transform3D in seating.get_seat_transforms():
		if seating_side==SeatingSide.LEFT and seat.origin.x>=0: continue
		if seating_side==SeatingSide.RIGHT and seat.origin.x<=0: continue
		var local := from_seating*seat
		_seat_poses.append(local)
		points.append(Vector2(local.origin.x,local.origin.z))
	return points

func _person_transform(point: Vector2, index: int, rng: RandomNumberGenerator) -> Transform3D:
	if _seat_poses.is_empty():
		return super._person_transform(point,index,rng)
	var pose := _seat_poses[index]
	var width := person_scale*rng.randf_range(1.0-build_variation,1.0+build_variation)
	pose.basis=pose.basis.scaled(Vector3(width,person_scale,width))
	# Shader's seated hip is y=.32. Seat height therefore follows chair dimensions.
	pose.origin.y-=person_scale*0.32
	return pose

func _rebuild_hitboxes() -> void:
	super._rebuild_hitboxes()
	if _seat_poses.is_empty():
		return
	for index in range(_hitbox_shapes.size()):
		var collider := _hitbox_shapes[index]
		var capsule := collider.shape as CapsuleShape3D
		capsule.height=maxf(capsule.radius*2,capsule.height-person_scale*0.21)
		collider.position.y=_placements[index].origin.y+capsule.height*0.5

func _add_batch(batch_name: String, mesh: Mesh, material: Material, instances: Array) -> void:
	super._add_batch(batch_name,mesh,material,instances)
	var batch: MultiMeshInstance3D=_generated.get_child(-1)
	# Seated knees extend forward beyond the standing mesh's bounds.
	batch.custom_aabb=batch.custom_aabb.grow(0.15*person_scale)

func _get_configuration_warnings() -> PackedStringArray:
	if is_instance_valid(seating):
		if not seating.has_method("get_seat_transforms"):
			return PackedStringArray(["Seating must reference a PainterlyCeremonySeating component."])
		if generated_count<count:
			return PackedStringArray(["%d graduates fit the assigned chair rows (requested %d)."%[generated_count,count]])
		return PackedStringArray()
	return super._get_configuration_warnings()
