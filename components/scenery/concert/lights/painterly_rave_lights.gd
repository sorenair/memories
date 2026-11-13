@tool
class_name PainterlyRaveLights
extends PainterlyConcertComponent
## Moving-head fixtures, painted light shafts, and soft receiving-surface pools.
## One rig callback moves up to eight lights; no real-time lights or shadow maps.
const BEAM = preload("res://components/lighting/light_shaft/light_shaft.gdshader")
const WASH = preload("res://components/lighting/light_wash/light_wash.gdshader")

@export_group("Light Rig")
@export_range(1, 8, 1) var light_count: int = 4:
	set(value):
		light_count = clampi(value, 1, 8)
		_request_rebuild()
@export_range(2.5, 12.0, 0.1) var rig_width: float = 6.1:
	set(value):
		rig_width = clampf(value, 2.5, 12)
		_request_rebuild()
@export_range(2.0, 6.0, 0.1) var mount_height: float = 3.2:
	set(value):
		mount_height = clampf(value, 2, 6)
		_request_rebuild()
@export var supports_enabled: bool = true:
	set(value):
		supports_enabled = value
		_request_rebuild()

@export_group("Painted Light")
@export var light_colors := PackedColorArray([Color("9e79c4"), Color("61b5bf"), Color("dfa571"), Color("c17ba1")]):
	set(value):
		light_colors = value
		_request_rebuild()
@export_range(0.0, 1.5, 0.05) var intensity: float = 0.85:
	set(value):
		intensity = clampf(value, 0, 1.5)
		_apply_frame()
@export_range(0.6, 3.0, 0.1) var beam_width: float = 1.65:
	set(value):
		beam_width = clampf(value, 0.6, 3)
		_apply_frame()
@export var beams_enabled: bool = true:
	set(value):
		beams_enabled = value
		_request_rebuild()
@export var floor_pools_enabled: bool = true:
	set(value):
		floor_pools_enabled = value
		_request_rebuild()
## Relative to the component root, e.g. -0.45 for a rig mounted on a 0.45 m deck.
@export_range(-4.0, 2.0, 0.05) var receiving_height: float = 0.0:
	set(value):
		receiving_height = value
		_apply_frame()

@export_group("Sweep and Rhythm")
@export_enum("Crossing Fans", "Slow Waves", "Still") var sweep_pattern: int = 0:
	set(value):
		sweep_pattern = clampi(value, 0, 2)
		_apply_frame()
@export_range(0.0, 2.0, 0.05) var sweep_speed: float = 0.65:
	set(value):
		sweep_speed = clampf(value, 0, 2)
@export_range(0.0, 4.0, 0.1) var sweep_width: float = 2.0:
	set(value):
		sweep_width = clampf(value, 0, 4)
		_apply_frame()
@export_range(1.0, 7.0, 0.1) var target_distance: float = 3.8:
	set(value):
		target_distance = clampf(value, 1, 7)
		_apply_frame()
@export_range(0.0, 180.0, 1.0) var beat_bpm: float = 112.0:
	set(value):
		beat_bpm = clampf(value, 0, 180)
		_apply_frame()
## Gentle brightness breathing. There are deliberately no hard flashes.
@export_range(0.0, 0.45, 0.01) var pulse_amount: float = 0.18:
	set(value):
		pulse_amount = clampf(value, 0, 0.45)
		_apply_frame()

var _heads: Array[MeshInstance3D] = []
var _beams: Array[MeshInstance3D] = []
var _pools: Array[MeshInstance3D] = []
var _clock: float = 0.0

func _build_geometry() -> Dictionary:
	var config := _config()
	for key in ["rig_width", "mount_height", "supports_enabled", "light_count"]:
		config[key] = get(key)
	return GEOMETRY.new().truss(config)

