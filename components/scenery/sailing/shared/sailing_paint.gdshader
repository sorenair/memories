shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.55;
uniform float paint_phase = 0.0;
uniform float wind_strength = 0.035;
uniform float bob_amount = 0.025;
uniform float motion_speed = 1.0;
uniform float animation_time = -1.0;
varying vec3 paint_position;
varying vec3 painted;
varying float material_kind;

void vertex() {
	float t = (animation_time >= 0.0 ? animation_time : TIME) * motion_speed;
	material_kind = UV2.x;
	paint_position = VERTEX;
	// The sail weight vanishes at all three sewn edges, so the rig stays attached.
	float cloth = step(2.5, material_kind);
	VERTEX.x += cloth * UV2.y * wind_strength * (sin(t * 1.35 + VERTEX.y * 1.2) + 0.3 * sin(t * 2.1 - VERTEX.z * 2.0));
	float roll = sin(t * 0.65 + paint_phase) * bob_amount * 0.20;
	mat2 turn = mat2(vec2(cos(roll), sin(roll)), vec2(-sin(roll), cos(roll)));
	VERTEX.xy = turn * VERTEX.xy;
	NORMAL.xy = turn * NORMAL.xy;
	VERTEX.y += sin(t * 0.9 + paint_phase) * bob_amount;
	vec3 n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(n, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	// Cloth remains luminous cream on either side rather than becoming a dark card.
	light = mix(light, abs(dot(n, normalize(vec3(-0.45, 0.82, 0.35)))) * 0.65 + 0.35, cloth);
	float shade = mix(0.76, 0.96, smoothstep(0.26, 0.43, light));
	shade = mix(shade, 1.035, smoothstep(0.71, 0.84, light));
	painted = COLOR.rgb * shade;
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 p = paint_position;
	float wash = sin(p.x * 2.9 + sin(p.y * 2.1 + paint_phase)) * sin(p.z * 2.0 + p.y * 1.3);
	float broad = smoothstep(-0.35, 0.5, wash);
	ALBEDO = painted * mix(0.955, 1.04, mix(0.5, broad, pigment_strength));
	float a = assembly_clarity(assembly_position);
	if (a <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, a));
}
