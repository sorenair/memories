@tool
class_name TreeVariants
extends RefCounted
## Layout multipliers preserve authored height/width and existing foliage systems.
enum Kind { BROADLEAF, OAK, BIRCH, WILLOW, PINE, CYPRESS }
const DEFINITIONS = [
	{"width": 1.0, "stem": 0.88, "trunk": 1.0, "leaf_size": 1.0, "leaf_shape": Vector3.ONE, "tint": 0.0},
	{"width": 1.15, "stem": 0.78, "trunk": 1.4, "leaf_size": 1.05, "leaf_shape": Vector3.ONE, "tint": -0.025},
	{"width": 0.48, "stem": 0.99, "trunk": 0.65, "leaf_size": 0.65, "leaf_shape": Vector3.ONE, "tint": 0.045},
	{"width": 1.05, "stem": 0.86, "trunk": 1.0, "leaf_size": 1.12, "leaf_shape": Vector3(0.95, 0.8, 1.3), "tint": 0.0},
	{"width": 0.78, "stem": 0.99, "trunk": 0.9, "leaf_size": 1.35, "leaf_shape": Vector3.ONE, "tint": -0.08},
	{"width": 0.34, "stem": 0.99, "trunk": 0.7, "leaf_size": 1.10, "leaf_shape": Vector3.ONE, "tint": -0.05}
]
static func definition(kind: int) -> Dictionary:
	return DEFINITIONS[clampi(kind, 0, DEFINITIONS.size() - 1)]
