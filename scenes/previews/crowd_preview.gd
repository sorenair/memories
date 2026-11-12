extends Node3D
## F6 preview with the actual explorer scenes, independent of memory progression/LAN.

func _ready() -> void:
	var soren := $Display/Soren as MemoryExplorer
	var vivian := $Display/Vivian as MemoryExplorer
	soren.set_avatar(MemoryExplorer.Avatar.SOREN)
	vivian.set_avatar(MemoryExplorer.Avatar.VIVIAN)
	# This is a static comparison stage: retain avatar idle animations, disable locomotion.
	soren.set_physics_process(false)
	vivian.set_physics_process(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
