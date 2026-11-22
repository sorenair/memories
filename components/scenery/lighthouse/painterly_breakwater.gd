@tool
extends PainterlyConcertComponent
## A concrete breakwater with an eight-sided lighthouse landing. Shore is local +Z.

const DECK_HEIGHT := 0.045
const PIER_HALF_WIDTH := 1.66
const PIER_FRONT := 1.90
const PIER_END := -13.20
const LANDING_CENTER := -13.75
const LANDING_RADIUS := 3.28

func _landing_outline() -> PackedVector2Array:
	var outline := PackedVector2Array()
	for index in range(8):
		var angle := (index + 0.5) * TAU / 8.0
		outline.append(Vector2(cos(angle) * LANDING_RADIUS, LANDING_CENTER + sin(angle) * LANDING_RADIUS))
	return outline

func get_walk_outline() -> PackedVector2Array:
	var strip := PackedVector2Array([
		Vector2(-PIER_HALF_WIDTH, PIER_FRONT), Vector2(-PIER_HALF_WIDTH, PIER_END),
		Vector2(PIER_HALF_WIDTH, PIER_END), Vector2(PIER_HALF_WIDTH, PIER_FRONT)])
	var outline := Geometry2D.merge_polygons(strip, _landing_outline())[0]
	var world_outline := PackedVector2Array()
	for point in outline:
		var world := to_global(Vector3(point.x, 0.0, point.y))
		world_outline.append(Vector2(world.x, world.z))
	return world_outline

func _build_geometry() -> Dictionary:
	var builder := GEOMETRY.new()
	builder.begin(_config())
	var section_count := 9
	var usable_length := PIER_FRONT - PIER_END
	for index in section_count:
		var length := usable_length / section_count
		var z := PIER_FRONT - (index + 0.5) * length
		var tone := body_color.lightened(builder.rng.randf_range(-0.035, 0.035))
		builder.box(Vector3(0, -0.37, z), Vector3(PIER_HALF_WIDTH * 2, 0.68, length), tone.darkened(0.10))
		builder.box(Vector3(0, DECK_HEIGHT - 0.038, z), Vector3(PIER_HALF_WIDTH * 2, 0.076, length - 0.012), tone)
	builder.colliders.append({"name": "Deck", "center": Vector3(0, -0.32, (PIER_FRONT + PIER_END) * 0.5),
		"size": Vector3(PIER_HALF_WIDTH * 2, (DECK_HEIGHT + 0.32) * 2, usable_length)})

	var landing := _landing_outline()
	var collision := PackedVector3Array()
	for index in landing.size():
		var a := landing[index]
		var b := landing[(index + 1) % landing.size()]
		var top_a := Vector3(a.x, DECK_HEIGHT + 0.007, a.y)
		var top_b := Vector3(b.x, DECK_HEIGHT + 0.007, b.y)
		var flare_a := Vector3(a.x * 1.17, -0.52, LANDING_CENTER + (a.y - LANDING_CENTER) * 1.17)
		var flare_b := Vector3(b.x * 1.17, -0.52, LANDING_CENTER + (b.y - LANDING_CENTER) * 1.17)
		var center := Vector3(0, DECK_HEIGHT + 0.007, LANDING_CENTER)
		builder.quad(center, top_a, top_b, center, body_color.darkened(0.045))
		builder.quad(top_a, flare_a, flare_b, top_b, accent_color)
		builder.quad(flare_a, Vector3(flare_a.x, -0.93, flare_a.z), Vector3(flare_b.x, -0.93, flare_b.z), flare_b,
			accent_color.darkened(0.24))
		collision.append(top_a)
		collision.append(top_a - Vector3.UP * 0.55)
		# Leave the north-facing edge open where the straight pier meets the landing.
		if (a.y + b.y) * 0.5 < LANDING_CENTER + 2.6:
			var edge := (top_b - top_a).normalized()
			var span := top_a.distance_to(top_b)
			var mid := (top_a + top_b) * 0.5 + Vector3.UP * 0.14
			builder.box(mid, Vector3(span, 0.29, 0.18), trim_color, 0,
				Basis(Vector3.UP, atan2(-edge.z, edge.x)))
	builder.colliders.append({"name": "Landing", "points": collision})
	return builder.finish()
