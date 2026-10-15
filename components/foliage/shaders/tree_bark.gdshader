shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 bark_shadow : source_color = vec4(0.29, 0.25, 0.21, 1.0);
uniform vec4 bark_light : source_color = vec4(0.64, 0.54, 0.39, 1.0);
uniform vec4 root_color : source_color;
uniform float birch_marks = 0.0;
varying vec3 bark_position;
varying vec3 painted_color;
varying float haze;
void vertex() {
	bark_position = VERTEX;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	painted_color = mix(bark_shadow.rgb, bark_light.rgb, COLOR.r);
	// Root flare inherits a little ground pigment, tying wood into the meadow.
	painted_color = mix(mix(root_color.rgb, bark_shadow.rgb, 0.65), painted_color, smoothstep(0.0, 0.35, VERTEX.y));
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	float band = 1.0 - smoothstep(0.035, 0.10, abs(fract(bark_position.y * 4.5 + sin(bark_position.x * 7.0) * 0.12) - 0.5));
	float broken = smoothstep(0.15, 0.75, sin(bark_position.x * 20.0 + bark_position.z * 13.0 + floor(bark_position.y * 4.5) * 2.3));
	vec3 color = painted_color * (1.0 - birch_marks * band * broken * 0.45);
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
}
