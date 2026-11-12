@tool
extends Node3D
## An individual cap is the target; the band cabinet is never highlighted.
var band: Node3D
var instrument: int
var cap: MeshInstance3D

func _ready() -> void:
	if not Engine.is_editor_hint(): add_to_group(&"memory_interactables")

func can_interact(actor: Node3D) -> bool:
	return is_instance_valid(band) and band.can_play(instrument, actor)

func try_activate(actor: Node3D) -> bool:
	return can_interact(actor) and band.play_instrument(instrument)

func interaction_outline_selected_only() -> bool:
	return true

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if is_instance_valid(cap): result.append(cap)
	return result

func get_interaction_tap_position() -> Vector3:
	return cap.global_position

func get_interaction_tap_radius() -> float:
	return 36.0

func get_interaction_occlusion_root() -> Node3D:
	return band
