extends Node3D
## Each instrument can send out a short painted gesture on its own beat.

const PAINT = preload("res://scenes/memories/first_meeting/band_flourish.gdshader")
const INK: Array[Color] = [Color("f06d45"), Color("f5af32"), Color("cd5491"), Color("39b8ae")]
const ORIGINS: Array[Vector3] = [
	Vector3(-1.77, 0.95, 0.74), Vector3(-0.62, 0.77, 0.78),
	Vector3(0.41, 1.06, 0.62), Vector3(1.35, 1.08, 0.72),
]
const DURATION := 0.82

@export var band: PainterlyMechanicalBand
var _voices: Array[MeshInstance3D] = []
var _elapsed := PackedFloat32Array()

func _ready() -> void:
	set_process(false)
	var mesh := _strokes()
	for index in INK.size():
		var paint := ShaderMaterial.new()
		paint.shader = PAINT
		paint.set_shader_parameter("ink", INK[index])
		paint.set_shader_parameter("sweep_side", -1.0 if index < 2 else 1.0)
		var voice := MeshInstance3D.new()
		voice.name = PainterlyMechanicalBand.INSTRUMENTS[index]
		voice.mesh = mesh
		voice.custom_aabb = AABB(Vector3.ONE * -1.7, Vector3.ONE * 3.4)
		voice.material_override = paint
		voice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		voice.hide()
		add_child(voice, false, Node.INTERNAL_MODE_BACK)
		_voices.append(voice)
		_elapsed.append(0.0)
	band.instrument_played.connect(_on_note)

func _on_note(instrument: StringName) -> void:
	var index := PainterlyMechanicalBand.INSTRUMENTS.find(instrument)
	if index < 0:
		return
	var voice := _voices[index]
	voice.global_position = band.to_global(ORIGINS[index] * band.prop_scale)
	voice.material_override.set_shader_parameter("progress", 0.0)
	_elapsed[index] = 0.0
	voice.show()
	set_process(true)

func _process(delta: float) -> void:
	var any_playing := false
	for index in _voices.size():
		var voice := _voices[index]
		if not voice.visible:
			continue
		_elapsed[index] += delta
		if _elapsed[index] >= DURATION:
			voice.hide()
		else:
			voice.material_override.set_shader_parameter("progress", _elapsed[index] / DURATION)
			any_playing = true
	set_process(any_playing)

func _strokes() -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 16
	for ribbon in 3:
		var start := ribbon * (SEGMENTS + 1) * 2
		for segment in SEGMENTS + 1:
			for side in 2:
				var along := float(segment) / SEGMENTS
				builder.set_uv(Vector2(along, float(side)))
				builder.set_uv2(Vector2(float(ribbon), 0.0))
				builder.add_vertex(Vector3(along, float(side), 0.0))
		for segment in SEGMENTS:
			var a := start + segment * 2
			for vertex in [a, a + 2, a + 1, a + 1, a + 2, a + 3]:
				builder.add_index(vertex)
	return builder.commit()
