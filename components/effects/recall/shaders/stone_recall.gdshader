shader_type spatial;
render_mode unshaded, fog_disabled;
uniform vec4 base_color : source_color;
uniform vec4 shadow_color : source_color;
uniform vec4 mid_color : source_color;
uniform vec4 highlight_color : source_color;
uniform float plane_variation = 0.025;
#include "res://components/effects/recall/shaders/solid_recall.gdshaderinc"
varying vec3 local_position;
varying vec3 painted_color;
varying float haze;
void vertex() {
	local_position = VERTEX;
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	// One clean, painted tone per physical plane. Triangulation is invisible.
	vec3 color = mix(shadow_color.rgb, mid_color.rgb, smoothstep(0.18, 0.70, light));
	color = mix(color, highlight_color.rgb, smoothstep(0.72, 1.0, light));
	painted_color = color * (1.0 + (COLOR.r - 0.5) * plane_variation);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	float clarity = solid_recall_clarity(local_position);
	if (clarity <= 0.001) { discard; }
	vec3 color = painted_color;
	float contact = 1.0 - smoothstep(-0.03, 0.12, local_position.y);
	color = mix(color, base_color.rgb, contact * 0.22);
	ALBEDO = mix(recall_void_color.rgb, mix(color, vec3(0.87, 0.86, 0.77), haze), smoothstep(0.0, 1.0, clarity));
}
