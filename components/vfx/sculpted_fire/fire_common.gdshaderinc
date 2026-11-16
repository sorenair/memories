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
uniform float smoke_definition = 0.8;
uniform vec4 smoke_color : source_color = vec4(0.482, 0.467, 0.447, 1.0);
uniform float spark_amount = 0.65;
uniform float spark_height = 2.2;
uniform float spark_size = 0.03;
uniform float spark_variation = 0.65;
uniform float spark_burstiness = 0.35;
float fire_clock(float engine_time) {
	return (preview_time >= 0.0 ? preview_time : engine_time) * animation_speed + fire_phase;
}
float fire_noise(vec3 p) {
	// Broad, coherent pigment movement; deliberately no high-frequency grain.
	return sin(p.x * 1.7 + sin(p.z * 1.3)) * sin(p.y * 1.4 - p.z * 0.8) * 0.5 + 0.5;
}
float smoke_base_height() {
	return fire_size.y * mix(0.50, 0.62, body_fullness);
}
