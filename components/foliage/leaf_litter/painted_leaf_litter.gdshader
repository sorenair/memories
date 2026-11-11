shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 ochre_color : source_color = vec4(0.83, 0.56, 0.23, 1);
uniform vec4 rust_color : source_color = vec4(0.57, 0.29, 0.15, 1);
uniform vec4 cream_color : source_color = vec4(0.92, 0.79, 0.50, 1);
uniform float flutter_strength = 0.0;
uniform float flutter_speed = 0.7;
varying vec3 paint;
varying vec2 brush_uv;
varying float haze;
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	// Tiny leaf-edge lift, anchored in place: never a scrolling layer or airborne effect.
	float phase = INSTANCE_CUSTOM.b * 6.283185;
	float flutter = (0.5 + 0.5 * sin(TIME * flutter_speed + phase)) * flutter_strength;
	VERTEX.y += flutter * abs(VERTEX.x) * abs(VERTEX.x);
	float hue = INSTANCE_CUSTOM.r;
	vec3 pigment = mix(rust_color.rgb, ochre_color.rgb, smoothstep(0.08, 0.60, hue));
	pigment = mix(pigment, cream_color.rgb, smoothstep(0.76, 1.0, hue));
	paint = pigment * (0.95 + INSTANCE_CUSTOM.g * 0.045);
	brush_uv = UV;
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(origin, 1)).xyz));
}
void fragment() {
	// Broad, softly edged pigment regions cross the whole leaf rather than
	// following individual fan triangles. There is no contrasting stalk or vein.
	float fold = smoothstep(-0.22, 0.24, brush_uv.x + sin(brush_uv.y * 2.4) * 0.055);
	float wash = smoothstep(-0.75, 0.75, brush_uv.y);
	vec3 color = paint * (0.910 + fold * 0.110 + wash * 0.020);
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
}
