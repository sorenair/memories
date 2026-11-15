uniform vec2 fire_size = vec2(1.55, 1.65);
uniform float body_fullness = 0.72;
uniform float intensity = 1.0;
uniform float animation_speed = 1.0;
uniform float curl_amount = 0.8;
uniform vec2 wind = vec2(0.16, 0.04);
uniform float fire_phase = 0.0;
uniform float preview_time = -1.0;
uniform float recall_visibility = 1.0;
uniform vec4 core_color : source_color = vec4(1.0, 0.94, 0.753, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.533, 0.145, 1.0);
uniform vec4 edge_color : source_color = vec4(0.875, 0.188, 0.125, 1.0);
uniform float glow_strength = 0.55;
uniform float smoke_amount = 0.65;
uniform float smoke_height = 2.4;
uniform float smoke_spread = 0.75;
uniform float smoke_turbulence = 0.7;
uniform vec4 smoke_color : source_color = vec4(0.424, 0.388, 0.369, 1.0);
uniform float spark_amount = 0.65;
uniform float spark_height = 2.2;
uniform float spark_size = 0.03;
uniform float spark_burstiness = 0.65;
float fire_clock(float engine_time) {
	return (preview_time >= 0.0 ? preview_time : engine_time) * animation_speed + fire_phase;
}
float tongue_age(float t, float index) {
	return fract(t * (1.04 + index * 0.137) + index / 3.0);
}
// The main tongues and their detached tips share a burst clock and profile.
void tongue_profile(float t, float index, out vec4 stem, out vec4 arc, out vec2 tip, out float bend) {
	float clock = t * (1.04 + index * 0.137) + index / 3.0;
	float age = fract(clock);
	float variation = sin(floor(clock) * 7.13 + index * 4.7 + fire_phase) * 0.5 + 0.5;
	float life = smoothstep(0.0, 0.09, age) * (1.0-smoothstep(0.72,1.0,age));
	float growth = smoothstep(0.0,0.18,age);
	float root_x = 0.10 + body_fullness * 0.07 + sin(t*2.1+index)*0.045;
	float root_y = 0.17 + growth*(0.14+variation*0.12) + age*0.16;
	float radius = (0.19+variation*0.14)*sqrt(life)*(0.75+growth*0.25);
	// Even a newborn tongue extends beyond its thick root cap. Shorter arcs
	// exposed round-ended stalks before the curling tip could become visible.
	float sweep = 1.35+smoothstep(0.02,0.72,age)*(0.40+curl_amount*1.60);
	vec2 center = vec2(root_x,root_y)-vec2(cos(-0.65),sin(-0.65)*1.25)*radius;
	stem = vec4(root_x,root_y,(0.17+variation*0.055)*life,(0.22+variation*0.035)*life);
	arc = vec4(center,radius,sweep);
	tip = center+vec2(cos(-0.65+sweep),sin(-0.65+sweep)*1.25)*radius;
	bend = sin(t*5.1+index*2.0)*0.22;
}
float fire_noise(vec3 p) {
	// Broad, coherent pigment movement; deliberately no high-frequency grain.
	return sin(p.x * 1.7 + sin(p.z * 1.3)) * sin(p.y * 1.4 - p.z * 0.8) * 0.5 + 0.5;
}
float smoke_base_height() {
	return fire_size.y * mix(0.32, 0.46, body_fullness);
}
