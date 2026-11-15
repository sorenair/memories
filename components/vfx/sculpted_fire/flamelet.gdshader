shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
varying float life;
varying float flame_age;
void vertex() {
	float t = fire_clock(TIME);
	float index = INSTANCE_CUSTOM.x;
	float direction = -0.62 + index * 2.399963;
	float source_age = tongue_age(t,index);
	float age = clamp((source_age - 0.62) / 0.38,0.0,1.0);
	float envelope = smoothstep(0.0,0.18,age) * (1.0-smoothstep(0.55,1.0,age));
	vec4 stem,arc;
	vec2 tip;
	float bend;
	tongue_profile(t,index,stem,arc,tip,bend);
	float h = UV.y;
	float a = UV.x * 6.283185;
	float angle = -0.55 + h * (1.2 + curl_amount * (0.7 + age));
	float curve_radius = 0.045 * (0.75 + INSTANCE_CUSTOM.y * 0.5);
	vec2 axis = vec2(cos(direction), sin(direction));
	vec3 center = vec3(axis.x * (cos(angle)-cos(-0.55)), sin(angle)-sin(-0.55), axis.y * (cos(angle)-cos(-0.55))) * curve_radius;
	vec3 radial = vec3(axis.x*cos(angle),sin(angle),axis.y*cos(angle));
	vec3 across = vec3(-axis.y,0.0,axis.x);
	float width = max(sin(h * 3.141593),0.0) * pow(1.0-h,1.3) * 0.034;
	vec3 p = (center + radial*cos(a)*width + across*sin(a)*width*0.7) * envelope;
	p.xz += axis * (tip.x + age * 0.10) + wind * tip.y*tip.y * 0.32;
	p.y += tip.y + age * 0.40;
	p.xz *= fire_size.x * sqrt(max(intensity, 0.0));
	p.y *= fire_size.y * mix(0.55, 1.0, intensity);
	p *= max(recall_visibility, 0.001);
	VERTEX = p;
	NORMAL = normalize(radial * cos(a) + across * sin(a));
	life = envelope;
	flame_age = age;
}
void fragment() {
	if (life < 0.01 || intensity <= 0.0 || recall_visibility <= 0.001) { discard; }
	float face = abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 color = mix(flame_color.rgb, edge_color.rgb, smoothstep(0.35, 0.95, flame_age));
	color = mix(edge_color.rgb, color, smoothstep(0.1, 0.65, face));
	float hot = (1.0 - smoothstep(0.0, 0.3, flame_age)) * (1.0 - smoothstep(0.12, 0.4, UV.y));
	color = mix(color, core_color.rgb, hot * face * 0.45);
	ALBEDO = color;
	EMISSION = color * glow_strength * 0.18;
}
