shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D pigment_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D caustic_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D shore_field : repeat_disable, filter_linear;
uniform vec2 field_origin;
uniform vec2 field_size = vec2(6.0);
uniform bool stream_body = false;
uniform float flow_offset = 0.0;
uniform vec4 deep_color : source_color;
uniform vec4 body_color : source_color;
uniform vec4 shallow_color : source_color;
uniform vec4 foam_color : source_color;
uniform vec4 sky_color : source_color = vec4(0.55, 0.78, 0.73, 1.0);
uniform vec3 light_direction = vec3(-0.45, 0.82, -0.35);
uniform float flow_speed = 0.22;
uniform vec2 flow_direction = vec2(0.25, 1.0);
uniform float ripple_scale = 1.4;
uniform float paint_contrast = 0.6;
uniform float depth_distance = 1.6;
uniform float caustic_strength = 0.36;
uniform float highlight_amount = 0.55;
uniform float normal_strength = 0.30;
uniform float reflection_strength = 0.25;
uniform float wave_activity = 0.6;
uniform float wave_height = 0.008;
uniform float foam_amount = 1.0;
uniform float foam_width = 0.34;
uniform float foam_cell_size = 1.0;
uniform float motion_phase = 0.0;
varying vec3 paint_position;
varying vec2 field_uv;
varying vec2 stream_uv;
varying vec2 axis_x;
varying vec2 axis_z;
vec3 wave_phases(vec2 world, float t) {
	return vec3(dot(world, vec2(0.94, 0.34)) * 1.9 + t,
		dot(world, vec2(-0.45, 0.89)) * 2.7 - t * 1.17 + 1.3,
		dot(world, vec2(0.20, -0.98)) * 3.8 + t * 0.73 + 2.7);
}
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	field_uv = (VERTEX.xz - field_origin) / field_size;
	stream_uv = UV;
	float distance = textureLod(shore_field, field_uv, 0.0).r;
	vec3 phases = wave_phases(world.xz * ripple_scale / 1.6, TIME * flow_speed * 3.2);
	VERTEX.y += dot(sin(phases), vec3(0.50, 0.30, 0.20)) * wave_height * wave_activity * smoothstep(0.0, 0.4, distance);
	paint_position = world;
	axis_x = normalize(MODEL_MATRIX[0].xz);
	axis_z = normalize(MODEL_MATRIX[2].xz);
}
void fragment() {
	vec4 shore = texture(shore_field, field_uv);
	// Geometry defines the outer body; registered rock sections cut interior holes.
	if (shore.r < -0.025) { discard; }
	float distance = max(shore.r, 0.0);
	vec2 local_flow = stream_body ? shore.gb : flow_direction;
	vec2 flow = axis_x * local_flow.x + axis_z * local_flow.y;
	float speed = shore.a * (stream_body ? 1.0 : min(length(flow_direction), 1.0));
	vec2 direction = length(flow) > 0.01 ? normalize(flow) : vec2(0.0, 1.0);
	vec2 cross_flow = vec2(direction.y, -direction.x);
	vec2 world = paint_position.xz;
	vec2 phase = vec2(motion_phase * 0.013, motion_phase * 0.007);
	float t = TIME * flow_speed;
	vec3 phases = wave_phases(world * ripple_scale / 1.6, t * 3.2);
	vec3 swell = sin(phases);
	vec3 slope = cos(phases);
	// Flow-aligned ripples and phase-blended advection keep streams readable on bends.
	vec2 aligned = (stream_body ? stream_uv + vec2(0.0, flow_offset) : vec2(dot(world, cross_flow), dot(world, direction))) * ripple_scale * 0.11;
	float cycle = t * 0.18 * max(wave_activity, speed);
	float phase_a = fract(cycle);
	float phase_b = fract(cycle + 0.5);
	float blend = abs(phase_a * 2.0 - 1.0);
	vec2 current = flow * speed * (stream_body ? 0.48 : 0.12);
	vec4 n_a = texture(normal_mask, aligned + phase - vec2(0.0, phase_a * speed * 0.16));
	vec4 n_b = texture(normal_mask, aligned + phase - vec2(0.0, phase_b * speed * 0.16) + vec2(0.37, 0.19));
	vec2 ripples = mix(n_a.rg, n_b.rg, blend) * 2.0 - 1.0;
	vec2 broad_ripples = texture(normal_mask, world * ripple_scale * 0.065 + vec2(-t * 0.015, t * 0.021) + phase).rg * 2.0 - 1.0;
	vec2 wave_slope = vec2(slope.x * 0.94 - slope.y * 0.45 + slope.z * 0.20, slope.x * 0.34 + slope.y * 0.89 - slope.z * 0.98);
	vec2 slopes = (cross_flow * ripples.x + direction * ripples.y + broad_ripples * 0.6 + wave_slope * 0.08) * normal_strength * wave_activity;
	vec3 normal = normalize(vec3(-slopes.x, 1.0, -slopes.y));
	vec2 deformation = slopes * 0.06;
	vec2 paint_uv = world * 0.12 * ripple_scale + phase;
	vec4 pigment = texture(pigment_mask, paint_uv + deformation);
	vec4 underpaint = texture(pigment_mask, paint_uv * 0.47 + vec2(0.43, 0.61));
	// Depth follows the physical shore and rocks; broad paint modulates the basin.
	float depth = smoothstep(0.0, max(depth_distance, 0.2), distance);
	depth = clamp(depth + (underpaint.r - 0.5) * depth * 0.28, 0.0, 1.0);
	vec3 water = mix(shallow_color.rgb, body_color.rgb, smoothstep(0.0, 0.55, depth));
	water = mix(water, deep_color.rgb, smoothstep(0.25, 1.0, depth) * 0.78);
	float quiet = smoothstep(0.25, 0.70, pigment.b);
	float brush = (pigment.r - 0.5) * paint_contrast;
	water = mix(water, shallow_color.rgb, max(-brush, 0.0) * (0.6 + quiet));
	water = mix(water, deep_color.rgb, max(brush, 0.0) * 0.85);
	water *= 0.985 + pigment.g * 0.03;
	// Independent caustics are a restrained shallow-water layer, not cell outlines
	// on every pigment shape. Opposing deformation makes luminous patches evolve.
	vec2 c_uv = world * ripple_scale * 0.11 + phase;
	vec4 c_a = texture(caustic_mask, c_uv + deformation - current * phase_a * 0.1);
	vec4 c_b = texture(caustic_mask, c_uv + deformation - current * phase_b * 0.1 + vec2(0.31, 0.57));
	float caustic = mix(c_a.r * c_a.g, c_b.r * c_b.g, blend);
	caustic = smoothstep(0.035, 0.28, caustic) * caustic_strength * (1.0 - depth * 0.78) * quiet;
	water = mix(water, mix(shallow_color.rgb, foam_color.rgb, 0.55), caustic * 0.7);
	// Analytic sky cue and a broad painted specular lobe respond to viewing angle.
	vec3 view = normalize(INV_VIEW_MATRIX[3].xyz - paint_position);
	float fresnel = pow(1.0 - max(dot(normal, view), 0.0), 3.0);
	vec3 sky = mix(sky_color.rgb * 0.65, sky_color.rgb, clamp(reflect(-view, normal).y * 0.5 + 0.5, 0.0, 1.0));
	water = mix(water, sky, reflection_strength * (0.12 + fresnel * 0.88));
	vec3 halfway = normalize(normalize(light_direction) + view);
	float broad_light = pow(max(dot(normal, halfway), 0.0), 22.0);
	float painted_light = smoothstep(0.28, 0.78, broad_light) * (0.35 + pigment.g * 0.65);
	water = mix(water, mix(sky_color.rgb, foam_color.rgb, 0.55), painted_light * highlight_amount * 0.18);
	// Preserve one white band with large cells and an inward opacity fade.
	if (foam_amount > 0.0 && distance < foam_width * 1.4) {
		vec2 foam_uv = world * (0.24 / max(foam_cell_size, 0.01)) + phase;
		vec4 froth = texture(foam_mask, foam_uv + vec2(t * 0.0384, -t * 0.0576));
		float lap = sin(t * 3.36 - world.x * 0.72 + world.y * 0.85);
		float width = foam_width * (0.82 + froth.b * 0.22 + lap * 0.22);
		float aa = max(fwidth(distance) * 1.1, 0.006);
		float band = 1.0 - smoothstep(width - aa, width + aa, distance);
		float growth = sin(t * 2.304 + froth.r * 6.28318) * 0.12;
		float holes = smoothstep(0.55, 0.60, froth.a + growth) * smoothstep(width * 0.15, width * 0.45, distance);
		float opacity = 1.0 - smoothstep(width * 0.12, width, distance);
		water = mix(water, foam_color.rgb, band * (1.0 - holes) * opacity * foam_amount);
	}
	ALBEDO = water;
}
