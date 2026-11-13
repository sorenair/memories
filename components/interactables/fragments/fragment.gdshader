shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float speed = 1.0;
// Guided wisps can share their route's clock; ordinary fragments use live TIME.
uniform float time_override = -1.0;
uniform float tap_feedback = 0.0;
uniform float activity : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 1.0;
uniform int mote_count = 8;
uniform float wisp_strength = 1.0;
uniform float decay : hint_range(0.0, 1.0) = 0.0;
uniform float interaction_outline : hint_range(0.0, 1.0) = 0.0;
varying vec3 pigment_position;
varying vec3 painted_normal;
varying vec3 world_position;
varying float family;
varying float identity;
varying float visibility;
mat3 turn(float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}
mat3 bank(float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat3(vec3(c, s, 0), vec3(-s, c, 0), vec3(0, 0, 1));
}
void vertex() {
	float t = (time_override >= 0.0 ? time_override : TIME) * speed;
	family = UV2.x;
	identity = UV2.y;
	float id = identity;
	float phase = id * 1.91 + seed * 1.71;
	float release = smoothstep(0.0, 1.0, decay);
	visibility = 1.0;
	pigment_position = VERTEX;
	if (family > 1.5) {
		float age = fract(t * (0.08 + fract(id * 0.37) * 0.04) + fract(id * 0.618 + seed * 0.13));
		float angle = t * 0.19 + id * 2.39996 + seed;
		float radius = 1.10 + 0.42 * sin(id * 3.0 + age * 3.0);
		vec3 center = vec3(cos(angle) * radius, mix(-1.65, 2.2, age), sin(angle) * radius);
		center += normalize(vec3(cos(phase), 1.0, sin(phase))) * release * 2.0 * wisp_strength;
		visibility = smoothstep(0.0, 0.18, age) * (1.0 - smoothstep(0.73, 1.0, age));
		visibility *= (id < float(mote_count) ? 1.0 : 0.0) * (1.0 - decay);
		VERTEX = turn(angle) * VERTEX * mix(0.6, 1.0, activity) + center;
		NORMAL = turn(angle) * NORMAL;
	} else if (family > 0.5) {
		// A full orbit takes about 20–26 seconds. Different rates and phase-lagged
		// currents let the veils overtake one another without abrupt reversals.
		float orbit = t * (0.24 + id * 0.024) + sin(t * 0.33 + phase) * 0.12;
		float twist = sin(UV.y * 4.8 - t * 0.62 + phase) * 0.17;
		mat3 rotation = turn(orbit + twist) * bank(sin(t * 0.27 + phase) * 0.10);
		VERTEX.xz *= 1.0 + sin(t * 0.46 + phase + UV.y * 3.2) * 0.075;
		VERTEX = rotation * VERTEX;
		VERTEX.y += sin(t * 0.41 + phase) * 0.11;
		vec3 outward = vec3(cos(phase), 0.65, sin(phase));
		VERTEX += outward * release * 1.1 * wisp_strength;
		VERTEX.y += release * 1.2;
		VERTEX *= 1.0 + tap_feedback * 0.08;
		NORMAL = rotation * NORMAL;
	} else {
		VERTEX *= (1.0 + sin(t * 1.45 + seed) * 0.10 + tap_feedback * 0.30) * (1.0 - smoothstep(0.0, 0.65, decay));
		VERTEX.x += sin(t * 0.8 + seed) * 0.045;
		VERTEX.y += sin(t * 1.1 + seed) * 0.07;
	}
	painted_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	if (visibility < 0.01 || decay >= 0.999) { discard; }
	float t = (time_override >= 0.0 ? time_override : TIME) * speed;
	vec3 p = pigment_position;
	vec3 eye = normalize(CAMERA_POSITION_WORLD - world_position);
	float facing = abs(dot(normalize(painted_normal), eye));
	float core = 1.0 - step(0.5, family);
	float fleck = step(1.5, family);
	float veil = 1.0 - core - fleck;
	// Pale opalescent washes drift along the strands. No hard shell, glass shine,
	// surface perforation, or camera-facing symbol supplies the silhouette.
	float brush = sin(UV.y * 10.0 - t * 0.43 + identity * 2.0 + seed)
		* sin(UV.x * 4.0 + UV.y * 4.0 + identity);
	float pigment = smoothstep(-0.65, 0.65, brush);
	vec3 cool = mix(vec3(0.36, 0.45, 0.68), vec3(0.59, 0.52, 0.74), 0.5 + 0.5 * sin(identity * 2.0));
	vec3 ivory = vec3(1.0, 0.97, 0.86);
	vec3 paint = mix(cool, ivory, 0.24 + pigment * 0.52);
	paint = mix(paint, ivory, core * 0.95 + fleck * 0.70);
	paint = mix(paint, vec3(1.0, 0.99, 0.95), tap_feedback * 0.5);
	float across = abs(UV.x * 2.0 - 1.0);
	float feather = 1.0 - smoothstep(0.18 + brush * 0.06, 1.0, across);
	float ends = pow(max(sin(UV.y * 3.14159), 0.0), 0.65);
	// Soft lavender underpainting follows the actual curved strands. It remains
	// visible on pale scenery, while the feathered outer edge stays translucent.
	float stroke = exp(-pow((across - 0.64 + brush * 0.035) / 0.17, 2.0));
	float core_stroke = exp(-pow((facing - 0.30) / 0.16, 2.0));
	float ink = veil * stroke * 0.88 + core * core_stroke * 0.66;
	paint = mix(paint, vec3(0.25, 0.28, 0.42), clamp(ink, 0.0, 1.0));
	// A moving luminous thread sits inside a much softer painted veil.
	float thread = exp(-pow((UV.x - 0.48 - sin(UV.y * 7.0 + identity) * 0.07) * 11.0, 2.0));
	float traveling = 0.72 + 0.28 * sin(UV.y * 7.0 - t * 0.8 + identity * 2.0);
	float alpha = veil * feather * ends * (0.22 + pigment * 0.16 + thread * 0.18) * traveling;
	alpha *= mix(0.58, 1.0, activity) * (0.6 + facing * 0.4);
	alpha += core * smoothstep(0.02, 0.80, facing) * 0.92 * mix(0.65, 1.0, activity)
		+ fleck * 0.75 * mix(0.45, 1.0, activity);
	alpha += (veil * stroke * ends * 0.46 + core * core_stroke * 0.32) * mix(0.65, 1.0, activity);
	alpha *= visibility * (1.0 - smoothstep(0.0, 1.0, decay));
	alpha *= 1.0 + tap_feedback * 0.30;
	ALBEDO = paint * glow_color.rgb;
	EMISSION = glow_color.rgb * (core * (0.18 + activity * 0.30) * (0.88 + 0.12 * sin(t * 1.45 + seed)) + thread * veil * 0.08 + fleck * 0.20
		+ interaction_outline * veil * feather * 0.12) * (1.0 - decay) * (1.0 - ink * 0.95);
	ALPHA = clamp(alpha, 0.0, 0.96);
}
