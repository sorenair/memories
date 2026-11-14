shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float light_strength = 0.65;
varying float phase;
void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 world = center + INV_VIEW_MATRIX[0].xyz * VERTEX.x * size
		+ INV_VIEW_MATRIX[1].xyz * VERTEX.y * size;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	phase = INSTANCE_CUSTOM.r * 6.28318;
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float radius = length((UV - 0.5) * 2.0);
	float glow = exp(-radius * radius * 4.8) * (1.0 - smoothstep(0.65, 1.0, radius));
	float breath = 0.94 + sin(TIME * 0.55 + phase) * 0.06;
	ALBEDO = vec3(1.0, 0.97, 0.87);
	ALPHA = glow * light_strength * 0.24 * breath;
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
	ALPHA *= assembly;
}
