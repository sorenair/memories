@tool
class_name PainterlyBird
extends Node3D
## A painted silhouette for ground, departing, or circling birds.
signal startled(explorer: Node3D)
signal departed

enum State { IDLE, TAKING_OFF, FLYING, DEPARTED, CIRCLING }
enum Behavior { GROUND, FLEE_ON_APPROACH, CIRCLING }
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/animals/bird/bird.gdshader")
const SHADOW = preload("res://shaders/contact_shadow.gdshader")
const COLORS = [
	[Color("9b8064"), Color("e4d9b6"), Color("736c60")],
	[Color("798c8c"), Color("d5a17d"), Color("60777c")],
	[Color("9cb8c1"), Color("eee3c6"), Color("718f9e")],
	[Color("e3dfcf"), Color("f4eddb"), Color("b2b6ad")],
	[], # Custom keeps its original serialized index.
	[Color("efece3"), Color("f6f3ec"), Color("e1ded7")],
	[Color("272631"), Color("33313c"), Color("23232d")]
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
@export_enum("Sparrow", "Robin", "Bluebird", "Dove", "Custom", "White", "Black") var palette_preset: int = 6:
	set(value):
		palette_preset = clampi(value, 0, COLORS.size() - 1)
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
## Ground birds can still fly away when take_off(direction) is called.
@export var behavior: Behavior = Behavior.FLEE_ON_APPROACH:
	set(value):
		behavior = value
		_request_rebuild()
@export_range(0.0, 1.5, 0.05) var hop_radius := 0.38
@export_range(0.5, 25.0, 0.1) var circle_radius := 4.5
@export_range(0.5, 25.0, 0.1) var circle_height := 5.0
@export_range(0.5, 6.0, 0.1) var scare_radius: float = 1.8
@export_range(0.0, 2.0, 0.05) var idle_motion: float = 1.0
@export_range(1.0, 8.0, 0.1) var flight_speed: float = 3.5
@export_range(0.5, 5.0, 0.1) var ascent_speed: float = 1.8
## Minimum flight time. A bird still in the camera continues until it clears the frame.
@export_range(1.0, 8.0, 0.1) var flight_duration: float = 3.5
## Zero means once per memory visit; otherwise returns after this many seconds.
@export_range(0.0, 60.0, 0.5) var respawn_delay: float = 0.0
@export_tool_button("Reset bird") var reset = rebuild
var state: State = State.IDLE
var _visual: Node3D
var _wings: Array[Node3D] = []
var _feet: MeshInstance3D
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
var _circle_angle := 0.0

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
	state = State.CIRCLING if behavior == Behavior.CIRCLING else State.IDLE
	_circle_angle = fposmod(float(bird_seed) * 2.399963, TAU)
	_flight_time = 0
	_scan_time = 0
	_time = float(posmod(bird_seed, 100)) * 0.37
	_heading = sin(float(bird_seed) * 2.1) * PI
	_visual = Node3D.new()
	_visual.name = "Bird"
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_visual, false, Node.INTERNAL_MODE_BACK)
	var colors: Array = [body_color, belly_color, wing_color] if palette_preset == 4 else COLORS[palette_preset]
	var detail: Color = colors[2] if palette_preset >= 5 else beak_color
	var material := ShaderMaterial.new()
	material.shader = PAINT
	var body := GEOMETRY.new()
	body.s = SurfaceTool.new()
	body.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One continuous surface carries the crown, throat, breast and beak.
	_body_form(body, colors[0], colors[1], detail)
	_brush_form(body, PackedVector2Array([
		Vector2(-0.075, 0.09), Vector2(0.075, 0.09),
		Vector2(0.105, 0.38), Vector2(0.073, 0.43), Vector2(0.0, 0.356),
		Vector2(-0.073, 0.43), Vector2(-0.105, 0.38)
	]), Vector3(0, 0.20, 0), colors[2], 0.015)
	_mesh(_visual, "Body", body.s.commit(), material)
	var feet := GEOMETRY.new()
	feet.s = SurfaceTool.new()
	feet.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		var ankle := Vector3(side * 0.065, 0.024, 0.019)
		_tapered_stroke(feet, [Vector3(side * 0.053, 0.131, 0.027),
			Vector3(side * 0.060, 0.071, 0.036), ankle],
			[0.017, 0.011, 0.008], detail)
		for toe in [-1.0, 0.0, 1.0]:
			var spread := Vector3(toe * 0.025, 0, -0.064 + absf(toe) * 0.015)
			_tapered_stroke(feet, [ankle, ankle + spread * 0.55 - Vector3.UP * 0.009,
				ankle + spread - Vector3.UP * 0.011], [0.007, 0.005, 0.0015], detail)
		_tapered_stroke(feet, [ankle, ankle + Vector3(side * 0.010, -0.008, 0.034)],
			[0.007, 0.0018], detail)
	_feet = _mesh(_visual, "Feet", feet.s.commit(), material)
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "LeftWing" if side < 0 else "RightWing"
		hinge.position = Vector3(side * 0.075, 0.255, -0.02)
		_visual.add_child(hinge)
		var wing := GEOMETRY.new()
		wing.s = SurfaceTool.new()
		wing.s.begin(Mesh.PRIMITIVE_TRIANGLES)
		var outline := PackedVector2Array([
			Vector2(-0.045, -0.12), Vector2(0.16, -0.17),
			Vector2(0.36, -0.135), Vector2(0.61, -0.045),
			Vector2(0.78, 0.048), Vector2(0.61, 0.091),
			Vector2(0.65, 0.125), Vector2(0.46, 0.129),
			Vector2(0.32, 0.185), Vector2(0.11, 0.168), Vector2(-0.044, 0.11)
		])
		if side < 0.0:
			for index in outline.size():
				outline[index].x *= -1.0
			outline.reverse()
		_brush_form(wing, outline, Vector3.ZERO, colors[2], 0.055, colors[0])
		_mesh(hinge, "Feathers", wing.s.commit(), material)
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
	if state == State.CIRCLING:
		_pose_circle(0.0)
	else:
		_pose_idle()

