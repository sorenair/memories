@tool
extends PainterlyVietnamPiece
## Small local furnishings built with the shared paint, collision and recall kit.
@export_enum("Shopfront", "Lakeside Bench", "Hanging Sign") var detail_kind := 0:
	set(value):
		detail_kind = value
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var b := BUILDER.new()
	b.begin(_config())
	if detail_kind==0:
		# Low pavement furniture tucked under an awning, never in the shared lane.
		for at in [Vector3(-0.35,0,0.05),Vector3(0.48,0,0.27)]:
			b.disc(at+Vector3.UP*0.32,0.22,0.075,accent_color,Vector3.UP,0,16)
			for x in [-0.13,0.13]:
				for z in [-0.13,0.13]:
					b.rod(at+Vector3(x,0.03,z),at+Vector3(x,0.30,z),0.024,accent_color.darkened(0.12),8)
		b.flat_deck(Vector3(0,0.51,-0.45),0.82,0.50,0.06,body_color,0.065)
		for x in [-0.31,0.31]:
			b.rod(Vector3(x,0,-0.45),Vector3(x,0.49,-0.45),0.045,body_color.darkened(0.10),10)
		b.disc(Vector3(-0.14,0.558,-0.45),0.07,0.055,Color("ded7bb"),Vector3.UP,0,16)
		b.disc(Vector3(0.14,0.558,-0.45),0.07,0.055,Color("ded7bb"),Vector3.UP,0,16)
		b.collider(Vector3(0,0.27,-0.14),Vector3(1.25,0.55,1.1),"PavementFurniture")
	elif detail_kind==1:
		for z in [-0.20,0.0,0.20]:
			b.soft_box(Vector3(0,0.43,z),Vector3(1.85,0.075,0.17),body_color,0.025)
		for y in [0.70,0.88]:
			b.soft_box(Vector3(0,y,-0.27),Vector3(1.85,0.13,0.055),body_color,0.025)
		for side in [-1.0,1.0]:
			b.box(Vector3(side*0.62,0.20,0),Vector3(0.20,0.40,0.46),trim_color)
			b.rod(Vector3(side*0.77,0.40,-0.27),Vector3(side*0.77,0.97,-0.27),0.035,accent_color,10)
		b.collider(Vector3(0,0.48,-0.02),Vector3(1.9,0.95,0.64),"Bench")
	else:
		b.rod(Vector3(0,2.35,-0.1),Vector3(0,2.35,0.6),0.025,accent_color,8)
		for x in [-0.23,0.23]: b.rod(Vector3(x,2.35,0.55),Vector3(x,2.14,0.55),0.012,accent_color,6)
		b.soft_box(Vector3(0,1.92,0.55),Vector3(0.68,0.48,0.065),body_color,0.06)
		# A simple cup silhouette: suggest a shop without invented personal text.
		b.soft_box(Vector3(-0.04,1.92,0.59),Vector3(0.23,0.20,0.012),trim_color,0.04)
		b.disc(Vector3(0.10,1.93,0.60),0.065,0.013,trim_color,Vector3.BACK,0,16)
		b.disc(Vector3(0.11,1.93,0.61),0.036,0.015,body_color,Vector3.BACK,0,16)
	return b.finish()
