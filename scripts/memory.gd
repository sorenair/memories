class_name MemoryScene
extends Node3D
## Inherit memory_base.tscn and compose ordered MemoryZone instances under Zones.
@export var memory_id: StringName = &"blank_void"
@export var display_name: String = "A memory yet to take shape"
## Optional paths relative to this memory. Empty uses Zones child order (legacy: scene order).
@export var guidance_fragments: Array[NodePath] = []

func get_guidance_fragments() -> Array[MemoryFragment]:
	var result: Array[MemoryFragment] = []
	if guidance_fragments.is_empty():
		var zones := get_zones()
		if not zones.is_empty():
			for zone in zones:
				var fragment := zone.get_fragment()
				if fragment:
					result.append(fragment)
		else:
			# Retained scenes such as Seasonal Demo can still use their original layout.
			for node in find_children("*","MemoryFragment",true,false):
				result.append(node as MemoryFragment)
	else:
		for path in guidance_fragments:
			var fragment := get_node_or_null(path) as MemoryFragment
			if fragment and is_ancestor_of(fragment) and not result.has(fragment): result.append(fragment)
	return result

func get_zones() -> Array[MemoryZone]:
	var result: Array[MemoryZone] = []
	for node in $Zones.get_children():
		if node is MemoryZone:
			result.append(node)
	return result

func get_entry_transform() -> Transform3D:
	return $Entry.global_transform

func get_audio() -> MemoryAudio:
	return $Audio
