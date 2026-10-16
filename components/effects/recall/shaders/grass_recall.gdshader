shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// Solid, low-poly leaves: no alpha cards, texture samples, or shadow passes.
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform float wind_strength = 0.10;
uniform float wind_speed = 0.8;
uniform vec3 explorer_position = vec3(0.0, -1000.0, 0.0);
uniform float bend_radius = 0.65;
varying vec3 paint;
varying float height_mix;
varying float distance_haze;
varying float edge_bleach;

#include "res://components/effects/recall/shaders/recall_field.gdshaderinc"
uniform bool recall_groundcover = false;
varying float recall_growth;
varying float recall_color;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = INSTANCE_CUSTOM.b * 6.28318;
	float field = recall_field(origin.xz);
	float delay = INSTANCE_CUSTOM.g * 0.035;
	recall_growth = recall_groundcover
		? smoothstep(0.12 + delay, 0.68 + delay, field)
		: smoothstep(0.30 + delay, 0.98, field);
	recall_color = smoothstep(0.2, 0.95, field);
	float wave = sin(TIME * wind_speed + origin.x * 0.8 + origin.z * 0.6 + phase * 0.3);
	float flutter = sin(TIME * wind_speed * 1.7 + phase) * 0.20;
	float anchored = UV.y * UV.y;
	VERTEX.x += (wave + flutter) * wind_strength * anchored;
	VERTEX.z += cos(TIME * wind_speed * 0.7 + phase) * wind_strength * 0.35 * anchored;
	vec2 away = origin.xz - explorer_position.xz;
	float distance_to_player = length(away);
	float influence = 1.0 - smoothstep(0.0, bend_radius, distance_to_player);
	// Ease through the center instead of abruptly flipping the bend direction.
	vec3 world_push = vec3(away.x, 0.0, away.y) / sqrt(dot(away, away) + 0.0144);
	vec3 local_push = vec3(dot(normalize(MODEL_MATRIX[0].xyz), world_push), 0.0,
		dot(normalize(MODEL_MATRIX[2].xyz), world_push));
	VERTEX += local_push * influence * anchored * 0.23;
	VERTEX.y -= influence * anchored * 0.10;
	// Deform first, then grow about the instance root. Hidden grass cannot sway.
	VERTEX.y *= recall_growth;
	VERTEX.xz *= recall_groundcover ? recall_growth : mix(0.25, 1.0, recall_growth);
	float tint = INSTANCE_CUSTOM.r;
	vec3 middle = mix(shade_color.rgb, leaf_color.rgb, smoothstep(0.10, 0.75, tint));
	paint = mix(middle, sun_color.rgb, smoothstep(0.66, 1.0, tint));
	paint *= mix(0.91, 1.06, INSTANCE_CUSTOM.g);
	height_mix = UV.y;
	edge_bleach = pow(1.0 - INSTANCE_CUSTOM.a, 2.0) * 0.65;
	distance_haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(origin, 1.0)).xyz));
}
void fragment() {
	if (recall_growth <= 0.001) { discard; }
	// Broad painted bands, with dark roots tying leaves into the ground pigment.
	float band = smoothstep(0.06, 0.45, height_mix) * 0.64 + smoothstep(0.45, 0.9, height_mix) * 0.36;
	vec3 color = mix(root_color.rgb, paint, 0.15 + band * 0.85) * COLOR.rgb;
	vec3 resolved = mix(color, vec3(0.87, 0.86, 0.77), max(distance_haze, edge_bleach));
	// Roots acquire pigment before tips. At completion this is the base shader.
	float clarity = smoothstep(0.0, 1.0, recall_color + (1.0 - height_mix) * 0.22);
	ALBEDO = mix(recall_void_color.rgb, resolved, clarity);
}
