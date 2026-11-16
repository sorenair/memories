shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 glass_color : source_color = vec4(0.68, 0.77, 0.74, 1.0);
void vertex() {
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float brush = sin(assembly_position.y * 5.0 + assembly_position.x * 2.2);
	ALBEDO = glass_color.rgb;
	ALPHA = (0.09 + smoothstep(0.3, 0.8, brush) * 0.06) * assembly_clarity(assembly_position);
}
