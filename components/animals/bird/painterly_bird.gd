@tool
class_name PainterlyBird
extends Node3D
## A decorative, ground-idling bird. Flight is visual and does not affect physics.
signal startled(explorer: Node3D)
signal departed

enum State { IDLE, TAKING_OFF, FLYING, DEPARTED }
const PAINT = preload("res://components/animals/bird/bird.gdshader")
const SHADOW = preload("res://shaders/contact_shadow.gdshader")
const COLORS = [
	[Color("9b8064"), Color("e4d9b6"), Color("736c60")],
	[Color("798c8c"), Color("d5a17d"), Color("60777c")],
	[Color("9cb8c1"), Color("eee3c6"), Color("718f9e")],
	[Color("e3dfcf"), Color("f4eddb"), Color("b2b6ad")]
]
@export var bird_seed: int = 41:
	set(value):
		bird_seed = value
		_request_rebuild()
@export_range(0.4, 2.0, 0.05) var bird_size: float = 1.0:
	set(value):
		bird_size = value
		_request_rebuild()
@export_range(0.0, 0.4, 0.01) var ground_offset: float = 0.04:
	set(value):
		ground_offset = value
		_request_rebuild()
@export_group("Colors")
@export_enum("Sparrow", "Robin", "Bluebird", "Dove", "Custom") var palette_preset: int = 0:
	set(value):
		palette_preset = clampi(value, 0, 4)
		_request_rebuild()
@export var body_color := Color("9b8064"):
	set(value):
		body_color = value
		_request_rebuild()
@export var belly_color := Color("e4d9b6"):
	set(value):
		belly_color = value
		_request_rebuild()
@export var wing_color := Color("736c60"):
	set(value):
		wing_color = value
		_request_rebuild()
@export var beak_color := Color("c9a16a"):
	set(value):
		beak_color = value
		_request_rebuild()
@export_group("Behavior")
@export_range(0.5, 6.0, 0.1) var scare_radius: float = 1.8
@export_range(0.0, 2.0, 0.05) var idle_motion: float = 1.0
@export_range(1.0, 8.0, 0.1) var flight_speed: float = 3.5
@export_range(0.5, 5.0, 0.1) var ascent_speed: float = 1.8
@export_range(1.0, 8.0, 0.1) var flight_duration: float = 3.5
## Zero means once per memory visit; otherwise returns after this many seconds.
@export_range(0.0, 60.0, 0.5) var respawn_delay: float = 0.0
@export_tool_button("Reset bird") var reset = rebuild
var state: State = State.IDLE
var _visual: Node3D
var _wings: Array[Node3D] = []
var _shadow: MeshInstance3D
var _shadow_material: ShaderMaterial
var _queued: bool = false
var _time: float = 0.0
var _flight_time: float = 0.0
var _scan_time: float = 0.0
var _return_time: float = 0.0
var _heading: float = 0.0
var _departure_heading: float = 0.0
var _origin := Vector3.ZERO
var _direction := Vector3.FORWARD

func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for node in [_visual, _shadow]:
		if is_instance_valid(node):
			remove_child(node)
			node.free()
	_wings.clear()
	state = State.IDLE
	_flight_time = 0
	_scan_time = 0
	_time = float(posmod(bird_seed, 100)) * 0.37
	_heading = sin(float(bird_seed) * 2.1) * PI
	_visual = Node3D.new()
	_visual.name = "Bird"
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_visual, false, Node.INTERNAL_MODE_BACK)
	var colors: Array = COLORS[palette_preset] if palette_preset < 4 else [body_color, belly_color, wing_color]
	var material := ShaderMaterial.new()
	material.shader = PAINT
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	_oval(body, Vector3(0, 0.25, 0.02), Vector3(0.19, 0.22, 0.25), colors[0])
	_oval(body, Vector3(0, 0.23, -0.105), Vector3(0.153, 0.165, 0.15), colors[1])
	_oval(body, Vector3(0, 0.43, -0.12), Vector3(0.155, 0.15, 0.16), colors[0])
	for sign_x in [-1.0, 1.0]:
		_oval(body, Vector3(sign_x * 0.126, 0.458, -0.216), Vector3(0.023, 0.028, 0.022), Color("353f3d"), 8, 4)
		_oval(body, Vector3(sign_x * 0.133, 0.468, -0.229), Vector3.ONE * 0.007, Color("fff4d7"), 8, 4)
		_oval(body, Vector3(sign_x * 0.067, 0.055, -0.015), Vector3(0.018, 0.06, 0.018), beak_color, 8, 4)
		_oval(body, Vector3(sign_x * 0.067, 0.016, -0.047), Vector3(0.035, 0.014, 0.057), beak_color, 8, 4)
	var beak := CylinderMesh.new()
	beak.top_radius = 0.0
	beak.bottom_radius = 0.052
	beak.height = 0.12
	beak.radial_segments = 8
	beak.rings = 1
	_append(body, beak, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.408, -0.288)), beak_color)
	for feather in range(3):
		_oval(body, Vector3(float(feather - 1) * 0.045, 0.23, 0.295), Vector3(0.045, 0.025, 0.15), colors[2], 12, 4)
	_mesh(_visual, "Body", body.commit(), material)
	for sign_x in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "LeftWing" if sign_x < 0 else "RightWing"
		hinge.position = Vector3(sign_x * 0.14, 0.30, 0.025)
		_visual.add_child(hinge)
		var wing := SurfaceTool.new()
		wing.begin(Mesh.PRIMITIVE_TRIANGLES)
		_oval(wing, Vector3(sign_x * 0.14, 0, 0.035), Vector3(0.20, 0.035, 0.19), colors[2], 16, 6)
		_mesh(hinge, "Feathers", wing.commit(), material)
		_wings.append(hinge)
	_shadow_material = ShaderMaterial.new()
	_shadow_material.shader = SHADOW
	_shadow_material.set_shader_parameter("shadow_color", Color(0.27, 0.30, 0.25, 0.2))
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.9, 0.75) * bird_size
	_shadow = MeshInstance3D.new()
	_shadow.name = "ContactShadow"
	_shadow.mesh = plane
	_shadow.material_override = _shadow_material
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_shadow, false, Node.INTERNAL_MODE_BACK)
	set_process(true)
	_pose_idle()