func _body_form(builder: RefCounted, back: Color, breast: Color, beak: Color) -> void:
	# Each station is Z, center Y, horizontal radius, vertical radius.
	var profile := [
		Vector4(-0.35, 0.286, 0.001, 0.001), Vector4(-0.295, 0.289, 0.031, 0.014),
		Vector4(-0.236, 0.296, 0.073, 0.053), Vector4(-0.154, 0.276, 0.098, 0.105),
		Vector4(-0.081, 0.228, 0.113, 0.119), Vector4(0.020, 0.202, 0.132, 0.121),
		Vector4(0.115, 0.197, 0.117, 0.098), Vector4(0.218, 0.195, 0.064, 0.051),
		Vector4(0.285, 0.196, 0.001, 0.001)]
	var spine := PackedVector4Array()
	for index in profile.size() - 1:
		var start: Vector4 = profile[index]
		var end: Vector4 = profile[index + 1]
		var prior: Vector4 = profile[maxi(0, index - 1)]
		var next: Vector4 = profile[mini(profile.size() - 1, index + 2)]
		for sample in 3:
			var t := float(sample) / 3.0
			var dimensions := Vector3(start.y, start.z, start.w).cubic_interpolate(
				Vector3(end.y, end.z, end.w), Vector3(prior.y, prior.z, prior.w),
				Vector3(next.y, next.z, next.w), t)
			spine.append(Vector4(lerpf(start.x, end.x, t), dimensions.x,
				maxf(0.001, dimensions.y), maxf(0.001, dimensions.z)))
	spine.append(profile.back())
	for row in spine.size() - 1:
		for side in 20:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
					Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var index: int = row + corner.x
				var angle := TAU * float(side + corner.y) / 20.0
				var station := spine[index]
				var tangent := _profile_point(spine[mini(index + 1, spine.size() - 1)], angle) 					- _profile_point(spine[maxi(index - 1, 0)], angle)
				var around := Vector3(-sin(angle) * station.z, cos(angle) * station.w, 0)
				var normal := around.cross(tangent).normalized()
				var throat := smoothstep(0.1, 0.95, -sin(angle)) * (1.0 - smoothstep(0.02, 0.25, station.x))
				if palette_preset >= 5:
					throat *= 0.36
				var color := back.lerp(breast, throat).lerp(beak, 1.0 - smoothstep(-0.305, -0.245, station.x))
				builder.vertex(_profile_point(station, angle), normal, color, 1.0)

