extends Node3D
## Shared presentation and local player setup, independent of memory content.
@onready var player: MemoryExplorer = $Explorer
@onready var memory: MemoryScene = $Memory

func _ready() -> void:
	player.global_transform = memory.get_entry_transform()
	player.reset_physics_interpolation()
	$CameraRig.global_position = player.global_position

func _physics_process(_delta: float) -> void:
	# Keep the seamless surface beneath the explorer even on long walks.
	$DreamSurface.global_position.x = player.global_position.x
	$DreamSurface.global_position.z = player.global_position.z
