shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
uniform sampler3D flow_noise : filter_linear, repeat_enable;
varying float life;
varying float flame_age;
void vertex() {
	float t = fire_clock(TIME);
	float index = INSTANCE_CUSTOM.x;
	float rate = 0.90+INSTANCE_CUSTOM.y*0.30;
	float age = fract(t*rate+index/3.0);
	float birth_time = t-age/rate;
	float phase = INSTANCE_CUSTOM.z*6.283185;
	vec3 source = vec3(cos(phase)*0.12,0.80,sin(phase)*0.12);
	vec3 offset = vec3(birth_time*0.035,-birth_time*0.43,birth_time*0.018)+fire_phase*vec3(0.137,0.079,0.193);
	vec4 birth = textureLod(flow_noise,source*vec3(1.10,0.52,1.10)+offset,0.0);
	float envelope = smoothstep(0.0,0.09,age)*(1.0-smoothstep(0.35,0.90,age));
	envelope *= smoothstep(0.35,0.58,birth.a);
	float h = UV.y;
	float a = UV.x*6.283185;
	float width = max(sin(h*3.141593),0.0)*pow(1.0-h,1.2)*0.027*envelope;
	vec2 axis = normalize(birth.xz-vec2(0.5)+vec2(0.001));
	vec2 across = vec2(-axis.y,axis.x);
	vec3 p = source;
	p.xz += (birth.xz-vec2(0.5))*age*0.55+wind*age*age*0.45;
	p.y += age*0.70;
	p.xz += axis*(h*h*0.065*curl_amount+cos(a)*width)+across*sin(a)*width*0.50;
	p.y += (h-0.25)*0.10*envelope;
	p *= vec3(fire_size.x*sqrt(max(intensity,0.0)),fire_size.y*mix(0.55,1.0,intensity),fire_size.x*sqrt(max(intensity,0.0)));
	VERTEX = p*max(recall_visibility,0.001);
	life = envelope;
	flame_age = age;
}
void fragment() {
	if (life<0.01 || intensity<=0.0 || recall_visibility<=0.001) { discard; }
	vec3 color = mix(flame_color.rgb,edge_color.rgb,smoothstep(0.25,0.90,flame_age));
	color = mix(color,core_color.rgb,(1.0-smoothstep(0.05,0.35,flame_age))*(1.0-UV.y)*0.35);
	ALBEDO = color;
	EMISSION = color*glow_strength*0.18;
}
