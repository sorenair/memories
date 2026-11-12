@tool
extends Node3D
## Cosmetic, deterministic individual routes. Two teams, six instanced mesh draws.
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
var field_size := Vector2(84, 37.3)
var team_colors: Array[Color] = [Color("7a0019"), Color("e5dcc8")]
var paint: ShaderMaterial
var animate := true
var elapsed := 0.0
var _bodies: Array[MultiMesh] = []
var _left_legs: Array[MultiMesh] = []
var _right_legs: Array[MultiMesh] = []
var _ball: MeshInstance3D

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var leg_builder := _builder()
	leg_builder.box(Vector3(0, -0.2, 0), Vector3(0.17, 0.4, 0.18), Color("555f63"), 1.0)
	leg_builder.box(Vector3(0, -0.4, 0.04), Vector3(0.2, 0.1, 0.26), Color("414b4f"), 1.0)
	var leg_mesh: ArrayMesh = leg_builder.s.commit()
	for team in 2:
		var b := _builder()
		b.soft_box(Vector3(0, 0.68, 0), Vector3(0.45, 0.62, 0.32), team_colors[team], 0.08, 1.0)
		b.ball(Vector3(0, 1.12, 0), Vector3.ONE * 0.33, Color("d9d2c2"), 1.0)
		_bodies.append(_batch("Team%dBodies" % team, b.s.commit()))
		_left_legs.append(_batch("Team%dLeftLegs" % team, leg_mesh))
		_right_legs.append(_batch("Team%dRightLegs" % team, leg_mesh))
	var ball_builder := _builder()
	ball_builder.ball(Vector3.ZERO, Vector3(0.32, 0.17, 0.17), Color("805c46"), 1.0)
	_ball = MeshInstance3D.new()
	_ball.name = "Football"
	_ball.mesh = ball_builder.s.commit()
	_ball.material_override = paint
	_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ball)
	_update_poses()
	set_process(animate and not Engine.is_editor_hint())

func _builder() -> RefCounted:
	var b := GEOMETRY.new()
	b.s = SurfaceTool.new()
	b.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	b.s.set_uv(Vector2.ZERO)
	return b

func _batch(id: String, mesh: Mesh) -> MultiMesh:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = 11
	instances.custom_aabb = AABB(Vector3(-field_size.x * 0.5, 0, -field_size.y * 0.5), Vector3(field_size.x, 2, field_size.y))
	var view := MultiMeshInstance3D.new()
	view.name = id
	view.multimesh = instances
	view.material_override = paint
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	return instances

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	elapsed += maxf(0.0, delta)
	_update_poses()

func route_position(index: int, team: int, at: float) -> Vector3:
	# Receivers have staggered starts, different lane bends and different reach.
	# Defenders follow those routes with individual reaction delays and pursuit offsets.
	var reaction := (0.5 + index * 0.065) if team == 1 else 0.0
	var phase := (at - index * 0.26 - reaction) * TAU / 22.0
	var reach := field_size.x * (0.235 + (index % 3) * 0.018)
	var x := -field_size.x * 0.10 + sin(phase) * reach + (index % 4 - 1.5) * 1.15
	var lane := 0.0 if index == 0 else (index - 5.5) * field_size.y * 0.052
	var z := lane + sin(phase * 2.0 + index * 0.6) * (1.3 + (index % 3) * 0.4)
	if team == 1:
		x -= cos(phase) * 1.8
		z += 0.7 + sin(at * 0.75 + index) * 0.4
	return Vector3(x, 0.07, z)

func sample_player(index: int, team: int, at: float) -> Dictionary:
	var position := route_position(index, team, at)
	var motion := (route_position(index, team, at + 0.025) - route_position(index, team, at - 0.025)) / 0.05
	var speed := Vector2(motion.x, motion.z).length()
	var stride := at * (6.5 + (index % 4) * 0.33) + index * 1.7 + team * 0.4
	var strength := clampf(speed / 2.0, 0.0, 1.0)
	return {"position": position, "yaw": atan2(motion.x, motion.z),
		"bob": (1.0 - cos(stride * 2.0)) * 0.035 * strength,
		"stride": sin(stride) * 0.5 * strength}

func _update_poses() -> void:
	if _bodies.is_empty():
		return
	for team in 2:
		for index in 11:
			var pose := sample_player(index, team, elapsed)
			var root := Transform3D(Basis(Vector3.UP, pose.yaw), pose.position + Vector3.UP * pose.bob)
			_bodies[team].set_instance_transform(index, root)
			_left_legs[team].set_instance_transform(index,
				root * Transform3D(Basis(Vector3.RIGHT, pose.stride), Vector3(-0.12, 0.45, 0)))
			_right_legs[team].set_instance_transform(index,
				root * Transform3D(Basis(Vector3.RIGHT, -pose.stride), Vector3(0.12, 0.45, 0)))
	var carrier := sample_player(0, 0, elapsed)
	_ball.transform = Transform3D(Basis(Vector3.UP, carrier.yaw),
		carrier.position + Vector3.UP * (0.72 + carrier.bob))
	_ball.position += _ball.basis.z * 0.25
