@tool
extends "res://tests/scenes/component_test.gd"

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		$Partner.set_avatar(MemoryExplorer.Avatar.VIVIAN)
