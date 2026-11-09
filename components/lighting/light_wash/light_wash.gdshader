shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// A painted surface wash, compatible with the project's unshaded scenery.
uniform vec4 light_color : source_color = vec4(1.0, 0.90, 0.65, 1.0);
uniform float intensity = 0.65;
uniform float softness = 0.65;
uniform float paint_variation = 0.18;
uniform float paint_seed = 0.0;
uniform int wash_shape = 0;
uniform vec2 window_grid = vec2(2.0, 2.0);
uniform float pane_gap = 0.08;
uniform int motion = 0;
uniform float motion_speed = 1.0;
uniform float motion_amount = 0.18;
uniform float recall_visibility = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float brush = noise(q * 3.0 + vec2(paint_seed, paint_seed * 0.31));
	float radius = wash_shape == 0 ? length(q) : max(abs(q.x), abs(q.y));
	float irregularity = (brush - 0.5) * paint_variation * 0.12;
	float edge = 1.0 - smoothstep(1.0 - softness, 1.0, radius + irregularity);
	float falloff = wash_shape == 0 ? pow(max(1.0 - radius * 0.65, 0.0), 0.65) : 1.0;
	float panes = 1.0;
	if (wash_shape == 2) {
		vec2 cell = fract(UV * window_grid);
		vec2 feather = max(fwidth(cell), vec2(0.002));
		vec2 near_frame = min(cell, 1.0 - cell);
		vec2 clear_pane = smoothstep(vec2(pane_gap * 0.5), vec2(pane_gap * 0.5) + feather * 2.0, near_frame);
		panes = clear_pane.x * clear_pane.y;
	}
	float t = TIME * motion_speed;
	float modulation = 1.0;
	if (motion == 1) {
		float flicker = 0.5 + sin(t * 7.1 + paint_seed) * 0.25 + sin(t * 11.3 + 1.7) * 0.15 + sin(t * 3.7) * 0.1;
		modulation -= flicker * motion_amount;
	} else if (motion == 2) {
		modulation -= (0.5 + 0.5 * sin(t * 1.4 + paint_seed)) * motion_amount;
	}
	float pigment = mix(1.0, 0.82 + brush * 0.18, paint_variation);
	float opacity = edge * falloff * panes * pigment * intensity * light_color.a * modulation * recall_visibility;
	if (opacity <= 0.001) { discard; }
	ALBEDO = light_color.rgb;
	ALPHA = clamp(opacity, 0.0, 1.0);
}