func _oval(surface: SurfaceTool, center: Vector3, size: Vector3, color: Color, segments: int = 16, rings: int = 8) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = segments
	sphere.rings = rings
	_append(surface, sphere, Transform3D(Basis.IDENTITY.scaled(size), center), color)

func _append(surface: SurfaceTool, mesh: Mesh, transform: Transform3D, color: Color) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normal_basis := transform.basis.inverse().transposed()
	for index in indices:
		surface.set_normal((normal_basis * normals[index]).normalized())
		surface.set_color(color.srgb_to_linear())
		surface.add_vertex(transform * vertices[index])

func _mesh(parent: Node3D, mesh_name: String, mesh: ArrayMesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		_pose_idle()
		return
	if state == State.IDLE:
		_pose_idle()
		_scan_time -= delta
		if _scan_time <= 0:
			_scan_time = 0.12
			var closest: Node3D
			var distance := scare_radius * scare_radius
			for explorer in get_tree().get_nodes_in_group(&"explorers"):
				if explorer.get_viewport() != get_viewport():
					continue
				var offset: Vector3 = global_position - explorer.global_position
				var candidate := Vector2(offset.x, offset.z).length_squared()
				if absf(offset.y) < 2.0 and candidate < distance:
					closest = explorer
					distance = candidate
			if closest:
				flee_from(closest)
	elif state == State.DEPARTED:
		_return_time -= delta
		if _return_time <= 0:
			rebuild()
	else:
		_pose_flight(delta)

func _pose_idle() -> void:
	var breath := sin(_time * 2.1) * 0.008 * idle_motion
	var peck := pow(maxf(0.0, sin(_time * 0.65)), 14.0) * idle_motion
	_visual.position = Vector3(0, ground_offset + breath, 0)
	_visual.scale = Vector3(1, 1 + breath * 1.5, 1) * bird_size
	_visual.rotation = Vector3(peck * 0.15, _heading + sin(_time * 0.75) * 0.10 * idle_motion, sin(_time) * 0.02 * idle_motion)
	for index in range(2):
		var sign_x := -1.0 if index == 0 else 1.0
		_wings[index].rotation.z = -sign_x * (1.15 + breath)
	_shadow.position = Vector3(0, 0.016, 0)

func flee_from(explorer: Node3D) -> void:
	if state != State.IDLE or not is_instance_valid(explorer):
		return
	_origin = global_position
	_departure_heading = _visual.global_rotation.y
	_direction = _origin - explorer.global_position
	_direction.y = 0
	if _direction.length_squared() < 0.001:
		_direction = Vector3(sin(_heading), 0, cos(_heading))
	_direction = _direction.normalized().rotated(Vector3.UP, sin(float(bird_seed)) * 0.25)
	_flight_time = 0
	state = State.TAKING_OFF
	startled.emit(explorer)

func _pose_flight(delta: float) -> void:
	_flight_time += delta
	var airborne := maxf(0.0, _flight_time - 0.12)
	var launch := 1.0 - exp(-airborne * 8.0)
	state = State.TAKING_OFF if _flight_time < 0.45 else State.FLYING
	var travel := flight_speed * (airborne - (1.0 - exp(-airborne * 5.0)) / 5.0)
	var height := ascent_speed * (airborne - (1.0 - exp(-airborne * 8.0)) / 8.0) + launch * 0.12
	var sideways := Vector3(-_direction.z, 0, _direction.x) * sin(airborne * 1.8) * airborne * 0.1
	_visual.global_position = _origin + Vector3.UP * (ground_offset + height) + _direction * travel + sideways
	var heading := atan2(-_direction.x, -_direction.z)
	_visual.global_rotation = Vector3(launch * 0.22, lerp_angle(_departure_heading, heading, 1.0 - exp(-_flight_time * 12.0)), sin(airborne * 1.8) * 0.08 * launch)
	var crouch := sin(clampf(_flight_time / 0.16, 0.0, 1.0) * PI) * 0.12
	_visual.scale = Vector3(1 + crouch * 0.4, 1 - crouch, 1) * bird_size
	for index in range(2):
		var sign_x := -1.0 if index == 0 else 1.0
		_wings[index].rotation.z = -sign_x * lerpf(1.15, 0.12 + sin(airborne * 22.0) * 0.9, launch)
	_shadow.global_position = Vector3(_visual.global_position.x, _origin.y + 0.016, _visual.global_position.z)
	_shadow_material.set_shader_parameter("shadow_color", Color(0.27, 0.30, 0.25, 0.2 * maxf(0.0, 1.0 - height / 0.9)))
	_shadow.visible = height < 0.9
	if _flight_time >= flight_duration:
		state = State.DEPARTED
		_visual.hide()
		_shadow.hide()
		_return_time = respawn_delay
		set_process(respawn_delay > 0.0)
		departed.emit()
