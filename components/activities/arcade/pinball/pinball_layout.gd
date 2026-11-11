@tool
extends RefCounted
## Shared coordinates for the painted machine and its local X/Z simulation.
const FIELD_MIN := Vector2(-0.37,-0.61)
const FIELD_MAX := Vector2(0.37,0.59)
const BALL_RADIUS := 0.021
const HOME := Vector2(0.339,0.52)
const BUMPER_RADIUS := 0.105
const BUMPERS: Array[Vector2] = [Vector2(-0.16,-0.31),Vector2(0.16,-0.38),Vector2(0.03,-0.08)]
const FLIPPER_RADIUS := 0.032
const SLING_RADIUS := 0.0475
const SLING_HALF_RUN := 0.0425
const GUIDE_RADIUS := 0.006
const GUIDE_A := Vector2(0.306,0.55)
const GUIDE_B := Vector2(0.306,-0.43)
const DEFLECTOR_RADIUS := 0.008
const DEFLECTOR_A := Vector2(0.27,-0.57)
const DEFLECTOR_B := Vector2(0.35,-0.49)
const POST_RADIUS := 0.014
const SCORE_POSITION := Vector3(0,1.31,-0.531)
const SCORE_SIZE := Vector2(0.50,0.074)

static func surface_y(z: float) -> float:
	return 0.973-z*0.214

static func on_surface(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(point.x,surface_y(point.y)+height,point.y)

static func ball_center(point: Vector2) -> Vector3:
	# Offset by the sphere/plane distance, not just a world-Y radius.
	return on_surface(point,BALL_RADIUS*sqrt(1.0+0.214*0.214))

static func flippers() -> Array[Dictionary]:
	return [
		{"a":Vector2(-0.24,0.35),"b":Vector2(-0.08,0.46),"radius":FLIPPER_RADIUS},
		{"a":Vector2(0.24,0.35),"b":Vector2(0.08,0.46),"radius":FLIPPER_RADIUS}
	]

static func slings() -> Array[Vector2]:
	return [Vector2(-0.25,0.19),Vector2(0.25,0.19)]

static func posts() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in range(10): result.append(Vector2(-0.31,lerpf(-0.52,0.4,float(i)/9.0)))
	return result
