shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float steam_strength = 0.4;
uniform float animation_time = -1.0;
void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 world = center + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y) * size;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	assembly_position = world;
}
void fragment() {
	float t = animation_time >= 0.0 ? animation_time : TIME;
	float y = 1.0 - UV.y;
	float density = 0.0;
	for (int i = 0; i < 3; i++) {
		float id = float(i);
		float center = 0.5 + sin(y * 5.0 - t * 0.75 + id * 2.0) * y * 0.16;
		float width = mix(0.025, 0.07, y);
		float line = exp(-pow((UV.x - center) / width, 2.0));
		float rise = 0.55 + 0.45 * sin(y * 10.0 - t * 1.2 + id);
		density += line * rise;
	}
	ALBEDO = vec3(0.94, 0.95, 0.91);
	ALPHA = min(density, 1.0) * smoothstep(0.0, 0.12, y) * (1.0 - smoothstep(0.4, 1.0, y)) * steam_strength * 0.26 * assembly_clarity(assembly_position);
}
