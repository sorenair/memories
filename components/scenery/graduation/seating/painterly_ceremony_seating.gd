@tool
class_name PainterlyCeremonySeating
extends PainterlyConcertComponent
const CEREMONY = preload("res://components/scenery/graduation/shared/ceremony_geometry.gd")
@export_group("Seating Layout")
@export_range(1,12,1) var rows: int = 3:
	set(value):
		rows=clampi(value,1,12)
		_request_rebuild()
## Total per row. Odd counts put the extra chair on the right side of the aisle.
@export_range(2,16,1) var seats_per_row: int = 8:
	set(value):
		seats_per_row=clampi(value,2,16)
		_request_rebuild()
@export_range(0.56,1.1,0.02) var seat_spacing: float = 0.64:
	set(value):
		seat_spacing=clampf(value,0.56,1.1)
		_request_rebuild()
@export_range(0.85,1.6,0.05) var row_spacing: float = 1.0:
	set(value):
		row_spacing=clampf(value,0.85,1.6)
		_request_rebuild()
@export_range(1.2,3.0,0.1) var aisle_width: float = 1.5:
	set(value):
		aisle_width=clampf(value,1.2,3.0)
		_request_rebuild()
@export var seat_shadows: bool = true:
	set(value):
		seat_shadows=value
		_request_rebuild()

func _validate_property(property: Dictionary) -> void:
	if property.name=="contact_shadow_enabled":
		property.usage=PROPERTY_USAGE_NO_EDITOR

## Local seat surface transforms, facing -Z toward a stage at the front of the rows.
func get_seat_transforms() -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	var left := seats_per_row/2
	for row in range(rows):
		for column in range(seats_per_row):
			var x := 0.0
			if column<left:
				x=-aisle_width*0.5-0.235-float(left-1-column)*seat_spacing
			else:
				x=aisle_width*0.5+0.235+float(column-left)*seat_spacing
			result.append(Transform3D(Basis(Vector3.UP,PI),Vector3(x,0.44,(float(row)-float(rows-1)*0.5)*row_spacing)))
	return result

func _build_geometry() -> Dictionary:
	var data: Dictionary = CEREMONY.new().folding_chair(_config())
	data.anchors={"AisleFront":Vector3(0,0,-float(rows-1)*row_spacing*0.5-0.65),"AisleRear":Vector3(0,0,float(rows-1)*row_spacing*0.5+0.65)}
	for pose in get_seat_transforms():
		data.colliders.append({"name":"Chair","center":pose.origin+Vector3(0,0.01,0),"size":Vector3(0.50,0.90,0.58)})
	return data

func _build_details() -> void:
	var source: MeshInstance3D=_generated_root.get_node("PaintedProp")
	var mesh := source.mesh
	_generated_root.remove_child(source)
	source.free()
	var shadow := _generated_root.get_node_or_null("ContactShadow")
	if shadow:
		_generated_root.remove_child(shadow)
		shadow.free()
	var seats := get_seat_transforms()
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=mesh
	batch.instance_count=seats.size()
	var bounds := AABB()
	for index in range(seats.size()):
		var pose := seats[index]
		pose.origin.y=0
		batch.set_instance_transform(index,pose)
		var extent: AABB=pose*mesh.get_aabb()
		bounds=extent if index==0 else bounds.merge(extent)
	batch.custom_aabb=bounds.grow(0.02)
	var visual := MultiMeshInstance3D.new()
	visual.name="ChairRows"
	visual.multimesh=batch
	visual.material_override=_material
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end=visibility_distance
	_generated_root.add_child(visual)
	if seat_shadows:
		var plane := PlaneMesh.new()
		plane.size=Vector2(0.64,0.66)
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=plane
		mm.instance_count=seats.size()
		for i in range(seats.size()):
			var p := seats[i]
			p.origin.y=0.009
			mm.set_instance_transform(i,p)
		var contact := MultiMeshInstance3D.new()
		contact.name="Contact_Seats"
		contact.multimesh=mm
		var paint := ShaderMaterial.new()
		paint.shader=CONTACT
		paint.set_shader_parameter("shadow_color",Color(0.31,0.32,0.31,0.16))
		contact.material_override=paint
		contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_generated_root.add_child(contact)
