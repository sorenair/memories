shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform sampler2D route : repeat_disable, filter_linear;
uniform float route_length = 10.0;
uniform float stroke_length = 0.95;
uniform float stroke_width = 0.11;
uniform float drift_speed = 0.34;
uniform float float_height = 0.48;
uniform float wander = 0.16;
uniform vec4 wisp_color : source_color = vec4(0.65, 0.81, 0.74, 1.0);
uniform vec4 edge_color : source_color = vec4(0.28, 0.50, 0.55, 1.0);
uniform float opacity = 0.5;
varying float life;
varying float individuality;
varying float flutter;
vec3 route_point(float t) {
	return textureLod(route, vec2((clamp(t, 0.0, 1.0) * 255.0 + 0.5) / 256.0, 0.5), 0.0).rgb;
}
void vertex() {
	float clock = TIME * drift_speed;
	float phase = INSTANCE_CUSTOM.r;
	individuality = INSTANCE_CUSTOM.g;
	float head = fract(phase + clock / max(route_length, 0.05));
	float length_fraction = min(stroke_length * mix(0.65, 1.25, INSTANCE_CUSTOM.b) / max(route_length, 0.05), 0.3);
	float t = head - (1.0 - UV.x) * length_fraction;
	vec3 center = route_point(t);
	vec3 tangent = route_point(t + 0.004) - route_point(t - 0.004);
	if (length(tangent) < 0.0001) { tangent = vec3(0.0, 0.0, -1.0); }
	tangent = normalize(tangent);
	float sway = clock * 1.4 + phase * 25.0;
	vec3 lateral = cross(tangent, vec3(0.0, 1.0, 0.0));
	center += lateral * sin(sway + UV.x * 2.5) * wander;
	center.y += float_height + sin(sway * 0.79 + UV.x * 3.0) * wander * 0.35;
	vec3 world = (MODEL_MATRIX * vec4(center, 1.0)).xyz;
	vec3 world_tangent = normalize(mat3(MODEL_MATRIX) * tangent);
	vec3 view = normalize(INV_VIEW_MATRIX[3].xyz - world);
	vec3 across = cross(world_tangent, view);
	if (length(across) < 0.001) { across = INV_VIEW_MATRIX[0].xyz; }
	across = normalize(across);
	float taper = pow(max(sin(UV.x * 3.14159), 0.0), 0.8);
	float breathe = 0.82 + 0.18 * sin(sway * 0.63);
	world += across * VERTEX.y * stroke_width * taper * breathe * mix(0.65, 1.2, INSTANCE_CUSTOM.a);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	// Fade before either end so wrapped strokes never visibly teleport.
	life = smoothstep(length_fraction, length_fraction + 0.05, head) * (1.0 - smoothstep(0.90, 1.0, head));
	life *= 0.65 + 0.35 * sin(sway * 0.47) * sin(sway * 0.47);
	flutter = clock * 0.5 + phase * 14.0;
}
void fragment() {
	float cross_stroke = abs(UV.y * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(0.18, 1.0, cross_stroke);
	float length_fade = pow(max(sin(UV.x * 3.14159), 0.0), 0.6);
	// Broad uneven pigment rather than particles, sparks, or a hard glowing tube.
	float brush = 0.78 + 0.12 * sin(UV.x * 19.0 + UV.y * 5.0 + individuality * 18.0) + 0.10 * sin(UV.x * 37.0 - UV.y * 8.0 + flutter);
	float core = (1.0 - smoothstep(0.0, 0.65, cross_stroke)) * 0.65;
	ALBEDO = mix(edge_color.rgb, wisp_color.rgb, core + UV.x * 0.25);
	ALPHA = opacity * life * edge * length_fade * brush;
}
