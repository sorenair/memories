shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.55;
uniform float paint_phase = 0.0;
uniform float beacon_strength = 0.65;
uniform float rotation_speed = 0.035;
uniform float beam_heading = 0.0;
uniform float animation_time = -1.0;
uniform vec4 stripe_color : source_color = vec4(0.68,0.31,0.27,1.0);
uniform int stripe_count = 6;
uniform float tower_height = 9.0;
uniform float base_band_height = 0.0;
uniform vec4 base_band_color : source_color = vec4(0.24,0.22,0.21,1.0);
varying float paint_shade;
varying vec3 pigment;
varying vec3 point;
varying float kind;
void vertex() {
	point = VERTEX;
	kind = UV2.x;
	vec3 n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(n, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.73, 0.95, smoothstep(0.27, 0.43, light));
	shade = mix(shade, 1.035, smoothstep(0.72, 0.85, light));
	paint_shade = shade;
	pigment = COLOR.rgb * shade;
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float wash = sin(point.x * 1.7 + sin(point.y * 0.85 + paint_phase)) * sin(point.z * 1.9 + point.y * 0.6);
	vec3 color = pigment * mix(0.96, 1.035, mix(0.5, smoothstep(-0.2, 0.5, wash), pigment_strength));
	// Only the tagged shaft receives stripes. Openings and fittings stay intact.
	if (kind > 2.5 && point.y > 0.40 && point.y < tower_height - 0.24) {
		float band = floor((point.y-0.40)/max(tower_height-0.64,0.1)*float(stripe_count));
		if (mod(band,2.0)>0.5) {
			color = stripe_color.rgb*paint_shade*mix(0.97,1.025,smoothstep(-0.2,0.5,wash));
		}
	}
	if (base_band_height > 0.0 && kind != 1.0 && point.y < base_band_height) {
		color = base_band_color.rgb * paint_shade * mix(0.94, 1.04, wash * 0.5 + 0.5);
	}
	float lamp = step(1.5, kind)*(1.0-step(2.5,kind));
	float t = animation_time >= 0.0 ? animation_time : TIME;
	float turn = t * rotation_speed * 6.283185 + beam_heading;
	float lens = 0.8 + 0.2 * cos(atan(point.x, point.z) - turn);
	color = mix(color, COLOR.rgb * (0.72 + beacon_strength * 0.3), lamp);
	ALBEDO = color;
	EMISSION = COLOR.rgb * lamp * beacon_strength * lens * 0.55;
	float a = assembly_clarity(assembly_position);
	if (a <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, a));
	EMISSION *= a;
}
