shader_type spatial;
render_mode unshaded, fog_disabled;
varying vec3 paint;
varying float haze;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float light = dot(normalize(MODEL_NORMAL_MATRIX * NORMAL), normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	float middle = smoothstep(0.30, 0.43, light);
	float sun = smoothstep(0.69, 0.82, light);
	paint = mix(COLOR.rgb * 0.76, COLOR.rgb, middle);
	float pigment = smoothstep(0.03, 0.12, max(COLOR.r, max(COLOR.g, COLOR.b)));
	paint = mix(paint, mix(COLOR.rgb, vec3(1.0, 0.98, 0.90), 0.16 * pigment), sun);
	haze = smoothstep(12.0, 30.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	ALBEDO = mix(paint, vec3(0.94, 0.935, 0.89), haze);
}
