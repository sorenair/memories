shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 halo_color : source_color = vec4(0.65, 0.61, 0.87, 1.0);
uniform vec2 display_size = vec2(5.4, 2.6);
uniform float brightness = 1.1;
void vertex() {
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = abs((UV - 0.5) * (display_size + vec2(1.0))) - display_size * 0.5;
	float distance = length(max(p, vec2(0.0)));
	float feather = exp(-distance * 7.5) * (1.0 - smoothstep(0.35, 0.49, distance));
	float assembly = assembly_clarity(assembly_position);
	ALBEDO = halo_color.rgb;
	ALPHA = feather * brightness * 0.13 * assembly;
}
