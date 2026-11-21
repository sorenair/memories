@tool
extends PainterlyVietnamPiece

const FABRIC = preload("res://components/scenery/vietnam/monuments/vietnam_flag.gdshader")

@export_range(5.0, 14.0, 0.25) var pole_height := 7.75:
	set(value):
		pole_height = clampf(value, 5.0, 14.0)
		_request_rebuild()
@export_range(1.25, 6.0, 0.05) var flag_width := 3.75:
	set(value):
		flag_width = clampf(value, 1.25, 6.0)
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var wind_strength := 0.67:
	set(value):
		wind_strength = clampf(value, 0.0, 1.0)
		if _cloth:
			_cloth.set_shader_parameter("wind_strength", wind_strength)

var _cloth: ShaderMaterial

func _build_geometry() -> Dictionary:
	var b := BUILDER.new()
	b.begin(_config())
	b.disc(Vector3(0, 0.1, 0), 0.62, 0.20, accent_color)
	b.disc(Vector3(0, 0.25, 0), 0.36, 0.16, accent_color.lightened(0.10))
	b.rod(Vector3(0, 0.24, 0), Vector3(0, pole_height, 0), 0.063, body_color, 10)
	b.disc(Vector3(0, pole_height + 0.033, 0), 0.123, 0.11, trim_color, Vector3.UP, 0, 12)
	b.collider(Vector3(0, 0.62, 0), Vector3(1.16, 1.24, 1.16), "FlagpoleBase")
	b.anchors["Flag"] = Vector3(0.075 + flag_width * 0.5, pole_height - 0.20 - flag_width / 3.0, 0)
	return b.finish()

func _build_details() -> void:
	var mesh := PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.size = Vector2(flag_width, flag_width / 1.5)
	mesh.subdivide_width = 30
	mesh.subdivide_depth = 12
	_cloth = ShaderMaterial.new()
	_cloth.shader = FABRIC
	_cloth.set_shader_parameter("wind_strength", wind_strength)
	var panel := _add_visual("FlagFabric", mesh, _cloth)
	panel.position = get_anchor(&"Flag").position
	panel.custom_aabb = mesh.get_aabb().grow(1.1)
