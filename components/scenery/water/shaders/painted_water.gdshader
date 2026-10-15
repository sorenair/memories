shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D paint_mask : repeat_enable, filter_linear_mipmap;
uniform vec4 deep_color : source_color;
uniform vec4 body_color : source_color;
uniform vec4 shallow_color : source_color;
uniform vec4 foam_color : source_color;
uniform float flow_speed = 0.22;
uniform vec2 flow_direction = vec2(0.25, 1.0);
uniform float ripple_scale = 1.6;
uniform float caustic_strength = 0.55;
uniform float highlight_amount = 0.55;
uniform float wave_activity = 0.72;
uniform float foam_amount = 0.9;
uniform float foam_width = 0.18;
uniform float foam_cell_size = 1.0;
uniform float wave_height = 0.008;
uniform vec2 water_size = vec2(4.5, 3.3);
uniform float depth_gradient = 0.72;
uniform float motion_phase = 0.0;
varying vec3 paint_position;
varying float shore_depth;
varying float painted_depth;
// Different directions, wavelengths, and phase speeds produce interference,
// rather than translating a single wave pattern across the whole body.
vec3 wave_phases(vec2 world, float t) {
	return vec3(dot(world, vec2(0.94, 0.34)) * 1.9 + t,
		dot(world, vec2(-0.45, 0.89)) * 2.7 - t * 1.17 + 1.3,
		dot(world, vec2(0.20, -0.98)) * 3.8 + t * 0.73 + 2.7);
}
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	shore_depth = COLOR.r;
	painted_depth = clamp(0.5 + dot(VERTEX.xz / water_size, vec2(0.35, -1.0)), 0.0, 1.0);
	vec3 phases = wave_phases(world.xz * ripple_scale / 1.6, TIME * flow_speed * 3.2);
	float swell = dot(sin(phases), vec3(0.50, 0.30, 0.20));
	VERTEX.y += swell * wave_height * wave_activity * smoothstep(0.0, 0.3, shore_depth);
	paint_position = world;
}
void fragment() {
	vec2 p = paint_position.xz * ripple_scale * 0.15;
	float t = TIME * flow_speed * 3.2;
	vec2 drift = flow_direction * TIME * flow_speed * 0.012;
	vec2 phase = vec2(motion_phase * 0.013, motion_phase * 0.007);
	vec3 phases = wave_phases(paint_position.xz * ripple_scale / 1.6, t);
	vec3 wave = sin(phases);
	vec3 slope = cos(phases);
	vec2 wave_bend = vec2(slope.x * 0.94 - slope.y * 0.45 + slope.z * 0.20,
		slope.x * 0.34 + slope.y * 0.89 - slope.z * 0.98) * 0.012;
	// Counter-moving low-frequency fields stretch and compress the painted shapes.
	// This evolves even with zero directional flow, as crossing swells still travel.
	vec4 current_a = texture(paint_mask, p * 0.63 + phase + vec2(t * 0.019, -t * 0.013));
	vec4 current_b = texture(paint_mask, p.yx * 0.91 + phase + vec2(-t * 0.015, t * 0.022) + vec2(0.43, 0.17));
	vec2 turbulence = vec2(current_a.b - current_b.b, current_a.a - current_b.a) * 0.065;
	vec4 broad = texture(paint_mask, p * 0.32 + phase);
	vec2 warp = vec2(broad.b - 0.5, broad.a - 0.5) * 0.085;
	vec2 deformation = (turbulence + wave_bend) * wave_activity;
	vec4 brush = texture(paint_mask, p * vec2(0.85, 1.10) + warp + deformation - drift + phase);
	vec4 overlay = texture(paint_mask, p * vec2(1.45, 1.65) - warp * 0.65 - deformation * 0.82 + drift * 0.6 + vec2(0.37, 0.61) + phase);
	float depth_field = mix(smoothstep(0.18, 0.85, broad.b), 1.0 - painted_depth, depth_gradient);
	vec3 water = mix(deep_color.rgb, body_color.rgb, 0.12 + depth_field * 0.80);
	// Varied opaque strokes: deep pools, translucent-looking turquoise brushwork,
	// and smaller overlapping shapes. Shore foam is composed separately below.
	water = mix(water, deep_color.rgb, brush.r * (0.10 + (1.0 - depth_field) * 0.24));
	water = mix(water, shallow_color.rgb, (1.0 - brush.r) * (0.08 + depth_field * 0.48));
	water = mix(water, body_color.rgb, overlay.r * 0.16);
	water = mix(water, shallow_color.rgb, depth_field * depth_field * 0.50);
	float grain = texture(paint_mask, p * 9.0 + phase).r;
	water *= 0.96 + brush.a * 0.065 + (grain - 0.5) * 0.025;
	// Crests gather and lose light as swells meet. Wider patches emerge where
	// waves reinforce one another, then break into softer painted highlights.
	float interference = dot(wave, vec3(0.46, 0.32, 0.22));
	float crest = smoothstep(0.12, 0.72, interference);
	float seam = smoothstep(0.34 + wave.y * 0.10 * wave_activity, 0.85, brush.g);
	float broken = smoothstep(0.25, 0.65, overlay.b) * smoothstep(0.10, 0.50, broad.r);
	float caustic = seam * broken * caustic_strength * mix(1.0, 0.50 + crest * 0.95, wave_activity);
	float glint = smoothstep(0.65, 0.94, overlay.g) * smoothstep(0.50, 0.85, brush.b) * highlight_amount;
	glint *= mix(1.0, 0.30 + crest * 1.3, wave_activity);
	float wash = crest * smoothstep(0.35, 0.75, current_a.b) * wave_activity;
	water = mix(water, shallow_color.rgb, wash * 0.14);
	water *= 1.0 + interference * wave_activity * 0.035;
	vec3 reflected = mix(shallow_color.rgb, foam_color.rgb, smoothstep(0.25, 0.80, caustic + glint));
	water = mix(water, reflected, clamp(caustic + glint, 0.0, 0.88));
	// Shore foam is a painted layer in this same opaque pass: no border mesh.
	float shore_meters = shore_depth * min(water_size.x, water_size.y) * 0.5;
	if (foam_amount > 0.0 && shore_meters < foam_width * 1.6) {
		// Large slow-moving cells cut solid foam into ribbons rather than fine fizz.
		vec2 foam_uv = paint_position.xz * (0.24 / max(foam_cell_size, 0.01)) + phase;
		vec4 froth = texture(paint_mask, foam_uv + vec2(t * 0.012, -t * 0.018));
		float lap = sin(t * 1.05 - paint_position.x * 0.72 + paint_position.z * 0.85);
		float width = foam_width * (0.82 + froth.b * 0.22 + lap * 0.22);
		float aa = max(fwidth(shore_meters) * 1.1, 0.006);
		float ribbon = 1.0 - smoothstep(width - aa, width + aa, shore_meters);
		float cell_growth = sin(t * 0.72 + froth.r * 6.28318) * 0.12;
		float holes = smoothstep(0.55, 0.60, froth.a + cell_growth);
		holes *= smoothstep(width * 0.15, width * 0.45, shore_meters);
		float foam = ribbon * (1.0 - holes);
		// Keep the shoreline opaque, then fade the foam layer into the water.
		float opacity = 1.0 - smoothstep(width * 0.12, width, shore_meters);
		foam *= opacity * foam_amount;
		water = mix(water, foam_color.rgb, foam);
	}
	ALBEDO = water;
}
