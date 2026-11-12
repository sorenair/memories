shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;

#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
#include "res://components/characters/crowd/crowd_poses.gdshaderinc"
uniform vec4 clothing_a : source_color = vec4(0.447, 0.569, 0.475, 1.0);
uniform vec4 clothing_b : source_color = vec4(0.671, 0.510, 0.396, 1.0);
uniform vec4 clothing_c : source_color = vec4(0.439, 0.580, 0.667, 1.0);
uniform vec4 clothing_d : source_color = vec4(0.706, 0.627, 0.447, 1.0);
uniform vec4 skin_a : source_color = vec4(0.83, 0.68, 0.55, 1.0);
uniform vec4 skin_b : source_color = vec4(0.68, 0.49, 0.36, 1.0);
uniform vec4 skin_c : source_color = vec4(0.47, 0.33, 0.27, 1.0);
uniform vec4 skin_d : source_color = vec4(0.89, 0.77, 0.65, 1.0);
uniform vec4 hair_a : source_color = vec4(0.28, 0.26, 0.23, 1.0);
uniform vec4 hair_b : source_color = vec4(0.46, 0.36, 0.27, 1.0);
uniform vec4 hair_c : source_color = vec4(0.67, 0.59, 0.43, 1.0);
uniform vec4 hair_d : source_color = vec4(0.57, 0.56, 0.52, 1.0);
uniform vec4 atmosphere_color : source_color = vec4(0.94, 0.935, 0.89, 1.0);
uniform float softness : hint_range(0.0, 0.65) = 0.06;
uniform float silhouette_variation : hint_range(0.0, 1.0) = 0.8;
uniform float motion_strength : hint_range(0.0, 1.0) = 0.45;
uniform float motion_speed : hint_range(0.0, 2.0) = 0.75;
// A non-negative value freezes the shader clock for deterministic previews/tests.
uniform float preview_time = -1.0;
varying vec3 pigment;
varying vec3 smooth_normal;
varying vec3 local_position;
varying float haze;
varying float garment_kind;
varying float detail_choice;

float choice(float seed, float salt) {
	// Cheap stable instance hashes; reserve trigonometry for the actual idle motion.
	float p = fract(seed * 9.731 + salt * 0.13787);
	p *= p + 19.19;
	return fract(p * (p + seed + salt * 0.183));
}

vec3 pick_color(float value, vec3 a, vec3 b, vec3 c, vec3 d) {
	vec3 result = mix(a, b, step(0.25, value));
	result = mix(result, c, step(0.5, value));
	return mix(result, d, step(0.75, value));
}

