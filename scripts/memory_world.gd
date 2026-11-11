extends Node3D
## Shared presentation and local player setup, independent of memory content.
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const RemoteMotion := preload("res://scripts/network/remote_motion.gd")
const ExplorerScene := preload("res://scenes/player/explorer.tscn")
const SNAPSHOT_INTERVAL := 0.05

@export var recalled_spawn_offset := Vector3(0.0, 0.0, 10.0)
@export_range(4.0, 14.0, 0.1) var arrival_drop_height: float = 6.0

var _bounded_memory: bool = false
var _platforms: Array[MemoryPlatform] = []
var _remote: MemoryExplorer
var _motion: RemoteMotion
var _remote_id := 0
var _send_timer := 0.0
var _lan_label: Label

@onready var player: MemoryExplorer = $Explorer
@onready var memory: MemoryScene = $Memory

func _ready() -> void:
	_configure_platforms()
	player.global_transform = memory.get_entry_transform()
	var recalled := get_tree().root.has_meta(MemoryArrival.REQUEST_META)
	if recalled:
		get_tree().root.remove_meta(MemoryArrival.REQUEST_META)
		# Land just outside the clearing, within a short walk of its static scenery.
		var landing := player.global_position + recalled_spawn_offset
		if not _bounded_memory or _landing_supported(landing):
			player.global_position = landing
	if LanSession.state != LanSession.State.OFFLINE:
		player.set_avatar(LanSession.local_avatar)
		if LanSession.state == LanSession.State.GUEST:
			var guest_spawn := player.global_position + Vector3.RIGHT * 1.2
			if not _bounded_memory or _landing_supported(guest_spawn):
				player.global_position = guest_spawn
		_setup_lan()
	player.reset_physics_interpolation()
	$CameraRig.global_position = player.global_position + $CameraRig.framing_offset
	$DreamSurface.global_position.x = player.global_position.x
	$DreamSurface.global_position.z = player.global_position.z
	if recalled:
		var arrival := MemoryArrival.new()
		arrival.name = "MemoryArrival"
		add_child(arrival)
		arrival.begin(self, arrival_drop_height)

func _physics_process(delta: float) -> void:
	if not _bounded_memory:
		# Legacy blank-void memories still use the seamless ground.
		$DreamSurface.global_position.x = player.global_position.x
		$DreamSurface.global_position.z = player.global_position.z
	if _remote_id == 0 or has_node("MemoryArrival"):
		return
	_send_timer -= delta
	if _send_timer <= 0.00001:
		_send_timer += SNAPSHOT_INTERVAL
		LanSession.send_snapshot(player.global_position, player.visual.rotation.y, player.walking)

func _setup_lan() -> void:
	# Sample the body after its movement tick; remote poses advance on render frames.
	process_physics_priority = 1
	_lan_label = Label.new()
	_lan_label.name = "LanStatus"
	_lan_label.position = Vector2(32.0, 24.0)
	_lan_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lan_label.add_theme_font_size_override("font_size", 24)
	_lan_label.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.12, 0.8))
	_lan_label.add_theme_constant_override("outline_size", 6)
	$Controls.add_child(_lan_label)
	LanSession.status_changed.connect(_update_lan)
	LanSession.snapshot_received.connect(_receive_snapshot)
	_update_lan()

func _update_lan() -> void:
	_lan_label.text = LanSession.status
	if _remote_id == LanSession.partner_id:
		return
	if is_instance_valid(_remote):
		_remote.hide()
		_remote.queue_free()
		_remote = null
	_motion = null
	_remote_id = LanSession.partner_id
	_send_timer = SNAPSHOT_INTERVAL

func _receive_snapshot(time: float, point: Vector3, heading: float, walking: bool) -> void:
	if _remote_id == 0:
		return
	if _remote == null:
		_remote = ExplorerScene.instantiate() as MemoryExplorer
		_remote.name = "Partner"
		_remote.hide()
		# The partner is presentation-only: no input, collisions, or second transform interpolator.
		_remote.remove_from_group(&"explorers")
		_remote.collision_layer = 0
		_remote.collision_mask = 0
		_remote.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(_remote)
		_remote.set_physics_process(false)
		_remote.set_avatar(LanSession.partner_avatar)
		_motion = RemoteMotion.new()
	_motion.push(time, point, heading, walking)

func _process(delta: float) -> void:
	if _motion != null:
		_motion.apply(delta, _remote)

func _configure_platforms() -> void:
	var environment: Environment = $WorldEnvironment.environment
	for node in get_tree().get_nodes_in_group(&"memory_platforms"):
		if memory.is_ancestor_of(node):
			_bounded_memory = true
			_platforms.append(node)
			node.void_color = environment.background_color
	if _bounded_memory:
		$DreamSurface.hide()
		$Ground/CollisionShape3D.disabled = true

func _landing_supported(point: Vector3) -> bool:
	for platform in _platforms:
		if platform.contains_ground_point(point, 0.8):
			return true
	return false
