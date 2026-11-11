shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float pigment_strength = 0.65;
uniform float paint_phase = 0.0;
varying vec3 paint;
varying vec3 position;
varying float material_kind;
varying float haze;
void vertex() {
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.74, 0.95, smoothstep(0.28, 0.39, light));
	shade = mix(shade, 1.03, smoothstep(0.71, 0.81, light));
	paint = COLOR.rgb * shade;
	position = VERTEX;
	material_kind = UV2.x;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(32.0, 75.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	// Broad pigment pools; no tiny noise, photoreal wear, or metallic reflections.
	vec3 p = position;
	float wash = sin(p.x * 4.1 + sin(p.y * 3.6 + paint_phase) + p.z * 1.2)
		* sin(p.y * 4.4 + sin(p.z * 3.0 + paint_phase));
	float band = smoothstep(-0.45, -0.15, wash) * 0.5 + smoothstep(0.2, 0.65, wash) * 0.5;
	float glow = smoothstep(1.5, 1.8, material_kind);
	vec3 color = paint * mix(0.94, 1.045, band * pigment_strength + (1.0 - pigment_strength) * 0.5);
	color = mix(color, COLOR.rgb, glow * 0.7);
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
	EMISSION = COLOR.rgb * glow * 0.16 * (1.0 - haze);
}