func _profile_point(station: Vector4, angle: float) -> Vector3:
	return Vector3(cos(angle) * station.z, station.y + sin(angle) * station.w, station.x)

func _brush_form(builder: RefCounted, outline: PackedVector2Array, center: Vector3,
		color: Color, thickness: float, root_color := Color.TRANSPARENT) -> void:
	var edge: PackedVector2Array = builder.smooth_outline(outline, true, 3)
	var hub := Vector2.ZERO
	for point in edge:
		hub += point
	hub /= edge.size()
	# A rounded brush shape has a soft crown and thins to a feather edge.
	for face in [-1.0, 1.0]:
		for ring in 3:
			for index in edge.size():
				for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
						Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					var t := float(ring + corner.x) / 3.0
					var outward := edge[(index + corner.y) % edge.size()] - hub
					var point := hub + outward * t
					var dome := 1.0 - t * t
					var normal := Vector3(outward.x * t * 0.8, face, outward.y * t * 0.8).normalized()
					var pigment := root_color.lerp(color, smoothstep(0.04, 0.40, absf(point.x))) if root_color.a > 0 else color
					builder.vertex(center + Vector3(point.x, face * thickness * 0.5 * dome, point.y),
						normal, pigment, 1.0 - smoothstep(0.04, 0.34, absf(point.x)))

func _tapered_stroke(builder: RefCounted, points: Array[Vector3], radii: Array[float], color: Color) -> void:
	for section in points.size() - 1:
		for side in 6:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
					Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var index: int = section + corner.x
				var tangent := (points[mini(index + 1, points.size() - 1)] - points[maxi(0, index - 1)]).normalized()
				var radial := tangent.cross(Vector3.RIGHT).normalized()
				var normal := radial.rotated(tangent, TAU * (side + corner.y) / 6.0)
				builder.vertex(points[index] + normal * radii[index], normal, color)

