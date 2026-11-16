shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 beacon_color : source_color = vec4(1.0, 0.91, 0.65, 1.0);
uniform float beacon_strength = 0.65;
uniform float beacon_height = 9.73;
uniform float rotation_speed = 0.035;
uniform float beam_heading = 0.0;
uniform float beam_length = 8.0;
uniform float animation_time = -1.0;
uniform bool halo = false;
varying vec2 brush_uv;
void vertex() {
	brush_uv = UV;
	vec3 center;
	vec3 world;
	if (halo) {
		center = MODEL_MATRIX[3].xyz;
		world = center + INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y;
	} else {
		float clock = animation_time >= 0.0 ? animation_time : TIME;
		float angle = clock * rotation_speed * 6.283185 + beam_heading;
		vec3 direction = vec3(sin(angle), 0.0, cos(angle));
		vec3 world_direction = normalize(mat3(MODEL_MATRIX) * direction);
		float scale = length(MODEL_MATRIX[0].xyz);
		center = (MODEL_MATRIX * vec4(vec3(0, beacon_height, 0), 1.0)).xyz + world_direction * UV.y * beam_length * scale;
		vec3 to_camera = normalize(INV_VIEW_MATRIX[3].xyz - center);
		vec3 across = cross(world_direction, to_camera);
		if (length(across) < 0.001) { across = INV_VIEW_MATRIX[0].xyz; }
		world = center + normalize(across) * (UV.x * 2.0 - 1.0) * mix(0.10, beam_length * 0.12, UV.y) * scale;
	}
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	assembly_position = world;
}
void fragment() {
	float alpha;
	if (halo) {
		float r = length((brush_uv - 0.5) * 2.0);
		alpha = exp(-r * r * 5.0) * (1.0 - smoothstep(0.65, 1.0, r)) * 0.19;
	} else {
		float across = abs(brush_uv.x * 2.0 - 1.0);
		float edge = 1.0 - smoothstep(0.08, 1.0, across);
		float ends = smoothstep(0.02, 0.15, brush_uv.y) * (1.0 - smoothstep(0.45, 1.0, brush_uv.y));
		float paint = 0.88 + 0.12 * sin(brush_uv.x * 17.0 + brush_uv.y * 3.0);
		alpha = edge * ends * paint * 0.14;
	}
	ALBEDO = beacon_color.rgb;
	EMISSION = beacon_color.rgb * 0.15;
	ALPHA = alpha * beacon_strength * beacon_color.a * assembly_clarity(assembly_position);
}
