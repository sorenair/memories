shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;

uniform vec3 start_point = vec3(-2.0, 0.65, 0.0);
uniform vec3 end_point = vec3(2.0, 1.0, -1.0);
uniform float arc_height = 0.38;
uniform float curve_bend = 0.24;
uniform float stroke_width = 0.42;
uniform vec4 pigment_color : source_color = vec4(1.0);
uniform vec4 edge_color : source_color = vec4(0.93, 0.93, 0.93, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0);
uniform float opacity = 0.86;
uniform float glow_strength = 1.0;
uniform float evolution_strength = 1.0;
uniform float travel_duration = 5.5;
uniform float trail_duration = 2.8;
uniform float rest_duration = 1.6;
uniform float playback_speed = 1.0;
uniform float motion_amount = 0.06;
uniform float wash_height = 0.018;
uniform float wash_opacity = 0.14;
uniform float seed_phase = 0.15;
uniform float route_length = 4.2;
uniform bool surface_layer = false;
// Deterministic render verification. A negative value uses the live shader clock.
uniform float time_override = -1.0;
uniform bool use_route = false;
uniform sampler2D route_texture : filter_linear, repeat_disable;
uniform bool randomized_start = true;
uniform bool single_pass = false;
uniform float pulse_interval = 0.0;
uniform float guide_opacity = 1.0;
varying float paint_age;
varying float paint_clock;
varying float head_progress;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1,0)), f.x),
		mix(hash21(i + vec2(0,1)), hash21(i + vec2(1,1)), f.x), f.y);
}
vec3 gesture(float t) {
	if (use_route) {
		return textureLod(route_texture,vec2(mix(0.5/256.0,255.5/256.0,t),0.5),0.0).xyz;
	}
	vec3 delta = end_point - start_point;
	vec3 direction = length(delta) > 0.0001 ? normalize(delta) : vec3(0);
	vec3 side = cross(direction, vec3(0,1,0));
	side = dot(side, side) < 0.001 ? vec3(1,0,0) : normalize(side);
	return mix(start_point, end_point, t) + vec3(0, sin(t * PI) * arc_height, 0)
		+ side * sin(t * TAU) * sin(t * PI) * curve_bend;
}
float paint_life(float age, float progress) {
	// Short gathered mark at birth, longer swept paint in the middle,
	// then a shorter, released tail near arrival. Never extends past the cycle.
	float duration = trail_duration * mix(1.0,
		0.55 + 0.45 * sin(PI * progress), evolution_strength);
	return smoothstep(0.0, 0.18, age)
		* (1.0 - smoothstep(duration * 0.22, duration, age));
}
void vertex() {
	float clock = (time_override >= 0.0 ? time_override : TIME) * playback_speed;
	float cycle_length = travel_duration + trail_duration + rest_duration;
	float cycle = single_pass ? clock : mod(clock + (randomized_start ? seed_phase * cycle_length : 0.0), cycle_length);
	float progress = clamp(cycle / travel_duration, 0.0, 1.0);
	paint_age = cycle - UV.x * travel_duration;
	if (pulse_interval > 0.0) {
		// Several widely separated gestures can follow one route without drawing a line.
		float passage = clock - UV.x*travel_duration;
		paint_age = passage >= 0.0 ? mod(passage,pulse_interval) : passage;
		float departure = max(0.0,floor(passage/pulse_interval))*pulse_interval;
		progress = clamp((clock-departure)/travel_duration,0.0,1.0);
	}
	head_progress = progress;
	paint_clock = clock;
	float lead = smoothstep(0.0, 0.23, paint_age);
	float life = paint_life(paint_age, progress);
	float bloom = (0.28 + 0.98 * smoothstep(0.0, 0.34, progress))
		* (1.0 - 0.65 * smoothstep(0.68, 1.0, progress));
	float pressure = pow(lead, 0.48) * (0.35 + 0.65 * life);
	pressure *= mix(1.0, bloom, evolution_strength);
	pressure *= 0.78 + 0.22 * sin(PI * UV.x);
	pressure *= 1.0 + sin(UV.x * 19.0 - clock * 1.25) * 0.12 * evolution_strength;
	vec3 center = gesture(UV.x);
	vec3 tangent = gesture(min(1.0, UV.x + 0.003)) - gesture(max(0.0, UV.x - 0.003));
	if (length(tangent) < 0.0001) { tangent = vec3(1,0,0); }
	tangent = normalize(tangent);
	vec3 across;
	if (surface_layer) {
		center.y = wash_height;
		across = vec3(-tangent.z, 0.0, tangent.x);
		if (length(across) < 0.0001) { across = vec3(1,0,0); }
		across = normalize(across);
		center += across * (UV.y * 2.0 - 1.0) * stroke_width * 0.9 * pressure;
	} else {
		vec3 world_tangent = normalize(mat3(MODEL_MATRIX) * tangent);
		vec3 world_center = (MODEL_MATRIX * vec4(center, 1.0)).xyz;
		vec3 to_camera = normalize(INV_VIEW_MATRIX[3].xyz - world_center);
		vec3 world_across = cross(world_tangent, to_camera);
		if (length(world_across) < 0.01) { world_across = INV_VIEW_MATRIX[0].xyz; }
		across = normalize(inverse(mat3(MODEL_MATRIX)) * normalize(world_across));
		float flutter = sin(UV.x * 7.0 - clock * 0.85 + seed_phase * TAU);
		center += (across * flutter + vec3(0, sin(UV.x * 9.0 + clock * 0.72), 0) * 0.35)
			* sin(PI * UV.x) * motion_amount;
		center += across * sin(UV.x * 13.0 - clock * 1.1) * sin(PI * UV.x)
			* stroke_width * 0.14 * evolution_strength;
		float cross_coordinate = UV.y * 2.0 - 1.0;
		// The same sheet contains the crisp pigment and its wider soft halo.
		center += across * cross_coordinate * 2.6 * stroke_width * 0.5 * pressure;
		center += tangent * sin(cross_coordinate * PI) * stroke_width * 0.12 * flutter * lead;
	}
	VERTEX = center;
}
void fragment() {
	float u = UV.x * route_length;
	float v = (UV.y * 2.0 - 1.0) * (surface_layer ? 1.0 : 2.6);
	float age = paint_age;
	float life = paint_life(age, head_progress);
	float endpoints = smoothstep(0.0, 0.035, UV.x) * (1.0 - smoothstep(0.965, 1.0, UV.x));
	float release = smoothstep(0.65, 0.98, head_progress) * evolution_strength;
	float morph = paint_clock * evolution_strength;
	vec2 brush_uv = vec2(u * 2.5 + seed_phase * 29.0, v * 2.0);
	float broad = noise2(brush_uv + vec2(morph * 0.12, sin(morph * 0.6) * 0.3));
	float bristles = noise2(vec2(u * 1.9 + seed_phase * 13.0 - morph * 0.18,
		v * 6.5 + sin(u * 2.6 + morph * 0.45) * 0.6 + broad * 0.8));
	float boundary = abs(v) + (broad - 0.5) * 0.24 + (bristles - 0.5) * 0.10;
	float edge = 1.0 - smoothstep(0.77, 1.0, boundary);
	float dry_brush = mix(0.22, 1.0, smoothstep(0.22, 0.66, bristles + life * 0.06));
	dry_brush = mix(dry_brush, 1.0, life * life * 0.38);
	// Arrival releases the broad paint into a few curling, separated filaments.
	float filaments = smoothstep(-0.20, 0.45, sin(v * 9.2 + sin(u * 2.0 - morph * 0.7) * 1.4));
	dry_brush *= mix(1.0, 0.12 + filaments * 0.88, release);
	float pigment = 0.70 + 0.30 * smoothstep(0.2, 0.8, broad);
	float paint_band = smoothstep(0.32, 0.47, broad) * 0.5 + smoothstep(0.61, 0.72, broad) * 0.5;
	vec3 color = mix(edge_color.rgb, pigment_color.rgb, 0.35 + paint_band * 0.65);
	float long_brush = noise2(vec2(u * 0.65 + seed_phase * 19.0, v * 4.0 + morph * 0.09));
	color = mix(color, highlight_color.rgb, smoothstep(0.45, 0.76, long_brush) * 0.65);
	float wet_head = 1.0 - smoothstep(0.4, 0.9, age);
	float core = clamp(opacity * (1.0 + wet_head * 0.15) * edge * dry_brush * pigment, 0.0, 1.0);
	float halo = exp(-v * v * 0.85) * (1.0 - smoothstep(2.1, 2.6, abs(v)))
		* glow_strength * 0.22 * (0.65 + wet_head * 0.35);
	float alpha = (core + halo * (1.0 - core)) * life * endpoints;
	if (surface_layer) {
		alpha = wash_opacity * life * endpoints * edge * (0.55 + broad * 0.45);
		color = mix(pigment_color.rgb, edge_color.rgb, 0.18);
	}
	ALBEDO = color;
	EMISSION = color * glow_strength * (surface_layer ? 0.0 : 0.16 * edge);
	ALPHA = alpha * guide_opacity;
}
