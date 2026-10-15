shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 shadow_color : source_color = vec4(0.25, 0.29, 0.28, 0.36);

void fragment() {
	float radius = length((UV - 0.5) * 2.0);
	// A broad feathered penumbra and a tighter contact patch under the feet.
	float feather = exp(-4.0 * radius * radius);
	float contact = exp(-18.0 * radius * radius);
	float edge = 1.0 - smoothstep(0.65, 1.0, radius);
	ALBEDO = shadow_color.rgb;
	ALPHA = (feather * 0.75 + contact * 0.25) * edge * shadow_color.a;
}
