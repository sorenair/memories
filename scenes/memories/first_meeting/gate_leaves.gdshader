shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform float elapsed = 0.0;
uniform vec2 breeze = vec2(0.0, -1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.73, 0.18, 1.0);
uniform vec4 orange : source_color = vec4(0.95, 0.40, 0.09, 1.0);
uniform vec4 scarlet : source_color = vec4(0.76, 0.24, 0.15, 1.0);
varying vec3 paint;
varying float visibility;
varying float tipped;

mat2 turn(float angle) {
	return mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
}

void vertex() {
	vec4 seed = INSTANCE_CUSTOM;
	float age = clamp((elapsed - seed.r * 0.18) / 0.82, 0.0, 1.0);
	float phase = seed.b * 6.28318;
	float lift = sin(age * 3.14159);
	float tumble = phase + age * (4.4 + seed.g * 3.4);
	vec3 blade = VERTEX * mix(0.055, 0.105, seed.a);
	blade.xy = turn(tumble) * blade.xy;
	blade.xz = turn(phase + age * 2.2) * blade.xz;
	vec2 crosswind = vec2(-breeze.y, breeze.x);
	vec2 scatter = crosswind * (seed.g - 0.5) * 1.65 + breeze * (seed.a - 0.5) * 0.65;
	scatter += breeze * mix(0.65, 1.15, seed.a) * age;
	scatter += crosswind * sin(phase + age * 6.0) * lift * 0.34;
	VERTEX = blade + vec3(scatter.x, 0.045 + lift * mix(0.18, 0.78, seed.r), scatter.y);
	paint = mix(mix(gold.rgb, orange.rgb, min(seed.g * 1.8, 1.0)), scarlet.rgb, smoothstep(0.53, 0.95, seed.g));
	tipped = cos(tumble) * 0.08;
	visibility = smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.69, 1.0, age));
}

void fragment() {
	float fold = exp(-abs(UV.x) * 13.0);
	ALBEDO = paint * (0.9 + tipped + fold * 0.17);
	ALPHA = visibility;
}
