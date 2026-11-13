shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float speed = 1.0;
uniform float tap_feedback = 0.0;
uniform float activity : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 1.0;
uniform float decay = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[0] *= length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX[1] *= length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX[2] *= length(MODEL_MATRIX[2].xyz);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float t = TIME * speed;
	float angle = atan(p.y, p.x);
	float r = length(p) + 0.025 * sin(angle * 5.0 + t + seed) + 0.018 * sin(angle * 9.0 - t);
	float spread = 1.0 + tap_feedback * 0.20 + (1.0 - pow(1.0 - decay, 3.0)) * 0.6;
	float flash = 1.0 + 2.5 * sin(min(decay * 3.0, 1.0) * 3.14159265);
	float wash = pow(max(0.0, 1.0 - r / spread), 3.0) * 0.30 * flash * (1.0 + tap_feedback * 1.8);
	ALBEDO = glow_color.rgb;
	ALPHA = wash * mix(0.22, 0.65, activity) * (1.0 - decay) * (0.86 + 0.14 * sin(t * 1.8 + seed));
}
