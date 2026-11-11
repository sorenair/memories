shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
varying vec3 paint;
varying float haze;
void vertex() {
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	float middle = smoothstep(0.25, 0.39, light);
	float highlight = smoothstep(0.68, 0.82, light);
	paint = COLOR.rgb * mix(0.69, 0.93, middle);
	paint = mix(paint, mix(COLOR.rgb, vec3(0.96, 0.95, 0.88), 0.18), highlight);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	ALBEDO = mix(paint, vec3(0.94, 0.935, 0.89), haze);
}
