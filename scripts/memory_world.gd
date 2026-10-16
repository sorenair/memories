extends Node3D
## Shared presentation and local player setup, independent of memory content.
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")

@export var recalled_spawn_offset := Vector3(0.0, 0.0, 10.0)
@export_range(4.0, 14.0, 0.1) var arrival_drop_height: float = 6.0

var _bounded_memory: bool = false
var _platforms: Array[MemoryPlatform] = []

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
	player.reset_physics_interpolation()
	$CameraRig.global_position = player.global_position
	$DreamSurface.global_position.x = player.global_position.x
	$DreamSurface.global_position.z = player.global_position.z
	if recalled:
		var arrival := MemoryArrival.new()
		arrival.name = "MemoryArrival"
		add_child(arrival)
		arrival.begin(self, arrival_drop_height)

func _physics_process(_delta: float) -> void:
	if _bounded_memory:
		return
	# Legacy blank-void memories still use the seamless ground.
	$DreamSurface.global_position.x = player.global_position.x
	$DreamSurface.global_position.z = player.global_position.z

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
		set_physics_process(false)

func _landing_supported(point: Vector3) -> bool:
	for platform in _platforms:
		if platform.contains_ground_point(point, 0.8):
			return true
	return false
