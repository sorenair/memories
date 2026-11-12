@tool
class_name PainterlyMechanicalBand
extends PainterlyArcadeComponent
## Four independently playable mechanical instruments; no frame callbacks at rest.
signal instrument_played(instrument: StringName)
const BUTTON = preload("res://components/activities/arcade/mechanical_band/band_button.gd")
const INSTRUMENTS: Array[StringName] = [&"Guitar", &"Kick", &"Snare", &"Piano"]
const SOUNDS: Array[AudioStream] = [
	preload("res://components/activities/arcade/mechanical_band/audio/guitar.wav"),
	preload("res://components/activities/arcade/mechanical_band/audio/kick.wav"),
	preload("res://components/activities/arcade/mechanical_band/audio/snare.wav"),
	preload("res://components/activities/arcade/mechanical_band/audio/piano.wav")
]
const DURATIONS := [0.72, 0.50, 0.44, 0.92]
const STRIKE_TIME := 0.075

@export_group("Band Interaction")
@export_range(0.4, 3.0, 0.05) var interaction_range: float = 0.95:
	set(value): interaction_range = clampf(value, 0.4, 3.0)
@export_range(-30.0, 3.0, 1.0, "suffix:dB") var volume_db: float = -7.0:
	set(value):
		volume_db = clampf(value, -30.0, 3.0)
		for sound in _sounds: sound.volume_db = volume_db
@export_range(0.25, 1.5, 0.05) var animation_strength: float = 1.0:
	set(value): animation_strength = clampf(value, 0.25, 1.5)
@export_tool_button("Preview band") var preview_band = _preview_band

var _parts: Dictionary = {}
var _buttons: Array[Node3D] = []
var _sounds: Array[AudioStreamPlayer] = []
var _elapsed := [0.0, 0.0, 0.0, 0.0]
var _playing := [false, false, false, false]

func _kind() -> StringName:
	return &"mechanical_band"

func _build_details(result: Dictionary) -> void:
	_parts.clear()
	_buttons.clear()
	_sounds.clear()
	_playing.fill(false)
	_elapsed.fill(0.0)
	set_process(false)
	var assembly := Node3D.new()
	assembly.name = "Mechanisms"
	assembly.scale = Vector3.ONE * prop_scale
	assembly.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_generated(assembly)
	for id in result.parts:
		var part: Dictionary = result.parts[id]
		var mesh := MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.material_override = _material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if String(id).ends_with("Button"):
			var button := BUTTON.new()
			button.name = id
			button.position = part.pivot
			button.band = self
			button.instrument = INSTRUMENTS.find(StringName(String(id).trim_suffix("Button")))
			button.cap = mesh
			mesh.name = "Cap"
			button.add_child(mesh)
			assembly.add_child(button)
			_buttons.append(button)
		else:
			mesh.name = id
			mesh.position = part.pivot
			mesh.set_meta(&"rest_position", mesh.position)
			assembly.add_child(mesh)
			_parts[id] = mesh
	# Keep instrument indices stable even if geometry build order changes.
	_buttons.sort_custom(func(a: Node3D, b: Node3D): return a.instrument < b.instrument)
	for i in INSTRUMENTS.size():
		# Musical response uses the local mix: the elevated orthographic camera is
		# ~19 meters away, so camera-distance attenuation would silence these notes.
		var sound := AudioStreamPlayer.new()
		sound.name = String(INSTRUMENTS[i])+"Sound"
		sound.bus = &"SFX"
		sound.stream = SOUNDS[i]
		sound.volume_db = volume_db
		sound.max_polyphony = 2
		_generated(sound)
		_sounds.append(sound)

func can_play(instrument: int, actor: Node3D) -> bool:
	if instrument < 0 or instrument >= 4 or _playing[instrument] or _buttons.size() != 4: return false
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.get_viewport() != get_viewport(): return false
	if not is_inside_tree() or not is_visible_in_tree() or not can_process(): return false
	if not _buttons[instrument].is_visible_in_tree(): return false
	# Approach the front of the console, not the instrument behind its collider.
	var approach := to_global(Vector3(_buttons[instrument].position.x, 0.0, 2.1)*prop_scale)
	return actor.global_position.distance_squared_to(approach) <= interaction_range*interaction_range

func play_instrument(instrument: int) -> bool:
	if instrument < 0 or instrument >= 4 or not is_inside_tree() or _playing[instrument] or _buttons.size() != 4: return false
	_playing[instrument] = true
	_elapsed[instrument] = 0.0
	set_process(true)
	instrument_played.emit(INSTRUMENTS[instrument])
	return true

func _preview_band() -> void:
	for i in 4: play_instrument(i)

func get_button(instrument: int) -> Node3D:
	return _buttons[instrument] if instrument >= 0 and instrument < _buttons.size() else null

func _process(delta: float) -> void:
	var active := false
	for i in 4:
		if not _playing[i]: continue
		var previous: float = _elapsed[i]
		_elapsed[i] = minf(DURATIONS[i], previous + maxf(0.0, delta))
		var t: float = _elapsed[i]
		if previous < STRIKE_TIME and t >= STRIKE_TIME: _sounds[i].play()
		_buttons[i].cap.position.y = -0.025 * (smoothstep(0.0, 0.04, t) - smoothstep(0.16, 0.32, t))
		_pose(i, t)
		if t >= DURATIONS[i]:
			_playing[i] = false
			_buttons[i].cap.position = Vector3.ZERO
			_pose(i, DURATIONS[i])
		else:
			active = true
	set_process(active)

func _pose(instrument: int, t: float) -> void:
	var windup := smoothstep(0.0, STRIKE_TIME, t)
	var time := maxf(0.0, t-STRIKE_TIME)
	var settle := 1.0 - smoothstep(DURATIONS[instrument]-0.14, DURATIONS[instrument], t)
	var strike := exp(-time*18.0)*windup*settle*animation_strength
	var vibration := sin(time*48.0)*exp(-time*10.0)*settle*animation_strength
	match instrument:
		0:
			_parts[&"GuitarPick"].rotation.z = -0.42*strike + 0.12*sin(time*22.0)*exp(-time*6.0)*settle*animation_strength
		1:
			_parts[&"KickBeater"].rotation.x = -0.33*strike
			_parts[&"KickHead"].position.z = _parts[&"KickHead"].get_meta(&"rest_position").z + vibration*0.018
		2:
			_parts[&"SnareStick"].rotation.x = 0.36*strike + vibration*0.08
			_parts[&"SnareHead"].position.y = _parts[&"SnareHead"].get_meta(&"rest_position").y - vibration*0.012
		3:
			var press := (smoothstep(0.0, STRIKE_TIME, t) - smoothstep(0.30, 0.65, t))*animation_strength
			_parts[&"PianoAction"].position.y = _parts[&"PianoAction"].get_meta(&"rest_position").y - press*0.042