func _build_details() -> void:
	_heads.clear()
	_beams.clear()
	_pools.clear()
	var rig := GEOMETRY.new()
	for index in range(light_count):
		var color := light_colors[index % light_colors.size()] if not light_colors.is_empty() else Color("a38cc4")
		var data: Dictionary = rig.fixture(_config(), color)
		var head := _add_visual("Fixture_%d" % index, data.mesh)
		head.position = Vector3(_source_x(index), mount_height - 0.32, 0)
		_heads.append(head)
		if beams_enabled:
			var material := ShaderMaterial.new()
			material.shader = BEAM
			material.render_priority = -1
			material.set_shader_parameter("light_color", color.lightened(0.10))
			material.set_shader_parameter("source_width", 0.19)
			material.set_shader_parameter("paint_variation", 0.34)
			material.set_shader_parameter("paint_seed", float(index) * 1.71 + float(posmod(prop_seed, 997)))
			material.set_shader_parameter("drift_speed", 0.0)
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				surface.set_uv(uv)
				surface.set_normal(Vector3.FORWARD)
				surface.add_vertex(Vector3(uv.x * 2.0 - 1.0, uv.y, 0))
			_beams.append(_add_visual("Beam_%d" % index, surface.commit(), material))
		if floor_pools_enabled:
			var material := ShaderMaterial.new()
			material.shader = WASH
			material.set_shader_parameter("light_color", color)
			material.set_shader_parameter("softness", 0.88)
			material.set_shader_parameter("paint_variation", 0.4)
			material.set_shader_parameter("paint_seed", float(index) * 1.71)
			material.set_shader_parameter("motion", 0)
			var plane := PlaneMesh.new()
			plane.size = Vector2.ONE
			_pools.append(_add_visual("Pool_%d" % index, plane, material))
	_apply_frame()
	set_process(not Engine.is_editor_hint())

func _source_x(index: int) -> float:
	return 0.0 if light_count == 1 else lerpf(-rig_width * 0.5 + 0.45, rig_width * 0.5 - 0.45, float(index) / float(light_count - 1))

func _process(delta: float) -> void:
	_clock += delta
	_apply_frame()

## Deterministic authoring/capture hook; ordinary playback advances this clock.
func seek_time(seconds: float) -> void:
	_clock = maxf(0, seconds)
	_apply_frame()

func _apply_frame() -> void:
	if not is_inside_tree() or _heads.is_empty() or not is_instance_valid(_heads[0]):
		return
	var sweep := _clock * sweep_speed
	var beat := 0.5 + sin(_clock * beat_bpm / 60.0 * TAU) * 0.5 if beat_bpm > 0 else 0.5
	var energy := intensity * (1.0 - pulse_amount + pulse_amount * beat)
	if _material:
		_material.set_shader_parameter("animation_time", _clock)
		_material.set_shader_parameter("beat_bpm", beat_bpm)
		_material.set_shader_parameter("pulse_amount", pulse_amount)
		_material.set_shader_parameter("light_intensity", intensity)
	for index in range(_heads.size()):
		var phase := float(index) * 1.9 + float(posmod(prop_seed, 100)) * 0.07
		var x := _source_x(index)
		var target_x := -x * 0.58 if sweep_pattern == 0 else x * 0.80
		var target_z := target_distance
		if sweep_pattern != 2:
			target_x += sin(sweep * 0.77 + phase) * sweep_width * 0.55
			target_z += cos(sweep * 0.51 + phase) * 0.6
		var y := minf(receiving_height, mount_height - 1.0)
		var target := Vector3(target_x, y, target_z)
		var head := _heads[index]
		head.look_at(to_global(target), Vector3.UP, true)
		var source := head.position + head.basis * Vector3(0, 0, 0.216)
		if beams_enabled and index < _beams.size():
			var beam := _beams[index]
			beam.position = target
			var material := beam.material_override as ShaderMaterial
			material.set_shader_parameter("beam_height", source.y - y)
			material.set_shader_parameter("source_offset", Vector2(source.x - target.x, source.z - target.z))
			material.set_shader_parameter("footprint", Vector2(beam_width, beam_width))
			material.set_shader_parameter("opacity", minf(0.55, energy * 0.32))
			var bounds := AABB(Vector3.ZERO, Vector3.ZERO).expand(source - target)
			beam.custom_aabb = bounds.grow(beam_width * 0.55 + 0.10)
		if floor_pools_enabled and index < _pools.size():
			var pool := _pools[index]
			pool.position = target + Vector3.UP * 0.014
			pool.scale = Vector3(beam_width * 1.55, 1, beam_width * 2.0)
			var material := pool.material_override as ShaderMaterial
			material.set_shader_parameter("intensity", energy * 0.52)
