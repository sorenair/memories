@tool
class_name PainterlyFootballField
extends PainterlyStadiumPiece
const MINNESOTA = preload("res://components/scenery/stadium/minnesota_marks.gd")
const PLAYERS = preload("res://components/scenery/stadium/football_players.gd")
## A scenic, art-scaled football field: painted bands, yard/hash lines, goals and teams.

@export var field_size := Vector2(84.0, 37.3):
	set(value):
		field_size = value.max(Vector2(24, 12))
		_request_rebuild()
@export var turf_color := Color("83988a"):
	set(value):
		turf_color = value
		_request_rebuild()
@export var end_zone_color := Color("906867"):
	set(value):
		end_zone_color = value
		_request_rebuild()
@export_range(0.0, 0.8, 0.05) var snow_coverage := 0.4:
	set(value):
		snow_coverage = value
		_request_rebuild()
@export var show_teams := true:
	set(value):
		show_teams = value
		_request_rebuild()
@export var minnesota_branding := false:
	set(value):
		minnesota_branding = value
		_request_rebuild()
@export var animate_players := true:
	set(value):
		animate_players = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	var half := field_size * 0.5
	var end_length := field_size.x / 12.0
	var playing_length := field_size.x - end_length * 2
	var line := Color("eeeadd")
	_material.set_shader_parameter("frost_amount", snow_coverage)
	_material.set_shader_parameter("edge_half_size", half + Vector2(8, 7))
	for band in 10:
		var x := -playing_length * 0.5 + playing_length * (band + 0.5) / 10.0
		var color := turf_color.lightened(0.055) if band % 2 else turf_color
		b.box(Vector3(x, 0, 0), Vector3(playing_length / 10.0, 0.035, field_size.y), color)
	for side in [-1.0, 1.0]:
		b.box(Vector3(side * (half.x - end_length * 0.5), 0, 0), Vector3(end_length, 0.04, field_size.y), end_zone_color, 5.0)
		b.box(Vector3(0, 0.035, side * half.y), Vector3(field_size.x, 0.025, 0.16), line, 5.0)
		b.box(Vector3(side * half.x, 0.035, 0), Vector3(0.16, 0.025, field_size.y), line, 5.0)
		_goal(b, side * (half.x + 2.0), side)
		if minnesota_branding:
			MINNESOTA.append_end_zone_text(b, Vector3(side * (half.x - end_length * 0.5), 0.08, 0), side, end_length * 0.78, field_size.y * 0.84)
	for yard in 21:
		var x := -playing_length * 0.5 + playing_length * yard / 20.0
		b.box(Vector3(x, 0.04, 0), Vector3(0.13 if yard % 2 == 0 else 0.08, 0.025, field_size.y), line, 5.0)
		for hash_mark in 4:
			var tick_x := x + playing_length * (hash_mark + 1) / 100.0
			if yard == 20: continue
			for z in [-half.y + 0.5, -3.0, 3.0, half.y - 0.5]:
				b.box(Vector3(tick_x, 0.05, z), Vector3(0.08, 0.025, 0.45), line, 5.0)
	if minnesota_branding:
		MINNESOTA.append_field_mark(b, Vector3(0, 0.085, 0), playing_length * 0.17)
	if show_teams:
		var players := PLAYERS.new()
		players.name = "Players"
		players.field_size = field_size
		players.team_colors = [MINNESOTA.MAROON if minnesota_branding else Color("976966"), Color("e5dcc8")]
		players.paint = _material
		players.animate = animate_players
		_generated(players)

func _goal(b: RefCounted, x: float, side: float) -> void:
	var gold := Color("c5ad74")
	var support: Array[Vector3] = [Vector3(x + side * 1.2, 0, 0),
		Vector3(x + side * 1.2, 2.2, 0), Vector3(x, 3.3, 0)]
	b.tube(support, 0.11, gold)
	b.rod(Vector3(x, 3.3, -3.0), Vector3(x, 3.3, 3.0), 0.075, gold)
	for z in [-3.0, 3.0]:
		b.rod(Vector3(x, 3.3, z), Vector3(x, 7.0, z), 0.065, gold)

