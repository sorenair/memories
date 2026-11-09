shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// One straight tapered ribbon, with soft edges and painted variation inside.
uniform vec4 light_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);
uniform float beam_height = 4.5;
uniform vec2 source_offset = vec2(-1.5, -1.0);
uniform vec2 footprint = vec2(2.8, 1.8);
uniform float source_width = 0.75;
uniform float opacity = 0.18;
uniform float paint_variation = 0.28;
uniform float drift_speed = 0.08;
uniform float paint_seed = 0.0;
uniform float recall_visibility = 1.0;
// Interpolate actual lateral distance, then normalize by the taper per fragment.
// Interpolating raw UV.x across a trapezoid creates a diagonal kink between triangles.
varying vec2 shaft_coordinate;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
void vertex() {
	float t = UV.y;
	vec3 local_center = vec3(source_offset.x * t, beam_height * t, source_offset.y * t);
	vec3 world_center = (MODEL_MATRIX * vec4(local_center, 1.0)).xyz;
	// Keep each cross-section horizontal and shared across all four vertices.
	// A tilted axis/view cross-product can sink one lower corner through the floor.
	vec3 across = vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z);
	if (length(across) < 0.001) { across = vec3(1.0, 0.0, 0.0); }
	across = normalize(across);
	float local_width = mix(footprint.x, source_width, t);
	shaft_coordinate = vec2(VERTEX.x * local_width * 0.5, t);
	float width = local_width * length(MODEL_MATRIX[0].xyz);
	vec3 world = world_center + across * VERTEX.x * width * 0.5;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
}
void fragment() {
	float t = shaft_coordinate.y;
	float clock = TIME * drift_speed;
	vec2 q = vec2(shaft_coordinate.x / max(mix(footprint.x, source_width, t) * 0.5, 0.001), t);
	float brush = noise(vec2(q.x * 3.5 + paint_seed, t * 2.8 - clock * 0.12));
	float edge = 1.0 - smoothstep(0.15, 1.0, abs(q.x));
	float ends = smoothstep(0.0, 0.16, t) * (1.0 - smoothstep(0.76, 1.0, t));
	float strokes = 0.82 + sin(q.x * 11.0 + paint_seed) * 0.12 + sin(q.x * 23.0 + paint_seed * 0.3) * 0.06;
	float pigment = mix(1.0, 0.65 + brush * 0.35, paint_variation);
	float breathe = 0.96 + 0.04 * sin(clock * 0.7 + paint_seed);
	ALBEDO = light_color.rgb;
	ALPHA = opacity * edge * ends * strokes * pigment * breathe * light_color.a * recall_visibility;
}