func _mesh(parent: Node3D, mesh_name: String, mesh: ArrayMesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _process(delta: float) -> void:
	_time += delta
	if state == State.CIRCLING:
		_pose_circle(delta)
		return
	if Engine.is_editor_hint():
		_pose_idle()
		return
	if state == State.IDLE:
		_pose_idle()
		if behavior != Behavior.FLEE_ON_APPROACH:
			return
		_scan_time -= delta
		if _scan_time <= 0:
			_scan_time = 0.12
			var closest: Node3D
			var distance := scare_radius * scare_radius
			for explorer in get_tree().get_nodes_in_group(&"explorers"):
				if explorer.get_viewport() != get_viewport():
					continue
				var offset: Vector3 = _visual.global_position - explorer.global_position
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
	var hop_clock := _time / 2.25
	var step := floorf(hop_clock)
	var hop := clampf(fposmod(hop_clock, 1.0) / 0.17, 0.0, 1.0)
	var start_angle := step * 2.4
	var end_angle := (step + 1.0) * 2.4
	var start := Vector3(cos(start_angle), 0, sin(start_angle))
	var end := Vector3(cos(end_angle), 0, sin(end_angle))
	var offset := start.lerp(end, smoothstep(0, 1, hop)) * hop_radius * minf(idle_motion, 1.0)
	var lift := sin(hop * PI) * 0.095 * idle_motion if hop_radius > 0.0 else 0.0
	_visual.position = offset + Vector3.UP * (ground_offset + breath + lift)
	_visual.scale = Vector3(1, 1 + breath * 1.5, 1) * bird_size
	var heading := _heading
	if hop_radius > 0.0 and idle_motion > 0.0:
		var previous := Vector3(cos(start_angle - 2.4), 0, sin(start_angle - 2.4))
		heading = lerp_angle(_flight_heading(start - previous), _flight_heading(end - start), smoothstep(0, 0.68, hop))
	_visual.rotation = Vector3(peck * 0.18 - lift, heading + sin(_time * 0.75) * 0.10 * idle_motion, 0)
	_pose_wings(0.0, 0.0)
	_shadow.position = offset + Vector3.UP * 0.016

func _pose_wings(spread: float, phase: float, strength: float = 1.0) -> void:
	_feet.visible = spread < 0.7
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var stroke := sin(phase + index * 0.08) * 0.88 * strength + 0.12
		_wings[index].scale.x = lerpf(0.58, 1.0, spread)
		_wings[index].rotation = Vector3(0, -side * lerpf(1.26, 0.0, spread),
			side * lerpf(-0.18, stroke, spread))

func _flight_heading(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)

func _pose_circle(delta: float) -> void:
	_circle_angle = fposmod(_circle_angle + delta * flight_speed / maxf(circle_radius, 0.5), TAU)
	var t := _circle_angle
	_visual.position = Vector3(cos(t) * circle_radius,
		circle_height + sin(t * 2.0) * 0.19, sin(t) * circle_radius)
	_visual.rotation = Vector3(0.04, _flight_heading(Vector3(-sin(t), 0, cos(t))), 0.24)
	_visual.scale = Vector3.ONE * bird_size
	# Several beats followed by a short banked glide.
	_pose_wings(1.0, _time * 16.0, smoothstep(-0.48, 0.3, sin(_time * 1.4)))
	_shadow.hide()

func flee_from(explorer: Node3D) -> void:
	if not is_instance_valid(explorer):
		return
	var away := _visual.global_position - explorer.global_position if is_instance_valid(_visual) else Vector3.ZERO
	if take_off(away.rotated(Vector3.UP, sin(float(bird_seed)) * 0.25)):
		startled.emit(explorer)

## Start a one-way departure in a world-space direction from the current hop.
func take_off(direction: Vector3 = Vector3.FORWARD) -> bool:
	if state != State.IDLE or not is_instance_valid(_visual) or not direction.is_finite():
		return false
	_origin = _visual.global_position
	_departure_heading = _visual.global_rotation.y
	_direction = Vector3(direction.x, 0, direction.z)
	if _direction.length_squared() < 0.001:
		_direction = Vector3.FORWARD.rotated(Vector3.UP, _departure_heading)
	_direction = _direction.normalized()
	_flight_time = 0
	state = State.TAKING_OFF
	return true

func _pose_flight(delta: float) -> void:
	_flight_time += delta
	var airborne := maxf(0.0, _flight_time - 0.12)
	var launch := 1.0 - exp(-airborne * 8.0)
	state = State.TAKING_OFF if _flight_time < 0.45 else State.FLYING
	var travel := flight_speed * (airborne - (1.0 - exp(-airborne * 5.0)) / 5.0)
	var height := ascent_speed * (airborne - (1.0 - exp(-airborne * 8.0)) / 8.0) + launch * 0.12
	var sideways := Vector3(-_direction.z, 0, _direction.x) * sin(airborne * 1.8) * airborne * 0.1
	_visual.global_position = _origin + Vector3.UP * height + _direction * travel + sideways
	var heading := _flight_heading(_direction)
	_visual.global_rotation = Vector3(launch * 0.22, lerp_angle(_departure_heading, heading, 1.0 - exp(-_flight_time * 12.0)), sin(airborne * 1.8) * 0.08 * launch)
	var crouch := sin(clampf(_flight_time / 0.16, 0.0, 1.0) * PI) * 0.12
	_visual.scale = Vector3(1 + crouch * 0.4, 1 - crouch, 1) * bird_size
	_pose_wings(launch, airborne * 22.0)
	_shadow.global_position = Vector3(_visual.global_position.x, global_position.y + 0.016, _visual.global_position.z)
	_shadow_material.set_shader_parameter("shadow_color", Color(0.27, 0.30, 0.25, 0.2 * maxf(0.0, 1.0 - height / 0.9)))
	_shadow.visible = height < 0.9
	if _flight_time >= flight_duration and _clear_of_camera():
		state = State.DEPARTED
		_visual.hide()
		_shadow.hide()
		_return_time = respawn_delay
		set_process(respawn_delay > 0.0)
		departed.emit()


func _clear_of_camera() -> bool:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return true
	var at := _visual.global_position
	if camera.is_position_behind(at):
		return true
	# Allow a full wingspan beyond the edge before removing the silhouette.
	var margin := 1.15 * bird_size
	for offset in [Vector3.ZERO, camera.global_basis.x * margin, -camera.global_basis.x * margin,
			camera.global_basis.y * margin, -camera.global_basis.y * margin]:
		if camera.is_position_in_frustum(at + offset):
			return false
	return true
