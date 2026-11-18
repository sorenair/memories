extends MultiMeshInstance3D
## Seeded pigment strokes peel away from the canvas and return on the same clock.
const COUNT := 110
const PIGMENTS := [
	Color("e8ae57"), Color("ebc78d"), Color("c77e58"), Color("9f6072"),
	Color("71648e"), Color("ad98ba"), Color("f3d7a9")]
var _starts := PackedVector3Array()
var _angles := PackedFloat32Array()
var _sizes := PackedFloat32Array()

func setup(canvas_size: Vector2) -> void:
	var stroke := SphereMesh.new()
	stroke.radial_segments = 6
	stroke.rings = 3
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.vertex_color_use_as_albedo = true
	stroke.material = paint
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = stroke
	multimesh.instance_count = COUNT
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-4, -2, -0.1), Vector3(8, 5, 5))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var random := RandomNumberGenerator.new()
	random.seed = 10436
	for index in COUNT:
		var lane := index % 3
		var along := float(index) / COUNT
		_starts.append(Vector3(
			(along - 0.5) * canvas_size.x * 0.94,
			canvas_size.y * (-0.20 + lane * 0.15 + random.randf_range(-0.10, 0.10)),
			0.145))
		_angles.append(random.randf_range(-0.35, 0.35))
		_sizes.append(random.randf_range(0.045, 0.13))
		var pigment: Color = PIGMENTS[(lane * 2 + floori(index / 9.0)) % PIGMENTS.size()]
		multimesh.set_instance_color(index, pigment.srgb_to_linear())

func seek(phase: float) -> void:
	if phase <= 0.0 or phase >= 1.0:
		multimesh.visible_instance_count = 0
		return
	multimesh.visible_instance_count = COUNT
	for index in COUNT:
		var delay := float(index) / COUNT * 0.18
		var t := clampf((phase - delay) / 0.82, 0.0, 1.0)
		# Three staggered arcs, with a common forward sweep and a curled tip.
		var envelope := pow(sin(t * PI), 1.45)
		var lane := float(index % 3)
		var angle := t * TAU * 0.75 + lane * 0.64 + _starts[index].x * 0.8
		var at := _starts[index] + Vector3(
			sin(angle) * (0.85 + lane * 0.17),
			0.62 + cos(angle) * 0.78 + lane * 0.17,
			1.45 + lane * 0.43 + cos(angle) * 0.35) * envelope
		var size := maxf(0.0001, _sizes[index] * smoothstep(0.0, 0.24, envelope))
		var brush := Basis(Vector3.BACK, -angle + _angles[index]).scaled_local(
			Vector3(size * (2.5 + lane * 0.46), size * 0.70, size * 0.38))
		multimesh.set_instance_transform(index, Transform3D(brush, at))
