shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never, shadows_disabled, fog_disabled;

uniform float visibility : hint_range(0.0, 1.0) = 0.0;
uniform float selected : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = mat3(VIEW_MATRIX) * (MODEL_NORMAL_MATRIX * NORMAL);
	vec2 direction = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	direction /= max(length(direction), 0.001);
	float breathe = 0.12 * sin(TIME * 2.4);
	float pixels = mix(1.35, 2.4 + breathe, selected) * visibility;
	clip.xy += direction * pixels * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = vec3(1.0);
	ALPHA = visibility * mix(0.55, 0.96, selected);
}
