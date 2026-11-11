shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
varying vec3 pigment;
varying vec3 paint_position;
varying float fade;
void vertex() {
	pigment = COLOR.rgb;
	fade = COLOR.a;
	paint_position = VERTEX;
}
void fragment() {
	vec3 p = paint_position;
	float wash = sin(p.x * 3.2 + sin(p.z * 2.8)) * sin(p.z * 5.1 + p.x * 0.7);
	ALBEDO = pigment * mix(0.96, 1.025, smoothstep(-0.3, 0.5, wash));
	ALPHA = fade * (0.88 + wash * 0.12);
}
