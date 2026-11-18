@tool
class_name PainterlyGrapevine
extends PainterlyVietnamPiece
## A rooted grapevine trained along local Z. Instance beside a trellis.
const CANOPY = preload("res://components/scenery/vineyard/grapevine_canopy.gd")

@export_range(1.7,3.2,0.05) var vine_height := 2.25:
	set(value):
		vine_height = value
		_request_rebuild()
@export_range(1.5,4.0,0.05) var vine_length := 3.4:
	set(value):
		vine_length = value
		_request_rebuild()
@export_range(0,10,1) var bunch_count := 5:
	set(value):
		bunch_count = value
		_request_rebuild()
@export var grape_color := Color("66517d"):
	set(value):
		grape_color = value
		_request_rebuild()
@export var foliage_palette: GrassPalette = preload("res://components/foliage/palettes/conservatory.tres"):
	set(value):
		foliage_palette = value
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var builder := BUILDER.new()
	builder.begin(_config())
	var random: RandomNumberGenerator = builder.rng
	var crown := vine_height * 0.73
	var fork := Vector3(0,crown,0)
	var trunk: Array[Vector3] = [
		Vector3(0,-0.06,0),Vector3(-0.09,crown*0.38,0.12),
		Vector3(0.07,crown*0.72,-0.12),fork]
	builder.tube(trunk,0.075,body_color,8)
	builder.collider(Vector3(0,crown*0.48,0),Vector3(0.22,crown,0.25),"Trunk")
	for side in [-1.0,1.0]:
		var arm: Array[Vector3] = [fork,Vector3(0.08,crown+0.08,side*vine_length*0.24),
			Vector3(0,crown+0.03,side*vine_length*0.49)]
		builder.tube(arm,0.037,body_color,7)
	for index in bunch_count:
		var side := 1.0 if index%2==0 else -1.0
		var lane := (float(index)+0.5)/bunch_count-0.5
		var z := (lane+random.randf_range(-0.06,0.06))*vine_length
		var tip := Vector3(side*random.randf_range(0.44,0.63),crown-random.randf_range(0.07,0.22),z)
		var shoot: Array[Vector3] = [Vector3(0,crown+0.05,z),tip+Vector3.UP*0.09,tip]
		builder.tube(shoot,0.016,body_color.lightened(0.15),6)
		var scale_factor := random.randf_range(0.78,1.20)
		var phase := random.randf()*TAU
		var berry := SphereMesh.new()
		berry.radial_segments = 8
		berry.rings = 4
		for tier in 4:
			var count := 4-tier
			for j in count:
				var angle := phase+float(j)/count*TAU+tier*0.8
				var spread := (0.092-tier*0.024)*scale_factor
				var at := tip+Vector3(cos(angle)*spread,-(0.03+tier*0.073)*scale_factor,sin(angle)*spread)
				var size := Vector3(1.0,1.13,1.0)*random.randf_range(0.105,0.136)*scale_factor
				var pigment := grape_color.lerp(Color("aa7898"),random.randf_range(0.0,0.35))
				builder.append(berry,Transform3D(Basis.IDENTITY.scaled(size),at),pigment,0)
	return builder.finish()

func _build_details() -> void:
	var canopy: PainterlyBush = CANOPY.new()
	canopy.name = "VineLeaves"
	canopy.position.y = vine_height*0.40
	canopy.bush_height = vine_height*0.69
	canopy.footprint = Vector2(1.23,vine_length)
	canopy.bush_seed = prop_seed
	canopy.mass_count = 4
	canopy.sprays_per_mass = 29
	canopy.palette_preset = 0
	canopy.palette = foliage_palette
	canopy.wind_strength = 0.035
	canopy.recall_enabled = recall_enabled
	# Keep foliage outside the assembled wood/fruit batch so it retains wind and response.
	_generated_root.add_child(canopy)
