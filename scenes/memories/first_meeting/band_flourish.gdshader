shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 ink : source_color = vec4(0.15, 0.68, 0.56, 1.0);
uniform float progress = 0.0;
uniform float sweep_side = 1.0;
varying float ribbon;
varying float age;

void vertex() {
	ribbon = UV2.x;
	age = clamp((progress - 0.08 - ribbon * 0.075) / 0.72, 0.0, 1.0);
	vec2 start = vec2(-0.12, -0.12);
	vec2 bend_a = vec2(0.41, -0.10);
	vec2 bend_b = vec2(0.61, 0.22);
	vec2 tip = vec2(0.27, 0.38);
	if (ribbon > 1.5) {
		start = vec2(0.53, 0.29);
		bend_a = vec2(0.58, 0.33);
		bend_b = vec2(0.65, 0.38);
		tip = vec2(0.65, 0.43);
	} else if (ribbon > 0.5) {
		start = vec2(0.10, -0.229);
		bend_a = vec2(0.22, -0.24);
		bend_b = vec2(0.43, -0.17);
		tip = vec2(0.50, -0.045);
	}
	float u = UV.x;
	vec2 a = mix(start, bend_a, u);
	vec2 b = mix(bend_a, bend_b, u);
	vec2 c = mix(bend_b, tip, u);
	vec2 ab = mix(a, b, u);
	vec2 bc = mix(b, c, u);
	vec2 stroke = mix(ab, bc, u);
	vec2 tangent = normalize(bc - ab);
	float taper = pow(sin(u * 3.14159), 0.74);
	float width = mix(0.086, 0.04, ribbon * 0.5) * taper * (1.0 - age * 0.34);
	stroke += vec2(-tangent.y, tangent.x) * (UV.y - 0.5) * width;
	stroke += vec2(age * 0.18, age * 0.29);
	stroke.x *= sweep_side;
	VERTEX = (inverse(MODELVIEW_MATRIX) * vec4(stroke, 0.0, 0.0)).xyz;
}

void fragment() {
	float leading_edge = smoothstep(UV.x - 0.13, UV.x + 0.12, age * 3.2);
	float fade = smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.45, 1.0, age));
	float side = abs(UV.y * 2.0 - 1.0);
	float bristle = 0.84 + 0.16 * sin(UV.x * 47.0 + UV.y * 11.0 + ribbon);
	float edge = 1.0 - smoothstep(0.55, 0.99, side + (1.0 - bristle) * 0.2);
	vec3 ivory = vec3(1.0, 0.88, 0.63);
	vec3 highlight = mix(ink.rgb, ivory, (1.0 - side) * 0.24 + ribbon * 0.12);
	ALBEDO = highlight;
	ALPHA = leading_edge * fade * edge * bristle;
}
