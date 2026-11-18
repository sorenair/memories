@tool
extends PainterlyBush

func _add_generated(node: GeometryInstance3D) -> void:
	super._add_generated(node)
	# This canopy sits above ground, so its normal ground pigment is omitted.
	if node.name == &"GroundPigment":
		node.visible = false
