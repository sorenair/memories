shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float age_mix;
varying float visibility;
varying float sparkle;
float ember_hash(float x) { return fract(sin(x * 127.1 + 31.7) * 43758.5453); }
vec3 ember_path(float age, float phase, float seed, float t) {
	float launch = 0.08 + seed * 0.18;
	vec2 direction = vec2(cos(phase), sin(phase));
	vec2 sideways = vec2(-direction.y, direction.x);
	vec2 drift = direction * fire_size.x * (launch + age * (0.18 + seed * 0.42));
	drift += sideways * sin(age * 5.0 + phase) * age * fire_size.x * 0.13;
	float rise = 1.0 - pow(1.0 - clamp(age, 0.0, 1.0), 1.45);
	float y = fire_size.y * (0.30 + rise * (spark_height - 0.30));
	float plume_h = clamp((y - smoke_base_height()) / smoke_height, 0.0, 1.0);
	drift += smoke_center(plume_h,t).xz * 0.70 + wind * age * age * 0.50;
	return vec3(drift.x, y, drift.y);
}
void vertex() {
	float t = fire_clock(TIME);
	float group = floor(INSTANCE_CUSTOM.x * 6.0);
	float emission_phase = mix(INSTANCE_CUSTOM.x, group / 6.0 + INSTANCE_CUSTOM.y * 0.04, spark_burstiness);
	float clock = t * (0.66 + group * 0.055) + emission_phase;
	float age = fract(clock);
	float cycle = floor(clock);
	float seed = ember_hash(cycle + INSTANCE_CUSTOM.z * 43.0);
	float phase = INSTANCE_CUSTOM.z * 6.283185 + seed * 1.3;
	float envelope = smoothstep(0.0, 0.035, age) * (1.0 - smoothstep(0.48, 0.88, age));
	float size = spark_size * mix(0.70, 1.30, seed) * sqrt(smoothstep(0.0, 0.035, age)) * intensity * recall_visibility;
	float streak = smoothstep(0.58, 0.9, INSTANCE_CUSTOM.w);
	vec3 velocity = normalize(ember_path(min(age + 0.01, 0.99), phase, seed,t) - ember_path(max(age - 0.01, 0.0), phase, seed,t) + vec3(0.0, 0.0001, 0.0));
	vec3 right = normalize(cross(velocity, vec3(0.0, 0.0, 1.0)));
	vec3 across = normalize(cross(right, velocity));
	float stretch = mix(0.85, 2.4, streak) * (0.85 + seed * 0.35);
	vec3 p = right * VERTEX.x * size * 0.48 + across * VERTEX.z * size * 0.48 + velocity * VERTEX.y * size * stretch;
	p += ember_path(age, phase, seed,t);
	VERTEX = p;
	NORMAL = normalize(right * NORMAL.x + velocity * NORMAL.y + across * NORMAL.z);
	age_mix = age;
	visibility = envelope;
	sparkle = 0.82 + sin(t * (12.0 + seed * 9.0) + phase) * 0.18;
}
void fragment() {
	if (visibility < 0.01 || spark_amount <= 0.0 || intensity <= 0.0 || recall_visibility <= 0.001) { discard; }
	float head = 1.0 - smoothstep(0.12, 0.55, UV.y);
	vec3 color = mix(flame_color.rgb, edge_color.rgb, smoothstep(0.55, 1.0, age_mix) * 0.75);
	color = mix(color, core_color.rgb, head * (1.0 - smoothstep(0.15, 0.7, age_mix)) * 0.95);
	float face = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = mix(edge_color.rgb, color, smoothstep(0.1, 0.55, face)) * sparkle;
	EMISSION = color * glow_strength * (0.45 + head * 0.8) * sparkle;
	ALPHA = visibility;
}
