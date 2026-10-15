class_name MemoryScene
extends Node3D
## Inherit memory_base.tscn and populate the named containers in each memory.
@export var memory_id: StringName = &"blank_void"
@export var display_name: String = "A memory yet to take shape"

func get_entry_transform() -> Transform3D:
	return $Entry.global_transform
