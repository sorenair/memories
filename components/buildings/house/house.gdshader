shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float pigment_strength = 0.65;
uniform float paint_phase = 0.0;
uniform float wall_top = 3.25;
uniform float foundation_height = 0.45;
varying vec3 paint;
varying vec3 paint_position;
varying float paint_kind;
varying float haze;
void vertex() {
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	float middle = smoothstep(0.27, 0.38, light);
	float highlight = smoothstep(0.70, 0.80, light);
	paint = COLOR.rgb * mix(0.78, 0.96, middle);
	paint = mix(paint, COLOR.rgb * 1.04, highlight);
	paint_position = VERTEX;
	paint_kind = UV2.x;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(30.0, 70.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	vec3 p = paint_position;
	float plaster = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 1.0));
	float roof = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 2.0));
	float glow = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 4.0));
	// Broad, connected pigment washes read like brushwork, never gritty noise.
	float brush = sin(p.x * 1.65 + sin(p.y * 1.9 + p.z * 0.7) + paint_phase)
		* sin(p.y * 2.2 + sin(p.z * 1.4 + paint_phase));
	float wash = smoothstep(-0.55, 0.55, brush);
	vec3 paper_paint = mix(vec3(0.955, 0.95, 0.935), vec3(1.025, 1.015, 0.995), wash);
	vec3 color = paint * mix(vec3(1.0), paper_paint, plaster * pigment_strength);
	float under_eave = smoothstep(wall_top - 0.34, wall_top - 0.05, p.y);
	float at_foundation = 1.0 - smoothstep(foundation_height + 0.04, foundation_height + 0.38, p.y);
	color *= 1.0 - plaster * (under_eave * 0.085 + at_foundation * 0.045);
	color *= 1.0 + roof * brush * pigment_strength * 0.018;
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
	EMISSION = color * glow * 0.18 * (1.0 - haze);
}
