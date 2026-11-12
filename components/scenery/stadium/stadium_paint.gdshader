shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// The same vertex-color workflow, broad pigment pools and soft stepped lighting
// as the First Meeting house and arcade; longer haze range for stadium scale.
uniform float pigment_strength = 0.65;
uniform float paint_phase = 0.0;
uniform float frost_amount = 0.0;
uniform float crowd_bounce_height = 0.0;
uniform float crowd_bounce_speed = 1.0;
uniform sampler2D artwork_texture : source_color, filter_linear_mipmap;
uniform sampler2D minnesota_mark : source_color, filter_linear_mipmap;
uniform vec2 edge_half_size = vec2(1000.0);
uniform vec3 void_color : source_color = vec3(0.94, 0.935, 0.89);
varying vec3 paint;
varying vec3 p;
varying float kind;
varying float haze;
float hash21(vec2 at) {
	vec3 q = fract(vec3(at.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float noise2(vec2 at) {
	vec2 cell = floor(at);
	vec2 f = fract(at);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), f.x), f.y);
}
float drift_noise(vec2 at) {
	float value = 0.0;
	float gain = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		value += noise2(at) * gain;
		at = mat2(vec2(1.6, -1.2), vec2(1.2, 1.6)) * at + vec2(8.3, 17.9);
		gain *= 0.5;
	}
	return value;
}
void vertex() {
	p = VERTEX;
	kind = UV2.x;
	if (abs(kind - 7.0) < 0.1) {
		// UVs are constant across each figure: phase and pace, baked once.
		float bounce = 0.5 + 0.5 * sin(TIME * crowd_bounce_speed * UV.y + UV.x);
		float variation = mix(0.65, 1.0, fract(UV.x * 2.73));
		VERTEX.y += crowd_bounce_height * variation * bounce;
	}
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.76, 0.96, smoothstep(0.28, 0.39, light));
	shade = mix(shade, 1.025, smoothstep(0.71, 0.81, light));
	paint = COLOR.rgb * shade;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(70.0, 155.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	float wash = sin(p.x * 1.65 + sin(p.z * 1.9) + paint_phase) * sin(p.z * 2.2 + sin(p.y * 1.4));
	vec3 color = paint * mix(0.955, 1.035, smoothstep(-0.55, 0.55, wash) * pigment_strength);
	if (abs(kind - 6.0) < 0.1) {
		vec4 mark = texture(minnesota_mark, UV);
		if (mark.a < 0.5) { discard; }
		color *= mark.rgb;
	}
	if (abs(kind - 8.0) < 0.1) { color *= texture(artwork_texture, UV).rgb; }
	float field = 1.0 - smoothstep(0.1, 0.3, abs(kind));
	float branding = 1.0 - smoothstep(0.1, 0.3, abs(kind - 4.0));
	float marking = 1.0 - smoothstep(0.1, 0.3, abs(kind - 5.0));
	vec2 snow_at = p.xz * vec2(0.13, 0.19) + vec2(paint_phase * 3.7, -paint_phase * 1.9);
	vec2 warp = vec2(noise2(snow_at * 0.48 + 23.4), noise2(snow_at * 0.57 - 41.7));
	float drift = drift_noise(snow_at + (warp - 0.5) * 4.0);
	float threshold = mix(0.81, 0.25, frost_amount);
	float frost = smoothstep(threshold - 0.07, threshold + 0.12, drift) * step(0.001, frost_amount);
	float broken_edge = mix(0.8, 1.0, noise2(snow_at * 7.0));
	color = mix(color, vec3(0.89, 0.91, 0.87), (field + marking * 0.7 + branding * 0.35) * frost * broken_edge);
	float edge = max(abs(p.x) / edge_half_size.x, abs(p.z) / edge_half_size.y);
	float dissolve = smoothstep(0.89, 1.0, edge);
	// Broken pigment edges instead of a hard rectangular miniature base.
	if (dissolve > 0.35 + wash * 0.3) { discard; }
	color = mix(color, void_color, dissolve);
	float glow = 1.0 - smoothstep(0.1, 0.3, abs(kind - 3.0));
	ALBEDO = mix(color, void_color, haze);
	EMISSION = COLOR.rgb * glow * 0.22 * (1.0 - haze);
}