void vertex() {
	float pose = floor(INSTANCE_CUSTOM.a * CROWD_POSE_COUNT);
	float identity = fract(INSTANCE_CUSTOM.a * CROWD_POSE_COUNT);
	float phase = identity * 6.283185;
	float t = (preview_time >= 0.0 ? preview_time : TIME) * motion_speed;
	vec3 rest_position = VERTEX;
	vec3 normal = NORMAL;
	if (abs(UV.x) > 0.5) {
		crowd_arm_pose(VERTEX, normal, sign(UV.x), UV.y, COLOR.r * 2.0, pose, t, phase, motion_strength);
	}
	float head_mask = UV2.y;
	float shape = silhouette_variation;
	float leg_length = mix(1.0, mix(0.85, 1.15, choice(identity, 1.0)), shape);
	float shoulder_width = mix(1.0, mix(0.88, 1.15, choice(identity, 2.0)), shape);
	float waist_width = mix(1.0, mix(0.86, 1.16, choice(identity, 3.0)), shape);
	float head_scale = mix(1.0, mix(0.90, 1.12, choice(identity, 4.0)), shape);
	vec3 head_pivot = vec3(0.0, 1.055, 0.0);
	VERTEX = mix(VERTEX, head_pivot + (VERTEX - head_pivot) * head_scale, head_mask);
	float upper_body = smoothstep(0.49, 0.74, VERTEX.y) * (1.0 - head_mask);
	float shoulders = smoothstep(0.67, 0.87, VERTEX.y);
	VERTEX.x *= mix(1.0, mix(waist_width, shoulder_width, shoulders), upper_body);
	VERTEX.z *= mix(1.0, mix(0.88, 1.16, choice(identity, 5.0)), upper_body * shape);
	// Independent leg/torso ratio, rather than merely scaling the entire person.
	VERTEX.y += min(VERTEX.y, 0.53) * (leg_length - 1.0);
	if (abs(UV.x) < 0.5 && head_mask < 0.5) {
		float foot = 1.0 - smoothstep(0.06, 0.52, rest_position.y);
		VERTEX.x += sign(rest_position.x) * mix(-0.015, 0.040, choice(identity, 13.0)) * foot * pose_strength;
		VERTEX.z += sign(rest_position.x) * mix(-0.047, 0.047, choice(identity, 14.0)) * foot * pose_strength;
	}
	float height = smoothstep(0.12, 1.17, VERTEX.y);
	VERTEX.x += (choice(identity, 6.0) - 0.5) * 0.065 * height * height * shape;
	VERTEX.z += (choice(identity, 7.0) - 0.5) * 0.050 * height * height * shape;
	// Fixed feet, quiet weight shift, very slight breathing; never a whole-body bob.
	float sway = sin(t * 0.83 + phase) + sin(t * 0.47 + phase * 2.3) * 0.35;
	VERTEX.x += sway * height * height * 0.022 * motion_strength;
	VERTEX.z += cos(t * 0.69 + phase * 1.8) * height * height * 0.014 * motion_strength;
	float breathe = sin(t * 1.85 + phase) * 0.008 * motion_strength;
	float chest = smoothstep(0.45, 0.77, VERTEX.y);
	VERTEX.x *= 1.0 + breathe * chest;
	VERTEX.z *= 1.0 + breathe * chest;
	float turn = ((choice(identity, 8.0) - 0.5) * 0.46 * shape + sin(t * 0.41 + phase * 2.7) * 0.065 * motion_strength) * head_mask;
	float tilt = (choice(identity, 9.0) - 0.5) * 0.20 * shape * head_mask;
	vec3 relative = VERTEX - vec3(0.0, 1.055 + 0.53 * (leg_length - 1.0), 0.0);
	mat2 turning = mat2(vec2(cos(turn), -sin(turn)), vec2(sin(turn), cos(turn)));
	mat2 tilting = mat2(vec2(cos(tilt), -sin(tilt)), vec2(sin(tilt), cos(tilt)));
	relative.xz = turning * relative.xz;
	relative.xy = tilting * relative.xy;
	VERTEX = relative + vec3(0.0, 1.055 + 0.53 * (leg_length - 1.0), 0.0);
	normal.xz = turning * normal.xz;
	normal.xy = tilting * normal.xy;
	vec3 clothes = pick_color(INSTANCE_CUSTOM.r, clothing_a.rgb, clothing_b.rgb, clothing_c.rgb, clothing_d.rgb);
	vec3 second = pick_color(choice(identity, 10.0), clothing_a.rgb, clothing_b.rgb, clothing_c.rgb, clothing_d.rgb);
	vec3 skin = pick_color(INSTANCE_CUSTOM.g, skin_a.rgb, skin_b.rgb, skin_c.rgb, skin_d.rgb);
	vec3 hair = pick_color(INSTANCE_CUSTOM.b, hair_a.rgb, hair_b.rgb, hair_c.rgb, hair_d.rgb);
	pigment = clothes;
	if (UV2.x > 0.5) { pigment = mix(second * mix(0.44, 0.79, choice(identity, 11.0)), hair * 0.65, 0.18); }
	if (UV2.x > 1.5) { pigment = skin; }
	if (UV2.x > 2.5) { pigment = hair; }
	if (UV2.x > 3.5) { pigment = mix(hair * 0.62, clothes * 0.47, 0.5); }
	if (UV2.x > 4.5) { pigment = mix(second, atmosphere_color.rgb, 0.12); }
	pigment *= mix(0.89, 1.08, fract(INSTANCE_CUSTOM.r * 7.37));
	smooth_normal = normalize(MODEL_NORMAL_MATRIX * normal);
	local_position = rest_position;
	garment_kind = UV2.x;
	detail_choice = choice(identity, 12.0);
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	assembly_position = world;
	haze = smoothstep(32.0, 75.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}

void fragment() {
	float light = dot(normalize(smooth_normal), normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.73, 0.94, smoothstep(0.32, 0.43, light));
	shade = mix(shade, 1.045, smoothstep(0.71, 0.82, light));
	// Large quiet pigment pools, not noisy fabric detail.
	float wash = sin(local_position.x * 13.0 + sin(local_position.y * 8.0)) * sin(local_position.y * 9.0 + local_position.z * 7.0);
	vec3 painted = pigment * shade * mix(0.96, 1.035, smoothstep(-0.25, 0.45, wash));
	// Occasional broad woven stripe: a quiet color block, not fine noisy texture.
	float stripe = smoothstep(0.766, 0.773, local_position.y) * (1.0 - smoothstep(0.807, 0.814, local_position.y));
	if (garment_kind < 0.5 && detail_choice > 0.73) {
		painted = mix(painted, mix(painted, atmosphere_color.rgb, 0.25), stripe);
	}
	painted = mix(painted, atmosphere_color.rgb, softness);
	ALBEDO = mix(painted, atmosphere_color.rgb, haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(atmosphere_color.rgb, ALBEDO, smoothstep(0.0, 1.0, assembly));
}
