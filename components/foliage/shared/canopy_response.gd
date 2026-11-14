extends RefCounted
## Smooth two-player response for low tree foliage, using the shared actor filter.
const RECALL = preload("res://components/effects/recall/component_recall.gd")
var positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var weights: Array[float] = [0.0, 0.0]
func clear(material: ShaderMaterial) -> void:
	weights = [0.0, 0.0]
	if material: material.set_shader_parameter("disturbance_sources", PackedVector4Array([Vector4.ZERO, Vector4.ZERO]))
func update(component: Node3D, material: ShaderMaterial, delta: float) -> void:
	if not material: return
	var actors := RECALL.explorers(component)
	var sources := PackedVector4Array()
	for index in range(2):
		var valid := index < actors.size()
		if valid:
			var target := actors[index].get_global_transform_interpolated().origin
			if weights[index] < 0.001 or positions[index].distance_squared_to(target) > 16.0:
				positions[index] = target
				weights[index] = 0.0
			else:
				positions[index] = positions[index].lerp(target, 1.0 - exp(-delta * 12.0))
		weights[index] = lerpf(weights[index], 1.0 if valid else 0.0, 1.0 - exp(-delta * 8.0))
		sources.append(Vector4(positions[index].x, positions[index].y, positions[index].z, weights[index]))
	material.set_shader_parameter("disturbance_sources", sources)
